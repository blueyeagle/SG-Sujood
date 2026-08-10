import SwiftUI

struct RamadanView: View {
    @EnvironmentObject var state: AppState

    private var iftarCountdown: String {
        let maghrib = state.time(for: WaktuRow.maghrib)
        let target = maghrib > state.now ? maghrib : Calendar.current.date(byAdding: .day, value: 1, to: maghrib)!
        let secs = max(0, Int(target.timeIntervalSince(state.now)))
        let h = secs / 3600, m = (secs % 3600) / 60
        return "\(h)h \(m)m"
    }

    var body: some View {
        ZStack {
            Palette.accent900.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s6) {
                    HStack { BackHeaderDark(); Spacer() }.padding(.top, 8)

                    VStack(alignment: .leading, spacing: Space.s2) {
                        CapsLabel("Ramadan · Day 14", color: Palette.accent400)
                        Text("Iftar in \(iftarCountdown)")
                            .font(Font2.condensed(40))
                            .foregroundStyle(Palette.paperInk)
                            .monospacedDigit()
                    }

                    HStack(spacing: 0) {
                        cell(label: "Imsak", value: state.imsakString(on: state.now))
                        Rectangle().fill(Palette.dividerOnDark).frame(width: 1)
                        cell(label: "Maghrib", value: state.clockString(for: WaktuRow.maghrib))
                    }
                    .overlay(Rectangle().stroke(Palette.dividerOnDark, lineWidth: 1))

                    VStack(alignment: .leading, spacing: Space.s3) {
                        CapsLabel("Terawih nearby", color: Palette.accent400)
                        VStack(spacing: 0) {
                            ForEach(Array(SampleData.terawih.enumerated()), id: \.element.id) { idx, t in
                                if idx > 0 { Hairline(onDark: true) }
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(t.mosque)
                                            .font(Font2.condensed(19))
                                            .foregroundStyle(Palette.paperInk)
                                        Text(t.detail)
                                            .font(Font2.body(12.5))
                                            .foregroundStyle(Palette.paperInkMuted)
                                    }
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Text("\(t.walkMinutes)")
                                            .font(Font2.condensed(22))
                                            .foregroundStyle(Palette.paperInk)
                                            .monospacedDigit()
                                        CapsLabel("min", color: Palette.paperInkMuted, size: 9)
                                    }
                                }
                                .padding(.vertical, 13)
                            }
                        }
                        .overlay(Rectangle().stroke(Palette.dividerOnDark, lineWidth: 1))
                    }

                    Text("Ramadan mode switches on by itself on 1 Ramadan and turns off after Syawal.")
                        .font(Font2.body(12.5))
                        .foregroundStyle(Palette.paperInkMuted)
                        .lineSpacing(2)
                }
                .padding(.horizontal, Space.gutter)
                .padding(.bottom, Space.s8)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func cell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            CapsLabel(label, color: Palette.accent400, size: 10)
            Text(value)
                .font(Font2.condensed(28))
                .foregroundStyle(Palette.paperInk)
                .monospacedDigit()
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
