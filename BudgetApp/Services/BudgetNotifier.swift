import UserNotifications

/// Shows budget alerts as notifications. Used when an expense is logged with Back Tap, where the app isn't on screen;
/// inside the app the same alert appears as a banner instead.
enum BudgetNotifier {
    /// iOS asks only the first time; after that this returns the answer given then.
    @discardableResult
    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// True when notifications for the app are switched off in iOS Settings.
    static func isDenied() async -> Bool {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied
    }

    static func post(_ alert: BudgetAlerts.Alert) async {
        let message = BudgetAlerts.message(for: alert)
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default
        // One identifier per level, so a repeat replaces the old notification instead of stacking.
        let request = UNNotificationRequest(identifier: "budget-\(alert.level.rawValue)", content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
