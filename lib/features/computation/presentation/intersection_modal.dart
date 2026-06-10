import 'package:flutter/material.dart';
import 'package:surveyor_pro/core/models/survey_point.dart';
import 'package:surveyor_pro/core/theme/app_theme.dart';
import 'package:surveyor_pro/core/utils/intersection_utils.dart';
import 'package:surveyor_pro/core/database/database_helper.dart';

class IntersectionModal extends StatefulWidget {
  final List<SurveyPoint> points;
  final Function(SurveyPoint) onPointCreated;

  const IntersectionModal({super.key, required this.points, required this.onPointCreated});

  @override
  State<IntersectionModal> createState() => _IntersectionModalState();
}

class _IntersectionModalState extends State<IntersectionModal> {
  String _mode = 'BB'; // BB (Bearing-Bearing), DD (Dist-Dist)
  
  SurveyPoint? _p1;
  SurveyPoint? _p2;
  
  final _param1Ctrl = TextEditingController();
  final _param2Ctrl = TextEditingController();
  final _newIdCtrl = TextEditingController();
  
  List<Offset> _results = [];
  Offset? _selectedResult;

  void _calculate() {
    if (_p1 == null || _p2 == null) return;
    final v1 = double.tryParse(_param1Ctrl.text);
    final v2 = double.tryParse(_param2Ctrl.text);
    
    if (v1 == null || v2 == null) return;
    
    setState(() {
       _results.clear();
       _selectedResult = null;
       
       if (_mode == 'BB') {
          final res = IntersectionUtils.bearingBearing(
             Offset(_p1!.easting, _p1!.northing), v1, 
             Offset(_p2!.easting, _p2!.northing), v2
          );
          if (res != null) _results.add(res);
       } else {
          _results = IntersectionUtils.distanceDistance(
             Offset(_p1!.easting, _p1!.northing), v1,
             Offset(_p2!.easting, _p2!.northing), v2
          );
       }
       
       if (_results.isNotEmpty) _selectedResult = _results.first;
    });
  }
  
  Future<void> _save() async {
    if (_selectedResult == null || _newIdCtrl.text.isEmpty) return;
    
    final newPoint = SurveyPoint(
       projectId: _p1!.projectId, // Inherit project
       name: _newIdCtrl.text,
       northing: _selectedResult!.dy,
       easting: _selectedResult!.dx,
       elevation: 0.0,
       description: 'INT $_mode ${_p1!.name}-${_p2!.name}',
       type: 'computed',
    );
    
    await DatabaseHelper.instance.createPoint(newPoint);
    widget.onPointCreated(newPoint);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
           margin: const EdgeInsets.all(24),
           padding: const EdgeInsets.all(20),
           decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[700]!)),
           child: SingleChildScrollView(
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                     const Text('Intersection Tool', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                     IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                  ]),
                  const SizedBox(height: 16),
                  
                  // Mode Toggle
                  Row(children: [
                     _buildModeBtn('Bearing-Bearing', 'BB'),
                     const SizedBox(width: 8),
                     _buildModeBtn('Distance-Distance', 'DD'),
                  ]),
                  const SizedBox(height: 16),
                  
                  // Point 1
                  _buildPointRow('Point 1', 'Azimuth' /* or Dist */, _p1, (p) => setState(() => _p1 = p), _param1Ctrl),
                  const SizedBox(height: 8),
                  
                  // Point 2
                  _buildPointRow('Point 2', 'Azimuth' /* or Dist */, _p2, (p) => setState(() => _p2 = p), _param2Ctrl),
                  
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _calculate, child: const Text('Calculate'))),
                  
                  if (_results.isNotEmpty) ...[
                     const SizedBox(height: 16),
                     const Text('Results', style: TextStyle(color: Colors.grey)),
                     const SizedBox(height: 8),
                     ..._results.asMap().entries.map((e) {
                        final idx = e.key;
                        final p = e.value;
                        final isSel = _selectedResult == p;
                        return GestureDetector(
                           onTap: () => setState(() => _selectedResult = p),
                           child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                 color: isSel ? AppColors.primary.withValues(alpha: 0.2) : Colors.black26, 
                                 border: Border.all(color: isSel ? AppColors.primary : Colors.transparent),
                                 borderRadius: BorderRadius.circular(8)
                              ),
                              child: Text('N: ${p.dy.toStringAsFixed(3)}, E: ${p.dx.toStringAsFixed(3)}', style: const TextStyle(color: Colors.white)),
                           ),
                        );
                     }),
                     
                     const SizedBox(height: 16),
                     Row(
                        children: [
                           Expanded(child: TextField(controller: _newIdCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(filled: true, fillColor: Colors.black26, hintText: 'New Point ID', hintStyle: TextStyle(color: Colors.grey)))),
                           const SizedBox(width: 8),
                           ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Save Point')),
                        ],
                     ),
                  ],
               ],
             ),
           ),
        ),
      ),
    );
  }
  
  Widget _buildPointRow(String label, String paramHint, SurveyPoint? val, Function(SurveyPoint?) onChanged, TextEditingController ctrl) {
     final hint = _mode == 'BB' ? 'Azimuth (Deg)' : 'Distance';
     return Row(
        children: [
           Expanded(
              flex: 2,
              child: DropdownButtonFormField<SurveyPoint>(
                 value: val,
                 dropdownColor: AppColors.surface,
                 decoration: InputDecoration(filled: true, fillColor: Colors.black26, labelText: label, labelStyle: const TextStyle(color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                 items: widget.points.map((p) => DropdownMenuItem(value: p, child: Text(p.name, style: const TextStyle(color: Colors.white)))).toList(),
                 onChanged: onChanged,
              ),
           ),
           const SizedBox(width: 8),
           Expanded(
              flex: 1,
              child: TextField(
                 controller: ctrl,
                 keyboardType: TextInputType.number,
                 style: const TextStyle(color: Colors.white),
                 decoration: InputDecoration(filled: true, fillColor: Colors.black26, labelText: hint, labelStyle: const TextStyle(color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              ),
           ),
        ],
     );
  }

  Widget _buildModeBtn(String label, String val) {
     final isSel = _mode == val;
     return Expanded(
        child: GestureDetector(
           onTap: () => setState(() => _mode = val),
           child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: isSel ? AppColors.primary : Colors.grey[800], borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
           ),
        ),
     );
  }
}
