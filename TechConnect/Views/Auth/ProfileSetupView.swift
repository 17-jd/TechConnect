import SwiftUI
import FirebaseAuth

struct ProfileSetupView: View {
    @ObservedObject var profileVM: ProfileViewModel
    @State private var name = ""
    @State private var role: AppUser.UserRole = .customer
    @State private var selectedSpecialties: Set<ServiceCategory> = []
    @State private var experience = ""

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(hex: "1a73e8"), Color(hex: "6c3ce1")],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 72, height: 72)
                            Image(systemName: "person.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.white)
                        }
                        Text("Almost There!")
                            .font(.title2.bold())
                        Text("Tell us a bit about yourself")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)

                    // Name card
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Your Name", systemImage: "person.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        AuthInputField(icon: "person.fill", placeholder: "Full Name", text: $name)
                    }
                    .cardStyle()

                    // Role card
                    VStack(alignment: .leading, spacing: 14) {
                        Label("I want to", systemImage: "person.2.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            RoleCard(
                                icon: "house.fill",
                                title: "Get Help",
                                subtitle: "I need IT support",
                                isSelected: role == .customer,
                                color: Color(hex: "1a73e8")
                            ) { role = .customer }

                            RoleCard(
                                icon: "wrench.and.screwdriver.fill",
                                title: "Provide Help",
                                subtitle: "I'm an IT engineer",
                                isSelected: role == .engineer,
                                color: Color(hex: "6c3ce1")
                            ) { role = .engineer }
                        }
                    }
                    .cardStyle()

                    // Engineer extras
                    if role == .engineer {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Your Specialties", systemImage: "star.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(ServiceCategory.allCases) { category in
                                    SpecialtyChip(
                                        category: category,
                                        isSelected: selectedSpecialties.contains(category)
                                    ) {
                                        if selectedSpecialties.contains(category) {
                                            selectedSpecialties.remove(category)
                                        } else {
                                            selectedSpecialties.insert(category)
                                        }
                                    }
                                }
                            }
                        }
                        .cardStyle()

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Experience", systemImage: "briefcase.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            AuthInputField(icon: "briefcase.fill", placeholder: "e.g. 5 years in IT support", text: $experience)
                        }
                        .cardStyle()
                    }

                    if let error = profileVM.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(error).font(.caption)
                        }
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                    }

                    // Continue button
                    Button {
                        Task {
                            _ = await profileVM.saveProfile(
                                name: name,
                                role: role,
                                specialties: selectedSpecialties.map(\.rawValue),
                                experience: experience
                            )
                        }
                    } label: {
                        ZStack {
                            if profileVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Continue")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(name.isEmpty
                            ? AnyShapeStyle(Color(.systemGray4))
                            : AnyShapeStyle(LinearGradient(colors: [Color(hex: "1a73e8"), Color(hex: "6c3ce1")],
                                             startPoint: .leading, endPoint: .trailing)))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: name.isEmpty ? .clear : Color(hex: "1a73e8").opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(name.isEmpty || profileVM.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            if let displayName = Auth.auth().currentUser?.displayName, !displayName.isEmpty {
                name = displayName
            }
        }
    }
}

struct RoleCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : Color(.systemGray5))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? .white : .secondary)
                }
                Text(title).font(.subheadline.bold())
                    .foregroundStyle(isSelected ? color : .primary)
                Text(subtitle).font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? color.opacity(0.08) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? color : .clear, lineWidth: 2))
        }
    }
}

struct SpecialtyChip: View {
    let category: ServiceCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon).font(.caption)
                Text(category.rawValue).font(.caption.bold()).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(isSelected ? Color(hex: "1a73e8").opacity(0.12) : Color(.systemGray6))
            .foregroundStyle(isSelected ? Color(hex: "1a73e8") : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color(hex: "1a73e8") : .clear, lineWidth: 1.5))
        }
    }
}

extension View {
    func cardStyle() -> some View {
        self.padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}
