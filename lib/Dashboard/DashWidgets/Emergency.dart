import 'package:flutter/material.dart';
import 'package:abhira/Dashboard/DashWidgets/Emergencies/AmbulanceEmergency.dart';
import 'package:abhira/Dashboard/DashWidgets/Emergencies/MetroEmergency.dart';
import 'package:abhira/Dashboard/DashWidgets/Emergencies/FirebrigadeEmergency.dart';
import 'package:abhira/Dashboard/DashWidgets/Emergencies/PoliceEmergency.dart';
import 'package:abhira/Dashboard/DashWidgets/Emergencies/WomenDistress.dart';

class Emergency extends StatelessWidget {
  const Emergency({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 200, // Increased height for better spacing
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // SOS (Women Distress) - Made more prominent
          Container(
            width: MediaQuery.of(context).size.width * 0.75, // Wider SOS card
            margin: const EdgeInsets.only(right: 12),
            child: const WomenDistress(),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.65,
            margin: const EdgeInsets.only(right: 12),
            child: const PoliceEmergency(),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.65,
            margin: const EdgeInsets.only(right: 12),
            child: const MetroEmergency(),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.65,
            margin: const EdgeInsets.only(right: 12),
            child: const AmbulanceEmergency(),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.65,
            child: const FireEmergency(),
          ),
        ],
      ),
    );
  }
}
