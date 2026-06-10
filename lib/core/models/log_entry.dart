class LogEntry {
  final int? id;
  final int projectId;
  final String date;
  final String note;
  final String? imagePath;

  LogEntry({
    this.id,
    required this.projectId,
    required this.date,
    required this.note,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'date': date,
      'note': note,
      'imagePath': imagePath,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'],
      projectId: map['projectId'],
      date: map['date'],
      note: map['note'],
      imagePath: map['imagePath'],
    );
  }
}
