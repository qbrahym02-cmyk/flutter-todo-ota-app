import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

import '../services/updater.dart';

Future<void> showUpdateDialog(
  BuildContext context,
  UpdateInfo info, {
  required bool mandatory,
}) {
  return showDialog(
    context: context,
    barrierDismissible: !mandatory,
    builder: (_) => PopScope(
      canPop: !mandatory,
      child: _UpdateDialog(info: info, mandatory: mandatory),
    ),
  );
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  final bool mandatory;
  const _UpdateDialog({required this.info, required this.mandatory});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  StreamSubscription<OtaEvent>? _sub;
  double? _progress;
  String? _status;
  bool _busy = false;

  void _start() {
    setState(() {
      _busy = true;
      _progress = 0;
      _status = 'جاري التنزيل...';
    });
    _sub = Updater.download(widget.info).listen((e) {
      setState(() {
        switch (e.status) {
          case OtaStatus.DOWNLOADING:
            _progress = (double.tryParse(e.value ?? '') ?? 0) / 100;
            _status = 'جاري التنزيل ${e.value ?? 0}%';
          case OtaStatus.INSTALLING:
          case OtaStatus.INSTALLATION_DONE:
            _progress = 1;
            _status = 'اضغط "تثبيت" في النافذة اللي ظهرت ✅';
            _busy = false;
          case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
            _status = 'فعّل "السماح بالتثبيت من هذا المصدر" ثم أعد المحاولة';
            _busy = false;
          case OtaStatus.CHECKSUM_ERROR:
            _status = 'الملف تالف (فشل التحقق). أعد المحاولة';
            _busy = false;
          default:
            _status = 'فشل التحديث: ${e.value ?? e.status.name}';
            _busy = false;
        }
      });
    }, onError: (Object err) {
      setState(() {
        _status = 'خطأ: $err';
        _busy = false;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return AlertDialog(
      icon: const Icon(Icons.system_update, size: 40),
      title: Text('تحديث جديد ${info.version}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.mandatory)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('هذا التحديث إجباري لمتابعة استخدام التطبيق.',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          if (info.changelog.isNotEmpty) ...[
            const Text('الجديد:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Flexible(
                child: SingleChildScrollView(child: Text(info.changelog))),
          ],
          if (_progress != null) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
          ],
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
      actions: [
        if (!widget.mandatory)
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('لاحقاً'),
          ),
        FilledButton.icon(
          onPressed: _busy ? null : _start,
          icon: const Icon(Icons.download),
          label: Text(_status == null ? 'حدّث الآن' : 'إعادة المحاولة'),
        ),
      ],
    );
  }
}
