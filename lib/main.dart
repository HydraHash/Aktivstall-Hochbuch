import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/brand.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize German locale (and primary fallback)
  await initializeDateFormatting('de_DE', null);
  Intl.defaultLocale = 'de_DE';
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
        textTheme: Brand.textTheme(GoogleFonts.interTextTheme(base.textTheme)),
        useMaterial3: true,
      ),

      // 2. ADD THESE LINES TO CONFIGURE LOCALIZATION
      locale: const Locale('de', 'DE'), // Set the default locale
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de', 'DE'), // German
        Locale('en', 'US'), // English (as a fallback)
      ],
      // --- END OF FIX ---

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