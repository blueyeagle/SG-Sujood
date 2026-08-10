import Foundation

// Prayer times are REAL (MUIS 2026 timetable — see PrayerData / prayer_times_2026.json).
// The rest below is placeholder, plausible but unverified — see README "Content caveats":
// nisab should come from the MUIS daily kadar nisab and spaces from a moderated database.

enum SampleData {

    // Fallback waktu clock used only for dates outside the bundled 2026 dataset. (h, m, isPM)
    static let waktuClock: [WaktuRow: (Int, Int, Bool)] = [
        .subuh:   (5, 44, false),
        .syuruk:  (7, 7,  false),
        .zohor:   (1, 9,  true),
        .asar:    (4, 32, true),
        .maghrib: (7, 11, true),
        .isyak:   (8, 25, true),
    ]

    static let location = "Orchard, Singapore"

    // MARK: - Sunnah rawatib (Shafi'i, as practised in Singapore)

    static let sunnah: [WaktuRow: [Sunnah]] = [
        .subuh: [
            Sunnah(position: "Before", rakaat: "2", rank: "Muakkad",
                   niat: "Usalli sunnatas Subhi rak'ataini qabliyyatan lillahi ta'ala.",
                   meaning: "I intend to pray the sunnah of Subuh, two rakaat, before, for Allah Ta'ala.")
        ],
        .syuruk: [
            Sunnah(position: "Dhuha, after", rakaat: "2–8", rank: "—",
                   niat: "Usalli sunnatad Dhuha rak'ataini lillahi ta'ala.",
                   meaning: "I intend to pray the sunnah of Dhuha, two rakaat, for Allah Ta'ala.")
        ],
        .zohor: [
            Sunnah(position: "Before", rakaat: "2 or 4", rank: "Muakkad",
                   niat: "Usalli sunnataz Zuhri rak'ataini qabliyyatan lillahi ta'ala.",
                   meaning: "I intend to pray the sunnah of Zohor, two rakaat, before, for Allah Ta'ala."),
            Sunnah(position: "After", rakaat: "2", rank: "Muakkad",
                   niat: "Usalli sunnataz Zuhri rak'ataini ba'diyyatan lillahi ta'ala.",
                   meaning: "I intend to pray the sunnah of Zohor, two rakaat, after, for Allah Ta'ala.")
        ],
        .asar: [
            Sunnah(position: "Before", rakaat: "2 or 4", rank: "Ghair muakkad",
                   niat: "Usalli sunnatal 'Asri rak'ataini qabliyyatan lillahi ta'ala.",
                   meaning: "I intend to pray the sunnah of Asar, two rakaat, before, for Allah Ta'ala.")
        ],
        .maghrib: [
            Sunnah(position: "Before", rakaat: "2", rank: "Ghair muakkad",
                   niat: "Usalli sunnatal Maghribi rak'ataini qabliyyatan lillahi ta'ala.",
                   meaning: "I intend to pray the sunnah of Maghrib, two rakaat, before, for Allah Ta'ala."),
            Sunnah(position: "After", rakaat: "2", rank: "Muakkad",
                   niat: "Usalli sunnatal Maghribi rak'ataini ba'diyyatan lillahi ta'ala.",
                   meaning: "I intend to pray the sunnah of Maghrib, two rakaat, after, for Allah Ta'ala.")
        ],
        .isyak: [
            Sunnah(position: "Before", rakaat: "2", rank: "Ghair muakkad",
                   niat: "Usalli sunnatal 'Isyaa'i rak'ataini qabliyyatan lillahi ta'ala.",
                   meaning: "I intend to pray the sunnah of Isyak, two rakaat, before, for Allah Ta'ala."),
            Sunnah(position: "After", rakaat: "2", rank: "Muakkad",
                   niat: "Usalli sunnatal 'Isyaa'i rak'ataini ba'diyyatan lillahi ta'ala.",
                   meaning: "I intend to pray the sunnah of Isyak, two rakaat, after, for Allah Ta'ala.")
        ],
    ]

    static func sunnahSummary(for row: WaktuRow) -> String {
        switch row {
        case .subuh:   return "SUNNAH · 2 rakaat before"
        case .syuruk:  return "SUNNAH · Dhuha 2–8 rakaat after"
        case .zohor:   return "SUNNAH · 2 or 4 before · 2 after"
        case .asar:    return "SUNNAH · 2 or 4 before"
        case .maghrib: return "SUNNAH · 2 before · 2 after"
        case .isyak:   return "SUNNAH · 2 before · 2 after"
        }
    }

    static func subNote(for row: WaktuRow) -> String {
        switch row {
        case .subuh:   return "Dawn"
        case .syuruk:  return "Sunrise — not a prayer time"
        case .zohor:   return "Jumu'ah on Friday"
        case .asar:    return "Afternoon"
        case .maghrib: return "Short window — about 74 minutes"
        case .isyak:   return "Night"
        }
    }

    // MARK: - Prayer spaces

    static let spaces: [PrayerSpace] = [
        PrayerSpace(name: "ION Orchard", type: .musollah,
                    floorLandmark: "B4, beside Food Opera", floorBadge: "B4",
                    landmarkSentence: "Beside Food Opera, past the service lift lobby",
                    walkMinutes: 3, originFrom: "From Orchard MRT, exit E",
                    address: "2 Orchard Turn", closing: "open until 10.00pm",
                    confirmedDaysAgo: 2, openNow: true, jumuah: nil,
                    steps: [
                        "Take the escalator down to B4 from the Basement 2 atrium.",
                        "Walk past Food Opera towards the service corridor on your left.",
                        "The musollah is the second door, signed in Malay and English."
                    ]),
        PrayerSpace(name: "Wisma Atria", type: .musollah,
                    floorLandmark: "L5, service corridor", floorBadge: "L5",
                    landmarkSentence: "Level 5, along the service corridor past the offices",
                    walkMinutes: 4, originFrom: "From Orchard MRT, exit B",
                    address: "435 Orchard Road", closing: "open until 10.00pm",
                    confirmedDaysAgo: 6, openNow: true, jumuah: nil, steps: [
                        "Take the lift to Level 5.",
                        "Turn right towards the service corridor.",
                        "The prayer room is at the end on the left."
                    ]),
        PrayerSpace(name: "Ngee Ann City", type: .musollah,
                    floorLandmark: "B2, carpark lift lobby C", floorBadge: "B2",
                    landmarkSentence: "Basement 2, by carpark lift lobby C",
                    walkMinutes: 5, originFrom: "From Orchard MRT, exit D",
                    address: "391 Orchard Road", closing: "open until 9.30pm",
                    confirmedDaysAgo: 21, openNow: true, jumuah: nil, steps: [
                        "Head to Basement 2 via the Takashimaya lifts.",
                        "Follow signs to carpark lift lobby C.",
                        "The musollah is beside the lobby."
                    ]),
        PrayerSpace(name: "Masjid Al-Falah", type: .masjid,
                    floorLandmark: "22 Bideford Road", floorBadge: "G",
                    landmarkSentence: "Inside the Cuppage building, ground and upper floors",
                    walkMinutes: 6, originFrom: "From Somerset MRT, exit B",
                    address: "22 Bideford Road", closing: "open for all waktu",
                    confirmedDaysAgo: 4, openNow: true,
                    jumuah: "Jumu'ah 12.30 pm and 1.45 pm", steps: [
                        "Walk down Bideford Road from Orchard.",
                        "Enter through the main entrance on the ground floor.",
                        "The main prayer hall is one level up."
                    ]),
        PrayerSpace(name: "Paragon", type: .musollah,
                    floorLandmark: "B1, near the taxi stand", floorBadge: "B1",
                    landmarkSentence: "Basement 1, tucked behind the taxi stand lobby",
                    walkMinutes: 8, originFrom: "From Orchard MRT, exit E",
                    address: "290 Orchard Road", closing: "open until 9.30pm",
                    confirmedDaysAgo: 12, openNow: true, jumuah: nil, steps: [
                        "Go to Basement 1.",
                        "Walk towards the taxi stand.",
                        "The prayer room is behind the lobby, signed."
                    ]),
    ]

    // MARK: - Dzikir presets

    static let dzikir: [DzikirPhrase] = [
        DzikirPhrase(name: "Subhanallah",    meaning: "Glory be to Allah",     target: 33),
        DzikirPhrase(name: "Alhamdulillah",  meaning: "Praise be to Allah",    target: 33),
        DzikirPhrase(name: "Allahu Akbar",   meaning: "Allah is the Greatest", target: 34),
        DzikirPhrase(name: "Astaghfirullah", meaning: "I seek Allah's forgiveness", target: 100),
    ]

    // Zakat nisab is real & remote-configurable — see NisabStore / nisab.json.

    // MARK: - Ramadan

    static let terawih: [TerawihEntry] = [
        TerawihEntry(mosque: "Masjid Al-Falah", detail: "20 rakaat · 8.30 pm", walkMinutes: 6),
        TerawihEntry(mosque: "Masjid Sultan",   detail: "8 rakaat · 8.15 pm",  walkMinutes: 14),
    ]

    // MARK: - Qibla

    static let qiblaBearing: Double = 293   // degrees from true north, Singapore → Makkah
}
