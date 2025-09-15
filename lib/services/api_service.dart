import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://app.aktivstall-hochbuch.de'; // use https in production

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get bookings for an ISO week (year, week) for objectId
  static Future<List<Booking>> getBookingsForWeek({
    required int year,
    required int week,
    required int objectId,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/bookings?year=$year&week=$week&object_id=$objectId');
    final res = await http.get(uri, headers: token != null ? {'Authorization': token} : {});
    if (res.statusCode == 200) {
      final List raw = json.decode(res.body) as List;
      return raw.map<Booking>((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load bookings: ${res.statusCode} ${res.body}');
    }
  }

  // Create booking: startUtc and endUtc must be DateTime in UTC (use .toUtc())
  static Future<Booking> createBooking({
    required int objectId,
    required DateTime startUtc,
    required DateTime endUtc,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');

    final payload = {
      'object_id': objectId,
      'start_time': startUtc.toIso8601String(), // includes Z
      'end_time': endUtc.toIso8601String(),
    };
    final uri = Uri.parse('$baseUrl/bookings');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: json.encode(payload));

    if (res.statusCode == 201 || res.statusCode == 200) {
      final j = json.decode(res.body);
      return Booking.fromJson(j as Map<String, dynamic>);
    } else {
      throw Exception('Create booking failed: ${res.statusCode} ${res.body}');
    }
  }

  static Future<String> login(String email, String password) async {
    final uri = Uri.parse("$baseUrl/auth/login");
    final res = await http.post(uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}));

    if (res.statusCode == 200) {
      final token = jsonDecode(res.body)["token"];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", token);
      return token;
    } else {
      throw Exception("Login failed");
    }
  }

  static Future<void> register(String email, String password, String code) async {
    final uri = Uri.parse("$baseUrl/auth/register");
    final res = await http.post(uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "code": code,
        }));

    if (res.statusCode != 200) {
      throw Exception("Registration failed: ${res.body}");
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }
}
