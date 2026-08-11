import SwiftUI

enum Tab: String, CaseIterable {
    case home = "Home", times = "Times", nearby = "Nearby", qibla = "Qibla", more = "More"
}

struct RootShell: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()
            switch state.selectedTab {
            case .home:
                NavigationStack { HomeView().rootTabBar($state.selectedTab) }
            case .times:
                NavigationStack { TimetableView().rootTabBar($state.selectedTab) }
            case .nearby:
                NavigationStack { NearbyView().rootTabBar($state.selectedTab) }
            case .qibla:
                NavigationStack { QiblaView().rootTabBar($state.selectedTab) }
            case .more:
                NavigationStack { MoreView().rootTabBar($state.selectedTab) }
            }
        }
    }
}

// MARK: - Type-only tab bar
// Caps labels, a 2px accent rule above the active one, 76px tall, 1px top divider.
// Attached only to root screens, so it is hidden on every pushed screen.

struct TabBar: View {
    @Binding var selection: Tab

    var body: some View {
        VStack(spacing: 0) {
            Hairline()
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Button {
                        Haptics.selection()
                        selection = t
                    } label: {
                        VStack(spacing: 6) {
                            Rectangle()
                                .fill(selection == t ? Palette.accent : Color.clear)
                                .frame(width: 26, height: 2)
                            CapsLabel(t.rawValue,
                                      color: selection == t ? Palette.text : Palette.mutedInk,
                                      size: 10.5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 76)
        }
        .background(Palette.bg)
    }
}

extension View {
    func rootTabBar(_ selection: Binding<Tab>) -> some View {
        self.safeAreaInset(edge: .bottom, spacing: 0) {
            TabBar(selection: selection)
        }
    }
}
