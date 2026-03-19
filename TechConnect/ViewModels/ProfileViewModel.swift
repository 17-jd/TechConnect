import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class ProfileViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasProfile = false

    private let firestoreService = FirestoreService.shared
    private var listener: ListenerRegistration?

    func loadProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        listener = firestoreService.listenToUser(id: uid) { [weak self] user in
            Task { @MainActor in
                self?.user = user
                self?.hasProfile = user != nil && !(user?.name.isEmpty ?? true)
                self?.isLoading = false
            }
        }
    }

    func saveProfile(name: String, role: AppUser.UserRole, specialties: [String], experience: String) async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        isLoading = true
        errorMessage = nil

        // email auth users don't have a phoneNumber
        let phone = Auth.auth().currentUser?.phoneNumber ?? Auth.auth().currentUser?.email ?? ""

        let appUser = AppUser(
            id: uid,
            name: name,
            phone: phone,
            role: role,
            specialties: specialties,
            experience: experience
        )

        do {
            if user == nil {
                try firestoreService.createUser(appUser)
            } else {
                try firestoreService.updateUser(appUser)
            }
            // Set both together so RootView never sees hasProfile=true with user=nil
            user = appUser
            hasProfile = true
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func switchRole() {
        guard var currentUser = user else { return }
        currentUser.role = currentUser.role == .customer ? .engineer : .customer
        user = currentUser
        do {
            try firestoreService.updateUser(currentUser)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
