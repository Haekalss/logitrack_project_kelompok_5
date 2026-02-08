import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kirimtrack/delivery_task_model.dart';
import 'package:kirimtrack/database_service.dart';

class OfflineFirstApiService {
  final String apiUrl = "https://jsonplaceholder.typicode.com/todos";
  final DatabaseService _dbService = DatabaseService();
  
  // Stream untuk mengamati perubahan konektivitas
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOnline = false;

  OfflineFirstApiService() {
    _initConnectivity();
  }

  void _initConnectivity() {
    // Monitor connectivity changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      _isOnline = result.isNotEmpty && 
                  result.any((r) => r != ConnectivityResult.none);
      if (_isOnline) {
        _syncWithServer();
      }
    });
  }

  // **OFFLINE-FIRST: Selalu load dari database lokal dulu**
  Future<List<DeliveryTask>> fetchDeliveryTasks() async {
    try {
      // 1. Load data dari database lokal DULU
      List<DeliveryTask> localTasks = await _dbService.getAllTasks();
      
      // 2. Kalau ada data lokal, return langsung
      if (localTasks.isNotEmpty) {
        print('Menggunakan data lokal: ${localTasks.length} tasks');
        
        // 3. Background sync kalau online
        if (_isOnline) {
          _backgroundSync();
        }
        
        return localTasks;
      }
      
      // 4. Kalau database kosong, coba fetch dari server
      if (_isOnline) {
        return await _fetchFromServerAndStore();
      }
      
      // 5. Kalau offline dan database kosong, gunakan mock data
      print('Offline dan database kosong, menggunakan mock data...');
      List<DeliveryTask> mockTasks = _getMockData();
      
      // Simpan mock data ke database untuk offline access
      for (var task in mockTasks) {
        await _dbService.insertTask(task);
      }
      
      return mockTasks;
      
    } catch (e) {
      print('Error in fetchDeliveryTasks: $e');
      // Fallback ke data lokal jika ada error
      return await _dbService.getAllTasks();
    }
  }

  // Fetch dari server dan simpan ke database lokal
  Future<List<DeliveryTask>> _fetchFromServerAndStore() async {
    try {
      print('Fetching data dari server...');
      
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<DeliveryTask> serverTasks = body
            .map((dynamic item) => DeliveryTask.fromJson(item))
            .toList();

        // Ambil data lokal yang ada bukti (foto/GPS) agar tidak tertimpa
        final localTasks = await _dbService.getAllTasks();
        final localTaskMap = <String, DeliveryTask>{};
        for (var t in localTasks) {
          if (t.imagePath != null || t.latitude != null || t.completedAt != null) {
            localTaskMap[t.id] = t;
          }
        }

        // Merge: pertahankan data lokal (foto, GPS, completedAt) jika ada
        List<DeliveryTask> mergedTasks = serverTasks.map((serverTask) {
          final local = localTaskMap[serverTask.id];
          if (local != null) {
            return serverTask.copyWith(
              isCompleted: local.isCompleted,
              imagePath: local.imagePath,
              latitude: local.latitude,
              longitude: local.longitude,
              completedAt: local.completedAt,
            );
          }
          return serverTask;
        }).toList();

        // Tambahkan task lokal yang tidak ada di server (task buatan lokal)
        for (var local in localTasks) {
          if (!mergedTasks.any((t) => t.id == local.id)) {
            mergedTasks.add(local);
          }
        }

        // Simpan hasil merge ke database
        await _dbService.clearAllData();
        for (var task in mergedTasks) {
          await _dbService.insertTask(task);
          await _dbService.markTaskAsSynced(task.id);
        }

        print('✅ Data server berhasil di-merge: ${mergedTasks.length} tasks');
        return mergedTasks;
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        // Silent fail untuk auth/permission errors - gunakan local data
        print('⚠️ Server auth failed - using local data');
        return await _dbService.getAllTasks();
      } else {
        // Server error lainnya - fallback ke local
        print('⚠️ Server error ${response.statusCode} - using local data');
        return await _dbService.getAllTasks();
      }
    } catch (e) {
      // Network error atau timeout - gunakan local data
      print('⚠️ Network error - using offline data: $e');
      return await _dbService.getAllTasks();
    }
  }

  // Background sync tanpa menggangu UI - silent fail jika offline
  void _backgroundSync() {
    Timer(const Duration(seconds: 2), () async {
      try {
        if (_isOnline) {
          await _fetchFromServerAndStore();
          print('✅ Background sync completed');
        }
      } catch (e) {
        // Silent fail - app tetap bekerja dengan local data
        print('📱 Background sync (optional) - using local data');
      }
    });
  }

  // **OFFLINE-FIRST CRUD Operations**
  
  Future<void> addTask(DeliveryTask task) async {
    // 1. Simpan ke database lokal dulu (SELALU berhasil)
    await _dbService.insertTask(task);
    print('Task berhasil disimpan offline: ${task.id}');
    
    // 2. Kalau online, coba sync ke server
    if (_isOnline) {
      await _syncTaskToServer(task, 'POST');
    }
  }

  Future<void> updateTask(DeliveryTask task) async {
    // 1. Update di database lokal dulu
    await _dbService.updateTask(task);
    print('Task berhasil diupdate offline: ${task.id}');
    
    // 2. Kalau online, coba sync ke server  
    if (_isOnline) {
      await _syncTaskToServer(task, 'PUT');
    }
  }

  Future<void> deleteTask(String taskId) async {
    // 1. Delete dari database lokal dulu
    await _dbService.deleteTask(taskId);
    print('Task berhasil dihapus offline: $taskId');
    
    // 2. Kalau online, coba sync ke server
    if (_isOnline) {
      await _syncDeleteToServer(taskId);
    }
  }

  // Sync individual task ke server
  Future<void> _syncTaskToServer(DeliveryTask task, String method) async {
    try {
      final uri = method == 'POST' 
          ? Uri.parse(apiUrl)
          : Uri.parse('$apiUrl/${task.id}');
      
      final response = method == 'POST'
          ? await http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(task.toJson()),
            )
          : await http.put(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(task.toJson()),
            );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _dbService.markTaskAsSynced(task.id);
        print('Task berhasil disync ke server: ${task.id}');
      }
    } catch (e) {
      print('Gagal sync task ke server: $e (akan dicoba lagi nanti)');
    }
  }

  Future<void> _syncDeleteToServer(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/$taskId'),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Task berhasil dihapus dari server: $taskId');
      }
    } catch (e) {
      print('Gagal hapus task dari server: $e');
    }
  }

  // Sync semua perubahan yang belum tersinkronisasi
  Future<void> _syncWithServer() async {
    try {
      final unsyncedTasks = await _dbService.getUnsyncedTasks();
      
      for (var taskMap in unsyncedTasks) {
        final task = DeliveryTask(
          id: taskMap['id'] as String,
          title: taskMap['title'] as String, 
          description: taskMap['description'] as String?,
          isCompleted: (taskMap['is_completed'] as int) == 1,
          imagePath: taskMap['image_path'] as String?,
          latitude: taskMap['latitude'] as double?,
          longitude: taskMap['longitude'] as double?,
          completedAt: taskMap['completed_at'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(taskMap['completed_at'] as int)
              : null,
        );
        
        await _syncTaskToServer(task, 'PUT');
      }
      
      if (unsyncedTasks.isNotEmpty) {
        print('Selesai sync ${unsyncedTasks.length} task yang pending');
      }
    } catch (e) {
      print('Error during sync: $e');
    }
  }

  // Mock data for fallback
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
    ];
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }
}