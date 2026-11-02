import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_ota/main.dart';
import 'package:todo_ota/models/task.dart';
import 'package:todo_ota/services/remote_config.dart';
import 'package:todo_ota/services/task_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Task JSON round-trip', () {
    final t = Task(id: '1', title: 'اختبار', priority: Priority.high, dueDate: DateTime(2026, 1, 1));
    final back = Task.fromJson(t.toJson());
    expect(back.title, 'اختبار');
    expect(back.priority, Priority.high);
    expect(back.isOverdue, isTrue);
  });

  testWidgets('add, complete and delete a task', (tester) async {
    final store = TaskStore();
    await store.load();
    final config = RemoteConfig(); // بدون init → لا طلبات شبكة
    await tester.pumpWidget(TodoApp(store: store, config: config));
    await tester.pumpAndSettle();

    expect(find.textContaining('ما عندك مهام'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'شراء خبز');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    expect(find.text('شراء خبز'), findsOneWidget);
    expect(store.tasks.length, 1);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(store.tasks.first.done, isTrue);
    expect(find.text('أنجزت 1 من 1'), findsOneWidget);

    await tester.drag(find.text('شراء خبز'), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(store.tasks, isEmpty);
  });
}
