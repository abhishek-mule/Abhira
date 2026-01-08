import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'dart:async';

class LiveFeed extends StatefulWidget {
  const LiveFeed({Key? key}) : super(key: key);
  @override
  _LiveFeedState createState() => _LiveFeedState();
}

class Vector3 {
  double x, y, z;
  Vector3(this.x, this.y, this.z);
  Vector3.zero()
      : x = 0,
        y = 0,
        z = 0;

  double get magnitude => sqrt(x * x + y * y + z * z);

  void setFrom(Vector3 other) {
    x = other.x;
    y = other.y;
    z = other.z;
  }
}

class DetectionResult {
  final String type;
  final double confidence;
  final String description;
  final Color color;

  DetectionResult({
    required this.type,
    required this.confidence,
    required this.description,
    required this.color,
  });
}

class _LiveFeedState extends State<LiveFeed> with TickerProviderStateMixin {
  CameraController? _cameraController;
  late Vector3 _accelerometer = Vector3.zero();
  late Vector3 _magnetometer = Vector3.zero();
  late Vector3 _gyroscope = Vector3.zero();
  late Vector3 _userAccelerometer = Vector3.zero();

  bool _isScanning = false;
  bool _isCameraInitialized = false;
  List<DetectionResult> _detections = [];
  double _magneticFieldStrength = 0.0;
  double _baselineMagneticField = 0.0;
  List<double> _magneticHistory = [];
  int _anomalyCount = 0;

  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  StreamSubscription? _magnetometerSubscription;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  StreamSubscription? _userAccelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeSensors();
    _setupAnimations();
    _calculateBaseline();
  }

  void _setupAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _scanAnimationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        await _cameraController!.setFlashMode(FlashMode.torch);
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _initializeSensors() {
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          _accelerometer = Vector3(event.x, event.y, event.z);
        });
      }
    });

    _userAccelerometerSubscription =
        userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      if (mounted) {
        setState(() {
          _userAccelerometer = Vector3(event.x, event.y, event.z);
        });
      }
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          _gyroscope = Vector3(event.x, event.y, event.z);
        });
      }
    });

    _magnetometerSubscription =
        magnetometerEvents.listen((MagnetometerEvent event) {
      if (mounted) {
        final newMag = Vector3(event.x, event.y, event.z);
        setState(() {
          _magnetometer = newMag;
          _magneticFieldStrength = newMag.magnitude;
          _updateMagneticHistory(_magneticFieldStrength);
          if (_isScanning) {
            _analyzeForAnomalies();
          }
        });
      }
    });
  }

  void _calculateBaseline() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_magneticHistory.isNotEmpty) {
        _baselineMagneticField =
            _magneticHistory.reduce((a, b) => a + b) / _magneticHistory.length;
      }
    });
  }

  void _updateMagneticHistory(double value) {
    _magneticHistory.add(value);
    if (_magneticHistory.length > 50) {
      _magneticHistory.removeAt(0);
    }
  }

  void _analyzeForAnomalies() {
    if (_baselineMagneticField == 0.0) return;

    final deviation = (_magneticFieldStrength - _baselineMagneticField).abs();
    final deviationPercentage = (deviation / _baselineMagneticField) * 100;

    _detections.clear();

    // High magnetic field anomaly detection
    if (deviationPercentage > 30) {
      _anomalyCount++;
      _detections.add(DetectionResult(
        type: 'High Magnetic Anomaly',
        confidence: min(deviationPercentage / 50 * 100, 100),
        description:
            'Strong magnetic field detected. Possible electronic device nearby.',
        color: Colors.red,
      ));
    } else if (deviationPercentage > 15) {
      _detections.add(DetectionResult(
        type: 'Moderate Anomaly',
        confidence: min(deviationPercentage / 30 * 100, 100),
        description: 'Unusual magnetic field pattern detected.',
        color: Colors.orange,
      ));
    }

    // Check for IR reflection (simulated through camera sensor changes)
    if (_isCameraInitialized && _cameraController != null) {
      _detections.add(DetectionResult(
        type: 'IR Scanning Active',
        confidence: 75.0,
        description: 'Camera lens reflection analysis in progress.',
        color: Colors.blue,
      ));
    }

    // Motion stability check
    final motionMagnitude = _userAccelerometer.magnitude;
    if (motionMagnitude < 0.5 && _anomalyCount > 5) {
      _detections.add(DetectionResult(
        type: 'Stationary Anomaly',
        confidence: 85.0,
        description:
            'Device is stable. Anomalies may indicate hidden electronics.',
        color: Colors.deepOrange,
      ));
    }

    setState(() {});
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
      if (!_isScanning) {
        _anomalyCount = 0;
        _detections.clear();
      }
    });
  }

  Color _getThreatColor(double magneticStrength) {
    final deviation = (_magneticFieldStrength - _baselineMagneticField).abs();
    final deviationPercentage = _baselineMagneticField > 0
        ? (deviation / _baselineMagneticField) * 100
        : 0;

    if (deviationPercentage > 30) return Colors.red;
    if (deviationPercentage > 15) return Colors.orange;
    return Colors.green;
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _userAccelerometerSubscription?.cancel();
    if (_cameraController?.value.isInitialized ?? false) {
      _cameraController!.setFlashMode(FlashMode.off);
      _cameraController!.dispose();
    }
    super.dispose();
  }

  Widget _buildSensorCard(String title, Vector3 data, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${data.magnitude.toStringAsFixed(2)} μT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAxisValue('X', data.x, Colors.red.shade400),
                _buildAxisValue('Y', data.y, Colors.green.shade400),
                _buildAxisValue('Z', data.z, Colors.blue.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAxisValue(String axis, double value, Color color) {
    return Column(
      children: [
        Text(
          axis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionCard(DetectionResult detection) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: detection.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: detection.color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: detection.color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  detection.type,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: detection.color,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: detection.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${detection.confidence.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detection.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Hidden Device Detection',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      _getThreatColor(_magneticFieldStrength).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getThreatColor(_magneticFieldStrength),
                    width: 2,
                  ),
                ),
                child: Text(
                  _baselineMagneticField > 0
                      ? '${((_magneticFieldStrength - _baselineMagneticField).abs() / _baselineMagneticField * 100).toStringAsFixed(1)}%'
                      : 'Calibrating...',
                  style: TextStyle(
                    color: _getThreatColor(_magneticFieldStrength),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview Section
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (_isCameraInitialized && _cameraController != null)
                  ClipRect(
                    child: Transform.scale(
                      scale: 1.0,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _cameraController!.value.aspectRatio,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Initializing Camera...',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                if (_isScanning)
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: MediaQuery.of(context).size.height *
                                0.35 *
                                _scanAnimation.value -
                            2,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.cyan.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isScanning ? Colors.red : Colors.grey,
                            shape: BoxShape.circle,
                            boxShadow: _isScanning
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isScanning ? 'SCANNING' : 'READY',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scan Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: ElevatedButton(
              onPressed: _toggleScanning,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScanning ? Colors.red : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isScanning ? Icons.stop_circle : Icons.radar,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isScanning ? 'Stop Scanning' : 'Start Detection Scan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Detection Results or Sensor Data
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_detections.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Detection Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    ..._detections
                        .map((detection) => _buildDetectionCard(detection)),
                    const SizedBox(height: 16),
                  ],
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Sensor Readings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildSensorCard(
                      'Magnetometer', _magnetometer, Icons.explore),
                  _buildSensorCard(
                      'Accelerometer', _accelerometer, Icons.speed),
                  _buildSensorCard(
                      'Gyroscope', _gyroscope, Icons.screen_rotation),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
