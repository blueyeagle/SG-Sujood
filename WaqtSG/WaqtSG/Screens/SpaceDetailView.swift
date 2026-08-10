import SwiftUI
import MapKit
import CoreLocation

struct SpaceDetailView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var location: LocationProvider
    let space: SpaceRecord

    private var metres: CLLocationDistance? { space.location?.distance(from: location.current) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                imageBand
                VStack(alignment: .leading, spacing: Space.s6) {
                    header
                    whereWalkGrid
                    details
                    actions
                    if let notes = space.notes { footer(notes) }
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
                    Text(space.isMosque ? space.name : "photo of the \(space.type.lowercased()) entrance\n(community submitted)")
                        .font(Font2.body(12))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Palette.mutedInk)
                        .padding(.horizontal, 40)
                }
            BackHeader()
                .padding(.leading, Space.gutter)
                .padding(.top, 56)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            CapsLabel(space.isMosque ? "Masjid" : space.type, color: Palette.accent700)
            Text(space.name)
                .font(Font2.condensed(32))
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
            if let addr = space.address {
                Text(addr)
                    .font(Font2.body(14))
                    .foregroundStyle(Palette.mutedInk)
            }
        }
    }

    private var whereWalkGrid: some View {
        HStack(spacing: 0) {
            cell(label: "Where",
                 big: space.isMosque ? space.region : (shortFloor ?? space.region),
                 note: space.floor ?? space.address ?? "")
            Rectangle().fill(Palette.divider).frame(width: 1)
            cell(label: "Walk",
                 big: metres.map { $0 >= 2000 ? String(format: "%.1f km", $0/1000) : "\(Walk.minutes($0)) min" } ?? "—",
                 note: location.isReal ? "From your location" : "From Orchard (allow location)")
        }
        .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
    }

    private var shortFloor: String? {
        guard let f = space.floor else { return nil }
        // first token like "L7", "B1", "B4" if present
        if let m = f.range(of: #"^[LB]?\d+"#, options: .regularExpression) {
            return String(f[m])
        }
        return f.count <= 4 ? f : nil
    }

    private func cell(label: String, big: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            CapsLabel(label)
            Text(big.isEmpty ? "—" : big)
                .font(Font2.condensed(28))
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
            Text(note)
                .font(Font2.body(12.5))
                .foregroundStyle(Palette.mutedInk)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            CapsLabel("Details")
            VStack(spacing: 0) {
                let items = detailItems
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    if idx > 0 { Hairline() }
                    HStack(alignment: .top) {
                        CapsLabel(item.0, size: 10)
                            .frame(width: 120, alignment: .leading)
                        Text(item.1)
                            .font(Font2.body(13.5))
                            .foregroundStyle(Palette.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 11)
                }
            }
            .padding(.horizontal, Space.s4)
            .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
        }
    }

    private var detailItems: [(String, String)] {
        var items: [(String, String)] = []
        if let f = space.facilities { items.append(("Facilities", f)) }
        if let g = space.genderSegregated { items.append(("Gender", g ? "Separate male / female areas" : "Shared / not segregated")) }
        if let a = space.access { items.append(("Access", a)) }
        if let c = space.capacity { items.append(("Capacity", "\(c) worshippers")) }
        if let y = space.yearEst { items.append(("Established", y)) }
        if let h = space.heritage { items.append(("Heritage", h)) }
        if let p = space.postal { items.append(("Postal", p)) }
        if items.isEmpty { items.append(("Access", "Public")) }
        return items
    }

    private var actions: some View {
        HStack(spacing: Space.s3) {
            PrimaryButton(title: "Directions") { openDirections() }
            let saved = state.isSaved(space.id)
            GhostButton(title: saved ? "Saved" : "Save") { state.toggleSave(space.id) }
        }
    }

    private func footer(_ notes: String) -> some View {
        Text(notes)
            .font(Font2.body(12.5))
            .foregroundStyle(Palette.mutedInk)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func openDirections() {
        guard let c = space.coordinate else { return }
        let item = MKMapItem(placemark: MKPlacemark(coordinate: c))
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
