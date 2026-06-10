class LevelObservation {
  final int? id;
  final int loopId;
  final String station;
  final double? backsight;
  final double? intermediate;
  final double? foresight;
  final double? elevation;
  final double? distance;
  final String? notes;
  final int ordinal;

  LevelObservation({
    this.id,
    required this.loopId,
    required this.station,
    this.backsight,
    this.intermediate,
    this.foresight,
    this.elevation,
    this.distance,
    this.notes,
    required this.ordinal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loopId': loopId,
      'station': station,
      'backsight': backsight,
      'intermediate': intermediate,
      'foresight': foresight,
      'elevation': elevation,
      'distance': distance,
      'notes': notes,
      'ordinal': ordinal,
    };
  }

  static LevelObservation fromMap(Map<String, dynamic> map) {
    return LevelObservation(
      id: map['id'],
      loopId: map['loopId'],
      station: map['station'],
      backsight: map['backsight'],
      intermediate: map['intermediate'],
      foresight: map['foresight'],
      elevation: map['elevation'],
      distance: map['distance'],
      notes: map['notes'],
      ordinal: map['ordinal'],
    );
  }
}
