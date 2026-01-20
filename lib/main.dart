import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:p1/auth_gate.dart';
import 'package:p1/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:p1/providers/delivery_task_provider.dart';

void main() async {
  // Pastikan Flutter binding terinisialisasi
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => DeliveryTaskProvider(),
      child: const MyApp(),
    ),
  );
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
