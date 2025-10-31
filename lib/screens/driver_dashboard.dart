import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_helper.dart';
import 'view_queue_status.dart';
import 'driver_profile_screen.dart';


class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  final String stageId = 'main_stage'; // same as Sacco dashboard

  // ✅ Driver check-in flow
Future<void> _checkIn(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final firestore = FirebaseFirestore.instance;
  final stageId = 'main_stage';

  // Step 1: Get driver info
  final driverDoc = await firestore.collection('users').doc(user.uid).get();
  final driverName = driverDoc.data()?['fullName'] ?? 'Driver';

  // Step 2: Find assigned vehicle
  final vehicleSnap = await firestore
      .collection('vehicles')
      .where('driverId', isEqualTo: user.uid)
      .limit(1)
      .get();

  String vehicleNumber = 'UNKNOWN';
  String ownerId = 'UNKNOWN_OWNER';

  if (vehicleSnap.docs.isNotEmpty) {
    final vData = vehicleSnap.docs.first.data();
    vehicleNumber = vData['vehicleNumber'] ?? 'UNKNOWN';
    ownerId = vData['ownerId'] ?? 'UNKNOWN_OWNER';
  }

  // Step 3: Get queue size safely
  final queueRef = firestore.collection('queues').doc(stageId).collection('vehicles');
  final queueSnapshot = await queueRef.get();
  final newPos = queueSnapshot.docs.length + 1;

  // Step 4: Save check-in
  await queueRef.add({
    'driverId': user.uid,
    'driverName': driverName,
    'checkedInAt': FieldValue.serverTimestamp(),
    'status': 'waiting',
    'position': newPos,
    'vehicleNumber': vehicleNumber,
    'ownerId': ownerId,
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("✅ $driverName checked in successfully!")),
  );
}


  // ✅ View trip history
  void _viewMyHistory(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("My Trip History")),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('queues')
                .doc('main_stage')
                .collection('vehicles')
                .where('driverId', isEqualTo: user.uid)
                .orderBy('checkedInAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No trip history found."));
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final vehicle = data['vehicleNumber'] ?? 'N/A';
                  final status = data['status'] ?? '-';
                  final checkedInAt = data['checkedInAt'];
                  final departedAt = data['departedAt'];

                  String formatTime(dynamic t) {
                    if (t == null || t is! Timestamp) return 'N/A';
                    final date = t.toDate();
                    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
                  }

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.blueGrey.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.directions_bus,
                          color: Colors.teal),
                      title: Text("Vehicle: $vehicle"),
                      subtitle: Text(
                        "Checked In: ${formatTime(checkedInAt)}\n"
                        "Departed: ${formatTime(departedAt)}\n"
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

  @override
  Widget build(BuildContext context) => buildDashboard(
        'Driver Dashboard',
        [
          {
            'title': 'Check-in Stage',
            'icon': Icons.check_circle,
            'color': Colors.blue,
            'onTap': (ctx) => _checkIn(ctx),
          },
          {
            'title': 'View Queue Status',
            'icon': Icons.queue,
            'color': Colors.green,
            'onTap': (ctx) {
              Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => const ViewQueueStatus()),
              );
            },
          },
          {
            'title': 'My Trip History',
            'icon': Icons.history,
            'color': Colors.orange,
            'onTap': (ctx) => _viewMyHistory(ctx),
          },
          {
            'title': 'Profile',
            'icon': Icons.person,
            'color': Colors.purple,
            'onTap': (ctx) {
              Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
              );
            },
          },

        ],
        context,
      );
}
