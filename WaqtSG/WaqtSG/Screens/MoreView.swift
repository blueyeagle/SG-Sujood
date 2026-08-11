import SwiftUI

enum MoreRoute: Hashable {
    case qadha, dzikir, afterSolat, zakat, reminders, addSpace, ramadan, widgets, location
}

struct MoreView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var location: LocationProvider

    private var rows: [(MoreRoute, String, String)] {
        [
            (.qadha,     "Qadha record",         "\(state.qadhaTotal) owing this month"),
            (.dzikir,    "Dzikir counter",       "Tasbih with presets and rounds"),
            (.afterSolat,"Doa after solat",      "Dhikr and supplications after prayer"),
            (.zakat,     "Zakat",                "Nisab, haul and your holding"),
            (.reminders, "Reminders",            "Silent nudges before each waktu"),
            (.addSpace,  "Add a prayer space",   "Help the next person find a room"),
            (.ramadan,   "Ramadan mode",         "Imsak, iftar and terawih nearby"),
            (.widgets,   "Widgets & Lock Screen","Next prayer and nearest space"),
            (.location,  "Location",             location.areaName),
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
            case .afterSolat: AfterSolatView()
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

// Location screen (More → Location) — shows live location.
struct LocationView: View {
    @EnvironmentObject var location: LocationProvider
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                HStack { BackHeader(); Spacer() }.padding(.top, 8)
                ScreenTitle(title: "Location",
                            subtitle: "Used on device only — never uploaded.")
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        CapsLabel("Current area")
                        Spacer()
                        CapsLabel(location.isReal ? "Live" : "Default",
                                  color: location.isReal ? Palette.accent700 : Palette.mutedInk, size: 9)
                    }
                    Text(location.areaName)
                        .font(Font2.condensed(26))
                        .foregroundStyle(Palette.text)
                    Text(String(format: "%.4f, %.4f", location.current.coordinate.latitude, location.current.coordinate.longitude))
                        .font(Font2.body(12.5))
                        .foregroundStyle(Palette.mutedInk)
                        .monospacedDigit()
                    Text("Timings are identical island-wide; your area only affects how nearby spaces are sorted.")
                        .font(Font2.body(13))
                        .foregroundStyle(Palette.mutedInk)
                        .lineSpacing(2)
                }
                .padding(Space.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .blueprint()

                if !location.isReal {
                    Text("Waiting for a location fix — allow location access in Settings if this stays on Default.")
                        .font(Font2.body(12.5))
                        .foregroundStyle(Palette.mutedInk)
                }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
        .navigationBarBackButtonHidden(true)
    }
}
