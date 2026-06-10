import 'dart:io';
import 'package:csv/csv.dart';

class CsvImportService {
  
  /// Parse CSV file and return list of rows
  Future<List<List<String>>> parseCsvFile(File file) async {
    try {
      final input = await file.readAsString();
      
      // Try different delimiters
      List<List<dynamic>> rows;
      if (input.contains('\t')) {
        rows = const CsvToListConverter(fieldDelimiter: '\t').convert(input);
      } else if (input.contains(';')) {
        rows = const CsvToListConverter(fieldDelimiter: ';').convert(input);
      } else {
        rows = const CsvToListConverter().convert(input);
      }
      
      // Convert to String list
      return rows.map((row) => row.map((cell) => cell.toString()).toList()).toList();
    } catch (e) {
      throw Exception('Failed to parse CSV: $e');
    }
  }
  
  /// Auto-detect column indices based on headers
  Map<String, int> detectColumns(List<String> headers) {
    final Map<String, int> detected = {};
    
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      
      // Point ID detection
      if (header.contains('point') || header == 'id' || header == 'number' || header == 'no') {
        detected['pointId'] = i;
      }
      
      // Northing detection
      if (header.contains('north') || header == 'n' || header == 'y') {
        detected['northing'] = i;
      }
      
      // Easting detection
      if (header.contains('east') || header == 'e' || header == 'x') {
        detected['easting'] = i;
      }
      
      // Elevation detection
      if (header.contains('elev') || header == 'z' || header.contains('height')) {
        detected['elevation'] = i;
      }
      
      // Description detection
      if (header.contains('desc') || header.contains('code') || header.contains('feature')) {
        detected['description'] = i;
      }
    }
    
    return detected;
  }
  
  /// Validate that required columns are present
  bool validateColumns(Map<String, int> columns) {
    return columns.containsKey('pointId') && 
           columns.containsKey('northing') && 
           columns.containsKey('easting');
  }
  
  /// Extract point data from row based on column mapping
  Map<String, dynamic> extractPointData(List<String> row, Map<String, int> columnMap) {
    return {
      'pointId': row[columnMap['pointId']!],
      'northing': double.tryParse(row[columnMap['northing']!]) ?? 0.0,
      'easting': double.tryParse(row[columnMap['easting']!]) ?? 0.0,
      'elevation': columnMap.containsKey('elevation') 
          ? (double.tryParse(row[columnMap['elevation']!]) ?? 0.0) 
          : 0.0,
      'description': columnMap.containsKey('description') && columnMap['description']! < row.length
          ? row[columnMap['description']!] 
          : '',
    };
  }
}
