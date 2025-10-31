import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/brand_header.dart';
import '../config/brand.dart';
import 'password_reset_confirm_screen.dart';


class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});
  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final emailCtrl = TextEditingController();
  // Removed passwordCtrl and codeCtrl
  bool _loading = false;

  void _resetPassword() async {
    setState(() => _loading = true);
    try {
      // Assume an ApiService method exists for password reset
      await ApiService.requestPasswordReset(emailCtrl.text);
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PasswordResetConfirmScreen(email: emailCtrl.text)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          // responsive header (no extra sizedbox)
          const BrandHeader(title: "", showSubtitle: false),
          //const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const Text(
                    'Geben Sie hier die E-Mail Adresse ein, die Sie zur Anmeldung verwendet haben.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: "Email")),
                  const SizedBox(height: 18), // Adjusted spacing
                  SizedBox(
                    width: double.infinity,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _resetPassword, // Changed function
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Brand.primary),
                            child: const Text(
                              'Passwort zurücksetzen', // Changed text
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                      onPressed: () =>
                          Navigator.pop(context), // Changed to pop
                      child: const Text(
                        'Zurück zum Login',
                        style: TextStyle(color: Colors.black87),
                      ))
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}