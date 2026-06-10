import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:surveyor_pro/core/database/database_helper.dart';
import 'package:surveyor_pro/core/models/project.dart';
import 'package:share_plus/share_plus.dart';
import 'package:surveyor_pro/core/services/export_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Project State
  Project? _project;
  // Mock tasks for now - not in DB yet
  final List<Map<String, dynamic>> _tasks = [
      {'id': 1, 'name': 'Establish Control Network', 'completed': true},
      {'id': 2, 'name': 'Boundary Verification', 'completed': true},
      {'id': 3, 'name': 'Topo Survey (Block A)', 'completed': true},
      {'id': 4, 'name': 'Stakeout Lot Corners', 'completed': false},
      {'id': 5, 'name': 'Utility Layout (Water/Sewer)', 'completed': false},
      {'id': 6, 'name': 'Final As-Built Check', 'completed': false},
  ];

  bool _isSyncing = false;
  bool _showProjectModal = false;
  bool _showReportModal = false;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getInt('active_project_id');
    
    Project? p;
    if (activeId != null) {
      p = await DatabaseHelper.instance.getProject(activeId);
    }
    
    // If project not found (e.g. deleted), we reset
    if (p == null && activeId != null) {
      prefs.remove('active_project_id');
    }

    setState(() {
      _project = p;
    });
  }
  
  void _handleSync() {
    setState(() => _isSyncing = true);
    Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isSyncing = false);
    });
  }

  void _toggleTask(int id) {
     setState(() {
        final index = _tasks.indexWhere((t) => t['id'] == id);
        if (index != -1) {
           _tasks[index]['completed'] = !_tasks[index]['completed'];
        }
     });
  }

  @override
  Widget build(BuildContext context) {
    if (_project == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(Icons.assignment_add, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
               const SizedBox(height: 24),
               const Text('No Active Project', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
               const SizedBox(height: 8),
               Text('Create or select a project to begin', style: TextStyle(color: Colors.grey[400])),
               const SizedBox(height: 32),
               ElevatedButton(
                 onPressed: () => context.push('/projects'),
                 style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                 child: const Text('Go to Projects', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               ),
            ],
          ),
        ),
      );
    }
    
    final tasks = _tasks;
    final completed = tasks.where((t) => t['completed']).length;
    final total = tasks.length;
    final progress = total == 0 ? 0.0 : (completed / total);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               color: Colors.grey[700],
                            ),
                            child: const Icon(Icons.person_outline, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Good Morning,', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              const Text('Guest User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                           IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined, color: Colors.grey)),
                           IconButton(
                             onPressed: _handleSync, 
                             icon: Icon(Icons.sync, color: _isSyncing ? AppColors.primary : Colors.grey),
                           ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Project
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             const Text('CURRENT PROJECT', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                             TextButton(
                               onPressed: () => context.push('/projects'),
                               child: const Text('SWITCH', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10)),
                             ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showProjectModal = true),
                          child: Container(
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[800]!)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Container(
                                   padding: const EdgeInsets.all(20),
                                   decoration: const BoxDecoration(
                                     border: Border(bottom: BorderSide(color: Colors.transparent)), // removed border
                                   ),
                                   child: Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                             Text(_project!.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                             const SizedBox(height: 4),
                                             Row(children: [
                                                const Icon(Icons.grid_3x3, color: AppColors.primary, size: 14),
                                                const SizedBox(width: 4),
                                                Text(_project!.jobId, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                             ]),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                                          child: const Text('Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                     ],
                                   ),
                                 ),
                                 
                                 // Details
                                 Padding(
                                   padding: const EdgeInsets.symmetric(horizontal: 20),
                                   child: Column(children: [
                                      _buildProjectDetail(Icons.business, _project!.client),
                                      const SizedBox(height: 8),
                                      _buildProjectDetail(Icons.location_on, _project!.location),
                                   ]),
                                 ),
                                 const SizedBox(height: 20),
                                 
                                 // Progress
                                 LinearProgressIndicator(value: progress, backgroundColor: AppColors.background, color: AppColors.primary, minHeight: 4),
                                 Padding(
                                   padding: const EdgeInsets.all(12),
                                   child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text('${(progress*100).toInt()}% Complete', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                      Text('$completed/$total Tasks', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                   ]),
                                 ),
                              ],
                            ),
                          )).animate().fade(duration: 500.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: 24),

                        // Pillars
                        const Text('OPERATIONAL PILLARS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 12),
                        GridView.count(
                           shrinkWrap: true,
                           physics: const NeverScrollableScrollPhysics(),
                           crossAxisCount: 2,
                           mainAxisSpacing: 12,
                           crossAxisSpacing: 12,
                           childAspectRatio: 1.4,
                           children: [
                              _buildPillar(Icons.calculate_outlined, 'Run Calculations', 'Process field points & adjustments', AppColors.primary, () => context.go('/computation')),
                              _buildPillar(Icons.upload_file_outlined, 'Import CSV', 'Load total station data', Colors.blue, () => context.push('/dashboard/import?projectId=${_project!.id}')),
                              _buildPillar(Icons.list_alt_outlined, 'View Field Log', 'Review daily site entries', Colors.green, () => context.push('/field_log')),
                              _buildPillar(Icons.map_outlined, 'Open CAD Map', 'Interactive layout viewer', Colors.purple, () => context.go('/map')),
                              _buildPillar(Icons.ios_share, 'Generate Reports', 'Export CSV/PDF datasets', Colors.orange, () => setState(() => _showReportModal = true)),
                           ].animate(interval: 100.ms).fade(duration: 500.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
                        ),

                        const SizedBox(height: 24),

                        const SizedBox(height: 24),

                        // Suggestion replacement: Recent Activity
                        const Text('RECENT FIELD ACTIVITY', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 12),
                        Container(
                           width: double.infinity,
                           padding: const EdgeInsets.all(24),
                           decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[800]!)),
                           child: Column(
                             children: [
                                Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[600]),
                                const SizedBox(height: 12),
                                Text('No recent activity recorded', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                             ],
                           ),
                        ).animate().fade(duration: 500.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Project Modal
            if (_showProjectModal)
              Container(
                color: Colors.black87,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                     Container(
                       height: MediaQuery.of(context).size.height * 0.85,
                       decoration: BoxDecoration(color: AppColors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border(top: BorderSide(color: Colors.grey[800]!))),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                 const Text('Active Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                                 IconButton(onPressed: () => setState(() => _showProjectModal = false), icon: const Icon(Icons.close, color: Colors.grey)),
                              ]),
                            ),
                            
                            // Task List
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                children: [
                                   const SizedBox(height: 24),
                                   const Text('MILESTONE CHECKLIST', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                                   const SizedBox(height: 12),
                                   ...tasks.map<Widget>((t) => 
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: InkWell(
                                          onTap: () => _toggleTask(t['id']),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: t['completed'] ? Colors.green.withValues(alpha: 0.1) : AppColors.surface,
                                              border: Border.all(color: t['completed'] ? Colors.green.withValues(alpha: 0.3) : Colors.grey[800]!),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                 Container(
                                                   width: 24, height: 24,
                                                   decoration: BoxDecoration(color: t['completed'] ? Colors.green : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: t['completed'] ? Colors.green : Colors.grey)),
                                                   child: t['completed'] ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                                                 ),
                                                 const SizedBox(width: 12),
                                                 Expanded(child: Text(t['name'], style: TextStyle(color: t['completed'] ? Colors.grey : Colors.white, decoration: t['completed'] ? TextDecoration.lineThrough : null))),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                   ).toList(),
                                ],
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => setState(() => _showProjectModal = false), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                            ),
                         ],
                       ),
                     ),
                  ],
                ),
              ),

             // Report Modal
             if (_showReportModal)
               Container(
                  color: Colors.black87,
                  child: Center(
                    child: Container(
                       margin: const EdgeInsets.all(32),
                       padding: const EdgeInsets.all(24),
                       decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[700]!)),
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                               const Text('Generate Field Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                               IconButton(onPressed: () => setState(() => _showReportModal = false), icon: const Icon(Icons.close, color: Colors.grey)),
                            ]),
                            const SizedBox(height: 24),
                            _buildReportOption(Icons.picture_as_pdf, 'PDF Report', 'Best for printing & sharing', Colors.red, () => _handleExport('pdf')),
                            const SizedBox(height: 12),
                            _buildReportOption(Icons.table_chart, 'CSV / Excel', 'Best for CAD import', Colors.green, () => _handleExport('csv')),
                         ],
                       ),
                    ),
                  ),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillar(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[800]!)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Container(
               width: 36, height: 36,
               decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
               child: Icon(icon, color: color, size: 20),
             ),
             const Spacer(),
             Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
             Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 10, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }



  Future<void> _handleExport(String type) async {
    if (_project == null) return;
    
    // Close modal first
    setState(() => _showReportModal = false);
    
    // Show loading
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generating $type report...')));
    
    try {
      final exportService = ExportService();
      XFile? file;
      
      if (type == 'csv') {
        final points = await DatabaseHelper.instance.getPointsForProject(_project!.id!);
        if (points.isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No points to export')));
           return;
        }
        final f = await exportService.generatePointsCSV(_project!, points);
        file = XFile(f.path);
      } else {
        final logs = await DatabaseHelper.instance.getLogsForProject(_project!.id!);
        if (logs.isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No logs to export')));
           return;
        }
        final f = await exportService.generateFieldReportPDF(_project!, logs);
        file = XFile(f.path);
      }
      
      await Share.shareXFiles([file], text: '${_project!.name} $type Export');
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Widget _buildReportOption(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[700]!), borderRadius: BorderRadius.circular(12), color: Colors.transparent),
        child: Row(
          children: [
             Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
             const SizedBox(width: 12),
             Expanded(
               child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
               ]),
             ),
             Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProjectDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }
}
