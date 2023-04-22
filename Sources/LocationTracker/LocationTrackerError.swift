//
//  LocationTrackerError.swift
//  
//
//  Created by bemohansingh on 29/12/2021.
//

import Foundation

public enum LocationTrackerError: LocalizedError {
    case authorizationFail(LocationAuthorizationStatus)
    case reducedPrecision
    
    public var errorDescription: String? {
        switch self {
        case .authorizationFail(let status): return "Location tracker needs to have `authorizedAlways` status to be true, got \(status)"
        case .reducedPrecision: return "Region monitoring doesn't work with reduced precision"
        }
    }
}
