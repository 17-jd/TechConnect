import SwiftUI
import FirebaseAuth

struct RootView: View {
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
                MainTabView(profileVM: profileVM, userRole: profileVM.user?.role ?? .customer)
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

struct MainTabView: View {
    @ObservedObject var profileVM: ProfileViewModel
    let userRole: AppUser.UserRole

    var body: some View {
        TabView {
            Group {
                if userRole == .customer {
                    CustomerHomeView()
                        .tabItem { Label("Home", systemImage: "house.fill") }
                } else {
                    EngineerHomeView()
                        .tabItem { Label("Jobs", systemImage: "wrench.and.screwdriver.fill") }
                }
            }

            JobHistoryView(role: userRole)
                .tabItem { Label("History", systemImage: "clock.fill") }

            ProfileView(profileVM: profileVM)
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(Color(hex: "1a73e8"))
    }
}

// ProfileView and InfoRow are defined in ProfileView.swift (shared with engineer target)
