import 'package:flutter/material.dart';
import 'package:kirimtrack/delivery_task_model.dart';
import 'package:kirimtrack/api_service.dart';

enum TaskState { Initial, Loading, Loaded, Error }

class DeliveryTaskProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<DeliveryTask> _tasks = [];
  TaskState _state = TaskState.Initial;
  String _errorMessage = '';

  List<DeliveryTask> get tasks => _tasks;
  TaskState get state => _state;
  String get errorMessage => _errorMessage;

  // Getter untuk filter tugas yang sudah selesai
  List<DeliveryTask> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();

  // Getter untuk filter tugas yang belum selesai
  List<DeliveryTask> get pendingTasks =>
      _tasks.where((task) => !task.isCompleted).toList();

  Future<void> fetchTasks() async {
    if (_state == TaskState.Loading) return; // Prevent multiple calls
    
    _state = TaskState.Loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _tasks = await _apiService.fetchDeliveryTasks();
      // Jika berhasil dapat data (termasuk mock), set ke Loaded
      _state = TaskState.Loaded;
      _errorMessage = '';
      print('✅ Tasks loaded successfully: ${_tasks.length} tasks');
    } catch (e) {
      print('❌ Error fetching tasks: $e');
      _state = TaskState.Error;
      _errorMessage = 'Tidak dapat memuat data. Periksa koneksi internet Anda.';
    }

    notifyListeners();
  }

  // Method untuk refresh tanpa loading state
  Future<void> refreshTasks() async {
    try {
      final newTasks = await _apiService.fetchDeliveryTasks();
      if (newTasks.isNotEmpty) {
        _tasks = newTasks;
        _state = TaskState.Loaded;
        _errorMessage = '';
        notifyListeners();
      }
    } catch (e) {
      // Silent refresh - tidak mengubah state jika gagal
    }
  }
}
