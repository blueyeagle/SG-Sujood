import Foundation
import MapKit
import CoreLocation

// Routed walking times via MKDirections. Apple throttles Directions requests, so we:
//  • compute on demand (space detail = 1 request; Nearby = only the nearest handful),
//  • run them through a serial queue with a small gap,
//  • cache by (space, coarse origin bucket), and
//  • fall back silently to the straight-line estimate when a route is unavailable.
@MainActor
final class RouteService: ObservableObject {

    @Published private(set) var minutes: [String: Int] = [:]   // key -> routed minutes

    private var inFlight = Set<String>()
    private var queue: [(key: String, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D)] = []
    private var draining = false

    /// Bucket the origin to ~500 m so small movements reuse the cached route.
    private func key(_ id: String, _ from: CLLocationCoordinate2D) -> String {
        let la = (from.latitude * 200).rounded()
        let lo = (from.longitude * 200).rounded()
        return "\(id)|\(la)|\(lo)"
    }

    /// Routed minutes if already computed for this space from ~this origin.
    func routed(_ id: String, from: CLLocationCoordinate2D) -> Int? {
        minutes[key(id, from)]
    }

    /// Ask for a walking route (no-op if cached or already queued).
    func request(_ id: String, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        let k = key(id, from)
        if minutes[k] != nil || inFlight.contains(k) { return }
        inFlight.insert(k)
        queue.append((k, from, to))
        Task { await drain() }
    }

    func requestMany(_ items: [(id: String, to: CLLocationCoordinate2D)], from: CLLocationCoordinate2D) {
        for it in items { request(it.id, from: from, to: it.to) }
    }

    private func drain() async {
        if draining { return }
        draining = true
        defer { draining = false }
        while !queue.isEmpty {
            let job = queue.removeFirst()
            await compute(job.key, from: job.from, to: job.to)
            try? await Task.sleep(nanoseconds: 250_000_000)   // be gentle with the Directions API
        }
    }

    private func compute(_ k: String, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async {
        let req = MKDirections.Request()
        req.transportType = .walking
        req.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        do {
            let resp = try await MKDirections(request: req).calculate()
            if let t = resp.routes.first?.expectedTravelTime {
                minutes[k] = max(1, Int((t / 60).rounded()))
            }
        } catch {
            // throttled / no walking route (e.g. offshore) → leave unset, UI keeps the estimate
        }
        inFlight.remove(k)
    }
}
