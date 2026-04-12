import 'package:aktivstall_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';
import '../config/brand.dart';
import '../services/api_service.dart';
import '../models/booking.dart';
import 'calendar_screen.dart';
import 'outside_calendar_screen.dart';
import 'bookings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  
  Booking? _nextUserBooking;
  
  Booking? _nextHalleBooking;
  int _halleUpcomingCount = 0;
  
  Booking? _nextPlatzBooking;
  int _platzUpcomingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // ISO week calculation
  Map<String, int> _isoWeekYear(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    final weekday = d.weekday;
    final thursday = d.add(Duration(days: 4 - weekday));
    final isoYear = thursday.year;
    final firstThursday = DateTime.utc(isoYear, 1, 4);
    final daysDiff = thursday.difference(DateTime.utc(isoYear, 1, 1)).inDays;
    final weekNumber = ((daysDiff + (firstThursday.weekday - 1)) / 7).floor() + 1;
    return {'year': isoYear, 'week': weekNumber};
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final map = _isoWeekYear(now);
      
      // Executes all three api calls at the same time
      final results = await Future.wait([
        ApiService.getMyBookings(),
        ApiService.getBookingsForWeek(year: map['year']!, week: map['week']!, objectId: 1),
        ApiService.getBookingsForWeek(year: map['year']!, week: map['week']!, objectId: 2),
      ]);

      final myBookings = results[0];
      final halleBookings = results[1];
      final platzBookings = results[2];

      // Next user booking
      final myFuture = myBookings.where((b) => b.end.isAfter(now)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      _nextUserBooking = myFuture.isNotEmpty ? myFuture.first : null;

      // Upcoing Reithalle Buchungen
      final halleToday = halleBookings.where((b) => 
        b.start.year == now.year && b.start.month == now.month && b.start.day == now.day && b.end.isAfter(now)
      ).toList()..sort((a, b) => a.start.compareTo(b.start));
      
      _nextHalleBooking = halleToday.isNotEmpty ? halleToday.first : null;
      _halleUpcomingCount = halleToday.length;

      // Upcoming Reitplatz Buchungen
      final platzToday = platzBookings.where((b) => 
        b.start.year == now.year && b.start.month == now.month && b.start.day == now.day && b.end.isAfter(now)
      ).toList()..sort((a, b) => a.start.compareTo(b.start));

      _nextPlatzBooking = platzToday.isNotEmpty ? platzToday.first : null;
      _platzUpcomingCount = platzToday.length;

    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  Widget _buildMyNextBookingCard() {
    if (_nextUserBooking == null) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Sie haben aktuell keine anstehenden Buchungen.', style: TextStyle(fontStyle: FontStyle.italic))),
        ),
      );
    }

    final b = _nextUserBooking!;
    final fmtDate = DateFormat('EEEE, dd.MM.', 'de_DE');
    final fmtTime = DateFormat('HH:mm');
    final objectName = b.objectId == 1 ? 'Reithalle' : 'Außenplatz';
    final iconColor = b.objectId == 1 ? Colors.blue : Colors.green;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), 
          side: BorderSide(color: Brand.primary.withOpacity(0.3))
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.2),
            child: Icon(Icons.event, color: iconColor),
          ),
          title: const Text('Ihre nächste Buchung', style: TextStyle(fontSize: 12, color: Colors.grey)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(objectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              Text('${fmtDate.format(b.start)} | ${fmtTime.format(b.start)} - ${fmtTime.format(b.end)} Uhr'),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildFacilityOverview(String title, Booking? nextBooking, int count, Widget targetScreen) {
    final fmtTime = DateFormat('HH:mm');
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 8),
            
            // Next Booking Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.schedule, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nextBooking != null 
                        ? 'Nächste Belegung: ${fmtTime.format(nextBooking.start)} - ${fmtTime.format(nextBooking.end)} Uhr' 
                        : 'Heute keine weiteren Belegungen.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Upcoming Count Info
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Anstehende Buchungen heute: $count'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Navigation Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen)),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Zum Belegungsplan'),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Brand.primary,
      ),
      body: Stack(
        children: [
          // Centered Grayed-Out Background Icon
          Center(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/icon.png',
                width: 250,
              ),
            ),
          ),
          
          // Foreground Content
          _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 16, bottom: 40),
                  children: [
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Text(
                        'Willkommen im Aktivstall Hochbuch!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildMyNextBookingCard(),
                    
                    const SizedBox(height: 16),
                    
                    _buildFacilityOverview(
                      'Reithalle', 
                      _nextHalleBooking, 
                      _halleUpcomingCount, 
                      const CalendarScreen()
                    ),
                    
                    _buildFacilityOverview(
                      'Reitplatz', 
                      _nextPlatzBooking, 
                      _platzUpcomingCount, 
                      const OutsideCalendarScreen()
                    ),

                  ],
                ),
              ),
        ],
      ),
    );
  }
}