import SwiftUI

struct RamadanView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var terawihStore: TerawihStore
    @EnvironmentObject var spaces: SpacesStore
    @EnvironmentObject var location: LocationProvider

    private var info: AppState.RamadanInfo { state.ramadan }

    // Curated terawih venues (from terawih.json), nearest first. Until that list is populated,
    // fall back to the nearest mosques in the directory.
    private struct Venue { let name: String; let subtitle: String?; let metres: Double? }
    private var usingCurated: Bool { !terawihStore.venues.isEmpty }
    private var terawihVenues: [Venue] {
        let origin = location.current
        if usingCurated {
            return terawihStore.sorted(from: origin).map {
                Venue(name: $0.name, subtitle: $0.address ?? $0.note,
                      metres: $0.location?.distance(from: origin))
            }
        }
        return spaces.spaces
            .filter { $0.category == "masjid" }
            .compactMap { s in s.location.map { (s, $0.distance(from: origin)) } }
            .sorted { $0.1 < $1.1 }
            .prefix(6)
            .map { Venue(name: $0.0.name, subtitle: $0.0.address, metres: $0.1) }
    }

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

    @ViewBuilder
    private var terawih: some View {
        let venues = terawihVenues
        VStack(alignment: .leading, spacing: Space.s3) {
            CapsLabel("Terawih nearby", color: Palette.accent400)
            if venues.isEmpty {
                Text("No terawih venues nearby yet.")
                    .font(Font2.body(13)).foregroundStyle(Palette.paperInkMuted)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(venues.enumerated()), id: \.offset) { idx, v in
                        if idx > 0 { Hairline(onDark: true) }
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(v.name).font(Font2.condensed(19)).foregroundStyle(Palette.paperInk)
                                if let sub = v.subtitle {
                                    Text(sub).font(Font2.body(12.5)).foregroundStyle(Palette.paperInkMuted).lineLimit(1)
                                }
                            }
                            Spacer()
                            if let m = v.metres {
                                HStack(spacing: 4) {
                                    Text(m >= 2000 ? String(format: "%.1f", m/1000) : "\(Walk.minutes(m))")
                                        .font(Font2.condensed(22)).foregroundStyle(Palette.paperInk).monospacedDigit()
                                    CapsLabel(m >= 2000 ? "km" : "min", color: Palette.paperInkMuted, size: 9)
                                }
                            }
                        }
                        .padding(.vertical, 13)
                    }
                }
                .overlay(Rectangle().stroke(Palette.dividerOnDark, lineWidth: 1))
                if !usingCurated {
                    Text("Showing nearest mosques — the curated terawih list updates nearer Ramadan.")
                        .font(Font2.body(11.5)).foregroundStyle(Palette.paperInkMuted)
                }
            }
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
