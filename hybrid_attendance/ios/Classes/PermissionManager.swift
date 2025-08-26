import Foundation
import CoreBluetooth
import CoreLocation

/// Manages permissions required for hybrid attendance functionality on iOS.
class PermissionManager: NSObject {
    
    private var locationManager: CLLocationManager?
    
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
    }
    
    /// Checks if all required permissions are granted.
    func hasAllPermissions() -> Bool {
        return hasBluetoothPermissions() && hasLocationPermissions()
    }
    
    /// Checks if Bluetooth permissions are granted.
    func hasBluetoothPermissions() -> Bool {
        if #available(iOS 13.1, *) {
            return CBCentralManager.authorization == .allowedAlways
        } else {
            // For iOS versions before 13.1, Bluetooth permission is not required
            return true
        }
    }
    
    /// Checks if location permissions are granted.
    func hasLocationPermissions() -> Bool {
        guard let locationManager = locationManager else { return false }
        
        let authorizationStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    /// Requests location permissions from the user.
    func requestLocationPermissions() {
        guard let locationManager = locationManager else { return }
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Gets a user-friendly description of missing permissions.
    func getMissingPermissionsDescription() -> String {
        var missingPermissions: [String] = []
        
        if !hasBluetoothPermissions() {
            missingPermissions.append("Bluetooth")
        }
        
        if !hasLocationPermissions() {
            missingPermissions.append("Location")
        }
        
        if missingPermissions.isEmpty {
            return ""
        } else if missingPermissions.count == 1 {
            return "Please enable \(missingPermissions[0]) permission in Settings"
        } else {
            return "Please enable \(missingPermissions.joined(separator: " and ")) permissions in Settings"
        }
    }
    
    /// Gets the current location authorization status.
    func getLocationAuthorizationStatus() -> CLAuthorizationStatus {
        guard let locationManager = locationManager else { return .notDetermined }
        
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    /// Gets the current Bluetooth authorization status.
    @available(iOS 13.0, *)
    func getBluetoothAuthorizationStatus() -> CBManagerAuthorization {
        if #available(iOS 13.1, *) {
            return CBCentralManager.authorization
        } else {
            return .allowedAlways // Assume allowed for older iOS versions
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension PermissionManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Handle location authorization changes if needed
        // This can be used to notify the app about permission changes
    }
    
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Handle location authorization changes for iOS 14+
        // This can be used to notify the app about permission changes
    }
}
