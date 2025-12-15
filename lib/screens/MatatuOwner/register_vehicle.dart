import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterVehicle extends StatefulWidget {
  const RegisterVehicle({super.key});

  @override
  State<RegisterVehicle> createState() => _RegisterVehicleState();
}

class _RegisterVehicleState extends State<RegisterVehicle> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  bool _loading = false;

  Future<void> _registerVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in')),
      );
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      await firestore.collection('vehicles').add({
        'vehicleNumber': _vehicleNumberController.text.trim().toUpperCase(),
        'ownerId': user.uid,
        'registeredAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Vehicle registered successfully!')),
      );

      _vehicleNumberController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Vehicle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(
                  labelText: "Vehicle Number (e.g. KCC 123A)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter a valid vehicle number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loading ? null : _registerVehicle,
                icon: const Icon(Icons.save),
                label: Text(_loading ? "Registering..." : "Register Vehicle"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
