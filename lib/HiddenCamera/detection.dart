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
  final IconData icon;

  DetectionResult({
    required this.type,
    required this.confidence,
    required this.description,
    required this.color,
    required this.icon,
  });
}

class _LiveFeedState extends State<LiveFeed> with TickerProviderStateMixin {
  CameraController? _cameraController;
  late Vector3 _magnetometer = Vector3.zero();

  bool _isScanning = false;
  bool _isCameraInitialized = false;
  bool _useFlashlight = false;
  List<DetectionResult> _detections = [];
  double _magneticFieldStrength = 0.0;
  double _baselineMagneticField = 0.0;
  List<double> _magneticHistory = [];
  List<double> _recentReadings = [];
  int _strongAnomalyCount = 0;
  String _scanMode = 'magnetic'; // 'magnetic' or 'lens'

  late AnimationController _scanAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  StreamSubscription? _magnetometerSubscription;
  Timer? _analysisTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeSensors();
    _setupAnimations();
    _showInfoDialog();
  }

  void _showInfoDialog() {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 12),
              Text('Detection Capabilities'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoSection(
                  '✅ What This App CAN Detect:',
                  [
                    'Electromagnetic Field (EMF) anomalies',
                    'Strong magnetic sources nearby',
                    'Unusual EM patterns',
                    'IR lens reflections (visual inspection)',
                  ],
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  '❌ What This App CANNOT Detect:',
                  [
                    'Non-wireless hidden cameras',
                    'RF signals (requires special hardware)',
                    'Cameras without active electronics',
                    'Professionally concealed devices',
                  ],
                  Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'This is a privacy awareness tool. For professional detection, consult security experts.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got It'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            '• $item',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        )),
      ],
    );
  }

  void _setupAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut),
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
    _magnetometerSubscription = magnetometerEvents.listen((MagnetometerEvent event) {
      if (mounted) {
        final newMag = Vector3(event.x, event.y, event.z);
        setState(() {
          _magnetometer = newMag;
          _magneticFieldStrength = newMag.magnitude;
          _updateMagneticHistory(_magneticFieldStrength);
        });
      }
    });

    // Calculate baseline after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (_magneticHistory.length >= 20) {
        _baselineMagneticField = _magneticHistory.reduce((a, b) => a + b) / _magneticHistory.length;
        setState(() {});
      }
    });
  }

  void _updateMagneticHistory(double value) {
    _magneticHistory.add(value);
    if (_magneticHistory.length > 100) {
      _magneticHistory.removeAt(0);
    }

    _recentReadings.add(value);
    if (_recentReadings.length > 20) {
      _recentReadings.removeAt(0);
    }
  }

  void _analyzeMagneticField() {
    if (_baselineMagneticField == 0.0 || _recentReadings.length < 10) return;

    _detections.clear();

    // Calculate statistics
    final recentAverage = _recentReadings.reduce((a, b) => a + b) / _recentReadings.length;
    final deviation = (recentAverage - _baselineMagneticField).abs();
    final deviationPercentage = (deviation / _baselineMagneticField) * 100;

    // Calculate variance (for spike detection)
    final variance = _recentReadings.map((v) => pow(v - recentAverage, 2)).reduce((a, b) => a + b) / _recentReadings.length;
    final standardDeviation = sqrt(variance);

    // Detection 1: Strong EMF Source
    if (deviationPercentage > 40) {
      _strongAnomalyCount++;
      _detections.add(DetectionResult(
        type: 'Strong EMF Detected',
        confidence: min((deviationPercentage / 50 * 100), 100),
        description: 'Significant electromagnetic field detected. Could be electronic device, wiring, or metal objects.',
        color: Colors.red,
        icon: Icons.electrical_services,
      ));
    } else if (deviationPercentage > 20) {
      _detections.add(DetectionResult(
        type: 'Moderate EMF Activity',
        confidence: min((deviationPercentage / 40 * 100), 100),
        description: 'Unusual magnetic field pattern. Move device slowly around the area.',
        color: Colors.orange,
        icon: Icons.warning_amber,
      ));
    }

    // Detection 2: Fluctuating Field (active electronics)
    if (standardDeviation > 5.0) {
      _detections.add(DetectionResult(
        type: 'Fluctuating Magnetic Field',
        confidence: min((standardDeviation / 10 * 100), 100),
        description: 'Rapid field changes detected. May indicate active electronic device with varying current.',
        color: Colors.deepOrange,
        icon: Icons.show_chart,
      ));
    }

    // Detection 3: Persistent Anomaly
    if (_strongAnomalyCount > 3 && deviationPercentage > 30) {
      _detections.add(DetectionResult(
        type: 'Persistent Anomaly',
        confidence: 85.0,
        description: 'Consistent high readings in this location. Investigate visually for hidden devices.',
        color: Colors.red.shade700,
        icon: Icons.location_searching,
      ));
    }

    // Add educational note
    if (_detections.isEmpty) {
      _detections.add(DetectionResult(
        type: 'Normal Readings',
        confidence: 100.0,
        description: 'No significant EMF anomalies detected. Move slowly around suspicious areas.',
        color: Colors.green,
        icon: Icons.check_circle,
      ));
    }

    setState(() {});
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
      if (_isScanning) {
        _strongAnomalyCount = 0;
        _analysisTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
          if (_scanMode == 'magnetic') {
            _analyzeMagneticField();
          }
        });
      } else {
        _analysisTimer?.cancel();
        _detections.clear();
      }
    });
  }

  Future<void> _toggleFlashlight() async {
    if (_cameraController == null || !_isCameraInitialized) return;

    setState(() {
      _useFlashlight = !_useFlashlight;
    });

    try {
      await _cameraController!.setFlashMode(
        _useFlashlight ? FlashMode.torch : FlashMode.off
      );
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  Color _getThreatColor() {
    if (_baselineMagneticField == 0) return Colors.grey;

    final deviation = (_magneticFieldStrength - _baselineMagneticField).abs();
    final deviationPercentage = (deviation / _baselineMagneticField) * 100;

    if (deviationPercentage > 40) return Colors.red;
    if (deviationPercentage > 20) return Colors.orange;
    return Colors.green;
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _pulseAnimationController.dispose();
    _analysisTimer?.cancel();
    _magnetometerSubscription?.cancel();
    if (_cameraController?.value.isInitialized ?? false) {
      _cameraController!.setFlashMode(FlashMode.off);
      _cameraController!.dispose();
    }
    super.dispose();
  }

  Widget _buildMagneticFieldCard() {
    final deviation = _baselineMagneticField > 0
        ? ((_magneticFieldStrength - _baselineMagneticField).abs() / _baselineMagneticField * 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getThreatColor().withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Magnetic Field',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getThreatColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getThreatColor(), width: 2),
                ),
                child: Text(
                  _baselineMagneticField > 0
                      ? '${deviation.toStringAsFixed(1)}%'
                      : 'Calibrating...',
                  style: TextStyle(
                    color: _getThreatColor(),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isScanning ? _pulseAnimation.value : 1.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getThreatColor().withOpacity(0.1),
                        border: Border.all(
                          color: _getThreatColor().withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          _magneticFieldStrength.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: _getThreatColor(),
                          ),
                        ),
                        Text(
                          'μT',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          if (_baselineMagneticField > 0)
            Text(
              'Baseline: ${_baselineMagneticField.toStringAsFixed(1)} μT',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetectionCard(DetectionResult detection) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: detection.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: detection.color.withOpacity(0.4), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: detection.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(detection.icon, color: detection.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        detection.type,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: detection.color,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: detection.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${detection.confidence.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  detection.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              const Text(
                'How to Use',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstruction('1', 'Move device slowly around suspicious areas'),
          _buildInstruction('2', 'Watch for persistent high EMF readings'),
          _buildInstruction('3', 'Use flashlight mode to check for lens reflections'),
          _buildInstruction('4', 'Visually inspect areas with anomalies'),
        ],
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
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
          'EMF & Privacy Scanner',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(
              _useFlashlight ? Icons.flashlight_on : Icons.flashlight_off,
              color: _useFlashlight ? Colors.amber : Colors.grey,
            ),
            onPressed: _toggleFlashlight,
            tooltip: 'Toggle Flashlight for Lens Detection',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview Section
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
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
                        top: MediaQuery.of(context).size.height * 0.3 * _scanAnimation.value - 2,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
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
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Look for lens reflections with flashlight ON',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scan Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                    _isScanning ? 'Stop Scanning' : 'Start EMF Scan',
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

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMagneticFieldCard(),
                  if (_detections.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Scan Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    ..._detections.map((d) => _buildDetectionCard(d)),
                  ],
                  if (!_isScanning)
                    _buildInstructionCard(),
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
}
