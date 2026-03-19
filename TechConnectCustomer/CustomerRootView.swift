import SwiftUI
import FirebaseAuth

/// Root view for the Customer app target.
/// Routes between login, profile setup, and the customer tab bar.
struct CustomerRootView: View {
    @ObservedObject private var authService = AuthService.shared
    @StateObject private var profileVM = ProfileViewModel()

    var body: some View {
        Group {
            if authService.user == nil {
                LoginView()
            } else if profileVM.isLoading {
                ZStack {
                    Color(.systemGroupedBackground).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading...").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            } else if !profileVM.hasProfile {
                ProfileSetupView(profileVM: profileVM)
            } else {
                CustomerTabView(profileVM: profileVM)
            }
        }
        .onChange(of: authService.user) {
            if authService.user != nil { profileVM.loadProfile() }
        }
        .onAppear {
            if authService.user != nil { profileVM.loadProfile() }
        }
    }
}

struct CustomerTabView: View {
    @ObservedObject var profileVM: ProfileViewModel

    var body: some View {
        TabView {
            CustomerHomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            JobHistoryView(role: .customer)
                .tabItem { Label("History", systemImage: "clock.fill") }

            ProfileView(profileVM: profileVM)
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(Color(hex: "1a73e8"))
    }
}
