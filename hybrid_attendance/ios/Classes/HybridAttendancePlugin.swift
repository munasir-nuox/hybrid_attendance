import Flutter
import UIKit
import CoreBluetooth
import CoreLocation

public class HybridAttendancePlugin: NSObject, FlutterPlugin {

    // Helper classes
    private let permissionManager = PermissionManager()
    private let bluetoothScanner = BluetoothScanner()
    private let locationChecker = LocationChecker()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "hybrid_attendance", binaryMessenger: registrar.messenger())
        let instance = HybridAttendancePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "checkAttendance":
            handleCheckAttendance(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Handles the checkAttendance method call from Flutter.
    private func handleCheckAttendance(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let config = parseAttendanceConfig(arguments: call.arguments) else {
            result(FlutterError(code: "INVALID_CONFIG", message: "Invalid attendance configuration", details: nil))
            return
        }

        // Check permissions first
        if !permissionManager.hasAllPermissions() {
            let missingPermissions = permissionManager.getMissingPermissionsDescription()
            result([
                "status": "failedPermissions",
                "message": missingPermissions
            ])
            return
        }

        // Perform attendance check
        performAttendanceCheck(config: config) { attendanceResult in
            result(attendanceResult)
        }
    }
}

// MARK: - Helper Methods and Data Structures
extension HybridAttendancePlugin {

    /// Data structure for attendance configuration.
    struct AttendanceConfig {
        let bleDeviceNames: [String]
        let locations: [LocationPoint]
        let radiusMeters: Int
        let bleScanTimeoutMs: Int
        let exactBleMatch: Bool
        let enableLogging: Bool
    }

    /// Parses attendance configuration from method call arguments.
    private func parseAttendanceConfig(arguments: Any?) -> AttendanceConfig? {
        guard let args = arguments as? [String: Any] else { return nil }

        let bleDeviceNames = args["bleDeviceNames"] as? [String] ?? []
        let locationsData = args["locations"] as? [[String: Any]] ?? []
        let locations = locationsData.compactMap { locationData -> LocationPoint? in
            guard let lat = locationData["latitude"] as? Double,
                  let lon = locationData["longitude"] as? Double else {
                return nil
            }
            return LocationPoint(latitude: lat, longitude: lon)
        }

        let radiusMeters = args["radiusMeters"] as? Int ?? 100
        let bleScanTimeoutSeconds = args["bleScanTimeoutSeconds"] as? Int ?? 20
        let exactBleMatch = args["exactBleMatch"] as? Bool ?? true
        let enableLogging = args["enableLogging"] as? Bool ?? false

        return AttendanceConfig(
            bleDeviceNames: bleDeviceNames,
            locations: locations,
            radiusMeters: radiusMeters,
            bleScanTimeoutMs: bleScanTimeoutSeconds * 1000,
            exactBleMatch: exactBleMatch,
            enableLogging: enableLogging
        )
    }

    /// Performs the hybrid attendance check: BLE scan first, then location fallback.
    private func performAttendanceCheck(config: AttendanceConfig, completion: @escaping ([String: Any]) -> Void) {
        if config.enableLogging {
            print("HybridAttendance: Starting attendance check with \(config.bleDeviceNames.count) BLE devices and \(config.locations.count) locations")
        }

        // Step 1: Try BLE scan if device names are configured
        if !config.bleDeviceNames.isEmpty {
            performBleCheck(config: config) { bleResult in
                if let result = bleResult {
                    completion(result)
                } else {
                    // Step 2: Fallback to location check if locations are configured
                    if !config.locations.isEmpty {
                        self.performLocationCheck(config: config) { locationResult in
                            if let result = locationResult {
                                completion(result)
                            } else {
                                // Step 3: No matches found
                                completion([
                                    "status": "failedNoMatch",
                                    "message": "No matching Bluetooth devices found and not within any configured location"
                                ])
                            }
                        }
                    } else {
                        // No locations configured, return failure
                        completion([
                            "status": "failedNoMatch",
                            "message": "No matching Bluetooth devices found and no locations configured"
                        ])
                    }
                }
            }
        } else if !config.locations.isEmpty {
            // No BLE devices configured, go directly to location check
            performLocationCheck(config: config) { locationResult in
                if let result = locationResult {
                    completion(result)
                } else {
                    completion([
                        "status": "failedNoMatch",
                        "message": "Not within any configured location"
                    ])
                }
            }
        } else {
            // Neither BLE devices nor locations configured
            completion([
                "status": "failedNoMatch",
                "message": "No BLE devices or locations configured"
            ])
        }
    }

    /// Performs BLE device scanning.
    private func performBleCheck(config: AttendanceConfig, completion: @escaping ([String: Any]?) -> Void) {
        bluetoothScanner.scanForDevices(
            deviceNames: config.bleDeviceNames,
            exactMatch: config.exactBleMatch,
            timeoutMs: config.bleScanTimeoutMs,
            enableLogging: config.enableLogging,
            onDeviceFound: { deviceName in
                completion([
                    "status": "successBle",
                    "message": "Attendance verified via Bluetooth device: \(deviceName)",
                    "data": ["deviceName": deviceName]
                ])
            },
            onScanComplete: { found in
                if !found {
                    completion(nil)
                }
            }
        )
    }

    /// Performs location-based checking.
    private func performLocationCheck(config: AttendanceConfig, completion: @escaping ([String: Any]?) -> Void) {
        locationChecker.checkLocationProximity(
            targetLocations: config.locations,
            radiusMeters: config.radiusMeters,
            enableLogging: config.enableLogging
        ) { isWithinRadius, closestDistance, currentLocation in
            if isWithinRadius {
                var data: [String: Any] = [:]
                if let location = currentLocation {
                    data["latitude"] = location.latitude
                    data["longitude"] = location.longitude
                }
                if let distance = closestDistance {
                    data["distance"] = distance
                }

                let distanceText = closestDistance != nil ? " (\(Int(closestDistance!))m away)" : ""
                completion([
                    "status": "successLocation",
                    "message": "Attendance verified via location\(distanceText)",
                    "data": data
                ])
            } else {
                completion(nil)
            }
        }
    }
}
