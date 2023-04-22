# LocationTracker

Location Monitoring Package to Track user Location in Background or in Killed state

## Required Keys
To use this package, add keys **NSLocationAlwaysAndWhenInUseUsageDescription**, **NSLocationWhenInUseUsageDescription** in the **Info.plist** file. Also, add following key in the same file to work in background mode.
```
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

## Usage
To use this package, first import it using
```
import LocationTracker
```

To start tracking location, call
```swift
locationTracker.startTrackingLocation()
```
To stop tracking, call
```swift
locationTracker.stopTrackingLocation()
```
**Note: ** To restart tracking, you need to first stop and then start tracking.
