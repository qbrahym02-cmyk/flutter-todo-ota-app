import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/remote_config.dart';

/// نافذة سفلية لإضافة/تعديل مهمة. ترجع المهمة أو null.
Future<Task?> showTaskEditor(
  BuildContext context, {
  required RemoteConfig config,
  Task? existing,
}) {
  return showModalBottomSheet<Task>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TaskEditor(config: config, existing: existing),
  );
}

class _TaskEditor extends StatefulWidget {
  final RemoteConfig config;
  final Task? existing;
  const _TaskEditor({required this.config, this.existing});

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _note = TextEditingController(text: widget.existing?.note);
  late Priority _priority = widget.existing?.priority ?? Priority.normal;
  late DateTime? _due = widget.existing?.dueDate;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final e = widget.existing;
    Navigator.pop(
      context,
      Task(
        id: e?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        note: _note.text.trim(),
        done: e?.done ?? false,
        priority: _priority,
        dueDate: _due,
        createdAt: e?.createdAt,
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (d != null) setState(() => _due = d);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isEdit ? 'تعديل المهمة' : 'مهمة جديدة',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'عنوان المهمة',
              border: OutlineInputBorder(),
            ),
          ),
          if (!isEdit && cfg.quickTasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: cfg.quickTasks
                  .map((q) => ActionChip(
                        label: Text(q),
                        onPressed: () => setState(() => _title.text = q),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ملاحظة (اختياري)',
              border: OutlineInputBorder(),
            ),
          ),
          if (cfg.enablePriorities) ...[
            const SizedBox(height: 12),
            SegmentedButton<Priority>(
              segments: Priority.values
                  .map((p) => ButtonSegment(value: p, label: Text(p.label)))
                  .toList(),
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
          ],
          if (cfg.enableDueDates) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: Text(_due == null
                      ? 'إضافة تاريخ استحقاق'
                      : '${_due!.year}/${_due!.month}/${_due!.day}'),
                ),
                if (_due != null)
                  IconButton(
                    tooltip: 'إزالة التاريخ',
                    onPressed: () => setState(() => _due = null),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submit,
            child: Text(isEdit ? 'حفظ' : 'إضافة'),
          ),
        ],
      ),
    );
  }
}
