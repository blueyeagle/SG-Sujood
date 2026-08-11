import CoreText
import Foundation

// Registers the bundled Barlow / Barlow Condensed TTFs at launch, so
// Font.custom(...) resolves them without a UIAppFonts Info.plist entry.
enum FontRegistrar {
    static func register() {
        let names = [
            "Barlow-Regular", "Barlow-Medium", "Barlow-Bold",
            "BarlowCondensed-SemiBold", "BarlowCondensed-Regular"
        ]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
