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
// The live directory is modelled in SpacesStore (SpaceRecord), loaded from spaces.json.
// SpaceType is kept for the "Add a space" form's type picker.

enum SpaceType: String, CaseIterable, Codable {
    case musollah = "Musollah"
    case masjid   = "Masjid"
    case prayerRoom = "Prayer room"
}

// MARK: - Niat / du'a (transliteration + meaning)

struct Niat: Identifiable {
    let id = UUID()
    let title: String
    let transliteration: String
    let meaning: String
}

// A titled group of niat (e.g. "Solat Sunat") for the Niat Solat reference page.
struct NiatGroup: Identifiable {
    let id = UUID()
    let title: String
    let note: String?
    let items: [Niat]
    init(_ title: String, note: String? = nil, _ items: [Niat]) {
        self.title = title; self.note = note; self.items = items
    }
}

// Terawih venues are modelled in TerawihStore (TerawihVenue), loaded from terawih.json.

// MARK: - Dzikir

struct DzikirPhrase: Identifiable {
    let id = UUID()
    let name: String       // "Subhanallah"
    let meaning: String    // "Glory be to Allah"
    let target: Int
}

// Zakat nisab is modelled in NisabStore (NisabInfo / NisabPayload), loaded from
// nisab.json and refreshed from the remote config URL.
