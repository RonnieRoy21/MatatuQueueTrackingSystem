import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_screen.dart';
import 'all_dashboards.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  /// ✅ Role mapping so Firestore values match your dashboards
  String normalizeRole(String role) {
    switch (role.trim()) {
      case 'driver':
        return 'driver';
      case 'conductor':
        return 'conductor';
      case 'stageMarshal':
        return 'stageMarshal';
      case 'saccoOfficial':
        return 'saccoOfficial';
      case 'matatuOwner':
        return 'matatuOwner';
      default:
        return '';
    }
  }


Future<void> _login() async {
  setState(() => isLoading = true);

  try {
    final cred = await _auth.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    final user = cred.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed: no user returned')),
      );
      return;
    }

    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    final rawRole = (doc.exists && doc.data()!.containsKey('role')) ? (doc['role'] ?? '') as String : '';

    debugPrint('Login: user=${user.email}, rawRole="$rawRole"');

    // canonicalize whatever is in Firestore into the exact keys your dashboards expect
    String canonicalRole(String role) {
      final r = role.trim();
      if (r.isEmpty) return '';

      final lower = r.toLowerCase();
      final compact = lower.replaceAll(RegExp(r'[\s_\-]'), ''); // remove spaces/underscores/hyphens

      if (lower == 'driver' || compact == 'driver') return 'driver';
      if (lower == 'conductor' || compact == 'conductor') return 'conductor';

      // stage marshal variants
      if (compact == 'stagemarshal' || lower == 'stagemarshal' || r == 'stageMarshal') return 'stageMarshal';

      // sacco official variants
      if (compact == 'saccoofficial' || lower == 'saccoofficial' || r == 'saccoOfficial') return 'saccoOfficial';

      // matatu owner variants
      if (compact == 'matatuowner' || lower == 'matatuowner' || r == 'matatuOwner') return 'matatuOwner';

      return ''; // unknown
    }

    final canon = canonicalRole(rawRole);

    debugPrint('Canonical role resolved: "$canon" from rawRole="$rawRole"');

    if (canon.isEmpty) {
      // Quick fallback: if the DB had "Driver" etc. but we couldn't map, try mapping common labels
      final fallback = (rawRole.trim().toLowerCase());
      debugPrint('Fallback raw lower: "$fallback"');
      // give a helpful message and do not navigate
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unrecognized role "$rawRole". Please contact admin.')),
      );
      setState(() => isLoading = false);
      return;
    }

    // If Firestore has a non-canonical value, update it so next time this user is canonicalized automatically
    if (rawRole != canon) {
      try {
        await docRef.update({'role': canon});
        debugPrint('Updated Firestore role for ${user.uid} -> "$canon"');
      } catch (e) {
        debugPrint('Failed to update Firestore role: $e');
      }
    }

    final next = getDashboard(canon);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => next),
    );
  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message ?? 'Login failed')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unexpected error: $e')),
    );
  } finally {
    setState(() => isLoading = false);
  }
}


  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0EA5A4), Color(0xFF60A5FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: width > 600 ? 520 : double.infinity,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'QueueTrack',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Colors.teal.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sign in to manage your matatu stage',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email),
                          labelText: 'Email',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock),
                          labelText: 'Password',
                        ),
                      ),
                      const SizedBox(height: 18),
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _login,
                              child: const Text('Login'),
                            ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup'); // ✅ fixed
                        },
                        child: const Text("Don't have an account? Sign up"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
