import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {

    // Navigation
    @Published var onboarded: Bool = false
    @Published var selectedTab: Tab = .home

    // Clock — drives countdown, next-waktu and progress rail
    @Published var now: Date = Date()

    // Fardhu tracker (per calendar day)
    @Published var dayLog: [Prayer: PrayerStatus] = [
        .subuh: .done, .zohor: .done, .asar: .pending, .maghrib: .pending, .isyak: .pending
    ]

    // Qadha counts (month-scoped)
    @Published var qadha: [Prayer: Int] = [
        .subuh: 9, .zohor: 4, .asar: 6, .maghrib: 2, .isyak: 2
    ]

    // Nearby
    @Published var spaceFilter: SpaceFilter = .all
    @Published var savedSpaces: Set<UUID> = []

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

    // Zakat — haul countdown
    // Haul began 12 Rabiulawal 1447; completes 25 August 2026 (per prototype).
    let haulStart = AppState.makeDate(2025, 9, 5)      // ~ start
    let haulEnd   = AppState.makeDate(2026, 8, 25)     // completion
    let haulDay   = 339
    let haulTotalDays = 354

    private var timer: AnyCancellable?

    init() {
        start()
    }

    func start() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in self?.now = date }
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
    var gregorianLong: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE d MMMM yyyy"
        return f.string(from: now)
    }

    /// Hijri date as computed (Umm al-Qura). Note: MUIS uses an observed calendar,
    /// so this can differ by ±1 day — treat as indicative until wired to MUIS.
    var hijriString: String {
        var cal = Calendar(identifier: .islamicUmmAlQura)
        cal.locale = Locale(identifier: "en")
        let f = DateFormatter()
        f.calendar = cal
        f.locale = Locale(identifier: "en")
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: now)
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

    var filteredSpaces: [PrayerSpace] {
        let list = SampleData.spaces.sorted { $0.walkMinutes < $1.walkMinutes }
        switch spaceFilter {
        case .all:      return list
        case .musollah: return list.filter { $0.type == .musollah || $0.type == .prayerRoom }
        case .masjid:   return list.filter { $0.type == .masjid }
        }
    }

    var nearestSpace: PrayerSpace {
        SampleData.spaces.min { $0.walkMinutes < $1.walkMinutes } ?? SampleData.spaces[0]
    }

    func toggleSave(_ space: PrayerSpace) {
        if savedSpaces.contains(space.id) { savedSpaces.remove(space.id) }
        else { savedSpaces.insert(space.id) }
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

    // MARK: - Zakat haul countdown

    var haulCountdown: String {
        let secs = max(0, Int(haulEnd.timeIntervalSince(now)))
        let d = secs / 86400
        let h = (secs % 86400) / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        return String(format: "%dd %02dh %02dm %02ds", d, h, m, s)
    }

    var haulFraction: Double { Double(haulDay) / Double(haulTotalDays) }

    // MARK: - Helpers

    static func makeDate(_ y: Int, _ mo: Int, _ d: Int) -> Date {
        var c = DateComponents(); c.year = y; c.month = mo; c.day = d; c.hour = 12
        return Calendar.current.date(from: c) ?? Date()
    }
}
