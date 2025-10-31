import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssignVehicleScreen extends StatefulWidget {
  const AssignVehicleScreen({super.key});

  @override
  State<AssignVehicleScreen> createState() => _AssignVehicleScreenState();
}

class _AssignVehicleScreenState extends State<AssignVehicleScreen> {
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController driverIdController = TextEditingController();
  bool isLoading = false;

  Future<void> _registerVehicle() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ You must be logged in.")),
      );
      return;
    }

    final vehicleNumber = vehicleNumberController.text.trim().toUpperCase();
    final driverId = driverIdController.text.trim();

    if (vehicleNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a vehicle number.")),
      );
      return;
    }

    setState(() => isLoading = true);

    final firestore = FirebaseFirestore.instance;

    try {
      // ✅ Check if vehicle already exists
      final existing = await firestore
          .collection('vehicles')
          .where('vehicleNumber', isEqualTo: vehicleNumber)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Vehicle already registered.")),
        );
        setState(() => isLoading = false);
        return;
      }

      // ✅ Add new vehicle linked to owner
      await firestore.collection('vehicles').add({
        'vehicleNumber': vehicleNumber,
        'ownerId': currentUser.uid,
        'driverId': driverId.isEmpty ? null : driverId,
        'status': 'inactive', // default until first check-in
        'registeredAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Vehicle registered successfully!")),
      );

      vehicleNumberController.clear();
      driverIdController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    vehicleNumberController.dispose();
    driverIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register / Assign Vehicle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: vehicleNumberController,
              decoration: const InputDecoration(
                labelText: "Vehicle Number",
                prefixIcon: Icon(Icons.directions_bus),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: driverIdController,
              decoration: const InputDecoration(
                labelText: "Driver ID (optional)",
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Register Vehicle"),
                    onPressed: _registerVehicle,
                  ),
          ],
        ),
      ),
    );
  }
}
