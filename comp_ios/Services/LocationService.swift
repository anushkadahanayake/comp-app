import Foundation
import CoreLocation
import Combine
import UIKit

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    @Published private(set) var currentLatitude: Double?
    @Published private(set) var currentLongitude: Double?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?

    var currentCoordinate: CLLocationCoordinate2D? {
        guard let lat = currentLatitude, let lon = currentLongitude else { return nil }
        return AFCoordinateMake(lat, lon)
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
        manager.distanceFilter = 5
        authorizationStatus = manager.authorizationStatus
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
        if authorizationStatus == .notDetermined {
            requestPermission()
            return
        }
        if isAuthorized {
            manager.requestLocation()
            startUpdating()
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func apply(_ location: CLLocation?) {
        guard let location else {
            currentLatitude = nil
            currentLongitude = nil
            return
        }
        currentLatitude = AFLatitudeFromLocation(location)
        currentLongitude = AFLongitudeFromLocation(location)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if self.isAuthorized {
                self.locationError = nil
                manager.startUpdatingLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async {
            self.apply(locations.last)
            self.locationError = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
        }
    }
}
