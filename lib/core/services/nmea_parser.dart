import 'package:surveyor_pro/core/models/survey_point.dart';

class NmeaParser {
  // Parsing State
  double? _lat;
  double? _lon;
  double? _elev;
  double? _hdop;
  int? _quality; // 1=GPS, 2=DGPS, 4=RTK Fix, 5=RTK Float
  int? _sats;

  /// Parses a raw NMEA string line.
  /// Returns a SurveyPoint ONLY if enough data is gathered (e.g. after GPGGA).
  /// Note: NMEA comes in bursts. We usually buffer data until we get a position.
  SurveyPoint? parseLine(String line) {
    if (!line.startsWith('\$')) return null;
    
    // Validate Checksum if needed (skip for now for simplicity)
    
    final parts = line.split('*')[0].split(',');
    if (parts.isEmpty) return null;

    final type = parts[0];

    try {
      if (type.endsWith('GGA')) {
         // $GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47
         // 2: Lat, 3: N/S, 4: Lon, 5: E/W, 6: Fix Qual, 7: Sats, 8: HDOP, 9: Elev
         _lat = _parseCoord(parts[2], parts[3]);
         _lon = _parseCoord(parts[4], parts[5]);
         _quality = int.tryParse(parts[6]);
         _sats = int.tryParse(parts[7]);
         _hdop = double.tryParse(parts[8]);
         _elev = double.tryParse(parts[9]);

         if (_lat != null && _lon != null) {
            // Determine type based on quality
            String desc = 'GNSS';
            if (_quality == 4) desc = 'RTK FIX';
            else if (_quality == 5) desc = 'RTK FLOAT';
            else if (_quality == 2) desc = 'DGPS';
            else if (_quality == 1) desc = 'GPS';

            return SurveyPoint(
               projectId: 0, // transient
               name: 'GNSS',
               northing: _lat!, // Store Lat in Northing for now (Logic layer maps it later or we use Projection)
               easting: _lon!,  // Store Lon in Easting
               elevation: _elev ?? 0.0,
               description: '$desc S:$_sats H:$_hdop',
               type: 'GNSS_RAW'
            );
         }
      } 
      // Add RMC or others if needed
    } catch (e) {
      // parse error
    }
    return null;
  }

  // Convert NMEA DDMM.MMMM to Decimal Degrees
  double? _parseCoord(String val, String card) {
    if (val.isEmpty || card.isEmpty) return null;
    
    // 4807.038 -> 48 deg 07.038 min
    double raw = double.parse(val);
    int deg = (raw / 100).floor();
    double min = raw - (deg * 100);
    double dd = deg + (min / 60.0);
    
    if (card == 'S' || card == 'W') {
      dd = -dd;
    }
    return dd;
  }
}
