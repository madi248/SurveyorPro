import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../../core/services/bluetooth_service.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/survey_point.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:math' as math;

class StakeoutScreen extends StatefulWidget {
  final int projectId;
  
  const StakeoutScreen({super.key, required this.projectId});

  @override
  State<StakeoutScreen> createState() => _StakeoutScreenState();
}

class _StakeoutScreenState extends State<StakeoutScreen> {
  final AppBluetoothService _ble = AppBluetoothService();
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<SurveyPoint> _points = [];
  SurveyPoint? _selectedTarget;
  SurveyPoint? _currentPosition;
  StreamSubscription? _gpsSubscription;

  @override
  void initState() {
    super.initState();
    _loadPoints();
    _ble.init();
    _startGpsTracking();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPoints() async {
    final points = await _db.getPointsByProject(widget.projectId);
    setState(() => _points = points);
  }
  
  void _startGpsTracking() {
    _gpsSubscription = _ble.dataStream.listen((nmea) {
      // Parse NMEA to get current position
      // For now, we'll use a simplified approach
      // Real implementation would parse GPGGA sentences
      if (mounted) {
        setState(() {
          // This would be parsed from actual NMEA data
          // Example: _currentPosition = parsedPoint;
        });
      }
    });
  }
  
  double _calculateDistance(SurveyPoint p1, SurveyPoint p2) {
    final dx = p2.easting - p1.easting;
    final dy = p2.northing - p1.northing;
    return math.sqrt(dx * dx + dy * dy);
  }
  
  double _calculateBearing(SurveyPoint from, SurveyPoint to) {
    final dx = to.easting - from.easting;
    final dy = to.northing - from.northing;
    var bearing = math.atan2(dx, dy) * 180 / math.pi;
    if (bearing < 0) bearing += 360;
    return bearing;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stakeout Navigation'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _selectedTarget == null
          ? _buildPointList()
          : _buildNavigationView(),
    );
  }
  
  Widget _buildPointList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Target Point', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${_points.length} points available', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: _points.isEmpty
              ? const Center(child: Text('No points found. Import CSV or add points manually.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _points.length,
                  itemBuilder: (context, index) {
                    final point = _points[index];
                    final distance = _currentPosition != null 
                        ? _calculateDistance(_currentPosition!, point)
                        : null;
                    
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: Colors.blue),
                      ),
                      title: Text(point.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'E: ${point.easting.toStringAsFixed(2)}, N: ${point.northing.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: distance != null
                          ? Text('${distance.toStringAsFixed(1)}m', style: const TextStyle(color: Colors.blue))
                          : null,
                      onTap: () => setState(() => _selectedTarget = point),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildNavigationView() {
    if (_currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('Waiting for GPS...', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() => _selectedTarget = null),
              child: const Text('Back to Point List'),
            ),
          ],
        ),
      );
    }
    
    final distance = _calculateDistance(_currentPosition!, _selectedTarget!);
    final bearing = _calculateBearing(_currentPosition!, _selectedTarget!);
    final isOnTarget = distance < 0.5; // Within 0.5m tolerance
    
    return Column(
      children: [
        // Target Info
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Target', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(_selectedTarget!.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _selectedTarget = null),
              ),
            ],
          ),
        ),
        
        // Navigation Display
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Compass/Arrow
                Transform.rotate(
                  angle: bearing * math.pi / 180,
                  child: Icon(
                    Icons.arrow_upward,
                    size: 120,
                    color: isOnTarget ? Colors.green : Colors.blue,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Distance
                Text(
                  '${distance.toStringAsFixed(2)}m',
                  style: TextStyle(
                    color: isOnTarget ? Colors.green : Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isOnTarget ? 'ON TARGET' : 'Distance Remaining',
                  style: TextStyle(
                    color: isOnTarget ? Colors.green : Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Bearing
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('Bearing', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        '${bearing.toStringAsFixed(1)}°',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Mark as Staked Button
                if (isOnTarget)
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Mark point as staked (could add flag to database)
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text('Point Staked', style: TextStyle(color: Colors.white)),
                          content: Text('${_selectedTarget!.name} marked as staked', style: const TextStyle(color: Colors.grey)),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() => _selectedTarget = null);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Staked'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Current Position Info
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Position', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                'E: ${_currentPosition!.easting.toStringAsFixed(3)}  N: ${_currentPosition!.northing.toStringAsFixed(3)}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
