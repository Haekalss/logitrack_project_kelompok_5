import 'package:flutter/material.dart';
import 'package:kirimtrack/delivery_task_model.dart';
import 'package:kirimtrack/offline_first_api_service.dart';

/// Provider untuk mengelola delivery tasks dengan offline-first approach
class OfflineFirstDeliveryProvider with ChangeNotifier {
  final OfflineFirstApiService _apiService = OfflineFirstApiService();
  
  List<DeliveryTask> _tasks = [];
  bool _isLoading = false;
  String? _error;
  bool _isOnline = true;

  // Getters
  List<DeliveryTask> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnline => _isOnline;
  
  int get completedTasksCount => 
      _tasks.where((task) => task.isCompleted).length;
  
  int get pendingTasksCount => 
      _tasks.where((task) => !task.isCompleted).length;

  /// Fetch tasks - OFFLINE FIRST
  /// Akan selalu load dari database lokal dulu, lalu sync background
  Future<void> fetchTasks() async {
    _setLoading(true);
    _error = null;
    
    try {
      // Offline-first: Load dari database lokal dulu
      _tasks = await _apiService.fetchDeliveryTasks();
      
      // Jika tidak ada data, tambah dummy data
      if (_tasks.isEmpty) {
        await _insertDummyData();
        _tasks = await _apiService.fetchDeliveryTasks();
      }
      
      notifyListeners();
      
      print('✅ Tasks loaded successfully: ${_tasks.length} tasks');
    } catch (e) {
      _error = 'Error loading tasks: $e';
      print('❌ Error in fetchTasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Insert dummy data untuk testing
  Future<void> _insertDummyData() async {
    final dummyTasks = [
      DeliveryTask(
        id: 'PKG001',
        title: 'Pengiriman ke Jakarta Pusat',
        description: 'Paket elektronik untuk PT. Teknologi Maju - Jl. Sudirman No. 123',
        isCompleted: false,
      ),
      DeliveryTask(
        id: 'PKG002',
        title: 'Delivery Bandung - Cimahi',
        description: 'Fashion items untuk Toko Cantik - Jl. Raya Cimahi No. 45',
        isCompleted: true,
      ),
      DeliveryTask(
        id: 'PKG003',
        title: 'Pengiriman Express Surabaya',
        description: 'Dokumen penting untuk Kantor Hukum Bersama - Jl. Tunjungan',
        isCompleted: false,
      ),
      DeliveryTask(
        id: 'PKG004',
        title: 'Same Day Delivery Depok',
        description: 'Makanan & minuman untuk acara kantor - Jl. Margonda Raya',
        isCompleted: true,
      ),
      DeliveryTask(
        id: 'PKG005',
        title: 'Pengiriman Regular Bekasi',
        description: 'Spare part kendaraan - Jl. Ahmad Yani Bekasi Timur',
        isCompleted: false,
      ),
      DeliveryTask(
        id: 'PKG006',
        title: 'Urgent Delivery Tangerang',
        description: 'Obat-obatan untuk Apotek Sehat - Jl. Diponegoro Tangerang',
        isCompleted: false,
      ),
      DeliveryTask(
        id: 'PKG007',
        title: 'Cod Delivery Bogor',
        description: 'Pakaian bayi untuk Ibu Sari - Jl. Pajajaran Bogor',
        isCompleted: false,
      ),
      DeliveryTask(
        id: 'PKG008',
        title: 'Regular Shipment Yogyakarta',
        description: 'Buku dan alat tulis untuk Toko Buku Pintar - Jl. Malioboro',
        isCompleted: false,
      ),
      DeliveryTask(
        id: 'PKG009',
        title: 'Electronics Express Semarang',
        description: 'Laptop dan aksesoris untuk PT. Digital Solution - Jl. Pemuda',
        isCompleted: false,
      ),
      DeliveryTask(
        id: 'PKG010',
        title: 'Medical Supply Malang',
        description: 'Peralatan medis untuk RS. Harapan Sehat - Jl. Veteran Malang',
        isCompleted: false,
      ),
    ];

    for (final task in dummyTasks) {
      await _apiService.addTask(task);
    }
    print('✅ Dummy data inserted successfully!');
  }

  /// Tambah task baru - OFFLINE FIRST
  Future<void> addTask(DeliveryTask task) async {
    _setLoading(true);
    _error = null;
    
    try {
      // Add ke service (akan disimpan offline dulu)
      await _apiService.addTask(task);
      
      // Update UI langsung
      _tasks.add(task);
      notifyListeners();
      
      print('✅ Task added offline-first: ${task.id}');
    } catch (e) {
      _error = 'Error adding task: $e';
      print('❌ Error adding task: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update task - OFFLINE FIRST  
  Future<void> updateTask(DeliveryTask updatedTask) async {
    _error = null;
    
    try {
      // Update di service
      await _apiService.updateTask(updatedTask);
      
      // Update UI langsung
      final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
      
      print('✅ Task updated offline-first: ${updatedTask.id}');
    } catch (e) {
      _error = 'Error updating task: $e';
      print('❌ Error updating task: $e');
    }
  }

  /// Toggle complete status - OFFLINE FIRST
  Future<void> toggleTaskComplete(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
    );

    await updateTask(updatedTask);
  }

  /// Complete task with details (photo, location, timestamp) - OFFLINE FIRST
  Future<void> completeTaskWithDetails({
    required String taskId,
    String? imagePath,
    double? latitude,
    double? longitude,
  }) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final updatedTask = task.copyWith(
      isCompleted: true,
      imagePath: imagePath,
      latitude: latitude,
      longitude: longitude,
      completedAt: DateTime.now(),
    );

    await updateTask(updatedTask);
  }

  /// Delete task - OFFLINE FIRST
  Future<void> deleteTask(String taskId) async {
    _error = null;
    
    try {
      // Delete dari service
      await _apiService.deleteTask(taskId);
      
      // Update UI langsung
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
      
      print('✅ Task deleted offline-first: $taskId');
    } catch (e) {
      _error = 'Error deleting task: $e';
      print('❌ Error deleting task: $e');
    }
  }

  /// Filter tasks berdasarkan status
  List<DeliveryTask> getFilteredTasks(String filter, String searchQuery) {
    var filteredTasks = _tasks;
    
    // Filter berdasarkan status
    switch (filter) {
      case 'Belum Selesai':
        filteredTasks = filteredTasks.where((task) => !task.isCompleted).toList();
        break;
      case 'Selesai':
        filteredTasks = filteredTasks.where((task) => task.isCompleted).toList();
        break;
      case 'Semua':
      default:
        break;
    }
    
    // Filter berdasarkan search query
    if (searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) =>
        task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
        task.description?.toLowerCase().contains(searchQuery.toLowerCase()) == true
      ).toList();
    }
    
    return filteredTasks;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}