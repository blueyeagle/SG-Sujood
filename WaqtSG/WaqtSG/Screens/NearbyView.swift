import SwiftUI
import MapKit
import CoreLocation

struct NearbyView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var spaces: SpacesStore
    @EnvironmentObject var location: LocationProvider

    @State private var camera: MapCameraPosition = .automatic

    private var sorted: [SpaceRecord] {
        spaces.sortedByDistance(from: location.current, filter: state.spaceFilter)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s4) {
                HStack(alignment: .firstTextBaseline) {
                    ScreenTitle(title: "Nearby")
                    Spacer()
                    Text("\(sorted.count)")
                        .font(Font2.condensed(20))
                        .foregroundStyle(Palette.mutedInk)
                        .monospacedDigit()
                }
                .padding(.top, 12)

                HStack(spacing: Space.s2) {
                    ForEach(AppState.SpaceFilter.allCases, id: \.self) { f in
                        FilterButton(title: f.rawValue, selected: state.spaceFilter == f) {
                            state.spaceFilter = f
                        }
                    }
                    Spacer()
                }

                map

                if !location.isReal {
                    Text("Showing distance from Orchard — allow location for spaces near you.")
                        .font(Font2.body(12))
                        .foregroundStyle(Palette.mutedInk)
                }

                LazyVStack(spacing: 0) {
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, s in
                        if idx > 0 { Hairline() }
                        NavigationLink(value: s) { spaceRow(s) }
                            .buttonStyle(.plain)
                    }
                }
                .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))

                NavigationLink(value: NearbyRoute.addSpace) {
                    Text("Add a space you know")
                        .font(Font2.condensed(17)).tracking(0.5)
                        .foregroundStyle(Palette.text)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, Space.s2)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
        .navigationDestination(for: SpaceRecord.self) { SpaceDetailView(space: $0) }
        .navigationDestination(for: NearbyRoute.self) { _ in AddSpaceView() }
    }

    private var map: some View {
        // Cap pins to the nearest 40 for performance across 165 spaces.
        let pins = Array(sorted.prefix(40)).filter { $0.coordinate != nil }
        return Map(position: $camera) {
            UserAnnotation()
            ForEach(pins) { s in
                Annotation(s.name, coordinate: s.coordinate!) {
                    Rectangle()
                        .fill(s.isMosque ? Palette.accent900 : Palette.accent)
                        .frame(width: 11, height: 11)
                        .overlay(Rectangle().stroke(Palette.paperInk, lineWidth: 1.5))
                }
            }
        }
        .frame(height: 220)
        .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
        .mapStyle(.standard(elevation: .flat))
        .onAppear {
            camera = .region(MKCoordinateRegion(
                center: location.current.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))
        }
    }

    private func spaceRow(_ s: SpaceRecord) -> some View {
        let metres = s.location?.distance(from: location.current)
        return HStack(alignment: .top, spacing: Space.s3) {
            VStack(alignment: .leading, spacing: 3) {
                Text(s.name)
                    .font(Font2.condensed(19))
                    .foregroundStyle(Palette.text)
                Text(s.subtitle)
                    .font(Font2.body(13))
                    .foregroundStyle(Palette.mutedInk)
                    .lineLimit(1)
                if let extra = metaLine(s) {
                    Text(extra)
                        .font(Font2.body(12))
                        .foregroundStyle(Palette.mutedInk)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: -2) {
                if let metres {
                    Text(metres >= 2000 ? String(format: "%.1f", metres/1000) : "\(Walk.minutes(metres))")
                        .font(Font2.condensed(30))
                        .foregroundStyle(Palette.text)
                        .monospacedDigit()
                    CapsLabel(metres >= 2000 ? "km" : "min walk", size: 9)
                } else {
                    CapsLabel(s.region, size: 9)
                }
            }
        }
        .padding(.horizontal, Space.s4)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func metaLine(_ s: SpaceRecord) -> String? {
        if let addr = s.address { return addr }
        return s.notes
    }
}

enum NearbyRoute: Hashable { case addSpace }
