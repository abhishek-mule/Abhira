import 'dart:async';
import 'dart:math';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sensors_plus/sensors_plus.dart';

Future<bool> onStart(ServiceInstance service) async {
  print("Service started");
  final prefs = await SharedPreferences.getInstance();
  print("Service initialized");

  service.on('setAsForeground').listen((event) async {
    print("Foreground mode activated");
  });

  service.on('setAsBackground').listen((event) async {
    print("Background mode activated");
  });

  service.on('stopService').listen((event) async {
    service.stopSelf();
  });

  double lastMagnitude = 0;
  int lastTrigger = 0;

  // Listen to accelerometer for shake detection
  userAccelerometerEvents.listen((event) async {
    final m = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    // threshold + debounce (shake detection)
    if (m > 18 && DateTime.now().millisecondsSinceEpoch - lastTrigger > 4000) {
      lastTrigger = DateTime.now().millisecondsSinceEpoch;
      print("Shake detected! Magnitude: $m");

      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('whatsapp_share_enabled') ?? false;

      if (enabled) {
        print("WhatsApp sharing enabled, getting location...");
        try {
          final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
          print("Location obtained: ${pos.latitude}, ${pos.longitude}");
          await shareLocationOnWhatsApp(pos.latitude, pos.longitude);
        } catch (e) {
          print("Error getting location for WhatsApp sharing: $e");
        }
      } else {
        print("WhatsApp sharing is disabled");
      }
    }

    lastMagnitude = m;
  });

  // Keep service alive with minimal timer
  Timer.periodic(Duration(seconds: 10), (timer) async {
    service.invoke('update', {
      'current_date': DateTime.now().toIso8601String(),
      'message': "Shake detection active",
    });
  });

  return true;
}

Future<void> shareLocationOnWhatsApp(double latitude, double longitude) async {
  try {
    print("Starting WhatsApp sharing process...");
    // Get the SOS contacts
    final prefs = await SharedPreferences.getInstance();
    List<String> sosNumbers = prefs.getStringList('numbers') ?? [];

    if (sosNumbers.isEmpty) {
      print("No SOS contacts found for WhatsApp sharing");
      return;
    }

    print("Found ${sosNumbers.length} SOS contacts");

    // Create Google Maps URL
    String mapsUrl =
        "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";

    // Create SOS message
    String sosMessage = "🚨 EMERGENCY SOS 🚨\n\n"
        "I need help! My current location is:\n"
        "📍 $mapsUrl\n\n"
        "Please check on me immediately!";

    // Encode the message for WhatsApp URL
    String encodedMessage = Uri.encodeComponent(sosMessage);

    // Share with each SOS contact
    for (String contactData in sosNumbers) {
      // Extract phone number from contact format (Name***PhoneNumber)
      String phoneNumber = contactData.split("***")[1];

      // Clean the phone number (remove any non-digit characters)
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

      // Create WhatsApp URL
      String whatsappUrl = "https://wa.me/$cleanedNumber?text=$encodedMessage";

      print("Attempting to share with: $cleanedNumber");

      // Check if WhatsApp can be launched
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        try {
          await launchUrl(Uri.parse(whatsappUrl));
          print("Shared location on WhatsApp with $cleanedNumber");
          // Add a small delay between shares
          await Future.delayed(Duration(seconds: 2));
        } catch (e) {
          print("Error launching WhatsApp for $cleanedNumber: $e");
        }
      } else {
        print("Could not launch WhatsApp for $cleanedNumber");
      }
    }

    print("WhatsApp sharing process completed");
  } catch (e) {
    print("Error in WhatsApp sharing: $e");
  }
}

//GET HOME SAFE _ WORK MANAGER SET TO 15 minutes frequency
// This fumction is attached to get home safe functionality
// which will send the user location data to his/her selected
// contact after every 15 minutes.

// Its simply a workManager which is executing a given task perioadically
// afeter every 15 minutes

// I hope this project have helped you
// And I am just happy that I have helped you in any way :)
// May your all wishes come true - Happy Fluttering <3
