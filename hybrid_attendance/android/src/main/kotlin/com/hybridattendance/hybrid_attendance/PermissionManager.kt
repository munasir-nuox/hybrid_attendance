package com.hybridattendance.hybrid_attendance

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

/**
 * Manages permissions required for hybrid attendance functionality.
 */
class PermissionManager(private val context: Context) {
    
    companion object {
        const val PERMISSION_REQUEST_CODE = 1001
        
        // Bluetooth permissions
        private val BLUETOOTH_PERMISSIONS_LEGACY = arrayOf(
            Manifest.permission.BLUETOOTH,
            Manifest.permission.BLUETOOTH_ADMIN,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
        
        private val BLUETOOTH_PERMISSIONS_API31 = arrayOf(
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
        
        // Location permissions
        private val LOCATION_PERMISSIONS = arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )
    }
    
    /**
     * Gets the required permissions based on Android version.
     */
    fun getRequiredPermissions(): Array<String> {
        val permissions = mutableSetOf<String>()
        
        // Add Bluetooth permissions based on API level
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions.addAll(BLUETOOTH_PERMISSIONS_API31)
        } else {
            permissions.addAll(BLUETOOTH_PERMISSIONS_LEGACY)
        }
        
        // Add location permissions
        permissions.addAll(LOCATION_PERMISSIONS)
        
        return permissions.toTypedArray()
    }
    
    /**
     * Checks if all required permissions are granted.
     */
    fun hasAllPermissions(): Boolean {
        return getRequiredPermissions().all { permission ->
            ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
        }
    }
    
    /**
     * Checks if Bluetooth permissions are granted.
     */
    fun hasBluetoothPermissions(): Boolean {
        val bluetoothPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            BLUETOOTH_PERMISSIONS_API31
        } else {
            BLUETOOTH_PERMISSIONS_LEGACY
        }
        
        return bluetoothPermissions.all { permission ->
            ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
        }
    }
    
    /**
     * Checks if location permissions are granted.
     */
    fun hasLocationPermissions(): Boolean {
        return LOCATION_PERMISSIONS.all { permission ->
            ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
        }
    }
    
    /**
     * Gets the list of missing permissions.
     */
    fun getMissingPermissions(): List<String> {
        return getRequiredPermissions().filter { permission ->
            ContextCompat.checkSelfPermission(context, permission) != PackageManager.PERMISSION_GRANTED
        }
    }
    
    /**
     * Requests permissions from the user.
     * Note: This requires an Activity context.
     */
    fun requestPermissions(activity: Activity) {
        val missingPermissions = getMissingPermissions()
        if (missingPermissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                activity,
                missingPermissions.toTypedArray(),
                PERMISSION_REQUEST_CODE
            )
        }
    }
    
    /**
     * Gets a user-friendly description of missing permissions.
     */
    fun getMissingPermissionsDescription(): String {
        val missing = getMissingPermissions()
        if (missing.isEmpty()) return ""
        
        val descriptions = mutableListOf<String>()
        
        val hasBluetoothMissing = missing.any { 
            it.contains("BLUETOOTH") || it == Manifest.permission.ACCESS_FINE_LOCATION 
        }
        val hasLocationMissing = missing.any { 
            it.contains("LOCATION") 
        }
        
        if (hasBluetoothMissing) {
            descriptions.add("Bluetooth scanning")
        }
        if (hasLocationMissing) {
            descriptions.add("Location access")
        }
        
        return when (descriptions.size) {
            0 -> ""
            1 -> "Please enable ${descriptions[0]} permission in Settings"
            else -> "Please enable ${descriptions.joinToString(" and ")} permissions in Settings"
        }
    }
}
