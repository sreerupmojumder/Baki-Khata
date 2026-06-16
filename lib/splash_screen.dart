import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tali_khata/admin/admin_login_screen.dart';
import 'package:tali_khata/views/due_management_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  // ৩ সেকেন্ড অপেক্ষা করে লগইন স্টেট চেক করবে এবং সঠিক স্ক্রিনে নিয়ে যাবে
  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // ফায়ারবেসের কারেন্ট ইউজার সেশন চেক করা (এটি অফলাইনেও কাজ করে)
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // যদি আগে থেকে লগইন করা থাকে, সরাসরি ড্যাশবোর্ডে যাবে
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DueManagementScreen()),
      );
    } else {
      // লগইন করা না থাকলে লগইন স্ক্রিনে যাবে
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ব্যাকগ্রাউন্ডে আপনার অ্যাপের থিম কালার (Teal) ব্যবহার করা হয়েছে
      backgroundColor: Colors.teal[800],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // অ্যাপের চমৎকার একটি আইকন অ্যানিমেশন বা ডিজাইন
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Icon(
                Icons.menu_book_rounded, // খাতার আইকন
                size: 70,
                color: Colors.teal[850],
              ),
            ),
            const SizedBox(height: 24),
            
            // অ্যাপের নাম
            const Text(
              'বাকি খাতা',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            
            // একটি ক্যাচলাইন বা সাবটাইটেল
            Text(
              'সহজ ও নিরাপদ হিসাব ট্র্যাকিং',
              style: TextStyle(
                fontSize: 14,
                color: Colors.teal.shade100,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 48),
            
            // নিচে একটি মিনিমাল লাইট লোডিং ইন্ডিকেটর
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}