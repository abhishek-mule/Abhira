import 'package:flutter/material.dart';
import 'package:abhira/Dashboard/DashWidgets/OtherFeatures/CameraDetection.dart';
import 'package:abhira/Dashboard/DashWidgets/OtherFeatures/FakeCall.dart';

import 'package:abhira/Dashboard/DashWidgets/OtherFeatures/SelfDefence.dart';

class OtherFeature extends StatelessWidget {
  const OtherFeature({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 180,
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.65,
            margin: const EdgeInsets.only(right: 12),
            child: const FakeCall(),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.65,
            margin: const EdgeInsets.only(right: 12),
            child: const CameraDetection(),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.65,
            child: const Defence(),
          ),
        ],
      ),
    );
  }
}
