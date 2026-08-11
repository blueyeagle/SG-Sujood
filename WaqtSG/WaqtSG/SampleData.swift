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

    // MARK: - Dua Qunut (recited in the second rakaat of Subuh, Shafi'i)
    static let duaQunut = Niat(
        title: "Dua Qunut · in the i'tidal of the second rakaat",
        transliteration: "Allahummahdini fiman hadait, wa 'afini fiman 'afait, wa tawallani fiman tawallait, wa barik li fima a'tait, wa qini syarra ma qadhait, fa innaka taqdhi wa la yuqdha 'alaik, wa innahu la yazillu man walait, wa la ya'izzu man 'adait, tabarakta rabbana wa ta'alait, falakal hamdu 'ala ma qadhait, astaghfiruka wa atubu ilaik, wa sallallahu 'ala sayyidina Muhammadin nabiyyil ummiyyi wa 'ala alihi wa sahbihi wa sallam.",
        meaning: "O Allah, guide me among those You have guided, grant me wellbeing among those You have granted wellbeing, take me into Your charge among those You have taken into Your charge, bless me in what You have given, and protect me from the evil of what You have decreed. For You decree and none decrees over You; none is disgraced whom You befriend, and none is honoured whom You oppose. Blessed and Exalted are You, our Lord. All praise is Yours for what You decree; I seek Your forgiveness and turn to You in repentance. May Allah bless our master Muhammad, the unlettered Prophet, and his family and companions.")

    // MARK: - Doa & dhikr after solat (Shafi'i, as commonly practised in Singapore)
    static let afterSolatDua: [Niat] = [
        Niat(title: "Istighfar · ×3",
             transliteration: "Astaghfirullahal 'azim, alladzi la ilaha illa huwal hayyul qayyum, wa atubu ilaih.",
             meaning: "I seek forgiveness from Allah the Magnificent, besides whom there is no god, the Ever-Living, the Sustainer, and I turn to Him in repentance."),
        Niat(title: "Recognising Allah as peace",
             transliteration: "Allahumma antas-salam, wa minkas-salam, tabarakta ya dzal jalali wal ikram.",
             meaning: "O Allah, You are Peace and from You comes peace. Blessed are You, O Owner of Majesty and Honour."),
        Niat(title: "Tasbih · after every prayer",
             transliteration: "Subhanallah (×33), Alhamdulillah (×33), Allahu Akbar (×33) — then: La ilaha illallah wahdahu la syarika lah, lahul mulku wa lahul hamdu wa huwa 'ala kulli syai'in qadir.",
             meaning: "Glory be to Allah (×33), praise be to Allah (×33), Allah is the Greatest (×33) — then: there is no god but Allah alone, without partner; His is the dominion and His the praise, and He has power over all things."),
        Niat(title: "Help to remember and worship",
             transliteration: "Allahumma a'inni 'ala dzikrika wa syukrika wa husni 'ibadatik.",
             meaning: "O Allah, help me to remember You, to thank You, and to worship You in the best manner."),
        Niat(title: "Good in both worlds",
             transliteration: "Rabbana atina fid-dunya hasanah, wa fil akhirati hasanah, wa qina 'adzaban-nar.",
             meaning: "Our Lord, grant us good in this world and good in the Hereafter, and protect us from the punishment of the Fire."),
        Niat(title: "Protection & steadfastness",
             transliteration: "Rabbana la tuzigh qulubana ba'da idz hadaitana wa hab lana min ladunka rahmah, innaka antal wahhab.",
             meaning: "Our Lord, let not our hearts deviate after You have guided us, and grant us mercy from Yourself; verily You are the Bestower."),
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
