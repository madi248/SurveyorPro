import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:surveyor_pro/core/database/database_helper.dart';
import 'package:surveyor_pro/core/models/log_entry.dart';
import 'package:surveyor_pro/core/theme/app_theme.dart';

class AddLogScreen extends StatefulWidget {
  const AddLogScreen({super.key});

  @override
  State<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends State<AddLogScreen> {
  final _noteCtrl = TextEditingController();
  bool _isSaving = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveLog() async {
    if (_noteCtrl.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a note or add an image')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getInt('active_project_id');

    if (activeId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active project found')),
        );
        setState(() => _isSaving = false);
      }
      return;
    }

    // Capture standard format date
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}';
    
    String? savedImagePath;
    
    // Save image to app documents
    if (_selectedImage != null) {
       try {
         final appDir = await getApplicationDocumentsDirectory();
         final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
         final savedImage = await _selectedImage!.copy(path.join(appDir.path, fileName));
         savedImagePath = savedImage.path;
       } catch (e) {
         debugPrint('Error saving image: $e');
         // Continue without image or show error?
         // For now, continue but maybe warn
       }
    }

    final newLog = LogEntry(
      projectId: activeId,
      date: dateStr,
      note: _noteCtrl.text.trim(),
      imagePath: savedImagePath, 
    );

    await DatabaseHelper.instance.createLog(newLog);

    if (mounted) {
      context.pop(); // Return to previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Add Field Log', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Field Notes', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: TextField(
                controller: _noteCtrl,
                maxLines: 6,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Enter observation details here...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Attachments', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400])),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!, style: BorderStyle.solid), 
                  image: _selectedImage != null 
                     ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover, opacity: 0.5)
                     : null,
                ),
                child: Column(
                  children: [
                    if (_selectedImage == null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Text('Tap to add photos', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
                    ] else ...[
                       const Icon(Icons.check_circle, color: Colors.greenAccent, size: 48),
                       const SizedBox(height: 8),
                       Text('Image Selected', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                       Text('Tap to change', style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Save Entry', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
