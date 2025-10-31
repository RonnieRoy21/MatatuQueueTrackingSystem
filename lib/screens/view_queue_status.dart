import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ✅ Helper: format relative time like "5 min ago"
String timeAgo(dynamic timestamp) {
  if (timestamp is! Timestamp) return '';
  final now = DateTime.now();
  final diff = now.difference(timestamp.toDate());
  if (diff.inMinutes < 1) return "just now";
  if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
  if (diff.inHours < 24) return "${diff.inHours} hr ago";
  return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago";
}

class ViewQueueStatus extends StatelessWidget {
  const ViewQueueStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('d/M/yyyy  h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text("Queue Status")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('queues')
            .doc('main_stage')
            .collection('vehicles')
            .where('status', isEqualTo: 'waiting') // only active vehicles
            .orderBy('position')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("🚐 No drivers in the queue yet"));
          }

          final drivers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final data = drivers[index].data() as Map<String, dynamic>;
              final name = data['driverName'] ?? 'Unknown';
              final pos = data['position'] ?? index + 1;
              final checkedInAt = data['checkedInAt'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Text('$pos', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    checkedInAt != null
                        ? "Checked in: ${formatter.format((checkedInAt as Timestamp).toDate())} (${timeAgo(checkedInAt)})"
                        : "Checked in: N/A",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
