import '../models/reminders_model.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class AddReminderScreen extends StatefulWidget {
  final ReminderModel? reminder;

  const AddReminderScreen({super.key, this.reminder});

  @override
  _AddReminderScreenState createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  TimeOfDay? _selectedTime;
  bool _isEnabled = true;
  late Box<ReminderModel> remindersBox;

  @override
  void initState() {
    super.initState();
    remindersBox = Hive.box<ReminderModel>('reminders');
    if (widget.reminder != null) {
      _messageController.text = widget.reminder!.message;
      _selectedTime = TimeOfDay(
        hour: widget.reminder!.time.hour,
        minute: widget.reminder!.time.minute,
      );
      _isEnabled = widget.reminder!.isEnabled;
    } else {
      _selectedTime = TimeOfDay.now();
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime!,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveReminder() {
    if (_formKey.currentState!.validate() && _selectedTime != null) {
      final DateTime now = DateTime.now();
      final DateTime reminderTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (widget.reminder == null) {
        remindersBox.add(
          ReminderModel(
            id: Uuid().v4(),
            time: reminderTime,
            message: _messageController.text,
            isEnabled: _isEnabled,
          ),
        );
      } else {
        widget.reminder!.time = reminderTime;
        widget.reminder!.message = _messageController.text;
        widget.reminder!.isEnabled = _isEnabled;
        widget.reminder!.save();
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? "Add Reminder" : "Edit Reminder"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Time picker row with a smooth transition
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blue),
                      SizedBox(width: 16),
                      Text(
                        _selectedTime!.format(context),
                        style: TextStyle(fontSize: 18),
                      ),
                      Spacer(),
                      Icon(Icons.edit, color: Colors.blue),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Reminder message
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: "Reminder Message",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter a message" : null,
              ),
              SizedBox(height: 16),
              // Enable/disable toggle
              SwitchListTile(
                title: Text(
                  "Enable Reminder",
                  style: TextStyle(color: Colors.blue),
                ),
                value: _isEnabled,
                activeColor: Colors.blue,
                onChanged: (value) {
                  setState(() {
                    _isEnabled = value;
                  });
                },
              ),
              Spacer(),
              // Save button with an animation on tap
              ElevatedButton(
                onPressed: _saveReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("Save Reminder"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
