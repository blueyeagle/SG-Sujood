import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {

    // Navigation
    @Published var onboarded: Bool = false
    @Published var selectedTab: Tab = .home

    // Clock — drives countdown, next-waktu and progress rail
    @Published var now: Date = Date()

    // Fardhu tracker (per calendar day) — all start unmarked ("Mark"). Persisted; resets on a new day.
    @Published var dayLog: [Prayer: PrayerStatus] = AppState.emptyDayLog {
        didSet { persistDayLog() }
    }

    // Qadha counts — start at 0; rise only when a prayer is marked missed; persist until recorded.
    @Published var qadha: [Prayer: Int] = [
        .subuh: 0, .zohor: 0, .asar: 0, .maghrib: 0, .isyak: 0
    ] {
        didSet { persistQadha() }
    }

    static var emptyDayLog: [Prayer: PrayerStatus] {
        [.subuh: .pending, .zohor: .pending, .asar: .pending, .maghrib: .pending, .isyak: .pending]
    }

    // Nearby
    @Published var spaceFilter: SpaceFilter = .all
    @Published var savedSpaces: Set<String> = []   // SpaceRecord.id

    // Reminders
    @Published var reminderOn: [Prayer: Bool] = [
        .subuh: true, .zohor: true, .asar: true, .maghrib: true, .isyak: true
    ]
    @Published var syurukReminder: Bool = false
    @Published var leadMinutes: Int = 15   // 10 / 15 / 30

    // Timetable
    @Published var expandedWaktu: WaktuRow? = nil

    // Dzikir
    @Published var dzikirIndex: Int = 0
    @Published var dzikirCount: Int = 0
    @Published var dzikirRounds: Int = 0

    // Zakat — user-configurable, persisted to UserDefaults.
    let haulTotalDays = 354   // one lunar (Hijri) year
    private static let kBalance = "zakat.lowestBalance"
    private static let kHaulStart = "zakat.haulStart"

    @Published var lowestBalance: Double {
        didSet { UserDefaults.standard.set(lowestBalance, forKey: Self.kBalance) }
    }
    @Published var haulStartDate: Date {
        didSet { UserDefaults.standard.set(haulStartDate.timeIntervalSince1970, forKey: Self.kHaulStart) }
    }

    private static let kQadha = "tracker.qadha"
    private static let kDayLog = "tracker.dayLog"
    private static let kDayLogDate = "tracker.dayLogDate"
    private var currentDayKey = ""

    private var timer: AnyCancellable?

    init() {
        let d = UserDefaults.standard
        lowestBalance = d.object(forKey: Self.kBalance) as? Double ?? 24_000
        if let ts = d.object(forKey: Self.kHaulStart) as? Double {
            haulStartDate = Date(timeIntervalSince1970: ts)
        } else {
            haulStartDate = AppState.makeDate(2025, 9, 5)   // default seed
        }

        // Restore persisted qadha (property observers don't fire during init).
        if let stored = d.dictionary(forKey: Self.kQadha) as? [String: Int] {
            var q = qadha
            for (k, v) in stored { if let p = Prayer(rawValue: k) { q[p] = v } }
            qadha = q
        }
        // Restore today's tracker only if it belongs to today; otherwise start fresh.
        let today = AppState.dayKey(Date())
        currentDayKey = today
        if d.string(forKey: Self.kDayLogDate) == today,
           let stored = d.dictionary(forKey: Self.kDayLog) as? [String: String] {
            var log = AppState.emptyDayLog
            for (k, v) in stored {
                if let p = Prayer(rawValue: k), let s = PrayerStatus(rawValue: v) { log[p] = s }
            }
            dayLog = log
        }

        start()
    }

    func start() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                guard let self else { return }
                self.now = date
                self.rolloverIfNeeded()
            }
    }

    // MARK: - Persistence

    static func dayKey(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }

    private func persistQadha() {
        let dict = Dictionary(uniqueKeysWithValues: qadha.map { ($0.key.rawValue, $0.value) })
        UserDefaults.standard.set(dict, forKey: Self.kQadha)
    }
    private func persistDayLog() {
        let dict = Dictionary(uniqueKeysWithValues: dayLog.map { ($0.key.rawValue, $0.value.rawValue) })
        UserDefaults.standard.set(dict, forKey: Self.kDayLog)
        UserDefaults.standard.set(currentDayKey, forKey: Self.kDayLogDate)
    }

    /// When the calendar day changes while the app is open, reset the tracker (missed prayers
    /// are already counted in qadha). Does nothing until an actual day change.
    private func rolloverIfNeeded() {
        let key = AppState.dayKey(now)
        guard key != currentDayKey else { return }
        currentDayKey = key
        dayLog = AppState.emptyDayLog
    }

    enum SpaceFilter: String, CaseIterable { case all = "All", musollah = "Musollah", masjid = "Masjid" }

    // MARK: - Waktu times anchored to today

    /// The absolute Date for a waktu on the current calendar day, from the MUIS 2026 dataset.
    func time(for row: WaktuRow) -> Date { time(for: row, on: now) }

    func time(for row: WaktuRow, on day: Date) -> Date {
        let (hour24, minute) = PrayerData.components(for: row, on: day)
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: day)
        comps.hour = hour24
        comps.minute = minute
        comps.second = 0
        return Calendar.current.date(from: comps) ?? day
    }

    func time(for prayer: Prayer) -> Date {
        time(for: WaktuRow(rawValue: prayer.rawValue) ?? .subuh)
    }

    /// "5.44 am" — MUIS-style dotted clock, from the real dataset.
    func clockString(for row: WaktuRow) -> String {
        clockString(for: time(for: row))
    }
    func clockString(for prayer: Prayer) -> String {
        clockString(for: WaktuRow(rawValue: prayer.rawValue) ?? .subuh)
    }

    func clockString(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h.mm a"
        return f.string(from: date).lowercased()
    }

    // MARK: - Dates

    /// "Monday 10 August 2026"
    var gregorianLong: String { gregorianLong(now) }
    func gregorianLong(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE d MMMM yyyy"
        return f.string(from: date)
    }

    /// Hijri date as computed (Umm al-Qura). Note: MUIS uses an observed calendar,
    /// so this can differ by ±1 day — treat as indicative until wired to MUIS.
    var hijriString: String { hijriString(now) }
    func hijriString(_ date: Date) -> String {
        var cal = Calendar(identifier: .islamicUmmAlQura)
        cal.locale = Locale(identifier: "en")
        let f = DateFormatter()
        f.calendar = cal
        f.locale = Locale(identifier: "en")
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: date)
    }

    /// Imsak ≈ 10 minutes before Subuh.
    func imsakString(on day: Date) -> String {
        let subuh = time(for: WaktuRow.subuh, on: day)
        let imsak = Calendar.current.date(byAdding: .minute, value: -10, to: subuh) ?? subuh
        return clockString(for: imsak)
    }

    // MARK: - Next / previous waktu (prayers only, for the hero)

    private var prayerRowsOrder: [WaktuRow] { [.subuh, .zohor, .asar, .maghrib, .isyak] }

    /// The next upcoming prayer and its time; rolls to tomorrow's Subuh after Isyak.
    var nextPrayer: (row: WaktuRow, date: Date) {
        for row in prayerRowsOrder {
            let t = time(for: row)
            if t > now { return (row, t) }
        }
        // After Isyak → tomorrow's Subuh (using tomorrow's own published time)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        return (.subuh, time(for: WaktuRow.subuh, on: tomorrow))
    }

    var previousPrayer: (row: WaktuRow, date: Date) {
        var prev: (WaktuRow, Date) = (.isyak, Calendar.current.date(byAdding: .day, value: -1, to: time(for: WaktuRow.isyak))!)
        for row in prayerRowsOrder {
            let t = time(for: row)
            if t <= now { prev = (row, t) } else { break }
        }
        return prev
    }

    /// The next waktu across the full timetable (used to ink the upcoming row).
    var nextWaktuRow: WaktuRow {
        for row in WaktuRow.allCases {
            if time(for: row) > now { return row }
        }
        return .subuh
    }

    var countdownString: String {
        let secs = max(0, Int(nextPrayer.date.timeIntervalSince(now)))
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        if h > 0 { return "\(h)h \(m)m \(s)s" }
        return "\(m)m \(s)s"
    }

    var progressFraction: Double {
        let start = previousPrayer.date.timeIntervalSince1970
        let end = nextPrayer.date.timeIntervalSince1970
        let cur = now.timeIntervalSince1970
        guard end > start else { return 0 }
        return (cur - start) / (end - start)
    }

    // MARK: - Fardhu tracker (three-state cycle → writes through to qadha)

    func cycleStatus(_ prayer: Prayer) {
        let current = dayLog[prayer] ?? .pending
        let next = current.next
        // Entering Missed increments qadha; leaving Missed decrements (floor 0).
        if next == .missed { qadha[prayer, default: 0] += 1 }
        if current == .missed { qadha[prayer] = max(0, (qadha[prayer] ?? 0) - 1) }
        dayLog[prayer] = next
    }

    var doneCount: Int { dayLog.values.filter { $0 == .done }.count }
    var missedCount: Int { dayLog.values.filter { $0 == .missed }.count }
    var toComeCount: Int { dayLog.values.filter { $0 == .pending }.count }

    var qadhaTotal: Int { qadha.values.reduce(0, +) }

    // MARK: - Qadha (decrement only, floor 0)

    func recordQadha(_ prayer: Prayer) {
        qadha[prayer] = max(0, (qadha[prayer] ?? 0) - 1)
    }

    // MARK: - Nearby
    // The directory itself lives in SpacesStore (remote-configurable); distance sorting
    // is done in the views using LocationProvider. AppState only holds the filter + saves.

    func isSaved(_ id: String) -> Bool { savedSpaces.contains(id) }
    func toggleSave(_ id: String) {
        if savedSpaces.contains(id) { savedSpaces.remove(id) } else { savedSpaces.insert(id) }
    }

    // MARK: - Dzikir

    var currentDzikir: DzikirPhrase { SampleData.dzikir[dzikirIndex] }

    func tapDzikir() {
        dzikirCount += 1
        if dzikirCount >= currentDzikir.target {
            dzikirCount = 0
            if dzikirIndex == SampleData.dzikir.count - 1 {
                dzikirRounds += 1
                dzikirIndex = 0
            } else {
                dzikirIndex += 1
            }
            Haptics.success()
        } else {
            Haptics.light()
        }
    }

    func undoDzikir() {
        dzikirCount = max(0, dzikirCount - 1)
    }

    func resetDzikir() {
        dzikirCount = 0
        dzikirIndex = 0
        dzikirRounds = 0
    }

    func selectDzikir(_ index: Int) {
        dzikirIndex = index
        dzikirCount = 0
    }

    // MARK: - Zakat haul countdown (derived from haulStartDate)

    /// End of haul = start + one lunar year.
    var haulEnd: Date {
        Calendar.current.date(byAdding: .day, value: haulTotalDays, to: haulStartDate) ?? haulStartDate
    }
    /// Days elapsed since the haul began (clamped to the year).
    var haulDay: Int {
        let days = Calendar.current.dateComponents([.day], from: haulStartDate, to: now).day ?? 0
        return max(0, min(haulTotalDays, days))
    }
    var zakatDue: Double { lowestBalance * 0.025 }

    var haulCountdown: String {
        let secs = max(0, Int(haulEnd.timeIntervalSince(now)))
        let d = secs / 86400
        let h = (secs % 86400) / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        return String(format: "%dd %02dh %02dm %02ds", d, h, m, s)
    }

    var haulFraction: Double { Double(haulDay) / Double(haulTotalDays) }

    /// "25 August 2026"
    func longDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d MMMM yyyy"
        return f.string(from: date)
    }

    // MARK: - Ramadan (Hijri, Umm al-Qura — indicative; MUIS observes the moon)

    struct RamadanInfo {
        let isRamadan: Bool
        let hijriYear: Int
        let dayOfRamadan: Int   // 1...30 when in Ramadan, else 0
        let daysToNext: Int     // 0 when in Ramadan
        let start: Date         // 1 Ramadan
        let end: Date           // 1 Syawal (Hari Raya)
    }

    var ramadan: RamadanInfo {
        var cal = Calendar(identifier: .islamicUmmAlQura)
        cal.locale = Locale(identifier: "en")
        let c = cal.dateComponents([.year, .month, .day], from: now)
        let hy = c.year ?? 1448, hm = c.month ?? 1, hd = c.day ?? 1

        func firstOf(month: Int, year: Int) -> Date {
            cal.date(from: DateComponents(year: year, month: month, day: 1)) ?? now
        }

        let isRamadan = (hm == 9)
        let startYear: Int = (hm <= 9) ? hy : hy + 1   // upcoming (or current) Ramadan
        let start = firstOf(month: 9, year: startYear)
        let end = firstOf(month: 10, year: startYear)  // 1 Syawal
        let daysToNext = isRamadan ? 0 : max(0, cal.dateComponents([.day], from: now, to: start).day ?? 0)

        return RamadanInfo(isRamadan: isRamadan, hijriYear: startYear,
                           dayOfRamadan: isRamadan ? hd : 0,
                           daysToNext: daysToNext, start: start, end: end)
    }

    // MARK: - Helpers

    static func makeDate(_ y: Int, _ mo: Int, _ d: Int) -> Date {
        var c = DateComponents(); c.year = y; c.month = mo; c.day = d; c.hour = 12
        return Calendar.current.date(from: c) ?? Date()
    }
}
