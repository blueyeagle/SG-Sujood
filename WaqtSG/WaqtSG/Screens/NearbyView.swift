import SwiftUI
import MapKit
import CoreLocation

struct NearbyView: View {
    @EnvironmentObject var state: AppState

    // Approximate Orchard-area coordinates for each space (production: from the database / OneMap).
    private static let coords: [String: CLLocationCoordinate2D] = [
        "ION Orchard":   .init(latitude: 1.3040, longitude: 103.8318),
        "Wisma Atria":   .init(latitude: 1.3048, longitude: 103.8324),
        "Ngee Ann City": .init(latitude: 1.3030, longitude: 103.8347),
        "Masjid Al-Falah": .init(latitude: 1.3015, longitude: 103.8375),
        "Paragon":       .init(latitude: 1.3038, longitude: 103.8360),
    ]
    private let userCoord = CLLocationCoordinate2D(latitude: 1.3038, longitude: 103.8335)

    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(center: .init(latitude: 1.3035, longitude: 103.8340),
                           span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012))
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s4) {
                ScreenTitle(title: "Nearby").padding(.top, 12)

                HStack(spacing: Space.s2) {
                    ForEach(AppState.SpaceFilter.allCases, id: \.self) { f in
                        FilterButton(title: f.rawValue, selected: state.spaceFilter == f) {
                            state.spaceFilter = f
                        }
                    }
                    Spacer()
                }

                map

                VStack(spacing: 0) {
                    ForEach(Array(state.filteredSpaces.enumerated()), id: \.element.id) { idx, s in
                        if idx > 0 { Hairline() }
                        NavigationLink(value: s) { spaceRow(s) }
                            .buttonStyle(.plain)
                    }
                }
                .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))

                GhostButton(title: "Add a space you know") {}
                    .padding(.top, Space.s2)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
        .navigationDestination(for: PrayerSpace.self) { SpaceDetailView(space: $0) }
    }

    private var map: some View {
        Map(position: $camera, interactionModes: [.pan, .zoom]) {
            Annotation("You", coordinate: userCoord) {
                Circle()
                    .fill(Palette.accent)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Palette.paperInk, lineWidth: 2))
            }
            ForEach(state.filteredSpaces) { s in
                if let c = Self.coords[s.name] {
                    Annotation("\(shortName(s.name)) · \(s.walkMinutes)m", coordinate: c) {
                        Rectangle()
                            .fill(Palette.accent)
                            .frame(width: 12, height: 12)
                            .overlay(Rectangle().stroke(Palette.paperInk, lineWidth: 1.5))
                    }
                }
            }
        }
        .frame(height: 210)
        .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
        .mapStyle(.standard(elevation: .flat))
    }

    private func shortName(_ name: String) -> String {
        switch name {
        case "Ngee Ann City": return "Ngee Ann"
        case "Masjid Al-Falah": return "Al-Falah"
        default: return name
        }
    }

    private func spaceRow(_ s: PrayerSpace) -> some View {
        HStack(alignment: .top, spacing: Space.s3) {
            VStack(alignment: .leading, spacing: 3) {
                Text(s.name)
                    .font(Font2.condensed(19))
                    .foregroundStyle(Palette.text)
                Text("\(s.type.rawValue) · \(s.floorLandmark)")
                    .font(Font2.body(13))
                    .foregroundStyle(Palette.mutedInk)
                Text(s.jumuah ?? "Confirmed \(s.confirmedDaysAgo) days ago")
                    .font(Font2.body(12))
                    .foregroundStyle(Palette.mutedInk)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: -2) {
                Text("\(s.walkMinutes)")
                    .font(Font2.condensed(34))
                    .foregroundStyle(Palette.text)
                    .monospacedDigit()
                CapsLabel("min", size: 9)
            }
        }
        .padding(.horizontal, Space.s4)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}
