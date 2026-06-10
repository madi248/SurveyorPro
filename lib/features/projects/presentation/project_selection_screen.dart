import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:surveyor_pro/core/database/database_helper.dart';
import 'package:surveyor_pro/core/models/project.dart';

class ProjectSelectionScreen extends StatefulWidget {
  const ProjectSelectionScreen({super.key});

  @override
  State<ProjectSelectionScreen> createState() => _ProjectSelectionScreenState();
}

class _ProjectSelectionScreenState extends State<ProjectSelectionScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await DatabaseHelper.instance.getAllProjects();
    
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }

  Future<void> _handleSelectProject(Project project) async {
    final prefs = await SharedPreferences.getInstance();
    // Save ID for dashboard retrieval
    await prefs.setInt('active_project_id', project.id!);
    if (mounted) context.go('/dashboard');
  }

  Future<void> _createProject(Project newProject) async {
    await DatabaseHelper.instance.createProject(newProject);
    await _loadProjects(); // Reload to get the new project with ID
    
    // Mark onboarding as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    
    // Auto-select the most recently created (which should be last or first depending on sort)
    // getAllProjects sorts by lastModified DESC, so it should be first.
    final projects = await DatabaseHelper.instance.getAllProjects();
    if (projects.isNotEmpty) {
      _handleSelectProject(projects.first);
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateProjectDialog(onCreate: _createProject),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Projects', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Select a workspace to begin', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400])),
                ],
              ),
            ),
            
            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _projects.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        if (index == _projects.length) {
                          return _buildNewProjectButton();
                        }
                        return _buildProjectCard(_projects[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project p) {
    return GestureDetector(
      onTap: () => _handleSelectProject(p),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (p.status == 'Active')
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(64)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.jobId,
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(p.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(p.client, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
                          ],
                        ),
                      ),
                      Icon(
                        p.status == 'Completed' ? Icons.check_circle : Icons.chevron_right,
                        color: p.status == 'Completed' ? Colors.green : Colors.grey[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.location, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
                      Text('Last modified: ${_formatDate(p.lastModified)}', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.0, // Initial progress 0 as per request
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation(p.status == 'Completed' ? Colors.green : AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildNewProjectButton() {
    return GestureDetector(
      onTap: _showCreateDialog,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!, style: BorderStyle.solid), // Dashed border needs custom painter, falling back to solid grey for MVP or check functionality
        ),
        // To strictly match prototype dashed border, we'd use CustomPaint. For now solid dark grey is close enough functionality wise.
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text('Create New Project', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class CreateProjectDialog extends StatefulWidget {
  final Function(Project) onCreate;
  const CreateProjectDialog({super.key, required this.onCreate});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _nameCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _locCtrl = TextEditingController();

  void _submit() {
    if (_nameCtrl.text.isEmpty || _clientCtrl.text.isEmpty) return;
    
    final p = Project(
      jobId: _idCtrl.text.isNotEmpty ? _idCtrl.text : '#${10000 + Random().nextInt(90000)}',
      name: _nameCtrl.text,
      client: _clientCtrl.text,
      location: _locCtrl.text.isNotEmpty ? _locCtrl.text : 'Unknown Location',
      lastModified: DateTime.now(),
      status: 'Active',
    );
    widget.onCreate(p);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('New Project', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 16),
            _buildInput('Project Name', _nameCtrl, 'e.g. Riverfront Park'),
            const SizedBox(height: 12),
            _buildInput('Client Name', _clientCtrl, 'e.g. City Dept'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInput('Job ID (Opt)', _idCtrl, '#12345')),
                const SizedBox(width: 12),
                Expanded(child: _buildInput('Location', _locCtrl, 'City/Zone')),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create & Open'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500])),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[700]),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[800]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[800]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
