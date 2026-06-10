import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:dxf/dxf.dart';
import 'package:flutter/material.dart';

class DxfService {
  Future<List<List<Offset>>?> pickAndParseDxf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dxf'],
      );

      if (result != null && result.files.single.path != null) {
         final file = File(result.files.single.path!);
         final String data = await file.readAsString();
         final dxf = DXF.fromString(data);
         return _parseEntities(dxf);
      }
    } catch (e) {
      debugPrint('Error parsing DXF: $e');
      return null;
    }
    return null;
  }

  List<List<Offset>> _parseEntities(DXF dxf) {
    final List<List<Offset>> polylines = [];
    
    // Iterate through entites
    for (var entity in dxf.entities) {
       if (entity is AcDbLine) {
         polylines.add([
           Offset(entity.x, entity.y),
           Offset(entity.x1, entity.y1),
         ]);
       } else if (entity is AcDbPolyline) {
         final List<Offset> points = [];
         for (var v in entity.vertices) {
           points.add(Offset(v[0], v[1]));
         }
         // Check if closed
         if (entity.isClosed && points.isNotEmpty) {
           points.add(points.first);
         }
         polylines.add(points);
       }
       // Add other types if needed (Circle, Arc - might need segmentation)
    }
    return polylines;
  }
}
