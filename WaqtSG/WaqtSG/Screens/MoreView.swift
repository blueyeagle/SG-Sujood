import SwiftUI

enum MoreRoute: Hashable {
    case qadha, dzikir, zakat, reminders, addSpace, ramadan, widgets, location
}

struct MoreView: View {
    @EnvironmentObject var state: AppState

    private var rows: [(MoreRoute, String, String)] {
        [
            (.qadha,     "Qadha record",         "\(state.qadhaTotal) owing this month"),
            (.dzikir,    "Dzikir counter",       "Tasbih with presets and rounds"),
            (.zakat,     "Zakat",                "Nisab, haul and your holding"),
            (.reminders, "Reminders",            "Silent nudges before each waktu"),
            (.addSpace,  "Add a prayer space",   "Help the next person find a room"),
            (.ramadan,   "Ramadan mode",         "Imsak, iftar and terawih nearby"),
            (.widgets,   "Widgets & Lock Screen","Next prayer and nearest space"),
            (.location,  "Location",             SampleData.location),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                ScreenTitle(title: "More").padding(.top, 12)

                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                        if idx > 0 { Hairline() }
                        NavigationLink(value: row.0) {
                            HStack(spacing: Space.s3) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(row.1)
                                        .font(Font2.condensed(19))
                                        .foregroundStyle(Palette.text)
                                    Text(row.2)
                                        .font(Font2.body(12.5))
                                        .foregroundStyle(Palette.mutedInk)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(Palette.mutedInk)
                            }
                            .padding(.vertical, 15)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
                .padding(.horizontal, 2)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
        .navigationDestination(for: MoreRoute.self) { route in
            switch route {
            case .qadha:     QadhaView()
            case .dzikir:    DzikirView()
            case .zakat:     ZakatView()
            case .reminders: RemindersView()
            case .addSpace:  AddSpaceView()
            case .ramadan:   RamadanView()
            case .widgets:   WidgetsSpecView()
            case .location:  LocationView()
            }
        }
    }
}

// Simple Location screen (More → Location).
struct LocationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                HStack { BackHeader(); Spacer() }.padding(.top, 8)
                ScreenTitle(title: "Location",
                            subtitle: "Used on device only — never uploaded.")
                VStack(alignment: .leading, spacing: 8) {
                    CapsLabel("Current area")
                    Text(SampleData.location)
                        .font(Font2.condensed(26))
                        .foregroundStyle(Palette.text)
                    Text("Timings are identical island-wide; your area only affects how nearby spaces are sorted.")
                        .font(Font2.body(13))
                        .foregroundStyle(Palette.mutedInk)
                        .lineSpacing(2)
                }
                .padding(Space.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .blueprint()
                GhostButton(title: "Set my location manually") {}
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
        .navigationBarBackButtonHidden(true)
    }
}
