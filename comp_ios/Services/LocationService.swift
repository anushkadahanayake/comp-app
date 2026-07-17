import Foundation
import CoreLocation
import Combine
import MapKit
import UIKit

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    /// Used when GPS is unavailable so the map doesn't jump to the US.
    static let sriLankaFallback = AFCoordinateMake(7.8731, 80.7718)

    private let manager = CLLocationManager()
    @Published private(set) var currentLatitude: Double?
    @Published private(set) var currentLongitude: Double?
    @Published private(set) var horizontalAccuracy: Double?
    @Published private(set) var placeLabel: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?

    private var reverseGeocodeTask: Task<Void, Never>?

    var currentCoordinate: CLLocationCoordinate2D? {
        guard let lat = currentLatitude, let lon = currentLongitude else { return nil }
        return AFCoordinateMake(lat, lon)
    }

    /// Best camera target: live GPS → Sri Lanka fallback (never Apple US default).
    var preferredMapCoordinate: CLLocationCoordinate2D {
        currentCoordinate ?? Self.sriLankaFallback
    }

    var hasFix: Bool { currentLatitude != nil && currentLongitude != nil }

    var coordinateLabel: String? {
        guard let lat = currentLatitude, let lon = currentLongitude else { return nil }
        return String(format: "%.4f, %.4f", lat, lon)
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var statusLabel: String {
        switch authorizationStatus {
        case .notDetermined: return "Not Asked"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always Allowed"
        case .authorizedWhenInUse: return "While Using App"
        @unknown default: return "Unknown"
        }
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        manager.activityType = .other
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus

        // Restore last good fix quickly (helps after relaunch).
        if let cached = manager.location, isUsable(cached) {
            apply(cached)
        }
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        guard isAuthorized else { return }
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    func refreshLocation() {
        locationError = nil
        if authorizationStatus == .notDetermined {
            requestPermission()
            return
        }
        guard isAuthorized else {
            locationError = "Location permission is off. Enable it in Settings."
            return
        }
        manager.requestLocation()
        manager.startUpdatingLocation()
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func isUsable(_ location: CLLocation) -> Bool {
        // Reject invalid / wildly inaccurate readings.
        location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 2000
    }

    private func apply(_ location: CLLocation?) {
        guard let location, isUsable(location) else { return }
        currentLatitude = AFLatitudeFromLocation(location)
        currentLongitude = AFLongitudeFromLocation(location)
        horizontalAccuracy = location.horizontalAccuracy
        reverseGeocode(location)
    }

    private func reverseGeocode(_ location: CLLocation) {
        reverseGeocodeTask?.cancel()
        reverseGeocodeTask = Task { [weak self] in
            guard let self else { return }
            guard let request = MKReverseGeocodingRequest(location: location) else { return }
            do {
                let mapItems = try await request.mapItems
                guard !Task.isCancelled else { return }
                let label = Self.placeLabel(from: mapItems.first)
                await MainActor.run {
                    if let label {
                        self.placeLabel = label
                    }
                }
            } catch {
                // Keep last place label; GPS fix is still valid without a name.
            }
        }
    }

    private static func placeLabel(from mapItem: MKMapItem?) -> String? {
        guard let mapItem else { return nil }
        if let short = mapItem.address?.shortAddress, !short.isEmpty {
            return short
        }
        if let full = mapItem.address?.fullAddress, !full.isEmpty {
            return full
        }
        if let name = mapItem.name, !name.isEmpty {
            return name
        }
        return nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if self.isAuthorized {
                self.locationError = nil
                manager.startUpdatingLocation()
                manager.requestLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async {
            // Prefer the most accurate recent sample.
            let best = locations
                .filter { self.isUsable($0) }
                .sorted { $0.horizontalAccuracy < $1.horizontalAccuracy }
                .first ?? locations.last
            self.apply(best)
            self.locationError = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            // Keep last good fix; only surface the error.
            self.locationError = error.localizedDescription
        }
    }
}
