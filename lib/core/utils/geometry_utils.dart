import 'dart:math';
import 'package:vector_math/vector_math_64.dart';
import 'package:surveyor_pro/core/models/survey_point.dart'; 
// strictly speaking we just need coordinates.

class GeometryUtils {
  
  /// Calculates the area of a 2D polygon using the Shoelace Formula.
  /// Returns area in square meters (assuming input coordinates are in meters).
  static double calculatePolygonArea(List<Vector2> points) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    int j = points.length - 1; // The last vertex is the 'previous' one to the first

    for (int i = 0; i < points.length; i++) {
      area += (points[j].x + points[i].x) * (points[j].y - points[i].y);
      j = i; // j is previous vertex to i
    }

    return (area / 2.0).abs();
  }

  /// Converts square meters to acres
  static double sqMetersToAcres(double sqMeters) {
    return sqMeters * 0.000247105;
  }
  
  /// Converts square meters to square feet
  static double sqMetersToSqFeet(double sqMeters) {
    return sqMeters * 10.7639;
  }
}
