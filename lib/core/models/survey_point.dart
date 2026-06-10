class SurveyPoint {
  final int? id;
  final int projectId;
  final String name; // User facing ID like STN-1, 1001
  final double northing;
  final double easting;
  final double elevation;
  final String description;
  final String type; // 'control', 'side_shot', 'station'

  SurveyPoint({
    this.id,
    required this.projectId,
    required this.name,
    required this.northing,
    required this.easting,
    this.elevation = 0.0,
    required this.description,
    this.type = 'side_shot',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'northing': northing,
      'easting': easting,
      'elevation': elevation,
      'description': description,
      'type': type,
    };
  }

  factory SurveyPoint.fromMap(Map<String, dynamic> map) {
    return SurveyPoint(
      id: map['id'],
      projectId: map['projectId'],
      name: map['name'],
      northing: map['northing'],
      easting: map['easting'],
      elevation: map['elevation'] ?? 0.0,
      description: map['description'],
      type: map['type'] ?? 'side_shot',
    );
  }
}
