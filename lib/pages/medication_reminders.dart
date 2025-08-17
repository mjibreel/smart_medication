import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

// Add Medication model in same file for reference
class Medication {
  final String id;
  final String name;
  final String dosage;
  final List<String> times;
  final int days;
  bool isDone;

  Medication({
    this.id = '',
    required this.name,
    required this.dosage,
    required this.times,
    required this.days,
    this.isDone = false,
  });
}

class MedicationReminderPage extends StatefulWidget {
  final Medication? medication;

  const MedicationReminderPage({
    super.key,
    this.medication,
  });

  @override
  _MedicationReminderPageState createState() => _MedicationReminderPageState();
}

class _MedicationReminderPageState extends State<MedicationReminderPage> {
  final TextEditingController _medicationNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  TimeOfDay? _time1;
  TimeOfDay? _time2;
  TimeOfDay? _time3;

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _medicationNameController.text = widget.medication!.name;
      _dosageController.text = widget.medication!.dosage;
      _daysController.text = widget.medication!.days.toString();
      if (widget.medication!.times.isNotEmpty) {
        final parts = widget.medication!.times[0].split(':');
        _time1 = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (widget.medication!.times.length > 1) {
        final parts = widget.medication!.times[1].split(':');
        _time2 = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (widget.medication!.times.length > 2) {
        final parts = widget.medication!.times[2].split(':');
        _time3 = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm();  // "6:00 AM" format
    return format.format(dt);
  }

  Future<void> _selectTime(int timeNumber) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        switch (timeNumber) {
          case 1:
            _time1 = picked;
            break;
          case 2:
            _time2 = picked;
            break;
          case 3:
            _time3 = picked;
            break;
        }
      });
    }
  }

  Future<void> _saveMedication() async {
    if (_medicationNameController.text.isEmpty ||
        _dosageController.text.isEmpty ||
        _daysController.text.isEmpty ||
        _time1 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Prepare times list and schedule notifications
      List<String> times = [];
      final days = int.parse(_daysController.text.trim());
      final medicationName = _medicationNameController.text.trim();
      
      // Schedule notifications for each time and each day
      for (int day = 0; day < days; day++) {
        if (_time1 != null) {
          final time1String = '${_time1!.hour.toString().padLeft(2, '0')}:${_time1!.minute.toString().padLeft(2, '0')}';
          times.add(time1String);
          
          final scheduledTime = DateTime.now().add(Duration(days: day));
          final notificationTime = DateTime(
            scheduledTime.year,
            scheduledTime.month,
            scheduledTime.day,
            _time1!.hour,
            _time1!.minute,
          );
          
          await NotificationService.scheduleNotification(
            id: day * 3,  // Unique ID for each notification
            title: 'Medication Reminder',
            body: 'Time to take $medicationName',
            scheduledTime: notificationTime,
          );
        }
        
        if (_time2 != null) {
          final time2String = '${_time2!.hour.toString().padLeft(2, '0')}:${_time2!.minute.toString().padLeft(2, '0')}';
          times.add(time2String);
          
          final scheduledTime = DateTime.now().add(Duration(days: day));
          final notificationTime = DateTime(
            scheduledTime.year,
            scheduledTime.month,
            scheduledTime.day,
            _time2!.hour,
            _time2!.minute,
          );
          
          await NotificationService.scheduleNotification(
            id: (day * 3) + 1,
            title: 'Medication Reminder',
            body: 'Time to take $medicationName',
            scheduledTime: notificationTime,
          );
        }
        
        if (_time3 != null) {
          final time3String = '${_time3!.hour.toString().padLeft(2, '0')}:${_time3!.minute.toString().padLeft(2, '0')}';
          times.add(time3String);
          
          final scheduledTime = DateTime.now().add(Duration(days: day));
          final notificationTime = DateTime(
            scheduledTime.year,
            scheduledTime.month,
            scheduledTime.day,
            _time3!.hour,
            _time3!.minute,
          );
          
          await NotificationService.scheduleNotification(
            id: (day * 3) + 2,
            title: 'Medication Reminder',
            body: 'Time to take $medicationName',
            scheduledTime: notificationTime,
          );
        }
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('medications').add({
        'userId': user.uid,
        'medicationName': medicationName,
        'dosage': _dosageController.text.trim(),
        'times': times,
        'days': days,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'isDone': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show test notification
      await NotificationService.showInstantNotification(
        'Medication Scheduled',
        'Reminder set for $medicationName',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, '/scheduling');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving medication: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Add Medication',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medication Info Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medication Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          controller: _medicationNameController,
                          label: 'Medication Name',
                          icon: Icons.medication,
                          iconColor: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _dosageController,
                          label: 'Dosage',
                          icon: Icons.medical_information,
                          iconColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Schedule Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Schedule',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeButton(
                                label: _time1 != null ? _formatTimeOfDay(_time1!) : 'Select Time 1',
                                onPressed: () => _selectTime(1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTimeButton(
                                label: _time2 != null ? _formatTimeOfDay(_time2!) : 'Select Time 2',
                                onPressed: () => _selectTime(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTimeButton(
                                label: _time3 != null ? _formatTimeOfDay(_time3!) : 'Select Time 3',
                                onPressed: () => _selectTime(3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          controller: _daysController,
                          label: 'Number of Days',
                          icon: Icons.calendar_today,
                          keyboardType: TextInputType.number,
                          iconColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveMedication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Medication',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Color iconColor = Colors.green,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: iconColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildTimeButton({required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(label),
    );
  }
}
