import 'package:flutter/material.dart';
import 'package:smart_medication/pages/medication_reminders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_medication/pages/checkup_page.dart';
import 'package:smart_medication/widgets/user_header.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class MedicationTrackerPage extends StatefulWidget {
  const MedicationTrackerPage({super.key});

  @override
  State<MedicationTrackerPage> createState() => _MedicationTrackerPageState();
}

class _MedicationTrackerPageState extends State<MedicationTrackerPage> {
  DateTime _selectedDate = DateTime.now();
  List<Medication> medications = [];

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  String _formatTimeWithPeriod(String time) {
    final hour = int.parse(time.split(':')[0]);
    final minute = time.split(':')[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '$displayHour:$minute $period';
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadMedications();
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final selectedDateStr = _selectedDate.toIso8601String().split('T')[0];
      
      final snapshot = await FirebaseFirestore.instance
          .collection('medications')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: selectedDateStr)
          .get();

      setState(() {
        medications = snapshot.docs.map((doc) {
          final data = doc.data();
          return Medication(
            id: doc.id,
            name: data['medicationName'] ?? '',
            dosage: data['dosage'] ?? '',
            times: List<String>.from(data['times'] ?? []),
            days: data['days'] ?? 0,
            isDone: data['isDone'] ?? false,
          );
        }).toList();
      });
    } catch (e) {
      print('Error loading medications: $e');
    }
  }

  Future<void> _toggleMedicationStatus(String id, bool isDone) async {
    try {
      await FirebaseFirestore.instance
          .collection('medications')
          .doc(id)
          .update({'isDone': isDone});
          
      if (isDone) {
        await NotificationService.showInstantNotification(
          'Medication Taken',
          'Great job taking your medication on time!',
        );
      }
      
      await _loadMedications();
    } catch (e) {
      print('Error updating medication status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> dailyTasks = [
      {
        'title': 'Morning Walk',
        'description': '15 minutes',
        'icon': Icons.directions_walk,
        'time': '07:00 AM',
        'isDone': false,
      },
      {
        'title': 'Drink Water',
        'description': '8 glasses',
        'icon': Icons.water_drop,
        'time': 'All day',
        'isDone': false,
      },
      {
        'title': 'Doctor Checkups',
        'description': 'View your appointments',
        'icon': Icons.medical_services,
        'time': 'View all',
        'isDone': false,
        'isCheckup': true,
      },
    ];

    List<Map<String, dynamic>> weeklyTasks = [
      {
        'title': 'Blood Pressure',
        'description': 'Check and record',
        'icon': Icons.favorite,
        'day': 'Monday',
        'isDone': false,
      },
      {
        'title': 'Blood Sugar',
        'description': 'Fasting test',
        'icon': Icons.bloodtype,
        'day': 'Wednesday',
        'isDone': false,
      },
      {
        'title': 'Heart Rate',
        'description': 'Morning reading',
        'icon': Icons.monitor_heart,
        'day': 'Friday',
        'isDone': false,
      },
    ];

    List<DateTime> getWeekDays() {
      return List.generate(
        5,
        (index) => _selectedDate.add(Duration(days: index - 2)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: const UserHeader(),
        ),
        Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousDay,
              ),
              ...List.generate(5, (index) {
                final weekDays = getWeekDays();
                final day = weekDays[index];
                final isSelected = day.day == _selectedDate.day &&
                    day.month == _selectedDate.month &&
                    day.year == _selectedDate.year;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = day;
                      });
                      _loadMedications();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('EEE').format(day),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day.day.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextDay,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Medications Section
              const Text(
                'Medications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              ...medications.map((medication) => _buildMedicationCard(medication)).toList(),
              
              const SizedBox(height: 24),
              
              // Daily Tasks Section
              const Text(
                'Daily Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              ...dailyTasks.map((task) => _buildDailyTaskCard(task)).toList(),
              
              const SizedBox(height: 24),
              
              // Weekly Tasks Section
              const Text(
                'Weekly Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 12),
              ...weeklyTasks.map((task) => _buildWeeklyTaskCard(task)).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    final now = DateTime.now();
    final medicationTime = TimeOfDay(
      hour: int.parse(medication.times[0].split(':')[0]),
      minute: int.parse(medication.times[0].split(':')[1]),
    );
    
    final medicationDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      medicationTime.hour,
      medicationTime.minute,
    );

    String status = 'Not yet';
    Color statusColor = Colors.grey;
    
    if (medication.isDone) {
      status = 'Done';
      statusColor = Colors.green;
    } else if (medicationDateTime.isBefore(now)) {
      status = 'Missed';
      statusColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.medication,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        medication.dosage,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTimeWithPeriod(medication.times[0]),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!medication.isDone)
            InkWell(
              onTap: () => _toggleMedicationStatus(medication.id, true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Take Medication',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyTaskCard(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        leading: Icon(
          task['icon'] as IconData,
          color: task['isCheckup'] == true ? Colors.red : Colors.blue,
        ),
        title: Text(task['title']),
        subtitle: Text(task['description']),
        trailing: Text(task['time']),
        onTap: () {
          if (task['isCheckup'] == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CheckupPage(),
              ),
            );
          } else {
            // Toggle task completion for non-checkup tasks
            // setState(() {
            //   task['isDone'] = !task['isDone'];
            // });
          }
        },
      ),
    );
  }

  Widget _buildWeeklyTaskCard(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        leading: Icon(task['icon'] as IconData, color: Colors.purple),
        title: Text(task['title']),
        subtitle: Text(task['description']),
        trailing: Text(task['day']),
        onTap: () {
          // Toggle task completion
          // setState(() {
          //   task['isDone'] = !task['isDone'];
          // });
        },
      ),
    );
  }
}
