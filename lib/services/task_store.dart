import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

/// تخزين المهام محلياً على الجهاز (تبقى محفوظة حتى بعد التحديث).
class TaskStore extends ChangeNotifier {
  static const _key = 'tasks_v1';
  final List<Task> _tasks = [];

  List<Task> get tasks => List.unmodifiable(_tasks);
  int get doneCount => _tasks.where((t) => t.done).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _tasks
          ..clear()
          ..addAll(list.map((e) => Task.fromJson(e as Map<String, dynamic>)));
      } catch (_) {/* بيانات تالفة — نتجاهلها */}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(_tasks.map((t) => t.toJson()).toList()));
  }

  void add(Task t) {
    _tasks.insert(0, t);
    notifyListeners();
    _save();
  }

  void insertAt(int index, Task t) {
    _tasks.insert(index.clamp(0, _tasks.length), t);
    notifyListeners();
    _save();
  }

  void update(Task t) {
    final i = _tasks.indexWhere((x) => x.id == t.id);
    if (i != -1) _tasks[i] = t;
    notifyListeners();
    _save();
  }

  void toggle(String id) {
    final t = _tasks.firstWhere((x) => x.id == id);
    t.done = !t.done;
    notifyListeners();
    _save();
  }

  /// يرجع موقع المهمة المحذوفة (عشان زر "تراجع").
  int remove(String id) {
    final i = _tasks.indexWhere((x) => x.id == id);
    if (i != -1) _tasks.removeAt(i);
    notifyListeners();
    _save();
    return i;
  }

  int clearDone() {
    final before = _tasks.length;
    _tasks.removeWhere((t) => t.done);
    notifyListeners();
    _save();
    return before - _tasks.length;
  }
}
