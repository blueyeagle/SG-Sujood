import Foundation

// Niat Solat reference (Shafi'i, as commonly practised in Singapore/Malaysia).
// Transliterations are the widely-published forms; have the wording — especially the
// jamak/qasar case endings — reviewed by a religious authority before public release.
// Add "ma'muman" (as makmum) or "imaman" (as imam) for congregational prayer where relevant.

extension SampleData {
    static let niatSolat: [NiatGroup] = [

        NiatGroup("Solat Jumaat", [
            Niat(title: "Jumaat",
                 transliteration: "Usalli fardal Jumu'ati rak'ataini ma'muman lillahi ta'ala.",
                 meaning: "I intend to pray the obligatory Jumu'ah prayer, two rakaat, as a follower (makmum), for Allah Ta'ala."),
        ]),

        NiatGroup("Solat Jenazah", note: "Four takbir; fardhu kifayah.", [
            Niat(title: "Jenazah lelaki (male)",
                 transliteration: "Usalli 'ala haazal mayyiti arba'a takbiraatin fardhal kifaayati ma'muman lillahi ta'ala.",
                 meaning: "I intend to pray over this deceased man, four takbir, as a communal obligation, as a follower, for Allah Ta'ala."),
            Niat(title: "Jenazah perempuan (female)",
                 transliteration: "Usalli 'ala haazihil mayyitati arba'a takbiraatin fardhal kifaayati ma'muman lillahi ta'ala.",
                 meaning: "I intend to pray over this deceased woman, four takbir, as a communal obligation, as a follower, for Allah Ta'ala."),
        ]),

        NiatGroup("Qada Solat", note: "For making up a missed obligatory prayer.", [
            Niat(title: "Subuh",   transliteration: "Usalli fardas Subhi rak'ataini qadaa'an lillahi ta'ala.",
                 meaning: "I intend to pray the fardhu of Subuh, two rakaat, as qada (make-up), for Allah Ta'ala."),
            Niat(title: "Zuhur",   transliteration: "Usalli fardaz Zuhri arba'a raka'atin qadaa'an lillahi ta'ala.",
                 meaning: "I intend to pray the fardhu of Zuhur, four rakaat, as qada, for Allah Ta'ala."),
            Niat(title: "Asar",    transliteration: "Usalli fardal 'Asri arba'a raka'atin qadaa'an lillahi ta'ala.",
                 meaning: "I intend to pray the fardhu of Asar, four rakaat, as qada, for Allah Ta'ala."),
            Niat(title: "Maghrib", transliteration: "Usalli fardal Maghribi thalatha raka'atin qadaa'an lillahi ta'ala.",
                 meaning: "I intend to pray the fardhu of Maghrib, three rakaat, as qada, for Allah Ta'ala."),
            Niat(title: "Isyak",   transliteration: "Usalli fardal 'Isyaa'i arba'a raka'atin qadaa'an lillahi ta'ala.",
                 meaning: "I intend to pray the fardhu of Isyak, four rakaat, as qada, for Allah Ta'ala."),
        ]),

        NiatGroup("Solat Jamak & Qasar", note: "Jamak (combining) with qasar (shortening to two rakaat) — for travellers who meet the conditions. Maghrib keeps three rakaat. Wording per akuislam.com.", [
            Niat(title: "Jamak Taqdim — Zohor (at Zohor time)",
                 transliteration: "Usolli fardol Zuhri qosron rak'ataini jama'a takdiimin lillahi taala.",
                 meaning: "I intend to pray the fardhu of Zohor, shortened to two rakaat, combined and advanced (jamak taqdim), for Allah Ta'ala."),
            Niat(title: "Jamak Taqdim — Asar",
                 transliteration: "Usolli fardol 'Asri qosron rak'ataini jama'a takdiimin lillahi taala.",
                 meaning: "I intend to pray the fardhu of Asar, shortened to two rakaat, combined and advanced (jamak taqdim), for Allah Ta'ala."),
            Niat(title: "Jamak Takhir — Asar (prayed first, at Asar time)",
                 transliteration: "Usolli fardol 'Asri qosron rak'ataini jam'a takhirin lillahi taala.",
                 meaning: "I intend to pray the fardhu of Asar, shortened to two rakaat, combined and delayed (jamak takhir), for Allah Ta'ala."),
            Niat(title: "Jamak Takhir — Zohor",
                 transliteration: "Usolli fardol Zuhri qosron rak'ataini jam'a takhirin lillahi taala.",
                 meaning: "I intend to pray the fardhu of Zohor, shortened to two rakaat, combined and delayed (jamak takhir), for Allah Ta'ala."),
            Niat(title: "Jamak Taqdim — Maghrib (at Maghrib time)",
                 transliteration: "Usolli fardol Maghribi salasa raka'atin jama'a takdiimin lillahi taala.",
                 meaning: "I intend to pray the fardhu of Maghrib, three rakaat (not shortened), combined and advanced (jamak taqdim), for Allah Ta'ala."),
            Niat(title: "Jamak Taqdim — Isyak",
                 transliteration: "Usolli fardol Isya'i qosron rak'ataini jama'a takdiimin lillahi taala.",
                 meaning: "I intend to pray the fardhu of Isyak, shortened to two rakaat, combined and advanced (jamak taqdim), for Allah Ta'ala."),
            Niat(title: "Jamak Takhir — Isyak (prayed first, at Isyak time)",
                 transliteration: "Usolli fardol Isya'i qosron rak'ataini jama'a takhirin lillahi taala.",
                 meaning: "I intend to pray the fardhu of Isyak, shortened to two rakaat, combined and delayed (jamak takhir), for Allah Ta'ala."),
            Niat(title: "Jamak Takhir — Maghrib",
                 transliteration: "Usolli fardol Maghribi salasa raka'atin jama'a takhirin lillahi taala.",
                 meaning: "I intend to pray the fardhu of Maghrib, three rakaat (not shortened), combined and delayed (jamak takhir), for Allah Ta'ala."),
            Niat(title: "Jamak Jumaat — Jumaat",
                 transliteration: "Usolli fardol Jum'ati rak'ataini makmuman lillahi taala.",
                 meaning: "I intend to pray the fardhu of Jumu'ah, two rakaat, as a follower (makmum), for Allah Ta'ala."),
            Niat(title: "Jamak Jumaat — Asar (taqdim only)",
                 transliteration: "Usolli fardol 'Asri qosron rak'ataini jama'a takdiimin lillahi taala.",
                 meaning: "I intend to pray the fardhu of Asar, shortened to two rakaat, combined with Jumu'ah and advanced (jamak taqdim), for Allah Ta'ala. With Jumu'ah, jamak is taqdim only (Shafi'i)."),
        ]),

        NiatGroup("Solat Sunat", [
            Niat(title: "Tahajjud",
                 transliteration: "Usalli sunnatat Tahajjudi rak'ataini lillahi ta'ala.",
                 meaning: "I intend to pray the sunnah Tahajjud, two rakaat, for Allah Ta'ala."),
            Niat(title: "Taubat",
                 transliteration: "Usalli sunnatat Taubati rak'ataini lillahi ta'ala.",
                 meaning: "I intend to pray the sunnah Taubat (repentance), two rakaat, for Allah Ta'ala."),
            Niat(title: "Dhuha",
                 transliteration: "Usalli sunnatad Dhuha rak'ataini lillahi ta'ala.",
                 meaning: "I intend to pray the sunnah Dhuha, two rakaat, for Allah Ta'ala."),
            Niat(title: "Hajat",
                 transliteration: "Usalli sunnatal Haajati rak'ataini lillahi ta'ala.",
                 meaning: "I intend to pray the sunnah Hajat (of need), two rakaat, for Allah Ta'ala."),
            Niat(title: "Tarawih",
                 transliteration: "Usalli sunnatat Taraawiihi rak'ataini ma'muman lillahi ta'ala.",
                 meaning: "I intend to pray the sunnah Tarawih, two rakaat, as a follower, for Allah Ta'ala."),
            Niat(title: "Witir",
                 transliteration: "Usalli sunnatal Witri rak'ataini lillahi ta'ala.",
                 meaning: "I intend to pray the sunnah Witir, two rakaat, for Allah Ta'ala. (For a single rakaat: “…rak'atan…”.)"),
            Niat(title: "Tahiyyatul Masjid",
                 transliteration: "Usalli sunnatan Tahiyyatal Masjidi rak'ataini lillahi ta'ala.",
                 meaning: "I intend to pray the sunnah of greeting the mosque, two rakaat, for Allah Ta'ala."),
            Niat(title: "Istikharah",
                 transliteration: "Usalli sunnatal Istikhaarati rak'ataini lillahi ta'ala.",
                 meaning: "I intend to pray the sunnah Istikharah (seeking guidance), two rakaat, for Allah Ta'ala."),
        ]),
    ]
}
