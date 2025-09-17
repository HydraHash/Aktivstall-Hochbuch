import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'config/brand.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _decideStartPage() async {
    final loggedIn = await AuthService.isLoggedIn();
    return loggedIn ? const HomeScreen() : const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Brand.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Brand.primary),
        primaryColor: Brand.primary,
        scaffoldBackgroundColor: Colors.white,
        textTheme: Brand.textTheme(GoogleFonts.interTextTheme(base.textTheme)), // or remove GoogleFonts
        useMaterial3: true,
      ),
      home: FutureBuilder<Widget>(
        future: _decideStartPage(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.data!;
        },
      ),
    );
  }
}