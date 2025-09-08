import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/booking_provider.dart';
import 'screens/calendar_screen.dart';

void main() {
  runApp(const BookingApp());
}

class BookingApp extends StatelessWidget {
  const BookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingProvider(objectId: 1),
      child: MaterialApp(
        title: 'Booking App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const CalendarScreen(),
      ),
    );
  }
}
