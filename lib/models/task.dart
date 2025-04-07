class Task {
  final int? id;
  final String title;
  final String description;
  final bool completed;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.completed = false,
  });

  // تحويل من Map إلى Task
  factory Task.fromMap(Map<String, dynamic> map) {
    try {
      print('تحويل Task من Map: $map');
      return Task(
        id: map['id'] as int?,
        title: map['title'] as String? ?? 'مهمة بدون عنوان',
        description: map['description'] as String? ?? '',
        completed: map.containsKey('status')
            ? (map['status'] as int?) == 1
            : map.containsKey('completed')
                ? (map['completed'] as int?) == 1
                : false,
      );
    } catch (e) {
      print('خطأ في تحويل Task من Map: $e');
      print('Map القادم: $map');
      return Task(
        id: map['id'] is int ? map['id'] : null,
        title: map['title'] is String ? map['title'] : 'مهمة بدون عنوان',
        description: map['description'] is String ? map['description'] : '',
        completed: false,
      );
    }
  }

  // تحويل من Task إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': completed ? 1 : 0,
    };
  }

  // إنشاء نسخة جديدة من Task مع تعديل بعض الخصائص
  Task copyWith({
    int? id,
    String? title,
    String? description,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, description: $description, completed: $completed)';
  }
}
