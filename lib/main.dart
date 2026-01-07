import 'dart:async';

// import 'package:background_location/background_location.dart';
// import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gosecure/Dashboard/Dashboard.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gosecure/Onboarding/onboarding_screen.dart';
import 'package:gosecure/background_services.dart';

// List<CameraDescription> cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // cameras = await availableCameras();
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: onStart,
    ),
  );

  final Location location = Location();
  late PermissionStatus permissionGranted;
  late bool serviceEnabled;
  serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      return;
    }
  }

  permissionGranted = await location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await location.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      return;
    }
  }
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoSecure',
      theme: ThemeData(
        fontFamily: GoogleFonts.poppins().fontFamily,
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
          future: isAppOpeningForFirstTime(),
          builder: (context, AsyncSnapshot<bool> snap) {
            if (snap.hasData) {
              if (snap.data!) {
                // return LiveFeed(cameras);
                return Dashboard();
                // return Onboarding();
              } else {
                // Future.delayed(Duration.zero, () => showLocAlert(context));
                return Onboarding();
                // return Splash();
              }
            } else {
              return Onboarding();
            }
          }),
    );
  }

  Future<bool> isAppOpeningForFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool result = prefs.getBool("appOpenedBefore") ?? false;
    if (!result) {
      prefs.setBool("appOpenedBefore", true);
    }
    return result;
  }
}

class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }
}
