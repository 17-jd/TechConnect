import Foundation
import UserNotifications
import UIKit

/// Handles local notification permission for both apps.
/// FCM token registration is handled by AppDelegate in the Engineer app target.
@MainActor
class NotificationService: NSObject {
    static let shared = NotificationService()

    private override init() {}

    /// Requests notification permission and registers with APNs.
    /// Call on EngineerHomeView.onAppear.
    func requestPermissionAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}
