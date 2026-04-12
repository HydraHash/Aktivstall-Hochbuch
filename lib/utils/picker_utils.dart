import 'package:flutter/material.dart';

// Numeric time picker dialog: returns TimeOfDay or null
  Future<TimeOfDay?> showNumericTimePicker({
    required BuildContext context,
    required String title,
    required TimeOfDay initial,
  }) async {
    final hourCtrl = TextEditingController(text: initial.hour.toString().padLeft(2, '0'));
    final minCtrl = TextEditingController(text: initial.minute.toString().padLeft(2, '0'));
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: Row(
            children: [
              Flexible(
                child: TextFormField(
                  controller: hourCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stunden'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Notwendig';
                    final i = int.tryParse(v);
                    if (i == null || i < 0 || i > 23) return 'Ungültig';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: TextFormField(
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minuten'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Notwendig';
                    final i = int.tryParse(v);
                    if (i == null || i < 0 || i > 59) return 'Ungültig';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Zurück')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final h = int.parse(hourCtrl.text);
                final m = int.parse(minCtrl.text);
                Navigator.pop(c, TimeOfDay(hour: h, minute: m));
              }
            },
            child: const Text('Weiter'),
          ),
        ],
      ),
    );

    return result;
  }