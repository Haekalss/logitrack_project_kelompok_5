import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:p1/delivery_task_model.dart';

class ApiService {
  // URL endpoint dari API
  final String apiUrl = "https://jsonplaceholder.typicode.com/todos";

  // Fungsi untuk mengambil data
  Future<List<DeliveryTask>> fetchDeliveryTasks() async {
    const int maxRetries = 3;
    int attempt = 0;
    int delayMs = 500; // initial backoff

    while (true) {
      try {
        attempt++;
        final response = await http
            .get(Uri.parse(apiUrl))
            .timeout(const Duration(seconds: 10));

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
          } catch (e) {
            // cache failure shouldn't block normal flow
            print('Warning: failed to write cache: $e');
          }

          return tasks;
        } else {
          final msg = 'Gagal memuat data dari API: status=${response.statusCode}';
          print(msg);
          throw Exception(msg);
        }
      } on SocketException catch (e) {
        final msg = 'Koneksi bermasalah: $e';
        print(msg);
        if (attempt >= maxRetries) {
          // try to return cached data if available
          final cached = await _loadCachedTasks();
          if (cached != null) return cached;
          throw Exception(msg);
        }
      } on TimeoutException catch (e) {
        final msg = 'Timeout saat menghubungi API: $e';
        print(msg);
        if (attempt >= maxRetries) {
          final cached = await _loadCachedTasks();
          if (cached != null) return cached;
          throw Exception(msg);
        }
      } catch (e) {
        final msg = 'Terjadi kesalahan: $e';
        print(msg);
        // non-network errors: don't retry
        final cached = await _loadCachedTasks();
        if (cached != null) return cached;
        throw Exception(msg);
      }

      // exponential backoff
      await Future.delayed(Duration(milliseconds: delayMs));
      delayMs *= 2;
    }
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
