import SwiftUI

// A specification / preview screen for the WidgetKit widgets (built separately as an extension).
struct WidgetsSpecView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                HStack { BackHeader(); Spacer() }.padding(.top, 8)
                ScreenTitle(title: "Widgets")

                // Lock Screen
                VStack(alignment: .leading, spacing: Space.s3) {
                    CapsLabel("Lock screen")
                    lockScreenPreview
                }

                // Home Screen
                VStack(alignment: .leading, spacing: Space.s3) {
                    CapsLabel("Home screen")
                    HStack(spacing: 0) {
                        homeCell(label: "Asar", big: "4.32", note: "in 30 minutes")
                        Rectangle().fill(Palette.divider).frame(width: 1)
                        homeCell(label: "Nearest", big: "ION Orchard", note: "B4 · 3 min walk", condensedBig: false)
                    }
                    .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
                }

                Text("Both widgets refresh on the hour and whenever you move to a new building.")
                    .font(Font2.body(12.5))
                    .foregroundStyle(Palette.mutedInk)
                    .lineSpacing(2)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
        .navigationBarBackButtonHidden(true)
    }

    private var lockScreenPreview: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            Text("Monday 10 August")
                .font(Font2.body(12))
                .foregroundStyle(Palette.paperInkMuted)
            Text("4:02")
                .font(Font2.condensed(44))
                .foregroundStyle(Palette.paperInk)
                .monospacedDigit()
            HStack(spacing: 0) {
                lockCell(label: "Asar", value: "in 30m")
                Rectangle().fill(Palette.dividerOnDark).frame(width: 1)
                lockCell(label: "Nearest", value: "ION · 3m")
            }
            .overlay(Rectangle().stroke(Palette.dividerOnDark, lineWidth: 1))
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.accent900)
    }

    private func lockCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            CapsLabel(label, color: Palette.accent400, size: 9)
            Text(value)
                .font(Font2.condensed(18))
                .foregroundStyle(Palette.paperInk)
        }
        .padding(.vertical, 8).padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func homeCell(label: String, big: String, note: String, condensedBig: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            CapsLabel(label, size: 9)
            Text(big)
                .font(condensedBig ? Font2.condensed(34) : Font2.condensed(22))
                .foregroundStyle(Palette.text)
            Text(note)
                .font(Font2.body(11.5))
                .foregroundStyle(Palette.mutedInk)
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
    }
}
