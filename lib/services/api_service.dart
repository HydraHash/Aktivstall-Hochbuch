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

  // GET bookings for a given iso year/week and objectId
  static Future<List<Booking>> getBookingsForWeek({required int year, required int week, required int objectId}) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/bookings?year=$year&week=$week&object_id=$objectId');
    final res = await http.get(uri, headers: token != null ? {'Authorization': token} : {});
    if (res.statusCode == 200) {
      final List raw = json.decode(res.body) as List;
      return raw.map<Booking>((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load bookings (${res.statusCode}): ${res.body}');
    }
  }

  // POST create booking
  static Future<Booking> createBooking({
    required int objectId,
    required DateTime startUtc,
    required DateTime endUtc,
    bool exclusive = false,
    String? details,
    String? nameRider,
    String? nameHorse,
    String? descUsage,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');
    final payload = {
      'object_id': objectId,
      'start_time': startUtc.toIso8601String(),
      'end_time': endUtc.toIso8601String(),
      'exclusive': exclusive ? 1 : 0,
      'details': details ?? '',
      'name_rider': nameRider ?? '',
      'name_horse': nameHorse ?? '',
      'desc_usage': descUsage ?? '',
    };
    final uri = Uri.parse('$baseUrl/bookings');
    final res = await http.post(uri, 
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: json.encode(payload));
    if (res.statusCode == 200 || res.statusCode == 201) {
      final j = json.decode(res.body);
      // if API returns created booking object (it does), convert to Booking
      return Booking.fromJson(j as Map<String, dynamic>);
    } else {
      throw Exception('Create booking failed: ${res.statusCode} ${res.body}');
    }
  }

  static Future<bool> postFeedback({required String os, required String message}) async {
    final uri = Uri.parse('$baseUrl/feedback');
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) headers['Authorization'] = token;

    final body = jsonEncode({'os': os, 'message': message});
    final res = await http.post(uri, headers: headers, body: body);
    return res.statusCode == 200 || res.statusCode == 201;
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

  static Future<void> requestPasswordReset(String email) async {
    final uri = Uri.parse("$baseUrl/auth/check");
    
    final res = await http.post(uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}));

    if (res.statusCode == 200) {
      return;
    } else {
      throw Exception("Diese E-Mail kann keinem Benutzer zugeordnet werden.");
    }
  }

  static Future<void> confirmPasswordReset(String email, String newPassword) async {
    final uri = Uri.parse("$baseUrl/auth/reset");
    final res = await http.post(uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": newPassword}));

    if (res.statusCode != 200) {
      throw Exception("E-Mail oder Passwort ungültig.");
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

  // GET all bookings for current user
  static Future<List<Booking>> getMyBookings() async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');
    final uri = Uri.parse('$baseUrl/bookings/my');
    final res = await http.get(uri, headers: {'Authorization': token});
    if (res.statusCode == 200) {
      final List raw = json.decode(res.body) as List;
      return raw.map<Booking>((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load bookings (${res.statusCode}): ${res.body}');
    }
  }

  // DELETE a booking by ID
  static Future<bool> deleteBooking(int id) async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');
    final uri = Uri.parse('$baseUrl/bookings/delete/$id');
    final res = await http.delete(uri, headers: {'Authorization': token});
    return res.statusCode == 200 || res.statusCode == 204;
  }


  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }
}
