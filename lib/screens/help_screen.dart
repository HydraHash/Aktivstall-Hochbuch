// lib/screens/help_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../config/brand.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  Future<void> _sendFeedback() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte beschreiben Sie das Problem oder Feedback genauer.')));
      return;
    }
    setState(() => _sending = true);

    final token = await StorageService.readToken();
    final uri = Uri.parse('${_apiBase()}/feedback'); // backend endpoint (if exists)
    try {
      final res = await http.post(uri,
        headers: {
          if (token != null) 'Authorization': token,
          'Content-Type': 'application/json'
        },
        body: '{"message": ${Uri.encodeComponent(text)}}',
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback erfolgreich gesendet — Vielen Dank!')));
        _controller.clear();
      } else {
        // fallback: show success locally (if backend not present)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server response: ${res.statusCode}')));
      }
    } catch (e) {
      // If backend not available, still provide local feedback
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback konnte nicht gesendet werden - bitte senden Sie uns eine Mail.')));
    } finally {
      setState(() => _sending = false);
    }
  }

  String _apiBase(){
    // copy the same base url used in ApiService
    return 'https://app.aktivstall-hochbuch.de';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hilfe & Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Bitte beschreiben Sie das Problem oder Feedback genauer.',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _sendFeedback,
                    icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                    label: const Text('Senden'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}