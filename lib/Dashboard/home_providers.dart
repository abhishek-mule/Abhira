import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abhira/services/evidence_service.dart';

/// Models
class SafetyContext {
  final IconData icon;
  final String urgency;
  final String title;
  final String subtitle;
  final Color color;
  final String actionText;
  final VoidCallback action;

  const SafetyContext({
    required this.icon,
    required this.urgency,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.actionText,
    required this.action,
  });
}

class ScenarioCard {
  final String emoji;
  final String title;
  final String subtitle;
  final String impact;
  final Color color;
  final VoidCallback action;

  const ScenarioCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.impact,
    required this.color,
    required this.action,
  });

  ScenarioCard copyWith({
    String? emoji,
    String? title,
    String? subtitle,
    String? impact,
    Color? color,
    VoidCallback? action,
  }) {
    return ScenarioCard(
      emoji: emoji ?? this.emoji,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      impact: impact ?? this.impact,
      color: color ?? this.color,
      action: action ?? this.action,
    );
  }
}

/// Services
class BatteryService {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _subscription;

  Future<int> getBatteryLevel() => _battery.batteryLevel;

  void startMonitoring(Function(int level) onLevelChange) async {
    _subscription?.cancel();
    final initialLevel = await getBatteryLevel();
    onLevelChange(initialLevel);

    _subscription = _battery.onBatteryStateChanged.listen((state) async {
      final level = await getBatteryLevel();
      onLevelChange(level);
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}

class LocationService {
  Future<Position?> getCurrentPosition() async {
    try {
      // Check location permissions first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }
  }

  Future<String> getLocationLink() async {
    final position = await getCurrentPosition();
    if (position == null) return 'Location unavailable';

    return "https://www.google.com/maps?q=${position.latitude},${position.longitude}";
  }
}

/// State Notifiers
class BatteryNotifier extends StateNotifier<int> {
  BatteryNotifier() : super(100);

  final BatteryService _service = BatteryService();

  void startMonitoring() {
    _service.startMonitoring((level) {
      state = level;
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

class ContactCountNotifier extends StateNotifier<int> {
  ContactCountNotifier() : super(0);

  Future<void> loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contacts = prefs.getStringList('numbers') ?? [];
      state = contacts.length;
    } catch (e) {
      debugPrint('Contact count error: $e');
    }
  }
}

class ContextRotationNotifier extends StateNotifier<int> {
  ContextRotationNotifier() : super(0);

  Timer? _timer;

  void startRotation(List<SafetyContext> contexts) {
    _timer?.cancel();
    // _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
    //   state = (state + 1) % contexts.length;
    // });
  }

  void pause() => _timer?.cancel();
  void resume() => startRotation([]);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class SOSStateNotifier extends StateNotifier<bool> {
  SOSStateNotifier() : super(false);

  final AudioPlayer _player = AudioPlayer();

  Future<void> toggleSOS() async {
    try {
      if (state) {
        await _player.stop();
        state = false;
        // Stop Evidence Collection
        await EvidenceService().stopRecording();
        
        Fluttertoast.showToast(
          msg: 'Emergency alert & recording stopped',
          backgroundColor: const Color(0xFF10B981),
        );
      } else {
        await _player.play(AssetSource('emergency.mp3'));
        state = true;
        // Start Evidence Collection
        await EvidenceService().startEmergencyRecording();

        Fluttertoast.showToast(
          msg: '🚨 EMERGENCY ALERT & RECORDING ACTIVE',
          backgroundColor: const Color(0xFFEF4444),
          toastLength: Toast.LENGTH_LONG,
        );
      }
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('⚠️ Siren error: $e');
      Fluttertoast.showToast(
        msg: 'Unable to play siren audio',
        backgroundColor: const Color(0xFFEF4444),
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

/// Providers
final batteryProvider = StateNotifierProvider<BatteryNotifier, int>((ref) {
  final notifier = BatteryNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

final contactCountProvider =
    StateNotifierProvider<ContactCountNotifier, int>((ref) {
  final notifier = ContactCountNotifier();
  notifier.loadContacts();
  return notifier;
});

final headerRotationProvider =
    StateNotifierProvider<ContextRotationNotifier, int>((ref) {
  final notifier = ContextRotationNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

final sosAlertStateProvider =
    StateNotifierProvider<SOSStateNotifier, bool>((ref) {
  final notifier = SOSStateNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

/// Computed providers
final contextCardsProvider = Provider<List<SafetyContext>>((ref) {
  final batteryLevel = ref.watch(batteryProvider);
  final contactCount = ref.watch(contactCountProvider);
  final isNight = DateTime.now().hour >= 20 || DateTime.now().hour < 6;

  final cards = <SafetyContext>[];

  // Night travel warning (priority if it's night)
  if (isNight) {
    cards.add(SafetyContext(
      icon: Icons.nights_stay_rounded,
      urgency: 'NIGHT ALERT',
      title: 'Share your location',
      subtitle:
          'Traveling at night? Let trusted contacts track you in real-time.',
      color: const Color(0xFF6366F1),
      actionText: 'Share Now',
      action: () =>
          ref.read(homeControllerProvider.notifier).shareLiveLocation(),
    ));
  }

  // Low battery warning (critical priority)
  if (batteryLevel <= 20) {
    cards.add(SafetyContext(
      icon: Icons.battery_alert_rounded,
      urgency: 'URGENT',
      title: 'Battery critically low',
      subtitle:
          'Emergency features need power. Charge now or enable battery saver.',
      color: const Color(0xFFEF4444),
      actionText: 'Power Tips',
      action: () => ref.read(homeControllerProvider.notifier).showBatteryTips(),
    ));
  }

  // Missing contacts warning (high priority)
  if (contactCount == 0) {
    cards.add(SafetyContext(
      icon: Icons.person_add_rounded,
      urgency: 'ACTION NEEDED',
      title: 'No trusted contacts yet',
      subtitle:
          'Add 3-5 people who can help in emergencies. Your safety network.',
      color: const Color(0xFFF59E0B),
      actionText: 'Add Now',
      action: () =>
          ref.read(homeControllerProvider.notifier).navigateToContacts(),
    ));
  } else if (contactCount < 3) {
    cards.add(SafetyContext(
      icon: Icons.group_add_rounded,
      urgency: 'RECOMMENDED',
      title: 'Build your safety circle',
      subtitle:
          'You have $contactCount contact${contactCount == 1 ? '' : 's'}. Add 2-3 more for better coverage.',
      color: const Color(0xFF10B981),
      actionText: 'Add More',
      action: () =>
          ref.read(homeControllerProvider.notifier).navigateToContacts(),
    ));
  }

  // Solo commute safety
  cards.add(SafetyContext(
    icon: Icons.directions_walk_rounded,
    urgency: 'SAFETY TIP',
    title: 'Walking alone?',
    subtitle:
        'Share your route, keep phone charged, and stay in well-lit areas.',
    color: const Color(0xFF8B5CF6),
    actionText: 'Safety Guide',
    action: () =>
        ref.read(homeControllerProvider.notifier).navigateToAIAssistant(),
  ));

  // Default: Emergency ready
  if (cards.isEmpty || cards.length < 2) {
    cards.add(SafetyContext(
      icon: Icons.shield_rounded,
      urgency: 'READY',
      title: 'Emergency system active',
      subtitle:
          'Shake 3x to alert contacts. Test it once so you know it works.',
      color: const Color(0xFF3B82F6),
      actionText: 'Test Now',
      action: () =>
          ref.read(homeControllerProvider.notifier).testEmergencyFeature(),
    ));
  }

  return cards;
});

final scenarioCardsProvider = Provider<List<ScenarioCard>>((ref) {
  final contactCount = ref.watch(contactCountProvider);

  return [
    ScenarioCard(
      emoji: '🚨',
      title: 'Test Emergency Alert',
      subtitle: 'Practice your shake-to-SOS',
      impact: 'Know it works when you need it',
      color: const Color(0xFFEF4444),
      action: () =>
          ref.read(homeControllerProvider.notifier).testEmergencyFeature(),
    ),
    ScenarioCard(
      emoji: '👥',
      title: 'Add Trusted Contacts',
      subtitle: 'Build your safety network',
      impact: '$contactCount contact${contactCount == 1 ? '' : 's'} added',
      color: const Color(0xFF10B981),
      action: () => debugPrint('Navigate to contacts'),
    ),
    ScenarioCard(
      emoji: '📍',
      title: 'Share Live Location',
      subtitle: 'Walking alone? Stay connected',
      impact: 'Real-time tracking for safety',
      color: const Color(0xFF6366F1),
      action: () =>
          ref.read(homeControllerProvider.notifier).shareLiveLocation(),
    ),
    ScenarioCard(
      emoji: '🤖',
      title: 'Ask AI for Help',
      subtitle: 'Get instant safety advice',
      impact: '24/7 intelligent assistance',
      color: const Color(0xFF8B5CF6),
      action: () => debugPrint('Navigate to AI assistant'),
    ),
    ScenarioCard(
      emoji: '📝',
      title: 'Report Incident',
      subtitle: 'Anonymous & confidential',
      impact: 'Help make streets safer',
      color: const Color(0xFFF59E0B),
      action: () => ref.read(homeControllerProvider.notifier).reportIncident(),
    ),
  ];
});

/// Controller provider
final homeControllerProvider =
    StateNotifierProvider<HomeController, void>((ref) {
  return HomeController(ref);
});

class HomeController extends StateNotifier<void> {
  HomeController(this.ref) : super(null) {
    _init();
  }

  final Ref ref;
  final LocationService _locationService = LocationService();

  void _init() {
    ref.read(batteryProvider.notifier).startMonitoring();
  }

  void onLifecycleChanged(AppLifecycleState state) {
    final rotationNotifier = ref.read(headerRotationProvider.notifier);
    if (state == AppLifecycleState.paused) {
      rotationNotifier.pause();
    } else if (state == AppLifecycleState.resumed) {
      rotationNotifier.resume();
    }
  }

  Future<void> refresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    await ref.read(contactCountProvider.notifier).loadContacts();
  }

  void testEmergencyFeature() {
    HapticFeedback.heavyImpact();
    // TODO: Show dialog - need context
    debugPrint('Test emergency feature');
  }

  Future<void> shareLiveLocation() async {
    HapticFeedback.mediumImpact();
    try {
      final link = await _locationService.getLocationLink();
      Fluttertoast.showToast(
        msg: '📍 Location ready to share: $link',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: const Color(0xFF6366F1),
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Enable location permissions to share',
        backgroundColor: const Color(0xFFEF4444),
      );
    }
  }

  void reportIncident() {
    HapticFeedback.lightImpact();
    Fluttertoast.showToast(
      msg: '📝 Anonymous incident reporting coming soon',
      backgroundColor: const Color(0xFFF59E0B),
    );
  }

  void showBatteryTips() {
    // TODO: Show dialog - need context
    debugPrint('Show battery tips');
  }

  void navigateToContacts() {
    // TODO: Navigation needs context - implement in widget
    debugPrint('Navigate to contacts');
  }

  void navigateToAIAssistant() {
    // TODO: Navigation needs context - implement in widget
    debugPrint('Navigate to AI assistant');
  }

  Future<void> confirmActivateSOS(BuildContext context) async {
    if (ref.read(sosAlertStateProvider)) {
      await ref.read(sosAlertStateProvider.notifier).toggleSOS();
    } else {
      final shouldActivate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFEF4444),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text('Activate SOS?', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'This will:\n• Play loud siren\n• Alert all contacts\n• Share your location\n\nUse only in real emergencies.',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFEF4444),
              ),
              child: const Text('Activate'),
            ),
          ],
        ),
      );

      if (shouldActivate == true) {
        await ref.read(sosAlertStateProvider.notifier).toggleSOS();
      }
    }
  }
}
