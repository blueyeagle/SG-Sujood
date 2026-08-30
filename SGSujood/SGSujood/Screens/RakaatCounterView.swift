import SwiftUI
import AVFoundation

// Rak'ah / sujud counter — a prototype that watches your posture through the camera and counts
// how many times you stand and go into sujud. Everything runs on device; nothing is recorded.

struct RakaatCounterView: View {
    @StateObject private var cam = PoseCamera()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                HStack { BackHeader(); Spacer() }.padding(.top, 8)
                ScreenTitle(title: "Rak'ah counter",
                            subtitle: "Counts on device from your posture — never recorded.")

                previewArea
                counters
                controls
                tips
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
        .navigationBarBackButtonHidden(true)
        .task { cam.start() }
        .onDisappear { cam.stop() }
    }

    // MARK: Preview / permission

    @ViewBuilder private var previewArea: some View {
        switch cam.authorization {
        case .denied, .restricted:
            permissionCard
        default:
            ZStack {
                CameraPreview(session: cam.session)
                    .overlay(SkeletonOverlay(points: cam.overlayPoints))
                    .overlay(alignment: .topLeading) { posturePill.padding(10) }
                    .overlay(alignment: .topTrailing) { flipButton.padding(10) }
                    .overlay(alignment: .bottomLeading) { framingHint.padding(10) }
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Palette.divider, lineWidth: 1))
            }
            .frame(height: 440)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var posturePill: some View {
        let color: Color
        switch cam.posture {
        case .sujud:    color = Palette.success
        case .standing: color = Palette.accent
        case .ruku:     color = Palette.accent700
        case .sitting:  color = Palette.mutedInk
        case .unknown:  color = Palette.mutedInk
        }
        return Text(cam.posture.label.uppercased())
            .font(Font2.condensed(15))
            .tracking(1)
            .foregroundStyle(.white)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(color))
    }

    private var flipButton: some View {
        Button { cam.flipCamera() } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 13, weight: .semibold))
                Text(cam.usingFront ? "Front" : "Wide")
                    .font(Font2.condensed(13))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.55)))
        }
    }

    @ViewBuilder private var framingHint: some View {
        if !cam.bodyInFrame {
            Text("Step back so your whole body is in frame")
                .font(Font2.body(12))
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(Color.black.opacity(0.55)))
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Camera access needed")
                .font(Font2.condensed(20))
                .foregroundStyle(Palette.text)
            Text("This counter reads your posture through the camera, live and on device. Video is never recorded or uploaded. Enable camera access to use it.")
                .font(Font2.body(13))
                .foregroundStyle(Palette.mutedInk)
                .lineSpacing(2)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(Font2.condensed(16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Capsule().fill(Palette.accent))
            }
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .blueprint()
    }

    // MARK: Counters

    private var counters: some View {
        VStack(spacing: Space.s3) {
            // Hero: total rak'ah completed so far — big enough to read at a glance from your mat,
            // so you can check where you are if you lose track.
            VStack(spacing: 0) {
                Text("\(cam.rakaat)")
                    .font(Font2.condensed(104))
                    .foregroundStyle(Palette.accent)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("rak'ah completed")
                    .font(Font2.condensed(18))
                    .foregroundStyle(Palette.text)
                Text("counts after the 2nd sujud of each rak'ah")
                    .font(Font2.body(11.5))
                    .foregroundStyle(Palette.mutedInk)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Space.s4)
            .blueprint()

            HStack(spacing: Space.s3) {
                stat("Sujud", cam.sujudCount, Palette.success)
                stat("Stand-ups", cam.standUps, Palette.accent700)
            }
        }
    }

    private func stat(_ title: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(Font2.condensed(40))
                .foregroundStyle(color)
                .monospacedDigit()
            CapsLabel(title)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Space.s3)
        .blueprint()
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: Space.s3) {
            Button { cam.reset() } label: {
                Text("Reset")
                    .font(Font2.condensed(16))
                    .foregroundStyle(Palette.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.divider, lineWidth: 1))
            }
            Button { cam.isRunning ? cam.stop() : cam.start() } label: {
                Text(cam.isRunning ? "Pause" : "Resume")
                    .font(Font2.condensed(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Palette.accent))
            }
        }
    }

    // MARK: Tips

    private var tips: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tips")
                .font(Font2.condensed(16))
                .foregroundStyle(Palette.text)
            ForEach([
                "Place the phone in front of you, tilted up, so your whole body — head to the floor — stays in view. A little elevation (on a low stand) helps.",
                "Tap Front / Wide (top-right): the front camera lets you see yourself (~1.5–2 m); the Wide back lens fits you in from ~1 m — set it up, then face it (screen away).",
                "A slight side angle makes ruku' vs. sujud clearest, but front works for counting.",
                "Good, even lighting improves detection.",
                "Rak'ah is estimated as sujud ÷ 2. This is a prototype — verify your count.",
            ], id: \.self) { t in
                HStack(alignment: .top, spacing: 8) {
                    Text("•").foregroundStyle(Palette.accent)
                    Text(t).font(Font2.body(12.5)).foregroundStyle(Palette.mutedInk).lineSpacing(2)
                }
            }
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .blueprint()
    }
}

// Simple dot overlay showing the detected joints (normalised, top-left origin).
private struct SkeletonOverlay: View {
    let points: [CGPoint]
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                for p in points {
                    let rect = CGRect(x: p.x * size.width - 4, y: p.y * size.height - 4,
                                      width: 8, height: 8)
                    ctx.fill(Path(ellipseIn: rect), with: .color(Palette.accent.opacity(0.9)))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .allowsHitTesting(false)
        }
    }
}
