import SwiftUI

// MARK: - Design tokens (Industry design system — steel-blue wireframe on a light technical ground)

enum Palette {
    static let bg        = Color(hex: 0xF2F2F3) // Page ground
    static let surface   = Color(hex: 0xE9E9EA) // Raised card fill
    static let text      = Color(hex: 0x1D1F20) // Body ink
    static let accent    = Color(hex: 0x5980A6) // Steel accent — active states, primary fill, markers
    static let accent400 = Color(hex: 0x94BCE3) // Accent on dark plates
    static let accent700 = Color(hex: 0x416180) // Accent text at paragraph size
    static let accent900 = Color(hex: 0x1D2D3D) // The dark "field" — hero plate, Ramadan, Dzikir, Zakat header

    static let divider   = Color(hex: 0x1D1F20).opacity(0.16)
    static let mutedInk  = Color(hex: 0x1D1F20).opacity(0.55)

    // On the dark plate
    static let paperInk        = Color(hex: 0xF2F2F3)
    static let paperInkMuted   = Color(hex: 0xF2F2F3).opacity(0.60)
    static let dividerOnDark   = Color(hex: 0x94BCE3).opacity(0.38)
}

// MARK: - Spacing scale  3.4 / 6.8 / 10.2 / 13.6 / 20.4 / 27.2

enum Space {
    static let s1: CGFloat = 3.4
    static let s2: CGFloat = 6.8
    static let s3: CGFloat = 10.2
    static let s4: CGFloat = 13.6
    static let s6: CGFloat = 20.4
    static let s8: CGFloat = 27.2
    static let gutter: CGFloat = 22
}

// MARK: - Typography  (Barlow / Barlow Condensed, bundled; graceful fallback)

enum Font2 {
    // Headings — Barlow Condensed 600
    static func condensed(_ size: CGFloat) -> Font {
        Font.custom("BarlowCondensed-SemiBold", size: size)
    }
    static func condensedRegular(_ size: CGFloat) -> Font {
        Font.custom("BarlowCondensed-Regular", size: size)
    }
    // Body — Barlow 400 / 500
    static func body(_ size: CGFloat) -> Font {
        Font.custom("Barlow-Regular", size: size)
    }
    static func medium(_ size: CGFloat) -> Font {
        Font.custom("Barlow-Medium", size: size)
    }
    static func bold(_ size: CGFloat) -> Font {
        Font.custom("Barlow-Bold", size: size)
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

// MARK: - All-caps label (letter-spaced kicker)

struct CapsLabel: View {
    let text: String
    var color: Color = Palette.mutedInk
    var size: CGFloat = 11
    init(_ text: String, color: Color = Palette.mutedInk, size: CGFloat = 11) {
        self.text = text; self.color = color; self.size = size
    }
    var body: some View {
        Text(text.uppercased())
            .font(Font2.medium(size))
            .tracking(size * 0.16)          // 0.12–0.2em
            .foregroundStyle(color)
    }
}
