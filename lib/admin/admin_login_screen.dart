import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tali_khata/views/due_management_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // ফায়ারবেস অথেন্টিকেশন দিয়ে লগইন ফাংশন
  Future<void> _loginAdmin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // ফায়ারবেস সাইন-ইন লজিক
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          // সফলভাবে লগইন হলে মেইন বাকি খাতা স্ক্রিনে নিয়ে যাবে এবং লগইন স্ক্রিন ব্যাকস্ট্যাক থেকে মুছে দেবে
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DueManagementScreen(),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = "লগইন ব্যর্থ হয়েছে! আবার চেষ্টা করুন।";

        if (e.code == 'user-not-found') {
          errorMessage = "এই ইমেইল দিয়ে কোনো অ্যাডমিন অ্যাকাউন্ট পাওয়া যায়নি।";
        } else if (e.code == 'wrong-password') {
          errorMessage = "ভুল পাসওয়ার্ড দিয়েছেন! সঠিক পাসওয়ার্ড লিখুন।";
        } else if (e.code == 'invalid-email') {
          errorMessage = "ইমেইলের ফরম্যাটটি সঠিক নয়।";
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // অ্যাপের লোগো বা আইকন সেকশন
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.teal[800],
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'অ্যাডমিন লগইন',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'বাকি খাতা অ্যাক্সেস করতে আপনার তথ্য দিন',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // লগইন ফর্ম কার্ড
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // ইমেইল ইনপুট ফিল্ড
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'অ্যাডমিন ইমেইল',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.teal,
                              ),
                              border: OutlineInputBorder(),
                              floatingLabelStyle: TextStyle(color: Colors.teal),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.teal,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'অনুগ্রহ করে ইমেইল লিখুন';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value.trim())) {
                                return 'সঠিক ইমেইল ফরম্যাট ব্যবহার করুন';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // পাসওয়ার্ড ইনপুট ফিল্ড
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'সিক্রেট পাসওয়ার্ড',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Colors.teal,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: const OutlineInputBorder(),
                              floatingLabelStyle: const TextStyle(
                                color: Colors.teal,
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.teal,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'অনুগ্রহ করে পাসওয়ার্ড লিখুন';
                              }
                              if (value.length < 6) {
                                return 'পাসওয়ার্ড সর্বনিম্ন ৬ অক্ষরের হতে হবে';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // লগইন বাটন
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _loginAdmin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'লগইন করুন',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
