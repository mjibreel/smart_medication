import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeStatsCard extends StatelessWidget {
  const HomeStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medications')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Calculate statistics
        final stats = _calculateStats(snapshot.data!.docs);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStatItem(
                icon: Icons.warning,
                color: Colors.red,
                title: 'Missed Medications',
                value: '${stats.missedCount}',
                subtitle: 'Today',
              ),
              const Divider(height: 20),
              _buildStatItem(
                icon: Icons.check_circle,
                color: Colors.green,
                title: 'Weekly Adherence',
                value: '${stats.adherenceRate.toStringAsFixed(1)}%',
                subtitle: 'Last 7 days',
              ),
              const Divider(height: 20),
              _buildStatItem(
                icon: Icons.calendar_today,
                color: Colors.blue,
                title: 'Upcoming Appointments',
                value: '${stats.upcomingAppointments}',
                subtitle: 'Next 7 days',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  _Stats _calculateStats(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    // Count missed medications for today
    int missedCount = 0;
    // Count total and taken medications for the week
    int weeklyTotal = 0;
    int weeklyTaken = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = DateTime.parse(data['date'] as String);
      final isDone = data['isDone'] as bool;
      final times = List<String>.from(data['times'] ?? []);

      // Check for today's missed medications
      if (date.isAtSameMomentAs(today)) {
        for (var time in times) {
          final parts = time.split(':');
          final medicationTime = DateTime(
            today.year,
            today.month,
            today.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
          if (medicationTime.isBefore(now) && !isDone) {
            missedCount++;
          }
        }
      }

      // Calculate weekly statistics
      if (date.isAfter(weekAgo) || date.isAtSameMomentAs(weekAgo)) {
        weeklyTotal += times.length;
        if (isDone) weeklyTaken += times.length;
      }
    }

    // Calculate adherence rate
    final adherenceRate = weeklyTotal > 0 
        ? (weeklyTaken / weeklyTotal) * 100 
        : 100.0;

    // Get upcoming appointments
    int upcomingAppointments = 0;
    // This would need to be implemented with your appointments collection
    // For now, returning a placeholder value
    upcomingAppointments = 2;

    return _Stats(
      missedCount: missedCount,
      adherenceRate: adherenceRate,
      upcomingAppointments: upcomingAppointments,
    );
  }
}

class _Stats {
  final int missedCount;
  final double adherenceRate;
  final int upcomingAppointments;

  _Stats({
    required this.missedCount,
    required this.adherenceRate,
    required this.upcomingAppointments,
  });
} 