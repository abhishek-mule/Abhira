import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String screenShake = "Be strong, We are with you!";
  double lat = 0.0;
  double long = 0.0;

  try {
    Position userLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    lat = userLocation.latitude;
    long = userLocation.longitude;
    await prefs.setStringList("location", [lat.toString(), long.toString()]);
    print("Location saved: $lat, $long");
  } catch (e) {
    print("Error getting location: $e");
  }

  Timer.periodic(Duration(seconds: 1), (timer) async {
    service.invoke('update', {
      'current_date': DateTime.now().toIso8601String(),
      'message': screenShake,
    });
  });

  return true;
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
