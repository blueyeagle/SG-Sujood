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

    // Prayer spaces are real & remote-configurable — see SpacesStore / spaces.json.

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

    // Ramadan intentions & du'a (Shafi'i, as commonly practised in Singapore).
    // Have wording reviewed by a religious authority before shipping; consider adding Arabic script.
    static let ramadanNiat: [Niat] = [
        Niat(title: "Daily fast · nightly intention",
             transliteration: "Nawaitu sauma ghadin 'an adaa'i fardhi syahri Ramadhaana haadzihis sanati lillaahi ta'aala.",
             meaning: "I intend to fast tomorrow to fulfil the obligation of the month of Ramadan this year, for Allah Ta'ala."),
        Niat(title: "Whole month · first night",
             transliteration: "Nawaitu sauma jamii'i syahri Ramadhaana haadzihis sanati lillaahi ta'aala.",
             meaning: "I intend to fast the entire month of Ramadan this year, for Allah Ta'ala — a recommended intention on the first night, made alongside the nightly niat."),
        Niat(title: "Breaking fast · doa berbuka",
             transliteration: "Allaahumma laka sumtu wa bika aamantu wa 'alaa rizqika aftartu, birahmatika yaa arhamar raahimiin.",
             meaning: "O Allah, for You I fasted, in You I believe, and with Your provision I break my fast; by Your mercy, O Most Merciful of the merciful."),
    ]

    // MARK: - Qibla

    static let qiblaBearing: Double = 293   // degrees from true north, Singapore → Makkah
}
