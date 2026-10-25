import Foundation
import UserNotifications

/// Posts a silent banner when a phase ends.
final class Notifier: NSObject, UNUserNotificationCenterDelegate, Sendable {
    /// UserNotifications needs a real app bundle; `swift run` builds have none.
    private var center: UNUserNotificationCenter? {
        Bundle.main.bundleURL.pathExtension == "app" ? .current() : nil
    }

    func requestAuthorization() {
        guard let center else { return }
        center.delegate = self
        center.requestAuthorization(options: [.alert]) { _, error in
            if let error {
                NSLog("Pomodoro: notification permission failed: \(error)")
            }
        }
    }

    func post(title: String, body: String) {
        guard let center else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    // A menu bar app counts as frontmost while its panel is open; show banners anyway.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}
