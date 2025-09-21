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
              DrawerHeader(child: Center(child: Image.asset('assets/icon.png'))),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // use the same header, now title shown optionally (pass app name)
            const BrandHeader(title: "", showSubtitle: false),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760, minWidth: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Text(
                        'Willkommen in der App des Aktivstall Hochbuch. Hier können Sie die Hallenbelegungen einsehen und Plätze buchen.\n\nWir entwickeln die App ständig weiter, dabei sind wir auch auf Ihr Feedback angewiesen. Bei Fragen oder Feedback nutzen Sie bitte den Hilfebereich.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}