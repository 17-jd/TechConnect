import Foundation
import UserNotifications
import UIKit

/// Engineer-app notification service.
/// FCM token sync will be added here once FirebaseMessaging SPM product is enabled
/// and a paid Apple Developer account is configured for APNs.
@MainActor
class NotificationService: NSObject {
    static let shared = NotificationService()

    private override init() {}

    func requestPermissionAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}
