class Booking {
  final int id;
  final int objectId;
  final int userId;
  final DateTime startUtc;
  final DateTime endUtc;

  Booking({
    required this.id,
    required this.objectId,
    required this.userId,
    required this.startUtc,
    required this.endUtc,
  });

  factory Booking.fromJson(Map<String, dynamic> j) {
    DateTime parseDate(String? s) => s == null ? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.parse(s);
    return Booking(
      id: j['id'] is int ? j['id'] : int.parse(j['id'].toString()),
      objectId: j['object_id'] ?? j['objectId'] ?? 1,
      userId: j['user_id'] ?? j['userId'] ?? 0,
      startUtc: parseDate(j['start_time'] ?? j['startTime']),
      endUtc: parseDate(j['end_time'] ?? j['endTime']),
    );
  }
}
