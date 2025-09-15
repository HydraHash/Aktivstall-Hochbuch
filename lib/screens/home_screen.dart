import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'help_screen.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _logout() async {
    await ApiService.logout();
    if (context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Center(child: Text("Aktivstall Hochbuch"))),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Kalender"),
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text("Hilfe und Feedback"),
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: _logout,
            ),
          ],
        ),
      ),
      appBar: AppBar(title: const Text("Home")),
      body: const Center(child: Text("Herzlich Willkommen! Wir entwickeln diese App ständig weiter, Ihr Feedback hilft uns dabei. Nutzen Sie bitte bei technischen Problemen oder Anregungen den Hilfebereich im Menü.")),
    );
  }
}