import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/csv_import_service.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/survey_point.dart';
import '../../../core/theme/app_theme.dart';

class ImportScreen extends StatefulWidget {
  final int projectId;
  
  const ImportScreen({super.key, required this.projectId});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final CsvImportService _csvService = CsvImportService();
  
  File? _selectedFile;
  List<List<String>>? _csvData;
  Map<String, int> _columnMapping = {};
  bool _hasHeader = true;
  bool _importing = false;
  
  final List<String> _requiredFields = ['pointId', 'northing', 'easting'];
  final List<String> _optionalFields = ['elevation', 'description'];

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final data = await _csvService.parseCsvFile(file);
        
        setState(() {
          _selectedFile = file;
          _csvData = data;
          
          // Auto-detect columns if first row looks like header
          if (data.isNotEmpty) {
            _columnMapping = _csvService.detectColumns(data[0]);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading file: $e')),
        );
      }
    }
  }
  
  Future<void> _importData() async {
    if (_csvData == null || !_csvService.validateColumns(_columnMapping)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please map required columns: Point ID, Northing, Easting')),
      );
      return;
    }
    
    setState(() => _importing = true);
    
    try {
      final db = DatabaseHelper.instance;
      int startRow = _hasHeader ? 1 : 0;
      int imported = 0;
      
      for (int i = startRow; i < _csvData!.length; i++) {
        final row = _csvData![i];
        if (row.length < 3) continue; // Skip invalid rows
        
        final pointData = _csvService.extractPointData(row, _columnMapping);
        
        final point = SurveyPoint(
          projectId: widget.projectId,
          name: pointData['pointId'],
          easting: pointData['easting'],
          northing: pointData['northing'],
          elevation: pointData['elevation'],
          description: pointData['description'],
        );
        
        await db.createPoint(point);
        imported++;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported $imported points')),
        );
        context.go('/map');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e')),
        );
      }
    } finally {
      setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Import CSV/TXT'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // File Selection
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select File', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.file_open),
                  label: Text(_selectedFile == null ? 'Choose CSV/TXT File' : _selectedFile!.path.split('/').last),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _hasHeader,
                      onChanged: (v) => setState(() => _hasHeader = v!),
                      activeColor: AppColors.primary,
                    ),
                    const Text('First row contains headers', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          
          // Preview
          if (_csvData != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Preview (${_csvData!.length} rows)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey[800]),
                    columns: _csvData![0].map((h) => DataColumn(label: Text(h, style: const TextStyle(color: Colors.white)))).toList(),
                    rows: _csvData!.skip(1).take(3).map((row) => 
                      DataRow(cells: row.map((cell) => DataCell(Text(cell, style: const TextStyle(color: Colors.grey)))).toList())
                    ).toList(),
                  ),
                ),
              ),
            ),
            
            // Column Mapping
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Map Columns', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._requiredFields.map((field) => _buildColumnMapper(field, true)),
                  ..._optionalFields.map((field) => _buildColumnMapper(field, false)),
                ],
              ),
            ),
          ] else
            const Expanded(
              child: Center(
                child: Text('No file selected', style: TextStyle(color: Colors.grey)),
              ),
            ),
          
          // Import Button
          if (_csvData != null)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _importing ? null : _importData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _importing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Import Points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildColumnMapper(String field, bool required) {
    final displayName = {
      'pointId': 'Point ID',
      'northing': 'Northing',
      'easting': 'Easting',
      'elevation': 'Elevation',
      'description': 'Description'
    }[field]!;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              displayName + (required ? ' *' : ''),
              style: TextStyle(color: required ? Colors.white : Colors.grey[400]),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _columnMapping[field],
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              hint: const Text('Select column', style: TextStyle(color: Colors.grey)),
              items: [
                const DropdownMenuItem(value: null, child: Text('None', style: TextStyle(color: Colors.grey))),
                if (_csvData != null && _csvData!.isNotEmpty)
                  ...List.generate(_csvData![0].length, (i) => 
                    DropdownMenuItem(value: i, child: Text('Column ${i + 1}: ${_csvData![0][i]}', style: const TextStyle(color: Colors.white)))
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == null) {
                    _columnMapping.remove(field);
                  } else {
                    _columnMapping[field] = value;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
