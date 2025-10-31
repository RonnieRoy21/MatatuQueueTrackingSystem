import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VehicleMasterList extends StatelessWidget {
  const VehicleMasterList({super.key});

  String formatDate(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return 'N/A';
    return DateFormat('d/M/yyyy  h:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Master List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Refreshing vehicle list...")),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No vehicles registered yet"));
          }

          final vehicles = snapshot.data!.docs;

          return ListView.builder(
            itemCount: vehicles.length,
            itemBuilder: (context, i) {
              final data = vehicles[i].data() as Map<String, dynamic>;
              final vehicleNumber = data['vehicleNumber'] ?? 'UNKNOWN';
              final driverName = data['driverName'] ?? 'N/A';
              final ownerName = data['ownerName'] ?? 'N/A';
              final status = data['status'] ?? 'inactive';
              final createdAt = data['createdAt'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: status == 'active'
                        ? Colors.green
                        : Colors.grey.shade400,
                    child: const Icon(Icons.directions_bus, color: Colors.white),
                  ),
                  title: Text(
                    vehicleNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Driver: $driverName\n"
                    "Owner: $ownerName\n"
                    "Registered: ${formatDate(createdAt)}",
                  ),
                  trailing: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: status == 'active'
                          ? Colors.green
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
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
