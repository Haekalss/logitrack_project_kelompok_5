import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kirimtrack/delivery_task_model.dart';

class ApiService {
  // URL endpoint dari API
  final String apiUrl = "https://jsonplaceholder.typicode.com/todos";

  // Mock data sebagai fallback
  List<DeliveryTask> _getMockData() {
    return [
      DeliveryTask(
        id: "KT001", 
        title: "Pengiriman Jakarta Selatan", 
        isCompleted: false,
        description: "Paket elektronik ke Kemang"
      ),
      DeliveryTask(
        id: "KT002", 
        title: "Pengiriman Bandung", 
        isCompleted: true,
        description: "Dokumen penting ke kantor pusat"
      ),
      DeliveryTask(
        id: "KT003", 
        title: "Pengiriman Surabaya", 
        isCompleted: false,
        description: "Paket makanan frozen"
      ),
      DeliveryTask(
        id: "KT004", 
        title: "Pengiriman Yogyakarta", 
        isCompleted: true,
        description: "Buku dan alat tulis"
      ),
      DeliveryTask(
        id: "KT005", 
        title: "Pengiriman Bali", 
        isCompleted: false,
        description: "Souvenir dan kerajinan tangan"
      ),
    ];
  }

  // Fungsi untuk mengambil data
  Future<List<DeliveryTask>> fetchDeliveryTasks() async {
    const int maxRetries = 2;
    int attempt = 0;
    int delayMs = 1000;

    while (attempt < maxRetries) {
      try {
        attempt++;
        print('Mencoba koneksi API, percobaan ke-$attempt...');
        
        final response = await http
            .get(Uri.parse(apiUrl))
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          List<dynamic> body = jsonDecode(response.body);
          List<DeliveryTask> tasks = body
              .map((dynamic item) => DeliveryTask.fromJson(item))
              .toList();

          // cache result locally
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_tasks', response.body);
            await prefs.setInt('cached_tasks_ts', DateTime.now().millisecondsSinceEpoch);
            print('Data API berhasil dimuat: ${tasks.length} tasks');
          } catch (e) {
            print('Warning: failed to write cache: $e');
          }

          return tasks;
        } else {
          print('API error: status ${response.statusCode}');
          if (attempt >= maxRetries) {
            print('API gagal setelah $maxRetries percobaan, menggunakan mock data...');
            return _getMockData();
          }
        }
      } on SocketException catch (e) {
        print('Network error: $e');
        if (attempt >= maxRetries) {
          // try cached data first, then mock
          final cached = await _loadCachedTasks();
          if (cached != null && cached.isNotEmpty) {
            print('Menggunakan data cache...');
            return cached;
          }
          print('Tidak ada cache, menggunakan mock data...');
          return _getMockData();
        }
      } on TimeoutException catch (e) {
        print('Timeout: $e');
        if (attempt >= maxRetries) {
          final cached = await _loadCachedTasks();
          if (cached != null && cached.isNotEmpty) {
            print('Menggunakan data cache karena timeout...');
            return cached;
          }
          print('Menggunakan mock data karena timeout...');
          return _getMockData();
        }
      } catch (e) {
        print('Unexpected error: $e');
        if (attempt >= maxRetries) {
          final cached = await _loadCachedTasks();
          if (cached != null && cached.isNotEmpty) return cached;
          print('Menggunakan mock data karena error...');
          return _getMockData();
        }
      }

      // Wait before retry
      if (attempt < maxRetries) {
        print('Menunggu ${delayMs}ms sebelum mencoba lagi...');
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs += 500;
      }
    }

    // Fallback terakhir
    print('Semua percobaan gagal, menggunakan mock data sebagai fallback...');
    return _getMockData();
  }

  Future<List<DeliveryTask>?> _loadCachedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cached_tasks');
      if (raw == null) return null;
      final body = jsonDecode(raw) as List<dynamic>;
      final tasks = body.map((e) => DeliveryTask.fromJson(e)).toList();
      print('Loaded ${tasks.length} tasks from cache');
      return tasks;
    } catch (e) {
      print('Failed to load cache: $e');
      return null;
    }
  }
}
