import Foundation
#if canImport(CoreLocation)
import CoreLocation
#endif

/// Wraps `CLLocationManager` region monitoring for the up-to-20 geofences
/// iOS allows an app to watch concurrently. Each `LocationReminder` becomes a
/// `CLCircularRegion` keyed by its `UUID` string so entry events map straight
/// back to the model without a lookup table.
///
/// Requires "Always" location authorization and the `location` background
/// mode, since entry events must fire even when Hearth isn't foregrounded.
#if canImport(CoreLocation)
public protocol LocationMonitorServiceDelegate: AnyObject, Sendable {
    /// Fired on the main actor when the device enters a monitored region.
    /// `reminderID` matches `LocationReminder.id` so the caller can look up
    /// the associated tasks and post the high-priority local notification.
    func locationMonitorService(_ service: LocationMonitorService, didEnterRegionWithReminderID reminderID: UUID) async
}

@MainActor
public final class LocationMonitorService: NSObject {
    public weak var delegate: LocationMonitorServiceDelegate?

    private let manager = CLLocationManager()

    public override init() {
        super.init()
        manager.delegate = self
    }

    public func requestAlwaysAuthorizationIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    /// Re-syncs the set of monitored regions with the active `LocationReminder`s.
    /// Call this after any create/edit/delete of a reminder.
    public func syncMonitoredRegions(with reminders: [LocationReminder]) {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }

        for reminder in reminders where reminder.isActive {
            let center = CLLocationCoordinate2D(latitude: reminder.latitude, longitude: reminder.longitude)
            let region = CLCircularRegion(center: center, radius: reminder.radiusMeters, identifier: reminder.id.uuidString)
            region.notifyOnEntry = true
            region.notifyOnExit = false
            manager.startMonitoring(for: region)
        }
    }
}

extension LocationMonitorService: CLLocationManagerDelegate {
    public nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let reminderID = UUID(uuidString: region.identifier) else { return }
        Task { @MainActor in
            await delegate?.locationMonitorService(self, didEnterRegionWithReminderID: reminderID)
        }
    }
}
#endif
