import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../widgets/brand_header.dart';
import '../config/brand.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  bool _loading = false;

  void _register() async {
    setState(() => _loading = true);
    try {
      await ApiService.register(emailCtrl.text, passwordCtrl.text, codeCtrl.text);
      if (context.mounted) {
        Navigator.pop(context); // back to login
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrierung erfolgreich.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registrierung fehlgeschlagen: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 40),
          const BrandHeader(title: "", showSubtitle: false, logoHeight: 120),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
                  const SizedBox(height: 12),
                  TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: "Passwort"), obscureText: true),
                  const SizedBox(height: 12),
                  TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Registrierungs-Code")),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: _loading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(backgroundColor: Brand.primary),
                      child: const Text('Registrieren', style: TextStyle(color: Colors.black87),),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => 
                  const LoginScreen())), child: const Text('Zurück zum Login', style: TextStyle(color: Colors.black87),))
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}