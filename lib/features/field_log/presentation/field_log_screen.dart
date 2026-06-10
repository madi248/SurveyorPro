import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surveyor_pro/core/database/database_helper.dart';
import 'package:surveyor_pro/core/models/log_entry.dart';
import 'package:surveyor_pro/features/field_log/presentation/add_log_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

class FieldLogScreen extends StatefulWidget {
  const FieldLogScreen({super.key});

  @override
  State<FieldLogScreen> createState() => _FieldLogScreenState();
}

class _FieldLogScreenState extends State<FieldLogScreen> {
  List<LogEntry> _logs = [];
  bool _isLoading = true;
  int? _activeProjectId;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  // Refresh logs when returning from add screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getInt('active_project_id');
    
    if (activeId != null) {
      final logs = await DatabaseHelper.instance.getLogsForProject(activeId);
      if (mounted) {
        setState(() {
          _logs = logs;
          _activeProjectId = activeId;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _logs = [];
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAddLog() async {
     await Navigator.push(
       context,
       MaterialPageRoute(builder: (context) => const AddLogScreen()),
     );
     // Reload logs on return
     _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    if (_activeProjectId == null && !_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text('Field Log', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.go('/dashboard')),
        ),
        body: Center(
          child: Text('No active project selected.', style: TextStyle(color: Colors.grey[500])),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Field Log', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.go('/dashboard')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                itemCount: _logs.length,
                itemBuilder: (context, index) => _buildLogCard(_logs[index], index),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddLog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text('No Logs Yet', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Tap the + button to add observations', style: GoogleFonts.inter(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildLogCard(LogEntry log, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             // Timeline line and dot
             SizedBox(
               width: 24,
               child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                     Container(width: 2, color: Colors.grey[800]),
                     Container(
                       margin: const EdgeInsets.only(top: 24),
                       width: 10, height: 10, 
                       decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 2)),
                     ),
                  ],
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                 ),
                 child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                            Text(log.date, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                            const Icon(Icons.more_horiz, color: Colors.grey, size: 16),
                         ],
                       ),
                       const SizedBox(height: 8),
                       Text(log.note, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                       if (log.imagePath != null && log.imagePath!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(log.imagePath!),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 120,
                                    width: double.infinity,
                                    color: Colors.grey[900],
                                    child: const Center(child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, color: Colors.grey),
                                        SizedBox(height: 4),
                                        Text('Image not found', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                      ],
                                    )),
                                  );
                                },
                              ),
                            ),
                          ),
                    ],
                 ),
               ),
             ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms, delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
  }
}
