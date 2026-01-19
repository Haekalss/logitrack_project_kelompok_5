import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import 'delivery_task_model.dart';
import 'location_service.dart';

class DeliveryDetailPage extends StatefulWidget {
  final DeliveryTask task;

  const DeliveryDetailPage({super.key, required this.task});

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

  Future<void> _getCurrentLocationAndCompleteDelivery() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengiriman Selesai di Lat: ${position.latitude}, Lon: ${position.longitude}'),
        ),
      );
      // Di sini Anda bisa menandai tugas selesai atau mengirim data ke server
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail: ${widget.task.id}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${widget.task.isCompleted ? "Selesai" : "Dalam Proses"}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Bukti Pengiriman',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _imageFile == null
                  ? const Center(child: Text('Belum ada gambar'))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_imageFile!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPicking ? null : _pickImageFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Ambil Foto Bukti'),
              ),
            ),
            const SizedBox(height: 16),
            // Widget untuk menampilkan data lokasi
            if (_currentPosition != null)
              Text(
                'Lokasi Terekam:\nLat: ${_currentPosition!.latitude}\nLon: ${_currentPosition!.longitude}',
                style: const TextStyle(fontSize: 16, color: Colors.green),
              )
            else
              const Text(
                'Lokasi belum direkam.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.location_on),
                label: const Text('Selesaikan Pengiriman & Rekam Lokasi'),
                onPressed: _getCurrentLocationAndCompleteDelivery,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
