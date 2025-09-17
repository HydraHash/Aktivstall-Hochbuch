import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'help_screen.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../widgets/brand_header.dart';
import '../config/brand.dart';

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
        child: SafeArea(
          child: ListView(
            children: [
              DrawerHeader(child: Center(child: Text(Brand.appName, style: Theme.of(context).textTheme.titleLarge))),
              ListTile(leading: const Icon(Icons.home), title: const Text("Home"), onTap: () => Navigator.pop(context)),
              ListTile(leading: const Icon(Icons.calendar_today), title: const Text("Kalender"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()))),
              ListTile(leading: const Icon(Icons.help), title: const Text("Hilfe und Feedback"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))),
              const Divider(),
              ListTile(leading: const Icon(Icons.logout), title: const Text("Logout"), onTap: _logout),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Brand.primary,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          const BrandHeader(title: "", showSubtitle: false, logoHeight: 120),
          // Body content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Text(
                    'Willkommen bei Aktivstall Hochbuch. Hier können Sie die Belegungen einsehen und Plätze buchen. Bei Fragen nutzen Sie bitte den Hilfebereich.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}