package com.hybridattendance.hybrid_attendance

import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.os.Looper
import android.util.Log
import com.google.android.gms.location.*
import com.google.android.gms.tasks.Task
import kotlin.math.*

/**
 * Handles location-based attendance verification.
 */
class LocationChecker(private val context: Context) {
    
    companion object {
        private const val TAG = "LocationChecker"
        private const val LOCATION_TIMEOUT_MS = 10000L // 10 seconds
    }
    
    private val fusedLocationClient: FusedLocationProviderClient by lazy {
        LocationServices.getFusedLocationProviderClient(context)
    }
    
    /**
     * Data class representing a location point.
     */
    data class LocationPoint(val latitude: Double, val longitude: Double)
    
    /**
     * Checks if the current location is within the specified radius of any target locations.
     * 
     * @param targetLocations List of target locations to check against
     * @param radiusMeters Radius in meters for location matching
     * @param enableLogging Whether to enable detailed logging
     * @param onResult Callback with result (isWithinRadius, closestDistance, currentLocation)
     */
    fun checkLocationProximity(
        targetLocations: List<LocationPoint>,
        radiusMeters: Int,
        enableLogging: Boolean,
        onResult: (Boolean, Double?, LocationPoint?) -> Unit
    ) {
        if (enableLogging) {
            Log.d(TAG, "Starting location check for ${targetLocations.size} target locations with radius ${radiusMeters}m")
        }
        
        // Check if location services are available
        if (!isLocationEnabled()) {
            if (enableLogging) {
                Log.e(TAG, "Location services are disabled")
            }
            onResult(false, null, null)
            return
        }
        
        getCurrentLocation(enableLogging) { currentLocation ->
            if (currentLocation == null) {
                if (enableLogging) {
                    Log.e(TAG, "Failed to get current location")
                }
                onResult(false, null, null)
                return@getCurrentLocation
            }
            
            if (enableLogging) {
                Log.d(TAG, "Current location: ${currentLocation.latitude}, ${currentLocation.longitude}")
            }
            
            var closestDistance = Double.MAX_VALUE
            var isWithinRadius = false
            
            for (targetLocation in targetLocations) {
                val distance = calculateDistance(
                    currentLocation.latitude, currentLocation.longitude,
                    targetLocation.latitude, targetLocation.longitude
                )
                
                if (enableLogging) {
                    Log.d(TAG, "Distance to target (${targetLocation.latitude}, ${targetLocation.longitude}): ${distance.toInt()}m")
                }
                
                if (distance < closestDistance) {
                    closestDistance = distance
                }
                
                if (distance <= radiusMeters) {
                    isWithinRadius = true
                    if (enableLogging) {
                        Log.d(TAG, "Location match found within ${distance.toInt()}m")
                    }
                    break
                }
            }
            
            onResult(isWithinRadius, closestDistance, currentLocation)
        }
    }
    
    /**
     * Gets the current location using FusedLocationProviderClient.
     */
    private fun getCurrentLocation(
        enableLogging: Boolean,
        onResult: (LocationPoint?) -> Unit
    ) {
        try {
            val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 1000)
                .setWaitForAccurateLocation(false)
                .setMinUpdateIntervalMillis(500)
                .setMaxUpdateDelayMillis(LOCATION_TIMEOUT_MS)
                .build()
            
            val locationCallback = object : LocationCallback() {
                override fun onLocationResult(locationResult: LocationResult) {
                    super.onLocationResult(locationResult)
                    val location = locationResult.lastLocation
                    if (location != null) {
                        if (enableLogging) {
                            Log.d(TAG, "Received location update: ${location.latitude}, ${location.longitude}")
                        }
                        fusedLocationClient.removeLocationUpdates(this)
                        onResult(LocationPoint(location.latitude, location.longitude))
                    }
                }
                
                override fun onLocationAvailability(locationAvailability: LocationAvailability) {
                    super.onLocationAvailability(locationAvailability)
                    if (!locationAvailability.isLocationAvailable) {
                        if (enableLogging) {
                            Log.w(TAG, "Location not available")
                        }
                    }
                }
            }
            
            // Try to get last known location first
            fusedLocationClient.lastLocation.addOnSuccessListener { location ->
                if (location != null) {
                    val age = System.currentTimeMillis() - location.time
                    if (age < 60000) { // Use if less than 1 minute old
                        if (enableLogging) {
                            Log.d(TAG, "Using cached location (${age}ms old)")
                        }
                        onResult(LocationPoint(location.latitude, location.longitude))
                        return@addOnSuccessListener
                    }
                }
                
                // Request fresh location
                if (enableLogging) {
                    Log.d(TAG, "Requesting fresh location")
                }
                fusedLocationClient.requestLocationUpdates(
                    locationRequest,
                    locationCallback,
                    Looper.getMainLooper()
                )
                
                // Set timeout for location request
                android.os.Handler(Looper.getMainLooper()).postDelayed({
                    fusedLocationClient.removeLocationUpdates(locationCallback)
                    if (enableLogging) {
                        Log.w(TAG, "Location request timeout")
                    }
                    onResult(null)
                }, LOCATION_TIMEOUT_MS)
            }.addOnFailureListener { exception ->
                if (enableLogging) {
                    Log.e(TAG, "Failed to get location: ${exception.message}")
                }
                onResult(null)
            }
            
        } catch (e: SecurityException) {
            if (enableLogging) {
                Log.e(TAG, "Security exception getting location: ${e.message}")
            }
            onResult(null)
        } catch (e: Exception) {
            if (enableLogging) {
                Log.e(TAG, "Exception getting location: ${e.message}")
            }
            onResult(null)
        }
    }
    
    /**
     * Calculates the distance between two geographical points using the Haversine formula.
     * 
     * @return Distance in meters
     */
    private fun calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val earthRadius = 6371000.0 // Earth's radius in meters
        
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        
        val a = sin(dLat / 2).pow(2) + cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) * sin(dLon / 2).pow(2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    /**
     * Checks if location services are enabled.
     */
    private fun isLocationEnabled(): Boolean {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
               locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }
}
