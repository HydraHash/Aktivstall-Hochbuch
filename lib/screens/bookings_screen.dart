import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
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
      final success = await ApiService.deleteBooking(booking.id);
      if (success) {
        setState(() => _bookings.removeWhere((b) => b.id == booking.id));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Buchung gelöscht.')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Löschen fehlgeschlagen.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler beim Löschen: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meine Buchungen')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(child: Text('Keine bevorstehenden Buchungen.'))
              : RefreshIndicator(
                  onRefresh: _loadMyBookings,
                  child: ListView.builder(
                    itemCount: _bookings.length,
                    itemBuilder: (context, i) {
                      final b = _bookings[i];
                      final fmt = DateFormat('EEE dd.MM HH:mm', 'de_DE');
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: b.exclusive
                              ? const Icon(Icons.lock, color: Colors.redAccent)
                              : const Icon(Icons.event),
                          title: Text(
                            '${fmt.format(b.start)} — ${DateFormat('HH:mm').format(b.end)}',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((b.nameRider ?? '').isNotEmpty) Text('Reiter: ${b.nameRider}'),
                              if ((b.nameHorse ?? '').isNotEmpty) Text('Pferd: ${b.nameHorse}'),
                              if ((b.descUsage ?? '').isNotEmpty) Text('Verwendung: ${b.descUsage}'),
                              if ((b.details ?? '').isNotEmpty) Text('Details: ${b.details}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _confirmDelete(b),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}