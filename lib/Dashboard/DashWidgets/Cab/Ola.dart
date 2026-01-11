import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OlaCard extends StatelessWidget {
  const OlaCard({Key? key}) : super(key: key);

  _openOla() async {
    // Try to open Ola app directly, fallback to Play Store
    String appUrl = "ola://";
    String playStoreUrl =
        "https://play.google.com/store/apps/details?id=com.olacabs.customer&gl=US";

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
                _openOla();
                // Navigator.of(context).push(MaterialPageRoute(builder: (context) => Detection()));
              },
              child: Container(
                  height: 50,
                  width: 50,
                  child: Center(
                      child: Image.asset(
                    "assets/ola.png",
                    height: 32,
                  ))),
            ),
          ),
          Text("Ola")
        ],
      ),
    );
  }
}

