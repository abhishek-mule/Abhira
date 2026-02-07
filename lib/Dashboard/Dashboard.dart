import 'dart:async';
import 'dart:math';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as appPermissions;
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:abhira/Dashboard/ContactScreens/phonebook_view.dart';
import 'package:abhira/Dashboard/Home.dart';
import 'package:abhira/Dashboard/ContactScreens/MyContacts.dart';
import 'package:abhira/Dashboard/AIAssistant/ai_assistant_screen.dart';
import 'package:abhira/Dashboard/Settings/SettingsScreen.dart';
import 'package:abhira/Dashboard/Settings/About.dart';
import 'package:abhira/background_services.dart';
import 'package:abhira/design_system.dart';
import 'package:sensors_plus/sensors_plus.dart'; 
import 'package:abhira/services/evidence_service.dart';
import 'package:abhira/services/voice_sos_service.dart';
import 'package:abhira/services/sms_service.dart';


class Dashboard extends StatefulWidget {
  final int pageIndex;
  const Dashboard({Key? key, this.pageIndex = 0}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState(currentPage: pageIndex);
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  _DashboardState({this.currentPage = 0});

  List<Widget> screens = [Home(), MyContactsScreen()];
  bool alerted = false;
  int currentPage = 0;
  var _battery = Battery();
  final TextEditingController _pinPutController = TextEditingController();
  final FocusNode _pinPutFocusNode = FocusNode();
  bool pinChanged = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  // Shake detection variables
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _shakeThreshold = 8.0; // Increased sensitivity - lower threshold
  int _shakeCount = 0;
  DateTime? _lastShakeTime;
  Timer? _shakeResetTimer;

  final defaultPinTheme = PinTheme(
    width: 60,
    height: 60,
    textStyle: TextStyle(
      fontSize: 24,
      color: Color(0xFF1A1A1A),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Color(0xFFE5E7EB), width: 2),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
  );

  @override
  void initState() {
    super.initState();

    // Initialize animation synchronously FIRST
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    // Then initialize async operations
    checkAlertSharedPreferences();
    checkPermission();
    _initShakeDetection();
    
    // Initialize Voice SOS (With auto-restart logic inside service)
    VoiceSOSService().init(onSOSTriggered: () {
      if (mounted && !alerted) {
         debugPrint("Voice SOS Detected! Sending Alert...");
         sendAlertSMS(true);
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _shakeResetTimer?.cancel();
    _fabAnimationController.dispose();
    _pinPutController.dispose();
    _pinPutFocusNode.dispose();
    super.dispose();
  }

  // PART 1: SHAKE DETECTION
  void _initShakeDetection() {
    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        _detectShake(event.x, event.y, event.z);
      },
      onError: (error) {
        print("Accelerometer error: $error");
      },
    );
  }

  void _detectShake(double x, double y, double z) {
    // Calculate the magnitude of acceleration
    double acceleration = sqrt(x * x + y * y + z * z);

    // Remove gravity (9.8 m/s²)
    double gForce = (acceleration - 9.8).abs();

    if (gForce > _shakeThreshold) {
      DateTime now = DateTime.now();

      // Check if this is a new shake or continuation
      if (_lastShakeTime == null ||
          now.difference(_lastShakeTime!) > Duration(milliseconds: 500)) {
        _shakeCount = 1;
      } else {
        _shakeCount++;
      }

      _lastShakeTime = now;

      // Reset shake count after 2 seconds
      _shakeResetTimer?.cancel();
      _shakeResetTimer = Timer(Duration(seconds: 2), () {
        _shakeCount = 0;
      });

      // Trigger SOS after 3 rapid shakes (prevent accidental triggers)
      if (_shakeCount >= 3) {
        _onShakeDetected();
        _shakeCount = 0; // Reset to prevent multiple triggers
      }
    }
  }

  void _onShakeDetected() async {
    print("⚡ _onShakeDetected called! Current alerted state: $alerted");

    if (!alerted) {
      HapticFeedback.heavyImpact();

      // Check if notifications are enabled
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('shake_notifications_enabled') ?? true;

      if (notificationsEnabled) {
        Fluttertoast.showToast(
          msg: '🚨 Shake detected! Sending SOS...',
          backgroundColor: Color(0xFFEF4444),
          textColor: Colors.white,
          fontSize: 16,
          toastLength: Toast.LENGTH_LONG,
        );
      }

      print("🚀 Calling sendAlertSMS(true)...");
      sendAlertSMS(true);
    } else {
      print("⚠️ Already in alerted state, ignoring shake");
    }
  }

  late SharedPreferences prefs;

  checkAlertSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        alerted = prefs.getBool("alerted") ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      floatingActionButton: _buildSOSFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      drawer: _buildDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 56, // Standard app bar height
        title: Text(
          'Abhira',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false, // Align title to the left
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Settings icon - opposite side of drawer (right side)
          IconButton(
            icon: Icon(Icons.settings_rounded, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
          // Emergency indicator if alert is active
          if (alerted)
            Container(
              margin: EdgeInsets.only(left: 8, right: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.destructive.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.destructive.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppColors.destructive, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'ALERT ACTIVE',
                    style: TextStyle(
                      color: AppColors.destructive,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Stack(
        children: [
          _buildBottomNavigation(),
          // Abhira AI Button positioned above bottom navigation, right side - ULTRA VISIBLE
          Positioned(
            right: 28,
            bottom: 110, // Increased clearance above navigation bar
            child: Transform.scale(
              scale: 1.1, // Slightly larger for better visibility
              child: Container(
                width: 68, // Larger container
                height: 68, // Larger container
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1), // Indigo
                      Color(0xFF8B5CF6), // Purple
                    ],
                  ),
                  boxShadow: [
                    // Dark shadow for depth
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 3,
                      offset: Offset(0, 8),
                    ),
                    // Colored glow effect - multiple layers
                    BoxShadow(
                      color: Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 2,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 1,
                      offset: Offset(0, 4),
                    ),
                    // White inner glow
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: -4,
                      offset: Offset(-2, -2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  elevation: 16,
                  borderRadius: BorderRadius.circular(34),
                  shadowColor: Colors.black.withOpacity(0.5),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AIAssistantScreen()),
                      );
                    },
                    customBorder: CircleBorder(),
                    child: Center(
                      child: Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 28, // Larger icon
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: screens[currentPage],
      ),
    );
  }

  // SOS FAB - Center docked, always visible - VISUAL ANCHOR
  Widget _buildSOSFab() {
    return Semantics(
      label: alerted ? 'Stop SOS alert' : 'Send SOS alert',
      button: true,
      hint: alerted
          ? 'Tap to stop the emergency alert'
          : 'Tap to send emergency alert to your contacts',
      child: Container(
        width: 90, // Increased size
        height: 90, // Increased size
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: alerted
                ? [Color(0xFFDC2626), Color(0xFFB91C1C)]
                : [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          boxShadow: [
            BoxShadow(
              color: (alerted ? Color(0xFFDC2626) : Color(0xFFEF4444))
                  .withOpacity(0.5),
              blurRadius: 25,
              spreadRadius: 3,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: (alerted ? Color(0xFFDC2626) : Color(0xFFEF4444))
                  .withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 1,
              offset: Offset(0, 15),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              HapticFeedback.heavyImpact();

              if (alerted) {
                int pin = (prefs.getInt('pin') ?? -1111);
                if (pin == -1111) {
                  sendAlertSMS(false);
                } else {
                  showPinModelBottomSheet(pin);
                }
              } else {
                sendAlertSMS(true);
              }
            },
            customBorder: CircleBorder(),
            child: Center(
              child: alerted
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_rounded,
                          color: Colors.white,
                          size: 36, // Increased icon size
                        ),
                        SizedBox(height: 2),
                        Text(
                          "STOP",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 44, // Increased icon size
                        ),
                        SizedBox(height: 1),
                        Text(
                          "SOS",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // Bottom Navigation: Home (left) | SOS (center) | Contacts (right)
  Widget _buildBottomNavigation() {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: _buildBottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                isSelected: currentPage == 0,
              ),
            ),
            const SizedBox(width: 80), // Space for the center-docked SOS FAB
            Expanded(
              flex: 1,
              child: _buildBottomNavItem(
                icon: Icons.contacts_rounded,
                label: 'Contacts',
                index: 1,
                isSelected: currentPage == 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    int? index,
    VoidCallback? onTap,
    required bool isSelected,
  }) {
    return Semantics(
      label: '$label tab',
      selected: isSelected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ??
              () {
                if (index != null && index != currentPage) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    currentPage = index;
                  });
                }
              },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? const Color(0xFFEF4444) : Colors.grey,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFFEF4444) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  checkPermission() async {
    appPermissions.PermissionStatus conPer =
        await appPermissions.Permission.contacts.status;
    appPermissions.PermissionStatus locPer =
        await appPermissions.Permission.location.status;
    appPermissions.PermissionStatus phonePer =
        await appPermissions.Permission.phone.status;
    appPermissions.PermissionStatus smsPer =
        await appPermissions.Permission.sms.status;

    if (conPer != appPermissions.PermissionStatus.granted) {
      await appPermissions.Permission.contacts.request();
    }
    if (locPer != appPermissions.PermissionStatus.granted) {
      await appPermissions.Permission.location.request();
    }
    if (phonePer != appPermissions.PermissionStatus.granted) {
      await appPermissions.Permission.phone.request();
    }
    if (smsPer != appPermissions.PermissionStatus.granted) {
      await appPermissions.Permission.sms.request();
    }
  }

  // PART 2: GET LOCATION & BUILD GOOGLE MAPS LINK
  Future<String> _getLocationAndBuildLink() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      // Build Google Maps link
      String mapsLink =
          "https://www.google.com/maps?q=${position.latitude},${position.longitude}";

      print("Location obtained: ${position.latitude}, ${position.longitude}");
      print("Maps link: $mapsLink");

      return mapsLink;
    } catch (e) {
      print("Error getting location: $e");
      throw e;
    }
  }

  // PART 3: OPEN WHATSAPP WITH PREFILLED TEXT
  Future<void> _sendWhatsAppMessage(
      String message, List<String> phoneNumbers) async {
    try {
      // WhatsApp only supports one recipient at a time
      // We'll loop through all numbers
      for (String number in phoneNumbers) {
        // Clean the phone number (remove spaces, dashes, etc.)
        String cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');

        // Ensure number has country code
        if (!cleanNumber.startsWith('+')) {
          // Add default country code if needed (adjust for your region)
          cleanNumber = '+91$cleanNumber'; // Change +91 to your country code
        }

        // Encode the message for URL
        String encodedMessage = Uri.encodeComponent(message);

        // Create WhatsApp URL (universal link format)
        // For multiple contacts, we send to each one individually
        String whatsappUrl = 'https://wa.me/$cleanNumber?text=$encodedMessage';

        Uri uri = Uri.parse(whatsappUrl);

        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          // Add delay between messages if sending to multiple contacts
          if (phoneNumbers.indexOf(number) < phoneNumbers.length - 1) {
            await Future.delayed(Duration(seconds: 2));
          }
        } else {
          throw Exception('Could not launch WhatsApp for $cleanNumber');
        }
      }
    } catch (e) {
      print("Error sending WhatsApp message: $e");
      throw e;
    }
  }

  // Alternative: Send to multiple contacts using WhatsApp's group feature
  Future<void> _sendWhatsAppToFirst(String message, String phoneNumber) async {
    try {
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      if (!cleanNumber.startsWith('+')) {
        cleanNumber = '+91$cleanNumber'; // Adjust country code
      }

      String encodedMessage = Uri.encodeComponent(message);
      String whatsappUrl = 'https://wa.me/$cleanNumber?text=$encodedMessage';

      Uri uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      print("Error sending WhatsApp message: $e");
      throw e;
    }
  }

  sendAlertSMS(bool isAlert) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool("alerted", isAlert);
      alerted = isAlert;
    });
    checkPermission();

    prefs.setBool("alerted", isAlert);
    List<String> numbers = prefs.getStringList("numbers") ?? [];

    try {
      if (numbers.isEmpty) {
        setState(() {
          prefs.setBool("alerted", false);
          alerted = false;
        });
        return Fluttertoast.showToast(
          msg: 'No Contacts Found!',
          backgroundColor: Color(0xFFEF4444),
          textColor: Colors.white,
          fontSize: 16,
        );
      }

      // Get location and build maps link
      String mapsLink = await _getLocationAndBuildLink();

      if (isAlert) {
        // SOS Alert - Load custom message or use default
        final prefs = await SharedPreferences.getInstance();
        String customMessage = prefs.getString('custom_sos_message') ??
            "🚨 EMERGENCY SOS ALERT 🚨\n\nI need immediate help! Please check my location:\n\n{LOCATION}\n\nThis is an automated emergency message from my safety app.";

        // Replace {LOCATION} placeholder with actual Google Maps link
        String message = customMessage.replaceAll('{LOCATION}', mapsLink);

        // Show immediate feedback to user
        Fluttertoast.showToast(
          msg: '🚨 Sending SOS Alert...',
          backgroundColor: Color(0xFFEF4444),
          textColor: Colors.white,
          fontSize: 16,
        );

        // Run heavy operations in background to avoid blocking UI
        _sendSOSInBackground(message, numbers, mapsLink);
      } else {
        // Safe notification / False alarm
        String message = "✅ FALSE ALARM - I am safe\n\n"
            "The previous SOS alert was a false alarm. I am okay.\n\n"
            "Current location: $mapsLink\n\n"
            "Thank you for your concern.";

        await _sendWhatsAppMessage(message, numbers);
        
        // Stop Evidence Recording
        await EvidenceService().stopRecording();

        Fluttertoast.showToast(
          msg: "Contacts notified via WhatsApp",
          backgroundColor: Color(0xFF10B981),
          textColor: Colors.white,
          fontSize: 16,
        );
      }
    } catch (e) {
      print("Error in sendAlertSMS: $e");

      // Reset alert state on error
      prefs.setBool("alerted", false);
      setState(() {
        alerted = false;
      });

      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Color(0xFFEF4444),
        textColor: Colors.white,
        fontSize: 16,
      );
    }
  }

  // Background method to handle SOS operations without blocking UI
  void _sendSOSInBackground(String message, List<String> numbers, String mapsLink) async {
    try {
      // 1. Start SMS sending FIRST (asynchronous, non-blocking)
      debugPrint("📱 Initiating SMS send to ${numbers.length} contacts...");
      Future.microtask(() async {
        bool smsSuccess = await SMSService().sendSOS(
          numbers, 
          message, 
          locationLink: mapsLink,
          delayAfterWhatsApp: 0, // No delay needed now as we reordered
        );
        if (smsSuccess) {
          debugPrint("✅ SMS sent successfully in background");
        } else {
          debugPrint("⚠️ SMS sending had issues (check logs)");
        }
      });
      
      // 2. Start Evidence Recording (asynchronous, non-blocking)
      Future.microtask(() async {
        await EvidenceService().startEmergencyRecording();
        debugPrint("📹 Evidence recording started in background");
      });

      // 3. Show success message (immediate)
      if (mounted) {
        Fluttertoast.showToast(
          msg: '🚨 SOS Alert Initiated! Sending SMS & Recording...',
          backgroundColor: Color(0xFFEF4444),
          textColor: Colors.white,
          fontSize: 16,
          toastLength: Toast.LENGTH_LONG,
        );
      }

      // 4. Send via WhatsApp (context-switching, should be last)
      // We don't await this if it's the last operation, or we await it but tasks before it are already started
      await _sendWhatsAppMessage(message, numbers);
      
      debugPrint("✅ Background SOS process completed");

    } catch (e) {
      debugPrint("❌ Error in background SOS: $e");
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error sending SOS: ${e.toString()}',
          backgroundColor: Color(0xFFEF4444),
          textColor: Colors.white,
          fontSize: 16,
        );
      }
    }
  }

  showPinModelBottomSheet(int userPin) {
    showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFEF2F2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          color: Color(0xFFEF4444),
                          size: 40,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Enter Your PIN",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Please verify your identity to stop the alert",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 32),
                      Pinput(
                        length: 4,
                        onCompleted: (String pin) =>
                            _showSnackBar(pin, context, userPin),
                        focusNode: _pinPutFocusNode,
                        controller: _pinPutController,
                        defaultPinTheme: defaultPinTheme,
                        hapticFeedbackType: HapticFeedbackType.lightImpact,
                        submittedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            color: Color(0xFFFEF2F2),
                            border: Border.all(
                              color: Color(0xFFEF4444),
                              width: 2,
                            ),
                          ),
                        ),
                        focusedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            border: Border.all(
                              color: Color(0xFFEF4444).withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String pin, BuildContext context, int userPin) {
    if (userPin == int.parse(pin)) {
      Navigator.of(context).pop();
      Fluttertoast.showToast(
        msg: 'We are glad that you are safe',
        backgroundColor: Color(0xFF10B981),
        textColor: Colors.white,
        fontSize: 16,
      );
      sendAlertSMS(false);
      _pinPutController.clear();
      _pinPutFocusNode.unfocus();
    } else {
      Fluttertoast.showToast(
        msg: 'Wrong Pin! Please try again',
        backgroundColor: Color(0xFFEF4444),
        textColor: Colors.white,
        fontSize: 16,
      );
      _pinPutController.clear();
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header with App Logo and Name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white, // Clean white background
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Logo
                  Image.asset(
                    'assets/icons/abhira.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8), // Closer spacing
                  Text(
                    'Abhira',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Main Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    index: 0,
                    isSelected: currentPage == 0,
                  ),
                  _buildDrawerItem(
                    icon: Icons.contacts_rounded,
                    title: 'Contacts',
                    index: 1,
                    isSelected: currentPage == 1,
                  ),
                  Divider(height: 1, color: AppColors.border),
                  _buildDrawerItem(
                    icon: Icons.warning_rounded,
                    title: 'SOS / Alerts',
                    onTap: () {
                      // Trigger SOS alert
                      sendAlertSMS(true);
                      Navigator.of(context).pop();
                    },
                    isSelected: false,
                  ),
                  _buildDrawerItem(
                    icon: Icons.smart_toy_rounded,
                    title: 'AI Bot',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AIAssistantScreen()),
                      );
                    },
                    isSelected: false,
                  ),
                  Divider(height: 1, color: AppColors.border),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Profile / Settings',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingsScreen()),
                      );
                    },
                    isSelected: false,
                  ),
                  _buildDrawerItem(
                    icon: Icons.history_rounded,
                    title: 'History / Logs',
                    onTap: () {
                      // TODO: Implement history screen
                      Navigator.of(context).pop();
                      Fluttertoast.showToast(
                        msg: 'History feature coming soon!',
                        backgroundColor: AppColors.primary,
                      );
                    },
                    isSelected: false,
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_rounded,
                    title: 'Resources / Help',
                    onTap: () {
                      // TODO: Implement help screen
                      Navigator.of(context).pop();
                      Fluttertoast.showToast(
                        msg: 'Help & Resources coming soon!',
                        backgroundColor: AppColors.primary,
                      );
                    },
                    isSelected: false,
                  ),
                ],
              ),
            ),

            // Bottom Section - Secondary Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                children: [
                  _buildDrawerItem(
                    icon: Icons.share_rounded,
                    title: 'Share App',
                    onTap: () => _shareApp(context),
                    isSelected: false,
                    isSecondary: true,
                  ),
                  _buildDrawerItem(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy / About',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AboutUs()),
                      );
                    },
                    isSelected: false,
                    isSecondary: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Share App functionality
  void _shareApp(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer first

    // APK download URL - You can replace this with your actual download URL
    const String apkDownloadUrl =
        'https://your-website.com/download/abhira.apk';

    // Show share options dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),

            // Title
            Text(
              'Share Abhira',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Help keep women safe by sharing our app',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),

            // Functional QR Code
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: QrImageView(
                  data: apkDownloadUrl,
                  version: QrVersions.auto,
                  size: 140,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  embeddedImage: AssetImage('assets/icons/abhira.png'),
                  embeddedImageStyle: QrEmbeddedImageStyle(
                    size: Size(24, 24),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Scan QR code to download',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),

            // Direct download link
            Text(
              'Direct Download',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final Uri uri = Uri.parse(apkDownloadUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                apkDownloadUrl,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 32),

            // Share buttons
            Row(
              children: [
                // Share via system
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Share.share(
                        '🚨 Keep women safe with Abhira! 🚨\n\n'
                        'Download the Abhira safety app - your personal emergency companion.\n\n'
                        'Features:\n'
                        '• One-tap SOS alerts to emergency contacts\n'
                        '• Shake-to-alert functionality\n'
                        '• AI-powered safety assistant\n'
                        '• Emergency services at your fingertips\n\n'
                        '📱 Download APK: $apkDownloadUrl\n\n'
                        '#WomenSafety #Abhira #StaySafe',
                        subject: 'Check out Abhira - Women Safety App',
                      );
                    },
                    icon: Icon(Icons.share_rounded),
                    label: Text('Share via...'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Copy link
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Copy link to clipboard
                      Clipboard.setData(ClipboardData(text: apkDownloadUrl));
                      Navigator.of(context).pop();
                      Fluttertoast.showToast(
                        msg: 'Download link copied!',
                        backgroundColor: Colors.green,
                      );
                    },
                    icon: Icon(Icons.copy_rounded),
                    label: Text('Copy Link'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    int? index,
    VoidCallback? onTap,
    required bool isSelected,
    bool isSecondary = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? AppColors.primary
            : isSecondary
                ? AppColors.textSecondary
                : AppColors.textPrimary,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTypography.body.copyWith(
          color: isSelected
              ? AppColors.primary
              : isSecondary
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap ??
          () {
            if (index != null) {
              setState(() {
                currentPage = index;
              });
            }
            Navigator.of(context).pop();
          },
    );
  }
}
