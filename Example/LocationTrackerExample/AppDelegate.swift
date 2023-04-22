//
//  AppDelegate.swift
//  LocationTrackerExample
//
//  Created by bemohansingh on 27/12/2021.
//

import UIKit
import LocationTracker

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
    lazy var tracker: LocationTracker = {
        let configuration = LocationTrackerConfiguration()
        configuration.distanceFilter = 100
        let tracker = LocationTracker(configuration: configuration)
        tracker.delegate = self
        return tracker
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let options: UNAuthorizationOptions = [.badge, .alert]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { _, error in
          if let error = error {
            print("Error: \(error)")
          }
        }
        // Override point for customization after application launch.
        if let locationKey = launchOptions?[.location] {
            AppDelegate.showNotification(content: "location key: \(locationKey)")
        }
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    static func showNotification(content: String) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.body = content
        notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "location_test",
            content: notificationContent,
            trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error: \(error)")
            }
        }
    }
    
    
}

extension AppDelegate: LocationTrackerDelegate {
    func locationTrackerDidTrackLocation(tracker: LocationTracker, location: TrackerCoordinates) {
        if UIApplication.shared.applicationState == .active {
          print("tracker called")
        } else {
            AppDelegate.showNotification(content: "remaining: \(UIApplication.shared.applicationState.rawValue)")
        }
        
    }
}

