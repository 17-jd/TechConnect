import SwiftUI
import FirebaseAuth

/// Root view for the Engineer app target.
/// Routes between login, profile setup, and the engineer tab bar.
struct EngineerRootView: View {
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
                EngineerTabView(profileVM: profileVM)
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

struct EngineerTabView: View {
    @ObservedObject var profileVM: ProfileViewModel

    var body: some View {
        TabView {
            EngineerHomeView()
                .tabItem { Label("Jobs", systemImage: "wrench.and.screwdriver.fill") }

            JobHistoryView(role: .engineer)
                .tabItem { Label("History", systemImage: "clock.fill") }

            ProfileView(profileVM: profileVM)
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(Color(hex: "1a73e8"))
    }
}
