import 'package:flutter/material.dart';

// نموذج للمهام اليومية مع تصنيف نوع المهمة
class DailyTask {
  final int? id;
  final String title;
  final bool completed;
  final bool inProgress;
  final TaskType taskType;
  final bool isArchive;

  DailyTask({
    this.id,
    required this.title,
    this.completed = false,
    this.inProgress = false,
    this.taskType = TaskType.both,
    this.isArchive = false,
  });

  // تحويل من Map إلى DailyTask
  factory DailyTask.fromMap(Map<String, dynamic> map) {
    try {
      return DailyTask(
        id: map['id'] as int?,
        title: map['title'] as String? ?? 'مهمة بدون عنوان',
        completed: map.containsKey('completed')
            ? (map['completed'] as int?) == 1
            : false,
        inProgress: map.containsKey('in_progress')
            ? (map['in_progress'] as int?) == 1
            : false,
        taskType: TaskType
            .values[map['task_type'] as int? ?? 2], // الافتراضي هو الاثنين معاً
        isArchive: map.containsKey('is_archive')
            ? (map['is_archive'] as int?) == 1
            : false,
      );
    } catch (e) {
      print('خطأ في تحويل DailyTask من Map: $e');
      print('Map القادم: $map');
      return DailyTask(
        id: map['id'] is int ? map['id'] : null,
        title: map['title'] is String ? map['title'] : 'مهمة بدون عنوان',
        completed: false,
        inProgress: false,
        taskType: TaskType.both,
        isArchive: false,
      );
    }
  }

  // تحويل من DailyTask إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completed': completed ? 1 : 0,
      'in_progress': inProgress ? 1 : 0,
      'task_type': taskType.index,
      'is_archive': isArchive ? 1 : 0,
    };
  }

  // إنشاء نسخة جديدة من DailyTask مع تعديل بعض الخصائص
  DailyTask copyWith({
    int? id,
    String? title,
    bool? completed,
    bool? inProgress,
    TaskType? taskType,
    bool? isArchive,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      inProgress: inProgress ?? this.inProgress,
      taskType: taskType ?? this.taskType,
      isArchive: isArchive ?? this.isArchive,
    );
  }

  @override
  String toString() {
    return 'DailyTask(id: $id, title: $title, completed: $completed, inProgress: $inProgress, taskType: $taskType, isArchive: $isArchive)';
  }
}

// أنواع المهام
enum TaskType {
  worldly, // دنيوي
  religious, // ديني
  both, // الاثنين معا
}

// امتداد لتحويل نوع المهمة إلى نص
extension TaskTypeExtension on TaskType {
  String get arabicName {
    switch (this) {
      case TaskType.worldly:
        return 'دنيوي';
      case TaskType.religious:
        return 'أخروي';
      case TaskType.both:
        return 'دنيوي وأخروي';
    }
  }

  Color get color {
    switch (this) {
      case TaskType.worldly:
        return Colors.blue.shade600;
      case TaskType.religious:
        return Colors.green.shade700;
      case TaskType.both:
        return Colors.purple.shade600;
    }
  }
}
