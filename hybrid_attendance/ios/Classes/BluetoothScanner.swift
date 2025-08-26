import Foundation
import CoreBluetooth

/// Handles Bluetooth Low Energy (BLE) scanning for attendance verification on iOS.
class BluetoothScanner: NSObject {
    
    private var centralManager: CBCentralManager?
    private var scanTimer: Timer?
    private var isScanning = false
    
    // Scan configuration
    private var targetDeviceNames: [String] = []
    private var exactMatch = true
    private var enableLogging = false
    
    // Callbacks
    private var onDeviceFound: ((String) -> Void)?
    private var onScanComplete: ((Bool) -> Void)?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Scans for BLE devices with the specified device names.
    ///
    /// - Parameters:
    ///   - deviceNames: List of device names to scan for
    ///   - exactMatch: Whether to use exact matching or partial matching
    ///   - timeoutMs: Timeout in milliseconds
    ///   - enableLogging: Whether to enable detailed logging
    ///   - onDeviceFound: Callback when a matching device is found
    ///   - onScanComplete: Callback when scan completes (with or without finding devices)
    func scanForDevices(
        deviceNames: [String],
        exactMatch: Bool,
        timeoutMs: Int,
        enableLogging: Bool,
        onDeviceFound: @escaping (String) -> Void,
        onScanComplete: @escaping (Bool) -> Void
    ) {
        self.targetDeviceNames = deviceNames
        self.exactMatch = exactMatch
        self.enableLogging = enableLogging
        self.onDeviceFound = onDeviceFound
        self.onScanComplete = onScanComplete
        
        if enableLogging {
            print("BluetoothScanner: Starting BLE scan for devices: \(deviceNames) (exactMatch: \(exactMatch), timeout: \(timeoutMs)ms)")
        }
        
        // Check if Bluetooth is available and powered on
        guard let centralManager = centralManager else {
            if enableLogging {
                print("BluetoothScanner: Central manager not available")
            }
            onScanComplete(false)
            return
        }
        
        if centralManager.state != .poweredOn {
            if enableLogging {
                print("BluetoothScanner: Bluetooth not powered on, state: \(centralManager.state.rawValue)")
            }
            onScanComplete(false)
            return
        }
        
        // Stop any existing scan
        stopScan()
        
        // Start scanning
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        
        isScanning = true
        
        if enableLogging {
            print("BluetoothScanner: BLE scan started")
        }
        
        // Set timeout
        scanTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeoutMs) / 1000.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.isScanning {
                if self.enableLogging {
                    print("BluetoothScanner: BLE scan timeout reached")
                }
                self.stopScan()
                self.onScanComplete?(false)
            }
        }
    }
    
    /// Stops the current BLE scan.
    func stopScan() {
        guard let centralManager = centralManager, isScanning else { return }
        
        centralManager.stopScan()
        isScanning = false
        
        scanTimer?.invalidate()
        scanTimer = nil
        
        if enableLogging {
            print("BluetoothScanner: BLE scan stopped")
        }
    }
    
    /// Checks if Bluetooth is available and powered on.
    func isBluetoothAvailable() -> Bool {
        guard let centralManager = centralManager else { return false }
        return centralManager.state == .poweredOn
    }
    
    /// Checks if a device name matches the target criteria.
    private func isDeviceNameMatch(_ deviceName: String) -> Bool {
        if exactMatch {
            return targetDeviceNames.contains(deviceName)
        } else {
            return targetDeviceNames.contains { targetName in
                deviceName.localizedCaseInsensitiveContains(targetName)
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothScanner: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if enableLogging {
            print("BluetoothScanner: Central manager state updated: \(central.state.rawValue)")
        }
        
        // If Bluetooth becomes unavailable during scanning, stop the scan
        if isScanning && central.state != .poweredOn {
            if enableLogging {
                print("BluetoothScanner: Bluetooth became unavailable during scan")
            }
            stopScan()
            onScanComplete?(false)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard let deviceName = peripheral.name, !deviceName.isEmpty else {
            return
        }
        
        if enableLogging {
            print("BluetoothScanner: Found BLE device: \(deviceName)")
        }
        
        if isDeviceNameMatch(deviceName) {
            if enableLogging {
                print("BluetoothScanner: Device match found: \(deviceName)")
            }
            
            stopScan()
            onDeviceFound?(deviceName)
        }
    }
}
