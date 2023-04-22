import Foundation
import UIKit
import CoreLocation

public typealias LocationAuthorizationStatus = CLAuthorizationStatus
public typealias TrackerCoordinates = CLLocationCoordinate2D

/**
 *   Class to track location using minimim power
 */
final public class LocationTracker: NSObject {
    
    public let configuration: LocationTrackerConfiguration
    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.distanceFilter = configuration.distanceFilter
        locationManager.activityType = .automotiveNavigation
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        return locationManager
    }()
    
    public var authorizationStatus: LocationAuthorizationStatus {
        if #available(iOS 14, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    public var isAuthorized: Bool { authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse }
    
    private var currentLocation: CLLocation?
    public var currentCoordinates: TrackerCoordinates? { currentLocation?.coordinate }
    
    weak public var delegate: LocationTrackerDelegate?
    private var currentRegion: CLCircularRegion?
    private let trackerIdentifier = "ebloctracker"
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    public init(configuration: LocationTrackerConfiguration) {
        self.configuration = configuration
        super.init()
    }
    
    deinit {
        stopTrackingLocation()
    }
    
    /// Start tracking user location
    public func startTrackingLocation() {
        guard currentRegion == nil else {
            // Already tracking location
            return
        }
        
        if checkAndAskAuthorization() {
            locationManager.startUpdatingLocation()
        }
    }
    
    private func checkAndAskAuthorization() -> Bool {
        var isAuthorized = false
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            delegate?.locationTrackerDidFailToInitialize(tracker: self, error: .authorizationFail(authorizationStatus))
        case .authorizedWhenInUse, .authorizedAlways: isAuthorized = true
        @unknown default: break
        }
        return isAuthorized
    }
    
    // Stop tracking user location
    public func stopTrackingLocation() {
        locationManager.stopUpdatingLocation()
        if let region = currentRegion {
            currentRegion = nil
            for monitoredRegion in locationManager.monitoredRegions where
                monitoredRegion.identifier == region.identifier {
                locationManager.stopMonitoring(for: monitoredRegion)
            }
        }
    }
    
    private func restartUpdatingLocation() {
        // Stop tracking current region
        stopTrackingLocation()
        
        // Restart updating location to monitor new region
        locationManager.startUpdatingLocation()
    }
    
    private func locationTrackingFailedToInitialize(error: LocationTrackerError) {
        stopTrackingLocation()
        delegate?.locationTrackerDidFailToInitialize(tracker: self, error: error)
    }
    
    private func locationTrackingFailedToTrack(error: Error) {
        stopTrackingLocation()
        delegate?.locationTrackerDidFailToTrack(tracker: self, error: error)
    }
}

extension LocationTracker: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        delegate?.locationTrackerAuthorizationDidChange(status: authorizationStatus)
        // Region monitoring only works with `authorizedAlways`
        guard isAuthorized else {
            return locationTrackingFailedToInitialize(error: .authorizationFail(authorizationStatus))
        }
        
        // Region monitoring needs to have full precision to work
        if #available(iOS 14, *), manager.accuracyAuthorization == .reducedAccuracy {
            return locationTrackingFailedToInitialize(error: .reducedPrecision)
        }
        
        startTrackingLocation()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard currentRegion == nil, let lastLocation = locations.last else { return }
        self.currentLocation = lastLocation
        
        startMonitoring(location: lastLocation)
    }
    
    private func finishBackgroundTask(latestLocation: CLLocation?) {
        guard backgroundTask != .invalid else { return }
        
        // Send latest update location if it is not same with last sent location before killing app
        if let latestLocation = latestLocation,
           let currentLocation = self.currentLocation,
           currentLocation.distance(from: latestLocation) > configuration.distanceFilter {
            delegate?.locationTrackerDidTrackLocation(tracker: self, location: latestLocation.coordinate)
        }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        self.backgroundTask = .invalid
    }
    
    private func startMonitoring(location: CLLocation) {
        // Stop updating location to prevent multiple triggering
        locationManager.stopUpdatingLocation()
        
        // Send current updates to the delegates
        delegate?.locationTrackerDidTrackLocation(tracker: self, location: location.coordinate)
        
        // Clamp radius to not exceed max monitoring distance as monitoring would fail otherwise
        let allowedTrackingRadius = min(configuration.distanceFilter, locationManager.maximumRegionMonitoringDistance)
        
        let regionIdentifier = getRegionIdentifier(for: location.coordinate)
        // Create new region with our location as center which we need to monitor
        let region = CLCircularRegion(center: location.coordinate, radius: allowedTrackingRadius, identifier: regionIdentifier)
        
        // Only allow monitoring for exit as we are already on the region
        region.notifyOnEntry = false
        region.notifyOnExit = true
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            locationManager.startMonitoring(for: region)
            self.currentRegion = region
        } else {
            // TODO: - Use significant location change tracking
        }
    }
    
    private func getRegionIdentifier(for coordinate: TrackerCoordinates) -> String {
        return trackerIdentifier + "\(coordinate)"
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let currentRegion = currentRegion, region == currentRegion else { return }
        
        if UIApplication.shared.applicationState == .active {
            restartUpdatingLocation()
        } else if backgroundTask == .invalid {
            
            self.backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: { [weak self] in
                self?.finishBackgroundTask(latestLocation: manager.location)
            })
            
            restartUpdatingLocation()
            finishBackgroundTask(latestLocation: manager.location)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        if region == currentRegion {
            locationTrackingFailedToTrack(error: error)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // If the error is location unknown, system tries again and we should ignore this error
        guard let locationError = error as NSError?,
           locationError.code != CLError.Code.locationUnknown.rawValue else {
            return
        }
        locationTrackingFailedToTrack(error: error)
    }
}
