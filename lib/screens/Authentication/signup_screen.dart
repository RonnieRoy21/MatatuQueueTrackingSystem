import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignUpScreen extends StatefulWidget {
  final String selectedRole;
  const SignUpScreen({super.key,required this.selectedRole});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final idNumberController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _fs = FirebaseFirestore.instance;

  bool isLoading = false;
  String? selectedRole;

  /// Dropdown labels (user friendly)
  final roles = [
    'Sacco_Official',
    'Matatu_Owner',
  ];

  Future<void> _signUp({required String category}) async {

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

      if(selectedRole!.toLowerCase()=='matatu_owner'){
        //create matatu owner user
        await _fs.collection(category).doc(userId).set({
                'ownerName': nameController.text.trim(),
                'ownerEmail': emailController.text.trim(),
                'ownerId': idNumberController.text.trim(),
              });
        Fluttertoast.showToast(msg: 'Account created');
      }else{
        //create sacco official owner user
        await _fs.collection(category.toLowerCase()).doc(userId).set({
          'saccoOfficialName':nameController.text.trim(),
          'saccoOfficialEmail':emailController.text.trim(),
          'saccoOfficialId':idNumberController.text.trim(),
        });
        Fluttertoast.showToast(msg: 'Account created');
      }
      // if (!mounted) Navigator.pop(context);
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
    idNumberController.dispose();
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
                    controller: idNumberController,
                    decoration:
                        const InputDecoration(labelText: 'Your Id Number')),
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
                  initialValue: selectedRole,
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
                        onPressed: ()async {
                          await _signUp(category: widget.selectedRole);
                        },child: const Text('Create account'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
