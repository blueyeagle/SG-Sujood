import SwiftUI

@main
struct WaqtSGApp: App {
    @StateObject private var state = AppState()
    @StateObject private var nisab = NisabStore()

    init() { FontRegistrar.register() }

    var body: some Scene {
        WindowGroup {
            Group {
                if let screen = ProcessInfo.processInfo.environment["WAQT_SCREEN"] {
                    DebugScreen(name: screen)          // UI-verification hook (launch env only)
                } else if state.onboarded {
                    RootShell()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(state)
            .environmentObject(nisab)
            .tint(Palette.accent)
            .preferredColorScheme(.light)   // The design is authored on a light technical ground.
            .task { await nisab.refresh() }  // pull latest nisab from remote config
        }
    }
}

// Renders a single screen for headless screenshot verification. Reached only when the
// WAQT_SCREEN launch environment variable is set; never wired into the shipping UI.
struct DebugScreen: View {
    let name: String
    var body: some View {
        NavigationStack {
            switch name {
            case "home":      RootShell()
            case "times":     TimetableView()
            case "nearby":    NearbyView()
            case "qibla":     QiblaView()
            case "more":      MoreView()
            case "qadha":     QadhaView()
            case "zakat":     ZakatView()
            case "dzikir":    DzikirView()
            case "ramadan":   RamadanView()
            case "reminders": RemindersView()
            case "addspace":  AddSpaceView()
            case "widgets":   WidgetsSpecView()
            case "space":     SpaceDetailView(space: SampleData.spaces[0])
            default:          RootShell()
            }
        }
    }
}
