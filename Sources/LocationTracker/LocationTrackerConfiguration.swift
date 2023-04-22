//
//  LocationTrackerConfiguration.swift
//  
//
//  Created by bemohansingh on 27/12/2021.
//

import Foundation

final public class LocationTrackerConfiguration {
    
    /**
     *      Minimimum distance at which tracking will occur.
     *      Distance greater than 200m is preferred to correctly monitor in background state.
     */
    public var distanceFilter: Double = 250
    
    public init() {
        
    }
}
