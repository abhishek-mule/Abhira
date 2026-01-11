import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abhira/Dashboard/Settings/About.dart';
import 'package:abhira/Dashboard/Settings/ChangePin.dart';
import 'package:abhira/Dashboard/Settings/ShareAppScreen.dart';
import 'package:abhira/background_services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool switchValue = false;
  bool whatsappSwitchValue = false;
  Future<int> checkPIN() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int pin = (prefs.getInt('pin') ?? -1111);
    print('User $pin .');
    return pin;
  }

  @override
  void initState() {
    super.initState();
    checkService();
    checkWhatsAppSetting();
  }

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
            }),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Text(
              "Settings",
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.w900),
            ),
          ),
          FutureBuilder(
              future: checkPIN(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChangePinScreen(pin: snapshot.data),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: Center(
                        child: Image.asset("assets/pin.png"),
                      ),
                    ),
                    title: Text(snapshot.data == -1111
                        ? "Create SOS pin"
                        : "Change SOS pin"),
                    subtitle:
                        Text("SOS PIN is required to switch OFF the SOS alert"),
                    trailing: CircleAvatar(
                      radius: 7,
                      backgroundColor:
                          snapshot.data == -1111 ? Colors.red : Colors.white,
                      child: Center(
                        child: Card(
                            color: snapshot.data == -1111
                                ? Colors.orange
                                : Colors.white,
                            shape: CircleBorder(),
                            child: SizedBox(
                              height: 5,
                              width: 5,
                            )),
                      ),
                    ),
                  );
                } else {
                  return SizedBox();
                }
              }),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Notifications",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Expanded(child: Divider())
            ],
          ),
          SwitchListTile(
            onChanged: (val) {
              setState(() {
                switchValue = val;
                controllSafeShake(val);
              });
            },
            value: switchValue,
            secondary: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Center(
                  child: Image.asset(
                "assets/shake.png",
                height: 24,
              )),
            ),
            title: Text("Safe Shake"),
            subtitle: Text("Switch ON to listen for device shake"),
          ),
          Divider(
            indent: 40,
            endIndent: 40,
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Text(
              "Safe Shake is the key feature for the app. It can be turned on to silently listens for the device shake. When the user feels uncomfortable or finds herself in a situation where sending SOS is the most viable descision. Then She can shake her phone rapidly to send SOS alert to specified contacts without opening the app.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "WhatsApp Sharing",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Expanded(child: Divider())
            ],
          ),
          SwitchListTile(
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('whatsapp_share_enabled', val);
              setState(() {
                whatsappSwitchValue = val;
              });
            },
            value: whatsappSwitchValue,
            secondary: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Center(
                  child: Image.asset(
                "assets/share.png",
                height: 24,
              )),
            ),
            title: Text("Share on WhatsApp"),
            subtitle: Text("Share location via WhatsApp when shake detected"),
          ),
          Divider(
            indent: 40,
            endIndent: 40,
          ),
          SwitchListTile(
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('shake_notifications_enabled', val);
              setState(() {
                // Update state if needed
              });
            },
            value: true, // Default to enabled
            secondary: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Center(
                  child: Icon(
                Icons.notifications_rounded,
                color: Color(0xFF10B981),
                size: 24,
              )),
            ),
            title: Text("Shake Notifications"),
            subtitle: Text("Show toast notifications when shake is detected"),
          ),
          Divider(
            indent: 40,
            endIndent: 40,
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Text(
              "When enabled, the app will automatically share your location via WhatsApp with your SOS contacts when shake is detected. This provides an additional safety measure for emergencies.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Application",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Expanded(child: Divider())
            ],
          ),
          ListTile(
            onTap: () {
              _showEditSOSMessageDialog(context);
            },
            title: Text("Edit SOS Message"),
            subtitle: Text("Customize the emergency message sent via WhatsApp"),
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Center(
                  child: Icon(
                Icons.message_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              )),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          Divider(
            indent: 40,
            endIndent: 40,
          ),
          ListTile(
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => AboutUs()));
            },
            title: Text("About Us"),
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Center(
                  child: Image.asset(
                "assets/info.png",
                height: 24,
              )),
            ),
          ),
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShareAppScreen(),
                ),
              );
            },
            title: Text("Share App"),
            subtitle: Text("Share Abhira with QR code and download link"),
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Center(
                  child: Image.asset(
                "assets/share.png",
                height: 24,
              )),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }

  Future<bool> checkService() async {
    final service = FlutterBackgroundService();
    bool running = await service.isRunning();
    setState(() {
      switchValue = running;
    });
    return running;
  }

  Future<void> checkWhatsAppSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      whatsappSwitchValue = prefs.getBool('whatsapp_share_enabled') ?? false;
    });
  }

  void controllSafeShake(bool val) async {
    final service = FlutterBackgroundService();
    if (val) {
      service.startService();
    } else {
      // Stop the service using invoke
      service.invoke("stopService", {"action": "stopService"});
    }
  }

  void _showEditSOSMessageDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final currentMessage = prefs.getString('custom_sos_message') ??
        "🚨 EMERGENCY SOS ALERT 🚨\n\nI need immediate help! Please check my location:\n\n{LOCATION}\n\nThis is an automated emergency message from my safety app.";

    final TextEditingController messageController =
        TextEditingController(text: currentMessage);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.message_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 12),
              Text('Edit SOS Message'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize the emergency message sent via WhatsApp. Use {LOCATION} as a placeholder for the Google Maps link.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Enter your custom SOS message...',
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Preview: {LOCATION} will be replaced with actual Google Maps link',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final message = messageController.text.trim();
                if (message.isNotEmpty) {
                  await prefs.setString('custom_sos_message', message);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('SOS message updated successfully!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
