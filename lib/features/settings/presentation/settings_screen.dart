import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State
  String _name = 'Guest User';
  String _title = 'Surveyor';
  
  final Map<String, String> _settings = {
    'distUnit': 'Meters',
    'angleFormat': 'DMS',
    'coordSystem': 'UTM Zone 18N',
    'lastBackup': 'Today 08:00',
  };
  bool _autoSync = true;
  
  Map<String, String> _gnss = {'status': 'error', 'text': 'Not Connected'};
  Map<String, String> _ts = {'status': 'error', 'text': 'Not Connected'};
  Map<String, String> _disto = {'status': 'error', 'text': 'Not Connected'};

  String? _modalType; // 'PROFILE', 'UNIT', 'ANGLE', 'COORD', 'COORD_INFO', null

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
       _name = prefs.getString('profile_name') ?? _name;
       _title = prefs.getString('profile_title') ?? _title;
       _settings['distUnit'] = prefs.getString('setting_distUnit') ?? 'Meters';
       _settings['angleFormat'] = prefs.getString('setting_angleFormat') ?? 'DMS';
       _settings['coordSystem'] = prefs.getString('setting_coordSystem') ?? 'UTM Zone 18N';
       _autoSync = prefs.getBool('setting_autoSync') ?? true;
    });
  }

  Future<void> _saveSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('setting_$key', value);
    setState(() => _settings[key] = value);
  }

  Future<void> _saveProfile(String name, String title) async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.setString('profile_name', name);
     await prefs.setString('profile_title', title);
     setState(() {
        _name = name;
        _title = title;
        _modalType = null;
     });
  }

  void _toggleHardware(String type) {
     // Mock toggle logic
     setState(() {
        if (type == 'gnss') _gnss = _gnss['status'] == 'success' ? {'status': 'error', 'text': 'Not Connected'} : {'status': 'success', 'text': 'Connected'};
        if (type == 'ts') _ts = _ts['status'] == 'success' ? {'status': 'error', 'text': 'Not Connected'} : {'status': 'success', 'text': 'Connected'};
        if (type == 'disto') _disto = _disto['status'] == 'success' ? {'status': 'error', 'text': 'Not Connected'} : {'status': 'success', 'text': 'Connected'};
     });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'success': return Colors.greenAccent;
      case 'error': return Colors.redAccent;
      case 'warning': return Colors.orangeAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: Colors.grey[800]!))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(onPressed: () => context.go('/dashboard'), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                      Text('Settings', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 48), // Spacer
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Profile
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[800]!)),
                          child: Row(
                            children: [
                               Expanded(
                                 child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(_name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(_title, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                 ]),
                               ),
                               TextButton(onPressed: () => setState(() => _modalType = 'PROFILE'), child: const Text('EDIT', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),

                        // Unit & Coord
                        _buildSectionHeader('Units & Coordinate System'),
                        Container(
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[800]!)),
                          child: Column(
                            children: [
                               _buildSettingItem('straighten', 'Distance Unit', _settings['distUnit']!, () => setState(() => _modalType = 'UNIT')),
                               _buildDivider(),
                               _buildSettingItem('speed', 'Angle Format', _settings['angleFormat']!, () => setState(() => _modalType = 'ANGLE')),
                               _buildDivider(),
                               _buildSettingItem('grid_3x3', 'Coordinate System', _settings['coordSystem']!, () => setState(() => _modalType = 'COORD')),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Hardware
                        _buildSectionHeader('Hardware'),
                        Container(
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[800]!)),
                          child: Column(
                            children: [
                               _buildHardwareItem('satellite_alt', 'GNSS Receiver', _gnss, () => context.go('/settings/device_connection')),
                               _buildDivider(),
                               _buildHardwareItem('settings_remote', 'Total Station', _ts, () => _toggleHardware('ts')),
                               _buildDivider(),
                               _buildHardwareItem('straighten', 'Laser Distometer', _disto, () => _toggleHardware('disto')),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),

                         // Data
                        _buildSectionHeader('Data Management'),
                        Container(
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[800]!)),
                          child: Column(
                            children: [
                               Padding(
                                 padding: const EdgeInsets.all(16),
                                 child: Row(
                                   children: [
                                      const Icon(Icons.sync, color: Colors.grey),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text('Auto-Sync (Wi-Fi)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                                      Switch(
                                        value: _autoSync, 
                                        onChanged: (v) { setState(() => _autoSync = v); SharedPreferences.getInstance().then((p) => p.setBool('setting_autoSync', v)); },
                                        activeTrackColor: AppColors.primary,
                                      ),
                                   ],
                                 ),
                               ),
                               _buildDivider(),
                               _buildSettingItem('save', 'Local Backup', 'Last: ${_settings['lastBackup']}', () {}),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.remove('has_completed_onboarding');
                                await prefs.remove('active_project_id');
                                if (mounted) context.go('/onboarding');
                              },
                              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.withValues(alpha: 0.5)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text('Surveyor Pro v1.2.4 (Build 4092)', style: TextStyle(color: Colors.grey[700], fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Modals
            if (_modalType != null)
               _buildModal(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Align(alignment: Alignment.centerLeft, child: Text(title.toUpperCase(), style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1))),
    );
  }

  Widget _buildSettingItem(String icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
             Icon(iconMap[icon] ?? Icons.help, color: Colors.grey),
             const SizedBox(width: 12),
             Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
             Text(value, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
             const SizedBox(width: 8),
             Icon(Icons.chevron_right, color: Colors.grey[600], size: 18),
          ],
        ),
      ),
    );
  }
  
  // Helper for mapping material symbol names to Icons
  static const Map<String, IconData> iconMap = {
    'straighten': IconData(0xe602, fontFamily: 'MaterialIcons'), // straight ruler
    'speed': IconData(0xe5ce, fontFamily: 'MaterialIcons'),
    'grid_3x3': IconData(0xf016, fontFamily: 'MaterialIcons'), 
    'satellite_alt': IconData(0xe559, fontFamily: 'MaterialIcons'), // approximate
    'settings_remote': IconData(0xe57e, fontFamily: 'MaterialIcons'),
    'save': IconData(0xe161, fontFamily: 'MaterialIcons'),
  };

  Widget _buildHardwareItem(String icon, String label, Map<String, String> status, VoidCallback onTap) {
     return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
             Icon(iconMap[icon] ?? Icons.device_unknown, color: Colors.grey),
             const SizedBox(width: 12),
             Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
             Text(status['text']!, style: TextStyle(color: _getStatusColor(status['status']!), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, thickness: 1, color: Colors.grey[800]);

  Widget _buildModal() {
    if (_modalType == 'PROFILE') {
      final nameCtrl = TextEditingController(text: _name);
      final titleCtrl = TextEditingController(text: _title);
      return Container(
        color: Colors.black87,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[700]!)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                 const SizedBox(height: 16),
                 const Text('Full Name', style: TextStyle(color: Colors.grey, fontSize: 12)),
                 const SizedBox(height: 4),
                 TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(isDense: true, filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                 const SizedBox(height: 12),
                 const Text('Job Title', style: TextStyle(color: Colors.grey, fontSize: 12)),
                 const SizedBox(height: 4),
                 TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(isDense: true, filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                 const SizedBox(height: 24),
                 Row(children: [
                    Expanded(child: TextButton(onPressed: () => setState(() => _modalType = null), child: const Text('Cancel', style: TextStyle(color: Colors.grey)))),
                    Expanded(child: ElevatedButton(onPressed: () => _saveProfile(nameCtrl.text, titleCtrl.text), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Save', style: TextStyle(color: Colors.white)))),
                 ]),
              ],
            ),
          ),
        ),
      );
    }
    
    // Selection Modals
    List<String> options = [];
    String title = '';
    String? currentVal;
    
    if (_modalType == 'UNIT') { title = 'Select Distance Unit'; options = ['Meters', 'US Survey Feet', 'International Feet']; currentVal = _settings['distUnit']; }
    else if (_modalType == 'ANGLE') { title = 'Select Angle Format'; options = ['DMS', 'Decimal Degrees', 'Gons/Grads']; currentVal = _settings['angleFormat']; }
    else if (_modalType == 'COORD') { title = 'Select Coordinate System'; options = ['UTM Zone 18N', 'UTM Zone 19N', 'State Plane NY East', 'Local Grid', 'WGS84 Lat/Lon']; currentVal = _settings['coordSystem']; }
    
    return Container(
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
           Container(
             decoration: BoxDecoration(color: AppColors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border(top: BorderSide(color: Colors.grey[800]!))),
             padding: const EdgeInsets.all(24),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                     Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                     TextButton(onPressed: () => setState(() => _modalType = null), child: const Text('Close', style: TextStyle(color: Colors.grey))),
                  ]),
                  const SizedBox(height: 16),
                  ...options.map((opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                         if (_modalType == 'UNIT') _saveSetting('distUnit', opt);
                         if (_modalType == 'ANGLE') _saveSetting('angleFormat', opt);
                         if (_modalType == 'COORD') _saveSetting('coordSystem', opt);
                         setState(() => _modalType = null);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: currentVal == opt ? AppColors.primary.withValues(alpha: 0.2) : AppColors.background,
                          border: Border.all(color: currentVal == opt ? AppColors.primary : Colors.transparent),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                           Expanded(child: Text(opt, style: TextStyle(color: currentVal == opt ? AppColors.primary : Colors.white))),
                           if (currentVal == opt) Icon(Icons.check, color: AppColors.primary),
                        ]),
                      ),
                    ),
                  )),
               ],
             ),
           ),
        ],
      ),
    );
  }
}
