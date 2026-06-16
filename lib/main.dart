import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart'; // স্প্ল্যাশ স্ক্রিনটি ইম্পোর্ট করুন

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'বাকি খাতা',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      // অ্যাপ ওপেন হলেই প্রথমে SplashScreen দেখাবে
      home: const SplashScreen(), 
    );
  }
}