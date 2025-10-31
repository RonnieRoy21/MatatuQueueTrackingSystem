import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _fs = FirebaseFirestore.instance;

  bool isLoading = false;
  String? selectedRole;

  /// Dropdown labels (user friendly)
  final roles = [
    'Driver',
    'Conductor',
    'Stage Marshal',
    'Sacco Official',
    'Matatu Owner',
  ];

  /// ✅ Map labels → canonical role keys
  String roleKey(String label) {
    switch (label) {
      case 'Driver':
        return 'driver';
      case 'Conductor':
        return 'conductor';
      case 'Stage Marshal':
        return 'stageMarshal';
      case 'Sacco Official':
        return 'saccoOfficial';
      case 'Matatu Owner':
        return 'matatuOwner';
      default:
        return '';
    }
  }

  Future<void> _signUp() async {
    if (selectedRole == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please choose a role')));
      return;
    }
    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => isLoading = true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userId = cred.user!.uid;

      /// ✅ Save role in canonical form
      await _fs.collection('users').doc(userId).set({
        'fullName': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'role': roleKey(selectedRole!), // save correct role
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully')));

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Sign up failed')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Full name')),
                const SizedBox(height: 12),
                TextField(
                    controller: phoneController,
                    decoration:
                        const InputDecoration(labelText: 'Phone number')),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 12),
                TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Confirm Password')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedRole = v),
                  decoration:
                      const InputDecoration(labelText: 'Select Role'),
                ),
                const SizedBox(height: 18),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signUp,
                        child: const Text('Create account'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
