import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/remote_config.dart';
import '../services/task_store.dart';
import '../services/updater.dart';
import '../widgets/task_editor.dart';
import '../widgets/update_dialog.dart';

enum Filter { all, active, done }

class HomeScreen extends StatefulWidget {
  final TaskStore store;
  final RemoteConfig config;
  const HomeScreen({super.key, required this.store, required this.config});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Filter _filter = Filter.all;
  String _version = '';
  bool _updateDialogOpen = false;

  TaskStore get store => widget.store;
  RemoteConfig get cfg => widget.config;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Updater.currentVersion().then((v) => mounted ? setState(() => _version = v) : null);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// كل ما يرجع المستخدم للتطبيق نفحص الإعدادات والتحديثات من جديد.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      cfg.refresh();
      _checkUpdate();
    }
  }

  Future<void> _checkUpdate({bool manual = false}) async {
    if (_updateDialogOpen) return;
    final r = await Updater.check();
    if (!mounted) return;
    if (r == null) {
      if (manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عندك آخر نسخة ✅')),
        );
      }
      return;
    }
    _updateDialogOpen = true;
    await showUpdateDialog(context, r.info, mandatory: r.mandatory);
    _updateDialogOpen = false;
  }

  Future<void> _refreshAll() async {
    await cfg.refresh();
    await _checkUpdate(manual: true);
  }

  Future<void> _add() async {
    final t = await showTaskEditor(context, config: cfg);
    if (t != null) store.add(t);
  }

  Future<void> _edit(Task task) async {
    final t = await showTaskEditor(context, config: cfg, existing: task);
    if (t != null) store.update(t);
  }

  void _delete(Task task) {
    final index = store.remove(task.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('تم حذف "${task.title}"'),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () => store.insertAt(index, task),
        ),
      ));
  }

  List<Task> get _visible {
    final list = switch (_filter) {
      Filter.all => store.tasks,
      Filter.active => store.tasks.where((t) => !t.done).toList(),
      Filter.done => store.tasks.where((t) => t.done).toList(),
    };
    // غير المنجزة أولاً، ثم حسب الأولوية
    final sorted = [...list]..sort((a, b) {
        if (a.done != b.done) return a.done ? 1 : -1;
        return b.priority.index.compareTo(a.priority.index);
      });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([store, cfg]),
      builder: (context, _) {
        if (cfg.maintenance) return _Maintenance(message: cfg.maintenanceMessage, onRetry: cfg.refresh);
        final tasks = _visible;
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: Text(cfg.appTitle),
            actions: [
              IconButton(
                tooltip: 'تحديث',
                onPressed: _refreshAll,
                icon: const Icon(Icons.sync),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'clear') {
                    final n = store.clearDone();
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم حذف $n مهمة منجزة')));
                  } else if (v == 'about') {
                    showAboutDialog(
                      context: context,
                      applicationName: cfg.appTitle,
                      applicationVersion: _version,
                      children: const [
                        Text('تطبيق مهام يتحدّث عن بعد بدون الحاجة لتحميله من جديد.'),
                      ],
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'clear', child: Text('حذف المنجزة')),
                  PopupMenuItem(value: 'about', child: Text('عن التطبيق')),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('مهمة'),
          ),
          body: RefreshIndicator(
            onRefresh: _refreshAll,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (cfg.announcement != null)
                  SliverToBoxAdapter(
                    child: Card(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      color: scheme.tertiaryContainer,
                      child: ListTile(
                        leading: Icon(Icons.campaign, color: scheme.onTertiaryContainer),
                        title: Text(cfg.announcement!,
                            style: TextStyle(color: scheme.onTertiaryContainer)),
                      ),
                    ),
                  ),
                if (cfg.showStats && store.tasks.isNotEmpty)
                  SliverToBoxAdapter(child: _Stats(store: store)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: SegmentedButton<Filter>(
                      segments: const [
                        ButtonSegment(value: Filter.all, label: Text('الكل')),
                        ButtonSegment(value: Filter.active, label: Text('المتبقية')),
                        ButtonSegment(value: Filter.done, label: Text('المنجزة')),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (s) => setState(() => _filter = s.first),
                    ),
                  ),
                ),
                if (tasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.checklist_rtl, size: 72, color: scheme.outline),
                            const SizedBox(height: 12),
                            Text(cfg.emptyMessage,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 96),
                    sliver: SliverList.builder(
                      itemCount: tasks.length,
                      itemBuilder: (_, i) => _TaskTile(
                        key: ValueKey(tasks[i].id),
                        task: tasks[i],
                        showPriority: cfg.enablePriorities,
                        onToggle: () => store.toggle(tasks[i].id),
                        onTap: () => _edit(tasks[i]),
                        onDelete: () => _delete(tasks[i]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Stats extends StatelessWidget {
  final TaskStore store;
  const _Stats({required this.store});

  @override
  Widget build(BuildContext context) {
    final total = store.tasks.length;
    final done = store.doneCount;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أنجزت $done من $total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : done / total,
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final bool showPriority;
  final VoidCallback onToggle, onTap, onDelete;
  const _TaskTile({
    super.key,
    required this.task,
    required this.showPriority,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prioColor = switch (task.priority) {
      Priority.high => Colors.red,
      Priority.normal => scheme.primary,
      Priority.low => Colors.grey,
    };
    final subtitle = <String>[
      if (task.note.isNotEmpty) task.note,
      if (task.dueDate != null)
        '📅 ${task.dueDate!.year}/${task.dueDate!.month}/${task.dueDate!.day}${task.isOverdue ? ' (متأخرة)' : ''}',
    ].join('\n');

    return Dismissible(
      key: ValueKey('d-${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: scheme.errorContainer,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          onTap: onTap,
          leading: Checkbox(value: task.done, onChanged: (_) => onToggle()),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.done ? TextDecoration.lineThrough : null,
              color: task.done ? scheme.outline : null,
            ),
          ),
          subtitle: subtitle.isEmpty
              ? null
              : Text(subtitle,
                  style: TextStyle(color: task.isOverdue ? scheme.error : null)),
          trailing: showPriority && !task.done
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: prioColor, shape: BoxShape.circle),
                )
              : null,
        ),
      ),
    );
  }
}

class _Maintenance extends StatelessWidget {
  final String message;
  final Future<bool> Function() onRetry;
  const _Maintenance({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 80),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      ),
    );
  }
}
