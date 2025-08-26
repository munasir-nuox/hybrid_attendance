package com.hybridattendance.hybrid_attendance

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import kotlin.coroutines.suspendCoroutine

/** HybridAttendancePlugin */
class HybridAttendancePlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var activityBinding: ActivityPluginBinding? = null

  // Helper classes
  private lateinit var permissionManager: PermissionManager
  private lateinit var bluetoothScanner: BluetoothScanner
  private lateinit var locationChecker: LocationChecker

  // Coroutine scope for async operations
  private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

  // Pending permission result
  private var pendingPermissionResult: Result? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "hybrid_attendance")
    channel.setMethodCallHandler(this)

    // Initialize helper classes
    permissionManager = PermissionManager(context)
    bluetoothScanner = BluetoothScanner(context)
    locationChecker = LocationChecker(context)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "checkAttendance" -> {
        handleCheckAttendance(call, result)
      }
      "requestPermissions" -> {
        handleRequestPermissions(result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    scope.cancel()
  }

  // ActivityAware implementation
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activityBinding = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activityBinding = binding
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activityBinding?.removeRequestPermissionsResultListener(this)
    activityBinding = null
  }

  /**
   * Handles the checkAttendance method call from Flutter.
   */
  private fun handleCheckAttendance(call: MethodCall, result: Result) {
    scope.launch {
      try {
        val config = parseAttendanceConfig(call.arguments as? Map<String, Any>)
        if (config == null) {
          result.error("INVALID_CONFIG", "Invalid attendance configuration", null)
          return@launch
        }

        // Check permissions first
        if (!permissionManager.hasAllPermissions()) {
          val missingPermissions = permissionManager.getMissingPermissionsDescription()
          result.success(mapOf(
            "status" to "failedPermissions",
            "message" to missingPermissions
          ))
          return@launch
        }

        val attendanceResult = performAttendanceCheck(config)
        result.success(attendanceResult)

      } catch (e: Exception) {
        result.error("ATTENDANCE_ERROR", "Error during attendance check: ${e.message}", null)
      }
    }
  }

  /**
   * Handles the requestPermissions method call from Flutter.
   */
  private fun handleRequestPermissions(result: Result) {
    if (permissionManager.hasAllPermissions()) {
      result.success(mapOf(
        "granted" to true,
        "message" to "All permissions already granted"
      ))
      return
    }

    val activity = activityBinding?.activity
    if (activity == null) {
      result.error("NO_ACTIVITY", "No activity available for permission request", null)
      return
    }

    // Store the result for later use in permission callback
    pendingPermissionResult = result

    // Request permissions
    permissionManager.requestPermissions(activity)
  }

  // PluginRegistry.RequestPermissionsResultListener implementation
  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
    if (requestCode == PermissionManager.PERMISSION_REQUEST_CODE && pendingPermissionResult != null) {
      val allGranted = grantResults.all { it == android.content.pm.PackageManager.PERMISSION_GRANTED }

      if (allGranted) {
        pendingPermissionResult!!.success(mapOf(
          "granted" to true,
          "message" to "All permissions granted"
        ))
      } else {
        val missingPermissions = permissionManager.getMissingPermissionsDescription()
        pendingPermissionResult!!.success(mapOf(
          "granted" to false,
          "message" to missingPermissions
        ))
      }

      pendingPermissionResult = null
      return true
    }
    return false
  }

  /**
   * Data class for attendance configuration.
   */
  private data class AttendanceConfig(
    val bleDeviceNames: List<String>,
    val locations: List<LocationChecker.LocationPoint>,
    val radiusMeters: Int,
    val bleScanTimeoutMs: Long,
    val exactBleMatch: Boolean,
    val enableLogging: Boolean
  )

  /**
   * Performs the hybrid attendance check: BLE scan first, then location fallback.
   */
  private suspend fun performAttendanceCheck(config: AttendanceConfig): Map<String, Any> = withContext(Dispatchers.IO) {
    if (config.enableLogging) {
      android.util.Log.d("HybridAttendance", "Starting attendance check with ${config.bleDeviceNames.size} BLE devices and ${config.locations.size} locations")
    }

    // Step 1: Try BLE scan if device names are configured
    if (config.bleDeviceNames.isNotEmpty()) {
      val bleResult: Map<String, Any>? = performBleCheck(config)
      if (bleResult != null) {
        return@withContext bleResult
      }
    }

    // Step 2: Fallback to location check if locations are configured
    if (config.locations.isNotEmpty()) {
      val locationResult: Map<String, Any>? = performLocationCheck(config)
      if (locationResult != null) {
        return@withContext locationResult
      }
    }

    // Step 3: No matches found
    return@withContext mapOf(
      "status" to "failedNoMatch",
      "message" to "No matching Bluetooth devices found and not within any configured location"
    )
  }

  /**
   * Performs BLE device scanning.
   */
  private suspend fun performBleCheck(config: AttendanceConfig): Map<String, Any>? = suspendCancellableCoroutine { continuation ->
    bluetoothScanner.scanForDevices(
      deviceNames = config.bleDeviceNames,
      exactMatch = config.exactBleMatch,
      timeoutMs = config.bleScanTimeoutMs,
      enableLogging = config.enableLogging,
      onDeviceFound = { deviceName: String ->
        if (continuation.isActive) {
          continuation.resume(mapOf(
            "status" to "successBle",
            "message" to "Attendance verified via Bluetooth device: $deviceName",
            "data" to mapOf("deviceName" to deviceName)
          ), null)
        }
      },
      onScanComplete = { found: Boolean ->
        if (continuation.isActive && !found) {
          continuation.resume(null, null)
        }
      }
    )

    continuation.invokeOnCancellation {
      bluetoothScanner.stopScan()
    }
  }

  /**
   * Performs location-based checking.
   */
  private suspend fun performLocationCheck(config: AttendanceConfig): Map<String, Any>? = suspendCancellableCoroutine { continuation ->
    locationChecker.checkLocationProximity(
      targetLocations = config.locations,
      radiusMeters = config.radiusMeters,
      enableLogging = config.enableLogging
    ) { isWithinRadius: Boolean, closestDistance: Double?, currentLocation: LocationChecker.LocationPoint? ->
      if (continuation.isActive) {
        if (isWithinRadius) {
          val data = mutableMapOf<String, Any>()
          currentLocation?.let { location: LocationChecker.LocationPoint ->
            data["latitude"] = location.latitude
            data["longitude"] = location.longitude
          }
          closestDistance?.let { distance: Double ->
            data["distance"] = distance
          }

          continuation.resume(mapOf(
            "status" to "successLocation",
            "message" to "Attendance verified via location${if (closestDistance != null) " (${closestDistance.toInt()}m away)" else ""}",
            "data" to data
          ), null)
        } else {
          continuation.resume(null, null)
        }
      }
    }

    continuation.invokeOnCancellation {
      // Location checking doesn't need explicit cancellation
    }
  }

  /**
   * Parses attendance configuration from method call arguments.
   */
  private fun parseAttendanceConfig(arguments: Map<String, Any>?): AttendanceConfig? {
    if (arguments == null) return null

    try {
      val bleDeviceNames = (arguments["bleDeviceNames"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList<String>()
      val locationsData = arguments["locations"] as? List<*> ?: emptyList<Any>()
      val locations = locationsData.mapNotNull { locationData: Any? ->
        val locationMap = locationData as? Map<*, *>
        val lat = locationMap?.get("latitude") as? Double
        val lon = locationMap?.get("longitude") as? Double
        if (lat != null && lon != null) {
          LocationChecker.LocationPoint(lat, lon)
        } else null
      }

      val radiusMeters = (arguments["radiusMeters"] as? Number)?.toInt() ?: 100
      val bleScanTimeoutSeconds = (arguments["bleScanTimeoutSeconds"] as? Number)?.toInt() ?: 20
      val exactBleMatch = arguments["exactBleMatch"] as? Boolean ?: true
      val enableLogging = arguments["enableLogging"] as? Boolean ?: false

      return AttendanceConfig(
        bleDeviceNames = bleDeviceNames,
        locations = locations,
        radiusMeters = radiusMeters,
        bleScanTimeoutMs = bleScanTimeoutSeconds * 1000L,
        exactBleMatch = exactBleMatch,
        enableLogging = enableLogging
      )
    } catch (e: Exception) {
      return null
    }
  }
}
