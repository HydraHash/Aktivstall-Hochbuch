import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../utils/picker_utils.dart';
import 'login_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool _loading = true;
  List<Booking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadMyBookings();
  }

  Future<void> _loadMyBookings() async {
    setState(() => _loading = true);
    try {
      final bookings = await ApiService.getMyBookings();
      // Sort by start time ascending, and only keep future ones
      final now = DateTime.now();
      final upcoming = bookings.where((b) => b.end.isAfter(now)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      setState(() {
        _bookings = upcoming;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), 
      (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _confirmDelete(Booking booking) async {
    final fmt = DateFormat('EEE dd.MM.yyyy HH:mm', 'de_DE');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Buchung löschen?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Datum: ${fmt.format(booking.start)} – ${fmt.format(booking.end)}'),
            if ((booking.nameRider ?? '').isNotEmpty) Text('Reiter: ${booking.nameRider}'),
            if ((booking.nameHorse ?? '').isNotEmpty) Text('Pferd: ${booking.nameHorse}'),
            if ((booking.descUsage ?? '').isNotEmpty) Text('Verwendung: ${booking.descUsage}'),
            if ((booking.details ?? '').isNotEmpty) Text('Details: ${booking.details}'),
            const SizedBox(height: 16),
            const Text('Wollen Sie diese Buchung wirklich entfernen?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteBooking(booking);
    }
  }

  Future<void> _deleteBooking(Booking booking) async {
    setState(() => _loading = true);
    try {
      await ApiService.deleteBooking(booking.id);
      setState(() => _bookings.removeWhere((b) => b.id == booking.id));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buchung erfolgreich gelöscht.'))
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showEditSheet(Booking booking) {
    // Initialize local state with current booking data
    DateTime selectedDate = booking.start.toLocal();
    TimeOfDay startTime = TimeOfDay.fromDateTime(booking.start.toLocal());
    TimeOfDay endTime = TimeOfDay.fromDateTime(booking.end.toLocal());
    bool exclusive = booking.exclusive;
    
    final riderCtrl = TextEditingController(text: booking.nameRider);
    final horseCtrl = TextEditingController(text: booking.nameHorse);
    final usageCtrl = TextEditingController(text: booking.descUsage);
    final detailsCtrl = TextEditingController(text: booking.details);

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Crucial for forms so the keyboard pushes it up
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final fmtDate = DateFormat('EEEE, dd.MM.yyyy', 'de_DE');
          
          return Padding(
            // Adds padding for the keyboard
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Buchung bearbeiten', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // --- DATE AND TIME CONTROLS ---
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Datum'),
                    subtitle: Text(fmtDate.format(selectedDate)),
                    onTap: () async {
                      final newDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (newDate != null) setModalState(() => selectedDate = newDate);
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.access_time),
                          title: const Text('Start'),
                          subtitle: Text(startTime.format(context)),
                          onTap: () async {
                            final newTime = await showNumericTimePicker(context: context, title: 'Startzeit anpassen', initial: startTime);
                            if (newTime != null) setModalState(() => startTime = newTime);
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.access_time_filled),
                          title: const Text('Ende'),
                          subtitle: Text(endTime.format(context)),
                          onTap: () async {
                            final newTime = await showNumericTimePicker(context: context, title: 'Endzeit anpassen', initial: endTime);
                            if (newTime != null) setModalState(() => endTime = newTime);
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(),

                  // --- TEXT FIELDS ---
                  TextField(controller: riderCtrl, decoration: const InputDecoration(labelText: 'Name Reiter')),
                  const SizedBox(height: 8),
                  TextField(controller: horseCtrl, decoration: const InputDecoration(labelText: 'Name Pferd')),
                  const SizedBox(height: 8),
                  TextField(controller: usageCtrl, decoration: const InputDecoration(labelText: 'Zweck / Nutzung')),
                  const SizedBox(height: 8),
                  
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: exclusive,
                    onChanged: (v) => setModalState(() => exclusive = v ?? false),
                    title: const Text('Halle exklusiv benötigt'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  const SizedBox(height: 16),
                  
                  // --- SAVE BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        setModalState(() => isSaving = true);
                        
                        // Combine Date and TimeOfDay
                        final newStartLocal = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, startTime.hour, startTime.minute);
                        final newEndLocal = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, endTime.hour, endTime.minute);

                        try {
                          await ApiService.updateBooking(
                            bookingId: booking.id,
                            objectId: booking.objectId, // Keep the same object
                            startUtc: newStartLocal.toUtc(),
                            endUtc: newEndLocal.toUtc(),
                            exclusive: exclusive,
                            nameRider: riderCtrl.text,
                            nameHorse: horseCtrl.text,
                            descUsage: usageCtrl.text,
                            details: detailsCtrl.text,
                          );

                          if (context.mounted) {
                            Navigator.pop(context); // Close the sheet
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Änderungen gespeichert!')));
                            _loadMyBookings(); // Refresh the list
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                          }
                        } finally {
                          setModalState(() => isSaving = false);
                        }
                      },
                      child: isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Speichern'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final reithalleBookings = _bookings.where((b) => b.objectId == 1).toList();
    final aussenplatzBookings = _bookings.where((b) => b.objectId == 2).toList();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Meine Buchungen')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMyBookings,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Section Reithalle ---
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text('Reithalle Innen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  ..._buildBookingSection(reithalleBookings, 'Keine Buchungen für die Reithalle.'),

                  // Visual Separator
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(thickness: 1.5, indent: 16, endIndent: 16),
                  ),

                  // Section Reitplatz ---
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 8),
                    child: Text('Reitplatz Außen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  ..._buildBookingSection(aussenplatzBookings, 'Keine Buchungen für den Reitplatz.'),
                  
                  // Space at the bottom
                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }

  // Helper 1: Show empty message or cards
  List<Widget> _buildBookingSection(List<Booking> sectionBookings, String emptyMessage) {
    if (sectionBookings.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            emptyMessage, 
            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        )
      ];
    }
    // If not empty, map the bookings to cards
    return sectionBookings.map((b) => _buildBookingCard(b)).toList();
  }

  // Helper 2: Exctracted Card build method
  Widget _buildBookingCard(Booking b) {
    final fmt = DateFormat('EEE dd.MM HH:mm', 'de_DE');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: b.objectId == 1
            ? const Icon(Icons.home, color: Colors.blueGrey)
            : const Icon(Icons.sunny, color: Colors.blueGrey),
        title: Text('${fmt.format(b.start)} — ${DateFormat('HH:mm').format(b.end)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((b.nameRider ?? '').isNotEmpty) Text('Reiter: ${b.nameRider}'),
            if ((b.nameHorse ?? '').isNotEmpty) Text('Pferd: ${b.nameHorse}'),
            if ((b.descUsage ?? '').isNotEmpty) Text('Verwendung: ${b.descUsage}'),
            if ((b.details ?? '').isNotEmpty) Text('Details: ${b.details}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blueGrey), onPressed: () => _showEditSheet(b)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _confirmDelete(b)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}