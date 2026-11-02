import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_constants.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String apkUrl;
  final String? sha256;
  final String changelog;
  final bool force;
  final int minSupportedBuild;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    this.sha256,
    this.changelog = '',
    this.force = false,
    this.minSupportedBuild = 0,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> j) => UpdateInfo(
        version: j['version'] as String? ?? '',
        buildNumber: (j['build_number'] as num?)?.toInt() ?? 0,
        apkUrl: j['apk_url'] as String? ?? '',
        sha256: j['sha256'] as String?,
        changelog: j['changelog'] as String? ?? '',
        force: j['force'] as bool? ?? false,
        minSupportedBuild: (j['min_supported_build'] as num?)?.toInt() ?? 0,
      );
}

/// يفحص update.json على السيرفر، ولو فيه نسخة أحدث ينزّلها داخل التطبيق
/// ويفتح شاشة التثبيت مباشرة (بدون متجر وبدون تحميل يدوي).
class Updater {
  static Future<({UpdateInfo info, bool mandatory})?> check() async {
    // على الويب ما نحتاج — الويب يتحدّث تلقائياً من السيرفر
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final pkg = await PackageInfo.fromPlatform();
      final current = int.tryParse(pkg.buildNumber) ?? 0;
      final res = await http
          .get(Uri.parse('$kUpdateUrl?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final info = UpdateInfo.fromJson(
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
      if (info.apkUrl.isEmpty || info.buildNumber <= current) return null;
      final mandatory = info.force || current < info.minSupportedBuild;
      return (info: info, mandatory: mandatory);
    } catch (e) {
      debugPrint('Updater: $e');
      return null;
    }
  }

  static Stream<OtaEvent> download(UpdateInfo info) {
    return OtaUpdate().execute(
      info.apkUrl,
      destinationFilename: 'todo_update.apk',
      sha256checksum: (info.sha256?.isNotEmpty ?? false) ? info.sha256 : null,
    );
  }

  static Future<String> currentVersion() async {
    final p = await PackageInfo.fromPlatform();
    return '${p.version} (${p.buildNumber})';
  }
}
