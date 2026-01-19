import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:p1/dashboard_page.dart';
import 'package:p1/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Jika user belum login
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // Jika user sudah login
        return const DashboardPage();
      },
    );
  }
}
