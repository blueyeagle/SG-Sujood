import Foundation
import Combine

// MARK: - Prayer times — remote-configurable
//
// The app ships MUIS's 2026 timetable bundled (prayer_times_2026.json) so it works fully
// offline. But that data covers ONE year — without this store the app would have no prayer
// times from 1 Jan 2027. This store pulls a hosted feed that can carry additional years, so a
// new year's timetable goes live by editing one JSON file — no App Store release, no reinstall.
//
// The hosted `prayer_times.json` is a flat array of the same day records as the bundled file,
// spanning every year MUIS has published. Resolution at launch: bundled seed → cached last-good
// remote → fresh remote (each simply merges by date over the previous, in PrayerData.byDate).

@MainActor
final class PrayerTimesStore: ObservableObject {

    /// Hosted feed, served by the data Worker (see RemoteConfig).
    static let remoteURL = RemoteConfig.url("prayer_times.json")

    enum Origin: String { case bundled, cached, remote }

    @Published private(set) var origin: Origin = .bundled
    @Published private(set) var lastRefreshed: Date?
    /// Distinct calendar years the app currently has data for (bundled + merged).
    @Published private(set) var coveredYears: [String] = []

    private static let cacheURL: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("prayer_times_cache.json")
    }()

    init() {
        // PrayerData.byDate is already seeded from the bundled year(s) on first access. Layer the
        // last good remote payload (if any) on top so we open with the widest coverage offline.
        if let cached = Self.decode(fileURL: Self.cacheURL), Self.isSane(cached) {
            PrayerData.merge(cached)
            origin = .cached
        }
        recomputeCoverage()
    }

    /// Fetch the remote feed; adopt it only if it decodes and passes a sanity check.
    func refresh() async {
        guard let url = Self.remoteURL else { return }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 12
            req.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return }
            let rows = try JSONDecoder().decode([DayTimes].self, from: data)
            guard Self.isSane(rows) else { return }
            PrayerData.merge(rows)
            origin = .remote
            lastRefreshed = Date()
            recomputeCoverage()
            try? data.write(to: Self.cacheURL, options: .atomic)   // cache last good
        } catch {
            // Offline / blocked / bad payload → keep the bundled + cached data we already have.
        }
    }

    // MARK: - Helpers

    private func recomputeCoverage() {
        let years = Set(PrayerData.byDate.keys.compactMap { $0.split(separator: "-").first.map(String.init) })
        coveredYears = years.sorted()
    }

    /// A payload is sane if it has a plausible number of days and the first record parses as a
    /// full day of "HH:mm" times. Guards against adopting an empty or malformed file.
    private static func isSane(_ rows: [DayTimes]) -> Bool {
        guard rows.count >= 28 else { return false }        // at least a month
        let r = rows[0]
        let fields = [r.subuh, r.syuruk, r.zohor, r.asar, r.maghrib, r.isyak]
        return r.d.count == 10 && fields.allSatisfy { $0.contains(":") }
    }

    private static func decode(fileURL: URL) -> [DayTimes]? {
        guard let data = try? Data(contentsOf: fileURL),
              let rows = try? JSONDecoder().decode([DayTimes].self, from: data)
        else { return nil }
        return rows
    }
}
