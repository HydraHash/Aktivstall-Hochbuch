import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/booking.dart';
import 'login_screen.dart';

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
    var week = map['week']!;
    try {
      final currentWeek = await ApiService.getBookingsForWeek(year: year, week: week, objectId: 1);
      final List<Booking> allBookings = [];
      allBookings.addAll(currentWeek);
      final Map<DateTime, List<Booking>> ev = {};
      for (final b in allBookings) {
        final localStart = b.start.toLocal();
        final key = _dateOnly(localStart);
        ev.putIfAbsent(key, () => []).add(b);
      }
      setState(() {
        // merge server events into existing events map (preserve locally added entries)
        final merged = Map<DateTime, List<Booking>>.from(_events);
        ev.forEach((key, list) {
          // if both exist, merge lists and deduplicate by id
          if (merged.containsKey(key)) {
            final existing = merged[key]!;
            // add new ones that aren't already present
            for (final b in list) {
              if (!existing.any((e) => e.id == b.id)) existing.add(b);
            }
          } else {
            merged[key] = List<Booking>.from(list);
          }
        });
        _events = merged;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), 
      (Route<dynamic> route) => false,
      );
    }
  }

  List<Booking> _getEventsForDay(DateTime day) => _events[_dateOnly(day)] ?? [];


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
                  decoration: const InputDecoration(labelText: 'Stunden'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Notwendig';
                    final i = int.tryParse(v);
                    if (i == null || i < 0 || i > 23) return 'Ungültig';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: TextFormField(
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minuten'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Notwendig';
                    final i = int.tryParse(v);
                    if (i == null || i < 0 || i > 59) return 'Ungültig';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Abbrechen')),
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
    // step 1: pick date
    final firstDate = DateTime.now();
    final initialDate = _focusedDay.isBefore(firstDate) ? firstDate : _focusedDay;

    final pickedDate = await showDatePicker(
      context: context,
      locale: const Locale('de', 'DE'),
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Datum auswählen',
      confirmText: 'Weiter',
      cancelText: 'Abbrechen',
    );
    if (pickedDate == null) return;

    // step 2: default start (next quarter-hour)
    final now = DateTime.now();
    final nextQuarter = ((now.minute + 14) ~/ 15) * 15;
    final defaultStart = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, now.hour, nextQuarter);
    final defaultStartTime = TimeOfDay(hour: defaultStart.hour, minute: defaultStart.minute);

    // pick start time (numeric dialog)
    final startTOD = await _showNumericTimePicker(
      context: context,
      title: 'Startzeit wählen:',
      initial: defaultStartTime,
    );
    if (startTOD == null) return;

    final startLocal = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, startTOD.hour, startTOD.minute);

    // default end = start + 1 hour
    final endDefault = startLocal.add(const Duration(hours: 1));
    final endTOD = await _showNumericTimePicker(
      context: context,
      title: 'Endzeit wählen:',
      initial: TimeOfDay(hour: endDefault.hour, minute: endDefault.minute),
    );
    if (endTOD == null) return;

    final endLocal = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, endTOD.hour, endTOD.minute);

    // validate chronological order
    if (!endLocal.isAfter(startLocal)) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endzeit muss 15 Minuten nach Startzeit sein!')));
      return;
    }

    // validate duration
    final durationMin = endLocal.difference(startLocal).inMinutes;
    if (durationMin < 15 || durationMin > 240) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dauer muss zwischen 15 und 240 Minuten liegen!')));
      return;
    }

    // step 3: collect metadata (rider, horse, usage, details, exclusive)
    String details = '';
    String nameRider = '';
    String nameHorse = '';
    String descUsage = '';
    bool exclusive = false;

    final gotMeta = await showDialog<bool>(
      context: context,
      builder: (c) {
        final detailsCtrl = TextEditingController();
        final riderCtrl = TextEditingController();
        final horseCtrl = TextEditingController();
        final usageCtrl = TextEditingController();
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('Weitere Angaben'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: riderCtrl, decoration: const InputDecoration(labelText: 'Name Reiter')),
                  const SizedBox(height: 8),
                  TextField(controller: horseCtrl, decoration: const InputDecoration(labelText: 'Name Pferd')),
                  const SizedBox(height: 8),
                  TextField(controller: usageCtrl, decoration: const InputDecoration(labelText: 'Kurz: Zweck / Nutzung')),
                  const SizedBox(height: 8),
                  TextField(controller: detailsCtrl, decoration: const InputDecoration(labelText: 'Details (optional)'), maxLines: 3),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: exclusive,
                    onChanged: (v) => setStateDialog(() => exclusive = v ?? false),
                    title: const Text('Ich benötige die Halle alleine'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Abbrechen')),
              ElevatedButton(onPressed: () {
                details = detailsCtrl.text.trim();
                nameRider = riderCtrl.text.trim();
                nameHorse = horseCtrl.text.trim();
                descUsage = usageCtrl.text.trim();
                Navigator.pop(c, true);
              }, child: const Text('Weiter')),
            ],
          );
        });
      },
    );

    if (gotMeta != true) return;

    // step 4: confirmation dialog (bullet list)
    final fmtDate = DateFormat('EEEE, dd.MM.yyyy', 'de_DE');
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
            _bulletRow('Startzeitpunkt', fmtTime.format(startLocal)),
            const SizedBox(height: 6),
            _bulletRow('Endzeitpunkt', fmtTime.format(endLocal)),
            const SizedBox(height: 6),
            _bulletRow('Dauer', '$durationMin Minuten'),
            if (nameRider.isNotEmpty) ...[const SizedBox(height: 6), _bulletRow('Reiter', nameRider)],
            if (nameHorse.isNotEmpty) ...[const SizedBox(height: 6), _bulletRow('Pferd', nameHorse)],
            if (descUsage.isNotEmpty) ...[const SizedBox(height: 6), _bulletRow('Verwendung', descUsage)],
            if (details.isNotEmpty) ...[const SizedBox(height: 6), _bulletRow('Details', details)],
            const SizedBox(height: 6),
            _bulletRow('Exklusiv', exclusive ? 'Ja' : 'Nein'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Buchen')),
        ],
      ),
    );

    if (confirmed != true) return;

    // step 5: call API
    final startUtc = startLocal.toUtc();
    final endUtc = endLocal.toUtc();

    setState(() => _loading = true);
    try {
      final created = await ApiService.createBooking(
        objectId: 1,
        startUtc: startUtc,
        endUtc: endUtc,
        exclusive: exclusive,
        details: details,
        nameRider: nameRider,
        nameHorse: nameHorse,
        descUsage: descUsage,
      );

      // update local events map
      final key = _dateOnly(created.start.toLocal());
      setState(() {
        _events.putIfAbsent(key, () => []).add(created);
      });

      // refresh authoritative data for week
      await _loadBookingsForWeek(_focusedDay);

      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buchung erfolgreich.')));
    } catch (e) {
      // Show the server message if available; the exception will contain response body in many cases
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Buchung nicht erfolgreich: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
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
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Reithalle Übersicht'),
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
                      return ListTile(
                        leading: b.exclusive ? Icon(Icons.lock, color: Colors.redAccent) : const Icon(Icons.event),
                        title: Text('${DateFormat('EEE dd.MM HH:mm', 'de_DE').format(b.start)} — ${DateFormat('HH:mm').format(b.end)}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((b.nameRider ?? '').isNotEmpty) Text('Reiter: ${b.nameRider}'),
                            if ((b.nameHorse ?? '').isNotEmpty) Text('Pferd: ${b.nameHorse}'),
                            if ((b.descUsage ?? '').isNotEmpty) Text('Verwendung: ${b.descUsage}'),
                            if ((b.details ?? '').isNotEmpty) Text('Details: ${b.details}'),
                          ],
                        ),
                        isThreeLine: true,
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