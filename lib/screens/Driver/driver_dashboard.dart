import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:queuetrack/QueueModel/queue_model.dart';
import '../dashboard_helper.dart';
import '../view_queue_status.dart';
import 'driver_profile_screen.dart';


class DriverDashboard extends StatelessWidget {
  
   DriverDashboard({super.key,});
final  QueueModel queueModel=QueueModel();
final FirebaseFirestore firestore=FirebaseFirestore.instance;
final TextEditingController vehicleNumberController=TextEditingController();


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

  Future _checkInUi(BuildContext context) {
    return showModalBottomSheet(
        context: context,
        builder: (context){
      return TextFormField(
        controller: vehicleNumberController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: 'Enter vehicle number',
          border: OutlineInputBorder(),
        ),
        validator: (value){
          if(value!.isEmpty){
            return 'Please enter a vehicle number';
          }
          return null;
        },
        onFieldSubmitted: (value){
          queueModel.requestCheckIn(vehicleNumber: value);
          Navigator.pop(context);

        }
      );
    });
  }
  @override
  Widget build(BuildContext context) => buildDashboard(
        'Driver Dashboard',
        [
          {
            'title': 'Check-in Stage',
            'icon': Icons.check_circle,
            'color': Colors.blue,
            'onTap': (ctx) => _checkInUi(context),
          },
          {
            'title': 'View Queue Status',
            'icon': Icons.queue,
            'color': Colors.green,
            'onTap': (ctx) {
              Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => ViewQueueStatus()),
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
