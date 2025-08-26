package com.hybridattendance.hybrid_attendance

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log

/**
 * Handles Bluetooth Low Energy (BLE) scanning for attendance verification.
 */
class BluetoothScanner(private val context: Context) {
    
    companion object {
        private const val TAG = "BluetoothScanner"
    }
    
    private val bluetoothManager: BluetoothManager? by lazy {
        context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    }
    
    private val bluetoothAdapter: BluetoothAdapter? by lazy {
        bluetoothManager?.adapter
    }
    
    private val bluetoothLeScanner: BluetoothLeScanner? by lazy {
        bluetoothAdapter?.bluetoothLeScanner
    }
    
    private val handler = Handler(Looper.getMainLooper())
    private var scanCallback: ScanCallback? = null
    private var isScanning = false
    
    /**
     * Scans for BLE devices with the specified device names.
     * 
     * @param deviceNames List of device names to scan for
     * @param exactMatch Whether to use exact matching or partial matching
     * @param timeoutMs Timeout in milliseconds
     * @param enableLogging Whether to enable detailed logging
     * @param onDeviceFound Callback when a matching device is found
     * @param onScanComplete Callback when scan completes (with or without finding devices)
     */
    fun scanForDevices(
        deviceNames: List<String>,
        exactMatch: Boolean,
        timeoutMs: Long,
        enableLogging: Boolean,
        onDeviceFound: (String) -> Unit,
        onScanComplete: (Boolean) -> Unit
    ) {
        if (enableLogging) {
            Log.d(TAG, "Starting BLE scan for devices: $deviceNames (exactMatch: $exactMatch, timeout: ${timeoutMs}ms)")
        }
        
        // Check if Bluetooth is available and enabled
        if (bluetoothAdapter == null) {
            if (enableLogging) Log.e(TAG, "Bluetooth not available")
            onScanComplete(false)
            return
        }
        
        if (!bluetoothAdapter!!.isEnabled) {
            if (enableLogging) Log.e(TAG, "Bluetooth not enabled")
            onScanComplete(false)
            return
        }
        
        if (bluetoothLeScanner == null) {
            if (enableLogging) Log.e(TAG, "BLE scanner not available")
            onScanComplete(false)
            return
        }
        
        // Stop any existing scan
        stopScan()
        
        // Create scan callback
        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                super.onScanResult(callbackType, result)
                
                val deviceName = result.device?.name
                if (deviceName != null) {
                    if (enableLogging) {
                        Log.d(TAG, "Found BLE device: $deviceName")
                    }
                    
                    val isMatch = if (exactMatch) {
                        deviceNames.contains(deviceName)
                    } else {
                        deviceNames.any { targetName ->
                            deviceName.contains(targetName, ignoreCase = true)
                        }
                    }
                    
                    if (isMatch) {
                        if (enableLogging) {
                            Log.d(TAG, "Device match found: $deviceName")
                        }
                        stopScan()
                        onDeviceFound(deviceName)
                        return
                    }
                }
            }
            
            override fun onScanFailed(errorCode: Int) {
                super.onScanFailed(errorCode)
                if (enableLogging) {
                    Log.e(TAG, "BLE scan failed with error code: $errorCode")
                }
                stopScan()
                onScanComplete(false)
            }
        }
        
        // Configure scan settings for better performance
        val scanSettings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
            .setMatchMode(ScanSettings.MATCH_MODE_AGGRESSIVE)
            .setNumOfMatches(ScanSettings.MATCH_NUM_ONE_ADVERTISEMENT)
            .setReportDelay(0L)
            .build()
        
        try {
            // Start scanning
            bluetoothLeScanner!!.startScan(null, scanSettings, scanCallback)
            isScanning = true
            
            if (enableLogging) {
                Log.d(TAG, "BLE scan started")
            }
            
            // Set timeout
            handler.postDelayed({
                if (isScanning) {
                    if (enableLogging) {
                        Log.d(TAG, "BLE scan timeout reached")
                    }
                    stopScan()
                    onScanComplete(false)
                }
            }, timeoutMs)
            
        } catch (e: SecurityException) {
            if (enableLogging) {
                Log.e(TAG, "Security exception during BLE scan: ${e.message}")
            }
            onScanComplete(false)
        } catch (e: Exception) {
            if (enableLogging) {
                Log.e(TAG, "Exception during BLE scan: ${e.message}")
            }
            onScanComplete(false)
        }
    }
    
    /**
     * Stops the current BLE scan.
     */
    fun stopScan() {
        if (isScanning && scanCallback != null && bluetoothLeScanner != null) {
            try {
                bluetoothLeScanner!!.stopScan(scanCallback)
            } catch (e: SecurityException) {
                Log.e(TAG, "Security exception stopping BLE scan: ${e.message}")
            } catch (e: Exception) {
                Log.e(TAG, "Exception stopping BLE scan: ${e.message}")
            }
        }
        isScanning = false
        scanCallback = null
    }
    
    /**
     * Checks if Bluetooth is available and enabled.
     */
    fun isBluetoothAvailable(): Boolean {
        return bluetoothAdapter != null && bluetoothAdapter!!.isEnabled
    }
}
