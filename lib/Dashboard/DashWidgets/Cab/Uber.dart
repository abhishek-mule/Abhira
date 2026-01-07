import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UberCard extends StatelessWidget {
  const UberCard({Key? key}) : super(key: key);

  _openUber() async {
    // Try to open Uber app directly, fallback to Play Store
    String appUrl = "uber://";
    String playStoreUrl = "market://details?id=com.ubercab";

    try {
      // Try to launch the app directly
      if (await canLaunch(appUrl)) {
        await launch(appUrl);
      } else {
        // Fallback to Play Store
        if (await canLaunch(playStoreUrl)) {
          await launch(playStoreUrl);
        }
      }
    } catch (e) {
      // Fallback to Play Store if direct launch fails
      if (await canLaunch(playStoreUrl)) {
        await launch(playStoreUrl);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: InkWell(
              onTap: () {
                _openUber();
              },
              child: Container(
                  height: 50,
                  width: 50,
                  child: Center(
                      child: Image.asset(
                    "assets/uber.png",
                    height: 32,
                  ))),
            ),
          ),
          Text("Uber")
        ],
      ),
    );
  }
}
