import 'package:flutter/material.dart';
import 'package:p1/login_page.dart';
import 'package:p1/register_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                      ),
                      child: const Icon(Icons.local_shipping, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 20),
                    Text('LogiTrack', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Pantau pengiriman dengan mudah', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black54)),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Aplikasi manajemen pengiriman sederhana untuk kurir dan penerima. Masuk untuk melihat tugas Anda atau daftar jika belum punya akun.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),

              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginPage())),
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Masuk')),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const RegisterPage())),
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Daftar')),
              ),
              const SizedBox(height: 18),
              Text('Dengan menggunakan aplikasi ini, Anda setuju dengan syarat dan ketentuan kami.', textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
