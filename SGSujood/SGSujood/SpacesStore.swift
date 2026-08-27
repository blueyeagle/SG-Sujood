import Foundation
import CoreLocation
import Combine

// MARK: - Prayer spaces — remote-configurable (same pattern as NisabStore)
//
// The list is compiled from the "SG Prayer Spaces" workbook (MUIS mosque directory +
// community musollah sources), geocoded via OneMap. The app reads a JSON you host so the
// directory can be updated without an App Store release.

struct SpaceRecord: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String          // "masjid" | "musollah"
    let type: String              // "Masjid" / "Mall" / "Hotel" / "Office" / "Surau" …
    let regionGroup: String?
    let area: String?
    let address: String?
    let postal: String?
    let floor: String?
    let genderSegregated: Bool?
    let facilities: String?
    let access: String?
    let capacity: String?
    let yearEst: String?
    let heritage: String?
    let notes: String?
    let lat: Double?
    let lng: Double?

    static func == (a: SpaceRecord, b: SpaceRecord) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }

    var isMosque: Bool { category == "masjid" }
    var coordinate: CLLocationCoordinate2D? {
        guard let lat, let lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    var location: CLLocation? {
        guard let lat, let lng else { return nil }
        return CLLocation(latitude: lat, longitude: lng)
    }
    /// Region normalised for display ("Central / City Area" → "Central").
    var region: String {
        guard let r = regionGroup else { return "" }
        if r.contains("Central") { return "Central" }
        if r == "Non-MUIS Managed" { return "Other" }
        return r
    }
    /// Short label under the name, e.g. "Musollah · L7 staircase" or "Masjid · 500 pax".
    var subtitle: String {
        if isMosque {
            var bits: [String] = ["Masjid"]
            if let heritage { bits.append(heritage) }
            else if let capacity { bits.append("\(capacity) pax") }
            return bits.joined(separator: " · ")
        } else {
            var bits: [String] = [type]
            if let floor, !floor.isEmpty { bits.append(floor) }
            return bits.joined(separator: " · ")
        }
    }
}

struct SpacesPayload: Decodable {
    let spaces: [SpaceRecord]
    let source: String?
    let updated: String?
    let count: Int?
}

@MainActor
final class SpacesStore: ObservableObject {

    /// Hosted directory, served by the data Worker (see RemoteConfig). Update spaces.json in the
    /// repo to change the in-app list without an App Store release.
    static let remoteURL = RemoteConfig.url("spaces.json")

    enum Origin: String { case bundled, cached, remote }

    @Published private(set) var spaces: [SpaceRecord]
    @Published private(set) var origin: Origin
    @Published private(set) var updated: String?

    private static let cacheURL: URL = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("spaces_cache.json")
    }()

    init() {
        if let cached = Self.decode(fileURL: Self.cacheURL) {
            spaces = cached.spaces; updated = cached.updated; origin = .cached
        } else if let bundled = Self.loadBundled() {
            spaces = bundled.spaces; updated = bundled.updated; origin = .bundled
        } else {
            spaces = []; origin = .bundled
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
            let payload = try JSONDecoder().decode(SpacesPayload.self, from: data)
            guard payload.spaces.count >= 1 else { return }
            spaces = payload.spaces
            updated = payload.updated
            origin = .remote
            try? data.write(to: Self.cacheURL, options: .atomic)
        } catch {
            // Offline / blocked / bad payload → keep bundled or cached list.
        }
    }

    // MARK: - Queries

    func filtered(_ filter: AppState.SpaceFilter) -> [SpaceRecord] {
        switch filter {
        case .all:      return spaces
        case .musollah: return spaces.filter { $0.category == "musollah" }
        case .masjid:   return spaces.filter { $0.category == "masjid" }
        }
    }

    /// Spaces sorted by distance from `origin`, nearest first (unlocatable spaces last).
    func sortedByDistance(from origin: CLLocation, filter: AppState.SpaceFilter) -> [SpaceRecord] {
        filtered(filter).sorted { a, b in
            let da = a.location?.distance(from: origin) ?? .greatestFiniteMagnitude
            let db = b.location?.distance(from: origin) ?? .greatestFiniteMagnitude
            return da < db
        }
    }

    func nearest(to origin: CLLocation) -> SpaceRecord? {
        spaces.compactMap { s -> (SpaceRecord, CLLocationDistance)? in
            guard let l = s.location else { return nil }
            return (s, l.distance(from: origin))
        }.min { $0.1 < $1.1 }?.0
    }

    // MARK: - Loading helpers

    private static func loadBundled() -> SpacesPayload? {
        guard let url = Bundle.main.url(forResource: "spaces", withExtension: "json") else { return nil }
        return decode(fileURL: url)
    }
    private static func decode(fileURL: URL) -> SpacesPayload? {
        guard let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder().decode(SpacesPayload.self, from: data) else { return nil }
        return payload
    }
}

// MARK: - Walking-distance helpers

enum Walk {
    /// Rough walking minutes from metres (≈ 80 m/min).
    static func minutes(_ metres: CLLocationDistance) -> Int { max(1, Int((metres / 80).rounded())) }
    static func label(_ metres: CLLocationDistance) -> String {
        metres >= 2000 ? String(format: "%.1f km", metres / 1000) : "\(minutes(metres)) min"
    }
}
