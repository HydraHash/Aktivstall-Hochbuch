import 'package:flutter/material.dart';

class BookingDialog extends StatefulWidget {
  final DateTime initialDay;
  const BookingDialog({required this.initialDay, super.key});
  @override State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  int _durationMinutes = 60;

  TimeOfDay _roundTo15(TimeOfDay t) {
    final min = ((t.minute + 7) / 15).floor() * 15;
    var hour = t.hour;
    var minute = min;
    if (minute >= 60) { hour += 1; minute = 0; }
    return TimeOfDay(hour: hour % 24, minute: minute);
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(context: context, initialTime: _start);
    if (picked == null) return;
    setState(()=> _start = _roundTo15(picked));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create booking'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Start time'),
            subtitle: Text(_start.format(context)),
            onTap: _pickStart,
          ),
          const SizedBox(height:8),
          Row(
            children: [
              const Text('Duration:'),
              const SizedBox(width:10),
              DropdownButton<int>(
                value: _durationMinutes,
                items: List.generate((240/15).round(), (i) => (i+1)*15)
                  .map((m)=> DropdownMenuItem(value: m, child: Text('$m min')))
                  .toList(),
                onChanged: (v) => setState(()=> _durationMinutes = v!),
              )
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: ()=> Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: (){
          final startLocal = DateTime(widget.initialDay.year, widget.initialDay.month, widget.initialDay.day, _start.hour, _start.minute);
          if (_durationMinutes < 15 || _durationMinutes > 240) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duration must be 15–240 minutes')));
            return;
          }
          Navigator.of(context).pop({'start': startLocal, 'duration': Duration(minutes: _durationMinutes)});
        }, child: const Text('Create')),
      ],
    );
  }
}
