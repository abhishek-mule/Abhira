import 'package:flutter/material.dart';

class HeatmapCard extends StatelessWidget {
  final VoidCallback onTap;

  const HeatmapCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: InkWell(
              onTap: onTap,
              child: Container(
                  height: 50,
                  width: 50,
                  child: Center(
                      child: Icon(Icons.map_rounded,
                          size: 32, color: Colors.blueAccent))),
            ),
          ),
          const SizedBox(height: 5), // Added SizedBox for consistency
          const Text("Heatmap")
        ],
      ),
    );
  }
}
