import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_constants.dart';

/// إعدادات تتحكم فيها من السيرفر (config.json).
/// أي تعديل على الملف يظهر عند المستخدمين فوراً — بدون أي تحميل أو تثبيت.
class RemoteConfig extends ChangeNotifier {
  static const _cacheKey = 'remote_config_cache';

  String appTitle = 'مهامي';
  Color seedColor = const Color(0xFF6750A4);
  String? announcement;
  bool maintenance = false;
  String maintenanceMessage = 'التطبيق تحت الصيانة، ارجع بعد شوي 🙏';
  bool showStats = true;
  bool enablePriorities = true;
  bool enableDueDates = true;
  List<String> quickTasks = const [];
  String emptyMessage = 'ما عندك مهام. أضف أول مهمة! ✨';

  Future<void> init() async {
    // 1) نحمّل آخر نسخة محفوظة (يشتغل بدون إنترنت)
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) _apply(cached);
    // 2) نجيب الجديد من السيرفر بالخلفية
    refresh();
  }

  Future<bool> refresh() async {
    try {
      // نضيف timestamp عشان نتجاوز الكاش
      final uri = Uri.parse(
          '$kConfigUrl?t=${DateTime.now().millisecondsSinceEpoch}');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = utf8.decode(res.bodyBytes);
        _apply(body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, body);
        return true;
      }
    } catch (e) {
      debugPrint('RemoteConfig: $e');
    }
    return false;
  }

  void _apply(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      appTitle = j['app_title'] as String? ?? appTitle;
      seedColor = _parseColor(j['theme_color'] as String?) ?? seedColor;
      announcement = (j['announcement'] as String?)?.trim();
      if (announcement?.isEmpty ?? false) announcement = null;
      maintenance = j['maintenance'] as bool? ?? false;
      maintenanceMessage =
          j['maintenance_message'] as String? ?? maintenanceMessage;
      final f = (j['features'] as Map<String, dynamic>?) ?? const {};
      showStats = f['show_stats'] as bool? ?? showStats;
      enablePriorities = f['priorities'] as bool? ?? enablePriorities;
      enableDueDates = f['due_dates'] as bool? ?? enableDueDates;
      quickTasks =
          (j['quick_tasks'] as List?)?.map((e) => e.toString()).toList() ??
              quickTasks;
      emptyMessage = j['empty_message'] as String? ?? emptyMessage;
      notifyListeners();
    } catch (e) {
      debugPrint('RemoteConfig parse error: $e');
    }
  }

  static Color? _parseColor(String? hex) {
    if (hex == null) return null;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }
}
