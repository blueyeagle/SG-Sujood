import SwiftUI
import CoreLocation
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject var state: AppState
    @StateObject private var permissions = PermissionRequester()

    var body: some View {
        ZStack {
            Palette.accent900.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s6) {
                    CapsLabel("SG Sujood", color: Palette.accent400, size: 12)
                        .padding(.top, 24)

                    Text("Know the time.\nKnow the room.")
                        .font(Font2.condensed(40))
                        .foregroundStyle(Palette.paperInk)
                        .lineSpacing(2)

                    Text("Prayer times from MUIS, and the nearest musollah in whichever mall, office tower or MRT interchange you happen to be standing in.")
                        .font(Font2.body(15))
                        .foregroundStyle(Palette.paperInkMuted)
                        .lineSpacing(3)

                    explainer(
                        title: "Use your location",
                        body: "So timings match your area and nearby spaces sort by walking distance. Location is used on device only."
                    )
                    explainer(
                        title: "Silent reminders",
                        body: "A vibration at each waktu, and a nudge 15 minutes before. Nothing will sound out loud in a meeting."
                    )

                    Spacer(minLength: Space.s6)

                    VStack(spacing: Space.s3) {
                        PrimaryButton(title: "Allow and continue") {
                            permissions.request {
                                withAnimation { state.onboarded = true }
                            }
                        }
                        Button {
                            withAnimation { state.onboarded = true }
                        } label: {
                            Text("Set my location manually")
                                .font(Font2.body(14))
                                .foregroundStyle(Palette.paperInkMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Space.gutter)
                .padding(.bottom, 24)
                .frame(minHeight: UIScreen.main.bounds.height - 80, alignment: .top)
            }
        }
    }

    private func explainer(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Font2.condensed(19))
                .foregroundStyle(Palette.paperInk)
            Text(body)
                .font(Font2.body(13.5))
                .foregroundStyle(Palette.paperInkMuted)
                .lineSpacing(2)
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .blueprint(onDark: true)
    }
}

// Triggers the real CLLocationManager + UNUserNotificationCenter prompts from the button.
final class PermissionRequester: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: (() -> Void)?

    func request(_ done: @escaping () -> Void) {
        completion = done
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) { _, _ in
            DispatchQueue.main.async { self.completion?(); self.completion = nil }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // No-op: continuation is driven by the notification callback.
    }
}
