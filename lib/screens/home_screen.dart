// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../config/brand.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simple welcome screen with logo centered and subtle background color
    return Container(
      color: Brand.accent.withOpacity(0.12), // soft tinted background
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // use the logo asset
            SizedBox(
              width: 180,
              height: 180,
              child: Image.asset(Brand.logoAsset, fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to ${Brand.appName}',
              style: TextStyle(fontSize: 20, color: Brand.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Use the calendar to book slots. '
                'Open the drawer to navigate between screens.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}