import 'dart:ui';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart';
import 'package:surveyor_pro/core/models/survey_point.dart';

class IntersectionUtils {
  
  /// Bearing-Bearing Intersection
  /// Given Point A and Bearing A->P, and Point B and Bearing B->P, find P.
  static Offset? bearingBearing(Offset p1, double az1Deg, Offset p2, double az2Deg) {
    // Convert azimuths to radians (math uses standard trig, survey uses North Azimuth)
    // Survey: 0 is North (Y axis), CW.
    // Math: 0 is East (X axis), CCW.
    // Math Angle = 90 - Azimuth
    
    double t1 = (90 - az1Deg) * pi / 180.0;
    double t2 = (90 - az2Deg) * pi / 180.0;
    
    double x1 = p1.dx, y1 = p1.dy;
    double x2 = p2.dx, y2 = p2.dy;
    
    // Slopes
    double m1 = tan(t1);
    double m2 = tan(t2);
    
    // Handle vertical lines (tan is infinite)
    if ((t1 - pi/2).abs() < 1e-9 || (t1 + pi/2).abs() < 1e-9) {
       // Line 1 is vertical (x = x1)
       // Intersection x = x1
       // y - y2 = m2 * (x - x2) => y = m2(x1 - x2) + y2
       return Offset(x1, m2 * (x1 - x2) + y2);
    }
    if ((t2 - pi/2).abs() < 1e-9 || (t2 + pi/2).abs() < 1e-9) {
       return Offset(x2, m1 * (x2 - x1) + y1);
    }
    
    if ((m1 - m2).abs() < 1e-9) return null; // Parallel
    
    // y - y1 = m1(x - x1) => y = m1x - m1x1 + y1
    // y - y2 = m2(x - x2) => y = m2x - m2x2 + y2
    // m1x - m1x1 + y1 = m2x - m2x2 + y2
    // x(m1 - m2) = m1x1 - y1 - m2x2 + y2
    
    double x = (m1 * x1 - m2 * x2 + y2 - y1) / (m1 - m2);
    double y = m1 * (x - x1) + y1;
    
    return Offset(x, y);
  }
  
  /// Distance-Distance Intersection
  /// Returns two possible points where circles intersect.
  static List<Offset> distanceDistance(Offset p1, double r1, Offset p2, double r2) {
    double d2 = (p1.dx - p2.dx)*(p1.dx - p2.dx) + (p1.dy - p2.dy)*(p1.dy - p2.dy);
    double d = sqrt(d2);
    
    if (d > r1 + r2 || d < (r1 - r2).abs() || d == 0) return []; // Separate or contained or coincident
    
    double a = (r1*r1 - r2*r2 + d2) / (2*d);
    double h = sqrt(r1*r1 - a*a);
    
    double x2 = p1.dx + a * (p2.dx - p1.dx) / d;
    double y2 = p1.dy + a * (p2.dy - p1.dy) / d;
    
    return [
      Offset(x2 + h * (p2.dy - p1.dy) / d, y2 - h * (p2.dx - p1.dx) / d),
      Offset(x2 - h * (p2.dy - p1.dy) / d, y2 + h * (p2.dx - p1.dx) / d),
    ];
  }
}
