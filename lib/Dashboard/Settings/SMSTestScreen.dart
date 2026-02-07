import 'package:flutter/material.dart';
import 'package:abhira/services/sms_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Debug screen to test SMS functionality
class SMSTestScreen extends StatefulWidget {
  const SMSTestScreen({super.key});

  @override
  State<SMSTestScreen> createState() => _SMSTestScreenState();
}

class _SMSTestScreenState extends State<SMSTestScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController(
    text: "🚨 TEST: This is a test emergency message from Abhira app."
  );
  
  bool _isSending = false;
  String _status = "Ready to test SMS";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SMS Test"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "SMS Functionality Test",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: "Phone Number",
                hintText: "+919876543210 or 9876543210",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: "Test Message",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isSending ? null : _checkPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.all(16),
              ),
              child: Text("1. Check SMS Permissions"),
            ),
            SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isSending ? null : _testSMS,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.all(16),
              ),
              child: _isSending 
                ? CircularProgressIndicator(color: Colors.white)
                : Text("2. Send Test SMS"),
            ),
            SizedBox(height: 20),
            
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Status:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(_status),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            Text(
              "⚠️ Note: Check the terminal/logcat for detailed logs",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _status = "Checking SMS permissions...";
    });

    var status = await Permission.sms.status;
    
    if (status.isGranted) {
      setState(() {
        _status = "✅ SMS Permission: GRANTED";
      });
    } else if (status.isDenied) {
      setState(() {
        _status = "⚠️ SMS Permission: DENIED - Requesting...";
      });
      
      var result = await Permission.sms.request();
      
      if (result.isGranted) {
        setState(() {
          _status = "✅ SMS Permission: GRANTED (after request)";
        });
      } else {
        setState(() {
          _status = "❌ SMS Permission: DENIED by user";
        });
      }
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _status = "❌ SMS Permission: PERMANENTLY DENIED\nGo to Settings → Apps → Abhira → Permissions";
      });
    }
  }

  Future<void> _testSMS() async {
    if (_phoneController.text.isEmpty) {
      setState(() {
        _status = "❌ Please enter a phone number";
      });
      return;
    }

    setState(() {
      _isSending = true;
      _status = "📤 Sending test SMS...";
    });

    try {
      bool success = await SMSService().sendSOS(
        [_phoneController.text],
        _messageController.text,
        locationLink: "https://maps.google.com/?q=28.6139,77.2090",
        delayAfterWhatsApp: 0, // No delay for test
      );

      setState(() {
        _isSending = false;
        if (success) {
          _status = "✅ SMS sent successfully!\nCheck your phone and terminal logs.";
        } else {
          _status = "⚠️ SMS sending failed.\nCheck terminal logs for details.";
        }
      });
    } catch (e) {
      setState(() {
        _isSending = false;
        _status = "❌ Error: $e";
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
