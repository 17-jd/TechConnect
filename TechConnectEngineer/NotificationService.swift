import Foundation
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

/// Handles FCM registration and notification permission for the Engineer app.
@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    private override init() {}

    func requestPermissionAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
            // FCM token will arrive via AppDelegate.messaging(_:didReceiveRegistrationToken:)
        }
    }

    /// Call this once to fetch the current FCM token and persist it.
    /// Handles the case where the token already exists before the delegate fires.
    func syncFCMToken() {
        Messaging.messaging().token { token, error in
            guard let token, error == nil,
                  let uid = Auth.auth().currentUser?.uid else { return }
            Task {
                try? await FirestoreService.shared.updateFCMToken(userId: uid, token: token)
            }
        }
    }
}
