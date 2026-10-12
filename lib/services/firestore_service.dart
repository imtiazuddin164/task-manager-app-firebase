import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasksRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  // CREATE
  Future<void> addTask(TaskModel task) async {
    final doc = _tasksRef(task.userId).doc();

    await doc.set(task.toMap());
  }

  // READ: realtime task stream
  Stream<List<TaskModel>> getTasks(String userId) {
    return _tasksRef(
      userId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TaskModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // UPDATE
  Future<void> updateTask(TaskModel task) async {
    await _tasksRef(task.userId).doc(task.id).update(task.toMap());
  }

  // DELETE
  Future<void> deleteTask({
    required String userId,
    required String taskId,
  }) async {
    await _tasksRef(userId).doc(taskId).delete();
  }

  // MARK COMPLETE / INCOMPLETE
  Future<void> toggleTaskCompletion(TaskModel task) async {
    await _tasksRef(
      task.userId,
    ).doc(task.id).update({'isCompleted': !task.isCompleted});
  }
}
