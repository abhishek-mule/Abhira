import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:intl/intl.dart';

class EvidenceService {
  static final EvidenceService _instance = EvidenceService._internal();
  factory EvidenceService() => _instance;
  EvidenceService._internal();

  CameraController? _cameraController;
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _photoTimer;
  bool _isRecording = false;
  String? _currentSessionId;

  // Initialize camera (usually called early on or when needed)
  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      // Prefer front camera for evidence
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low, // Changed from medium to low for better performance
        enableAudio: false, // We record audio separately
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
    } catch (e) {
      debugPrint("Error initializing camera for evidence: $e");
    }
  }

  Future<void> startEmergencyRecording() async {
    if (_isRecording) return;
    _isRecording = true;
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();

    // 1. Start Audio Recording
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/evidence_audio_$_currentSessionId.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(), 
          path: filePath
        );
      }
    } catch (e) {
      debugPrint("Error starting audio recording: $e");
    }

    // Start periodic photo capture (every 10 seconds for better performance)
    _photoTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      await _captureAndUploadPhoto();
    });
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    _photoTimer?.cancel();

    // Stop Audio & Upload
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        await _uploadFile(file, "audio.m4a");
      }
    } catch (e) {
      debugPrint("Error stopping audio recording: $e");
    }

    // Dispose camera resources if needed, or keep for next time
    // _cameraController?.dispose(); 
  }

  Future<void> _captureAndUploadPhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await initialize(); // Try to init if not ready
      if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    }

    if (_cameraController!.value.isTakingPicture) return;

    try {
      final XFile image = await _cameraController!.takePicture();
      final File file = File(image.path);
      
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      await _uploadFile(file, "photo_$timestamp.jpg");
    } catch (e) {
      debugPrint("Error taking evidence photo: $e");
    }
  }

  Future<void> _uploadFile(File file, String filename) async {
    if (_currentSessionId == null) return;
    
    try {
      if (!file.existsSync()) {
        debugPrint("❌ Error: Local file not found at ${file.path}");
        return;
      }

      // Structure: evidence/{sessionId}/{filename}
      final ref = FirebaseStorage.instance
          .ref()
          .child('evidence')
          .child(_currentSessionId!)
          .child(filename);

      await ref.putFile(file);
      debugPrint("✅ Evidence uploaded: $filename");
      
      // Optional: Delete local file after upload
      // await file.delete(); 
    } on FirebaseException catch (e) {
      debugPrint("❌ Firebase Storage Error ($filename): ${e.code} - ${e.message}");
      if (e.code == 'object-not-found') {
        debugPrint("👉 HINT: Make sure 'Storage' is enabled in your Firebase Console and the bucket info is in google-services.json");
      }
    } catch (e) {
      debugPrint("❌ General Upload Error: $e");
    }
  }
}
