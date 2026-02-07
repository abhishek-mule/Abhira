import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SafetyHeatmapService {
  // Generate dummy heatmap data (circles) around a location
  static Set<Circle> generateHeatmap(LatLng center) {
    Set<Circle> circles = {};
    final Random random = Random();

    // Create 100 random points around the center
    for (int i = 0; i < 50; i++) {
      // Random offset within ~2km
      double latOffset = (random.nextDouble() - 0.5) * 0.04;
      double lngOffset = (random.nextDouble() - 0.5) * 0.04;
      
      LatLng pos = LatLng(center.latitude + latOffset, center.longitude + lngOffset);
      
      // Determine safety level (random for demo)
      // 0-3: Danger (Red), 4-6: Caution (Yellow), 7-10: Safe (Green)
      int safetyScore = random.nextInt(10);
      Color color;
      if (safetyScore < 4) {
        color = Colors.red.withOpacity(0.3);
      } else if (safetyScore < 7) {
        color = Colors.amber.withOpacity(0.3);
      } else {
        color = Colors.green.withOpacity(0.3);
      }

      circles.add(
        Circle(
          circleId: CircleId('safety_zone_$i'),
          center: pos,
          radius: 200 + random.nextInt(300).toDouble(), // 200-500m radius
          fillColor: color,
          strokeWidth: 0,
        ),
      );
    }
    return circles;
  }
}
