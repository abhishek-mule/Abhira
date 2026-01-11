import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:permission_handler/permission_handler.dart';

class EmergencySlider extends StatefulWidget {
  final String emergencyNumber;
  final String label;

  const EmergencySlider({
    Key? key,
    required this.emergencyNumber,
    this.label = "Report to NCW Cell",
  }) : super(key: key);

  @override
  State<EmergencySlider> createState() => _EmergencySliderState();
}

class SwipeButtonDemo extends StatefulWidget {
  final String pageRoute;
  final String buttonTitle;

  const SwipeButtonDemo({
    Key? key,
    required this.pageRoute,
    required this.buttonTitle,
  }) : super(key: key);

  @override
  State<SwipeButtonDemo> createState() => _SwipeButtonDemoState();
}

class _EmergencySliderState extends State<EmergencySlider> {
  bool _coolingDown = false;

  Future<void> _triggerCall() async {
    if (_coolingDown) return;

    // haptic feedback
    HapticFeedback.mediumImpact();

    // permission check
    final status = await Permission.phone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone call permission denied")),
      );
      return;
    }

    // confirm intent
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Confirm Emergency Call",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text(
              "Call ${widget.emergencyNumber} now?",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Call"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _coolingDown = true);

    await FlutterPhoneDirectCaller.callNumber(widget.emergencyNumber);

    // cooldown to prevent repeat spam
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _coolingDown = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _coolingDown,
      child: Opacity(
        opacity: _coolingDown ? 0.6 : 1,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SlideAction(
            onSubmit: _triggerCall,
            innerColor: Colors.white,
            outerColor: Colors.red.shade700,
            text: _coolingDown ? "Please wait…" : widget.label,
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.043,
            ),
            sliderButtonIcon: const Icon(
              Icons.call,
              size: 44,
              color: Colors.white,
            ),
            submittedIcon: const Icon(Icons.check, color: Colors.white),
            sliderRotate: false,
          ),
        ),
      ),
    );
  }
}

class _SwipeButtonDemoState extends State<SwipeButtonDemo> {
  Future<void> _navigateToRoute() async {
    // haptic feedback
    HapticFeedback.mediumImpact();

    // Navigate to the specified route
    await Navigator.pushNamed(context, widget.pageRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SlideAction(
        onSubmit: _navigateToRoute,
        innerColor: Colors.white,
        outerColor: Colors.blue.shade700,
        text: widget.buttonTitle,
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: MediaQuery.of(context).size.width * 0.043,
        ),
        sliderButtonIcon: const Icon(
          Icons.arrow_forward,
          size: 44,
          color: Colors.white,
        ),
        submittedIcon: const Icon(Icons.check, color: Colors.white),
        sliderRotate: false,
      ),
    );
  }
}

