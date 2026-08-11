import SwiftUI

// Doa & dhikr recited after the fardhu prayer — a few common versions.
struct AfterSolatView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                HStack { BackHeader(); Spacer() }.padding(.top, 8)

                ScreenTitle(title: "Doa after solat",
                            subtitle: "Recited after the fardhu prayer")

                VStack(spacing: Space.s4) {
                    ForEach(Array(SampleData.afterSolatDua.enumerated()), id: \.element.id) { idx, d in
                        block(index: idx + 1, d)
                    }
                }

                Text("A selection of common recitations, not an exhaustive order. Have the wording and sequence confirmed with a religious authority.")
                    .font(Font2.body(12))
                    .foregroundStyle(Palette.mutedInk)
                    .lineSpacing(2)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
        .navigationBarBackButtonHidden(true)
    }

    private func block(index: Int, _ d: Niat) -> some View {
        HStack(alignment: .top, spacing: Space.s3) {
            Rectangle().fill(Palette.accent).frame(width: 2)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: Space.s2) {
                    Text("\(index)")
                        .font(Font2.condensed(18))
                        .foregroundStyle(Palette.accent700)
                        .monospacedDigit()
                    CapsLabel(d.title, color: Palette.accent700, size: 10)
                }
                Text("“\(d.transliteration)”")
                    .font(Font2.body(14))
                    .italic()
                    .foregroundStyle(Palette.text)
                    .lineSpacing(3)
                Text(d.meaning)
                    .font(Font2.body(12.5))
                    .foregroundStyle(Palette.mutedInk)
                    .lineSpacing(2)
            }
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .blueprint()
    }
}
