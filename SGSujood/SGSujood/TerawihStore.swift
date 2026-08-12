import Foundation
import CoreLocation
import Combine

// Terawih venues — remote-configurable (same pattern as SpacesStore / NisabStore).
// A curated list of mosques/spaces conducting terawih, updated nearer Ramadan from a
// workbook. No rakaat counts or start times. If empty, the app falls back to the nearest
// mosques in the main directory.

struct TerawihVenue: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let address: String?
    let note: String?
    let lat: Double?
    let lng: Double?

    var location: CLLocation? {
        guard let lat, let lng else { return nil }
        return CLLocation(latitude: lat, longitude: lng)
    }
}

struct TerawihPayload: Decodable {
    let venues: [TerawihVenue]
    let updated: String?
}

@MainActor
final class TerawihStore: ObservableObject {

    /// Hosted config (GitHub raw). Regenerated from the terawih workbook.
    static let remoteURL = URL(string: "https://raw.githubusercontent.com/blueyeagle/SG-Sujood/main/terawih.json")

    @Published private(set) var venues: [TerawihVenue] = []
    @Published private(set) var updated: String?

    private static let cacheURL: URL = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("terawih_cache.json")
    }()

    init() {
        if let p = Self.decode(fileURL: Self.cacheURL) ?? Self.loadBundled() {
            venues = p.venues; updated = p.updated
        }
    }

    func refresh() async {
        guard let url = Self.remoteURL else { return }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 15
            req.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return }
            let payload = try JSONDecoder().decode(TerawihPayload.self, from: data)
            venues = payload.venues
            updated = payload.updated
            try? data.write(to: Self.cacheURL, options: .atomic)
        } catch {
            // keep cached / bundled list
        }
    }

    /// Venues sorted by distance from `origin` (unlocatable last).
    func sorted(from origin: CLLocation) -> [TerawihVenue] {
        venues.sorted {
            ($0.location?.distance(from: origin) ?? .greatestFiniteMagnitude)
                < ($1.location?.distance(from: origin) ?? .greatestFiniteMagnitude)
        }
    }

    private static func loadBundled() -> TerawihPayload? {
        guard let url = Bundle.main.url(forResource: "terawih", withExtension: "json") else { return nil }
        return decode(fileURL: url)
    }
    private static func decode(fileURL: URL) -> TerawihPayload? {
        guard let data = try? Data(contentsOf: fileURL),
              let p = try? JSONDecoder().decode(TerawihPayload.self, from: data) else { return nil }
        return p
    }
}
