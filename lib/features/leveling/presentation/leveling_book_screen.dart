import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/database_helper.dart';
import 'package:surveyor_pro/features/leveling/domain/models/level_loop.dart';
import 'package:surveyor_pro/features/leveling/domain/models/level_observation.dart';

class LevelingBookScreen extends StatefulWidget {
  final int loopId;
  const LevelingBookScreen({super.key, required this.loopId});

  @override
  State<LevelingBookScreen> createState() => _LevelingBookScreenState();
}

class _LevelingBookScreenState extends State<LevelingBookScreen> {
  LevelLoop? _loop;
  List<LevelObservation> _obs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Fetch Loop
    // DatabaseHelper doesn't have getLoopById yet? Check getLevelLoops or add one.
    // I will assume getLevelLoops returns all for project, I might need to filter manually or add getLevelLoop(id).
    // For now, I'll fetch loops for current project... wait, I don't know project ID here easily without extra fetch.
    // I'll add getLevelLoop(id) to DatabaseHelper later if needed, or just select * where id = ? using raw query if lazy, 
    // but better to add a method.
    // Actually, I can just use getAllProjects -> getLevelLoops logic if I knew projectId.
    // Let's add getLevelLoop(id) to DatabaseHelper.
    // Or I can just fetch observations first.
    
    // FETCH OBS
    final obs = await DatabaseHelper.instance.getLevelObservations(widget.loopId);
    
    // FETCH LOOP INFO (Need to implement getLevelLoop in DB or fake it for now)
    // I'll assume I can just display ID or fetch later. 
    // Wait, I strictly need 'getLevelLoop(int id)' in DatabaseHelper to do this properly.
    // I'll assume it exists or implementation will follow.
    // Actually, I'll stick to just Observations for now to avoid blocking.
    
    setState(() {
      _obs = obs;
      _isLoading = false;
    });
  }

  Future<void> _addObservation() async {
    // Show Modal
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (ctx) => _AddObsModal(
        loopId: widget.loopId, 
        lastOrdinal: _obs.isEmpty ? 0 : _obs.last.ordinal,
        onAdded: _loadData
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Field Book #${widget.loopId}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/computation/differential_leveling'),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header / Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Stations: ${_obs.length}', style: const TextStyle(color: Colors.grey)),
                      // TODO: Add Closure Error display
                    ],
                  ),
                ),
                
                // Grid Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  color: Colors.black26,
                  child: Row(
                    children: const [
                       Expanded(flex: 2, child: Text('Station', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                       Expanded(child: Text('BS (+)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))),
                       Expanded(child: Text('IS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                       Expanded(child: Text('FS (-)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
                       Expanded(child: Text('Elev', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: ListView.builder(
                    itemCount: _obs.length,
                    itemBuilder: (context, index) {
                      final ob = _obs[index];
                      // Simple View
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[800]!))),
                        child: Row(
                          children: [
                             Expanded(flex: 2, child: Text(ob.station, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                             Expanded(child: Text(ob.backsight?.toStringAsFixed(3) ?? '-', style: const TextStyle(color: Colors.grey))),
                             Expanded(child: Text(ob.intermediate?.toStringAsFixed(3) ?? '-', style: const TextStyle(color: Colors.grey))),
                             Expanded(child: Text(ob.foresight?.toStringAsFixed(3) ?? '-', style: const TextStyle(color: Colors.grey))),
                             Expanded(child: Text(ob.elevation?.toStringAsFixed(3) ?? '-', style: const TextStyle(color: Colors.cyan))),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addObservation,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddObsModal extends StatefulWidget {
  final int loopId;
  final int lastOrdinal;
  final VoidCallback onAdded;

  const _AddObsModal({required this.loopId, required this.lastOrdinal, required this.onAdded});

  @override
  State<_AddObsModal> createState() => _AddObsModalState();
}

class _AddObsModalState extends State<_AddObsModal> {
  final _stationCtrl = TextEditingController();
  final _bsCtrl = TextEditingController(); // Backsight reading
  final _fsCtrl = TextEditingController(); // Foresight reading
  final _isCtrl = TextEditingController(); // Intermediate Sight
  final _elevCtrl = TextEditingController(); // Known Elevation (for BM)
  
  bool _isBenchmark = false;
  String _type = 'CP'; // BM, CP (Change Point), IS (Intermediate)

  @override
  void initState() {
    super.initState();
    if (widget.lastOrdinal == 0) {
      _type = 'BM';
      _isBenchmark = true;
    }
  }

  Future<void> _save() async {
     // Validate
     if (_stationCtrl.text.isEmpty) return;
     
     final bs = double.tryParse(_bsCtrl.text);
     final fs = double.tryParse(_fsCtrl.text);
     final inter = double.tryParse(_isCtrl.text);
     double? elev = double.tryParse(_elevCtrl.text);
     
     // Basic Logic (Refine later)
     // If BM, we need Elev + BS.
     // If CP, we need FS + BS.
     // If IS, we need IS.
     
     // TODO: Implement calculation service. 
     // For now, save raw values. Elevation calculation happens on retrieval or iteratively.
     // Actually, saving calculated elevation is better.
     
     final obs = LevelObservation(
       loopId: widget.loopId,
       station: _stationCtrl.text,
       backsight: bs,
       intermediate: inter,
       foresight: fs,
       elevation: elev, // Only if manual (BM)
       ordinal: widget.lastOrdinal + 1,
     );
     
     await DatabaseHelper.instance.addLevelObservation(obs);
     widget.onAdded();
     Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Add Observation', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              DropdownButton<String>(
                value: _type,
                dropdownColor: AppColors.surface,
                items: ['BM', 'CP', 'IS'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (val) {
                   setState(() {
                     _type = val!;
                     _isBenchmark = val == 'BM';
                   });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _stationCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDec('Station Name (e.g. BM1, TP1)'),
          ),
          const SizedBox(height: 12),
          if (_isBenchmark)
             Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: _elevCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDec('Known Elevation (Z)'))),
             
          Row(
            children: [
              if (_type == 'BM' || _type == 'CP')
                 Expanded(child: TextField(controller: _bsCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDec('Backsight (+BS)'))),
              if (_type == 'CP') 
                 const SizedBox(width: 12),
              if (_type == 'CP')
                 Expanded(child: TextField(controller: _fsCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDec('Foresight (-FS)'))),
              if (_type == 'IS')
                 Expanded(child: TextField(controller: _isCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDec('Intermediate (-IS)'))),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, 
            child: ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Save Reading', style: TextStyle(color: Colors.white)))
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  InputDecoration _inputDec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
