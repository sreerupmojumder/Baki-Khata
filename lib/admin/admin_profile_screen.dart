import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  // বর্তমান অ্যাডমিনের ডাটা লোড করা
  void _loadAdminData() {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _nameController.text = _currentUser!.displayName ?? "অ্যাডমিন";
      _emailController.text = _currentUser!.email ?? "";
    }
  }

  // ১. প্রোফাইল আপডেট (নাম ও ইমেইল) করার ফাংশন
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      try {
        // নাম আপডেট
        await _currentUser!.updateDisplayName(_nameController.text.trim());
        
        // ইমেইল আপডেট (ইমেইল পরিবর্তন করলে ফায়ারবেস একটি ভেরিফিকেশন মেইল পাঠাতে পারে)
        if (_emailController.text.trim() != _currentUser!.email) {
          await _currentUser!.verifyBeforeUpdateEmail(_emailController.text.trim());
          _showSnackBar("আপনার ইমেইল পরিবর্তনের অনুরোধ গ্রহণ করা হয়েছে। নতুন ইমেইলে ভেরিফিকেশন লিংক পাঠানো হয়েছে।", Colors.orange);
        } else {
          _showSnackBar("প্রোফাইল সফলভাবে আপডেট হয়েছে!", Colors.green);
        }
        
        await _currentUser!.reload();
        _loadAdminData();
      } on FirebaseAuthException catch (e) {
        _showSnackBar(e.message ?? "আপডেট ব্যর্থ হয়েছে!", Colors.red);
      } finally {
        setState(() { _isLoading = false; });
      }
    }
  }

  // ২. পাসওয়ার্ড পরিবর্তন করার ফাংশন
  Future<void> _changePassword() async {
    if (_passwordController.text.trim().isEmpty) {
      _showSnackBar("অনুগ্রহ করে নতুন পাসওয়ার্ডটি লিখুন", Colors.red);
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      _showSnackBar("পাসওয়ার্ড সর্বনিম্ন ৬ অক্ষরের হতে হবে", Colors.red);
      return;
    }

    setState(() { _isLoading = true; });
    try {
      await _currentUser!.updatePassword(_passwordController.text.trim());
      _passwordController.clear();
      _showSnackBar("পাসওয়ার্ড সফলভাবে পরিবর্তন হয়েছে!", Colors.green);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showSnackBar("নিরাপত্তার স্বার্থে এইমাত্র লগইন করে এসে পাসওয়ার্ড পরিবর্তন করুন।", Colors.red);
      } else {
        _showSnackBar(e.message ?? "পাসওয়ার্ড পরিবর্তন করা যায়নি!", Colors.red);
      }
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // ৩. লগআউট (Logout) ফাংশন
  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      // লগআউট করে একদম শুরুর লগইন স্ক্রিনে ব্যাক করবে এবং আগের সব স্ক্রিন মেমোরি থেকে মুছে দেবে
      Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('অ্যাডমিন প্রোফাইল', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'লগআউট',
            onPressed: _logout,
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // প্রোফাইল অবতার
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal.shade50,
                      child: Icon(Icons.account_circle, size: 90, color: Colors.teal[800]),
                    ),
                    const SizedBox(height: 24),

                    // সেকশন ১: তথ্য আপডেট কার্ড
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ব্যক্তিগত তথ্য', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal[800])),
                            const Divider(),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'অ্যাডমিনের নাম', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                              validator: (v) => v!.isEmpty ? 'নাম খালি রাখা যাবে না' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'ইমেইল অ্যাড্রেস', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                              validator: (v) => v!.isEmpty ? 'ইমেইল খালি রাখা যাবে না' : null,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton(
                                onPressed: _updateProfile,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800]),
                                child: const Text('প্রোফাইল আপডেট করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // সেকশন ২: পাসওয়ার্ড পরিবর্তন কার্ড
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('সিকিউরিটি ও পাসওয়ার্ড', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                            const Divider(),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'নতুন পাসওয়ার্ড দিন',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () { setState(() { _obscurePassword = !_obscurePassword; }); },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton(
                                onPressed: _changePassword,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                                child: const Text('পাসওয়ার্ড পরিবর্তন করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}