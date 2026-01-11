import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:abhira/Dashboard/ContactScreens/MyContacts.dart';
import 'package:abhira/Dashboard/AIAssistant/ai_assistant_screen.dart';
import 'package:abhira/Dashboard/Settings/SettingsScreen.dart';
import 'package:abhira/Dashboard/Articles%20-%20SafeCarousel/ArticleDesc.dart';
import 'package:abhira/Dashboard/Articles%20-%20SafeCarousel/SadeWebView.dart';
import 'package:abhira/constants.dart';

class AllArticles extends StatelessWidget {
  const AllArticles({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Features',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Emergency Services Section
            _buildSectionHeader('🚨 Emergency Services', Colors.red),
            _buildFeatureCard(
              context,
              'Women Distress Helpline',
              'Call 1091 for immediate help',
              Icons.phone,
              Colors.red,
              () => _makeCall('1091'),
            ),
            _buildFeatureCard(
              context,
              'Police Emergency',
              'Call 100 for police assistance',
              Icons.local_police,
              Colors.blue,
              () => _makeCall('100'),
            ),
            _buildFeatureCard(
              context,
              'Ambulance Service',
              'Call 102 for medical emergency',
              Icons.local_hospital,
              Colors.green,
              () => _makeCall('102'),
            ),
            _buildFeatureCard(
              context,
              'Fire Brigade',
              'Call 101 for fire emergency',
              Icons.fire_truck,
              Colors.orange,
              () => _makeCall('101'),
            ),

            const SizedBox(height: 24),

            // Safety Features Section
            _buildSectionHeader('🛡️ Safety Features', Colors.purple),
            _buildFeatureCard(
              context,
              'SOS Alert System',
              'One shake sends emergency alerts',
              Icons.warning,
              Colors.red,
              () => _showInfo(context, 'Shake Detection',
                  'Shake your phone 3 times to trigger SOS alerts to your emergency contacts.'),
            ),
            _buildFeatureCard(
              context,
              'Emergency Contacts',
              'Manage your safety network',
              Icons.contacts,
              Colors.blue,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => MyContactsScreen())),
            ),
            _buildFeatureCard(
              context,
              'AI Safety Assistant',
              '24/7 intelligent safety guidance',
              Icons.smart_toy,
              Colors.purple,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AIAssistantScreen())),
            ),
            _buildFeatureCard(
              context,
              'Fake Call Service',
              'Get out of uncomfortable situations',
              Icons.call,
              Colors.teal,
              () => _showInfo(context, 'Fake Call',
                  'Schedule a fake incoming call to help you exit uncomfortable situations safely.'),
            ),

            const SizedBox(height: 24),

            // Transportation Section
            _buildSectionHeader('🚗 Transportation', Colors.indigo),
            _buildFeatureCard(
              context,
              'Book Cab Safely',
              'Verified cab booking services',
              Icons.directions_car,
              Colors.indigo,
              () => _showInfo(context, 'Cab Booking',
                  'Book verified cabs through Ola, Uber, and Rapido for safe travel.'),
            ),

            const SizedBox(height: 24),

            // Live Safe Spots Section
            _buildSectionHeader('🏥 Live Safe Spots', Colors.cyan),
            _buildFeatureCard(
              context,
              'Nearby Hospitals',
              'Find medical facilities quickly',
              Icons.local_hospital,
              Colors.cyan,
              () => _showInfo(context, 'Hospitals',
                  'Locate nearby hospitals and medical centers for emergency care.'),
            ),
            _buildFeatureCard(
              context,
              'Police Stations',
              'Find law enforcement nearby',
              Icons.local_police,
              Colors.blue,
              () => _showInfo(context, 'Police Stations',
                  'Locate nearby police stations for immediate assistance.'),
            ),
            _buildFeatureCard(
              context,
              'Pharmacies',
              'Find medical stores',
              Icons.local_pharmacy,
              Colors.green,
              () => _showInfo(context, 'Pharmacies',
                  'Locate nearby pharmacies for medical supplies.'),
            ),

            const SizedBox(height: 24),

            // Articles Section
            _buildSectionHeader('📚 Safety Articles', Colors.amber),
            ..._buildArticlesSection(context),

            const SizedBox(height: 24),

            // Settings & More Section
            _buildSectionHeader('⚙️ Settings & More', Colors.grey),
            _buildFeatureCard(
              context,
              'App Settings',
              'Customize your safety preferences',
              Icons.settings,
              Colors.grey,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SettingsScreen())),
            ),
            _buildFeatureCard(
              context,
              'Report Incident',
              'Anonymous incident reporting',
              Icons.report,
              Colors.orange,
              () => _showInfo(context, 'Incident Reporting',
                  'Swipe the button on home screen to report incidents anonymously.'),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _openArticle(BuildContext context, int index) {
    switch (index) {
      case 0:
        navigateToRoute(
          context,
          SafeWebView(
            index: index,
            title: "Indian women inspiring the nation",
            url:
                "https://www.seniority.in/blog/10-women-who-changed-the-face-of-india-with-their-achievements/",
          ),
        );
        break;
      case 1:
        navigateToRoute(
          context,
          SafeWebView(
            index: index,
            title: "We have to end violence",
            url:
                "https://plan-international.org/ending-violence/16-ways-end-violence-girls",
          ),
        );
        break;
      case 2:
        navigateToRoute(context, ArticleDesc(index: index));
        break;
      default:
        navigateToRoute(
          context,
          SafeWebView(
            index: index,
            title: "You are strong",
            url:
                "https://www.healthline.com/health/womens-health/self-defense-tips-escape",
          ),
        );
    }
  }

  void navigateToRoute(BuildContext context, Widget route) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => route),
    );
  }

  // Helper method to build section headers
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: color.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build feature cards
  Widget _buildFeatureCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build articles section
  List<Widget> _buildArticlesSection(BuildContext context) {
    List<Widget> articles = [];
    for (int i = 0; i < articleTitle.length; i++) {
      articles.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _openArticle(context, i),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.article,
                      color: Colors.amber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          articleTitle[i],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap to read the full article',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.amber,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return articles;
  }

  // Helper method to make phone calls
  void _makeCall(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error making call: $e');
    }
  }

  // Helper method to show info dialogs
  void _showInfo(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
