import SwiftUI
import CoreLocation

struct QiblaView: View {
    @StateObject private var heading = HeadingProvider()
    private let bearing = SampleData.qiblaBearing

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Qibla")
                        .font(Font2.condensed(34))
                        .foregroundStyle(Palette.text)
                    Text("Hold the phone flat and turn slowly")
                        .font(Font2.body(13))
                        .foregroundStyle(Palette.mutedInk)
                }
                .padding(.top, 12)

                compass
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Space.s6)

                note

                GhostButton(title: "Recalibrate compass") { heading.recalibrate() }

                if heading.needsCalibration {
                    Text("Compass accuracy is low — move away from metal and wave the phone in a figure-eight.")
                        .font(Font2.body(12.5))
                        .foregroundStyle(Palette.accent700)
                }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
    }

    private var compass: some View {
        ZStack {
            // Outer + inner ring
            Circle().stroke(Palette.divider, lineWidth: 1).frame(width: 280, height: 280)
            Circle().stroke(Palette.divider, lineWidth: 1).frame(width: 214, height: 214)

            // Rotating dial (N/E/S/W) — reflects real-world north
            dial.rotationEffect(.degrees(-heading.degrees))

            // Needle to qibla, relative to current heading
            needle
                .rotationEffect(.degrees(bearing - heading.degrees))

            // Centre readout
            VStack(spacing: 2) {
                Text("\(Int(bearing))°")
                    .font(Font2.condensed(48))
                    .foregroundStyle(Palette.text)
                    .monospacedDigit()
                CapsLabel(compassPoint(bearing), size: 10)
            }
        }
        .frame(width: 280, height: 280)
    }

    private var dial: some View {
        ZStack {
            ForEach(Array(["N", "E", "S", "W"].enumerated()), id: \.offset) { i, mark in
                Text(mark)
                    .font(Font2.medium(13))
                    .foregroundStyle(mark == "N" ? Palette.accent700 : Palette.mutedInk)
                    .offset(y: -122)
                    .rotationEffect(.degrees(Double(i) * 90))
            }
        }
        .frame(width: 280, height: 280)
    }

    private var needle: some View {
        VStack(spacing: 0) {
            // Diamond marker at the tip
            Rectangle()
                .fill(Palette.accent)
                .frame(width: 10, height: 10)
                .rotationEffect(.degrees(45))
            Rectangle()
                .fill(Palette.accent)
                .frame(width: 1, height: 96)
            Spacer().frame(height: 96 + 10)
        }
        .frame(height: 280)
    }

    private func compassPoint(_ deg: Double) -> String {
        switch deg {
        case 293: return "Northwest"
        case 0..<22.5, 337.5...360: return "North"
        case 22.5..<67.5: return "Northeast"
        case 67.5..<112.5: return "East"
        case 112.5..<157.5: return "Southeast"
        case 157.5..<202.5: return "South"
        case 202.5..<247.5: return "Southwest"
        case 247.5..<292.5: return "West"
        default: return "Northwest"
        }
    }

    private var note: some View {
        Text("From Singapore the Kaaba lies 293° from true north — roughly the direction of the Botanic Gardens if you are standing on Orchard Road.")
            .font(Font2.body(13))
            .foregroundStyle(Palette.mutedInk)
            .lineSpacing(3)
            .padding(Space.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .blueprint()
    }
}

final class HeadingProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var degrees: Double = 0
    @Published var needsCalibration = false

    override init() {
        super.init()
        manager.delegate = self
        if CLLocationManager.headingAvailable() {
            manager.headingFilter = 1
            manager.startUpdatingHeading()
        }
    }

    func recalibrate() {
        manager.stopUpdatingHeading()
        manager.startUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let h = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        DispatchQueue.main.async {
            self.degrees = h
            self.needsCalibration = newHeading.headingAccuracy < 0 || newHeading.headingAccuracy > 20
        }
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool { true }
}
