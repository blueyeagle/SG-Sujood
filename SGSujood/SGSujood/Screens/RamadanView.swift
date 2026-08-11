import SwiftUI

struct RamadanView: View {
    @EnvironmentObject var state: AppState

    private var info: AppState.RamadanInfo { state.ramadan }

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

                    if info.isRamadan { activeHeader } else { countdownHeader }

                    if info.isRamadan {
                        imsakMaghribGrid
                        terawih
                    } else {
                        dormantNote
                    }

                    niatSection

                    Text(info.isRamadan
                         ? "Ramadan mode switches off by itself after Syawal."
                         : "Ramadan mode switches on by itself on 1 Ramadan. Hijri dates are computed (Umm al-Qura) and may differ from MUIS's observed calendar by a day.")
                        .font(Font2.body(12))
                        .foregroundStyle(Palette.paperInkMuted)
                        .lineSpacing(2)
                }
                .padding(.horizontal, Space.gutter)
                .padding(.bottom, Space.s8)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: Headers

    private var activeHeader: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            CapsLabel("Ramadan \(info.hijriYear) · Day \(info.dayOfRamadan)", color: Palette.accent400)
            Text("Iftar in \(iftarCountdown)")
                .font(Font2.condensed(40))
                .foregroundStyle(Palette.paperInk)
                .monospacedDigit()
        }
    }

    private var countdownHeader: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            CapsLabel("Next · Ramadan \(info.hijriYear)", color: Palette.accent400)
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text("\(info.daysToNext)")
                    .font(Font2.condensed(76))
                    .foregroundStyle(Palette.paperInk)
                    .monospacedDigit()
                Text(info.daysToNext == 1 ? "day away" : "days away")
                    .font(Font2.body(15))
                    .foregroundStyle(Palette.paperInkMuted)
            }
            Text("Begins \(state.longDate(info.start)) · ends \(state.longDate(info.end))")
                .font(Font2.body(12.5))
                .foregroundStyle(Palette.paperInkMuted)
        }
    }

    private var dormantNote: some View {
        Text("Imsak, iftar times and terawih nearby will appear here once Ramadan begins.")
            .font(Font2.body(13))
            .foregroundStyle(Palette.paperInkMuted)
            .lineSpacing(2)
            .padding(Space.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(Rectangle().stroke(Palette.dividerOnDark, lineWidth: 1))
    }

    // MARK: Sections

    private var imsakMaghribGrid: some View {
        HStack(spacing: 0) {
            cell(label: "Imsak", value: state.imsakString(on: state.now))
            Rectangle().fill(Palette.dividerOnDark).frame(width: 1)
            cell(label: "Maghrib", value: state.clockString(for: WaktuRow.maghrib))
        }
        .overlay(Rectangle().stroke(Palette.dividerOnDark, lineWidth: 1))
    }

    private var terawih: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            CapsLabel("Terawih nearby", color: Palette.accent400)
            VStack(spacing: 0) {
                ForEach(Array(SampleData.terawih.enumerated()), id: \.element.id) { idx, t in
                    if idx > 0 { Hairline(onDark: true) }
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.mosque).font(Font2.condensed(19)).foregroundStyle(Palette.paperInk)
                            Text(t.detail).font(Font2.body(12.5)).foregroundStyle(Palette.paperInkMuted)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Text("\(t.walkMinutes)").font(Font2.condensed(22)).foregroundStyle(Palette.paperInk).monospacedDigit()
                            CapsLabel("min", color: Palette.paperInkMuted, size: 9)
                        }
                    }
                    .padding(.vertical, 13)
                }
            }
            .overlay(Rectangle().stroke(Palette.dividerOnDark, lineWidth: 1))
        }
    }

    private var niatSection: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            CapsLabel("Niat & doa", color: Palette.accent400)
            VStack(spacing: Space.s3) {
                ForEach(SampleData.ramadanNiat) { n in niatBlock(n) }
            }
        }
    }

    private func niatBlock(_ n: Niat) -> some View {
        HStack(alignment: .top, spacing: Space.s3) {
            Rectangle().fill(Palette.accent400).frame(width: 2)
            VStack(alignment: .leading, spacing: 6) {
                CapsLabel(n.title, color: Palette.accent400, size: 10)
                Text("“\(n.transliteration)”")
                    .font(Font2.body(13.5)).italic()
                    .foregroundStyle(Palette.paperInk)
                    .lineSpacing(2)
                Text(n.meaning)
                    .font(Font2.body(12.5))
                    .foregroundStyle(Palette.paperInkMuted)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, Space.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
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
