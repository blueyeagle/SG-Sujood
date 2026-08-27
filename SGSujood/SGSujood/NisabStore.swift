import Foundation
import Combine

// MARK: - Nisab (kadar nisab) — remote-configurable
//
// MUIS publishes the nisab (value of 86 g of gold) MONTHLY on zakat.sg. There is no public
// API, and the site blocks automated scraping, so the app does not scrape it directly.
// Instead it reads a small JSON you host yourself and can update without an App Store release.
//
// Resolution order at launch: cached (last good remote) → bundled seed. Then an async refresh
// from `remoteURL` supersedes both if it succeeds and validates.
//
// To wire it up: host a file matching `nisab.json`'s schema and set `remoteURL` below.

struct NisabInfo: Codable, Equatable {
    var value: Double        // SGD, the nisab threshold (86 g gold)
    var month: String        // e.g. "May 2026" — the month MUIS published this figure for
    var effectiveFrom: String // "yyyy-MM-dd"

    var formatted: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        let n = f.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "$\(n)"
    }
}

struct NisabPayload: Codable {
    var current: NisabInfo
    var history: [NisabInfo]
    var source: String?
    var updated: String?
}

@MainActor
final class NisabStore: ObservableObject {

    /// Hosted config, served by the data Worker (see RemoteConfig). Update nisab.json in the
    /// blueyeagle/SG-Sujood repo to push a new figure without an App Store release. Until the
    /// Worker/file is reachable, this fails and the app falls back to the cached/bundled seed.
    static let remoteURL = RemoteConfig.url("nisab.json")

    enum Origin: String { case bundled, cached, remote }

    @Published private(set) var current: NisabInfo
    @Published private(set) var history: [NisabInfo]
    @Published private(set) var origin: Origin
    @Published private(set) var lastRefreshed: Date?

    private static let cacheURL: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("nisab_cache.json")
    }()

    init() {
        if let cached = Self.decode(fileURL: Self.cacheURL) {
            current = cached.current; history = cached.history; origin = .cached
        } else if let bundled = Self.loadBundled() {
            current = bundled.current; history = bundled.history; origin = .bundled
        } else {
            // Last-resort seed: last MUIS figure known at build time (May 2026).
            current = NisabInfo(value: 17017, month: "May 2026", effectiveFrom: "2026-05-01")
            history = []
            origin = .bundled
        }
    }

    /// Fetch the remote config; only adopts it if it decodes and passes a sanity check.
    func refresh() async {
        guard let url = Self.remoteURL else { return }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 12
            req.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return }
            let payload = try JSONDecoder().decode(NisabPayload.self, from: data)
            guard Self.isSane(payload.current) else { return }
            current = payload.current
            history = payload.history
            origin = .remote
            lastRefreshed = Date()
            try? data.write(to: Self.cacheURL, options: .atomic)   // cache last good
        } catch {
            // Offline / blocked / bad payload → keep whatever we already have.
        }
    }

    // MARK: - Helpers

    private static func isSane(_ info: NisabInfo) -> Bool {
        info.value >= 1_000 && info.value <= 1_000_000
    }

    private static func loadBundled() -> NisabPayload? {
        guard let url = Bundle.main.url(forResource: "nisab", withExtension: "json") else { return nil }
        return decode(fileURL: url)
    }

    private static func decode(fileURL: URL) -> NisabPayload? {
        guard let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder().decode(NisabPayload.self, from: data),
              isSane(payload.current) else { return nil }
        return payload
    }
}
