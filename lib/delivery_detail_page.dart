import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'delivery_task_model.dart';
import 'location_service.dart';
import 'providers/offline_first_delivery_provider.dart';

class DeliveryDetailPage extends StatefulWidget {
  final String taskId; // Changed from DeliveryTask to String

  const DeliveryDetailPage({super.key, required this.taskId});

  @override
  State<DeliveryDetailPage> createState() => _DeliveryDetailPageState();
}

class _DeliveryDetailPageState extends State<DeliveryDetailPage> {
  XFile? _imageFile;
  bool _isPicking = false;
  Position? _currentPosition; // State untuk menyimpan posisi
  final LocationService _locationService = LocationService(); // Instance service

  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    try {
      setState(() => _isPicking = true);
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.camera);
      if (!mounted) {
        return;
      }
      if (pickedFile != null) {
        setState(() => _imageFile = pickedFile);
      }
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Lokasi berhasil direkam!\nLat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal merekam lokasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeDelivery(String taskId) async {
    try {
      // Tandai task sebagai selesai dengan data lengkap (foto, GPS, timestamp)
      await Provider.of<OfflineFirstDeliveryProvider>(context, listen: false)
          .completeTaskWithDetails(
        taskId: taskId,
        imagePath: _imageFile?.path,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Pengiriman ${taskId} berhasil diselesaikan dengan bukti lengkap!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Kembali ke halaman sebelumnya setelah 1 detik
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal menyelesaikan pengiriman: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProgressStep(String stepNumber, String stepLabel, bool isCompleted, Color activeColor, {required bool isDark}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted ? activeColor : (isDark ? const Color(0xFF2D3A4F) : const Color(0xFFE8EDF5)),
            shape: BoxShape.circle,
            boxShadow: isCompleted
                ? [BoxShadow(color: activeColor.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    stepNumber,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stepLabel,
          style: TextStyle(
            fontSize: 11,
            color: isCompleted ? activeColor : (isDark ? Colors.grey[400] : Colors.grey[500]),
            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const darkBlue = Color(0xFF1E3A8A);
    const primaryBlue = Color(0xFF2563EB);

    // Theme-aware colors
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final placeholderBg = isDark ? const Color(0xFF2D3A4F) : const Color(0xFFF1F5F9);
    final placeholderBorder = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final bodyColor = isDark ? Colors.grey[300]! : Colors.grey[600]!;
    final sectionIconColor = isDark ? const Color(0xFF60A5FA) : darkBlue;
    final sectionTitleColor = isDark ? const Color(0xFF93C5FD) : darkBlue;
    final inactiveLine = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final disabledBtnBg = isDark ? const Color(0xFF374151) : Colors.grey[400]!;
    final disabledBtnFg = isDark ? Colors.grey[500]! : Colors.grey[500]!;

    return Consumer<OfflineFirstDeliveryProvider>(
      builder: (context, provider, child) {
        final task = provider.tasks.firstWhere(
          (t) => t.id == widget.taskId,
          orElse: () => DeliveryTask(
            id: widget.taskId,
            title: 'Task not found',
            description: 'This task could not be loaded',
            isCompleted: false,
          ),
        );

        // Helper untuk cek bukti: gabungkan state lokal + data tersimpan di DB
        final bool hasPhoto = _imageFile != null || task.imagePath != null;
        final bool hasGps = _currentPosition != null || (task.latitude != null && task.longitude != null);
        final String? displayImagePath = _imageFile?.path ?? task.imagePath;
        final double? displayLat = _currentPosition?.latitude ?? task.latitude;
        final double? displayLon = _currentPosition?.longitude ?? task.longitude;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: darkBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Detail Pengiriman',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card - ID & Status
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [darkBlue, primaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: darkBlue.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${task.id}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? Colors.green.withValues(alpha: 0.25)
                              : Colors.orange.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              task.isCompleted ? Icons.check_circle : Icons.schedule,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              task.isCompleted ? 'Selesai' : 'Dalam Proses',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Progress Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timeline_rounded, color: sectionIconColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Progress Pengiriman',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: sectionTitleColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildProgressStep('1', 'Foto Bukti', hasPhoto, primaryBlue, isDark: isDark),
                          Expanded(
                            child: Container(
                              height: 2,
                              color: hasPhoto ? primaryBlue : inactiveLine,
                            ),
                          ),
                          _buildProgressStep('2', 'GPS Lokasi', hasGps, const Color(0xFFF59E0B), isDark: isDark),
                          Expanded(
                            child: Container(
                              height: 2,
                              color: hasGps ? const Color(0xFFF59E0B) : inactiveLine,
                            ),
                          ),
                          _buildProgressStep('3', 'Selesai', task.isCompleted, const Color(0xFF10B981), isDark: isDark),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bukti Pengiriman Card 
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.camera_alt_rounded, color: sectionIconColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Bukti Pengiriman',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: sectionTitleColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: placeholderBg,
                          border: Border.all(
                            color: hasPhoto ? const Color(0xFF10B981) : placeholderBorder,
                            width: hasPhoto ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: !hasPhoto
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt_outlined, size: 44, color: subtitleColor),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Belum ada foto bukti',
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ambil foto bukti pengiriman',
                                      style: TextStyle(color: subtitleColor.withValues(alpha: 0.7), fontSize: 12),
                                    ),
                                  ],
                                ),
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.file(
                                      File(displayImagePath!),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image_rounded, size: 44, color: subtitleColor),
                                              const SizedBox(height: 8),
                                              Text('Foto tersimpan', style: TextStyle(color: subtitleColor, fontSize: 13)),
                                              Text(displayImagePath.split('/').last, style: TextStyle(color: subtitleColor.withValues(alpha: 0.7), fontSize: 11)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: (task.isCompleted || _isPicking) ? null : _pickImageFromCamera,
                          icon: Icon(
                            hasPhoto ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
                            size: 20,
                          ),
                          label: Text(
                            hasPhoto ? 'Foto Sudah Diambil' : 'Ambil Foto Bukti',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasPhoto ? const Color(0xFF10B981) : primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Lokasi GPS Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: sectionIconColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Lokasi GPS',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: sectionTitleColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (hasGps)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lokasi Terekam',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Lat: ${displayLat!.toStringAsFixed(6)}  |  Lon: ${displayLon!.toStringAsFixed(6)}',
                                      style: TextStyle(fontSize: 12, color: bodyColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.location_off_rounded, color: Color(0xFFF59E0B), size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Lokasi belum direkam. Tekan tombol di bawah untuk merekam GPS.',
                                  style: TextStyle(fontSize: 13, color: Color(0xFFF59E0B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: task.isCompleted ? null : _getCurrentLocation,
                          icon: Icon(
                            hasGps ? Icons.check_circle_rounded : Icons.my_location_rounded,
                            size: 20,
                          ),
                          label: Text(
                            hasGps ? 'Lokasi Sudah Direkam' : 'Rekam Lokasi GPS',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasGps
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Selesaikan Pengiriman Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      task.isCompleted ? Icons.check_circle_rounded : Icons.task_alt_rounded,
                      size: 22,
                    ),
                    label: Text(
                      task.isCompleted ? 'Pengiriman Sudah Selesai' : 'Selesaikan Pengiriman',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: task.isCompleted
                        ? null
                        : (hasPhoto && hasGps)
                            ? () => _completeDelivery(task.id)
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: task.isCompleted
                          ? disabledBtnBg
                          : (hasPhoto && hasGps)
                              ? const Color(0xFF10B981)
                              : disabledBtnBg,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark ? const Color(0xFF374151) : Colors.grey[300],
                      disabledForegroundColor: disabledBtnFg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: (hasPhoto && hasGps && !task.isCompleted) ? 2 : 0,
                      shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                    ),
                  ),
                ),

                // Helper text
                if (!task.isCompleted && (!hasPhoto || !hasGps))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Center(
                      child: Text(
                        !hasPhoto && !hasGps
                            ? 'Ambil foto bukti dan rekam lokasi terlebih dahulu'
                            : !hasPhoto
                                ? 'Ambil foto bukti terlebih dahulu'
                                : 'Rekam lokasi GPS terlebih dahulu',
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}