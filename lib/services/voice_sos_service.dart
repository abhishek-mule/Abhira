import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceSOSService {
  static final VoiceSOSService _instance = VoiceSOSService._internal();
  factory VoiceSOSService() => _instance;
  VoiceSOSService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  Function? _onSOSTriggered;
  Timer? _restartTimer;

  // Keywords that trigger the SOS
  final List<String> _triggerKeywords = [
    'help', 
    'save me', 
    'emergency', 
    'bachao' 
  ];

  Future<void> init({Function? onSOSTriggered}) async {
    _onSOSTriggered = onSOSTriggered;
    _isAvailable = await _speechToText.initialize(
      onError: (val) {
        debugPrint('STT Error: ${val.errorMsg} - ${val.permanent}');
        _isListening = false;
        // Only restart for non-permanent errors or timeouts
        if (val.errorMsg == 'error_speech_timeout' || val.errorMsg == 'error_no_match') {
          _restartListeningDelayed();
        }
      },
      onStatus: (val) {
        debugPrint('STT Status: $val');
        if (val == 'done' || val == 'notListening') {
           _isListening = false;
           _restartListeningDelayed();
        }
      },
      debugLogging: true,
    );

    if (_isAvailable) {
      startListening();
    }
  }

  void startListening() {
    if (_isListening || !_isAvailable) return;
    
    try {
      _speechToText.listen(
        onResult: (result) {
          final String words = result.recognizedWords.toLowerCase();
          // debugPrint("Heard: $words"); // Uncomment to see live words
          
          for (final keyword in _triggerKeywords) {
            if (words.contains(keyword)) {
              _triggerSOS();
              break;
            }
          }
        },
        listenFor: const Duration(seconds: 10), // Short burst to avoid system timeout
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      );
      _isListening = true;
    } catch (e) {
      debugPrint("STT Start Error: $e");
      _isListening = false;
      _restartListeningDelayed();
    }
  }

  void _restartListeningDelayed() {
    // Avoid rapid restart loops (fixing error_busy and reducing CPU load)
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(seconds: 3), () { // Increased from 2 to 3 seconds
      if (!_isListening) {
        startListening();
      }
    });
  }

  void _triggerSOS() {
    debugPrint("SOS TRIGGERED BY VOICE!");
    stopListening();
    if (_onSOSTriggered != null) {
      _onSOSTriggered!();
    }
  }

  void stopListening() {
    _displayStatus("Stopped");
    _restartTimer?.cancel();
    _speechToText.stop();
    _isListening = false;
  }
  
  void _displayStatus(String status) {
     debugPrint("Voice SOS: $status");
  }
}
