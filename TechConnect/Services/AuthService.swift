import Foundation
import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

class AuthService: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    static let shared = AuthService()

    private init() {
        self.user = Auth.auth().currentUser
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isLoading = false
            }
        }
    }

    var isLoggedIn: Bool { user != nil }
    var userId: String? { user?.uid }

    // MARK: - Email/Password

    func createAccount(email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            try await changeRequest.commitChanges()
            self.user = Auth.auth().currentUser
        } catch {
            self.errorMessage = friendlyError(error)
        }
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
        } catch {
            self.errorMessage = friendlyError(error)
        }
        isLoading = false
    }

    // MARK: - Google Sign-In

    func signInWithGoogle(presenting viewController: UIViewController) async {
        isLoading = true
        errorMessage = nil
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Google client ID. Please re-download GoogleService-Info.plist."
            isLoading = false
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get Google ID token."
                isLoading = false
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            self.user = authResult.user
        } catch {
            self.errorMessage = friendlyError(error)
        }
        isLoading = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func friendlyError(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue: return "This email is already in use."
        case AuthErrorCode.invalidEmail.rawValue: return "Please enter a valid email address."
        case AuthErrorCode.weakPassword.rawValue: return "Password must be at least 6 characters."
        case AuthErrorCode.wrongPassword.rawValue: return "Incorrect password. Please try again."
        case AuthErrorCode.userNotFound.rawValue: return "No account found with this email."
        default: return error.localizedDescription
        }
    }
}
