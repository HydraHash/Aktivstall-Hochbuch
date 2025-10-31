import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/brand.dart';
import '../widgets/brand_header.dart';
import 'login_screen.dart';

class PasswordResetConfirmScreen extends StatefulWidget {
  final String email;
  const PasswordResetConfirmScreen({super.key, required this.email});

  @override
  State<PasswordResetConfirmScreen> createState() => _PasswordResetConfirmScreenState();
}

class _PasswordResetConfirmScreenState extends State<PasswordResetConfirmScreen> {
  final _pwCtrl = TextEditingController();
  late final TextEditingController emailCtrl;
  bool _loading = false;

  @override
  void initState(){
    super.initState();
    emailCtrl = TextEditingController(text: widget.email);
  }

  void _submit() async {
    setState(() => _loading = true);
    try {
      await ApiService.confirmPasswordReset(emailCtrl.text, _pwCtrl.text);
      if (context.mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => 
          const LoginScreen()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwort erfolgreich geändert.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          const BrandHeader(title: "", showSubtitle: false),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: "Aktuelle E-Mail Adresse")
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _pwCtrl,
                    decoration: const InputDecoration(labelText: "Neues Passwort"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Brand.primary),
                            onPressed: _submit,
                            child: const Text("Passwort ändern", style: TextStyle(color: Colors.black87)),
                          ),
                  ),
                  TextButton(
                      onPressed: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => 
                          const LoginScreen())),
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
