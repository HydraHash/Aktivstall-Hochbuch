import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/booking.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.week;
  Map<DateTime, List<Booking>> _events = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookingsForWeek(_focusedDay);
  }

  Map<String,int> isoWeekYear(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    final weekday = d.weekday; // Mon=1..Sun=7
    final thursday = d.add(Duration(days: 4 - weekday));
    final isoYear = thursday.year;
    // first Thursday of isoYear
    final firstThursday = DateTime.utc(isoYear, 1, 4);
    final daysDiff = thursday.difference(DateTime.utc(isoYear,1,1)).inDays;
    final weekNumber = ((daysDiff + (firstThursday.weekday - 1)) / 7).floor() + 1;
    return {'year': isoYear, 'week': weekNumber};
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<void> _loadBookingsForWeek(DateTime anyDateInWeek) async {
    setState(() => _loading = true);
    final map = isoWeekYear(anyDateInWeek);
    final year = map['year']!;
    final week = map['week']!;
    try {
      final list = await ApiService.getBookingsForWeek(year: year, week: week, objectId: 1);
      final Map<DateTime, List<Booking>> ev = {};
      for (final b in list) {
        final localStart = b.start.toLocal();
        final key = _dateOnly(localStart);
        ev.putIfAbsent(key, () => []).add(b);
      }
      setState(() {
        _events = ev;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading bookings: $e')));
    }
  }

  List<Booking> _getEventsForDay(DateTime day) => _events[_dateOnly(day)] ?? [];

  void _prevWeek() {
    setState(() {
      _focusedDay = _focusedDay.subtract(const Duration(days: 7));
    });
    _loadBookingsForWeek(_focusedDay);
  }

  void _nextWeek() {
    setState(() {
      _focusedDay = _focusedDay.add(const Duration(days: 7));
    });
    _loadBookingsForWeek(_focusedDay);
  }

  Future<void> _createBookingFlow() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;

    final startTimeOfDay = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (startTimeOfDay == null) return;

    final startLocal = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      startTimeOfDay.hour,
      (startTimeOfDay.minute / 15).round() * 15,
    );

    final defaultEnd = startLocal.add(const Duration(hours: 1));
    final endTimeOfDay = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(defaultEnd));
    if (endTimeOfDay == null) return;

    final endLocal = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      endTimeOfDay.hour,
      (endTimeOfDay.minute / 15).round() * 15,
    );

    if (endLocal.isBefore(startLocal) || endLocal.isAtSameMomentAs(startLocal)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End must be after start')));
      return;
    }

    final durationMin = endLocal.difference(startLocal).inMinutes;
    if (durationMin < 15 || durationMin > 240) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duration must be 15–240 minutes')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm booking'),
        content: Text('Book from ${DateFormat('yyyy-MM-dd HH:mm').format(startLocal)} to ${DateFormat('yyyy-MM-dd HH:mm').format(endLocal)} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Book')),
        ],
      ),
    );

    if (confirmed != true) return;

    final startUtc = startLocal.toUtc();
    final endUtc = endLocal.toUtc();

    try {
      final created = await ApiService.createBooking(objectId: 1, startUtc: startUtc, endUtc: endUtc);
      final key = _dateOnly(created.start.toLocal());
      setState(() {
        _events.putIfAbsent(key, () => []).add(created);
      });
      _loadBookingsForWeek(_focusedDay);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking created')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final iso = isoWeekYear(_focusedDay);
    final week = iso['week']!;
    final year = iso['year']!;
    final weekText = 'Week $week / $year';

    return Scaffold(
      appBar: AppBar(
        title: Text('Shared Calendar - $weekText'),
        actions: [
          IconButton(onPressed: _prevWeek, icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: _nextWeek, icon: const Icon(Icons.chevron_right)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  calendarFormat: _format,
                  availableCalendarFormats: const {CalendarFormat.week: 'Week'},
                  onFormatChanged: (f) => setState(() => _format = f),
                  selectedDayPredicate: (d) => isSameDay(d, _focusedDay),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _focusedDay = selected;
                    });
                  },
                  eventLoader: _getEventsForDay,
                ),
                Expanded(
                  child: ListView(
                    children: _getEventsForDay(_focusedDay).map((b) {
                      final start = b.start.toLocal();
                      final end = b.end.toLocal();
                      final fmt = DateFormat('EEE dd.MM HH:mm');
                      return ListTile(
                        title: Text('${fmt.format(start)} — ${DateFormat('HH:mm').format(end)}'),
                        subtitle: Text('Booking id: ${b.id}${b.details != null ? ' — ${b.details}' : ''}'),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createBookingFlow,
        child: const Icon(Icons.add),
      ),
    );
  }
}