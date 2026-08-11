import SwiftUI

// Reference of prayer intentions (niat), grouped by category.
struct NiatSolatView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                HStack { BackHeader(); Spacer() }.padding(.top, 8)

                ScreenTitle(title: "Niat solat",
                            subtitle: "Prayer intentions, Shafi'i")

                ForEach(SampleData.niatSolat) { group in
                    section(group)
                }

                Text("Add “ma'muman” (as makmum) or “imaman” (as imam) for congregation where relevant. Have the wording — especially jamak & qasar — confirmed with a religious authority.")
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

    private func section(_ group: NiatGroup) -> some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            CapsLabel(group.title)
            if let note = group.note {
                Text(note)
                    .font(Font2.body(12.5))
                    .foregroundStyle(Palette.mutedInk)
            }
            VStack(spacing: 0) {
                ForEach(Array(group.items.enumerated()), id: \.element.id) { idx, n in
                    if idx > 0 { Hairline() }
                    block(n)
                }
            }
            .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
        }
    }

    private func block(_ n: Niat) -> some View {
        HStack(alignment: .top, spacing: Space.s3) {
            Rectangle().fill(Palette.accent).frame(width: 2)
            VStack(alignment: .leading, spacing: 6) {
                Text(n.title)
                    .font(Font2.condensed(17))
                    .foregroundStyle(Palette.text)
                Text("“\(n.transliteration)”")
                    .font(Font2.body(13.5))
                    .italic()
                    .foregroundStyle(Palette.accent700)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(n.meaning)
                    .font(Font2.body(12.5))
                    .foregroundStyle(Palette.mutedInk)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Space.s4)
    }
}
