import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:p1/auth_gate.dart';
import 'package:p1/firebase_options.dart';

void main() async {
  // Pastikan Flutter binding terinisialisasi
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// Ini adalah contoh StatelessWidget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}
