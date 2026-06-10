class Project {
  final int? id;
  final String name;
  final String jobId;
  final String client;
  final String location;
  final String status;
  final DateTime lastModified;

  Project({
    this.id,
    required this.name,
    required this.jobId,
    required this.client,
    required this.location,
    required this.status,
    required this.lastModified,
  });

  // Convert a Project into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'jobId': jobId,
      'client': client,
      'location': location,
      'status': status,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      jobId: map['jobId'],
      client: map['client'],
      location: map['location'],
      status: map['status'],
      lastModified: DateTime.parse(map['lastModified']),
    );
  }
}
