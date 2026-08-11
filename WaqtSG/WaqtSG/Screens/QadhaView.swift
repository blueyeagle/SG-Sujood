import SwiftUI

struct QadhaView: View {
    @EnvironmentObject var state: AppState

    // Day grid reflects the current month. There's no persisted per-day history yet, so past
    // days read as complete and today turns "missed" only if a prayer is marked missed today.
    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: state.now)?.count ?? 30
    }
    private var today: Int {
        Calendar.current.component(.day, from: state.now)
    }
    private var missedDays: Set<Int> {
        state.missedCount > 0 ? [today] : []
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                HStack {
                    BackHeader()
                    Spacer()
                }
                .padding(.top, 8)

                HStack(alignment: .firstTextBaseline) {
                    Text("Qadha")
                        .font(Font2.condensed(34))
                        .foregroundStyle(Palette.text)
                    Spacer()
                    monthStepper
                }

                Text("Every fardhu you left marked as missed is counted here. Pray it, then record it — the count comes down one at a time.")
                    .font(Font2.body(13.5))
                    .foregroundStyle(Palette.mutedInk)
                    .lineSpacing(2)

                outstandingCard
                dayGrid
                byWaktu

                Text("Recording a qadha reduces the count only — it does not change the day it was missed.")
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

    private var monthStepper: some View {
        HStack(spacing: 0) {
            stepButton("chevron.left")
            Text("AUG 2026")
                .font(Font2.medium(11))
                .tracking(1)
                .foregroundStyle(Palette.text)
                .padding(.horizontal, 12)
            stepButton("chevron.right")
        }
        .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
    }
    private func stepButton(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 12))
            .foregroundStyle(Palette.text)
            .frame(width: 34, height: 30)
    }

    private var outstandingCard: some View {
        HStack(alignment: .center) {
            CapsLabel("Outstanding this month")
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(state.qadhaTotal)")
                    .font(Font2.condensed(52))
                    .foregroundStyle(Palette.text)
                    .monospacedDigit()
                Text("prayers\nowing")
                    .font(Font2.body(11))
                    .foregroundStyle(Palette.mutedInk)
            }
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity)
        .blueprint(fill: Palette.surface)
    }

    private var dayGrid: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            CapsLabel("August")
            let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            LazyVGrid(columns: cols, spacing: 6) {
                ForEach(1...daysInMonth, id: \.self) { day in
                    dayCell(day)
                }
            }
            HStack(spacing: Space.s6) {
                legend(fill: Palette.accent.opacity(0.18), text: "Complete", ink: Palette.text)
                legend(fill: Palette.accent900, text: "One or more missed", ink: Palette.text)
            }
            .padding(.top, 4)
        }
    }

    private func dayCell(_ day: Int) -> some View {
        let isFuture = day > today
        let isMissed = missedDays.contains(day)
        let fill: Color = isFuture ? .clear : (isMissed ? Palette.accent900 : Palette.accent.opacity(0.18))
        let ink: Color = isMissed ? Palette.paperInk : (isFuture ? Palette.mutedInk.opacity(0.5) : Palette.text)
        return Text("\(day)")
            .font(Font2.body(12))
            .monospacedDigit()
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity, minHeight: 34)
            .background(fill)
            .overlay(Rectangle().stroke(Palette.divider, lineWidth: isFuture ? 1 : 0))
    }

    private func legend(fill: Color, text: String, ink: Color) -> some View {
        HStack(spacing: 6) {
            Rectangle().fill(fill).frame(width: 12, height: 12)
                .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
            Text(text).font(Font2.body(11.5)).foregroundStyle(Palette.mutedInk)
        }
    }

    private var byWaktu: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            CapsLabel("By waktu")
            VStack(spacing: 0) {
                ForEach(Array(Prayer.fardhu.enumerated()), id: \.element) { idx, prayer in
                    if idx > 0 { Hairline() }
                    waktuRow(prayer)
                }
            }
            .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
        }
    }

    private func waktuRow(_ prayer: Prayer) -> some View {
        let count = state.qadha[prayer] ?? 0
        let disabled = count == 0
        return VStack(spacing: 8) {
            HStack(spacing: Space.s3) {
                Text(prayer.rawValue)
                    .font(Font2.condensed(19))
                    .foregroundStyle(disabled ? Palette.mutedInk : Palette.text)
                Text("\(count) owing")
                    .font(Font2.body(13))
                    .foregroundStyle(Palette.mutedInk)
                Spacer()
                Button { state.recordQadha(prayer) } label: {
                    Text("QADHA DONE")
                        .font(Font2.medium(10.5))
                        .tracking(1)
                        .foregroundStyle(disabled ? Palette.mutedInk : Palette.paperInk)
                        .frame(height: 30)
                        .padding(.horizontal, 12)
                        .background(disabled ? Color.clear : Palette.accent)
                        .overlay(Rectangle().stroke(disabled ? Palette.divider : Color.clear, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(disabled)
            }
            ProgressRail(fraction: railFraction(prayer, count: count))
        }
        .padding(.horizontal, Space.s4)
        .padding(.vertical, 13)
    }

    // A simple visual: fraction of this prayer's owing against the month's max.
    private func railFraction(_ prayer: Prayer, count: Int) -> Double {
        let maxCount = max(1, state.qadha.values.max() ?? 1)
        return Double(count) / Double(maxCount)
    }
}
