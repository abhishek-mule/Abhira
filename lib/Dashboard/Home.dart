import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:abhira/Dashboard/ContactScreens/MyContacts.dart';
import 'package:abhira/Dashboard/ContactScreens/phonebook_view.dart';
import 'package:abhira/Dashboard/AIAssistant/ai_assistant_screen.dart';
import 'package:abhira/Dashboard/DashWidgets/Emergency.dart';
import 'package:abhira/Dashboard/DashWidgets/OtherFeature.dart';
import 'package:abhira/Dashboard/DashWidgets/BookCab.dart';
import 'package:abhira/Dashboard/DashWidgets/LiveSafe.dart';
import 'package:abhira/Dashboard/DashWidgets/Scream.dart';
import 'package:abhira/Dashboard/DashWidgets/SafeHome.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'home_providers.dart';

/// Home screen refactored with proper architecture
class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle lifecycle changes for timers and services
    ref.read(homeControllerProvider.notifier).onLifecycleChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeControllerProvider);

    return Scaffold(
      body: Stack(
        key: ValueKey('home_stack'), // Add unique key to prevent conflicts
        children: [
          RefreshIndicator(
            key: ValueKey('home_refresh'), // Add unique key
            onRefresh: () =>
                ref.read(homeControllerProvider.notifier).refresh(),
            color: const Color(0xFFEF4444),
            child: ListView(
              key: ValueKey('home_listview'), // Add unique key
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 10),
                // Smart Context-Aware Header
                const SmartHeader(),
                const SizedBox(height: 20),
                // Scenario-Based Action Carousel
                const ScenarioCarousel(),
                const SizedBox(height: 24),
                // Emergency SOS
                const SOSButton(),
                const SizedBox(height: 20),
                _buildSectionHeader("Emergency Services"),
                const Emergency(),
                _buildSectionDivider(),
                _buildSectionHeader("Safety Features"),
                const OtherFeature(),
                _buildSectionDivider(),
                _buildSectionHeader("Get Home Safe"),
                const BookCab(),
                _buildSectionDivider(),
                _buildSectionHeader("Nearby Safety"),
                const LiveSafe(),
                _buildSectionDivider(),
                _buildSectionHeader("Personal Safety"),
                const Scream(),
                const SafeHome(),
                const SizedBox(height: 100), // Add extra space for the chatbot
              ],
            ),
          ),
          // Fixed chatbot in bottom-right corner
          Positioned(
            key: ValueKey('home_chatbot'), // Add unique key
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AIAssistantScreen()),
                );
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Lottie.asset(
                  'assets/lottie/aibot.json',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      height: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }
}

/// Smart context-aware header widget
class SmartHeader extends ConsumerWidget {
  const SmartHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextCards = ref.watch(contextCardsProvider);
    final currentIndex = ref.watch(headerRotationProvider);

    if (currentIndex >= contextCards.length) return const SizedBox.shrink();

    final card = contextCards[currentIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: card.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: card.color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (card.actionText == 'Add Now' || card.actionText == 'Add More') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyContactsScreen()),
              );
            } else {
              card.action();
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        card.urgency,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        card.icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  card.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              card.actionText,
                              style: TextStyle(
                                color: card.color,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: card.color,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scenario-based carousel widget
class ScenarioCarousel extends ConsumerWidget {
  const ScenarioCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarios = ref.watch(scenarioCardsProvider);
    final contactCount = ref.watch(contactCountProvider);

    final updatedScenarios = scenarios.map((scenario) {
      if (scenario.title.contains('Add Trusted Contacts')) {
        return scenario.copyWith(
          impact: '$contactCount contact${contactCount == 1 ? '' : 's'} added',
        );
      }
      return scenario;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Quick Safety Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: PageView.builder(
            itemCount: updatedScenarios.length,
            itemBuilder: (context, index) {
              return ScenarioCardWidget(scenario: updatedScenarios[index]);
            },
          ),
        ),
      ],
    );
  }
}

/// Individual scenario card widget
class ScenarioCardWidget extends StatelessWidget {
  const ScenarioCardWidget({super.key, required this.scenario});

  final ScenarioCard scenario;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scenario.color.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: scenario.color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            if (scenario.title == 'Add Trusted Contacts') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyContactsScreen()),
              );
            } else if (scenario.title == 'Ask AI for Help') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AIAssistantScreen()),
              );
            } else {
              scenario.action();
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      scenario.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: scenario.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: scenario.color,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  scenario.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  scenario.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: scenario.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    scenario.impact,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: scenario.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Emergency SOS button widget
class SOSButton extends ConsumerWidget {
  const SOSButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertState = ref.watch(sosAlertStateProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref
              .read(homeControllerProvider.notifier)
              .confirmActivateSOS(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                AvatarGlow(
                  glowColor: Colors.white,
                  duration: const Duration(milliseconds: 2000),
                  animate: alertState,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        alertState
                            ? Icons.stop_circle_rounded
                            : Icons.warning_rounded,
                        color: const Color(0xFFEF4444),
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alertState ? 'EMERGENCY ACTIVE' : 'EMERGENCY SOS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alertState
                            ? 'Siren playing • Tap to stop'
                            : 'Alert all contacts instantly',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
}

/// Quick actions grid widget
class QuickActionsGrid extends ConsumerWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: QuickActionButton(
              icon: Icons.people_rounded,
              label: 'Contacts',
              color: const Color(0xFF10B981),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyContactsScreen()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: QuickActionButton(
              icon: Icons.smart_toy_rounded,
              label: 'AI Guide',
              color: const Color(0xFF8B5CF6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AIAssistantScreen()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: QuickActionButton(
              icon: Icons.my_location_rounded,
              label: 'Share',
              color: const Color(0xFF6366F1),
              onTap: () =>
                  ref.read(homeControllerProvider.notifier).shareLiveLocation(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual quick action button
class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// TODO: Implement providers and controllers in separate files
// This is a placeholder structure - actual implementation will be in next steps
