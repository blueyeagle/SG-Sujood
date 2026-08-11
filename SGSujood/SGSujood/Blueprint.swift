import SwiftUI

// MARK: - Blueprint frame
// A transparent line-drawing card: 1px divider border, square corners, no fill.
// Adds four `+` registration marks at the corners (11×11 crosshairs, offset −6px).

struct RegistrationMark: View {
    var color: Color
    var body: some View {
        ZStack {
            Rectangle().frame(width: 11, height: 1)
            Rectangle().frame(width: 1, height: 11)
        }
        .foregroundStyle(color)
    }
}

struct BlueprintFrame: ViewModifier {
    var onDark: Bool = false
    var showMarks: Bool = true
    var fill: Color? = nil

    private var stroke: Color { onDark ? Palette.dividerOnDark : Palette.divider }
    private var mark: Color { onDark ? Palette.dividerOnDark : Palette.divider }

    func body(content: Content) -> some View {
        content
            .background(fill ?? Color.clear)
            .overlay(Rectangle().stroke(stroke, lineWidth: 1))
            .overlay(alignment: .topLeading)     { if showMarks { RegistrationMark(color: mark).offset(x: -6, y: -6) } }
            .overlay(alignment: .topTrailing)    { if showMarks { RegistrationMark(color: mark).offset(x: 6, y: -6) } }
            .overlay(alignment: .bottomLeading)  { if showMarks { RegistrationMark(color: mark).offset(x: -6, y: 6) } }
            .overlay(alignment: .bottomTrailing) { if showMarks { RegistrationMark(color: mark).offset(x: 6, y: 6) } }
    }
}

extension View {
    /// Blueprint card: hairline border + corner registration marks. Square corners, no fill by default.
    func blueprint(onDark: Bool = false, marks: Bool = true, fill: Color? = nil) -> some View {
        modifier(BlueprintFrame(onDark: onDark, showMarks: marks, fill: fill))
    }
}

// MARK: - Hairline divider (1px)

struct Hairline: View {
    var onDark: Bool = false
    var body: some View {
        Rectangle()
            .fill(onDark ? Palette.dividerOnDark : Palette.divider)
            .frame(height: 1)
    }
}

// MARK: - Progress rail (2px)

struct ProgressRail: View {
    var fraction: Double            // 0...1
    var onDark: Bool = false
    var height: CGFloat = 2
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill((onDark ? Palette.paperInk : Palette.text).opacity(0.16))
                Rectangle()
                    .fill(onDark ? Palette.accent400 : Palette.accent)
                    .frame(width: geo.size.width * max(0, min(1, fraction)))
            }
        }
        .frame(height: height)
    }
}
