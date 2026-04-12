import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/booking.dart';
import '../widgets/app_drawer.dart';
import '../utils/picker_utils.dart';
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

  // Main flow to create booking using numeric time inputs and auto-end = +1h
  Future<void> _createBookingFlow() async {
  DateTime? pickedDate;
  TimeOfDay? startTOD;
  TimeOfDay? endTOD;
  String? serialInterval;
  String? numberIntervals;
  List<String> numberIntervalsList = <String>['2x', '3x', '4x', '5x'];

  final riderCtrl = TextEditingController();
  final horseCtrl = TextEditingController();
  final usageCtrl = TextEditingController();
  final detailsCtrl = TextEditingController();
  
  bool exclusive = false;
  bool serialBooking = false;

  int currentStep = 0;
  bool isFlowActive = true;

  while (isFlowActive) {
    switch (currentStep) {
      
      // STEP 1: DATE PICKER
      case 0:
        final firstDate = DateTime.now();
        final initialDate = pickedDate ?? (_focusedDay.isBefore(firstDate) ? firstDate : _focusedDay);

        final newDate = await showDatePicker(
          context: context,
          locale: const Locale('de', 'DE'),
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: DateTime.now().add(const Duration(days: 365)),
          helpText: 'Datum auswählen',
          confirmText: 'Weiter',
          cancelText: 'Abbrechen',
        );

        if (newDate == null) {
          isFlowActive = false; 
        } else {
          pickedDate = newDate;
          currentStep++;
        }
        break;

      // STEP 2: START TIME
      case 1:
        // Calculate default only if not already set (or reset based on date logic if needed)
        final now = DateTime.now();
        int nextQuarter = ((now.minute + 14) ~/ 15) * 15;
        if (nextQuarter == 60) nextQuarter = 00;
        
        // If we have a previous selection, use it, otherwise default
        final initial = startTOD ?? TimeOfDay(hour: now.hour, minute: nextQuarter);

        final newStart = await showNumericTimePicker(
          context: context,
          title: 'Startzeit wählen:',
          initial: initial,
        );

        if (newStart == null) {
          currentStep--;
        } else {
          startTOD = newStart;
          currentStep = 2;
        }
        break;

      // STEP 3: END TIME
      case 2:
        if (pickedDate == null || startTOD == null) {
          currentStep--; 
          break; 
        }
        
        final startLocal = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, startTOD.hour, startTOD.minute);
        
        final defaultEnd = startLocal.add(const Duration(hours: 1));
        final initialEnd = endTOD ?? TimeOfDay(hour: defaultEnd.hour, minute: defaultEnd.minute);

        final newEnd = await showNumericTimePicker(
          context: context,
          title: 'Endzeit wählen:',
          initial: initialEnd,
        );

        if (newEnd == null) {
          currentStep = 1;
          break;
        }

        // --- VALIDATION LOGIC ---
        final endLocal = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, newEnd.hour, newEnd.minute);

        if (!endLocal.isAfter(startLocal)) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endzeit muss nach Startzeit sein!')));
          break; 
        }

        final durationMin = endLocal.difference(startLocal).inMinutes;
        if (durationMin < 15 || durationMin > 240) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dauer muss 15-240 Min sein!')));
          break; 
        }

        endTOD = newEnd;
        currentStep = 3;
        break;

      // STEP 4: METADATA
      case 3:
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false, // Force user to use buttons
          builder: (c) {
            return StatefulBuilder(builder: (ctx, setStateDialog) {
              return AlertDialog(
                title: const Text('Weitere Angaben'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Controllers are defined at top, so text persists!
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
                      CheckboxListTile(
                        value: serialBooking,
                        onChanged: (v) => setStateDialog(() => serialBooking = v ?? false),
                        title: const Text('Serienbuchung anlegen'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
                actions: [
                  // BUTTON: BACK
                  TextButton(
                    onPressed: () => Navigator.pop(c, false), // Return false for Back
                    child: const Text('Zurück'),
                  ),
                  // BUTTON: NEXT
                  ElevatedButton(
                    onPressed: () => Navigator.pop(c, true), // Return true for Next
                    child: const Text('Weiter'),
                  ),
                ],
              );
            });
          },
        );

        if (result == true) {
          if (serialBooking) {
            currentStep = 5;
          } else {
            currentStep = 4;
          }
        } else {currentStep = 2;}

      // STEP 5: CONFIRMATION
      case 4:
        final startLocal = DateTime(pickedDate!.year, pickedDate.month, pickedDate.day, startTOD!.hour, startTOD.minute);
        final endLocal = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, endTOD!.hour, endTOD.minute);
        final durationMin = endLocal.difference(startLocal).inMinutes;

        final fmtDate = DateFormat('EEEE, dd.MM.yyyy', 'de_DE');
        final fmtTime = DateFormat('HH:mm');

        int totalBookings = 1;
        if (serialBooking && numberIntervals != null){
          totalBookings = int.parse(numberIntervals!.replaceAll('x', ''));
        }

        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false, 
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
                  if (riderCtrl.text != "") ...[const SizedBox(height: 6), _bulletRow('Reiter', riderCtrl.text)],
                  if (horseCtrl.text != "") ...[const SizedBox(height: 6), _bulletRow('Pferd', horseCtrl.text)],
                  if (usageCtrl.text != "") ...[const SizedBox(height: 6), _bulletRow('Verwendung', usageCtrl.text)],
                  if (detailsCtrl.text != "") ...[const SizedBox(height: 6), _bulletRow('Details', detailsCtrl.text)],
                  const SizedBox(height: 6),
                  _bulletRow('Exklusiv', exclusive ? 'Ja' : 'Nein'),

                  if (serialBooking) ...[ //Add serial information to confirmation page
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 6),
                    _bulletRow('Interval', serialInterval ?? ''),
                    const SizedBox(height: 6),
                    _bulletRow('Anzahl Termine', '$totalBookings'),
                  ]
               ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Zurück'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Buchen'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
            setState(() => _loading = true);

            //Generate Lists for Start and End times
            List<DateTime> startList = [];
            List<DateTime> endList = [];

            for (int i = 0; i < totalBookings; i++){
              DateTime currentStart = startLocal;
              DateTime currentEnd = endLocal;

              if (serialBooking && i > 0){
                int daysToAdd = 0;  //Add days based on chosen interval
                if (serialInterval == 'Täglich') daysToAdd = 1 * i;
                if (serialInterval == 'Wöchentlich') daysToAdd = 7 * i;
                if (serialInterval == 'Alle 2 Wochen') daysToAdd = 14 * i;
                if (serialInterval == 'Monatlich') {
                  currentStart = DateTime(startLocal.year, startLocal.month + i, startLocal.day, startLocal.hour, startLocal.minute);
                  currentEnd = DateTime(endLocal.year, endLocal.month + i, endLocal.day, endLocal.hour, endLocal.minute);
                } else {
                  currentStart = startLocal.add(Duration(days: daysToAdd));
                  currentEnd = endLocal.add(Duration(days: daysToAdd));
                }
              }
              startList.add(currentStart.toUtc());
              endList.add(currentEnd.toUtc());
            }

            try {
              final createdList = await ApiService.createBooking(
                objectId: 1,
                startUtcs: startList,
                endUtcs: endList,
                exclusive: exclusive,
                details: detailsCtrl.text,
                nameRider: riderCtrl.text,
                nameHorse: horseCtrl.text,
                descUsage: usageCtrl.text,
              );

              // update local events map with all created bookings
              setState(() {
                for (var booking in createdList) {
                  final key = _dateOnly(booking.start.toLocal());
                  _events.putIfAbsent(key, () => []).add(booking);
                }
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
           isFlowActive = false; // Break loop
        } else if (serialBooking == false){
           currentStep = 3;
        } else {currentStep = 5;}
        break;
      
      //Step 6: only when serialBooking button is wanted
      case 5:
        const List<String> intervalList = <String>['Täglich', 'Wöchentlich', 'Alle 2 Wochen', 'Monatlich'];
        const List<String> numberByWeeklyList = <String>['2x', '3x'];
        const List<String> numberMonthlyList = <String>['2x'];

        // Default to "Alle 7 Tage" if nothing selected yet
        serialInterval ??= intervalList[1];
        numberIntervals ??= numberIntervalsList[1];

        final serialResult = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (c) => StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return AlertDialog(
                title: const Text('Serien-Buchung'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Intervall wählen:'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: serialInterval,
                          isExpanded: true,
                          items: intervalList.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setStateDialog(() => serialInterval = newValue);
                            }
                            if (newValue == 'Alle 2 Wochen'){
                              setStateDialog(() => numberIntervalsList = numberByWeeklyList);
                            } else if (newValue == 'Monatlich'){
                              setStateDialog(() => numberIntervalsList = numberMonthlyList);
                            }
                          },
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: numberIntervals,
                          isExpanded: true,
                          items: numberIntervalsList.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setStateDialog(() => numberIntervals = newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                  //pickedDate is current date,

                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false), // Return false for Back
                    child: const Text('Zurück'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(c, true), // Return true for Next
                    child: const Text('Weiter'),
                  ),
                ],
              );
            },
          ),
        );

        if (serialResult == true) {
          currentStep = 4;
        } else {
          currentStep = 3;
        }
        break;
        
      default:
        isFlowActive = false;
    }
  }

  // Dispose controllers after flow is done
  riderCtrl.dispose();
  horseCtrl.dispose();
  usageCtrl.dispose();
  detailsCtrl.dispose();
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
      drawer: const AppDrawer(),
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Reithalle Innen 20x40m'),
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