import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/daily_task.dart';
import 'database_info_screen.dart';

class ThirdScreen extends StatefulWidget {
  const ThirdScreen({super.key});

  @override
  State<ThirdScreen> createState() => _ThirdScreenState();
}

class _ThirdScreenState extends State<ThirdScreen> {
  List<DailyTask> _dailyTasks = [];
  List<DailyTask> _filteredTasks = [];
  bool _isLoading = false;
  DateTime _lastSyncTime = DateTime.now();
  int _selectedFilter = -1;
  int _completionFilter = -1;
  bool _isSafeContext = true;

  @override
  void initState() {
    super.initState();
    _loadDailyTasks();
  }

  @override
  void dispose() {
    _isSafeContext = false;
    super.dispose();
  }

  Future<void> _loadDailyTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tasksMap = await DatabaseHelper.instance.getDailyTasks();
      if (mounted) {
        setState(() {
          _dailyTasks = tasksMap.map((map) => DailyTask.fromMap(map)).toList();
          _filterTasks();
          _isLoading = false;
          _lastSyncTime = DateTime.now();
          print('تم تحميل المهام اليومية: ${_dailyTasks.length} مهمة');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('خطأ أثناء تحميل المهام اليومية: $e');
    }
  }

  void _filterTasks() {
    setState(() {
      List<DailyTask> typeFiltered;
      if (_selectedFilter == -1) {
        typeFiltered = List.from(_dailyTasks);
      } else {
        typeFiltered = _dailyTasks
            .where((task) => task.taskType.index == _selectedFilter)
            .toList();
      }

      if (_completionFilter == -1) {
        _filteredTasks = typeFiltered;
      } else if (_completionFilter == 0) {
        _filteredTasks = typeFiltered.where((task) => task.completed).toList();
      } else if (_completionFilter == 1) {
        _filteredTasks = typeFiltered.where((task) => task.inProgress).toList();
      } else if (_completionFilter == 2) {
        _filteredTasks = typeFiltered
            .where((task) => !task.completed && !task.inProgress)
            .toList();
      }
    });
  }

  Future<void> _toggleTaskCompleted(int index) async {
    final task = _filteredTasks[index];
    if (task.id == null) return;

    try {
      // إذا تم تحديد المهمة كمكتملة، فيجب إلغاء حالة "أعمل عليه"
      bool newCompletedValue = !task.completed;
      bool newInProgressValue = task.inProgress;

      if (newCompletedValue && task.inProgress) {
        // إذا تم تحديد المهمة كمكتملة، فلا يمكن أن تكون قيد العمل
        newInProgressValue = false;
      }

      // تحديث حالة الإكمال
      await DatabaseHelper.instance.updateDailyTaskCompleted(
        task.id!,
        newCompletedValue,
      );

      // تحديث حالة "أعمل عليه" إذا لزم الأمر
      if (task.inProgress != newInProgressValue) {
        await DatabaseHelper.instance.updateDailyTaskInProgress(
          task.id!,
          newInProgressValue,
        );
      }

      await _loadDailyTasks();
    } catch (e) {
      print('خطأ أثناء تحديث حالة الإكمال للمهمة: $e');
      if (_isSafeContext && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تحديث حالة المهمة')),
        );
      }
    }
  }

  Future<void> _toggleTaskInProgress(int index) async {
    final task = _filteredTasks[index];
    if (task.id == null) return;

    try {
      // إذا تم تحديد المهمة كقيد العمل، فيجب إلغاء حالة "مكتملة"
      bool newInProgressValue = !task.inProgress;
      bool newCompletedValue = task.completed;

      if (newInProgressValue && task.completed) {
        // إذا تم تحديد المهمة كقيد العمل، فلا يمكن أن تكون مكتملة
        newCompletedValue = false;
      }

      // تحديث حالة "أعمل عليه"
      await DatabaseHelper.instance.updateDailyTaskInProgress(
        task.id!,
        newInProgressValue,
      );

      // تحديث حالة الإكمال إذا لزم الأمر
      if (task.completed != newCompletedValue) {
        await DatabaseHelper.instance.updateDailyTaskCompleted(
          task.id!,
          newCompletedValue,
        );
      }

      await _loadDailyTasks();
    } catch (e) {
      print('خطأ أثناء تحديث حالة التقدم للمهمة: $e');
      if (_isSafeContext && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تحديث حالة المهمة')),
        );
      }
    }
  }

  Future<void> _deleteTask(int index) async {
    final task = _dailyTasks[index];
    if (task.id == null) return;

    try {
      await DatabaseHelper.instance.deleteDailyTask(task.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف المهمة "${task.title}" بنجاح'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      await _loadDailyTasks();
    } catch (e) {
      print('خطأ أثناء حذف المهمة: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ أثناء حذف المهمة'),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    }
  }

  Future<void> _addNewTask() async {
    TextEditingController taskTitleController = TextEditingController();
    int selectedTaskType = 2; // الافتراضي: كلاهما

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة مهمة يومية جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: taskTitleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان المهمة',
                  hintText: 'أدخل عنوان المهمة الجديدة',
                ),
                autofocus: true,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              const Text('نوع المهمة:'),
              RadioListTile<int>(
                title: const Text('دنيوي'),
                value: 0,
                groupValue: selectedTaskType,
                onChanged: (value) {
                  setDialogState(() => selectedTaskType = value!);
                },
                activeColor: Colors.blue,
              ),
              RadioListTile<int>(
                title: const Text('أخروي'),
                value: 1,
                groupValue: selectedTaskType,
                onChanged: (value) {
                  setDialogState(() => selectedTaskType = value!);
                },
                activeColor: Colors.green,
              ),
              RadioListTile<int>(
                title: const Text('دنيوي وأخروي'),
                value: 2,
                groupValue: selectedTaskType,
                onChanged: (value) {
                  setDialogState(() => selectedTaskType = value!);
                },
                activeColor: Colors.purple,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (taskTitleController.text.trim().isNotEmpty) {
                  try {
                    await DatabaseHelper.instance.insertDailyTask({
                      'title': taskTitleController.text.trim(),
                      'task_type': selectedTaskType,
                      'completed': 0,
                      'in_progress': 0,
                    });
                    await _loadDailyTasks();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم إضافة المهمة اليومية بنجاح'),
                        ),
                      );
                    }
                    Navigator.of(context).pop();
                  } catch (e) {
                    print('خطأ أثناء إضافة مهمة جديدة: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('حدث خطأ أثناء إضافة المهمة الجديدة'),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetDailyTasksTable() async {
    bool confirm = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين المهام اليومية'),
        content: const Text(
          'هل أنت متأكد أنك تريد إعادة تعيين جميع المهام اليومية؟ سيتم حذف جميع المهام الحالية غير المؤرشفة وإضافة المهام الافتراضية الجديدة (قراءة القرآن، ممارسة الرياضة، صلة الرحم، وغيرها).',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              confirm = true;
              Navigator.of(context).pop();
            },
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );

    if (confirm) {
      setState(() {
        _isLoading = true;
      });

      try {
        await DatabaseHelper.instance.resetDailyTasksTable();
        await _loadDailyTasks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'تم حذف المهام الحالية وإضافة المهام الافتراضية الجديدة بنجاح.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('خطأ أثناء إعادة تعيين المهام اليومية: $e');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ أثناء إعادة تعيين المهام اليومية'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _archiveTask(int index) async {
    final task = _filteredTasks[index];
    if (task.id == null) return;

    try {
      await DatabaseHelper.instance.archiveDailyTask(task.id!, true);
      if (_isSafeContext && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت أرشفة المهمة بنجاح')),
        );
      }
      await _loadDailyTasks();
    } catch (e) {
      print('خطأ أثناء أرشفة المهمة: $e');
      if (_isSafeContext && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء أرشفة المهمة')),
        );
      }
    }
  }

  Future<void> _archiveDailyTasksSummary() async {
    bool confirm = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أرشفة بيانات المهام اليومية'),
        content: const Text(
          'هل تريد أرشفة بيانات المهام اليومية الحالية؟ سيتم حفظ ملخص للحالة الحالية في أرشيف المهام.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              confirm = true;
              Navigator.of(context).pop();
            },
            child: const Text('أرشفة'),
          ),
        ],
      ),
    );

    if (confirm) {
      setState(() {
        _isLoading = true;
      });

      try {
        int totalTasks = _dailyTasks.length;
        int completedTasks = _dailyTasks.where((task) => task.completed).length;
        int incompleteTasks = totalTasks - completedTasks;
        int inProgressTasks =
            _dailyTasks.where((task) => task.inProgress).length;

        // حساب نسبة المهام قيد الإنجاز من المهام غير المكتملة فقط
        int inProgressPercentage = incompleteTasks > 0
            ? ((inProgressTasks / incompleteTasks) * 100).round()
            : 0;

        // حساب نسبة الإكمال كعدد صحيح
        int completionPercentage =
            totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;

        int worldlyTotal = _dailyTasks
            .where((task) => task.taskType == TaskType.worldly)
            .length;
        int worldlyCompleted = _dailyTasks
            .where(
                (task) => task.taskType == TaskType.worldly && task.completed)
            .length;

        int religiousTotal = _dailyTasks
            .where((task) => task.taskType == TaskType.religious)
            .length;
        int religiousCompleted = _dailyTasks
            .where(
                (task) => task.taskType == TaskType.religious && task.completed)
            .length;

        int bothTotal =
            _dailyTasks.where((task) => task.taskType == TaskType.both).length;
        int bothCompleted = _dailyTasks
            .where((task) => task.taskType == TaskType.both && task.completed)
            .length;

        Map<String, dynamic> archiveData = {
          'date': DateTime.now().toIso8601String().split('T')[0],
          'total_tasks': totalTasks,
          'completed_tasks': completedTasks,
          'in_progress_tasks': inProgressTasks,
          'in_progress_percentage': inProgressPercentage,
          'completion_percentage': completionPercentage,
          'worldly_total': worldlyTotal,
          'worldly_completed': worldlyCompleted,
          'religious_total': religiousTotal,
          'religious_completed': religiousCompleted,
          'both_total': bothTotal,
          'both_completed': bothCompleted,
          'details': _dailyTasks.map((task) => task.title).join(', '),
        };

        await DatabaseHelper.instance.addDailyTasksArchive(archiveData);

        if (_isSafeContext && mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم أرشفة بيانات المهام اليومية بنجاح'),
            ),
          );
        }
      } catch (e) {
        print('خطأ أثناء أرشفة بيانات المهام اليومية: $e');

        if (_isSafeContext && mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ أثناء أرشفة بيانات المهام اليومية'),
            ),
          );
        }
      }
    }
  }

  // دالة لتصفير حالة المهام اليومية (بدون حذفها)
  Future<void> _resetDailyTasksStatus() async {
    bool confirm = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفير حالة المهام اليومية'),
        content: const Text(
          'هل أنت متأكد أنك تريد تصفير حالة جميع المهام اليومية؟ سيتم تعيين جميع المهام إلى حالة غير مكتملة (0) وغير قيد العمل (0) دون حذف المهام نفسها.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              confirm = true;
              Navigator.of(context).pop();
            },
            child: const Text('تصفير الحالة'),
          ),
        ],
      ),
    );

    if (confirm) {
      setState(() {
        _isLoading = true;
      });

      try {
        await DatabaseHelper.instance.resetDailyTasksStatus();
        await _loadDailyTasks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'تم تصفير حالة جميع المهام اليومية بنجاح. أصبحت جميع الصناديق صفر.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('خطأ أثناء تصفير حالة المهام اليومية: $e');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ أثناء تصفير حالة المهام اليومية'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المهام اليومية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exposure_zero),
            onPressed: _resetDailyTasksStatus,
            tooltip: 'تصفير حالة المهام',
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: _resetDailyTasksTable,
            tooltip: 'إعادة تعيين المهام',
          ),
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: _archiveDailyTasksSummary,
            tooltip: 'أرشفة بيانات المهام',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DatabaseInfoScreen(),
                ),
              );
            },
            tooltip: 'معلومات قاعدة البيانات',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTask,
        child: const Icon(Icons.add),
        tooltip: 'إضافة مهمة جديدة',
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadDailyTasks,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterButtons(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredTasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _dailyTasks.isEmpty
                                      ? Icons.playlist_add
                                      : Icons.filter_list_off,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _dailyTasks.isEmpty
                                      ? 'لا توجد مهام يومية. اضغط على زر + لإضافة مهمة جديدة.'
                                      : 'لا توجد مهام تطابق الفلتر المحدد.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                if (!_dailyTasks.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _selectedFilter = -1;
                                          _completionFilter = -1;
                                          _filterTasks();
                                        });
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('إظهار جميع المهام'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredTasks.length,
                            itemBuilder: (context, index) {
                              return _buildTaskItem(index);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCategoriesLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('دنيوي', Colors.blue),
        _buildLegendItem('أخروي', Colors.green),
        _buildLegendItem('دنيوي وأخروي', Colors.purple),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(int index) {
    final task = _filteredTasks[index];
    final Color taskColor = task.taskType.color;
    final backgroundColor = task.inProgress
        ? taskColor.withOpacity(0.3)
        : task.completed
            ? Colors.grey.shade100
            : taskColor.withOpacity(0.1);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: task.inProgress ? taskColor : taskColor.withOpacity(0.5),
          width: task.inProgress ? 2.0 : 1.5,
        ),
      ),
      color: backgroundColor,
      elevation: task.inProgress ? 3 : (task.completed ? 0 : 1),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              width: task.inProgress ? 12 : 8,
              height: 40,
              decoration: BoxDecoration(
                color: task.inProgress ? taskColor : taskColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontWeight: task.inProgress || !task.completed
                      ? FontWeight.bold
                      : FontWeight.normal,
                  decoration:
                      task.completed ? TextDecoration.lineThrough : null,
                  color: task.completed
                      ? Colors.grey
                      : task.inProgress
                          ? Colors.black
                          : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildTaskCheckbox(
              title: 'تم',
              value: task.completed,
              onChanged: (value) => _toggleTaskCompleted(index),
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 8),
            _buildTaskCheckbox(
              title: 'أعمل عليه',
              value: task.inProgress,
              onChanged: (value) => _toggleTaskInProgress(index),
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.archive_outlined,
                  color: Colors.blue, size: 20),
              onPressed: () => _archiveTask(index),
              tooltip: 'أرشفة المهمة',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteTask(index),
              tooltip: 'حذف المهمة',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCheckbox({
    required String title,
    required bool value,
    required Function(bool?) onChanged,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: TextStyle(fontSize: 10, color: color)),
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'عن الأزرار في الأعلى:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• زر اعادة التعيين (٠): يعيد تعيين حالة جميع المهام إلى صفر دون حذفها',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• زر الاسترجاع (↻): يحذف جميع المهام ويضيف المهام الافتراضية',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'تصفية المهام حسب النوع:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFilterButton(
                    label: 'الكل',
                    color: Colors.grey.shade700,
                    isSelected: _selectedFilter == -1,
                    onTap: () {
                      setState(() {
                        _selectedFilter = -1;
                        _filterTasks();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    label: 'دنيوي',
                    color: Colors.blue.shade600,
                    isSelected: _selectedFilter == 0,
                    onTap: () {
                      setState(() {
                        _selectedFilter = 0;
                        _filterTasks();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    label: 'أخروي',
                    color: Colors.green.shade700,
                    isSelected: _selectedFilter == 1,
                    onTap: () {
                      setState(() {
                        _selectedFilter = 1;
                        _filterTasks();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    label: 'مشترك',
                    color: Colors.purple.shade600,
                    isSelected: _selectedFilter == 2,
                    onTap: () {
                      setState(() {
                        _selectedFilter = 2;
                        _filterTasks();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'تصفية المهام حسب الحالة:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFilterButton(
                    label: 'جميع المهام',
                    color: Colors.grey.shade700,
                    isSelected: _completionFilter == -1,
                    onTap: () {
                      setState(() {
                        _completionFilter = -1;
                        _filterTasks();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    label: 'المكتملة',
                    color: Colors.green.shade700,
                    isSelected: _completionFilter == 0,
                    onTap: () {
                      setState(() {
                        _completionFilter = 0;
                        _filterTasks();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    label: 'قيد الإنجاز',
                    color: Colors.orange.shade600,
                    isSelected: _completionFilter == 1,
                    onTap: () {
                      setState(() {
                        _completionFilter = 1;
                        _filterTasks();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    label: 'لم تبدأ بعد',
                    color: Colors.red.shade600,
                    isSelected: _completionFilter == 2,
                    onTap: () {
                      setState(() {
                        _completionFilter = 2;
                        _filterTasks();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildTaskCategoriesLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.4),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
