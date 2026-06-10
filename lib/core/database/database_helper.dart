import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/project.dart';
import '../models/survey_point.dart';
import '../models/log_entry.dart';
import 'package:surveyor_pro/features/leveling/domain/models/level_loop.dart';
import 'package:surveyor_pro/features/leveling/domain/models/level_observation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('surveyor_pro.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE projects ( 
  id $idType, 
  name $textType,
  jobId $textType,
  client $textType,
  location $textType,
  status $textType,
  lastModified $textType
  )
''');

    await db.execute('''
CREATE TABLE points ( 
  id $idType, 
  projectId $intType,
  name $textType,
  northing $realType,
  easting $realType,
  elevation $realType,
  description $textType,
  type $textType,
  FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
  )
''');
    await db.execute('''
CREATE TABLE logs ( 
  id $idType, 
  projectId $intType,
  date $textType,
  note $textType,
  imagePath TEXT,
  FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
  )
''');

    await db.execute('''
CREATE TABLE map_features (
  id $idType,
  projectId $intType,
  name $textType,
  type $textType,
  color $textType,
  FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE map_feature_points (
  id $idType,
  featureId $intType,
  pointId $intType,
  ordinal $intType,
  FOREIGN KEY (featureId) REFERENCES map_features (id) ON DELETE CASCADE,
  FOREIGN KEY (pointId) REFERENCES points (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE level_loops (
  id $idType,
  projectId $intType,
  name $textType,
  date $textType,
  closureError REAL,
  status $textType,
  FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE level_obs (
  id $idType,
  loopId $intType,
  station $textType,
  backsight REAL,
  intermediate REAL,
  foresight REAL,
  elevation REAL,
  distance REAL,
  notes TEXT,
  ordinal $intType,
  FOREIGN KEY (loopId) REFERENCES level_loops (id) ON DELETE CASCADE
)
''');
  }

  Future<int> createMapFeature(int projectId, String name, String type, int colorValue, List<int> pointIds) async {
    final db = await instance.database;
    // Transaction to ensure integrity
    return await db.transaction((txn) async {
       final featureId = await txn.insert('map_features', {
         'projectId': projectId,
         'name': name,
         'type': type,
         'color': colorValue.toString(), // Store as string for simplicity or int
       });
       
       for (int i = 0; i < pointIds.length; i++) {
         await txn.insert('map_feature_points', {
           'featureId': featureId,
           'pointId': pointIds[i],
           'ordinal': i,
         });
       }
       return featureId;
    });
  }

  Future<List<Map<String, dynamic>>> getProjectFeatures(int projectId) async {
    final db = await instance.database;
    // Get features
    final features = await db.query('map_features', where: 'projectId = ?', whereArgs: [projectId]);
    
    // For each feature, get points
    final List<Map<String, dynamic>> result = [];
    for (var f in features) {
       final featureId = f['id'] as int;
       final points = await db.rawQuery('''
         SELECT p.* 
         FROM points p
         INNER JOIN map_feature_points mfp ON p.id = mfp.pointId
         WHERE mfp.featureId = ?
         ORDER BY mfp.ordinal ASC
       ''', [featureId]);
       
       result.add({
         'feature': f,
         'points': points.map((json) => SurveyPoint.fromMap(json)).toList(),
       });
    }
    return result;
  }
  
  // Also adding missing deletePoint support


  // PROJECT CRUD
  Future<Project> createProject(Project project) async {
    final db = await instance.database;
    final id = await db.insert('projects', project.toMap());
    return Project(
      id: id,
      name: project.name,
      jobId: project.jobId,
      client: project.client,
      location: project.location,
      status: project.status,
      lastModified: project.lastModified,
    );
  }

  Future<Project?> getProject(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'projects',
      columns: ['id', 'name', 'jobId', 'client', 'location', 'status', 'lastModified'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Project.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Project>> getAllProjects() async {
    final db = await instance.database;
    final orderBy = 'lastModified DESC';
    final result = await db.query('projects', orderBy: orderBy);

    return result.map((json) => Project.fromMap(json)).toList();
  }

  Future<int> updateProject(Project project) async {
    final db = await instance.database;
    return db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> deleteProject(int id) async {
    final db = await instance.database;
    return await db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // POINTS CRUD
  Future<SurveyPoint> createPoint(SurveyPoint point) async {
    final db = await instance.database;
    final id = await db.insert('points', point.toMap());
    return SurveyPoint(
      id: id,
      projectId: point.projectId,
      name: point.name,
      northing: point.northing,
      easting: point.easting,
      elevation: point.elevation,
      description: point.description,
      type: point.type,
    );
  }

  Future<List<SurveyPoint>> getPointsForProject(int projectId) async {
    final db = await instance.database;
    final result = await db.query(
      'points',
      where: 'projectId = ?',
      whereArgs: [projectId],
    );

    return result.map((json) => SurveyPoint.fromMap(json)).toList();
  }
  
  Future<int> deletePoint(int id) async {
    final db = await instance.database;
    return await db.delete(
      'points',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // LOGS CRUD
  Future<LogEntry> createLog(LogEntry log) async {
    final db = await instance.database;
    final id = await db.insert('logs', log.toMap());
    return LogEntry(
      id: id,
      projectId: log.projectId,
      date: log.date,
      note: log.note,
      imagePath: log.imagePath,
    );
  }

  Future<List<LogEntry>> getLogsForProject(int projectId) async {
    final db = await instance.database;
    final result = await db.query(
      'logs',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: 'id DESC',
    );

    return result.map((json) => LogEntry.fromMap(json)).toList();
  }

  // LEVELING CRUD
  Future<int> createLevelLoop(LevelLoop loop) async {
    final db = await instance.database;
    return await db.insert('level_loops', loop.toMap());
  }

  Future<List<LevelLoop>> getLevelLoops(int projectId) async {
    final db = await instance.database;
    final result = await db.query('level_loops', where: 'projectId = ?', whereArgs: [projectId], orderBy: 'date DESC');
    return result.map((json) => LevelLoop.fromMap(json)).toList();
  }

  Future<int> addLevelObservation(LevelObservation obs) async {
    final db = await instance.database;
    return await db.insert('level_obs', obs.toMap());
  }

  Future<List<LevelObservation>> getLevelObservations(int loopId) async {
    final db = await instance.database;
    final result = await db.query('level_obs', where: 'loopId = ?', whereArgs: [loopId], orderBy: 'ordinal ASC');
    return result.map((json) => LevelObservation.fromMap(json)).toList();
  }

  Future<void> updateLevelLoop(LevelLoop loop) async {
     final db = await instance.database;
     await db.update('level_loops', loop.toMap(), where: 'id = ?', whereArgs: [loop.id]);
  }

  Future<void> deleteLevelLoop(int id) async {
     final db = await instance.database;
     await db.delete('level_loops', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
