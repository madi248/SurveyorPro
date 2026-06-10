import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../../../../core/theme/app_theme.dart';
import 'package:surveyor_pro/core/database/database_helper.dart';
import 'package:surveyor_pro/core/models/survey_point.dart';
import 'package:surveyor_pro/core/utils/geometry_utils.dart';
import 'package:surveyor_pro/core/services/dxf_service.dart';
import 'package:surveyor_pro/core/services/bluetooth_service.dart';
import 'package:surveyor_pro/core/services/nmea_parser.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:surveyor_pro/features/computation/presentation/intersection_modal.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TransformationController _transformController = TransformationController();
  List<SurveyPoint> _points = [];
  List<Map<String, dynamic>> _features = []; // Loaded linework
  bool _showAddModal = false;
  
  // Inverse Tool State
  bool _isInverseMode = false;
  SurveyPoint? _inverseStart;
  SurveyPoint? _inverseEnd;
  double? _inverseDist;
  double? _inverseBearing;

  // Linework State
  bool _isLineworkMode = false;
  List<SurveyPoint> _pendingChain = [];

  // Area Tool State
  bool _isAreaMode = false;
  List<SurveyPoint> _areaPoints = [];
  double _currentArea = 0.0;
  List<List<Offset>> _dxfPolylines = []; // Background DXF
  bool _isWorldView = false; // Toggle for OSM
  
  // GNSS State
  final _ble = AppBluetoothService();
  final _nmea = NmeaParser();
  SurveyPoint? _userPosition; // For Bluetooth GNSS in Grid View
  Position? _deviceGpsPosition; // For device GPS in World View only
  bool _followGps = false;


  // Edit Point State
  bool _showEditModal = false;
  SurveyPoint? _selectedPoint;
  final _newIdCtrl = TextEditingController();
  final _newNCtrl = TextEditingController();
  final _newECtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _initGnss();
  }

  void _initGnss() async {
     // Listen to Bluetooth GNSS
     _ble.dataStream.listen((data) {
        final point = _nmea.parseLine(data);
        if (point != null) {
           setState(() {
              _userPosition = point;
              if (_followGps) {
                 // Auto-center (simple translation for now)
                 // NOTE: Real world would need Projection (LatLon -> UTM) to match _points
              }
           });
        }
     });
     
     // Also try to get device GPS
     try {
       final permission = await Geolocator.checkPermission();
       if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
         await Geolocator.requestPermission();
       }
       
       Geolocator.getPositionStream(
         locationSettings: const LocationSettings(
           accuracy: LocationAccuracy.high,
           distanceFilter: 1,
         ),
       ).listen((Position position) {
         // Save device GPS position for World View only
         if (mounted) {
           setState(() {
             _deviceGpsPosition = position;
           });
         }
       });
     } catch (e) {
       print('GPS Error: $e');
     }
  }

  @override
  void dispose() {
    _transformController.dispose();
    _newIdCtrl.dispose();
    _newNCtrl.dispose();
    _newECtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getInt('active_project_id');
    
    if (activeId == null) return;

    final points = await DatabaseHelper.instance.getPointsForProject(activeId);
    final features = await DatabaseHelper.instance.getProjectFeatures(activeId);
    
    setState(() {
      _points = points;
      _features = features;
    });
    
    if (_points.isNotEmpty && _transformController.value.isIdentity()) {
       WidgetsBinding.instance.addPostFrameCallback((_) => _zoomToExtents());
    }
  }

  void _zoomToExtents() {
    if (_points.isEmpty) return;
    
    double minN = _points.first.northing;
    double maxN = minN;
    double minE = _points.first.easting;
    double maxE = minE;

    for (var p in _points) {
      if (p.northing < minN) minN = p.northing;
      if (p.northing > maxN) maxN = p.northing;
      if (p.easting < minE) minE = p.easting;
      if (p.easting > maxE) maxE = p.easting;
    }

    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    
    final spanN = maxN - minN;
    final spanE = maxE - minE;
    
    final buffer = max(spanN, spanE) * 0.2;
    final safeSpanN = spanN == 0 ? 100.0 : spanN + buffer;
    final safeSpanE = spanE == 0 ? 100.0 : spanE + buffer;

    final scaleY = screenH / safeSpanN;
    final scaleX = screenW / safeSpanE;
    final scale = min(scaleX, scaleY) * 0.8;

    final centerN = (minN + maxN) / 2;
    final centerE = (minE + maxE) / 2;

    _transformController.value = Matrix4.identity()
      ..translate(screenW / 2, screenH / 2)
      ..scale(scale, -scale, 1.0)
      ..translate(-centerE, -centerN);
  }

  void _fitToScreen() {
    if (_points.isEmpty) return;
    
    // Calculate bounds
    double minE = _points.first.easting;
    double maxE = _points.first.easting;
    double minN = _points.first.northing;
    double maxN = _points.first.northing;
    
    for (var p in _points) {
      if (p.easting < minE) minE = p.easting;
      if (p.easting > maxE) maxE = p.easting;
      if (p.northing < minN) minN = p.northing;
      if (p.northing > maxN) maxN = p.northing;
    }
    
    // Calculate center
    final centerE = (minE + maxE) / 2;
    final centerN = (minN + maxN) / 2;
    
    // Calculate required scale
    final screenSize = MediaQuery.of(context).size;
    final pointRangeE = maxE - minE;
    final pointRangeN = maxN - minN;
    
    final scaleE = pointRangeE > 0 ? screenSize.width / (pointRangeE * 1.2) : 1.0;
    final scaleN = pointRangeN > 0 ? screenSize.height / (pointRangeN * 1.2) : 1.0;
    final newScale = scaleE < scaleN ? scaleE : scaleN;
    
    setState(() {
      _transformController.value = Matrix4.identity()
        ..scale(newScale, -newScale)
        ..translate(-centerE, -centerN);
    });
  }

  Future<void> _handlePointTap(SurveyPoint p) async {
    if (_isInverseMode) {
      _handleInverseTap(p);
    } else if (_isLineworkMode) {
      setState(() {
        if (!_pendingChain.contains(p)) { 
             _pendingChain.add(p);
        }
      });
    } else if (_isAreaMode) {
      setState(() {
         // Allow closing the polygon by tapping first point? Or just add all
         if (!_areaPoints.contains(p)) {
            _areaPoints.add(p);
            _calculateArea();
         }
      });
    } else {
      _openEditModal(p);
    }
  }

  Future<void> _saveChain() async {
    if (_pendingChain.length < 2) return;
    
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getInt('active_project_id');
    if (activeId == null) return;

    await DatabaseHelper.instance.createMapFeature(
      activeId, 
      'Line ${_features.length + 1}', 
      'polyline', 
      Colors.cyanAccent.value, 
      _pendingChain.map((p) => p.id!).toList()
    );

    setState(() {
      _pendingChain.clear();
      _isLineworkMode = false;
    });
    
    await _loadData();
  }

  void _calculateArea() {
    if (_areaPoints.length < 3) {
       _currentArea = 0.0;
       return;
    }
    final vectors = _areaPoints.map((p) => vector.Vector2(p.easting, p.northing)).toList();
    _currentArea = GeometryUtils.calculatePolygonArea(vectors);
  }

  Future<void> _importDxf() async {
    final polylines = await DxfService().pickAndParseDxf();
    if (polylines != null) {
      setState(() {
        _dxfPolylines = polylines;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${polylines.length} DXF entities')));
    }
  }

  void _handleInverseTap(SurveyPoint p) {
    setState(() {
      if (_inverseStart == null) {
        _inverseStart = p;
        _inverseEnd = null;
        _inverseDist = null;
        _inverseBearing = null;
      } else if (_inverseEnd == null) {
        _inverseEnd = p;
        _calculateInverse();
      } else {
        _inverseStart = p;
        _inverseEnd = null;
        _inverseDist = null;
        _inverseBearing = null;
      }
    });
  }

  void _calculateInverse() {
    if (_inverseStart == null || _inverseEnd == null) return;
    
    final dn = _inverseEnd!.northing - _inverseStart!.northing;
    final de = _inverseEnd!.easting - _inverseStart!.easting;
    
    final dist = sqrt(dn*dn + de*de);
    var bearing = atan2(de, dn);
    
    if (bearing < 0) bearing += 2 * pi;
    final bearingDeg = bearing * 180 / pi;

    setState(() {
      _inverseDist = dist;
      _inverseBearing = bearingDeg;
    });
  }

  void _openEditModal(SurveyPoint p) {
    _selectedPoint = p;
    _newIdCtrl.text = p.name;
    _newNCtrl.text = p.northing.toStringAsFixed(3);
    _newECtrl.text = p.easting.toStringAsFixed(3);
    _descCtrl.text = p.description;
    setState(() => _showEditModal = true);
  }

  Future<void> _updatePoint() async {
    if (_selectedPoint == null) return;
    
    final n = double.tryParse(_newNCtrl.text);
    final e = double.tryParse(_newECtrl.text);
    if (_newIdCtrl.text.isEmpty || n == null || e == null) return;

    final updated = SurveyPoint(
      id: _selectedPoint!.id,
      projectId: _selectedPoint!.projectId,
      name: _newIdCtrl.text,
      northing: n,
      easting: e,
      description: _descCtrl.text,
      type: _selectedPoint!.type,
    );

    await DatabaseHelper.instance.deletePoint(_selectedPoint!.id!);
    await DatabaseHelper.instance.createPoint(updated);

    await _loadData();
    setState(() => _showEditModal = false);
  }

  Future<void> _deletePoint() async {
    if (_selectedPoint == null) return;
    await DatabaseHelper.instance.deletePoint(_selectedPoint!.id!);
    await _loadData();
    setState(() => _showEditModal = false);
  }

  Future<void> _addPoint() async {
      final n = double.tryParse(_newNCtrl.text);
      final e = double.tryParse(_newECtrl.text);
      if (_newIdCtrl.text.isEmpty || n == null || e == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final activeId = prefs.getInt('active_project_id');
      if (activeId == null) return;
      
      final newPoint = SurveyPoint(
        projectId: activeId,
        name: _newIdCtrl.text,
        northing: n,
        easting: e,
        description: _descCtrl.text.isEmpty ? 'MANUAL' : _descCtrl.text,
        type: 'side_shot',
      );
      
      await DatabaseHelper.instance.createPoint(newPoint);
      _newIdCtrl.clear();
      _newNCtrl.clear();
      _newECtrl.clear();
      _descCtrl.clear();
      
      await _loadData();
      
      setState(() {
          _showAddModal = false;
      });
  }

  void _zoom(bool zoomIn) {
      final screenW = MediaQuery.of(context).size.width;
      final screenH = MediaQuery.of(context).size.height;
      final center = Offset(screenW/2, screenH/2);
      final matrix = _transformController.value;
      
      final s = zoomIn ? 1.2 : 0.8;
      
      final newMatrix = Matrix4.translationValues(center.dx, center.dy, 0.0)
        ..multiply(Matrix4.diagonal3Values(s, s, 1.0))
        ..multiply(Matrix4.translationValues(-center.dx, -center.dy, 0.0))
        ..multiply(matrix);
        
      _transformController.value = newMatrix;
  }

  String _formatDegree(double deg) {
     final d = deg.floor();
     final m = ((deg - d) * 60).floor();
     final s = (((deg - d) * 60 - m) * 60).round();
     return '$d°$m\'$s"';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Map Layer
          GestureDetector(
             onTapUp: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final local = details.localPosition;
                
                final matrix = _transformController.value;
                final inverse = Matrix4.tryInvert(matrix);
                
                if (inverse == null) return;
                
                final v = vector.Vector3(local.dx, local.dy, 0);
                inverse.transform3(v); 
                
                final tapE = v.x;
                final tapN = -v.y; 
                
                final scale = matrix.getMaxScaleOnAxis(); 
                final hitRadius = 30.0 / scale;
                
                SurveyPoint? hit;
                double closestDistSq = double.infinity;
                
                for (var p in _points) {
                   final dx = p.easting - tapE;
                   final dy = p.northing - tapN;
                   final distSq = dx*dx + dy*dy;
                   
                   if (distSq < hitRadius*hitRadius && distSq < closestDistSq) {
                      closestDistSq = distSq;
                      hit = p;
                   }
                }
                
                if (hit != null) {
                   _handlePointTap(hit);
                } else {
                   if (_isInverseMode) setState(() => _inverseStart = null);
                }
             },
             child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.001,
                maxScale: 1000.0,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                constrained: false, 
                child: SizedBox(
                   width: 100000,
                   height: 100000,
                   child: CustomPaint(
                      painter: MapPainter(
                        _points, 
                        _features, 
                        _inverseStart, 
                        _inverseEnd, 
                        _pendingChain, 
                        areaPoints: _areaPoints,
                        dxfPolylines: _dxfPolylines,
                        userPosition: _userPosition,
                      ),
                      size: const Size(100000, 100000), 
                   ),
                ),
              ),
           ),

           if (_isWorldView)
              Positioned.fill(
                 child: IgnorePointer(
                   ignoring: false,
                   child: FlutterMap(
                     options: MapOptions(
                        initialCenter: _deviceGpsPosition != null 
                            ? ll.LatLng(_deviceGpsPosition!.latitude, _deviceGpsPosition!.longitude) 
                            : const ll.LatLng(30.3753, 69.3451), // Default Pakistan center
                        initialZoom: 6.0,
                    ),
                    children: [
                       TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.surveyor_pro',
                          additionalOptions: const {'lang': 'en'},
                       ),
                       MarkerLayer(
                          markers: [
                             // User Position from device GPS
                             if (_deviceGpsPosition != null)
                                Marker(
                                   point: ll.LatLng(_deviceGpsPosition!.latitude, _deviceGpsPosition!.longitude),
                                   width: 20,
                                   height: 20,
                                   child: Container(
                                      decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                   ),
                                 ),
                          ],
                       ),
                    ],
                 ),
              ),
           ),

          // Header
          Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),
          
          // Pending Chain Controls
          if (_isLineworkMode)
             Positioned(
               top: 80,
               left: 0, right: 0,
               child: Center(
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.cyanAccent)),
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text('Points: ${_pendingChain.length}', style: const TextStyle(color: Colors.white)),
                       const SizedBox(width: 8),
                       if (_pendingChain.length >= 2)
                          GestureDetector(onTap: _saveChain, child: const Icon(Icons.check_circle, color: Colors.greenAccent)),
                       const SizedBox(width: 8),
                       GestureDetector(onTap: () => setState(() { _pendingChain.clear(); _isLineworkMode = false; }), child: const Icon(Icons.cancel, color: Colors.redAccent)),
                     ],
                   ),
                 ),
               ),
             ),

          // Inverse Results
          if (_isInverseMode && _inverseDist != null)
             Positioned(
                top: 80,
                left: 16,
                right: 16,
                child: Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
                   child: Column(
                      children: [
                         Text('Inverse Result', style: GoogleFonts.inter(color: Colors.grey, fontSize: 10)),
                         const SizedBox(height: 4),
                         Text('Dist: ${_inverseDist!.toStringAsFixed(3)}m', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                         Text('Azimuth: ${_formatDegree(_inverseBearing!)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                   ),
                ),
             ),
             
          // Area Result
          if (_isAreaMode && _areaPoints.length >= 3)
             Positioned(
                top: 80,
                left: 16,
                right: 16,
                child: Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orangeAccent)),
                   child: Column(
                      children: [
                         Text('Area Result', style: GoogleFonts.inter(color: Colors.grey, fontSize: 10)),
                         const SizedBox(height: 4),
                         Text('${_currentArea.toStringAsFixed(2)} m²', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                         Text('${GeometryUtils.sqMetersToAcres(_currentArea).toStringAsFixed(3)} ac | ${GeometryUtils.sqMetersToSqFeet(_currentArea).toStringAsFixed(0)} ft²', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                   ),
                ),
             ),
             
          // Clear Area Button
          if (_isAreaMode && _areaPoints.isNotEmpty)
             Positioned(
               top: 150,
               left: 0, right: 0,
               child: Center(
                 child: GestureDetector(
                   onTap: () => setState(() { _areaPoints.clear(); _currentArea = 0.0; }),
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                     child: const Text('Clear Area', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   ),
                 ),
               ),
             ),

          // Zoom Controls
          Positioned(
             bottom: 180,
             right: 16,
             child: Column(
                children: [
                   _buildZoomBtn(Icons.crop_free, _zoomToExtents),
                    const SizedBox(height: 8),
                   _buildZoomBtn(Icons.add, () => _zoom(true)),
                    const SizedBox(height: 8),
                   _buildZoomBtn(Icons.remove, () => _zoom(false)),
                ]
             )
          ),
          
          // Tool Bar (Bottom Left)
          Positioned(
             bottom: 40,
             left: 16,
             right: 16, // Extend to right
             child: Row(
               children: [
                 // Inverse Tool
                 FloatingActionButton(
                    heroTag: 'measure',
                    mini: true,
                    backgroundColor: _isInverseMode ? AppColors.primary : Colors.grey[800],
                    onPressed: () => setState(() { 
                        _isInverseMode = !_isInverseMode; 
                        _isLineworkMode = false;
                        _isAreaMode = false;
                        _inverseStart = null; _inverseEnd = null; 
                        _areaPoints.clear();
                    }),
                    child: const Icon(Icons.straighten, color: Colors.white),
                 ),
                 const SizedBox(width: 16),
                 // Linework Tool
                 FloatingActionButton(
                    heroTag: 'linework',
                    mini: true,
                    backgroundColor: _isLineworkMode ? Colors.cyan : Colors.grey[800],
                    onPressed: () => setState(() { 
                       _isLineworkMode = !_isLineworkMode; 
                       _isInverseMode = false;
                       _isAreaMode = false;
                       _pendingChain.clear();
                       _areaPoints.clear();
                    }),
                    child: const Icon(Icons.polyline, color: Colors.white),
                 ),
                 const SizedBox(width: 16),
                 // Area Tool
                 FloatingActionButton(
                    heroTag: 'area',
                    mini: true,
                    backgroundColor: _isAreaMode ? Colors.orangeAccent : Colors.grey[800],
                    onPressed: () => setState(() { 
                       _isAreaMode = !_isAreaMode; 
                       _isInverseMode = false;
                       _isLineworkMode = false;
                       _areaPoints.clear();
                       _currentArea = 0.0;
                    }),
                    child: const Icon(Icons.square_foot, color: Colors.white),
                 ),
                 const SizedBox(width: 16),
                  
                   // Intersection Tool
                    FloatingActionButton(
                      heroTag: 'intersection',
                      mini: true,
                      backgroundColor: Colors.grey[800],
                      onPressed: _openIntersectionModal,
                      child: const Icon(Icons.merge, color: Colors.white),
                   ),
                   const SizedBox(width: 16),
                   
                   // Add Point Tool
                   FloatingActionButton(
                     heroTag: 'addpoint',
                     backgroundColor: AppColors.primary,
                     onPressed: () { _newIdCtrl.clear(); _newNCtrl.clear(); _newECtrl.clear(); _descCtrl.clear(); setState(() => _showAddModal = true); },
                     child: const Icon(Icons.add, color: Colors.white),
                   ),
                ],
             ),
          ),

          // Modals
          if (_showAddModal) _buildAddModal(),
          if (_showEditModal) _buildEditModal(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: _fitToScreen,
              style: IconButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
              icon: const Icon(Icons.fit_screen),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => context.go('/dashboard'),
              style: IconButton.styleFrom(backgroundColor: AppColors.surface.withValues(alpha: 0.8), foregroundColor: Colors.white),
              icon: const Icon(Icons.arrow_back),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
              child: Text('${_points.length} Pts | ${_features.length} Lines', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            IconButton(
               onPressed: () => setState(() => _isWorldView = !_isWorldView),
               style: IconButton.styleFrom(backgroundColor: _isWorldView ? Colors.blue : Colors.grey[800], foregroundColor: Colors.white),
               icon: const Icon(Icons.public),
               tooltip: 'Toggle World/Grid',
            ),
             const SizedBox(width: 8),
            IconButton(
              onPressed: _importDxf,
              style: IconButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
              icon: const Icon(Icons.layers),
              tooltip: 'Import DXF',
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                 if (_userPosition != null) {
                    // Center on User
                    // _transformController.value.... (Complex matrix math needed for exact center)
                    // For now just toggle follow mode visual
                    setState(() => _followGps = !_followGps);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_followGps ? 'Tracking GPS' : 'GPS Tracking Off')));
                 } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No GPS Fix')));
                 }
              },
              style: IconButton.styleFrom(backgroundColor: _followGps ? Colors.blue : Colors.grey[800], foregroundColor: Colors.white),
              icon: const Icon(Icons.my_location),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[700]!)),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
  
  void _openIntersectionModal() {
     showDialog(
        context: context, 
        builder: (c) => IntersectionModal(
           points: _points, 
           onPointCreated: (p) {
              setState(() => _points.add(p));
              _loadData();
           },
        )
     );
  }
  
  Widget _buildAddModal() {
     return Container(
       color: Colors.black54,
       child: Center(
         child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[700]!)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 const Text('Add Point', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                 const SizedBox(height: 16),
                 _buildModalInput('ID', _newIdCtrl),
                 const SizedBox(height: 8),
                 Row(children: [ Expanded(child: _buildModalInput('N', _newNCtrl)), const SizedBox(width: 8), Expanded(child: _buildModalInput('E', _newECtrl)) ]),
                 const SizedBox(height: 8),
                 _buildModalInput('Description', _descCtrl),
                 const SizedBox(height: 24),
                 Row(children: [
                   Expanded(child: TextButton(onPressed: () => setState(() => _showAddModal = false), child: const Text('Cancel', style: TextStyle(color: Colors.grey)))),
                   Expanded(child: ElevatedButton(onPressed: _addPoint, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Add', style: TextStyle(color: Colors.white)))),
                 ]),
              ],
            ),
         ),
       ),
     );
  }

  Widget _buildEditModal() {
     return Container(
       color: Colors.black54,
       child: Center(
         child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[700]!)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 const Text('Edit Point', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                 const SizedBox(height: 16),
                 _buildModalInput('ID', _newIdCtrl),
                 const SizedBox(height: 8),
                 Row(children: [ Expanded(child: _buildModalInput('N', _newNCtrl)), const SizedBox(width: 8), Expanded(child: _buildModalInput('E', _newECtrl)) ]),
                 const SizedBox(height: 8),
                 _buildModalInput('Description', _descCtrl),
                 const SizedBox(height: 24),
                 Row(children: [
                   Expanded(child: TextButton(onPressed: _deletePoint, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete'))),
                   Expanded(child: TextButton(onPressed: () => setState(() => _showEditModal = false), child: const Text('Cancel', style: TextStyle(color: Colors.grey)))),
                   Expanded(child: ElevatedButton(onPressed: _updatePoint, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Save', style: TextStyle(color: Colors.white)))),
                 ]),
              ],
            ),
         ),
       ),
     );
  }

  Widget _buildModalInput(String hint, TextEditingController ctrl) {
      return TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: TextStyle(color: Colors.grey[500]),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.transparent)),
        ),
      );
  }
}

class MapPainter extends CustomPainter {
  final List<SurveyPoint> points;
  final List<Map<String, dynamic>> features;
  final SurveyPoint? startInv;
  final SurveyPoint? endInv;
  final List<SurveyPoint> pendingChain;
  final List<SurveyPoint> areaPoints;
  final List<List<Offset>> dxfPolylines;
  final SurveyPoint? userPosition;

  MapPainter(this.points, this.features, this.startInv, this.endInv, this.pendingChain, {this.areaPoints = const [], this.dxfPolylines = const [], this.userPosition});

  @override
  void paint(Canvas canvas, Size size) {
    
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.1)..strokeWidth = 1;
    
    // Draw DXF Background
    final dxfPaint = Paint()..color = Colors.grey.withValues(alpha: 0.3)..strokeWidth = 1..style = PaintingStyle.stroke;
    for (var poly in dxfPolylines) {
       if (poly.isEmpty) continue;
       for (int i = 0; i < poly.length - 1; i++) {
         // Invert Y for map coordinates
         // Note: Assuming DxfService returns raw DXF coordinates. map coord system is Y up (North).
         // Canvas is Y down. So draw (x, -y).
         canvas.drawLine(Offset(poly[i].dx, -poly[i].dy), Offset(poly[i+1].dx, -poly[i+1].dy), dxfPaint);
       }
    }
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    if (points.isNotEmpty) {
       double minN = points.first.northing; double maxN = minN;
       double minE = points.first.easting; double maxE = minE;
       for (var p in points) {
         if (p.northing < minN) minN = p.northing; if (p.northing > maxN) maxN = p.northing;
         if (p.easting < minE) minE = p.easting; if (p.easting > maxE) maxE = p.easting;
       }
       minN -= 50; maxN += 50; minE -= 50; maxE += 50;
       
       final startE = (minE ~/ 50) * 50.0;
       final startN = (minN ~/ 50) * 50.0;
       
       if (maxE - startE < 20000 && maxN - startN < 20000) {
           for (double x = startE; x <= maxE; x += 50) {
              canvas.drawLine(Offset(x, -startN), Offset(x, -maxN), gridPaint);
              textPainter.text = TextSpan(text: '${x.toInt()}E', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10));
              textPainter.layout();
              canvas.save();
              canvas.translate(x + 2, -maxN + 2);
              canvas.scale(1, -1); 
              textPainter.paint(canvas, Offset.zero);
              canvas.restore();
           }
           
           for (double y = startN; y <= maxN; y += 50) {
              canvas.drawLine(Offset(startE, -y), Offset(maxE, -y), gridPaint);
              textPainter.text = TextSpan(text: '${y.toInt()}N', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10));
              textPainter.layout();
              canvas.save();
              canvas.translate(startE + 2, -y - 12);
              canvas.scale(1, -1); 
              textPainter.paint(canvas, Offset.zero);
              canvas.restore();
           }
       }
    }
    
    // Draw Features
    for (var f in features) {
       final pts = f['points'] as List<SurveyPoint>;
       final colorInt = int.tryParse(f['feature']['color']) ?? 0xFFFFFFFF;
       final paint = Paint()..color = Color(colorInt)..strokeWidth = 2..style = PaintingStyle.stroke;
       
       if (pts.length > 1) {
          for (int i=0; i<pts.length-1; i++) {
             canvas.drawLine(
               Offset(pts[i].easting, -pts[i].northing),
               Offset(pts[i+1].easting, -pts[i+1].northing),
               paint
             );
          }
       }
    }
    
    // Draw Pending Chain
    if (pendingChain.length > 1) {
       final paint = Paint()..color = Colors.cyanAccent..strokeWidth = 2..style = PaintingStyle.stroke;
       for (int i=0; i<pendingChain.length-1; i++) {
          canvas.drawLine(
            Offset(pendingChain[i].easting, -pendingChain[i].northing),
            Offset(pendingChain[i+1].easting, -pendingChain[i+1].northing),
            paint
          );
       }
    }

    // Points
    final ptPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.black;
    final selPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = Colors.greenAccent;
    final chainPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = Colors.cyan;

    for (var p in points) {
       final offset = Offset(p.easting, -p.northing);
       
       if (p.name.startsWith('STN') || p.type == 'control') {
         ptPaint.color = const Color(0xFF135BEC);
       } else if (p.description == 'MANUAL') {
         ptPaint.color = const Color(0xFFFBBF24);
       } else {
         ptPaint.color = Colors.white;
       }
       
       if (p == startInv || p == endInv) {
          canvas.drawCircle(offset, 8, selPaint);
       }
       
       if (pendingChain.contains(p)) {
          canvas.drawCircle(offset, 8, chainPaint);
       }

       canvas.drawCircle(offset, 4, ptPaint);
       canvas.drawCircle(offset, 4, strokePaint);
       
       canvas.save();
       canvas.translate(offset.dx, offset.dy);
       canvas.scale(1, -1); 
       textPainter.text = TextSpan(text: p.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black)]));
       textPainter.layout();
       textPainter.paint(canvas, Offset(-textPainter.width/2, 6));
       canvas.restore();
    }
    
    // Inverse Line
    if (startInv != null && endInv != null) {
       final p1 = Offset(startInv!.easting, -startInv!.northing);
       final p2 = Offset(endInv!.easting, -endInv!.northing);
       final linePaint = Paint()..color = AppColors.primary..strokeWidth = 2..style = PaintingStyle.stroke;
       canvas.drawLine(p1, p2, linePaint);
    }
    
    // Draw Area Polygon
    if (areaPoints.isNotEmpty) {
       final path = Path();
       path.moveTo(areaPoints.first.easting, -areaPoints.first.northing);
       for (int i = 1; i < areaPoints.length; i++) {
          path.lineTo(areaPoints[i].easting, -areaPoints[i].northing);
       }
       if (areaPoints.length > 2) path.close();
       
       canvas.drawPath(path, Paint()..color = Colors.orangeAccent.withValues(alpha: 0.3)..style = PaintingStyle.fill);
       canvas.drawPath(path, Paint()..color = Colors.orangeAccent..style = PaintingStyle.stroke..strokeWidth = 2);
    }

     // Draw User Position
     if (userPosition != null) {
        final center = Offset(userPosition!.easting, -userPosition!.northing);
        canvas.drawCircle(center, 5.0, Paint()..color = Colors.blueAccent..style = PaintingStyle.fill);
        canvas.drawCircle(center, 5.0, Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.stroke);
        canvas.drawCircle(center, 15.0, Paint()..color = Colors.blueAccent.withValues(alpha: 0.2)..style = PaintingStyle.fill);
     }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) => true;
}
