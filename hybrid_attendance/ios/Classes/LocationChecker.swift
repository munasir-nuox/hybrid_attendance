import Foundation
import CoreLocation

/// Represents a geographical location point.
struct LocationPoint {
    let latitude: Double
    let longitude: Double
}

/// Handles location-based attendance verification on iOS.
class LocationChecker: NSObject {
    
    private var locationManager: CLLocationManager?
    private var enableLogging = false
    
    // Location request configuration
    private var targetLocations: [LocationPoint] = []
    private var radiusMeters: Int = 100
    
    // Callbacks
    private var onResult: ((Bool, Double?, LocationPoint?) -> Void)?
    
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = 10 // Update every 10 meters
    }
    
    /// Checks if the current location is within the specified radius of any target locations.
    ///
    /// - Parameters:
    ///   - targetLocations: List of target locations to check against
    ///   - radiusMeters: Radius in meters for location matching
    ///   - enableLogging: Whether to enable detailed logging
    ///   - onResult: Callback with result (isWithinRadius, closestDistance, currentLocation)
    func checkLocationProximity(
        targetLocations: [LocationPoint],
        radiusMeters: Int,
        enableLogging: Bool,
        onResult: @escaping (Bool, Double?, LocationPoint?) -> Void
    ) {
        self.targetLocations = targetLocations
        self.radiusMeters = radiusMeters
        self.enableLogging = enableLogging
        self.onResult = onResult
        
        if enableLogging {
            print("LocationChecker: Starting location check for \(targetLocations.count) target locations with radius \(radiusMeters)m")
        }
        
        guard let locationManager = locationManager else {
            if enableLogging {
                print("LocationChecker: Location manager not available")
            }
            onResult(false, nil, nil)
            return
        }
        
        // Check if location services are enabled
        if !CLLocationManager.locationServicesEnabled() {
            if enableLogging {
                print("LocationChecker: Location services are disabled")
            }
            onResult(false, nil, nil)
            return
        }
        
        // Check authorization status
        let authorizationStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        if authorizationStatus != .authorizedWhenInUse && authorizationStatus != .authorizedAlways {
            if enableLogging {
                print("LocationChecker: Location permission not granted, status: \(authorizationStatus.rawValue)")
            }
            onResult(false, nil, nil)
            return
        }
        
        // Try to get cached location first
        if let cachedLocation = locationManager.location {
            let age = Date().timeIntervalSince(cachedLocation.timestamp)
            if age < 60 { // Use if less than 1 minute old
                if enableLogging {
                    print("LocationChecker: Using cached location (\(Int(age))s old)")
                }
                processLocation(cachedLocation)
                return
            }
        }
        
        // Request fresh location
        if enableLogging {
            print("LocationChecker: Requesting fresh location")
        }
        
        locationManager.requestLocation()
        
        // Set timeout for location request
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self else { return }
            if self.onResult != nil {
                if self.enableLogging {
                    print("LocationChecker: Location request timeout")
                }
                self.onResult?(false, nil, nil)
                self.onResult = nil
            }
        }
    }
    
    /// Processes the received location and checks proximity to target locations.
    private func processLocation(_ location: CLLocation) {
        let currentLocation = LocationPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        if enableLogging {
            print("LocationChecker: Current location: \(currentLocation.latitude), \(currentLocation.longitude)")
        }
        
        var closestDistance = Double.greatestFiniteMagnitude
        var isWithinRadius = false
        
        for targetLocation in targetLocations {
            let targetCLLocation = CLLocation(latitude: targetLocation.latitude, longitude: targetLocation.longitude)
            let distance = location.distance(from: targetCLLocation)
            
            if enableLogging {
                print("LocationChecker: Distance to target (\(targetLocation.latitude), \(targetLocation.longitude)): \(Int(distance))m")
            }
            
            if distance < closestDistance {
                closestDistance = distance
            }
            
            if distance <= Double(radiusMeters) {
                isWithinRadius = true
                if enableLogging {
                    print("LocationChecker: Location match found within \(Int(distance))m")
                }
                break
            }
        }
        
        onResult?(isWithinRadius, closestDistance, currentLocation)
        onResult = nil
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationChecker: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, onResult != nil else { return }
        
        if enableLogging {
            print("LocationChecker: Received location update: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
        
        processLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if enableLogging {
            print("LocationChecker: Failed to get location: \(error.localizedDescription)")
        }
        
        if onResult != nil {
            onResult?(false, nil, nil)
            onResult = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if enableLogging {
            print("LocationChecker: Location authorization changed: \(status.rawValue)")
        }
        
        // If permission is denied during location request, fail immediately
        if onResult != nil && status != .authorizedWhenInUse && status != .authorizedAlways {
            onResult?(false, nil, nil)
            onResult = nil
        }
    }
    
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationManager(manager, didChangeAuthorization: manager.authorizationStatus)
    }
}
