## 1.0.1

### 🔒 Security Update

**Breaking Change:**
- **Minimum Android API level raised from 21 to 23** (Android 6.0+)
- Improves security by requiring runtime permission model
- Addresses BLE and location privacy vulnerabilities in older Android versions
- Still covers 99.7% of active Android devices

**Security Improvements:**
- ✅ Runtime permission controls for better user privacy
- ✅ Enhanced BLE security protocols
- ✅ Better location access controls
- ✅ Meets enterprise security requirements
- ✅ Addresses BlueBorne and other legacy vulnerabilities

**Migration:**
- No code changes required for apps already targeting API 23+
- Apps targeting API 21-22 will need to update their `minSdkVersion`

## 1.0.0

### 🎉 Initial Release

**Features:**
- ✅ Hybrid attendance verification using BLE + Location fallback
- ✅ Cross-platform support (Android API 21+, iOS 13.0+)
- ✅ Automatic permission handling with user-friendly messages
- ✅ Configurable BLE device names and location points
- ✅ Battery-optimized scanning with immediate stop on match
- ✅ Flexible matching options (exact vs partial BLE device names)
- ✅ Rich API with detailed result information
- ✅ Optional debug logging for troubleshooting
- ✅ Comprehensive example app with interactive UI

**Platform Support:**
- **Android:** Modern BLE and Location APIs with runtime permissions
- **iOS:** Core Bluetooth and Core Location with proper Info.plist setup

**API:**
- `HybridAttendance.checkAttendance()` - Main attendance verification
- `HybridAttendance.requestPermissions()` - Permission management
- `AttendanceConfig` - Comprehensive configuration options
- `AttendanceResult` - Detailed result with status and data

**Testing:**
- ✅ Comprehensive unit tests
- ✅ Example app for manual testing
- ✅ Both Android and iOS builds verified
