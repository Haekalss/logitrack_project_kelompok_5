import 'package:flutter/material.dart';
import 'Dashboard_page.dart';
import 'package:p1/auth_service.dart';
import 'package:p1/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:p1/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Tambahkan GlobalKey untuk Form
  final _formKey = GlobalKey<FormState>();

  // ✅ 1. Variabel state untuk melacak visibilitas password
  bool _isPasswordVisible = false;

  // ✅ 2. Controller untuk email & password
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ✅ 3. Membuat instance dari ApiService
  final apiService = ApiService();

  // ... di dalam _LoginPageState
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LogiTrack - Login'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        // 2. Bungkus Column dengan Form dan berikan key
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Ikon atau Logo
              const Icon(
                Icons.local_shipping,
                size: 80,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 48),

              // 3. Mengganti TextField menjadi TextFormField
              // Untuk TextFormField Email:
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                // Tambahkan validator untuk email
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  // Validasi format email sederhana
                  if (!value.contains('@')) {
                    return 'Masukkan format email yang valid';
                  }
                  return null; // Return null jika valid
                },
              ),
              const SizedBox(height: 16),

              // Untuk TextFormField Password:
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible, // tergantung state
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  // Tambahkan ikon di ujung kanan
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      // Ubah state visibilitas password
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                // Tambahkan validator untuk password
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  if (value.length < 6) {
                    return 'Password minimal harus 6 karakter';
                  }
                  return null; // Return null jika valid
                },
              ),

              const SizedBox(height: 32),

              // 5. Memicu Validasi Saat Tombol Ditekan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // 1. Cek apakah form valid
                    if (_formKey.currentState!.validate()) {
                      // Panggil service untuk login
                      User? user = await _authService.signInWithEmailPassword(
                        _emailController.text,
                        _passwordController.text,
                      );

                      if (user != null) {
                        // Navigasi jika login berhasil
                        Navigator.pushReplacement(
                          // Gunakan pushReplacement agar tidak bisa kembali ke login
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardPage(),
                          ),
                        );
                      } else {
                        // Tampilkan pesan error jika login gagal. Periksa email dan password Anda."));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Login gagal. Periksa email dan password Anda.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('LOGIN', style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 16),

              // Link to Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Belum punya akun? '),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text('Daftar di sini'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
