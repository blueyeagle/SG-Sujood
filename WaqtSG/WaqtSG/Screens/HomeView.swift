import SwiftUI

struct HomeView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                lightBody
            }
        }
        .background(Palette.bg)
        .ignoresSafeArea(edges: .top)
        .navigationDestination(for: PrayerSpace.self) { SpaceDetailView(space: $0) }
        .navigationDestination(for: HomeRoute.self) { route in
            switch route {
            case .qadha: QadhaView()
            }
        }
    }

    // MARK: - Dark hero plate

    private var hero: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            HStack(alignment: .top) {
                CapsLabel(SampleData.location, color: Palette.accent400, size: 11)
                Spacer()
                Text(state.hijriString)
                    .font(Font2.body(12))
                    .foregroundStyle(Palette.paperInkMuted)
            }
            .padding(.top, 64)

            VStack(alignment: .leading, spacing: Space.s2) {
                CapsLabel("Next · \(state.nextPrayer.row.rawValue)", color: Palette.accent400, size: 11)
                HStack(alignment: .lastTextBaseline, spacing: 12) {
                    Text(state.clockString(for: state.nextPrayer.row))
                        .font(Font2.condensed(76))
                        .foregroundStyle(Palette.paperInk)
                        .monospacedDigit()
                    Text("in \(state.countdownString)")
                        .font(Font2.body(15))
                        .foregroundStyle(Palette.paperInkMuted)
                        .monospacedDigit()
                    Spacer()
                }
            }

            VStack(spacing: 6) {
                ProgressRail(fraction: state.progressFraction, onDark: true)
                HStack {
                    Text("\(state.previousPrayer.row.rawValue) \(state.clockString(for: state.previousPrayer.row))")
                        .font(Font2.body(12))
                        .foregroundStyle(Palette.paperInkMuted)
                    Spacer()
                    Text("Now \(state.clockString(for: state.now))")
                        .font(Font2.body(12))
                        .foregroundStyle(Palette.paperInkMuted)
                        .monospacedDigit()
                }
            }
        }
        .padding(.horizontal, Space.gutter)
        .padding(.bottom, Space.s6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.accent900)
    }

    // MARK: - Light body

    private var lightBody: some View {
        VStack(alignment: .leading, spacing: Space.s6) {
            nearestSpace
            fardhuTracker
            qadhaRow
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.s6)
        .padding(.bottom, Space.s8)
    }

    private var nearestSpace: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            HStack {
                CapsLabel("Nearest space")
                Spacer()
                Button { state.selectedTab = .nearby } label: {
                    CapsLabel("See all", color: Palette.accent700)
                }
                .buttonStyle(.plain)
            }

            let s = state.nearestSpace
            NavigationLink(value: s) {
                VStack(alignment: .leading, spacing: Space.s3) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(s.name)
                                .font(Font2.condensed(22))
                                .foregroundStyle(Palette.text)
                            Text("\(s.type.rawValue) · \(s.floorLandmark)")
                                .font(Font2.body(13))
                                .foregroundStyle(Palette.mutedInk)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: -2) {
                            Text("\(s.walkMinutes)")
                                .font(Font2.condensed(40))
                                .foregroundStyle(Palette.text)
                                .monospacedDigit()
                            CapsLabel("min walk", size: 9.5)
                        }
                    }
                    HStack(spacing: Space.s2) {
                        if s.openNow { tag("Open now") }
                        tag("Confirmed \(s.confirmedDaysAgo) days ago")
                    }
                }
                .padding(Space.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .blueprint(fill: Palette.surface)
            }
            .buttonStyle(.plain)
        }
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(Font2.medium(10.5))
            .tracking(0.5)
            .foregroundStyle(Palette.accent700)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
    }

    // MARK: - Today's fardhu tracker

    private var fardhuTracker: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            CapsLabel("Today · \(state.doneCount) done, \(state.missedCount) missed, \(state.toComeCount) to come")

            VStack(spacing: 0) {
                ForEach(Array(Prayer.fardhu.enumerated()), id: \.element) { idx, prayer in
                    if idx > 0 { Hairline() }
                    fardhuRow(prayer)
                }
            }
            .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
        }
    }

    private func fardhuRow(_ prayer: Prayer) -> some View {
        let status = state.dayLog[prayer] ?? .pending
        return HStack(spacing: Space.s3) {
            statusDot(status)
            Text(prayer.rawValue)
                .font(Font2.medium(15))
                .foregroundStyle(Palette.text)
            Spacer()
            Text(state.clockString(for: prayer))
                .font(Font2.body(14))
                .foregroundStyle(Palette.mutedInk)
                .monospacedDigit()
            statusButton(prayer, status)
        }
        .padding(.horizontal, Space.s4)
        .padding(.vertical, 13)
    }

    private func statusDot(_ status: PrayerStatus) -> some View {
        Rectangle()
            .fill(dotColor(status))
            .frame(width: 7, height: 7)
    }
    private func dotColor(_ status: PrayerStatus) -> Color {
        switch status {
        case .pending: return Palette.divider
        case .done:    return Palette.accent
        case .missed:  return Palette.accent900
        }
    }

    private func statusButton(_ prayer: Prayer, _ status: PrayerStatus) -> some View {
        Button { state.cycleStatus(prayer) } label: {
            Text(status.label.uppercased())
                .font(Font2.medium(10.5))
                .tracking(1)
                .foregroundStyle(buttonInk(status))
                .frame(width: 74, height: 30)
                .background(buttonFill(status))
                .overlay(Rectangle().stroke(status == .pending ? Palette.divider : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
    private func buttonFill(_ status: PrayerStatus) -> Color {
        switch status {
        case .pending: return .clear
        case .done:    return Palette.accent
        case .missed:  return Palette.accent900
        }
    }
    private func buttonInk(_ status: PrayerStatus) -> Color {
        status == .pending ? Palette.mutedInk : Palette.paperInk
    }

    // MARK: - Qadha owing row

    private var qadhaRow: some View {
        NavigationLink(value: HomeRoute.qadha) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Qadha owing")
                        .font(Font2.condensed(18))
                        .foregroundStyle(Palette.text)
                    Text("Across August 2026")
                        .font(Font2.body(12.5))
                        .foregroundStyle(Palette.mutedInk)
                }
                Spacer()
                Text("\(state.qadhaTotal)")
                    .font(Font2.condensed(30))
                    .foregroundStyle(Palette.accent700)
                    .monospacedDigit()
            }
            .padding(Space.s4)
            .blueprint()
        }
        .buttonStyle(.plain)
    }
}

enum HomeRoute: Hashable { case qadha }
