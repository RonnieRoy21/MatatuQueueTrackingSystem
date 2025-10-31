import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyVehicleLogsScreen extends StatelessWidget {
  const MyVehicleLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final logsStream = FirebaseFirestore.instance
        .collection('queues')
        .doc('main_stage')
        .collection('vehicles')
        .where('ownerId', isEqualTo: user.uid)
        .orderBy('checkedInAt', descending: true)
        .snapshots();

    final formatter = DateFormat('d MMM, h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicle Logs'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: logsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No logs found.'));
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final data = logs[index].data() as Map<String, dynamic>;
              final vehicle = data['vehicleNumber'] ?? 'Unknown';
              final driver = data['driverName'] ?? 'Unknown';
              final status = data['status'] ?? '-';
              final checkIn = data['checkedInAt'] != null
                  ? formatter.format(data['checkedInAt'].toDate())
                  : 'N/A';
              final departed = data['departedAt'] != null
                  ? formatter.format(data['departedAt'].toDate())
                  : '—';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.directions_bus, color: Colors.indigo),
                  title: Text('$vehicle — $driver'),
                  subtitle: Text('Checked In: $checkIn\nDeparted: $departed'),
                  trailing: Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
