//
//  LocationTrackerDelegate.swift
//  
//
//  Created by bemohansingh on 29/12/2021.
//

import Foundation

public protocol LocationTrackerDelegate: AnyObject {
    func locationTrackerAuthorizationDidChange(status: LocationAuthorizationStatus)
    func locationTrackerDidFailToInitialize(tracker: LocationTracker, error: LocationTrackerError)
    func locationTrackerDidTrackLocation(tracker: LocationTracker, location: TrackerCoordinates)
    func locationTrackerDidFailToTrack(tracker: LocationTracker, error: Error)
}

public extension LocationTrackerDelegate {
    func locationTrackerAuthorizationDidChange(status: LocationAuthorizationStatus) {}
    
    func locationTrackerDidFailToInitialize(tracker: LocationTracker, error: LocationTrackerError) {}
    
    func locationTrackerDidFailToTrack(tracker: LocationTracker, error: Error) {}
}
