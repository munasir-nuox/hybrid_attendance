import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:hybrid_attendance/hybrid_attendance.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hybrid Attendance Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AttendanceHomePage(),
    );
  }
}

class AttendanceHomePage extends StatefulWidget {
  const AttendanceHomePage({super.key});

  @override
  State<AttendanceHomePage> createState() => _AttendanceHomePageState();
}

class _AttendanceHomePageState extends State<AttendanceHomePage> {
  String _platformVersion = 'Unknown';

  // Configuration
  final List<String> _bleDeviceNames = ['Office-Beacon-1', 'Office-Beacon-2'];
  final List<LocationPoint> _locations = [
    const LocationPoint(37.7749, -122.4194), // San Francisco
    const LocationPoint(40.7128, -74.0060), // New York
  ];
  int _radiusMeters = 100;
  Duration _bleScanTimeout = const Duration(seconds: 20);
  bool _exactBleMatch = true;
  bool _enableLogging = true;

  // State
  bool _isChecking = false;
  AttendanceResult? _lastResult;

  // Controllers for adding new items
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  Future<void> _initPlatformState() async {
    String platformVersion;
    try {
      platformVersion =
          await HybridAttendance.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _checkAttendance() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _lastResult = null;
    });

    try {
      // First, request permissions
      final permissionResult = await HybridAttendance.requestPermissions();

      if (permissionResult['granted'] != true) {
        setState(() {
          _lastResult = AttendanceResult.failedPermissions(
            message:
                permissionResult['message'] as String? ??
                'Permissions not granted',
          );
        });
        return;
      }

      final config = AttendanceConfig(
        bleDeviceNames: _bleDeviceNames,
        locations: _locations,
        radiusMeters: _radiusMeters,
        bleScanTimeout: _bleScanTimeout,
        exactBleMatch: _exactBleMatch,
        enableLogging: _enableLogging,
      );

      final result = await HybridAttendance.checkAttendance(config: config);

      setState(() {
        _lastResult = result;
      });
    } catch (e) {
      setState(() {
        _lastResult = AttendanceResult.failedNoMatch(message: 'Error: $e');
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hybrid Attendance Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Running on: $_platformVersion'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Configuration Section
            _buildConfigurationSection(),
            const SizedBox(height: 16),

            // Check Attendance Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _checkAttendance,
                child: _isChecking
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Checking Attendance...'),
                        ],
                      )
                    : const Text('Check Attendance'),
              ),
            ),
            const SizedBox(height: 16),

            // Result Section
            if (_lastResult != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // BLE Device Names
            Text(
              'BLE Device Names',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._bleDeviceNames.map(
              (name) => Chip(
                label: Text(name),
                onDeleted: () {
                  setState(() {
                    _bleDeviceNames.remove(name);
                  });
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _deviceNameController,
                    decoration: const InputDecoration(
                      hintText: 'Add BLE device name',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_deviceNameController.text.isNotEmpty) {
                      setState(() {
                        _bleDeviceNames.add(_deviceNameController.text);
                        _deviceNameController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Locations
            Text('Locations', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._locations.map(
              (location) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text('${location.latitude}, ${location.longitude}'),
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        _locations.remove(location);
                      });
                    },
                    icon: const Icon(Icons.delete),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      hintText: 'Latitude',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      hintText: 'Longitude',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final lat = double.tryParse(_latitudeController.text);
                    final lon = double.tryParse(_longitudeController.text);
                    if (lat != null && lon != null) {
                      setState(() {
                        _locations.add(LocationPoint(lat, lon));
                        _latitudeController.clear();
                        _longitudeController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Settings
            Text('Settings', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Radius (meters): '),
                Expanded(
                  child: Slider(
                    value: _radiusMeters.toDouble(),
                    min: 10,
                    max: 1000,
                    divisions: 99,
                    label: '$_radiusMeters m',
                    onChanged: (value) {
                      setState(() {
                        _radiusMeters = value.round();
                      });
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('BLE Scan Timeout: '),
                Expanded(
                  child: Slider(
                    value: _bleScanTimeout.inSeconds.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '${_bleScanTimeout.inSeconds}s',
                    onChanged: (value) {
                      setState(() {
                        _bleScanTimeout = Duration(seconds: value.round());
                      });
                    },
                  ),
                ),
              ],
            ),
            SwitchListTile(
              title: const Text('Exact BLE Match'),
              value: _exactBleMatch,
              onChanged: (value) {
                setState(() {
                  _exactBleMatch = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable Logging'),
              value: _enableLogging,
              onChanged: (value) {
                setState(() {
                  _enableLogging = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final result = _lastResult!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isSuccess ? Icons.check_circle : Icons.error,
                  color: result.isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Attendance Result',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status
            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: result.isSuccess
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: result.isSuccess ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    result.status.name.toUpperCase(),
                    style: TextStyle(
                      color: result.isSuccess ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Message
            if (result.message != null) ...[
              const Text(
                'Message: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(result.message!),
              const SizedBox(height: 8),
            ],

            // Data
            if (result.data != null && result.data!.isNotEmpty) ...[
              const Text(
                'Details: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...result.data!.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text('${entry.key}: ${entry.value}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
}
