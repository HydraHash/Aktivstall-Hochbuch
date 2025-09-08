import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class BookingProvider extends ChangeNotifier {
  final int objectId;
  Map<DateTime, List<Booking>> events = {};
  bool isLoading = false;

  BookingProvider({required this.objectId});

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<void> loadForRange(DateTime fromLocal, DateTime toLocal) async {
    isLoading = true;
    notifyListeners();
    final fromUtc = DateTime(fromLocal.year, fromLocal.month, fromLocal.day, 0,0).toUtc();
    final toUtc = DateTime(toLocal.year, toLocal.month, toLocal.day, 23,59,59).toUtc();
    final token = await StorageService.readToken();
    final fetched = await ApiService.fetchBookingsUtc(
      objectId: objectId,
      fromUtc: fromUtc,
      toUtc: toUtc,
      token: token,
    );
    events.clear();
    for (final b in fetched) {
      final localDate = _dateOnly(b.startUtc.toLocal());
      events.putIfAbsent(localDate, () => []).add(b);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> createBookingLocal(DateTime startLocal, Duration duration) async {
    final token = await StorageService.readToken();
    if (token == null) throw Exception('No token stored');
    final startUtc = startLocal.toUtc();
    final endUtc = startLocal.add(duration).toUtc();
    final id = await ApiService.createBooking(
      token: token,
      objectId: objectId,
      startUtc: startUtc,
      endUtc: endUtc,
    );
    final dateKey = _dateOnly(startLocal);
    final booking = Booking(id: id, objectId: objectId, userId: 0, startUtc: startUtc, endUtc: endUtc);
    events.putIfAbsent(dateKey, () => []).add(booking);
    notifyListeners();
  }
}
