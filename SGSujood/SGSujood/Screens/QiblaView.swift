import SwiftUI
import CoreLocation

struct QiblaView: View {
    @StateObject private var heading = HeadingProvider()
    @State private var aligned = false
    @State private var recalibrating = false
    private let bearing = SampleData.qiblaBearing

    // Alignment colours
    private let green  = Palette.success          // soft green, matches "done"
    private let yellow = Color(hex: 0xC79A2E)
    private let red    = Palette.missed            // muted rose

    /// Signed difference between the qibla bearing and current heading, in −180…180.
    private var signedDiff: Double {
        var d = (bearing - heading.degrees).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }
    private var delta: Double { abs(signedDiff) }
    private var isAligned: Bool { delta <= 5 }
    private var alignColor: Color {
        if delta <= 5 { return green }
        if delta <= 25 { return yellow }
        return red
    }
    private var turnHint: String { signedDiff > 0 ? "turn right" : "turn left" }

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
                    .padding(.vertical, Space.s8)
                    .background(Palette.accent900)

                if heading.hasHeading {
                    HStack(spacing: Space.s4) {
                        legendDot(green, "Aligned")
                        legendDot(yellow, "Close")
                        legendDot(red, "Turn")
                        Spacer()
                    }
                }

                note

                GhostButton(title: recalibrating ? "Recalibrating…" : "Recalibrate compass") {
                    Haptics.light()
                    heading.recalibrate()
                    recalibrating = true
                    Task { try? await Task.sleep(nanoseconds: 2_000_000_000); recalibrating = false }
                }

                if !heading.hasHeading {
                    Text("Compass needs a device with a magnetometer — it won't move in the Simulator.")
                        .font(Font2.body(12.5))
                        .foregroundStyle(Palette.mutedInk)
                } else if heading.needsCalibration {
                    Text("Compass accuracy is low — move away from metal and wave the phone in a figure-eight.")
                        .font(Font2.body(12.5))
                        .foregroundStyle(Palette.accent700)
                }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
        .onChange(of: heading.degrees) { _, _ in
            // Nudge once when we enter alignment.
            if isAligned && !aligned { Haptics.success() }
            aligned = isAligned
        }
    }

    // The active colour: alignment state when we have a heading, else gold.
    private var c: Color { heading.hasHeading ? alignColor : Palette.accent }
    private let D: CGFloat = 300

    private var compass: some View {
        ZStack {
            // Diamond lattice (Islamic tessellation), clipped to a circle
            latticeCanvas
                .frame(width: D * 0.80, height: D * 0.80)
                .clipShape(Circle())
            Circle().stroke(c.opacity(0.28), lineWidth: 1).frame(width: D * 0.80, height: D * 0.80)

            // Octagonal frame
            Octagon().stroke(c.opacity(0.9), lineWidth: 1.5).frame(width: D, height: D)

            // Rotating N/E/S/W dial — reflects real-world north
            dial.rotationEffect(.degrees(-heading.degrees))

            // Needle to the Kaaba, relative to current heading
            needleView.rotationEffect(.degrees(signedDiff))

            // Centre readout
            VStack(spacing: 2) {
                if heading.hasHeading {
                    Text(isAligned ? "0°" : "\(Int(delta))°")
                        .font(Font2.condensed(48))
                        .foregroundStyle(alignColor)
                        .monospacedDigit()
                    CapsLabel(isAligned ? "Facing qibla" : turnHint, color: alignColor, size: 10)
                } else {
                    Text("\(Int(bearing))°")
                        .font(Font2.condensed(48))
                        .foregroundStyle(Palette.paperInk)
                        .monospacedDigit()
                    CapsLabel(compassPoint(bearing), color: Palette.accent400, size: 10)
                }
            }
        }
        .frame(width: D, height: D)
    }

    private var latticeCanvas: some View {
        Canvas { ctx, size in
            let step = size.width / 8
            var path = Path()
            var k = -size.height
            while k < size.width {
                path.move(to: CGPoint(x: k, y: 0)); path.addLine(to: CGPoint(x: k + size.height, y: size.height))
                path.move(to: CGPoint(x: k, y: size.height)); path.addLine(to: CGPoint(x: k + size.height, y: 0))
                k += step
            }
            ctx.stroke(path, with: .color(c.opacity(0.16)), lineWidth: 0.8)
        }
    }

    private var dial: some View {
        let r = D * 0.5 - 4
        return ZStack {
            ForEach(Array(["N", "E", "S", "W"].enumerated()), id: \.offset) { i, mark in
                let ang = Double(i) * .pi / 2   // N,E,S,W clockwise from top
                Text(mark)
                    .font(Font2.medium(13))
                    .foregroundStyle(mark == "N" ? c : Palette.paperInkMuted)
                    .rotationEffect(.degrees(heading.degrees))   // counter the dial's rotation → stays upright
                    .offset(x: r * sin(ang), y: -r * cos(ang))
            }
        }
        .frame(width: D, height: D)
    }

    private var needleView: some View {
        let len = D * 0.40
        return ZStack {
            Rectangle()
                .fill(c)
                .frame(width: isAligned && heading.hasHeading ? 2.5 : 1.5, height: len)
                .offset(y: -len / 2)
            kaabaMarker.offset(y: -len)
        }
        .frame(width: D, height: D)
    }

    // Small Kaaba glyph at the needle tip (cube + kiswah band).
    private var kaabaMarker: some View {
        ZStack {
            Rectangle().fill(c).frame(width: 18, height: 16)
            Rectangle().fill(Palette.accent900).frame(width: 18, height: 2.5).offset(y: -3)
        }
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Rectangle().fill(color).frame(width: 10, height: 10)
            Text(label).font(Font2.body(12)).foregroundStyle(Palette.mutedInk)
        }
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

// Regular octagon with a vertex at the top (N / E / S / W at the cardinal vertices).
struct Octagon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY, r = min(rect.width, rect.height) / 2
        for i in 0..<8 {
            let a = Double(i) * .pi / 4 - .pi / 2   // start at the top
            let pt = CGPoint(x: cx + r * cos(a), y: cy + r * sin(a))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

final class HeadingProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var degrees: Double = 0
    @Published var needsCalibration = false
    @Published var hasHeading = false   // false on devices without a magnetometer (e.g. Simulator)

    override init() {
        super.init()
        manager.delegate = self
        // Verification hook: seed a heading on the Simulator (no magnetometer). Launch env only.
        if let v = ProcessInfo.processInfo.environment["SGSUJOOD_QIBLA_HEADING"], let d = Double(v) {
            degrees = d; hasHeading = true; return
        }
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
            self.hasHeading = true
            self.needsCalibration = newHeading.headingAccuracy < 0 || newHeading.headingAccuracy > 20
        }
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool { true }
}
