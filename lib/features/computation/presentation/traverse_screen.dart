import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class Observation {
  final int id;
  final String targetId;
  final String hAngle;
  final String slopeDist;

  Observation({required this.id, required this.targetId, required this.hAngle, required this.slopeDist});
}

class Coordinate {
  final String id;
  final double n;
  final double e;

  Coordinate({required this.id, required this.n, required this.e});

  Map<String, dynamic> toJson() => {'id': id, 'n': n, 'e': e};
}

class TraverseScreen extends StatefulWidget {
  const TraverseScreen({super.key});

  @override
  State<TraverseScreen> createState() => _TraverseScreenState();
}

class _TraverseScreenState extends State<TraverseScreen> {
  // Station State
  final _stationIdCtrl = TextEditingController(text: 'STN-1');
  final _startNCtrl = TextEditingController(text: '5000.000');
  final _startECtrl = TextEditingController(text: '5000.000');
  final _bsAzCtrl = TextEditingController(text: '0');

  // Observation State
  final List<Observation> _obsList = [];
  final _targetCtrl = TextEditingController();
  final _angleCtrl = TextEditingController();
  final _distCtrl = TextEditingController();

  // Results
  List<Coordinate> _results = [];

  @override
  void dispose() {
    _stationIdCtrl.dispose();
    _startNCtrl.dispose();
    _startECtrl.dispose();
    _bsAzCtrl.dispose();
    _targetCtrl.dispose();
    _angleCtrl.dispose();
    _distCtrl.dispose();
    super.dispose();
  }

  void _addLeg() {
    if (_targetCtrl.text.isEmpty || _angleCtrl.text.isEmpty || _distCtrl.text.isEmpty) return;

    setState(() {
      _obsList.add(Observation(
        id: DateTime.now().millisecondsSinceEpoch,
        targetId: _targetCtrl.text,
        hAngle: _angleCtrl.text,
        slopeDist: _distCtrl.text,
      ));
      _targetCtrl.clear();
      _angleCtrl.clear();
      _distCtrl.clear();
    });
  }

  void _deleteLeg(int id) {
    setState(() {
      _obsList.removeWhere((obs) => obs.id == id);
    });
  }

  Future<void> _calculateTraverse() async {
    double currentN = double.tryParse(_startNCtrl.text) ?? 5000.0;
    double currentE = double.tryParse(_startECtrl.text) ?? 5000.0;
    double currentAz = double.tryParse(_bsAzCtrl.text) ?? 0.0;

    final computedCoords = <Coordinate>[];

    for (var obs in _obsList) {
      final angle = double.tryParse(obs.hAngle) ?? 0.0;
      final dist = double.tryParse(obs.slopeDist) ?? 0.0;

      double newAz = currentAz + angle;
      if (newAz >= 360) newAz -= 360;

      final rad = newAz * (pi / 180);
      final dN = cos(rad) * dist;
      final dE = sin(rad) * dist;

      currentN += dN;
      currentE += dE;
      currentAz = newAz;

      computedCoords.add(Coordinate(
        id: obs.targetId,
        n: double.parse(currentN.toStringAsFixed(3)),
        e: double.parse(currentE.toStringAsFixed(3)),
      ));
    }

    setState(() {
      _results = computedCoords;
    });

    // Save to local storage for Map Viewer
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('survey_points', jsonEncode(computedCoords.map((c) => c.toJson()).toList()));

    if (mounted) _showResultsModal();
  }

  void _showResultsModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Calculation Results', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final res = _results[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(res.id, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('N: ${res.n.toStringAsFixed(3)}', style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
                            Text('E: ${res.e.toStringAsFixed(3)}', style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/map');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('View on Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
              ),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.go('/computation'), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                  const SizedBox(width: 8),
                  Text('Traverse (Radiation)', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.grey)),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Station Setup
                    _buildSectionHeader('Station Setup', Icons.analytics),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[800]!)),
                      child: Column(
                        children: [
                           Row(children: [
                             Expanded(child: _buildInput('Stn Easting', _startECtrl)),
                             const SizedBox(width: 16),
                             Expanded(child: _buildInput('Stn Northing', _startNCtrl)),
                           ]),
                           const SizedBox(height: 16),
                           Row(children: [
                             Expanded(child: _buildInput('Occupied ID', _stationIdCtrl)),
                             const SizedBox(width: 16),
                             Expanded(child: _buildInput('BS Azimuth', _bsAzCtrl)),
                           ]),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Observations
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('Observations', Icons.visibility),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Text('${_obsList.length} Legs', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_obsList.isEmpty)
                      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32), decoration: BoxDecoration(border: Border.all(color: Colors.grey[800]!, style: BorderStyle.solid), borderRadius: BorderRadius.circular(12)), child: Center(child: Text('No observations yet.', style: TextStyle(color: Colors.grey[600])))),
                    
                    ..._obsList.asMap().entries.map((entry) {
                       final i = entry.key;
                       final obs = entry.value;
                       return Container(
                         margin: const EdgeInsets.only(bottom: 12),
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[800]!)),
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                              Row(children: [
                                Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), shape: BoxShape.circle), child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)))),
                                const SizedBox(width: 12),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('To: ${obs.targetId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text('Angle: ${obs.hAngle}° • Dist: ${obs.slopeDist}m', style: TextStyle(color: Colors.grey[400], fontFamily: 'monospace', fontSize: 12)),
                                ]),
                              ]),
                              IconButton(onPressed: () => _deleteLeg(obs.id), icon: const Icon(Icons.delete_outline, color: Colors.grey)),
                           ],
                         ),
                       );
                    }),

                    const SizedBox(height: 16),
                    // New Leg Input
                    Container(
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Container(width: double.infinity, color: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12), alignment: Alignment.centerRight, child: const Text('NEW SHOT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildInput('Target Point ID', _targetCtrl, placeholder: 'e.g. 1001'),
                                const SizedBox(height: 16),
                                Row(children: [
                                  Expanded(child: _buildInput('Horiz. Angle', _angleCtrl, placeholder: '0.000')),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildInput('Slope Dist.', _distCtrl, placeholder: '0.000')),
                                ]),
                                const SizedBox(height: 16),
                                SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _addLeg, icon: const Icon(Icons.add_circle), label: const Text('Add Observation'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _obsList.isEmpty ? null : _calculateTraverse, icon: const Icon(Icons.calculate), label: const Text('Calculate Coordinates'), style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.grey[300], side: BorderSide(color: Colors.grey[700]!), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(children: [Icon(icon, color: AppColors.primary, size: 20), const SizedBox(width: 8), Text(title.toUpperCase(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))]);
  }

  Widget _buildInput(String label, TextEditingController ctrl, {String? placeholder}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[700]),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}
