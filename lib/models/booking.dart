class Booking {
  final int id;
  final int objectId;
  final int userId;
  final DateTime start;
  final DateTime end;
  final String? details;
  final String? nameRider;
  final String? nameHorse;
  final String? descUsage;
  final bool exclusive;

  Booking({
    required this.id,
    required this.objectId,
    required this.userId,
    required this.start,
    required this.end,
    this.details,
    this.nameRider,
    this.nameHorse,
    this.descUsage,
    this.exclusive = false,
  });

  factory Booking.fromJson(Map<String, dynamic> j) {
    DateTime parseDt(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.parse(v).toLocal();
    }

    return Booking(
      id: j['id'] is int ? j['id'] : int.parse(j['id'].toString()),
      objectId: j['object_id'] is int ? j['object_id'] : int.parse(j['object_id'].toString()),
      userId: j['user_id'] is int ? j['user_id'] : int.parse(j['user_id'].toString()),
      start: parseDt(j['start_time'] ?? j['startTime']),
      end: parseDt(j['end_time'] ?? j['endTime']),
      details: j['details'] as String?,
      nameRider: j['name_rider'] as String?,
      nameHorse: j['name_horse'] as String?,
      descUsage: j['desc_usage'] as String?,
      exclusive: (j['exclusive'] is bool) ? j['exclusive'] : (j['exclusive'].toString() == '1'),
    );
  }
}