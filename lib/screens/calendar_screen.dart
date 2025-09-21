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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.twoWeeks; // show 2 weeks
  Map<DateTime, List<Booking>> _events = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookingsForWeek(_focusedDay);
  }

  // ISO week helper (same as yours)
  Map<String, int> isoWeekYear(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    final weekday = d.weekday;
    final thursday = d.add(Duration(days: 4 - weekday));
    final isoYear = thursday.year;
    final firstThursday = DateTime.utc(isoYear, 1, 4);
    final daysDiff = thursday.difference(DateTime.utc(isoYear, 1, 1)).inDays;
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
      _focusedDay = _focusedDay.subtract(const Duration(days: 14)); // jump 2 weeks
    });
    _loadBookingsForWeek(_focusedDay);
  }

  void _nextWeek() {
    setState(() {
      _focusedDay = _focusedDay.add(const Duration(days: 14));
    });
    _loadBookingsForWeek(_focusedDay);
  }

  // Numeric time picker dialog: returns TimeOfDay or null
  Future<TimeOfDay?> _showNumericTimePicker({
    required BuildContext context,
    required String title,
    required TimeOfDay initial,
  }) async {
    final hourCtrl = TextEditingController(text: initial.hour.toString().padLeft(2, '0'));
    final minCtrl = TextEditingController(text: initial.minute.toString().padLeft(2, '0'));
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: Row(
            children: [
              Flexible(
                child: TextFormField(
                  controller: hourCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Hours (24h)'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final i = int.tryParse(v);
                    if (i == null || i < 0 || i > 23) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: TextFormField(
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minutes'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final i = int.tryParse(v);
                    if (i == null || i < 0 || i > 59) return 'Invalid';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final h = int.parse(hourCtrl.text);
                final m = int.parse(minCtrl.text);
                Navigator.pop(c, TimeOfDay(hour: h, minute: m));
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    return result;
  }

  // Main flow to create booking using numeric time inputs and auto-end = +1h
  Future<void> _createBookingFlow() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;

    // default start: next full quarter hour (rounded up)
    final now = DateTime.now();
    final defaultStart = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
        now.hour, ( (now.minute + 14) ~/ 15) * 15).add(const Duration(minutes: 0));
    final defaultStartTime = TimeOfDay(hour: defaultStart.hour, minute: defaultStart.minute);

    final startTOD = await _showNumericTimePicker(
      context: context,
      title: 'Startzeit wählen (24h)',
      initial: defaultStartTime,
    );
    if (startTOD == null) return;

    final startLocal = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, startTOD.hour, startTOD.minute);

    final endDefault = startLocal.add(const Duration(hours: 1));
    final endTOD = await _showNumericTimePicker(
      context: context,
      title: 'Endzeit wählen (24h)',
      initial: TimeOfDay(hour: endDefault.hour, minute: endDefault.minute),
    );
    if (endTOD == null) return;

    final endLocal = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, endTOD.hour, endTOD.minute);

    if (!endLocal.isAfter(startLocal)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End must be after start')));
      return;
    }

    final durationMin = endLocal.difference(startLocal).inMinutes;
    if (durationMin < 15 || durationMin > 240) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duration must be 15–240 minutes')));
      return;
    }

    // Confirmation dialog (bullet list)
    final fmtDate = DateFormat('EEEE, dd.MM.yyyy', 'de_DE'); // Monday spelled in German if locale used
    final fmtTime = DateFormat('HH:mm');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Bestätigen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bulletRow('Datum', fmtDate.format(startLocal)),
            const SizedBox(height: 6),
            _bulletRow('Start', fmtTime.format(startLocal)),
            const SizedBox(height: 6),
            _bulletRow('Ende', fmtTime.format(endLocal)),
            const SizedBox(height: 6),
            _bulletRow('Dauer', '${durationMin} Minuten'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Buchen')),
        ],
      ),
    );

    if (confirmed != true) return;

    // convert to UTC before sending
    final startUtc = startLocal.toUtc();
    final endUtc = endLocal.toUtc();

    setState(() => _loading = true);
    try {
      final created = await ApiService.createBooking(objectId: 1, startUtc: startUtc, endUtc: endUtc);
      final key = _dateOnly(created.start.toLocal());
      setState(() {
        _events.putIfAbsent(key, () => []).add(created);
      });
      // refresh the authoritative week
      await _loadBookingsForWeek(_focusedDay);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buchung erfolgreich.')));
    } catch (e) {
      // If API returns 409 or message, show it to user
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Buchung nicht erfolgreich: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _bulletRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6.0, right: 8.0),
          child: Icon(Icons.circle, size: 8),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final iso = isoWeekYear(_focusedDay);
    final week = iso['week']!;
    final year = iso['year']!;
    //final weekText = 'Woche $week / $year';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Reithalle Übersicht'),
        // keep back arrow if present; provide menu as action so users can always open drawer
        /*actions: [
          Builder(builder: (ctx) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(ctx).openDrawer();
              },
            );
          }),
        ],*/
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // bigger calendar area for better vertical visibility
                SizedBox(
                  height: 260, // increase for larger vertical cells (tweak to taste)
                  child: TableCalendar(
                    firstDay: DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: _format,
                    availableCalendarFormats: const {
                      CalendarFormat.twoWeeks: '2 Wochen',
                      CalendarFormat.week: '1 Woche',
                    },
                    startingDayOfWeek: StartingDayOfWeek.monday, // week starts Monday
                    onFormatChanged: (f) => setState(() => _format = f),
                    selectedDayPredicate: (d) => isSameDay(d, _focusedDay),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _focusedDay = selected;
                      });
                    },
                    eventLoader: _getEventsForDay,
                    calendarStyle: CalendarStyle(
                      // make daycells larger by increasing cellMargin or others as needed
                      outsideDaysVisible: false,
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      // you can tune text styles here
                    ),
                  ),
                ),
                // booking list for focused day
                Expanded(
                  child: ListView(
                    children: _getEventsForDay(_focusedDay).map((b) {
                      final start = b.start.toLocal();
                      final end = b.end.toLocal();
                      final fmt = DateFormat('EEE dd.MM HH:mm', 'de_DE'); // 24h
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