import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kirimtrack/providers/offline_user_profile_provider.dart';
import 'package:kirimtrack/providers/offline_first_delivery_provider.dart';
import 'package:kirimtrack/auth_service.dart';
import 'package:kirimtrack/user_profile_model.dart';

class OfflineProfilePage extends StatefulWidget {
  const OfflineProfilePage({super.key});

  @override
  State<OfflineProfilePage> createState() => _OfflineProfilePageState();
}

class _OfflineProfilePageState extends State<OfflineProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile Driver'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: Consumer2<OfflineUserProfileProvider, OfflineFirstDeliveryProvider>(
        builder: (context, profileProvider, deliveryProvider, child) {
          if (profileProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat profil...'),
                ],
              ),
            );
          }

          if (profileProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${profileProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => profileProvider.initialize(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final profile = profileProvider.currentProfile;
          if (profile == null) {
            return const Center(
              child: Text('Profil tidak ditemukan'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(profile, theme, profileProvider, deliveryProvider),
                const SizedBox(height: 24),
                
                // Statistics Cards - menggunakan data dari delivery provider
                _buildStatsGrid(deliveryProvider, theme),
                const SizedBox(height: 24),
                
                // Profile Details
                _buildProfileDetails(profile, theme, deliveryProvider),
                const SizedBox(height: 24),
                
                // Settings Section
                _buildSettingsSection(theme, profileProvider),
                const SizedBox(height: 24),
                
                // Action Buttons
                _buildActionButtons(theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile, ThemeData theme, OfflineUserProfileProvider provider, OfflineFirstDeliveryProvider deliveryProvider) {
    // Calculate experience level dari actual tasks
    final totalDeliveries = deliveryProvider.tasks.length;
    String experienceLevel;
    if (totalDeliveries >= 100) {
      experienceLevel = 'Expert Driver';
    } else if (totalDeliveries >= 50) {
      experienceLevel = 'Experienced Driver';
    } else if (totalDeliveries >= 20) {
      experienceLevel = 'Regular Driver';
    } else if (totalDeliveries >= 5) {
      experienceLevel = 'New Driver';
    } else {
      experienceLevel = 'Rookie Driver';
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Picture
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: profile.profileImageUrl != null
                      ? (profile.profileImageUrl!.startsWith('http')
                          ? NetworkImage(profile.profileImageUrl!)
                          : FileImage(File(profile.profileImageUrl!)))
                      : null,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: profile.profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      iconSize: 20,
                      onPressed: () => _pickImage(provider),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Name and Email
            Text(
              profile.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (profile.phoneNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                profile.phoneNumber!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 12),
            
            // Experience Level Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Text(
                experienceLevel,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(OfflineFirstDeliveryProvider deliveryProvider, ThemeData theme) {
    final total = deliveryProvider.tasks.length;
    final completed = deliveryProvider.completedTasksCount;
    final completionRate = total > 0 ? (completed / total * 100).toStringAsFixed(0) : '0';
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Pengiriman',
            total.toString(),
            Icons.local_shipping,
            theme.colorScheme.primary,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Selesai',
            completed.toString(),
            Icons.check_circle,
            Colors.green,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tingkat Selesai',
            '$completionRate%',
            Icons.trending_up,
            Colors.orange,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetails(UserProfile profile, ThemeData theme, OfflineFirstDeliveryProvider deliveryProvider) {
    // Calculate completion rate dari actual tasks
    final total = deliveryProvider.tasks.length;
    final completed = deliveryProvider.completedTasksCount;
    final completionRate = total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0';
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Profil',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Tingkat Penyelesaian', '${completionRate}%', Icons.trending_up),
            _buildDetailRow('Bergabung Sejak', _formatDate(profile.joinDate), Icons.calendar_today),
            _buildDetailRow('Terakhir Update', _formatDate(profile.lastUpdated), Icons.update),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(ThemeData theme, OfflineUserProfileProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaturan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Dark Mode Toggle
            _buildSettingTile(
              'Mode Gelap',
              'Menggunakan tema gelap untuk aplikasi',
              Icons.dark_mode,
              Switch(
                value: provider.isDarkModeEnabled,
                onChanged: (value) => provider.toggleDarkMode(value),
              ),
            ),
            
            // Notifications Toggle
            _buildSettingTile(
              'Notifikasi',
              'Terima notifikasi pengiriman dan update',
              Icons.notifications,
              Switch(
                value: provider.isNotificationsEnabled,
                onChanged: (value) => provider.toggleNotifications(value),
              ),
            ),
            
            // Auto Backup Toggle
            _buildSettingTile(
              'Backup Otomatis',
              'Backup data secara otomatis',
              Icons.backup,
              Switch(
                value: provider.isAutoBackupEnabled,
                onChanged: (value) => provider.toggleAutoBackup(value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, Widget trailing) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showChangePasswordDialog(),
            icon: const Icon(Icons.lock),
            label: const Text('Ganti Password'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _pickImage(OfflineUserProfileProvider provider) async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 80,
                );
                if (image != null && mounted) {
                  await provider.updateProfile(profileImageUrl: image.path);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Foto profil berhasil diperbarui!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Ambil Foto'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 80,
                );
                if (image != null && mounted) {
                  await provider.updateProfile(profileImageUrl: image.path);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Foto profil berhasil diperbarui!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final provider = context.read<OfflineUserProfileProvider>();
    final profile = provider.currentProfile;
    if (profile == null) return;

    final nameController = TextEditingController(text: profile.name);
    final phoneController = TextEditingController(text: profile.phoneNumber ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.updateProfile(
                name: nameController.text.trim().isNotEmpty ? nameController.text.trim() : null,
                phoneNumber: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil berhasil diperbarui!')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    // TODO: Implement change password functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur ganti password akan segera hadir!')),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final provider = context.read<OfflineUserProfileProvider>();
        await provider.logout();
        await auth.signOut();
        
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saat logout: $e')),
          );
        }
      }
    }
  }
}