import 'package:flutter/material.dart';
import 'package:p1/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:p1/providers/delivery_task_provider.dart';
import 'package:p1/profile_page.dart';
import 'package:p1/delivery_detail_page.dart';
import 'package:p1/qr_scanner_page.dart';
import 'package:p1/history_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // instance AuthService
  final AuthService _authService = AuthService();
  
  Widget _buildStatCard(String label, String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeliveryTaskProvider>(context, listen: false).fetchTasks();
    });
  }

  // initState above triggers provider fetch

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LogiTrack - Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Pengiriman',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const HistoryPage()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfilePage()));
              } else if (value == 'logout') {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Konfirmasi Logout'),
                    content: const Text('Apakah Anda yakin ingin keluar?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Ya, Logout')),
                    ],
                  ),
                );
                if (shouldLogout == true && mounted) {
                  await _authService.signOut();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Profil')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Consumer<DeliveryTaskProvider>(
        builder: (context, provider, child) {
          switch (provider.state) {
            case TaskState.Loading:
              return const Center(child: CircularProgressIndicator());
            case TaskState.Error:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text('Error', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(provider.errorMessage, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => provider.fetchTasks(),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              );
            case TaskState.Loaded:
              final data = provider.tasks;
              if (data.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox, size: 56, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text('Tidak ada data pengiriman.', style: theme.textTheme.titleLarge),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.fetchTasks(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final total = data.length;
                      final completed = data.where((t) => t.isCompleted).length;
                      final pending = total - completed;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Halo, Pengguna!', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                                    const SizedBox(height: 6),
                                    Text('Selamat datang di LogiTrack', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const QRScannerPage()),
                                    );
                                    if (result != null && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Paket terdeteksi: $result')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: const Text('Pindai QR'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: theme.colorScheme.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildStatCard('Total', total.toString(), Icons.format_list_bulleted, theme)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard('Selesai', completed.toString(), Icons.check_circle, theme)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard('Pending', pending.toString(), Icons.pending_actions, theme)),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }

                    final task = data[index - 1];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: task.isCompleted ? Colors.green[50] : theme.colorScheme.primary.withOpacity(0.12),
                          child: Icon(
                            task.isCompleted ? Icons.check : Icons.local_shipping,
                            color: task.isCompleted ? Colors.green : theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(task.title, style: theme.textTheme.titleLarge),
                        subtitle: Text('ID: ${task.id}', style: theme.textTheme.bodyMedium),
                        trailing: IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeliveryDetailPage(task: task),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            default:
              return const Center(child: Text('Memulai...'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScannerPage()),
          );
          if (result != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Paket terdeteksi: $result')),
            );
          }
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Pindai QR'),
      ),
    );
  }
}
