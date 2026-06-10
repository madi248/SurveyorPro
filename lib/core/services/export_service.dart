import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:surveyor_pro/core/models/project.dart';
import 'package:surveyor_pro/core/models/survey_point.dart';
import 'package:surveyor_pro/core/models/log_entry.dart';

class ExportService {
  
  Future<File> generatePointsCSV(Project project, List<SurveyPoint> points) async {
    List<List<dynamic>> rows = [];
    
    // Header
    rows.add(['Point ID', 'Northing', 'Easting', 'Description', 'Type']);
    
    // Data
    for (var p in points) {
      rows.add([
        p.name,
        p.northing.toStringAsFixed(3),
        p.easting.toStringAsFixed(3),
        p.description,
        p.type
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${project.name}_Points.csv';
    
    final file = File(path);
    await file.writeAsString(csv);
    
    return file;
  }

  Future<File> generateFieldReportPDF(Project project, List<LogEntry> logs) async {
    final pdf = pw.Document();
    
    // Pre-load images is tricky in PDF package without async inside widget build, 
    // so we build list of widgets beforehand or use a wrapper.
    // simpler: Iterate and build widgets list.
    
    final List<pw.Widget> content = [];
    
    // Header
    content.add(pw.Header(
      level: 0, 
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(project.name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Job ID: ${project.jobId}'),
            pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
          ]),
        ]
      )
    ));
    
    content.add(pw.SizedBox(height: 20));
    content.add(pw.Text('Field Observation Log', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)));
    content.add(pw.Divider());
    content.add(pw.SizedBox(height: 10));

    for (var log in logs) {
       content.add(pw.Container(
         margin: const pw.EdgeInsets.only(bottom: 20),
         child: pw.Column(
           crossAxisAlignment: pw.CrossAxisAlignment.start,
           children: [
             pw.Row(
               mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
               children: [
                 pw.Text(log.date, style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
               ]
             ),
             pw.SizedBox(height: 5),
             pw.Text(log.note, style: const pw.TextStyle(fontSize: 12)),
             pw.SizedBox(height: 10),
           ]
         )
       ));
       
       if (log.imagePath != null && log.imagePath!.isNotEmpty) {
          final file = File(log.imagePath!);
          if (file.existsSync()) {
             final image = pw.MemoryImage(file.readAsBytesSync());
             content.add(pw.Container(
               height: 200,
               alignment: pw.Alignment.centerLeft,
               child: pw.Image(image, fit: pw.BoxFit.contain)
             ));
             content.add(pw.SizedBox(height: 10));
          }
       }
       content.add(pw.Divider(color: PdfColors.grey300));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => content,
      )
    );

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${project.name}_Report.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
}
