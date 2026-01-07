import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

class LiveFeed extends StatefulWidget {
  const LiveFeed({Key? key}) : super(key: key);
  @override
  _LiveFeedState createState() => _LiveFeedState();
}

class Vector3 {
  double x, y, z;
  Vector3(this.x, this.y, this.z);
  Vector3.zero() : x = 0, y = 0, z = 0;
  void setFrom(Vector3 other) {
    x = other.x;
    y = other.y;
    z = other.z;
  }
}

class _LiveFeedState extends State<LiveFeed> {
  late CameraController _cameraController;
  late Vector3 _accelerometer = Vector3.zero();
  late Vector3 _magnetometer = Vector3.zero();
  late Vector3 _gyroscope = Vector3.zero();
  late Vector3 _userAaccelerometer = Vector3.zero();
  late Vector3 _orientation = Vector3.zero();
  late Vector3 _absoluteOrientation = Vector3.zero();
  late Vector3 _absoluteOrientation2 = Vector3.zero();
  late List<double> _rotation = List.filled(9, 0);
  
  late int _groupValue;

  @override
  void initState() {
    super.initState();
    _groupValue = 0;
    _initializeCamera();
    _initializeSensors();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.high,
        );
        await _cameraController.initialize();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _initializeSensors() {
    // Using sensors_plus which provides accelerometer, gyroscope, magnetometer
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          _accelerometer = Vector3(event.x, event.y, event.z);
        });
      }
    });

    userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      if (mounted) {
        setState(() {
          _userAaccelerometer = Vector3(event.x, event.y, event.z);
        });
      }
    });

    gyroscopeEvents.listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          _gyroscope = Vector3(event.x, event.y, event.z);
        });
      }
    });

    magnetometerEvents.listen((MagnetometerEvent event) {
      if (mounted) {
        setState(() {
          _magnetometer = Vector3(event.x, event.y, event.z);
        });
      }
    });
  }

  void _setUpdateInterval(int interval) {
    // sensors_plus automatically manages update intervals
    // Update interval is set via sensor event streams
  }

  double degrees(double radians) {
    return radians * 180 / pi;
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hidden Camera Detection')),
      body: Column(
        children: [
          Expanded(
            child: _cameraController.value.isInitialized
                ? CameraPreview(_cameraController)
                : const Center(child: CircularProgressIndicator()),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Accelerometer Display
                  Card(
                    child: Column(
                      children: [
                        const Text('Accelerometer'),
                        Text('X: ${_accelerometer.x.toStringAsFixed(4)}'),
                        Text('Y: ${_accelerometer.y.toStringAsFixed(4)}'),
                        Text('Z: ${_accelerometer.z.toStringAsFixed(4)}'),
                      ],
                    ),
                  ),
                  // Magnetometer Display
                  Card(
                    child: Column(
                      children: [
                        const Text('Magnetometer'),
                        Text('X: ${_magnetometer.x.toStringAsFixed(4)}'),
                        Text('Y: ${_magnetometer.y.toStringAsFixed(4)}'),
                        Text('Z: ${_magnetometer.z.toStringAsFixed(4)}'),
                      ],
                    ),
                  ),
                  // Gyroscope Display
                  Card(
                    child: Column(
                      children: [
                        const Text('Gyroscope'),
                        Text('X: ${_gyroscope.x.toStringAsFixed(4)}'),
                        Text('Y: ${_gyroscope.y.toStringAsFixed(4)}'),
                        Text('Z: ${_gyroscope.z.toStringAsFixed(4)}'),
                      ],
                    ),
                  ),
                  // User Accelerometer Display
                  Card(
                    child: Column(
                      children: [
                        const Text('User Accelerometer'),
                        Text('X: ${_userAaccelerometer.x.toStringAsFixed(4)}'),
                        Text('Y: ${_userAaccelerometer.y.toStringAsFixed(4)}'),
                        Text('Z: ${_userAaccelerometer.z.toStringAsFixed(4)}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
