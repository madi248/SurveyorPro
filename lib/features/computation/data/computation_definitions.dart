import 'dart:math';
import 'package:flutter/material.dart';
import '../domain/computation_types.dart';

// --- Math Helpers ---
double toRad(double deg) => (deg * pi) / 180;
double toDeg(double rad) => (rad * 180) / pi;

// --- Calculation Definitions ---

final Map<String, CalcDefinition> calcDefs = {
  // --- COGO ---
  'cogo_forward': CalcDefinition(
    title: 'Forward (Direct)',
    inputs: [
      const CalcInputDef(key: 'n', label: 'Start Northing', type: 'number'),
      const CalcInputDef(key: 'e', label: 'Start Easting', type: 'number'),
      const CalcInputDef(key: 'az', label: 'Azimuth (Deg)', type: 'number'),
      const CalcInputDef(key: 'dist', label: 'Distance', type: 'number'),
    ],
    calculate: (v) {
      final n = double.tryParse(v['n'] ?? '');
      final e = double.tryParse(v['e'] ?? '');
      final az = double.tryParse(v['az'] ?? '');
      final d = double.tryParse(v['dist'] ?? '');
      
      if (n == null || e == null || az == null || d == null) return {};

      final rad = toRad(az);
      return {
        'New Northing': (n + d * cos(rad)).toStringAsFixed(3),
        'New Easting': (e + d * sin(rad)).toStringAsFixed(3),
      };
    },
    outputOrder: ['New Northing', 'New Easting'],
  ),

  'cogo_radiation': CalcDefinition(
    title: 'Radiation',
    inputs: [
      const CalcInputDef(key: 'n', label: 'Station Northing', type: 'number'),
      const CalcInputDef(key: 'e', label: 'Station Easting', type: 'number'),
      const CalcInputDef(key: 'az', label: 'Azimuth (Deg)', type: 'number'),
      const CalcInputDef(key: 'dist', label: 'Distance', type: 'number'),
    ],
    calculate: (v) {
      final n = double.tryParse(v['n'] ?? '');
      final e = double.tryParse(v['e'] ?? '');
      final az = double.tryParse(v['az'] ?? '');
      final d = double.tryParse(v['dist'] ?? '');

      if (n == null || e == null || az == null || d == null) return {};

      final rad = toRad(az);
      return {
        'Point Northing': (n + d * cos(rad)).toStringAsFixed(3),
        'Point Easting': (e + d * sin(rad)).toStringAsFixed(3),
      };
    },
    outputOrder: ['Point Northing', 'Point Easting'],
  ),

  'cogo_offset': CalcDefinition(
    title: 'Station & Offset',
    inputs: [
      const CalcInputDef(key: 'n1', label: 'Line Start N', type: 'number'),
      const CalcInputDef(key: 'e1', label: 'Line Start E', type: 'number'),
      const CalcInputDef(key: 'n2', label: 'Line End N', type: 'number'),
      const CalcInputDef(key: 'e2', label: 'Line End E', type: 'number'),
      const CalcInputDef(key: 'station', label: 'Station (Dist along)', type: 'number'),
      const CalcInputDef(key: 'offset', label: 'Offset (+Right/-Left)', type: 'number'),
    ],
    calculate: (v) {
      final n1 = double.tryParse(v['n1'] ?? '');
      final e1 = double.tryParse(v['e1'] ?? '');
      final n2 = double.tryParse(v['n2'] ?? '');
      final e2 = double.tryParse(v['e2'] ?? '');
      final sta = double.tryParse(v['station'] ?? '');
      final off = double.tryParse(v['offset'] ?? '');

      if (n1 == null || e1 == null || n2 == null || e2 == null || sta == null || off == null) return {};

      final dN = n2 - n1;
      final dE = e2 - e1;
      final az = atan2(dE, dN);

      final nOnLine = n1 + sta * cos(az);
      final eOnLine = e1 + sta * sin(az);

      final azPerp = az + pi / 2;

      return {
        'Computed N': (nOnLine + off * cos(azPerp)).toStringAsFixed(3),
        'Computed E': (eOnLine + off * sin(azPerp)).toStringAsFixed(3),
      };
    },
    outputOrder: ['Computed N', 'Computed E'],
  ),

  // --- Leveling ---
  'level_trig': CalcDefinition(
    title: 'Trigonometric Leveling',
    inputs: [
      const CalcInputDef(key: 'elev', label: 'Station Elevation', type: 'number'),
      const CalcInputDef(key: 'hi', label: 'Instrument Height (HI)', type: 'number'),
      const CalcInputDef(key: 'va', label: 'Vertical Angle (Zenith: 0=Up)', type: 'number', defaultValue: '90'),
      const CalcInputDef(key: 'sd', label: 'Slope Distance', type: 'number'),
      const CalcInputDef(key: 'ht', label: 'Target Height (HT)', type: 'number'),
    ],
    calculate: (v) {
      final elev = double.tryParse(v['elev'] ?? '');
      final hi = double.tryParse(v['hi'] ?? '');
      final va = double.tryParse(v['va'] ?? '');
      final sd = double.tryParse(v['sd'] ?? '');
      final ht = double.tryParse(v['ht'] ?? '');

      if (elev == null || hi == null || va == null || sd == null || ht == null) return {};

      final vaRad = toRad(90 - va);
      final vertComp = sd * sin(vaRad);

      return {
        'Target Elevation': (elev + hi + vertComp - ht).toStringAsFixed(3),
        'Vertical Diff': vertComp.toStringAsFixed(3),
      };
    },
    outputOrder: ['Target Elevation', 'Vertical Diff'],
  ),

  'level_two_peg': CalcDefinition(
    title: 'Two Peg Test',
    inputs: [
      const CalcInputDef(key: 'a1', label: 'Reading A (Inst @ Mid)', type: 'number'),
      const CalcInputDef(key: 'b1', label: 'Reading B (Inst @ Mid)', type: 'number'),
      const CalcInputDef(key: 'a2', label: 'Reading A (Inst @ A)', type: 'number'),
      const CalcInputDef(key: 'b2', label: 'Reading B (Inst @ A)', type: 'number'),
      const CalcInputDef(key: 'dist', label: 'Distance A to B', type: 'number'),
    ],
    calculate: (v) {
      final a1 = double.tryParse(v['a1'] ?? '');
      final b1 = double.tryParse(v['b1'] ?? '');
      final a2 = double.tryParse(v['a2'] ?? '');
      final b2 = double.tryParse(v['b2'] ?? '');
      final d = double.tryParse(v['dist'] ?? '');

      if (a1 == null || b1 == null || a2 == null || b2 == null || d == null) return {};

      final trueDiff = a1 - b1;
      final apparentDiff = a2 - b2;
      final error = apparentDiff - trueDiff;
      final collimationError = atan(error / d) * (180 / pi) * 3600;

      return {
        'True Diff': trueDiff.toStringAsFixed(3),
        'Apparent Diff': apparentDiff.toStringAsFixed(3),
        'Error per Dist': error.toStringAsFixed(4),
        'Collimation Err (Sec)': collimationError.toStringAsFixed(1),
      };
    },
    outputOrder: ['True Diff', 'Apparent Diff', 'Collimation Err (Sec)'],
  ),

  // --- Intersections ---
  'int_brg_brg': CalcDefinition(
    title: 'Bearing - Bearing',
    inputs: [
      const CalcInputDef(key: 'n1', label: 'Pt 1 Northing', type: 'number'),
      const CalcInputDef(key: 'e1', label: 'Pt 1 Easting', type: 'number'),
      const CalcInputDef(key: 'az1', label: 'Azimuth from Pt 1', type: 'number'),
      const CalcInputDef(key: 'n2', label: 'Pt 2 Northing', type: 'number'),
      const CalcInputDef(key: 'e2', label: 'Pt 2 Easting', type: 'number'),
      const CalcInputDef(key: 'az2', label: 'Azimuth from Pt 2', type: 'number'),
    ],
    calculate: (v) {
      final n1 = double.tryParse(v['n1'] ?? '');
      final e1 = double.tryParse(v['e1'] ?? '');
      final az1Deg = double.tryParse(v['az1'] ?? '');
      final n2 = double.tryParse(v['n2'] ?? '');
      final e2 = double.tryParse(v['e2'] ?? '');
      final az2Deg = double.tryParse(v['az2'] ?? '');

      if (n1 == null || e1 == null || n2 == null || e2 == null || az1Deg == null || az2Deg == null) return {};

      final az1 = toRad(az1Deg);
      final az2 = toRad(az2Deg);

      final sin1 = sin(az1); final cos1 = cos(az1);
      final sin2 = sin(az2); final cos2 = cos(az2);

      final det = cos1 * sin2 - sin1 * cos2;
      if (det.abs() < 1e-9) return {'Error': 'Lines are parallel'};

      final t = ((n2 - n1) * sin2 - (e2 - e1) * cos2) / det;

      return {
        'Intersection N': (n1 + t * cos1).toStringAsFixed(3),
        'Intersection E': (e1 + t * sin1).toStringAsFixed(3),
      };
    },
    outputOrder: ['Intersection N', 'Intersection E'],
  ),

  'int_brg_dist': CalcDefinition(
    title: 'Bearing - Distance',
    inputs: [
      const CalcInputDef(key: 'n1', label: 'Line Pt Northing', type: 'number'),
      const CalcInputDef(key: 'e1', label: 'Line Pt Easting', type: 'number'),
      const CalcInputDef(key: 'az', label: 'Line Azimuth', type: 'number'),
      const CalcInputDef(key: 'n2', label: 'Circle Center N', type: 'number'),
      const CalcInputDef(key: 'e2', label: 'Circle Center E', type: 'number'),
      const CalcInputDef(key: 'dist', label: 'Radius/Dist', type: 'number'),
    ],
    calculate: (v) {
      final n1 = double.tryParse(v['n1'] ?? '');
      final e1 = double.tryParse(v['e1'] ?? '');
      final azDeg = double.tryParse(v['az'] ?? '');
      final n2 = double.tryParse(v['n2'] ?? '');
      final e2 = double.tryParse(v['e2'] ?? '');
      final r = double.tryParse(v['dist'] ?? '');

      if (n1 == null || e1 == null || azDeg == null || n2 == null || e2 == null || r == null) return {};

      final az = toRad(azDeg);

      final dN = n1 - n2;
      final dE = e1 - e2;
      final cosA = cos(az);
      final sinA = sin(az);

      final a = 1.0;
      final b = 2 * (dN * cosA + dE * sinA);
      final c = (dN * dN + dE * dE) - (r * r);

      final discrim = b * b - 4 * a * c;

      if (discrim < 0) return {'Error': 'Line does not intersect circle'};

      final t1 = (-b + sqrt(discrim)) / (2 * a);
      final t2 = (-b - sqrt(discrim)) / (2 * a);

      final sol1N = n1 + t1 * cosA;
      final sol1E = e1 + t1 * sinA;
      final sol2N = n1 + t2 * cosA;
      final sol2E = e1 + t2 * sinA;

      return {
        'Sol 1 N': sol1N.toStringAsFixed(3),
        'Sol 1 E': sol1E.toStringAsFixed(3),
        'Sol 2 N': sol2N.toStringAsFixed(3),
        'Sol 2 E': sol2E.toStringAsFixed(3),
      };
    },
    outputOrder: ['Sol 1 N', 'Sol 1 E', 'Sol 2 N', 'Sol 2 E'],
  ),

  'int_dist_dist': CalcDefinition(
    title: 'Distance - Distance',
    inputs: [
      const CalcInputDef(key: 'n1', label: 'Pt 1 N', type: 'number'),
      const CalcInputDef(key: 'e1', label: 'Pt 1 E', type: 'number'),
      const CalcInputDef(key: 'r1', label: 'Dist from Pt 1', type: 'number'),
      const CalcInputDef(key: 'n2', label: 'Pt 2 N', type: 'number'),
      const CalcInputDef(key: 'e2', label: 'Pt 2 E', type: 'number'),
      const CalcInputDef(key: 'r2', label: 'Dist from Pt 2', type: 'number'),
    ],
    calculate: (v) {
      final n1 = double.tryParse(v['n1'] ?? '');
      final e1 = double.tryParse(v['e1'] ?? '');
      final r1 = double.tryParse(v['r1'] ?? '');
      final n2 = double.tryParse(v['n2'] ?? '');
      final e2 = double.tryParse(v['e2'] ?? '');
      final r2 = double.tryParse(v['r2'] ?? '');

      if (n1 == null || e1 == null || r1 == null || n2 == null || e2 == null || r2 == null) return {};

      final d2 = pow(n2 - n1, 2) + pow(e2 - e1, 2);
      final d = sqrt(d2);

      if (d > r1 + r2 || d < (r1 - r2).abs() || d == 0) return {'Error': 'No intersection'};

      final a = (r1 * r1 - r2 * r2 + d2) / (2 * d);
      final h = sqrt(max(0, r1 * r1 - a * a));

      final x2 = n1 + a * (n2 - n1) / d;
      final y2 = e1 + a * (e2 - e1) / d;

      final n3_1 = x2 + h * (e2 - e1) / d;
      final e3_1 = y2 - h * (n2 - n1) / d;
      final n3_2 = x2 - h * (e2 - e1) / d;
      final e3_2 = y2 + h * (n2 - n1) / d;

      return {
        'Sol 1 N': n3_1.toStringAsFixed(3), 'Sol 1 E': e3_1.toStringAsFixed(3),
        'Sol 2 N': n3_2.toStringAsFixed(3), 'Sol 2 E': e3_2.toStringAsFixed(3),
      };
    },
    outputOrder: ['Sol 1 N', 'Sol 1 E', 'Sol 2 N', 'Sol 2 E'],
  ),

  'int_line_line': CalcDefinition(
    title: 'Line - Line (4 Pt)',
    inputs: [
      const CalcInputDef(key: 'n1', label: 'Line 1 Start N', type: 'number'),
      const CalcInputDef(key: 'e1', label: 'Line 1 Start E', type: 'number'),
      const CalcInputDef(key: 'n2', label: 'Line 1 End N', type: 'number'),
      const CalcInputDef(key: 'e2', label: 'Line 1 End E', type: 'number'),
      const CalcInputDef(key: 'n3', label: 'Line 2 Start N', type: 'number'),
      const CalcInputDef(key: 'e3', label: 'Line 2 Start E', type: 'number'),
      const CalcInputDef(key: 'n4', label: 'Line 2 End N', type: 'number'),
      const CalcInputDef(key: 'e4', label: 'Line 2 End E', type: 'number'),
    ],
    calculate: (v) {
      final n1 = double.tryParse(v['n1'] ?? '');
      final e1 = double.tryParse(v['e1'] ?? '');
      final n2 = double.tryParse(v['n2'] ?? '');
      final e2 = double.tryParse(v['e2'] ?? '');
      final n3 = double.tryParse(v['n3'] ?? '');
      final e3 = double.tryParse(v['e3'] ?? '');
      final n4 = double.tryParse(v['n4'] ?? '');
      final e4 = double.tryParse(v['e4'] ?? '');

      if (n1 == null) return {}; // Short circuit check for simplicity

      final den = (n1! - n2!) * (e3! - e4!) - (e1! - e2!) * (n3! - n4!);
      if (den.abs() < 1e-9) return {'Error': 'Lines are parallel'};

      final t = ((n1 - n3) * (e3 - e4) - (e1 - e3) * (n3 - n4)) / den;

      return {
        'Intersection N': (n1 + t * (n2 - n1)).toStringAsFixed(3),
        'Intersection E': (e1 + t * (e2 - e1)).toStringAsFixed(3),
      };
    },
    outputOrder: ['Intersection N', 'Intersection E'],
  ),

  'int_pt_line': CalcDefinition(
    title: 'Point to Line (Perp)',
    inputs: [
      const CalcInputDef(key: 'n1', label: 'Line Start N', type: 'number'),
      const CalcInputDef(key: 'e1', label: 'Line Start E', type: 'number'),
      const CalcInputDef(key: 'n2', label: 'Line End N', type: 'number'),
      const CalcInputDef(key: 'e2', label: 'Line End E', type: 'number'),
      const CalcInputDef(key: 'np', label: 'Point N', type: 'number'),
      const CalcInputDef(key: 'ep', label: 'Point E', type: 'number'),
    ],
    calculate: (v) {
      final n1 = double.tryParse(v['n1'] ?? '');
      final e1 = double.tryParse(v['e1'] ?? '');
      final n2 = double.tryParse(v['n2'] ?? '');
      final e2 = double.tryParse(v['e2'] ?? '');
      final np = double.tryParse(v['np'] ?? '');
      final ep = double.tryParse(v['ep'] ?? '');

      if (n1 == null || e1 == null || n2 == null || e2 == null || np == null || ep == null) return {};

      final dN = n2 - n1;
      final dE = e2 - e1;
      final lenSq = dN * dN + dE * dE;
      if (lenSq == 0) return {'Error': 'Line length is zero'};

      final t = ((np - n1) * dN + (ep - e1) * dE) / lenSq;

      final intN = n1 + t * dN;
      final intE = e1 + t * dE;

      final offN = np - intN;
      final offE = ep - intE;
      final offsetDist = sqrt(offN * offN + offE * offE);

      final cross = dE * (np - n1) - dN * (ep - e1);
      final side = cross > 0 ? 'Right' : 'Left';

      final totalLen = sqrt(lenSq);
      final station = t * totalLen;

      return {
        'Projected N': intN.toStringAsFixed(3),
        'Projected E': intE.toStringAsFixed(3),
        'Station': station.toStringAsFixed(3),
        'Offset': '${offsetDist.toStringAsFixed(3)} ($side)',
      };
    },
    outputOrder: ['Projected N', 'Projected E', 'Station', 'Offset'],
  ),

  // --- Area / Volume ---
  'area_coord': CalcDefinition(
    title: 'Coordinate Area',
    inputs: [
      const CalcInputDef(key: 'coords', label: 'Coordinates (N,E per line)', type: 'textarea', placeholder: '5000,5000\n5100,5000\n5100,5100'),
    ],
    calculate: (v) {
      final lines = (v['coords'] ?? '').split('\n');
      final points = <Map<String, double>>[];
      for (final line in lines) {
        final parts = line.split(',');
        if (parts.length >= 2) {
          final n = double.tryParse(parts[0].trim());
          final e = double.tryParse(parts[1].trim());
          if (n != null && e != null) {
            points.add({'n': n, 'e': e});
          }
        }
      }

      if (points.length < 3) return {'Status': 'Need 3+ points'};

      double area = 0;
      int j = points.length - 1;
      for (int i = 0; i < points.length; i++) {
        area += (points[j]['e']! + points[i]['e']!) * (points[j]['n']! - points[i]['n']!);
        j = i;
      }
      area = (area.abs() / 2);

      return {
        'Area (sq m)': area.toStringAsFixed(2),
        'Area (ha)': (area / 10000).toStringAsFixed(4),
      };
    },
    outputOrder: ['Area (sq m)', 'Area (ha)'],
  ),

  'vol_end_area': CalcDefinition(
    title: 'Earthwork (Avg End Area)',
    inputs: [
      const CalcInputDef(key: 'a1', label: 'Area 1 (sq m)', type: 'number'),
      const CalcInputDef(key: 'a2', label: 'Area 2 (sq m)', type: 'number'),
      const CalcInputDef(key: 'len', label: 'Length/Dist (m)', type: 'number'),
    ],
    calculate: (v) {
      final a1 = double.tryParse(v['a1'] ?? '');
      final a2 = double.tryParse(v['a2'] ?? '');
      final l = double.tryParse(v['len'] ?? '');
      if (a1 == null || a2 == null || l == null) return {};
      return {'Volume (cu m)': (((a1 + a2) / 2) * l).toStringAsFixed(2)};
    },
    outputOrder: ['Volume (cu m)'],
  ),

  // --- Curves ---
  'curve_horiz': CalcDefinition(
    title: 'Horizontal Curve',
    inputs: [
      const CalcInputDef(key: 'r', label: 'Radius', type: 'number'),
      const CalcInputDef(key: 'delta', label: 'Delta Angle (Deg)', type: 'number'),
    ],
    calculate: (v) {
      final r = double.tryParse(v['r'] ?? '');
      final delta = double.tryParse(v['delta'] ?? '');
      if (r == null || delta == null) return {};

      final deltaRad = toRad(delta);
      return {
        'Tangent (T)': (r * tan(deltaRad / 2)).toStringAsFixed(3),
        'Arc Length (L)': (r * deltaRad).toStringAsFixed(3),
        'Chord (C)': (2 * r * sin(deltaRad / 2)).toStringAsFixed(3),
        'External (E)': (r * (1 / cos(deltaRad / 2) - 1)).toStringAsFixed(3),
      };
    },
    outputOrder: ['Tangent (T)', 'Arc Length (L)', 'Chord (C)', 'External (E)'],
  ),

  'curve_vert': CalcDefinition(
    title: 'Vertical Curve',
    inputs: [
      const CalcInputDef(key: 'g1', label: 'Grade 1 (%)', type: 'number'),
      const CalcInputDef(key: 'g2', label: 'Grade 2 (%)', type: 'number'),
      const CalcInputDef(key: 'len', label: 'Curve Length (L)', type: 'number'),
      const CalcInputDef(key: 'pvi_sta', label: 'PVI Station', type: 'number'),
      const CalcInputDef(key: 'pvi_elev', label: 'PVI Elevation', type: 'number'),
    ],
    calculate: (v) {
      final g1 = double.tryParse(v['g1'] ?? '');
      final g2 = double.tryParse(v['g2'] ?? '');
      final L = double.tryParse(v['len'] ?? '');
      final pviS = double.tryParse(v['pvi_sta'] ?? '');
      final pviE = double.tryParse(v['pvi_elev'] ?? '');

      if (g1 == null || g2 == null || L == null || pviS == null || pviE == null) return {};

      final A = g2 - g1;
      final r = A / L;
      final bvcSta = pviS - L / 2;
      final bvcElev = pviE - (g1 / 100) * (L / 2);
      final evcSta = pviS + L / 2;
      final evcElev = pviE + (g2 / 100) * (L / 2);

      final K = L / A.abs();

      double highLowSta = bvcSta;
      double highLowElev = bvcElev;

      if (g1 != 0) {
        final x = -(g1 / 100) / (r / 100);
        if (x >= 0 && x <= L) {
          highLowSta = bvcSta + x;
          highLowElev = bvcElev + (g1 / 100) * x + 0.5 * (r / 100) * x * x;
        }
      }

      return {
        'BVC Station': bvcSta.toStringAsFixed(2),
        'BVC Elev': bvcElev.toStringAsFixed(3),
        'EVC Station': evcSta.toStringAsFixed(2),
        'EVC Elev': evcElev.toStringAsFixed(3),
        'K Value': K.toStringAsFixed(2),
        'Turning Point Sta': highLowSta.toStringAsFixed(2),
        'Turning Point Elev': highLowElev.toStringAsFixed(3),
      };
    },
    outputOrder: ['BVC Station', 'BVC Elev', 'EVC Station', 'EVC Elev', 'K Value', 'Turning Point Sta', 'Turning Point Elev'],
  ),

  // --- Conversions ---
  'conv_unit': CalcDefinition(
    title: 'Unit Conversion',
    inputs: [
      const CalcInputDef(key: 'val', label: 'Value', type: 'number'),
      const CalcInputDef(key: 'type', label: 'Type', type: 'select', options: [
        {'label': 'Meters to Feet', 'value': 'm2f'},
        {'label': 'Feet to Meters', 'value': 'f2m'},
        {'label': 'Acres to Hectares', 'value': 'ac2ha'},
        {'label': 'Hectares to Acres', 'value': 'ha2ac'},
      ]),
    ],
    calculate: (v) {
      final val = double.tryParse(v['val'] ?? '');
      final type = v['type'];
      if (val == null || type == null) return {};

      double res = 0;
      String unit = '';
      switch (type) {
        case 'm2f': res = val * 3.28084; unit = 'ft'; break;
        case 'f2m': res = val / 3.28084; unit = 'm'; break;
        case 'ac2ha': res = val * 0.404686; unit = 'ha'; break;
        case 'ha2ac': res = val * 2.47105; unit = 'ac'; break;
        default: return {};
      }
      return {'Result': '${res.toStringAsFixed(4)} $unit'};
    },
    outputOrder: ['Result'],
  ),
  'conv_dms_dec': CalcDefinition(
    title: 'DMS <-> Decimal',
    inputs: [
      const CalcInputDef(key: 'd', label: 'Deg', type: 'number'),
      const CalcInputDef(key: 'm', label: 'Min', type: 'number'),
      const CalcInputDef(key: 's', label: 'Sec', type: 'number'),
    ],
    calculate: (v) {
      final d = double.tryParse(v['d'] ?? '') ?? 0;
      final m = double.tryParse(v['m'] ?? '') ?? 0;
      final s = double.tryParse(v['s'] ?? '') ?? 0;
      final dec = d + m/60 + s/3600;
      return {'Decimal Degrees': dec.toStringAsFixed(7)};
    },
    outputOrder: ['Decimal Degrees'],
  ),
};

// --- Category Data ---

final Map<String, CategoryData> computationData = {
  'cogo': const CategoryData(
    id: 'cogo',
    title: 'COGO',
    icon: Icons.square_foot,
    color: Colors.blue,
    description: 'Coordinate Geometry.',
    items: [
      CalculationItem(id: 'cogo_inverse', name: 'Inverse', desc: 'Bearing/Dist between points.', targetRoute: '/computation/cogo_inverse'),
      CalculationItem(id: 'cogo_forward_dedicated', name: 'Bearing-Distance (Direct)', desc: 'Dedicated screen for Direct COGO.', targetRoute: '/computation/cogo_forward', badge: 'NEW'), // Updated routes
      CalculationItem(id: 'cogo_forward', name: 'Forward (Quick)', desc: 'New point from Azimuth/Dist.'),
      CalculationItem(id: 'cogo_radiation', name: 'Radiation', desc: 'Multiple points from station.'),
      CalculationItem(id: 'cogo_offset', name: 'Station & Offset', desc: 'Line offset calcs.'),
    ],
  ),
  'leveling': const CategoryData(
    id: 'leveling',
    title: 'Leveling',
    icon: Icons.landscape,
    color: Colors.green,
    description: 'Elevations & Adjustments.',
    items: [
      CalculationItem(id: 'level_digital', name: 'Digital Leveling Book', desc: 'Differential leveling loops.', targetRoute: '/computation/differential_leveling', badge: 'NEW'),
      CalculationItem(id: 'level_trig_dedicated', name: 'Trig Leveling (Visual)', desc: 'Dedicated screen with diagram.', targetRoute: '/computation/trig_leveling', badge: 'NEW'),
      CalculationItem(id: 'level_trig', name: 'Trig Leveling (Quick)', desc: 'Vertical Angle methods.'),
      CalculationItem(id: 'level_two_peg', name: 'Two Peg Test', desc: 'Check instrument error.'),
    ],
  ),
  'traversing': const CategoryData(
    id: 'traversing',
    title: 'Traversing',
    icon: Icons.polyline,
    color: Colors.purple,
    description: 'Network Adjustment.',
    items: [
      CalculationItem(id: 'trav_bowditch', name: 'Bowditch Loop', desc: 'Compass rule.', targetRoute: '/computation/traverse', badge: 'APP'),
      CalculationItem(id: 'trav_open', name: 'Open Traverse', desc: 'No adjustment.', targetRoute: '/computation/traverse'),
    ],
  ),
  'intersections': const CategoryData(
    id: 'intersections',
    title: 'Intersections',
    icon: Icons.my_location,
    color: Colors.cyan,
    description: 'Geometric solutions.',
    items: [
      CalculationItem(id: 'int_brg_brg', name: 'Bearing - Bearing', desc: 'Two Azimuths.'),
      CalculationItem(id: 'int_brg_dist', name: 'Bearing - Distance', desc: 'Line & Circle.'),
      CalculationItem(id: 'int_dist_dist', name: 'Distance - Distance', desc: 'Trilateration.'),
      CalculationItem(id: 'int_line_line', name: 'Line - Line (4 Pt)', desc: 'From coordinates.'),
      CalculationItem(id: 'int_pt_line', name: 'Point to Line', desc: 'Perpendicular offset.'),
    ],
  ),
  'area_volume': const CategoryData(
    id: 'area_volume',
    title: 'Area & Volume',
    icon: Icons.view_in_ar,
    color: Colors.orange,
    description: 'Earthworks & Parcels.',
    items: [
      CalculationItem(id: 'area_coord', name: 'Coordinate Area', desc: 'From point list.'),
      CalculationItem(id: 'vol_end_area', name: 'End Area Volume', desc: 'From cross-sections.'),
    ],
  ),
  'curves': const CategoryData(
    id: 'curves',
    title: 'Curves',
    icon: Icons.call_made,
    color: Colors.pink,
    description: 'Alignment Geometry.',
    items: [
      CalculationItem(id: 'curve_horiz', name: 'Horizontal Curve', desc: 'Circular curves.'),
      CalculationItem(id: 'curve_vert', name: 'Vertical Curve', desc: 'Parabolic crest/sag.'),
    ],
  ),
  'conversions': const CategoryData(
    id: 'conversions',
    title: 'Conversions',
    icon: Icons.sync_alt,
    color: Colors.yellow,
    description: 'Units & Datums.',
    items: [
      CalculationItem(id: 'conv_unit', name: 'Unit Converter', desc: 'Feet/Meters/Acres.'),
      CalculationItem(id: 'conv_dms_dec', name: 'DMS <-> Decimal', desc: 'Angle formats.'),
    ],
  ),
};
