import SwiftUI

struct TimetableView: View {
    @EnvironmentObject var state: AppState
    @State private var dayOffset = 0

    private var selectedDate: Date {
        Calendar.current.date(byAdding: .day, value: dayOffset, to: state.now) ?? state.now
    }
    private var isToday: Bool { dayOffset == 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Timetable").font(Font2.condensed(34)).foregroundStyle(Palette.text)
                        if !isToday {
                            Button { dayOffset = 0 } label: { CapsLabel("Today", color: Palette.accent700) }
                                .buttonStyle(.plain)
                        }
                    }
                    Text("\(state.gregorianLong(selectedDate)) · \(state.hijriString(selectedDate))")
                        .font(Font2.body(13)).foregroundStyle(Palette.mutedInk)
                }
                .padding(.top, 12)

                sourceNote

                VStack(spacing: 0) {
                    ForEach(Array(WaktuRow.allCases.enumerated()), id: \.element) { idx, row in
                        if idx > 0 { Hairline() }
                        waktuRow(row)
                    }
                }
                .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))

                HStack(spacing: Space.s3) {
                    GhostButton(title: "‹ Yesterday") { dayOffset -= 1; state.expandedWaktu = nil }
                    GhostButton(title: "Tomorrow ›") { dayOffset += 1; state.expandedWaktu = nil }
                }

                Text("Jumu'ah replaces Zohor on Friday — attend the khutbah at your nearest masjid.")
                    .font(Font2.body(12.5))
                    .foregroundStyle(Palette.mutedInk)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
    }

    private var sourceNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            CapsLabel("Source")
            Text("Majlis Ugama Islam Singapura — the published daily waktu solat for Singapore. Times are identical island-wide.")
                .font(Font2.body(13))
                .foregroundStyle(Palette.mutedInk)
                .lineSpacing(2)
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .blueprint()
    }

    @ViewBuilder
    private func waktuRow(_ row: WaktuRow) -> some View {
        let isNext = isToday && state.nextWaktuRow == row
        let expanded = state.expandedWaktu == row
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: Space.s3) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.rawValue)
                        .font(Font2.condensed(22))
                        .foregroundStyle(isNext ? Palette.accent : Palette.text)
                    Text(SampleData.subNote(for: row))
                        .font(Font2.body(12))
                        .foregroundStyle(Palette.mutedInk)
                }
                Spacer()
                Text(state.clockString(for: state.time(for: row, on: selectedDate)))
                    .font(Font2.condensed(22))
                    .foregroundStyle(isNext ? Palette.accent : Palette.text)
                    .monospacedDigit()
                expander(row, expanded: expanded)
            }
            .padding(.vertical, 13)

            CapsLabel(SampleData.sunnahSummary(for: row), size: 10)
                .padding(.bottom, expanded ? Space.s3 : 11)

            if expanded {
                VStack(spacing: Space.s3) {
                    ForEach(SampleData.sunnah[row] ?? []) { s in
                        sunnahBlock(s)
                    }
                    if row == .subuh {
                        qunutBlock(SampleData.duaQunut)
                    }
                }
                .padding(.bottom, Space.s4)
            }
        }
        .padding(.horizontal, Space.s4)
        .contentShape(Rectangle())
    }

    private func qunutBlock(_ q: Niat) -> some View {
        HStack(alignment: .top, spacing: Space.s3) {
            Rectangle().fill(Palette.accent).frame(width: 2)
            VStack(alignment: .leading, spacing: 6) {
                CapsLabel(q.title, color: Palette.accent700, size: 10)
                Text("“\(q.transliteration)”")
                    .font(Font2.body(13))
                    .italic()
                    .foregroundStyle(Palette.accent700)
                    .lineSpacing(2)
                Text(q.meaning)
                    .font(Font2.body(12.5))
                    .foregroundStyle(Palette.mutedInk)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, Space.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func expander(_ row: WaktuRow, expanded: Bool) -> some View {
        Button {
            withAnimation(.none) {
                state.expandedWaktu = expanded ? nil : row
            }
        } label: {
            Image(systemName: expanded ? "minus" : "plus")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Palette.text)
                .frame(width: 28, height: 28)
                .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func sunnahBlock(_ s: Sunnah) -> some View {
        HStack(alignment: .top, spacing: Space.s3) {
            Rectangle().fill(Palette.accent).frame(width: 2)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(s.position.uppercased()) · \(s.rakaat) RAKAAT")
                        .font(Font2.medium(11))
                        .tracking(1)
                        .foregroundStyle(Palette.text)
                    Spacer()
                    if s.rank != "—" {
                        Text(s.rank)
                            .font(Font2.body(11))
                            .foregroundStyle(Palette.mutedInk)
                    }
                }
                Text("“\(s.niat)”")
                    .font(Font2.body(13))
                    .italic()
                    .foregroundStyle(Palette.accent700)
                    .lineSpacing(2)
                Text(s.meaning)
                    .font(Font2.body(12.5))
                    .foregroundStyle(Palette.mutedInk)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, Space.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
