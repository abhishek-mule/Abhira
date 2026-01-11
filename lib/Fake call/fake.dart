import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:audioplayers/audioplayers.dart';

class Fake extends StatefulWidget {
  const Fake({super.key});

  @override
  _FakeState createState() => _FakeState();
}

class _FakeState extends State<Fake> {
  final _nameController = TextEditingController(text: 'Mom');
  final _numberController = TextEditingController(text: '+1 234 567 8900');
  Timer? _delayTimer;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _delayTimer?.cancel();
    super.dispose();
  }

  /// Show incoming call immediately
  void _showIncomingCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FakeCallScreen(
          callerName: _nameController.text.trim().isEmpty
              ? 'Unknown'
              : _nameController.text,
          callerNumber: _numberController.text.trim().isEmpty
              ? 'Unknown Number'
              : _numberController.text,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  /// Show incoming call with delay
  void _showDelayedCall(int seconds) {
    Fluttertoast.showToast(
      msg: "Incoming call in $seconds seconds...",
      backgroundColor: Colors.blue,
    );

    _delayTimer?.cancel();
    _delayTimer = Timer(Duration(seconds: seconds), () {
      if (mounted) {
        _showIncomingCall();
      }
    });
  }

  /// Show settings dialog
  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customize Caller'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Caller Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
              Fluttertoast.showToast(
                msg: "Caller info updated",
                backgroundColor: Colors.green,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Fake Call",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/bg-top.png'),
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            colorFilter: ColorFilter.mode(
              Colors.grey.shade50.withOpacity(0.3),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Caller Info Preview
              _buildCallerPreview(),

              const SizedBox(height: 40),

              // Call Buttons
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(15),
                  children: [
                    _buildCallButton(
                      "Incoming call now",
                      Icons.phone_in_talk,
                      _showIncomingCall,
                    ),
                    const SizedBox(height: 16),
                    _buildCallButton(
                      "Incoming call in 5 seconds",
                      Icons.timer,
                          () => _showDelayedCall(5),
                    ),
                    const SizedBox(height: 16),
                    _buildCallButton(
                      "Incoming call in 10 seconds",
                      Icons.timer,
                          () => _showDelayedCall(10),
                    ),
                    const SizedBox(height: 16),
                    _buildCallButton(
                      "Incoming call in 30 seconds",
                      Icons.timer,
                          () => _showDelayedCall(30),
                    ),
                    const SizedBox(height: 32),

                    // Info Card
                    _buildInfoCard(),
                  ],
                ),
              ),

              // Bottom Image
              Image.asset(
                "assets/bk_women.png",
                height: MediaQuery.of(context).size.height / 6,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallerPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _nameController.text.isEmpty ? 'Unknown' : _nameController.text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _numberController.text.isEmpty
                ? 'No Number'
                : _numberController.text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFD8080),
              Color(0xFFFB8580),
              Color(0xFFFBD079),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFD8080).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'How to use',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Tap settings icon to customize caller info\n'
                '• Choose when you want to receive the call\n'
                '• Use this feature to safely exit uncomfortable situations\n'
                '• The call will appear realistic on your screen',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Fake Call Screen
class FakeCallScreen extends StatefulWidget {
  final String callerName;
  final String callerNumber;

  const FakeCallScreen({
    super.key,
    required this.callerName,
    required this.callerNumber,
  });

  @override
  _FakeCallScreenState createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  final _player = AudioPlayer();
  bool _isRinging = true;
  bool _isCallActive = false;
  Timer? _callTimer;
  int _callDuration = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _playRingtone();
  }

  void _playRingtone() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      // Using a default sound - you can replace with your ringtone
      await _player.play(AssetSource('emergency.mp3'), volume: 0.5);
    } catch (e) {
      debugPrint('Ringtone error: $e');
    }
  }

  void _answerCall() async {
    await _player.stop();
    setState(() {
      _isRinging = false;
      _isCallActive = true;
    });

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callDuration++);
      }
    });

    Fluttertoast.showToast(
      msg: "Call connected",
      backgroundColor: Colors.green,
    );
  }

  void _endCall() async {
    await _player.stop();
    _callTimer?.cancel();
    Navigator.pop(context);

    Fluttertoast.showToast(
      msg: "Call ended",
      backgroundColor: Colors.grey,
    );
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade900,
              Colors.black,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Status
              Text(
                _isCallActive ? 'Connected' : 'Incoming Call...',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 40),

              // Caller Avatar with pulse animation
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: _isRinging
                          ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(
                            0.3 * _pulseController.value,
                          ),
                          blurRadius: 40 * _pulseController.value,
                          spreadRadius: 20 * _pulseController.value,
                        ),
                      ]
                          : [],
                    ),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.blue.shade700,
                      child: Text(
                        widget.callerName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Caller Name
              Text(
                widget.callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Caller Number or Duration
              Text(
                _isCallActive
                    ? _formatDuration(_callDuration)
                    : widget.callerNumber,
                style: TextStyle(
                  color: _isCallActive ? Colors.green : Colors.white70,
                  fontSize: 18,
                ),
              ),

              const Spacer(),

              // Action Buttons
              if (_isRinging) _buildRingingButtons(),
              if (_isCallActive) _buildActiveCallButtons(),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRingingButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Decline Button
        _buildCallActionButton(
          icon: Icons.call_end,
          color: Colors.red,
          label: 'Decline',
          onTap: _endCall,
        ),

        // Answer Button
        _buildCallActionButton(
          icon: Icons.call,
          color: Colors.green,
          label: 'Answer',
          onTap: _answerCall,
        ),
      ],
    );
  }

  Widget _buildActiveCallButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSmallButton(Icons.mic_off, 'Mute'),
            _buildSmallButton(Icons.dialpad, 'Keypad'),
            _buildSmallButton(Icons.volume_up, 'Speaker'),
          ],
        ),
        const SizedBox(height: 40),
        _buildCallActionButton(
          icon: Icons.call_end,
          color: Colors.red,
          label: 'End Call',
          onTap: _endCall,
        ),
      ],
    );
  }

  Widget _buildCallActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _player.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

}
