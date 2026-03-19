import Foundation
import Combine
import CoreLocation

nonisolated class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @MainActor @Published var currentLocation: CLLocationCoordinate2D?
    @MainActor @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    @MainActor static let shared = LocationService()

    nonisolated override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    @MainActor func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    @MainActor func startUpdating() {
        manager.startUpdatingLocation()
    }

    @MainActor func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate
        Task { @MainActor in
            self.currentLocation = coordinate
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
