import Foundation
import CoreLocation

/// Captures a one-shot location fix and reverse-geocodes it, so every scan can be tagged
/// with "where" automatically without the user typing anything.
@MainActor
final class LocationTaggingService: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestAuthorizationIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    /// Returns `nil` if permission isn't granted or a fix can't be obtained quickly —
    /// callers should treat location tagging as best-effort, never a hard requirement.
    func currentTag() async -> TaggedLocation? {
        guard manager.authorizationStatus == .authorizedWhenInUse
            || manager.authorizationStatus == .authorizedAlways else {
            return nil
        }

        let location = await withCheckedContinuation { (continuation: CheckedContinuation<CLLocation?, Never>) in
            self.continuation = continuation
            manager.requestLocation()
        }

        guard let location else { return nil }

        let placeName = await reverseGeocodedName(for: location)
        return TaggedLocation(
            name: placeName,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }

    private func reverseGeocodedName(for location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else {
            return nil
        }
        return placemark.name ?? placemark.locality
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            continuation?.resume(returning: locations.first)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(returning: nil)
            continuation = nil
        }
    }
}
