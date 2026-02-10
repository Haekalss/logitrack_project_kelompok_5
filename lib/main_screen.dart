import 'package:flutter/material.dart';
import 'package:kirimtrack/efficient_dashboard.dart';
import 'package:kirimtrack/offline_history_page.dart';
import 'package:kirimtrack/profile_page.dart';
import 'package:kirimtrack/qr_scanner_page.dart';
import 'package:provider/provider.dart';
import 'package:kirimtrack/providers/offline_first_delivery_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  // List of pages
  final List<Widget> _pages = [
    const EfficientDashboard(),
    const TasksPage(),
    const SizedBox.shrink(), // QR Scanner akan dibuka sebagai modal
    const OfflineHistoryPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // QR Scanner - buka sebagai modal/full screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerPage()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
        children: [
          _pages[0], // Beranda
          _pages[1], // Tasks
          _pages[3], // History
          _pages[4], // Profile
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6,
          elevation: 0,
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Beranda
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Beranda',
                index: 0,
                theme: theme,
              ),

              // Tasks
              _buildNavItem(
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment,
                label: 'Tasks',
                index: 1,
                theme: theme,
              ),

              // QR Scanner (Tengah - Floating)
              const SizedBox(width: 48), // Space untuk floating button

              // History
              _buildNavItem(
                icon: Icons.history_outlined,
                activeIcon: Icons.history,
                label: 'History',
                index: 3,
                theme: theme,
              ),

              // Profile
              _buildNavItem(
                icon: Icons.account_circle_outlined,
                activeIcon: Icons.account_circle,
                label: 'Profile',
                index: 4,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        height: 65,
        width: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'qr_scanner_fab', // Tambahkan unique hero tag
          onPressed: () => _onItemTapped(2),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: const Icon(
            Icons.qr_code_scanner,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    final isActive = _currentIndex == index;
      return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? theme.colorScheme.primary : Colors.grey.shade600,
              size: 22,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? theme.colorScheme.primary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tasks Page - Halaman untuk menampilkan daftar tugas
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OfflineFirstDeliveryProvider>(
        context,
        listen: false,
      ).fetchTasks();
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
          ),
        ),
      ),
      body: Consumer<OfflineFirstDeliveryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Terjadi Kesalahan',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => provider.fetchTasks(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final allTasks = provider.tasks;
          
          if (allTasks.isEmpty) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.05),
                    Colors.white,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Belum Ada Tugas',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'Semua tugas pengiriman akan\nditampilkan di sini',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchTasks(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allTasks.length,
              itemBuilder: (context, index) {
                final task = allTasks[index];
                final isCompleted = task.isCompleted;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: isCompleted 
                          ? Colors.green.shade50 
                          : Colors.orange.shade50,
                      child: Icon(
                        isCompleted ? Icons.check_circle : Icons.pending,
                        color: isCompleted 
                            ? Colors.green.shade600 
                            : Colors.orange.shade600,
                        size: 32,
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.tag,
                                size: 16,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ID: ${task.id}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                isCompleted ? Icons.done_all : Icons.schedule,
                                size: 16,
                                color: isCompleted 
                                    ? Colors.green.shade600 
                                    : Colors.orange.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCompleted ? 'Selesai' : 'Pending',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isCompleted 
                                      ? Colors.green.shade600 
                                      : Colors.orange.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (task.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              task.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    onTap: () {
                      // Navigate to detail page
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
