import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  Future<Map<String, dynamic>> _getDriverInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    // Get driver info from users collection
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    // Find assigned vehicle (if any)
    final vehicleSnap = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('driverId', isEqualTo: user.uid)
        .limit(1)
        .get();

    String vehicleNumber =
        vehicleSnap.docs.isNotEmpty ? vehicleSnap.docs.first['vehicleNumber'] : 'Not Assigned';

    return {
      'name': userData['name'] ?? 'Unknown Driver',
      'email': user.email ?? 'No email',
      'vehicleNumber': vehicleNumber,
    };
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Profile')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getDriverInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No driver information found."));
          }

          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(Icons.account_circle, size: 100, color: Colors.teal),
                ),
                const SizedBox(height: 20),
                Text("Name: ${data['name']}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text("Email: ${data['email']}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text("Vehicle Number: ${data['vehicleNumber']}",
                    style: const TextStyle(fontSize: 16)),
                const Spacer(),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
