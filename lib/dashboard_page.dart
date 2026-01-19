import 'package:flutter/material.dart';
import 'package:p1/api_service.dart';
import 'package:p1/auth_service.dart';
import 'package:p1/delivery_task_model.dart';
import 'package:p1/login_page.dart';
import 'package:p1/delivery_detail_page.dart';
import 'package:p1/qr_scanner_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // instance ApiService
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  // future untuk hasil fetch
  late Future<List<DeliveryTask>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    // panggil API
    _tasksFuture = _apiService.fetchDeliveryTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LogiTrack - Dashboard'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Tampilkan dialog konfirmasi logout
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Apakah Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Ya, Logout'),
                    ),
                  ],
                ),
              );

              // Jika user memilih logout
              if (shouldLogout == true && mounted) {
                await _authService.signOut();
                if (mounted) {
                  // Navigasi ke LoginPage dan hapus semua route sebelumnya
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      // REPLACED: ListView statis -> FutureBuilder
      body: FutureBuilder<List<DeliveryTask>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          // loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // error
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data;
          // data ada & tidak kosong
          if (data != null && data.isNotEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final task = data[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 0,
                  ),
                  child: ListTile(
                    leading: Icon(
                      task.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: task.isCompleted ? Colors.green : Colors.grey,
                    ),
                    title: Text(task.title),
                    subtitle: Text('ID Tugas: ${task.id}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeliveryDetailPage(task: task),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
          // data kosong
          return const Center(child: Text('Tidak ada data pengiriman.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigasi ke QR Scanner
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScannerPage()),
          );
          // Tampilkan kode SCAN dalam SnackBar
          if (result != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Paket terdeteksi: $result')),
            );
          }
          // Untuk sekarang, kita hanya menampilkan hasilnya.
          // Kode petik diatas di alter 'task' dari FutureBuilder
          // jika ingin update/filter data berdasarkan QR, manipulasi
          // state menjadi StatefulWidget dan refetch jika perlu
        },
        backgroundColor: Colors.blueAccent,
        tooltip: 'Pindai QR',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
