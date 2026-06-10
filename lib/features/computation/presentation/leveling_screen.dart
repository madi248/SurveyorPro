import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class LevelingScreen extends StatefulWidget {
  const LevelingScreen({super.key});

  @override
  State<LevelingScreen> createState() => _LevelingScreenState();
}

class _LevelingScreenState extends State<LevelingScreen> {
  final _elevCtrl = TextEditingController();
  final _hiCtrl = TextEditingController();
  final _htCtrl = TextEditingController();
  final _vaCtrl = TextEditingController();
  final _sdCtrl = TextEditingController();

  Map<String, String>? _result;

  @override
  void dispose() {
    _elevCtrl.dispose();
    _hiCtrl.dispose();
    _htCtrl.dispose();
    _vaCtrl.dispose();
    _sdCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() => _result = null);
    
    final elev = double.tryParse(_elevCtrl.text);
    final hi = double.tryParse(_hiCtrl.text);
    final ht = double.tryParse(_htCtrl.text);
    final va = double.tryParse(_vaCtrl.text);
    final sd = double.tryParse(_sdCtrl.text);

    if (elev == null || hi == null || ht == null || va == null || sd == null) return;

    final rad = va * (pi / 180);
    final vertComp = sd * cos(rad);
    final horizDist = sd * sin(rad);
    final targetZ = elev + hi + vertComp - ht;

    setState(() {
      _result = {
        'targetElev': targetZ.toStringAsFixed(3),
        'vertDiff': vertComp.toStringAsFixed(3),
        'horizDist': horizDist.toStringAsFixed(3),
      };
    });
    
    FocusScope.of(context).unfocus();
  }

  void _clear() {
    _elevCtrl.clear();
    _hiCtrl.clear();
    _htCtrl.clear();
    _vaCtrl.clear();
    _sdCtrl.clear();
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
                  Text('Trig Leveling', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    // Diagram
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[800]!)),
                      child: CustomPaint(painter: TrigLevelingPainter()),
                    ),
                    
                    const SizedBox(height: 24),

                    // Setup Data
                    _buildSection('Station Data', [
                       _buildInput('Station Elev (Z)', _elevCtrl),
                       _buildInput('Inst. Height (HI)', _hiCtrl),
                    ]),

                    const SizedBox(height: 16),

                    // Observation Data
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         const Text('OBSERVATION DATA', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                         const SizedBox(height: 12),
                         Row(children: [
                            Expanded(child: _buildInput('Zenith Angle (Deg)', _vaCtrl, placeholder: '90.000')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildInput('Slope Dist', _sdCtrl)),
                         ]),
                         Padding(padding: const EdgeInsets.only(top: 4, bottom: 12), child: Text('0° = Vertical Up, 90° = Horizontal', style: TextStyle(color: Colors.grey[600], fontSize: 10))),
                         SizedBox(width: (MediaQuery.of(context).size.width - 48) / 2, child: _buildInput('Target Height (HT)', _htCtrl)),
                      ],
                    ),

                    const SizedBox(height: 32),

                    SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _calculate, icon: const Icon(Icons.calculate), label: const Text('Calculate Elevation'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),

                    // Results
                    if (_result != null) ...[
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[700]!)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 20), const SizedBox(width: 8), const Text('RESULTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                            const Divider(color: Colors.grey, height: 24),
                            _buildResultRow('Target Elevation', '${_result!['targetElev']} m', isMain: true),
                            const SizedBox(height: 8),
                            _buildResultRow('Vertical Diff', '${_result!['vertDiff']} m'),
                            _buildResultRow('Horiz. Dist', '${_result!['horizDist']} m'),
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(title.toUpperCase(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
         const SizedBox(height: 12),
         Row(children: children.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w))).toList()),
      ],
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, {String? placeholder}) {
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
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[800]),
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

  Widget _buildResultRow(String label, String value, {bool isMain = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text(label, style: TextStyle(color: Colors.grey, fontWeight: isMain ? FontWeight.bold : FontWeight.normal)),
           Text(value, style: TextStyle(color: isMain ? AppColors.primary : Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: isMain ? 20 : 16)),
        ],
      ),
    );
  }
}

class TrigLevelingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;

    // Ground
    final groundPath = Path()..moveTo(0, h * 0.8)..quadraticBezierTo(w * 0.5, h * 0.75, w, h * 0.85);
    canvas.drawPath(groundPath, paint);

    // Instrument
    final instX = w * 0.2;
    final instY = h * 0.8;
    canvas.drawLine(Offset(instX, instY), Offset(instX, instY - 40), paint);
    canvas.drawCircle(Offset(instX, instY - 40), 2, Paint()..color = Colors.grey..style = PaintingStyle.fill);

    // Target
    final tgtX = w * 0.8;
    final tgtY = h * 0.82; // Approx ground at X=0.8
    canvas.drawLine(Offset(tgtX, tgtY), Offset(tgtX, tgtY - 60), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(tgtX, tgtY - 60), width: 8, height: 8), Paint()..color = Colors.grey..style = PaintingStyle.fill);

    // Sight Line
    final sightPaint = Paint()..color = AppColors.primary..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const dashWidth = 5;
    const dashSpace = 5;
    double startX = instX;
    final endX = tgtX;
    final startY = instY - 40;
    final endY = tgtY - 65; // Sight hits slightly below target top to match diagram logic? Or just direct.
    
    // Dashed line
    double distance = sqrt(pow(endX - startX, 2) + pow(endY - startY, 2));
    double dx = (endX - startX) / distance;
    double dy = (endY - startY) / distance;
    double currentDist = 0;
    while (currentDist < distance) {
       canvas.drawLine(
         Offset(startX + dx * currentDist, startY + dy * currentDist),
         Offset(startX + dx * min(currentDist + dashWidth, distance), startY + dy * min(currentDist + dashWidth, distance)),
         sightPaint
       );
       currentDist += dashWidth + dashSpace;
    }

    // Text Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    _drawText(canvas, textPainter, 'HI', Offset(instX - 15, instY - 20));
    _drawText(canvas, textPainter, 'HT', Offset(tgtX + 10, tgtY - 30));
    _drawText(canvas, textPainter, 'Slope Dist', Offset(w * 0.5, h * 0.4), color: AppColors.primary);
  }

  void _drawText(Canvas canvas, TextPainter painter, String text, Offset pos, {Color color = Colors.grey}) {
    painter.text = TextSpan(text: text, style: TextStyle(color: color, fontSize: 10));
    painter.layout();
    painter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
