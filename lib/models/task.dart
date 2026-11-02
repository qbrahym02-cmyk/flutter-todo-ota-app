enum Priority { low, normal, high }

extension PriorityLabel on Priority {
  String get label => switch (this) {
        Priority.low => 'منخفضة',
        Priority.normal => 'عادية',
        Priority.high => 'عالية',
      };
}

class Task {
  final String id;
  String title;
  String note;
  bool done;
  Priority priority;
  DateTime? dueDate;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.note = '',
    this.done = false,
    this.priority = Priority.normal,
    this.dueDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOverdue {
    if (done || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueDate!.isBefore(today);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'done': done,
        'priority': priority.name,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        note: j['note'] as String? ?? '',
        done: j['done'] as bool? ?? false,
        priority: Priority.values.firstWhere(
          (p) => p.name == j['priority'],
          orElse: () => Priority.normal,
        ),
        dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate']) : null,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}
