//
//  AppDelegate.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 3/29/22.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    private var deafaultConfiguration = "Default Configuration"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Apply global appearance early so every navigation stack inherits the same palette.
        AppTheme.applySageAndSlate()

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        LocalNotificationScheduler.shared.requestAuthorizationIfNeeded()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: deafaultConfiguration, sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // Show notifications even when the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }

}

/// Centralized scheduler for per-item due-time local notifications.
///
/// Behavior:
/// - The app schedules **at most one** pending notification per item, keyed by a stable identifier:
///   `chalkboard.due.<item-uuid>`.
/// - `rescheduleDueNotification(for:)` is idempotent: it always removes any existing pending request
///   for that item and then (re)schedules if there's a valid future fire date.
/// - If the user clears the due time (all-day item), the notification is **not** scheduled.
///
/// Due time representation:
/// - `ChalkboardItem.dueTimeMinutes` stores minutes since midnight (0...1439) on `item.date`
///   (which is stored/treated as the day, i.e. `startOfDay`).
///
/// Implementation note:
/// - This lives in `AppDelegate.swift` to avoid “file not in target membership” build issues.
///
protocol LocalNotificationSchedulerProtocol {
    func requestAuthorizationIfNeeded()
    func rescheduleDueNotification(for item: ChalkboardItem)
    func cancelDueNotification(for itemId: UUID)
}

extension LocalNotificationScheduler: LocalNotificationSchedulerProtocol { }

final class LocalNotificationScheduler {
    static let shared = LocalNotificationScheduler()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [center] settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    func rescheduleDueNotification(for item: ChalkboardItem) {
        cancelDueNotification(for: item.id)

        guard let fireDate = dueFireDate(for: item) else { return }
        guard fireDate > Date() else { return }

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = "Due"
        content.body = item.text
        content.sound = .default
        content.userInfo = ["itemId": item.id.uuidString]

        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: item.id),
            content: content,
            trigger: trigger
        )

        center.add(request) { _ in }
    }

    func cancelDueNotification(for itemId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier(for: itemId)])
    }
}

private extension LocalNotificationScheduler {
    func notificationIdentifier(for itemId: UUID) -> String {
        "chalkboard.due.\(itemId.uuidString)"
    }

    func dueFireDate(for item: ChalkboardItem) -> Date? {
        guard let minutes = item.dueTimeMinutes else { return nil }
        let day = Calendar.current.startOfDay(for: item.date)
        return Calendar.current.date(byAdding: .minute, value: minutes, to: day)
    }
}

