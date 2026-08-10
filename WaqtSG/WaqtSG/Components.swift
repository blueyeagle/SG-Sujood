import SwiftUI

// MARK: - Primary accent button (the one filled object on a screen)

struct PrimaryButton: View {
    let title: String
    var onDark: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: { Haptics.medium(); action() }) {
            Text(title)
                .font(Font2.condensed(17))
                .tracking(0.5)
                .foregroundStyle(Palette.paperInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Palette.accent)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ghost / hairline-bordered secondary button

struct GhostButton: View {
    let title: String
    var onDark: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font2.condensed(17))
                .tracking(0.5)
                .foregroundStyle(onDark ? Palette.paperInk : Palette.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .overlay(Rectangle().stroke(onDark ? Palette.dividerOnDark : Palette.divider, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Screen title (Barlow Condensed 34)

struct ScreenTitle: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Font2.condensed(34))
                .foregroundStyle(Palette.text)
            if let subtitle {
                Text(subtitle)
                    .font(Font2.body(13))
                    .foregroundStyle(Palette.mutedInk)
            }
        }
    }
}

// MARK: - Back header for pushed screens (tab bar is hidden here)

struct BackHeader: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: "arrow.left")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Palette.text)
                .frame(width: 40, height: 40)
                .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct BackHeaderDark: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: "arrow.left")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Palette.paperInk)
                .frame(width: 40, height: 40)
                .overlay(Rectangle().stroke(Palette.dividerOnDark, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Small square status/marker used across lists

struct AccentSquare: View {
    var filled: Bool = true
    var color: Color = Palette.accent
    var size: CGFloat = 7
    var body: some View {
        Rectangle()
            .fill(filled ? color : Color.clear)
            .frame(width: size, height: size)
            .overlay(Rectangle().stroke(color, lineWidth: filled ? 0 : 1))
    }
}

// MARK: - Filter / chip button

struct FilterButton: View {
    let title: String
    let selected: Bool
    var onDark: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: { Haptics.selection(); action() }) {
            Text(title.uppercased())
                .font(Font2.medium(11))
                .tracking(1.2)
                .foregroundStyle(selected ? Palette.paperInk : (onDark ? Palette.paperInkMuted : Palette.mutedInk))
                .padding(.vertical, 9)
                .padding(.horizontal, 14)
                .background(selected ? Palette.accent : Color.clear)
                .overlay(Rectangle().stroke(selected ? Color.clear : (onDark ? Palette.dividerOnDark : Palette.divider), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
