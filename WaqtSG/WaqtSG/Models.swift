import Foundation

// MARK: - Prayers

enum Prayer: String, CaseIterable, Identifiable, Codable {
    case subuh   = "Subuh"
    case zohor   = "Zohor"
    case asar    = "Asar"
    case maghrib = "Maghrib"
    case isyak   = "Isyak"

    var id: String { rawValue }

    /// The five fardhu, in order.
    static var fardhu: [Prayer] { allCases }
}

/// A row on the timetable — includes Syuruk (sunrise, not a prayer).
enum WaktuRow: String, CaseIterable, Identifiable {
    case subuh   = "Subuh"
    case syuruk  = "Syuruk"
    case zohor   = "Zohor"
    case asar    = "Asar"
    case maghrib = "Maghrib"
    case isyak   = "Isyak"

    var id: String { rawValue }
    var isPrayer: Bool { self != .syuruk }
    var prayer: Prayer? { Prayer(rawValue: rawValue) }
}

enum PrayerStatus: String, Codable {
    case pending, done, missed

    /// Mark → Done → Missed → Mark
    var next: PrayerStatus {
        switch self {
        case .pending: return .done
        case .done:    return .missed
        case .missed:  return .pending
        }
    }
    var label: String {
        switch self {
        case .pending: return "Mark"
        case .done:    return "Done"
        case .missed:  return "Missed"
        }
    }
}

// MARK: - Sunnah rawatib

struct Sunnah: Identifiable {
    let id = UUID()
    let position: String        // "Before" / "After" / "Dhuha, after"
    let rakaat: String          // "2", "2–8", "2 or 4"
    let rank: String            // "Muakkad" / "Ghair muakkad" / "—"
    let niat: String            // transliteration
    let meaning: String
}

// MARK: - Prayer spaces

enum SpaceType: String, CaseIterable, Codable {
    case musollah = "Musollah"
    case masjid   = "Masjid"
    case prayerRoom = "Prayer room"
}

struct PrayerSpace: Identifiable, Hashable {
    static func == (lhs: PrayerSpace, rhs: PrayerSpace) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    let id = UUID()
    let name: String
    let type: SpaceType
    let floorLandmark: String      // "B4, beside Food Opera"
    let floorBadge: String         // "B4"
    let landmarkSentence: String   // "Beside Food Opera, past the service lift lobby"
    let walkMinutes: Int
    let originFrom: String         // "From Orchard MRT, exit E"
    let address: String
    let closing: String            // "open until 10.00pm"
    let confirmedDaysAgo: Int
    let openNow: Bool
    let jumuah: String?            // "Jumu'ah 12.30 pm and 1.45 pm"
    let steps: [String]            // getting-there steps
}

// MARK: - Terawih (Ramadan)

struct TerawihEntry: Identifiable {
    let id = UUID()
    let mosque: String
    let detail: String   // "20 rakaat · 8.30 pm"
    let walkMinutes: Int
}

// MARK: - Dzikir

struct DzikirPhrase: Identifiable {
    let id = UUID()
    let name: String       // "Subhanallah"
    let meaning: String    // "Glory be to Allah"
    let target: Int
}

// Zakat nisab is modelled in NisabStore (NisabInfo / NisabPayload), loaded from
// nisab.json and refreshed from the remote config URL.
