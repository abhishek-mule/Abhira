import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:abhira/Dashboard/Dashboard.dart';
import 'package:abhira/Onboarding/onboarding_screen.dart';
import 'package:abhira/background_services.dart';
import 'package:abhira/design_system.dart';
import 'package:firebase_core/firebase_core.dart';

import 'dart:math' as math;

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize app with comprehensive error handling
  await _initializeApp();

  // Configure system UI
  await _configureSystemUI();

  // Run the app with error boundary
  runZonedGuarded(
    () => runApp(const ProviderScope(child: MyApp())),
    (error, stackTrace) {
      debugPrint('🔴 Uncaught error: $error');
      debugPrint('Stack trace: $stackTrace');
    },
  );
}

/// Initialize all app services and permissions with proper error handling
Future<void> _initializeApp() async {
  try {
    debugPrint('🚀 Initializing Abhira...');

    // Initialize Firebase first
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');

    // Initialize services in parallel for faster startup
    await Future.wait([
      _initializeBackgroundService(),
      _initializeLocationService(),
      _initializeSharedPreferences(),
    ]);

    debugPrint('✅ App initialization completed successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Critical initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    // App will continue but with reduced functionality
  }
}

/// Configure system UI appearance
Future<void> _configureSystemUI() async {
  try {
    // Lock device orientation to portrait mode
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Configure status bar and navigation bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    // Enable edge-to-edge display
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );

    debugPrint('✅ System UI configured');
  } catch (e) {
    debugPrint('⚠️ System UI configuration failed: $e');
  }
}

/// Initialize background service with error handling
Future<void> _initializeBackgroundService() async {
  try {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: false,
        autoStartOnBoot: false,
        notificationChannelId: 'abhira_foreground_service',
        initialNotificationTitle: 'Abhira Safety',
        initialNotificationContent: 'Monitoring your safety',
        foregroundServiceNotificationId: 888,
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
    // Service will be unavailable but app continues
  }
}

/// Initialize and request location permissions with comprehensive checks
Future<void> _initializeLocationService() async {
  try {
    final location = Location();

    // Check if location service is enabled
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      debugPrint('📍 Requesting location service...');
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location service not enabled by user');
        return;
      }
    }

    // Check and request location permission
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      debugPrint('📍 Requesting location permission...');
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        debugPrint('⚠️ Location permission denied by user');
        return;
      }
    }

    if (permissionGranted == PermissionStatus.deniedForever) {
      debugPrint('⚠️ Location permission permanently denied');
      return;
    }

    // Configure location settings
    await location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
      distanceFilter: 10,
    );

    debugPrint('✅ Location service initialized with high accuracy');
  } catch (e) {
    debugPrint('⚠️ Location service initialization failed: $e');
  }
}

/// Pre-initialize SharedPreferences for faster access
Future<void> _initializeSharedPreferences() async {
  try {
    await SharedPreferences.getInstance();
    debugPrint('✅ SharedPreferences initialized');
  } catch (e) {
    debugPrint('⚠️ SharedPreferences initialization failed: $e');
  }
}

/// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: _buildTheme(),
      home: const AppInitializer(),

      // Global error handling
      builder: (context, widget) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Limit text scaling for consistent UI
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
            ),
          ),
          child: widget ?? const SizedBox.shrink(),
        );
      },

      // Configure GetX settings
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),

      // Localization support (future-ready)
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }

  /// Build comprehensive app theme
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.medium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

/// App initializer with enhanced splash screen and routing logic
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isFirstTime = false;
  String _loadingMessage = 'Initializing...';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeAppData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Setup splash screen animations
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  /// Initialize app data with progress updates
  Future<void> _initializeAppData() async {
    try {
      // Minimum splash screen duration for branding
      final minimumDuration = Future.delayed(const Duration(seconds: 2));

      // Load user preferences
      _updateLoadingMessage('Loading preferences...');
      final isFirstTime = await _checkFirstTimeUser();

      // Verify permissions
      _updateLoadingMessage('Checking permissions...');
      await _verifyPermissions();

      // Preload critical data
      _updateLoadingMessage('Preparing app...');
      await _preloadData();

      // Wait for minimum duration
      await minimumDuration;

      if (mounted) {
        setState(() {
          _isFirstTime = isFirstTime;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error initializing app data: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFirstTime = true; // Default to onboarding on error
        });
      }
    }
  }

  /// Update loading message with animation
  void _updateLoadingMessage(String message) {
    if (mounted) {
      setState(() {
        _loadingMessage = message;
      });
    }
  }

  /// Check if user is opening app for first time
  Future<bool> _checkFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasOpenedBefore =
          prefs.getBool(AppConstants.keyAppOpenedBefore) ?? false;

      if (!hasOpenedBefore) {
        await prefs.setBool(AppConstants.keyAppOpenedBefore, true);
        debugPrint('👋 First time user detected');
        return true;
      }

      debugPrint('👤 Returning user detected');
      return false;
    } catch (e) {
      debugPrint('⚠️ Error checking first time user: $e');
      return true;
    }
  }

  /// Verify critical app permissions
  Future<void> _verifyPermissions() async {
    try {
      final location = Location();
      final hasPermission = await location.hasPermission();

      if (hasPermission != PermissionStatus.granted) {
        debugPrint('⚠️ Location permission not granted');
      }
    } catch (e) {
      debugPrint('⚠️ Permission verification failed: $e');
    }
  }

  /// Preload critical app data
  Future<void> _preloadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Preload emergency contacts
      final contacts = prefs.getStringList(AppConstants.keyEmergencyContacts);
      debugPrint('📇 Preloaded ${contacts?.length ?? 0} emergency contacts');

      // Additional preloading can be added here
    } catch (e) {
      debugPrint('⚠️ Data preloading failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildEnhancedSplashScreen();
    }

    // Navigate with smooth transition
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _isFirstTime ? const Onboarding() : const Dashboard(),
    );
  }

  /// Build enhanced splash screen with animations
  Widget _buildEnhancedSplashScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.85),
              AppColors.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Top flexible space
                const Spacer(flex: 1),

                // Centered logo and branding
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        _buildLogo(),

                        const SizedBox(height: AppSpacing.xxxLarge),

                        // App name
                        Text(
                          AppConstants.appName,
                          style: AppTypography.h1.copyWith(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.small),

                        // Tagline
                        Text(
                          AppConstants.appTagline,
                          style: AppTypography.subtitle.copyWith(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom flexible space with loading and footer
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Spacer(),

                      // Loading indicator with message
                      _buildLoadingSection(),

                      const SizedBox(height: AppSpacing.xxxLarge),

                      // Footer
                      _buildFooter(),

                      const SizedBox(height: AppSpacing.large),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build animated logo
  Widget _buildLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Image.asset(
              'assets/GoSecure-logos.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  /// Build loading section with progress
  Widget _buildLoadingSection() {
    return Column(
      children: [
        // Circular progress indicator
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
            backgroundColor: Colors.white.withOpacity(0.3),
          ),
        ),

        const SizedBox(height: AppSpacing.medium),

        // Loading message
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _loadingMessage,
            key: ValueKey<String>(_loadingMessage),
            style: AppTypography.body.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// Build footer with version info
  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Powered by Abhira Team',
          style: AppTypography.caption.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          'Version 1.0.0',
          style: AppTypography.caption.copyWith(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Enhanced hex color utility
class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return int.parse(hexColor, radix: 16);
  }
}

/// Comprehensive app constants
class AppConstants {
  // App identity
  static const String appName = 'Abhira';
  static const String appTagline = 'Your Safety, Our Priority';
  static const String appVersion = '1.0.0';

  // Color palette
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = Color(0xFFFBD079);
  static const Color dangerColor = AppColors.destructive;
  static const Color successColor = AppColors.success;

  // SharedPreferences keys
  static const String keyAppOpenedBefore = 'appOpenedBefore';
  static const String keyEmergencyContacts = 'numbers';
  static const String keyUserName = 'userName';
  static const String keyUserEmail = 'userEmail';
  static const String keyUserPin = 'pin';
  static const String keyAlerted = 'alerted';
  static const String keyBackgroundServiceEnabled = 'backgroundServiceEnabled';

  // Permission identifiers
  static const String permissionLocation = 'location';
  static const String permissionContacts = 'contacts';
  static const String permissionCamera = 'camera';
  static const String permissionMicrophone = 'microphone';
  static const String permissionSMS = 'sms';
  static const String permissionPhone = 'phone';

  // API endpoints (for future use)
  static const String baseUrl = 'https://api.abhira.app';

  // Emergency numbers
  static const String emergencyPolice = '100';
  static const String emergencyAmbulance = '102';
  static const String emergencyFireBrigade = '101';
}

/// Enhanced utility functions
class AppUtils {
  /// Show toast with enhanced styling
  static void showToast(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Color backgroundColor;
    if (isError) {
      backgroundColor = AppColors.destructive;
    } else if (isSuccess) {
      backgroundColor = AppColors.success;
    } else {
      backgroundColor = AppColors.primary;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Show enhanced loading dialog
  static void showLoadingDialog(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => WillPopScope(
        onWillPop: () async => barrierDismissible,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.large),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    message,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hide loading dialog safely
  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Format phone number with country code
  static String formatPhoneNumber(String phone, {String countryCode = '+91'}) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');

    if (cleaned.isEmpty) return phone;

    // Already has country code
    if (cleaned.startsWith(countryCode.substring(1))) {
      return '+$cleaned';
    }

    // Remove leading zero
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    // Add country code
    if (cleaned.length >= 10) {
      return '$countryCode$cleaned';
    }

    return phone;
  }

  /// Validate email address
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Validate phone number
  static bool isValidPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    return cleaned.length >= 10 && cleaned.length <= 15;
  }

  /// Validate PIN
  static bool isValidPin(String pin) {
    return RegExp(r'^\d{4}$').hasMatch(pin);
  }

  /// Format date time
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Calculate distance between two coordinates (Haversine formula)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Vibrate device for haptic feedback
  static Future<void> vibrate(
      {Duration duration = const Duration(milliseconds: 100)}) async {
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      debugPrint('⚠️ Vibration failed: $e');
    }
  }

  /// Heavy haptic feedback (for critical actions)
  static Future<void> heavyVibrate() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('⚠️ Heavy vibration failed: $e');
    }
  }
}
