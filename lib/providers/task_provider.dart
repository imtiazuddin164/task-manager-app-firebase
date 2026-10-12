import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/task_model.dart';
import '../services/firestore_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Stream<List<TaskModel>> getTasks(String userId) {
    return _service.getTasks(userId);
  }

  Future<bool> addTask(TaskModel task) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _service.addTask(task);
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateTask(TaskModel task) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _service.updateTask(task);
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteTask({
    required String userId,
    required String taskId,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _service.deleteTask(userId: userId, taskId: taskId);
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleCompletion(TaskModel task) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _service.toggleTaskCompletion(task);
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String _friendlyError(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Access denied. Check your Firestore rules.';
      }

      if (error.code == 'unavailable') {
        return 'Network unavailable. Please try again.';
      }
    }

    return 'Could not complete the task operation.';
  }
}
