import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareAppScreen extends StatelessWidget {
  // APK download URL - Replace with your actual hosting URL
  // For now, using a placeholder that can be updated to a real download link
  static const String apkDownloadUrl =
      'https://abhira-3ff53.web.app/download-apk'; // Update this with your actual APK URL

  // Share app text
  static const String shareMessage =
      'Join Abhira - Women Safety App! Download now and stay safe. Features include emergency alerts, location tracking, and AI-powered safety assistance.\n\nDownload: https://abhira-3ff53.web.app/download-apk';

  const ShareAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFCFE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Share Abhira',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Text(
                'Share Abhira with Friends',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Help women stay safe by sharing this app',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              // QR Code Section
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color(0xFFEF4444),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                  color: Colors.white,
                ),
                padding: EdgeInsets.all(20),
                child: QrImageView(
                  data: apkDownloadUrl,
                  size: 280.0,
                  backgroundColor: Colors.white,
                  version: QrVersions.auto,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Scan this QR code to download Abhira',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _shareViaShareSheet(context);
                  },
                  icon: Icon(Icons.share_rounded, size: 22),
                  label: Text(
                    'Share via WhatsApp/Message',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _openDownloadLink(context);
                  },
                  icon: Icon(Icons.download_rounded, size: 22),
                  label: Text(
                    'Download APK Directly',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Color(0xFFEF4444),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
              // App Features
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why Abhira?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildFeatureItem(
                      Icons.emergency_rounded,
                      'Emergency Alerts',
                      'Quick SOS with shake detection',
                    ),
                    SizedBox(height: 12),
                    _buildFeatureItem(
                      Icons.location_on_rounded,
                      'Location Tracking',
                      'Real-time location sharing',
                    ),
                    SizedBox(height: 12),
                    _buildFeatureItem(
                      Icons.smart_toy_rounded,
                      'AI Assistant',
                      'Safety advice powered by Gemini AI',
                    ),
                    SizedBox(height: 12),
                    _buildFeatureItem(
                      Icons.people_rounded,
                      'Emergency Contacts',
                      'Add and manage trusted contacts',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _shareViaShareSheet(BuildContext context) {
    Share.share(
      shareMessage,
      subject: 'Download Abhira - Women Safety App',
    );
  }

  void _openDownloadLink(BuildContext context) async {
    try {
      if (await canLaunchUrl(Uri.parse(apkDownloadUrl))) {
        await launchUrl(
          Uri.parse(apkDownloadUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open download link'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }
}
