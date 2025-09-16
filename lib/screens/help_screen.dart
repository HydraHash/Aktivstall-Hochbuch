import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/brand.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _controller = TextEditingController();
  String? _selectedOs;
  bool _sending = false;

  Future<void> _sendFeedback() async {
    final text = _controller.text.trim();
    final os = _selectedOs ?? 'Other';
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte beschreiben Sie das Problem oder Feedback genauer.')));
      return;
    }
    setState(() => _sending = true);
    try {
      final ok = await ApiService.postFeedback(os: os, message: text);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback erfolgreich gesendet — Vielen Dank!')));
        _controller.clear();
        setState(() => _selectedOs = null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fehler beim Senden, bitte versuchen Sie es später erneut.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback konnte nicht gesendet werden - bitte senden Sie uns eine Mail.')));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hilfe & Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Melden Sie ein technisches Problem oder senden Sie uns Feedback. Alternativ können Sie uns auch eine E-Mail unter technik@aktivstall-hochbuch.de zukommen lassen.',
              style: TextStyle(color: Brand.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedOs,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Betriebssystem'),
              items: const [
                DropdownMenuItem(value: 'Android', child: Text('Android')),
                DropdownMenuItem(value: 'iOS', child: Text('iOS')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _selectedOs = v),
              validator: (v) => v == null ? 'Bitte wählen' : null,
            ),
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