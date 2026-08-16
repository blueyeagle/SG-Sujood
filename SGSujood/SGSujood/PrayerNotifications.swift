import Foundation
import UserNotifications

// Schedules silent per-waktu prayer reminders (see the app's "Silent reminders" promise).
// iOS caps pending notifications at 64, so we schedule a rolling window of a few days and
// reschedule on launch and whenever the toggles / lead time change.
enum PrayerNotifications {

    private static let prefix = "prayer-"
    private static let days = 6                      // 5 waktu × 2 (nudge + at) × 6 ≈ 60 < 64

    /// Request authorization (if needed) and (re)build the schedule from the current settings.
    static func reschedule(enabled: [Prayer: Bool], leadMinutes: Int) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            center.getPendingNotificationRequests { pending in
                let stale = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
                center.removePendingNotificationRequests(withIdentifiers: stale)
                build(enabled: enabled, leadMinutes: leadMinutes, center: center)
            }
        }
    }

    /// Cancel all prayer reminders (e.g. when the user turns them all off).
    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            center.removePendingNotificationRequests(
                withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) })
        }
    }

    private static func build(enabled: [Prayer: Bool], leadMinutes: Int, center: UNUserNotificationCenter) {
        let cal = Calendar.current
        let now = Date()
        let df = DateFormatter(); df.locale = Locale(identifier: "en_US_POSIX"); df.dateFormat = "yyyyMMdd"

        for offset in 0..<days {
            guard let day = cal.date(byAdding: .day, value: offset, to: now) else { continue }
            let key = df.string(from: day)
            for prayer in Prayer.fardhu where (enabled[prayer] ?? false) {
                let row = WaktuRow(rawValue: prayer.rawValue) ?? .subuh
                let waktu = PrayerData.date(for: row, on: day)

                add(center, id: "\(prefix)\(prayer.rawValue)-\(key)-at",
                    title: "\(prayer.rawValue) — it's time to pray",
                    body: "The time for \(prayer.rawValue) has entered.",
                    at: waktu, now: now)

                if let pre = cal.date(byAdding: .minute, value: -leadMinutes, to: waktu) {
                    add(center, id: "\(prefix)\(prayer.rawValue)-\(key)-pre",
                        title: "\(prayer.rawValue) soon",
                        body: "\(prayer.rawValue) is in \(leadMinutes) minutes.",
                        at: pre, now: now)
                }
            }
        }
    }

    private static func add(_ center: UNUserNotificationCenter, id: String,
                            title: String, body: String, at date: Date, now: Date) {
        guard date > now else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil                       // silent, per the app's promise
        content.interruptionLevel = .timeSensitive // best-effort; degrades to .active without the entitlement
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
