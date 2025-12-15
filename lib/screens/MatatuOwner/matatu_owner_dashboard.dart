import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../dashboard_helper.dart';
import 'assign_vehicle_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatatuOwnerDashboard extends StatelessWidget {
  const MatatuOwnerDashboard({super.key});

  final String stageId = 'main_stage'; // same as Sacco dashboard

  // 🕒 Format timestamps nicely
  String formatDate(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return 'N/A';
    return DateFormat('d/M/yyyy  h:mm a').format(timestamp.toDate());
  }

  // 🧭 View Logs — only show logs for vehicles owned by this owner
  void _viewLogs(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not logged in")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("My Vehicle Logs")),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('queues')
                .doc(stageId)
                .collection('vehicles')
                .where('ownerId', isEqualTo: currentUser.uid) // ✅ Filter by owner
                .orderBy('checkedInAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No logs for your vehicles yet."));
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final vehicle = data['vehicleNumber'] ?? 'Unknown Vehicle';
                  final driver = data['driverName'] ?? 'Unknown Driver';
                  final status = data['status'] ?? '-';
                  final checkIn = data['checkedInAt'];
                  final departed = data['departedAt'];

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.blueGrey.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.directions_bus,
                          color: Colors.deepPurple),
                      title: Text(vehicle,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        "Driver: $driver\n"
                        "Checked In: ${formatDate(checkIn)}\n"
                        "Departed: ${formatDate(departed)}\n"
                        "Status: $status",
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // 📊 Track Trip Frequency — only for this owner's vehicles
  Future<void> _trackTripFrequency(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not logged in")),
      );
      return;
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final trips = await firestore
        .collection('queues')
        .doc(stageId)
        .collection('vehicles')
        .where('ownerId', isEqualTo: currentUser.uid) // ✅ Only their cars
        .where('departedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('departedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    final tripCount = trips.size;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Today's Trip Frequency"),
        content: Text("🚐 Your vehicles completed $tripCount trips today."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => buildDashboard(
        'Matatu Owner Dashboard',
        [
          {
            'title': 'View Logs',
            'icon': Icons.history,
            'color': Colors.orange,
            'onTap': (ctx) => _viewLogs(ctx),
          },
          {
            'title': 'Track Trip Frequency',
            'icon': Icons.track_changes,
            'color': Colors.red,
            'onTap': (ctx) => _trackTripFrequency(ctx),
          },
          {
            'title': 'Register / Assign Vehicle',
            'icon': Icons.directions_bus,
            'color': Colors.teal,
            'onTap': (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const AssignVehicleScreen()),
            ),
          },
        ],
        context,
      );
}
