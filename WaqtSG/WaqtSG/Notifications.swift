import Foundation
import UserNotifications

enum Notifications {

    /// Requests authorization (if needed) and schedules a one-off calendar notification.
    /// Completion returns whether it was scheduled (false if denied or the date is past).
    static func schedule(id: String, title: String, body: String, at date: Date,
                         completion: @escaping (Bool) -> Void) {
        guard date > Date() else { DispatchQueue.main.async { completion(false) }; return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { DispatchQueue.main.async { completion(false) }; return }
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(req) { error in
                DispatchQueue.main.async { completion(error == nil) }
            }
        }
    }

    /// 9:00 am on the given day.
    static func morningOf(_ day: Date) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: day)
        c.hour = 9; c.minute = 0
        return Calendar.current.date(from: c) ?? day
    }
}
