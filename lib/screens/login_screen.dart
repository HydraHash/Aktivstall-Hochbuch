import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'password_reset_screen.dart';
import '../widgets/brand_header.dart';
import '../config/brand.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool _loading = false;

  void _login() async {
    setState(() => _loading = true);
    try {
      await ApiService.login(emailCtrl.text, passwordCtrl.text);
      if (context.mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login fehlgeschlagen: Bitte prüfen Sie Mailadresse und Passwort!")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // no appbar on login, full-screen header
      body: SingleChildScrollView(
        child: Column(
          children: [
            // responsive header (no extra sizedbox)
            const BrandHeader(title: "", showSubtitle: false),
            const SizedBox(height: 12),
            // center the card and keep it sized to content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
                      const SizedBox(height: 12),
                      TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: "Passwort"), obscureText: true),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: _loading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(backgroundColor: Brand.primary),
                          child: const Text('Login', style: TextStyle(color: Colors.black87),),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => 
                      const RegisterScreen())), child: const Text("Registrieren", style: TextStyle(color: Colors.black87),)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => 
                      const PasswordResetScreen())), child: const Text("Passwort vergessen", style: TextStyle(color: Colors.black87),))
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}