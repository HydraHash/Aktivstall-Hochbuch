import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
        Navigator.pop(context); // go back to login
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registrierung erfolgreich.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registrierung fehlgeschlagen: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Registrieren")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: "Passwort"), obscureText: true),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Registrierungscode", hintText: "z.B. u5tg7g8t9")),
            const SizedBox(height: 20),
            _loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _register, child: const Text("Registrieren"))
          ]),
        ));
  }
}