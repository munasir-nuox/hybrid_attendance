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
