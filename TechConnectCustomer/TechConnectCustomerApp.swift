import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct TechConnectCustomerApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            CustomerRootView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
