import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @FocusState private var focusedField: Field?

    enum Field { case fullName, email, password }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Hero
                    ZStack {
                        LinearGradient(colors: [Color(hex: "1a73e8"), Color(hex: "6c3ce1")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                            .ignoresSafeArea()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.white)
                            }
                            Text("TechConnect")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            Text("IT support at your doorstep")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .padding(.vertical, 44)
                    }
                    .frame(height: 220)

                    VStack(spacing: 24) {
                        // Segmented toggle
                        HStack(spacing: 0) {
                            TabButton(title: "Sign In", isSelected: !viewModel.isSignUp) {
                                withAnimation { viewModel.isSignUp = false }
                            }
                            TabButton(title: "Create Account", isSelected: viewModel.isSignUp) {
                                withAnimation { viewModel.isSignUp = true }
                            }
                        }
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.top, 24)

                        // Form card
                        VStack(spacing: 14) {
                            if viewModel.isSignUp {
                                AuthInputField(icon: "person.fill", placeholder: "Full Name", text: $viewModel.fullName)
                                    .focused($focusedField, equals: .fullName)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .email }
                            }
                            AuthInputField(icon: "envelope.fill", placeholder: "Email", text: $viewModel.email,
                                           keyboardType: .emailAddress, autocapitalization: .never)
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                            AuthInputField(icon: "lock.fill", placeholder: "Password", text: $viewModel.password,
                                           isSecure: true)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.done)
                                .onSubmit { viewModel.submit() }
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)

                        // Error
                        if let error = viewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error).font(.caption)
                            }
                            .foregroundStyle(.red)
                            .padding(.horizontal, 4)
                        }

                        // Primary button
                        Button {
                            focusedField = nil
                            viewModel.submit()
                        } label: {
                            ZStack {
                                if viewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(viewModel.isSignUp ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LinearGradient(colors: [Color(hex: "1a73e8"), Color(hex: "6c3ce1")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color(hex: "1a73e8").opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .disabled(viewModel.isLoading)

                        // Divider
                        HStack {
                            Rectangle().frame(height: 1).foregroundStyle(Color(.systemGray4))
                            Text("or continue with").font(.caption).foregroundStyle(.secondary)
                            Rectangle().frame(height: 1).foregroundStyle(Color(.systemGray4))
                        }

                        // Google button
                        Button { viewModel.signInWithGoogle() } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "globe").font(.title3).foregroundStyle(Color(hex: "1a73e8"))
                                Text("Sign in with Google").fontWeight(.medium).foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 1))
                            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(isSelected ? Color(.systemBackground) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(3)
        }
    }
}

struct AuthInputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: "1a73e8"))
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
