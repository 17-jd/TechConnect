import Foundation
import Combine
import UIKit

class AuthViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var isSignUp = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService = AuthService.shared

    func submit() {
        guard validateInputs() else { return }
        isLoading = true
        errorMessage = nil
        Task {
            if isSignUp {
                await authService.createAccount(email: email, password: password, fullName: fullName)
            } else {
                await authService.signIn(email: email, password: password)
            }
            isLoading = authService.isLoading
            errorMessage = authService.errorMessage
        }
    }

    func signInWithGoogle() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        isLoading = true
        Task {
            await authService.signInWithGoogle(presenting: root)
            isLoading = authService.isLoading
            errorMessage = authService.errorMessage
        }
    }

    private func validateInputs() -> Bool {
        if isSignUp && fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your full name."
            return false
        }
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your email."
            return false
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            return false
        }
        return true
    }
}
