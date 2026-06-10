import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/database_helper.dart';
import 'package:surveyor_pro/features/leveling/domain/models/level_loop.dart';
import '../../../../core/models/project.dart';

class LevelingDashboardScreen extends StatefulWidget {
  const LevelingDashboardScreen({super.key});

  @override
  State<LevelingDashboardScreen> createState() => _LevelingDashboardScreenState();
}

class _LevelingDashboardScreenState extends State<LevelingDashboardScreen> {
  List<LevelLoop> _loops = [];
  bool _isLoading = true;
  Project? _currentProject; // In a real app we'd get this from context or state

  @override
  void initState() {
    super.initState();
    _loadLoops();
  }

  Future<void> _loadLoops() async {
    setState(() => _isLoading = true);
    // TODO: Get actual current project ID. For now hardcoding or picking first.
    // Assuming user selected a project before entering dashboard.
    // For this prototype, I'll fetch the most recent project or create a dummy one if none.
    
    final projects = await DatabaseHelper.instance.getAllProjects();
    if (projects.isNotEmpty) {
       _currentProject = projects.first;
       final loops = await DatabaseHelper.instance.getLevelLoops(_currentProject!.id!);
       setState(() {
         _loops = loops;
         _isLoading = false;
       });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createNewLoop() async {
    if (_currentProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active project found')));
      return;
    }

    final TextEditingController nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('New Level Loop', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Loop Name (e.g., Loop A)',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                final newLoop = LevelLoop(
                  projectId: _currentProject!.id!,
                  name: nameCtrl.text,
                  date: DateTime.now(),
                  status: 'open',
                );
                final id = await DatabaseHelper.instance.createLevelLoop(newLoop);
                Navigator.pop(context);
                _loadLoops(); // Refresh
                if (mounted) context.go('/computation/differential_leveling/book/$id');
              }
            },
            child: const Text('Create', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Digital Leveling', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/computation'),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _loops.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.landscape, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text('No Level Loops', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Create a new loop to start', style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _loops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final loop = _loops[index];
                    return ListTile(
                      onTap: () => context.go('/computation/differential_leveling/book/${loop.id}'),
                      tileColor: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[800]!)),
                      leading: CircleAvatar(
                        backgroundColor: loop.status == 'open' ? Colors.green.withValues(alpha: 0.2) : Colors.grey[800],
                        child: Icon(loop.status == 'open' ? Icons.edit : Icons.lock, color: loop.status == 'open' ? Colors.green : Colors.grey),
                      ),
                      title: Text(loop.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('${DateFormat('MMM d, yyyy').format(loop.date)} • ${loop.status.toUpperCase()}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewLoop,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Loop'),
      ),
    );
  }
}
