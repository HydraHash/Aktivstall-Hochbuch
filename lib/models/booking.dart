class Booking {
  final int id;
  final int objectId;
  final int userId;
  final DateTime start; // parsed DateTime (preserves timezone info)
  final DateTime end;
  final String? details;

  Booking({
    required this.id,
    required this.objectId,
    required this.userId,
    required this.start,
    required this.end,
    this.details,
  });

  factory Booking.fromJson(Map<String, dynamic> j) {
    DateTime parseDt(dynamic x) {
      if (x == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.parse(x as String);
    }

    return Booking(
      id: j['id'] is int ? j['id'] : int.parse(j['id'].toString()),
      objectId: j['object_id'] is int ? j['object_id'] : int.parse(j['object_id'].toString()),
      userId: j['user_id'] is int ? j['user_id'] : int.parse(j['user_id'].toString()),
      start: parseDt(j['start_time'] ?? j['startTime']),
      end: parseDt(j['end_time'] ?? j['endTime']),
      details: j['details'] as String?,
    );
  }
}