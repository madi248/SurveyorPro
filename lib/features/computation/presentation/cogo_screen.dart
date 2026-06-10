import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class CogoScreen extends StatefulWidget {
  final bool isForward;
  const CogoScreen({super.key, required this.isForward});

  @override
  State<CogoScreen> createState() => _CogoScreenState();
}

class _CogoScreenState extends State<CogoScreen> {
  // Common
  final _n1Ctrl = TextEditingController();
  final _e1Ctrl = TextEditingController();
  
  // Inverse specific
  final _n2Ctrl = TextEditingController();
  final _e2Ctrl = TextEditingController();

  // Forward specific
  final _azCtrl = TextEditingController();
  final _distCtrl = TextEditingController();

  Map<String, String>? _result;

  @override
  void dispose() {
    _n1Ctrl.dispose();
    _e1Ctrl.dispose();
    _n2Ctrl.dispose();
    _e2Ctrl.dispose();
    _azCtrl.dispose();
    _distCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() => _result = null);
    
    final n1 = double.tryParse(_n1Ctrl.text);
    final e1 = double.tryParse(_e1Ctrl.text);

    if (n1 == null || e1 == null) return;

    if (widget.isForward) {
      // Forward
      final az = double.tryParse(_azCtrl.text);
      final dist = double.tryParse(_distCtrl.text);
      if (az == null || dist == null) return;

      final rad = az * (pi / 180);
      final n2 = n1 + dist * cos(rad);
      final e2 = e1 + dist * sin(rad);
      
      setState(() {
        _result = {
          'New Northing': n2.toStringAsFixed(3),
          'New Easting': e2.toStringAsFixed(3),
        };
      });

    } else {
      // Inverse
      final n2 = double.tryParse(_n2Ctrl.text);
      final e2 = double.tryParse(_e2Ctrl.text);
      if (n2 == null || e2 == null) return;

      final dN = n2 - n1;
      final dE = e2 - e1;
      final dist = sqrt(dN * dN + dE * dE);
      
      double theta = atan2(dE, dN);
      if (theta < 0) theta += 2 * pi;

      final degDec = theta * (180 / pi);
      final d = degDec.floor();
      final mDec = (degDec - d) * 60;
      final m = mDec.floor();
      final s = ((mDec - m) * 60).round();

      setState(() {
        _result = {
          'Dist': dist.toStringAsFixed(3),
          'Azimuth': '$d° ${m.toString().padLeft(2, '0')}\' ${s.toString().padLeft(2, '0')}"',
          'AzDec': degDec.toStringAsFixed(4),
        };
      });
    }
    
    FocusScope.of(context).unfocus();
  }

  void _clear() {
    _n1Ctrl.clear();
    _e1Ctrl.clear();
    _n2Ctrl.clear();
    _e2Ctrl.clear();
    _azCtrl.clear();
    _distCtrl.clear();
    setState(() => _result = null);
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
              decoration: BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: Colors.grey[800]!))),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.go('/computation'), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                  const SizedBox(width: 8),
                  Text(widget.isForward ? 'COGO Forward' : 'Inverse Calc', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  IconButton(onPressed: _clear, icon: const Icon(Icons.refresh, color: Colors.white)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Start Point
                    _buildSection('Start Point', [
                       _buildInput('Northing', _n1Ctrl),
                       _buildInput('Easting', _e1Ctrl),
                    ], Icons.trip_origin, Colors.blue),
                    
                    const SizedBox(height: 24),

                    // Target / Params
                    if (widget.isForward)
                       _buildSection('Parameters', [
                         _buildInput('Azimuth (Deg)', _azCtrl),
                         _buildInput('Distance (m)', _distCtrl),
                       ], Icons.straighten, Colors.orange)
                    else
                       _buildSection('End Point', [
                         _buildInput('Northing', _n2Ctrl),
                         _buildInput('Easting', _e2Ctrl),
                       ], Icons.flag, Colors.green),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate),
                        label: Text(widget.isForward ? 'Calculate Coordinates' : 'Calculate Inverse'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    // Results
                    if (_result != null) ...[
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[700]!)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                               const Icon(Icons.check_circle, color: Colors.green, size: 20),
                               const SizedBox(width: 8),
                               const Text('RESULTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ]),
                            const Divider(color: Colors.grey, height: 24),
                            if (widget.isForward) ...[
                               _buildResultRow('New Northing', _result!['New Northing']!),
                               _buildResultRow('New Easting', _result!['New Easting']!),
                            ] else ...[
                               _buildResultRow('Grid Azimuth', _result!['Azimuth']!),
                               _buildResultRow('Horiz. Dist', '${_result!['Dist']} m'),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title.toUpperCase(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
         ]),
         const SizedBox(height: 12),
         Row(
           children: children.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w))).toList(),
         ),
      ],
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[700]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text(label, style: const TextStyle(color: Colors.grey)),
           Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 16)),
        ],
      ),
    );
  }
}
