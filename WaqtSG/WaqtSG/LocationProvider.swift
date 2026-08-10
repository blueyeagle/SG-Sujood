import Foundation
import CoreLocation
import Combine

/// Publishes the user's current location for distance sorting. Falls back to a central
/// Singapore point (Orchard MRT) when location is unavailable — e.g. on the Simulator or
/// before permission is granted — so the Nearby list always has a reference.
@MainActor
final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let fallback = CLLocation(latitude: 1.304, longitude: 103.8318)  // Orchard

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastGeocoded: CLLocation?

    @Published private(set) var current: CLLocation = LocationProvider.fallback
    @Published private(set) var isReal = false
    @Published private(set) var areaName: String = "Orchard, Singapore"

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func start() {
        manager.startUpdatingLocation()
    }

    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last else { return }
        Task { @MainActor in
            self.current = loc
            self.isReal = true
            self.reverseGeocodeIfNeeded(loc)
        }
    }

    /// Reverse-geocode to a readable area name, throttled to ~200 m of movement.
    private func reverseGeocodeIfNeeded(_ loc: CLLocation) {
        if let last = lastGeocoded, loc.distance(from: last) < 200 { return }
        lastGeocoded = loc
        geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
            guard let self, let p = placemarks?.first else { return }
            let area = p.subLocality ?? p.locality ?? p.name ?? "Singapore"
            let name = (p.country == "Singapore" || p.isoCountryCode == "SG") ? "\(area), Singapore" : area
            Task { @MainActor in self.areaName = name }
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError error: Error) { }

    nonisolated func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        let status = m.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            m.startUpdatingLocation()
        }
    }
}
