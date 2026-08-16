import Foundation

// Real MUIS prayer times for Singapore, Year 2026 — parsed from the official
// "Prayer timetable 2026" PDF into prayer_times_2026.json (365 days, 24-hour "HH:mm").
// Times are identical island-wide. Refresh annually with the next year's MUIS timetable.

struct DayTimes: Decodable {
    let d: String            // "yyyy-MM-dd"
    let subuh, syuruk, zohor, asar, maghrib, isyak: String  // "HH:mm" (24h)

    func time(for row: WaktuRow) -> String {
        switch row {
        case .subuh:   return subuh
        case .syuruk:  return syuruk
        case .zohor:   return zohor
        case .asar:    return asar
        case .maghrib: return maghrib
        case .isyak:   return isyak
        }
    }
}

enum PrayerData {
    /// Keyed by "yyyy-MM-dd".
    static let byDate: [String: DayTimes] = {
        guard let url = Bundle.main.url(forResource: "prayer_times_2026", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rows = try? JSONDecoder().decode([DayTimes].self, from: data)
        else { return [:] }
        return Dictionary(uniqueKeysWithValues: rows.map { ($0.d, $0) })
    }()

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date) -> String { keyFormatter.string(from: date) }

    /// The day's published times, or nil if the date is outside the bundled year.
    static func day(for date: Date) -> DayTimes? { byDate[key(for: date)] }

    /// (hour24, minute) for a waktu on a given day. Falls back to the SampleData
    /// reference clock when the date is outside the bundled dataset.
    static func components(for row: WaktuRow, on date: Date) -> (Int, Int) {
        if let hm = day(for: date)?.time(for: row) {
            let parts = hm.split(separator: ":")
            if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) { return (h, m) }
        }
        let (h, m, pm) = SampleData.waktuClock[row]!   // fallback
        return ((h % 12) + (pm ? 12 : 0), m)
    }

    /// The absolute Date for a waktu on a given calendar day.
    static func date(for row: WaktuRow, on day: Date) -> Date {
        let (h, m) = components(for: row, on: day)
        var c = Calendar.current.dateComponents([.year, .month, .day], from: day)
        c.hour = h; c.minute = m; c.second = 0
        return Calendar.current.date(from: c) ?? day
    }
}
