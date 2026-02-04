import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kirimtrack/providers/theme_provider.dart';
import 'package:kirimtrack/services/notification_service.dart';
import 'package:kirimtrack/widgets/custom_cards.dart';
import 'package:kirimtrack/widgets/status_widgets.dart';
import 'package:kirimtrack/theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = '';
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }
  
  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Section
            _buildUserSection(theme),
            
            const SizedBox(height: 20),
            
            // Appearance Section
            _buildSectionHeader('Tampilan', theme),
            _buildAppearanceSection(),
            
            const SizedBox(height: 20),
            
            // Notifications Section
            _buildSectionHeader('Notifikasi', theme),
            _buildNotificationsSection(),
            
            const SizedBox(height: 20),
            
            // Privacy & Security Section
            _buildSectionHeader('Privasi & Keamanan', theme),
            _buildPrivacySection(),
            
            const SizedBox(height: 20),
            
            // Support Section
            _buildSectionHeader('Dukungan', theme),
            _buildSupportSection(),
            
            const SizedBox(height: 20),
            
            // About Section
            _buildSectionHeader('Tentang', theme),
            _buildAboutSection(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildUserSection(ThemeData theme) {
    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengguna KirimTrack',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'user@kirimtrack.com',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          children: [
            _buildSettingsTile(
              title: 'Mode Gelap',
              subtitle: 'Ubah tampilan aplikasi',
              leading: Icons.dark_mode,
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              ),
            ),
            _buildSettingsTile(
              title: 'Bahasa',
              subtitle: 'Indonesia',
              leading: Icons.language,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageSelector(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      children: [
        _buildSettingsTile(
          title: 'Notifikasi Push',
          subtitle: 'Terima notifikasi pengiriman',
          leading: Icons.notifications,
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              CustomSnackBar.show(
                context,
                message: value 
                  ? 'Notifikasi diaktifkan'
                  : 'Notifikasi dinonaktifkan',
                type: SnackBarType.success,
              );
            },
          ),
        ),
        _buildSettingsTile(
          title: 'Pusat Notifikasi',
          subtitle: 'Lihat semua notifikasi',
          leading: Icons.notification_important,
          trailing: Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.unreadCount > 0)
                    StatusBadge(status: provider.unreadCount.toString()),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              );
            },
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationCenter()),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      children: [
        _buildSettingsTile(
          title: 'Lokasi',
          subtitle: 'Izinkan akses lokasi untuk tracking',
          leading: Icons.location_on,
          trailing: Switch(
            value: _locationEnabled,
            onChanged: (value) {
              setState(() {
                _locationEnabled = value;
              });
            },
          ),
        ),
        _buildSettingsTile(
          title: 'Data & Privasi',
          subtitle: 'Kelola data pribadi Anda',
          leading: Icons.security,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showPrivacyDialog(),
        ),
        _buildSettingsTile(
          title: 'Hapus Cache',
          subtitle: 'Bersihkan data sementara',
          leading: Icons.cleaning_services,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showClearCacheDialog(),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      children: [
        _buildSettingsTile(
          title: 'Bantuan',
          subtitle: 'FAQ dan panduan penggunaan',
          leading: Icons.help,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _launchUrl('https://kirimtrack.com/help'),
        ),
        _buildSettingsTile(
          title: 'Hubungi Kami',
          subtitle: 'support@kirimtrack.com',
          leading: Icons.email,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _launchUrl('mailto:support@kirimtrack.com'),
        ),
        _buildSettingsTile(
          title: 'Laporkan Bug',
          subtitle: 'Bantu kami tingkatkan aplikasi',
          leading: Icons.bug_report,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showBugReportDialog(),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        _buildSettingsTile(
          title: 'Versi Aplikasi',
          subtitle: _appVersion,
          leading: Icons.info,
          onTap: () => _showAppInfoDialog(),
        ),
        _buildSettingsTile(
          title: 'Syarat & Ketentuan',
          subtitle: 'Ketentuan penggunaan aplikasi',
          leading: Icons.description,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _launchUrl('https://kirimtrack.com/terms'),
        ),
        _buildSettingsTile(
          title: 'Kebijakan Privasi',
          subtitle: 'Cara kami melindungi data Anda',
          leading: Icons.privacy_tip,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _launchUrl('https://kirimtrack.com/privacy'),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    
    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              leading,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Bahasa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Bahasa Indonesia'),
              trailing: const Icon(Icons.check, color: Colors.green),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                Navigator.pop(context);
                CustomSnackBar.show(
                  context,
                  message: 'English coming soon!',
                  type: SnackBarType.info,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data & Privasi'),
        content: const Text(
          'KirimTrack berkomitmen melindungi privasi Anda. Data yang dikumpulkan hanya digunakan untuk meningkatkan layanan pengiriman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Cache'),
        content: const Text(
          'Menghapus cache akan membersihkan data sementara dan mungkin mempercepat aplikasi. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              CustomSnackBar.show(
                context,
                message: 'Cache berhasil dihapus',
                type: SnackBarType.success,
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laporkan Bug'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Terima kasih atas bantuan Anda!'),
            SizedBox(height: 12),
            Text('Silakan kirim laporan bug ke:'),
            SizedBox(height: 8),
            Text(
              'bugs@kirimtrack.com',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('KirimTrack'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versi: $_appVersion'),
            const SizedBox(height: 8),
            const Text('Smart Delivery Management System'),
            const SizedBox(height: 12),
            const Text('© 2026 KirimTrack Team'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Tidak dapat membuka link',
          type: SnackBarType.error,
        );
      }
    }
  }
}