import 'dart:convert';
import 'dart:io';
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

  // POST create single booking
  static Future<List<Booking>> createBooking({
    required int objectId,
    required List<DateTime> startUtcs,
    required List<DateTime> endUtcs,
    bool exclusive = false,
    String? details,
    String? nameRider,
    String? nameHorse,
    String? descUsage,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');

    if (startUtcs.length != endUtcs.length) {
      throw Exception('Mismatched start and end times');
    }

    // Added the new array for slots
    final slots = [];
    for (int i = 0; i < startUtcs.length; i++) {
      slots.add({
        'start_time': startUtcs[i].toIso8601String(),
        'end_time': endUtcs[i].toIso8601String(),
      });
    }

    final payload = {
      'object_id': objectId,
      'slots': slots,
      'exclusive': exclusive ? 1 : 0,
      'details': details ?? '',
      'name_rider': nameRider ?? '',
      'name_horse': nameHorse ?? '',
      'desc_usage': descUsage ?? '',
    };

    final uri = Uri.parse('$baseUrl/bookings/bulk');
    final res = await http.post(uri, 
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: json.encode(payload));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final List raw = json.decode(res.body) as List;
      // Map the returned JSON array to a List of Bookings
      return raw.map<Booking>((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Create serial booking failed: ${res.statusCode} ${res.body}');
    }
  }


  // POST feedback route with image support
  static Future<bool> postFeedback({required String os, required String message, File? imageFile}) async {
    final uri = Uri.parse('$baseUrl/feedback/image');
    final token = await getToken();

    // Create multipart request
    var request = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty){
      request.headers['Authorization'] = token;
    }

    // Add text fields and file if exists
    request.fields['os'] = os;
    request.fields['message'] = message;

    if (imageFile != null){
      var fileStream = await http.MultipartFile.fromPath('image', imageFile.path);
      request.files.add(fileStream);
    }

    // try sending the request
    try {
      var response = await request.send();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) { return false;} 
  }

  // POST login information
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

  // POST require new password
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

  // POST new password confirm request
  static Future<void> confirmPasswordReset(String email, String newPassword) async {
    final uri = Uri.parse("$baseUrl/auth/reset");
    final res = await http.post(uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": newPassword}));

    if (res.statusCode != 200) {
      throw Exception("E-Mail oder Passwort ungültig.");
    }
  }

  // POST register of new user
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
