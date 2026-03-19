import SwiftUI

struct ProfileView: View {
    @ObservedObject var profileVM: ProfileViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        if let user = profileVM.user {
                            // Avatar header
                            VStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [Color(hex: "1a73e8"), Color(hex: "6c3ce1")],
                                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 80, height: 80)
                                    Text(String(user.name.prefix(1).uppercased()))
                                        .font(.largeTitle.bold())
                                        .foregroundStyle(.white)
                                }
                                Text(user.name).font(.title3.bold())
                                Text(user.phone.isEmpty ? user.role.rawValue.capitalized : user.phone)
                                    .font(.subheadline).foregroundStyle(.secondary)
                                StatusBadge(status: .open)
                                    .opacity(0) // spacer
                                Text(user.role == .customer ? "Customer" : "Engineer")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 5)
                                    .background(Color(hex: "1a73e8").opacity(0.1))
                                    .foregroundStyle(Color(hex: "1a73e8"))
                                    .clipShape(Capsule())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)

                            // Info
                            VStack(spacing: 0) {
                                InfoRow(icon: "envelope.fill", label: "Email / Phone", value: user.phone.isEmpty ? "—" : user.phone)
                                Divider().padding(.leading, 52)
                                InfoRow(icon: "person.badge.shield.checkmark", label: "Role", value: user.role.rawValue.capitalized)
                                if user.role == .engineer && !user.experience.isEmpty {
                                    Divider().padding(.leading, 52)
                                    InfoRow(icon: "briefcase.fill", label: "Experience", value: user.experience)
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)

                            // Actions
                            VStack(spacing: 0) {
                                Button {
                                    profileVM.switchRole()
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.left.arrow.right")
                                            .foregroundStyle(Color(hex: "1a73e8"))
                                            .frame(width: 32)
                                        Text("Switch to \(user.role == .customer ? "Engineer" : "Customer")")
                                        Spacer()
                                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                                    }
                                    .padding(16)
                                }
                                .foregroundStyle(.primary)

                                Divider().padding(.leading, 52)

                                Button(role: .destructive) {
                                    AuthService.shared.signOut()
                                } label: {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .foregroundStyle(.red)
                                            .frame(width: 32)
                                        Text("Sign Out")
                                        Spacer()
                                    }
                                    .padding(16)
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: "1a73e8"))
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline)
            }
            Spacer()
        }
        .padding(16)
    }
}
