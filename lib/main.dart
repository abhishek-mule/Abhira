import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ursafe/Dashboard/Dashboard.dart';
import 'package:ursafe/Onboarding/onboarding_screen.dart';
import 'package:ursafe/background_services.dart';
import 'package:ursafe/design_system.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app with error handling
  await _initializeApp();

  // Lock device orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

/// Initialize all app services and permissions
Future<void> _initializeApp() async {
  try {
    // Initialize background service
    await _initializeBackgroundService();

    // Request location permissions
    await _initializeLocationService();

    debugPrint('✅ App initialization completed successfully');
  } catch (e) {
    debugPrint('❌ App initialization error: $e');
    // App will continue to run, but some features may be limited
  }
}

/// Initialize background service
Future<void> _initializeBackgroundService() async {
  try {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: false,
        autoStartOnBoot: false,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        onBackground: onStart,
        autoStart: false,
      ),
    );

    debugPrint('✅ Background service configured');
  } catch (e) {
    debugPrint('⚠️ Background service configuration failed: $e');
  }
}

/// Initialize and request location permissions
Future<void> _initializeLocationService() async {
  try {
    final location = Location();

    // Check if location service is enabled
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location service not enabled');
        return;
      }
    }

    // Check location permission
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        debugPrint('⚠️ Location permission not granted');
        return;
      }
    }

    debugPrint('✅ Location service initialized');
  } catch (e) {
    debugPrint('⚠️ Location service initialization failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Abhira',
      theme: _buildTheme(),
      home: const AppInitializer(),

      // Error handling
      builder: (context, widget) {
        // Handle text scaling
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor:
                MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
          ),
          child: widget ?? const SizedBox.shrink(),
        );
      },
    );
  }

  /// Build app theme
  ThemeData _buildTheme() {
    return AppTheme.lightTheme;
  }
}

/// App initializer with splash and first-time check
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _isFirstTime = false;

  @override
  void initState() {
    super.initState();
    _initializeAppData();
  }

  /// Initialize app data and check first-time status
  Future<void> _initializeAppData() async {
    try {
      // Simulate splash screen delay
      await Future.delayed(const Duration(seconds: 2));

      // Check if app is opening for first time
      final isFirstTime = await _checkFirstTimeUser();

      if (mounted) {
        setState(() {
          _isFirstTime = isFirstTime;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing app data: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFirstTime = true; // Default to onboarding on error
        });
      }
    }
  }

  /// Check if user is opening app for first time
  Future<bool> _checkFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasOpenedBefore = prefs.getBool("appOpenedBefore") ?? false;

      if (!hasOpenedBefore) {
        await prefs.setBool("appOpenedBefore", true);
        return true; // First time user
      }

      return false; // Returning user
    } catch (e) {
      debugPrint('Error checking first time user: $e');
      return true; // Default to first time on error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSplashScreen();
    }

    // Navigate to appropriate screen
    return _isFirstTime ? const Onboarding() : const Dashboard();
  }

  /// Build splash screen
  Widget _buildSplashScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.6),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxLarge),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/GoSecure-logos.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: AppSpacing.xxxLarge),

              // App name
              Text(
                'Abhira',
                style: AppTypography.h1.copyWith(
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: AppSpacing.small),

              // Tagline
              Text(
                'Your Safety, Our Priority',
                style: AppTypography.subtitle.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),

              const SizedBox(height: AppSpacing.xxxLarge),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hex color utility class
class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return int.parse(hexColor, radix: 16);
  }
}

/// App constants
class AppConstants {
  static const String appName = 'Abhira';
  static const String appTagline = 'Your Safety, Our Priority';

  // Colors
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = Color(0xFFFBD079);
  static const Color dangerColor = AppColors.destructive;

  // Shared preferences keys
  static const String keyAppOpenedBefore = 'appOpenedBefore';
  static const String keyEmergencyContacts = 'numbers';
  static const String keyUserName = 'userName';
  static const String keyUserEmail = 'userEmail';

  // Permissions
  static const String permissionLocation = 'location';
  static const String permissionContacts = 'contacts';
  static const String permissionCamera = 'camera';
  static const String permissionMicrophone = 'microphone';
}

/// Global utility functions
class AppUtils {
  /// Show toast message
  static void showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? AppColors.destructive : AppColors.primary,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.pop(context);
  }

  /// Format phone number
  static String formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length >= 10) {
      if (cleaned.length > 10 && !cleaned.startsWith('0')) {
        return '+$cleaned';
      }
      if (cleaned.startsWith('0')) {
        return '+92${cleaned.substring(1)}';
      }
      return '+$cleaned';
    }

    return phone;
  }

  /// Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate phone number
  static bool isValidPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    return cleaned.length >= 10;
  }
}
