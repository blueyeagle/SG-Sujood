import SwiftUI

struct RemindersView: View {
    @EnvironmentObject var state: AppState

    private let rows: [(WaktuRow, String)] = [
        (.subuh,   "Vibrate at waktu · nudge 15 min before"),
        (.syuruk,  "End of the Subuh window"),
        (.zohor,   "Vibrate at waktu · nudge 15 min before"),
        (.asar,    "Vibrate at waktu · nudge 15 min before"),
        (.maghrib, "Vibrate at waktu · nudge 15 min before"),
        (.isyak,   "Vibrate at waktu · nudge 15 min before"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                HStack { BackHeader(); Spacer() }.padding(.top, 8)

                ScreenTitle(title: "Reminders")

                Text("Every alert is silent. You will feel a vibration and see the waktu on the Lock Screen — nothing plays out loud.")
                    .font(Font2.body(13.5))
                    .foregroundStyle(Palette.mutedInk)
                    .lineSpacing(2)

                VStack(alignment: .leading, spacing: Space.s3) {
                    CapsLabel("Per waktu")
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                            if idx > 0 { Hairline() }
                            reminderRow(row.0, subtitle: row.1)
                        }
                    }
                    .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: Space.s3) {
                    CapsLabel("Nudge before")
                    HStack(spacing: Space.s2) {
                        ForEach([10, 15, 30], id: \.self) { m in
                            FilterButton(title: "\(m) min", selected: state.leadMinutes == m) {
                                state.leadMinutes = m
                            }
                        }
                        Spacer()
                    }
                    Text("The nudge names the nearest space, so you can decide whether to move now or pray where you are.")
                        .font(Font2.body(12.5))
                        .foregroundStyle(Palette.mutedInk)
                        .lineSpacing(2)
                }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
        .navigationBarBackButtonHidden(true)
    }

    private func reminderRow(_ row: WaktuRow, subtitle: String) -> some View {
        let binding: Binding<Bool> = {
            if let p = row.prayer {
                return Binding(get: { state.reminderOn[p] ?? false },
                               set: { state.reminderOn[p] = $0 })
            }
            return Binding(get: { state.syurukReminder }, set: { state.syurukReminder = $0 })
        }()
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.rawValue)
                    .font(Font2.condensed(19))
                    .foregroundStyle(Palette.text)
                Text(subtitle)
                    .font(Font2.body(12))
                    .foregroundStyle(Palette.mutedInk)
            }
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(Palette.accent)
        }
        .padding(.horizontal, Space.s4)
        .padding(.vertical, 12)
    }
}
