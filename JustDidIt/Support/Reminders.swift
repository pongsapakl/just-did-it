import Foundation
import UserNotifications

/// Daily check-in reminders that learn when you usually open the app
/// (Duolingo-style) instead of asking for a fixed time.
///
/// All local — nothing leaves the phone. On each foreground the app records the
/// open time, then reschedules the next week of reminders at your typical hour,
/// skipping today if you've already shown up.
enum Reminders {
    private static let enabledKey = "remindersEnabled"
    private static let openTimesKey = "reminderOpenMinutes"   // [Int], minutes since midnight
    private static let maxSamples = 21

    /// Rotating copy so the reminder doesn't go stale.
    private static let messages = [
        "What did you do today?",
        "Show up for today.",
        "Anything to check off?",
        "Just did something? Log it.",
        "Today's still open.",
    ]

    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    // MARK: Learning the usual open time

    /// Record "the app was opened now" — feeds the typical-time estimate.
    static func recordOpen() {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: Date())
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

        var samples = UserDefaults.standard.array(forKey: openTimesKey) as? [Int] ?? []
        samples.append(minutes)
        if samples.count > maxSamples { samples.removeFirst(samples.count - maxSamples) }
        UserDefaults.standard.set(samples, forKey: openTimesKey)
    }

    /// The hour/minute you typically open the app — median of recent opens,
    /// nudged 15 minutes earlier so the reminder lands *before* the habit slot.
    /// Falls back to 20:00 until there's enough signal.
    static func typicalTime() -> (hour: Int, minute: Int) {
        let samples = UserDefaults.standard.array(forKey: openTimesKey) as? [Int] ?? []
        guard samples.count >= 3 else { return (20, 0) }

        let median = samples.sorted()[samples.count / 2]
        let target = max(0, median - 15)
        return (target / 60, target % 60)
    }

    // MARK: Scheduling

    /// Ask once for permission (system remembers the answer; re-calls are no-ops
    /// once the user has decided).
    static func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    /// Replace all pending reminders with the next 7 days at the typical time.
    /// Today is skipped if you've already shown up (or the slot already passed).
    static func reschedule(shownUpToday: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard isEnabled else { return }

        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional else { return }

            let cal = Calendar.current
            let time = typicalTime()
            let now = Date()

            for offset in 0..<7 {
                guard let day = cal.date(byAdding: .day, value: offset, to: now),
                      let fireDate = cal.date(bySettingHour: time.hour, minute: time.minute,
                                              second: 0, of: day)
                else { continue }

                // Skip today when already shown up, or when the slot is behind us.
                if offset == 0 && (shownUpToday || fireDate <= now) { continue }

                let content = UNMutableNotificationContent()
                content.title = "Just Did It"
                let dayIndex = cal.ordinality(of: .day, in: .era, for: fireDate) ?? offset
                content.body = messages[dayIndex % messages.count]
                content.sound = .default

                let comps = cal.dateComponents([.year, .month, .day, .hour, .minute],
                                               from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                center.add(UNNotificationRequest(
                    identifier: "daily-checkin-\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)",
                    content: content,
                    trigger: trigger
                ))
            }
        }
    }

    /// Turn reminders off: clear everything pending.
    static func disable() {
        isEnabled = false
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
