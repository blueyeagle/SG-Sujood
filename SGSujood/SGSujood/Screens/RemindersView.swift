import SwiftUI

struct RemindersView: View {
    @EnvironmentObject var state: AppState

    private let rows: [(WaktuRow, String)] = [
        (.subuh,   "Silent alert at waktu, and a nudge before"),
        (.syuruk,  "End of the Subuh window"),
        (.zohor,   "Silent alert at waktu, and a nudge before"),
        (.asar,    "Silent alert at waktu, and a nudge before"),
        (.maghrib, "Silent alert at waktu, and a nudge before"),
        (.isyak,   "Silent alert at waktu, and a nudge before"),
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
                    Text("A silent nudge this many minutes before each waktu, so you can wrap up and get ready to pray.")
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
        .onChange(of: state.reminderOn) { _, _ in state.rescheduleReminders() }
        .onChange(of: state.leadMinutes) { _, _ in state.rescheduleReminders() }
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
