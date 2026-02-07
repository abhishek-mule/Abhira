import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class SMSService {
  static final SMSService _instance = SMSService._internal();
  factory SMSService() => _instance;
  SMSService._internal();

  // Your Fast2SMS API Key from .env or hardcoded here if needed
  String? get fast2SMSApiKey => dotenv.get('FAST2SMS_API_KEY', fallback: '');

  /// Main method to send SOS via SMS (can be called after WhatsApp)
  /// [recipients] - List of phone numbers
  /// [message] - SOS message content
  /// [locationLink] - Google Maps link or location string
  /// [delayAfterWhatsApp] - Optional delay in milliseconds before sending SMS (default: 2000ms)
  Future<bool> sendSOS(
      List<String> recipients,
      String message,
      {
        required String locationLink,
        int delayAfterWhatsApp = 2000,
      }
      ) async {
    if (recipients.isEmpty) {
      debugPrint("⚠️ No recipients to send SOS to.");
      return false;
    }

    // Optional delay to let WhatsApp complete first
    if (delayAfterWhatsApp > 0) {
      debugPrint("⏳ Waiting ${delayAfterWhatsApp}ms before sending SMS...");
      await Future.delayed(Duration(milliseconds: delayAfterWhatsApp));
    }

    // Append location link to message if not already included
    String fullMessage = message;
    if (!message.contains(locationLink)) {
      fullMessage = "$message\n\nLocation: $locationLink";
    }

    final hasInternet = await _checkInternetConnection();

    if (hasInternet && fast2SMSApiKey != null && fast2SMSApiKey!.isNotEmpty) {
      // Online: Use Fast2SMS API (Faster, reliable, uses data)
      debugPrint("📶 Online: Attempting to send via Fast2SMS API...");
      bool success = await _sendViaFast2SMS(recipients, fullMessage);

      if (!success) {
        // Fallback to offline SMS if API fails
        debugPrint("⚠️ Fast2SMS Failed. Falling back to Native SMS...");
        await _sendViaNativeSMS(recipients, fullMessage);
        return true; // Return true as fallback was attempted
      }
      return success;
    } else {
      // Offline: Use Native SMS (Uses SIM Card Balance)
      debugPrint("📵 No Internet or API Key missing. Sending via Native SMS...");
      await _sendViaNativeSMS(recipients, fullMessage);
      return true;
    }
  }

  /// Send SMS after WhatsApp with status callback
  Future<SMSResult> sendSOSAfterWhatsApp(
      List<String> recipients,
      String message,
      {
        required String locationLink,
        int delayMs = 2000,
      }
      ) async {
    try {
      bool success = await sendSOS(
        recipients,
        message,
        locationLink: locationLink,
        delayAfterWhatsApp: delayMs,
      );

      return SMSResult(
        success: success,
        recipientCount: recipients.length,
        method: await _checkInternetConnection() ? 'Fast2SMS API' : 'Native SMS',
      );
    } catch (e) {
      debugPrint("❌ Error in sendSOSAfterWhatsApp: $e");
      return SMSResult(
        success: false,
        recipientCount: recipients.length,
        method: 'Failed',
        error: e.toString(),
      );
    }
  }

  Future<bool> _checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    return false;
  }

  // Fast2SMS Implementation
  Future<bool> _sendViaFast2SMS(List<String> recipients, String message) async {
    try {
      // Fast2SMS supports bulk sending via comma separated numbers
      // Numbers should be 10 digits for Fast2SMS India.

      String numbers = recipients.map((e) {
        // Basic cleanup to get 10 digit number
        String cleaned = e.replaceAll(RegExp(r'\D'), '');
        // Take last 10 digits if number is longer
        return cleaned.length > 10 ? cleaned.substring(cleaned.length - 10) : cleaned;
      }).join(',');

      debugPrint("📤 Sending to numbers: $numbers");

      final url = Uri.parse("https://www.fast2sms.com/dev/bulkV2");
      final response = await http.post(
        url,
        headers: {
          'authorization': fast2SMSApiKey!,
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          "route": "q", // Quick transactional route
          "message": message,
          "language": "english",
          "flash": 0,
          "numbers": numbers,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Fast2SMS API timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['return'] == true) {
          debugPrint("✅ SMS Sent successfully via Fast2SMS to ${recipients.length} recipient(s)");
          return true;
        } else {
          debugPrint("❌ Fast2SMS API Error: ${data['message']}");
          return false;
        }
      } else {
        debugPrint("❌ Fast2SMS HTTP Error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Exception calling Fast2SMS: $e");
      return false;
    }
  }

  // Native SMS Implementation (Background)
  Future<void> _sendViaNativeSMS(List<String> recipients, String message) async {
    // Check SMS Permission
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
      if (!status.isGranted) {
        debugPrint("❌ SMS Permission Denied");
        return;
      }
    }

    final Telephony telephony = Telephony.instance;

    // Send to each recipient
    for (String recipient in recipients) {
      try {
        String cleanNumber = recipient.replaceAll(RegExp(r'\D'), '');

        // Telephony sends SMS in background by default
        await telephony.sendSms(
            to: cleanNumber,
            message: message,
            isMultipart: true, // Auto-split long messages
            statusListener: (SendStatus status) {
              if (status == SendStatus.SENT) {
                debugPrint("✅ SMS Sent to $cleanNumber");
              } else if (status == SendStatus.DELIVERED) {
                debugPrint("📩 SMS Delivered to $cleanNumber");
              }
            }
        );
        debugPrint("📤 Sending SMS to $cleanNumber...");

        // Small delay between messages to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));

      } catch (e) {
        debugPrint("❌ Error sending SMS to $recipient: $e");
      }
    }
  }
}

/// Result class to track SMS sending status
class SMSResult {
  final bool success;
  final int recipientCount;
  final String method;
  final String? error;

  SMSResult({
    required this.success,
    required this.recipientCount,
    required this.method,
    this.error,
  });

  @override
  String toString() {
    return 'SMSResult(success: $success, recipients: $recipientCount, method: $method${error != null ? ', error: $error' : ''})';
  }
}