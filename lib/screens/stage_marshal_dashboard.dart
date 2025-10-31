import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dashboard_helper.dart';

// ✅ Helper for relative time
String timeAgo(dynamic timestamp) {
  if (timestamp is! Timestamp) return '';
  final now = DateTime.now();
  final diff = now.difference(timestamp.toDate());
  if (diff.inMinutes < 1) return "just now";
  if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
  if (diff.inHours < 24) return "${diff.inHours} hr ago";
  return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago";
}

class StageMarshalDashboard extends StatelessWidget {
  const StageMarshalDashboard({super.key});

  final String stageId = 'main_stage';

  // -------------------- VIEW QUEUE LIST --------------------
  void _viewQueueList(BuildContext context) {
    final formatter = DateFormat('d/M/yyyy  h:mm a');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Manage Queue List')),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('queues')
                .doc(stageId)
                .collection('vehicles')
                .where('status', isEqualTo: 'waiting')
                .orderBy('position')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No vehicles in queue"));
              }

              final vehicles = snapshot.data!.docs;
              return ListView.builder(
                itemCount: vehicles.length,
                itemBuilder: (context, i) {
                  final data = vehicles[i].data() as Map<String, dynamic>;
                  final name = data['driverName'] ?? 'Unknown';
                  final pos = data['position'] ?? i + 1;
                  final status = data['status'] ?? 'waiting';
                  final docId = vehicles[i].id;
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
                        "Status: $status\n"
                        "Checked in: ${checkedInAt != null
                            ? "${formatter.format((checkedInAt as Timestamp).toDate())} (${timeAgo(checkedInAt)})"
                            : 'N/A'}\n"

                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Move Up
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, color: Colors.blue),
                            onPressed: i == 0
                                ? null
                                : () => _confirmMove(
                                      context,
                                      vehicles[i - 1].id,
                                      vehicles[i].id,
                                      (vehicles[i - 1].data() as Map)['position'],
                                      pos,
                                      up: true,
                                    ),
                          ),
                          // Move Down
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, color: Colors.blue),
                            onPressed: i == vehicles.length - 1
                                ? null
                                : () => _confirmMove(
                                      context,
                                      vehicles[i].id,
                                      vehicles[i + 1].id,
                                      pos,
                                      (vehicles[i + 1].data() as Map)['position'],
                                      up: false,
                                    ),
                          ),
                          // Depart Button
                          if (status == 'waiting')
                            ElevatedButton(
                              onPressed: () => _confirmDeparture(context, docId),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Depart'),
                            )
                          else
                            const Icon(Icons.check, color: Colors.green),
                        ],
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

  // -------------------- MOVE / DEPART CONFIRMATIONS --------------------
  void _confirmMove(BuildContext context, String id1, String id2, int pos1, int pos2, {required bool up}) {
    final direction = up ? 'up' : 'down';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Move $direction?'),
        content: Text('Are you sure you want to move this driver $direction in the queue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _swapPositions(id1, id2, pos1, pos2);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Driver moved $direction.')));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _confirmDeparture(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Departure'),
        content: const Text('Mark this vehicle as departed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _markDeparted(context, docId);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // -------------------- FIRESTORE ACTIONS --------------------
  Future<void> _swapPositions(String id1, String id2, int pos1, int pos2) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final doc1 = firestore.collection('queues').doc(stageId).collection('vehicles').doc(id1);
    final doc2 = firestore.collection('queues').doc(stageId).collection('vehicles').doc(id2);

    batch.update(doc1, {'position': pos2});
    batch.update(doc2, {'position': pos1});

    await batch.commit();
  }

  Future<void> _markDeparted(BuildContext context, String docId) async {
    final firestore = FirebaseFirestore.instance;
    final vehiclesCol = firestore.collection('queues').doc(stageId).collection('vehicles');
    final metaDoc = firestore.collection('queues').doc(stageId).collection('meta').doc('info');

    try {
      await vehiclesCol.doc(docId).update({
        'status': 'departed',
        'departedAt': FieldValue.serverTimestamp(),
      });

      final remaining = await vehiclesCol.where('status', isEqualTo: 'waiting').get();
      if (remaining.docs.isEmpty) {
        await metaDoc.update({'lastPosition': 0});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Queue reset — all vehicles departed.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle marked as departed.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  // -------------------- DASHBOARD --------------------
  @override
  Widget build(BuildContext context) => buildDashboard(
        'Stage Marshal Dashboard',
        [
          {
            'title': 'Manage Queue List',
            'icon': Icons.list,
            'color': Colors.purple,
            'onTap': (ctx) => _viewQueueList(ctx),
          },
        ],
        context,
      );
}
