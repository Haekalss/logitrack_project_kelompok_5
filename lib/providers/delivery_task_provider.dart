import 'package:flutter/material.dart';
import 'package:p1/delivery_task_model.dart';
import 'package:p1/api_service.dart';

enum TaskState { Initial, Loading, Loaded, Error }

class DeliveryTaskProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<DeliveryTask> _tasks = [];
  TaskState _state = TaskState.Initial;
  String _errorMessage = '';

  List<DeliveryTask> get tasks => _tasks;
  TaskState get state => _state;
  String get errorMessage => _errorMessage;

  Future<void> fetchTasks() async {
    _state = TaskState.Loading;
    notifyListeners();

    try {
      _tasks = await _apiService.fetchDeliveryTasks();
      _state = TaskState.Loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = TaskState.Error;
    }

    notifyListeners();
  }
}
