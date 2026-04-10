import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/outside_calendar_screen.dart';
import '../screens/bookings_screen.dart';
import '../screens/help_screen.dart';
import '../screens/login_screen.dart';
import '../services/api_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _logout(BuildContext context) async {
    await ApiService.logout();
    if (context.mounted) {
      // Use pushAndRemoveUntil to clear the entire navigation history on logout
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Helper method to navigate cleanly
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close the drawer first
    Navigator.pushReplacement( // Swap the current screen with the new one
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            DrawerHeader(child: Center(child: Image.asset('assets/icon.png'))),
            ListTile(leading: const Icon(Icons.dashboard), title: const Text("Dashboard"), onTap: () => _navigateTo(context, const HomeScreen())),
            ListTile(leading: const Icon(Icons.home), title: const Text("Reithalle Belegungsplan"), onTap: () => _navigateTo(context, const CalendarScreen())),
            ListTile(leading: const Icon(Icons.sunny), title: const Text("Reitplatz Belegungsplan"), onTap: () => _navigateTo(context, const OutsideCalendarScreen())),
            ListTile(leading: const Icon(Icons.list_alt), title: const Text("Meine Buchungen"), onTap: () => _navigateTo(context, const MyBookingsScreen())),
            const Divider(),
            ListTile(leading: const Icon(Icons.help), title: const Text("Hilfe und Feedback"), onTap: () => _navigateTo(context, const HelpScreen())),
            ListTile(leading: const Icon(Icons.logout), title: const Text("Logout"), onTap: () => _logout(context)),
          ],
        ),
      ),
    );
  }
}