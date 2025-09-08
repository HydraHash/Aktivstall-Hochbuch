import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking.dart';

class ApiService {
  // CHANGE this to your API base URL
  static const String baseUrl = 'https://app.aktivstall-hochbuch.de';

  static Future<List<Booking>> fetchBookingsUtc({
    required int objectId,
    required DateTime fromUtc,
    required DateTime toUtc,
    String? token,
  }) async {
    final qs = '?object_id=$objectId&from=${Uri.encodeComponent(fromUtc.toIso8601String())}&to=${Uri.encodeComponent(toUtc.toIso8601String())}';
    final uri = Uri.parse('$baseUrl/bookings$qs');
    final res = await http.get(uri, headers: token != null ? {'Authorization': token} : {});
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final List raw = body is List ? body : (body['data'] ?? body);
      return raw.map<Booking>((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load bookings: ${res.statusCode} ${res.body}');
    }
  }

  static Future<int> createBooking({
    required String token,
    required int objectId,
    required DateTime startUtc,
    required DateTime endUtc,
  }) async {
    final payload = {
      'object_id': objectId,
      'start_time': startUtc.toIso8601String(),
      'end_time': endUtc.toIso8601String(),
    };
    final uri = Uri.parse('$baseUrl/bookings');
    final res = await http.post(uri,
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: json.encode(payload));
    if (res.statusCode == 200 || res.statusCode == 201) {
      final j = json.decode(res.body);
      if (j is Map && j.containsKey('id')) return j['id'];
      if (j is Map && j['data'] is Map && j['data'].containsKey('id')) return j['data']['id'];
      return 0;
    } else {
      throw Exception('Create booking failed: ${res.statusCode} ${res.body}');
    }
  }
}
