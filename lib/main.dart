// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/brand.dart';
import 'providers/booking_provider.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/help_screen.dart';

void main() {
  runApp(const BookingApp());
}

class BookingApp extends StatelessWidget {
  const BookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide BookingProvider app-wide (objectId = 1)
    return ChangeNotifierProvider(
      create: (_) => BookingProvider(objectId: 1),
      child: MaterialApp(
        title: Brand.appName,
        theme: Brand.themeData(),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 0 = Home, 1 = Calendar, 2 = Help
  int _selectedIndex = 0;

  static const List<String> _titles = ['Home', 'Calendar', 'Help'];
  static final List<Widget> _pages = [
    HomeScreen(),
    CalendarScreen(),
    HelpScreen(),
  ];

  void _select(int idx) {
    setState(() => _selectedIndex = idx);
    Navigator.of(context).pop(); // close drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Brand.appName),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Brand.primary),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: Image.asset(Brand.logoAsset, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 8),
                    Text(Brand.appName, style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
              ListTile(
                leading: Image.asset(Brand.iconAsset, width: 24, height: 24),
                title: const Text('Home'),
                selected: _selectedIndex == 0,
                onTap: () => _select(0),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Calendar'),
                selected: _selectedIndex == 1,
                onTap: () => _select(1),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help'),
                selected: _selectedIndex == 2,
                onTap: () => _select(2),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text('Version 1.0', style: TextStyle(color: Colors.grey[600])),
              )
            ],
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      // optional floating action button for quick booking (only visible on Calendar)
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                // Open calendar quick-create: trigger a selection on calendar or open dialog
                // For now, do nothing or implement quick action later.
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}