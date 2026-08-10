import SwiftUI
import MapKit

struct SpaceDetailView: View {
    @EnvironmentObject var state: AppState
    let space: PrayerSpace

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                imageBand

                VStack(alignment: .leading, spacing: Space.s6) {
                    header
                    whereWalkGrid
                    gettingThere
                    actions
                    footer
                }
                .padding(.horizontal, Space.gutter)
            }
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
    }

    private var imageBand: some View {
        ZStack(alignment: .topLeading) {
            HatchPattern()
                .frame(height: 190 + 60)
                .clipped()
                .overlay(alignment: .center) {
                    Text("photo of the \(space.type.rawValue.lowercased()) entrance\n(community submitted)")
                        .font(Font2.body(12))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Palette.mutedInk)
                }
            BackHeader()
                .padding(.leading, Space.gutter)
                .padding(.top, 56)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            CapsLabel(space.type.rawValue, color: Palette.accent700)
            Text(space.name)
                .font(Font2.condensed(32))
                .foregroundStyle(Palette.text)
            Text("\(space.address) · \(space.closing)")
                .font(Font2.body(14))
                .foregroundStyle(Palette.mutedInk)
        }
    }

    private var whereWalkGrid: some View {
        HStack(spacing: 0) {
            cell(label: "Where", big: space.floorBadge, note: space.landmarkSentence)
            Rectangle().fill(Palette.divider).frame(width: 1)
            cell(label: "Walk", big: "\(space.walkMinutes) min", note: space.originFrom)
        }
        .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
    }

    private func cell(label: String, big: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            CapsLabel(label)
            Text(big)
                .font(Font2.condensed(30))
                .foregroundStyle(Palette.text)
            Text(note)
                .font(Font2.body(12.5))
                .foregroundStyle(Palette.mutedInk)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
    }

    private var gettingThere: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            CapsLabel("Getting there")
            HStack(alignment: .top, spacing: Space.s3) {
                Rectangle().fill(Palette.divider).frame(width: 1)
                VStack(alignment: .leading, spacing: Space.s4) {
                    ForEach(Array(space.steps.enumerated()), id: \.offset) { _, step in
                        HStack(alignment: .top, spacing: Space.s3) {
                            AccentSquare().padding(.top, 5)
                            Text(step)
                                .font(Font2.body(14))
                                .foregroundStyle(Palette.text)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.leading, 2)
        }
    }

    private var actions: some View {
        HStack(spacing: Space.s3) {
            PrimaryButton(title: "Directions") { openDirections() }
            let saved = state.savedSpaces.contains(space.id)
            GhostButton(title: saved ? "Saved" : "Save") { state.toggleSave(space) }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            (Text("Last confirmed \(space.confirmedDaysAgo) days ago by a Waqt SG user. ")
                .foregroundStyle(Palette.mutedInk)
             + Text("Something changed?")
                .foregroundStyle(Palette.accent700))
                .font(Font2.body(12.5))
                .lineSpacing(2)
        }
    }

    private func openDirections() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate:
            CLLocationCoordinate2D(latitude: 1.3040, longitude: 103.8318)))
        item.name = space.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}

// Diagonal hatch — stands in for the duotoned entrance photo.
struct HatchPattern: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Palette.surface))
                var path = Path()
                let step: CGFloat = 9
                var x: CGFloat = -size.height
                while x < size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                    x += step
                }
                ctx.stroke(path, with: .color(Palette.divider), lineWidth: 1)
            }
        }
    }
}
