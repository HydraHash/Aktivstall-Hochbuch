import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import this
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
  File? _selectedImage; // Holds the picked image
  bool _sending = false;

  final ImagePicker _picker = ImagePicker();

  // Pick image function
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _sendFeedback() async {
    final text = _controller.text.trim();
    final os = _selectedOs ?? 'Other';
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte beschreiben Sie das Problem oder Feedback genauer.')));
      return;
    }
    setState(() => _sending = true);
    try {
      // Pass the image file to the API
      final ok = await ApiService.postFeedback(os: os, message: text, imageFile: _selectedImage);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback erfolgreich gesendet — Vielen Dank!')));
        _controller.clear();
        setState(() {
          _selectedOs = null;
          _selectedImage = null; // Clear image on success
        });
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
      body: SingleChildScrollView( // Changed to SingleChildScrollView to prevent keyboard overflow
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                DropdownMenuItem(value: 'Other', child: Text('Andere')),
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
            
            // Image Picker Button & Preview
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Screenshot anhängen'),
                ),
              ],
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Remove image button
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _sendFeedback,
                    icon: _sending 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                      : const Icon(Icons.send),
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