import SwiftUI

@main
struct WaqtSGApp: App {
    @StateObject private var state = AppState()
    @StateObject private var nisab = NisabStore()
    @StateObject private var spacesStore = SpacesStore()
    @StateObject private var location = LocationProvider()
    @StateObject private var routes = RouteService()

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
            .environmentObject(spacesStore)
            .environmentObject(location)
            .environmentObject(routes)
            .tint(Palette.accent)
            .preferredColorScheme(.light)   // The design is authored on a light technical ground.
            .task {
                location.start()
                await nisab.refresh()        // pull latest nisab from remote config
                await spacesStore.refresh()  // pull latest prayer-space directory
            }
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
            case "aftersolat": AfterSolatView()
            case "niatsolat": NiatSolatView()
            case "ramadan":   RamadanView()
            case "reminders": RemindersView()
            case "addspace":  AddSpaceView()
            case "widgets":   WidgetsSpecView()
            case "space":     DebugSpaceDetail()
            default:          RootShell()
            }
        }
    }
}

// Debug helper: opens the first space in the bundled directory for screenshot verification.
struct DebugSpaceDetail: View {
    @EnvironmentObject var spaces: SpacesStore
    var body: some View {
        if let s = spaces.spaces.first { SpaceDetailView(space: s) }
        else { Text("no spaces") }
    }
}
