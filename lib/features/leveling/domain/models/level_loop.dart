class LevelLoop {
  final int? id;
  final int projectId;
  final String name;
  final DateTime date;
  final double? closureError;
  final String status; // 'open', 'closed'

  LevelLoop({
    this.id,
    required this.projectId,
    required this.name,
    required this.date,
    this.closureError,
    this.status = 'open',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'date': date.toIso8601String(),
      'closureError': closureError,
      'status': status,
    };
  }

  static LevelLoop fromMap(Map<String, dynamic> map) {
    return LevelLoop(
      id: map['id'],
      projectId: map['projectId'],
      name: map['name'],
      date: DateTime.parse(map['date']),
      closureError: map['closureError'],
      status: map['status'],
    );
  }
}
