import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_dialog.dart';
import '../models/booking.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late BookingProvider provider;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<BookingProvider>(context, listen: false);
    final start = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final end = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.loadForRange(start, end);
    });
  }

  List<Booking> _getEventsForDay(DateTime day) {
    return provider.events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _openCreateDialog(BuildContext ctx, DateTime day) async {
    final picked = await showDialog<Map<String, dynamic>>(context: ctx, builder: (c)=> BookingDialog(initialDay: day));
    if (picked == null) return;
    final startLocal = picked['start'] as DateTime;
    final duration = picked['duration'] as Duration;
    showDialog(context: context, builder: (ctx)=>const Center(child:CircularProgressIndicator()), barrierDismissible: false);
    try {
      await provider.createBookingLocal(startLocal, duration);
      Navigator.of(context).pop(); // remove spinner
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking created')));
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, prov, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Shared Calendar')),
          body: prov.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
              children: [
                TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  eventLoader: _getEventsForDay,
                ),
                ElevatedButton(
                  onPressed: _selectedDay == null ? null : () => _openCreateDialog(context, _selectedDay!),
                  child: const Text('Create booking for selected day'),
                ),
                Expanded(
                  child: ListView(
                    children: _getEventsForDay(_selectedDay ?? _focusedDay).map((b) {
                      final startLocal = b.startUtc.toLocal();
                      final endLocal = b.endUtc.toLocal();
                      final fmt = DateFormat('HH:mm');
                      return ListTile(
                        title: Text('${fmt.format(startLocal)} - ${fmt.format(endLocal)}'),
                        subtitle: Text('Booking id: ${b.id}'),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
        );
      },
    );
  }
}
