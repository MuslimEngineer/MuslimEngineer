import 'package:flutter/material.dart';
import 'dart:async';
import '../database/database_helper.dart';

// تعريف كلاس للخواطر
class Thought {
  final int? id;
  final String title;
  final DateTime date;
  final int category; // 0: دنيوي، 1: أخروي، 2: كلاهما
  final bool isArchived;

  Thought({
    this.id,
    required this.title,
    required this.date,
    required this.category,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': '', // manteniendo para compatibilidad con BD existente
      'date': date.toIso8601String(),
      'category': category,
      'is_archived': isArchived ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory Thought.fromMap(Map<String, dynamic> map) {
    return Thought(
      id: map['id'] as int?,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      category: (map['category'] as int?) ?? 0,
      isArchived: (map['is_archived'] as int?) == 1,
    );
  }
}

class ThoughtsJournalScreen extends StatefulWidget {
  const ThoughtsJournalScreen({super.key});

  @override
  State<ThoughtsJournalScreen> createState() => _ThoughtsJournalScreenState();
}

class _ThoughtsJournalScreenState extends State<ThoughtsJournalScreen> {
  List<Thought> _thoughts = [];
  bool _isLoading = false;
  bool _isSafeContext = true;

  @override
  void initState() {
    super.initState();
    _loadThoughts();
  }

  @override
  void dispose() {
    _isSafeContext = false;
    super.dispose();
  }

  // تحميل الخواطر من قاعدة البيانات
  Future<void> _loadThoughts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> thoughtsMaps =
          await DatabaseHelper.instance.getAllThoughts();

      final thoughts = thoughtsMaps.map((map) => Thought.fromMap(map)).toList();

      if (mounted) {
        setState(() {
          _thoughts = thoughts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('خطأ في تحميل الخواطر: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('حدث خطأ أثناء تحميل الخواطر: $e');
      }
    }
  }

  // حفظ خاطرة جديدة
  Future<void> _saveThought(String title, int category) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // تجهيز بيانات الخاطرة
      final now = DateTime.now();
      Thought thought = Thought(
        title: title,
        date: now,
        category: category,
      );

      // حفظ الخاطرة في قاعدة البيانات
      await DatabaseHelper.instance.insertThought(thought.toMap());

      // إعادة تحميل الخواطر بعد الإضافة
      await _loadThoughts();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showSuccessSnackBar('تم حفظ الخاطرة بنجاح');
      }
    } catch (e) {
      print('خطأ في حفظ الخاطرة: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showErrorSnackBar('حدث خطأ أثناء حفظ الخاطرة: $e');
      }
    }
  }

  // أرشفة خاطرة
  Future<void> _archiveThought(int id) async {
    _showArchiveConfirmation(id);
  }

  // عرض تأكيد الأرشفة
  void _showArchiveConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الأرشفة'),
        content: const Text('هل أنت متأكد من أرشفة هذه الخاطرة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performArchiveThought(id);
            },
            child: const Text('أرشفة'),
            style: TextButton.styleFrom(foregroundColor: Colors.amber),
          ),
        ],
      ),
    );
  }

  // تنفيذ أرشفة الخاطرة
  Future<void> _performArchiveThought(int id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DatabaseHelper.instance.archiveThought(id);
      await _loadThoughts();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showSuccessSnackBar('تم أرشفة الخاطرة بنجاح');
      }
    } catch (e) {
      print('خطأ في أرشفة الخاطرة: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _showErrorSnackBar('حدث خطأ أثناء أرشفة الخاطرة: $e');
      }
    }
  }

  // حذف خاطرة
  Future<void> _deleteThought(int id) async {
    try {
      await DatabaseHelper.instance.deleteThought(id);
      await _loadThoughts();

      if (_isSafeContext && mounted) {
        _showSuccessSnackBar('تم حذف الخاطرة بنجاح');
      }
    } catch (e) {
      print('خطأ في حذف الخاطرة: $e');
      if (_isSafeContext && mounted) {
        _showErrorSnackBar('حدث خطأ أثناء حذف الخاطرة: $e');
      }
    }
  }

  // الحصول على اسم التصنيف
  String _getCategoryName(int category) {
    switch (category) {
      case 0:
        return 'دنيوي';
      case 1:
        return 'أخروي';
      case 2:
        return 'دنيوي وأخروي';
      default:
        return 'غير محدد';
    }
  }

  // الحصول على لون التصنيف
  Color _getCategoryColor(int category) {
    switch (category) {
      case 0:
        return Colors.blue.shade600; // دنيوي
      case 1:
        return Colors.green.shade700; // أخروي
      case 2:
        return Colors.purple.shade600; // كلاهما
      default:
        return Colors.grey;
    }
  }

  // الحصول على أيقونة التصنيف
  IconData _getCategoryIcon(int category) {
    switch (category) {
      case 0:
        return Icons.work_outline; // دنيوي
      case 1:
        return Icons.brightness_7; // أخروي
      case 2:
        return Icons.all_inclusive; // كلاهما
      default:
        return Icons.help_outline;
    }
  }

  // عرض نافذة إضافة خاطرة جديدة
  void _showAddThoughtDialog() {
    final titleController = TextEditingController();
    int selectedCategory = 0; // دنيوي كقيمة افتراضية

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة خاطرة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'الخاطرة',
                    hintText: 'أدخل الخاطرة هنا',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 200,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text('تصنيف الخاطرة:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<int>(
                  title: const Text('دنيوي'),
                  value: 0,
                  groupValue: selectedCategory,
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value!);
                  },
                  activeColor: Colors.blue,
                ),
                RadioListTile<int>(
                  title: const Text('أخروي'),
                  value: 1,
                  groupValue: selectedCategory,
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value!);
                  },
                  activeColor: Colors.green,
                ),
                RadioListTile<int>(
                  title: const Text('دنيوي وأخروي'),
                  value: 2,
                  groupValue: selectedCategory,
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value!);
                  },
                  activeColor: Colors.purple,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                final title = titleController.text.trim();

                if (title.isEmpty) {
                  Navigator.pop(context);
                  _showErrorSnackBar('يرجى إدخال نص الخاطرة');
                  return;
                }

                Navigator.pop(context);
                _saveThought(title, selectedCategory);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  // عرض تفاصيل الخاطرة
  void _showThoughtDetails(Thought thought) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getCategoryIcon(thought.category),
              color: _getCategoryColor(thought.category),
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(thought.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'تاريخ الإنشاء: ${_formatDate(thought.date)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'التصنيف: ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          _getCategoryColor(thought.category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getCategoryName(thought.category),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCategoryColor(thought.category),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditThoughtDialog(thought);
            },
            child: const Text('تعديل'),
          ),
        ],
      ),
    );
  }

  // عرض نافذة تعديل الخاطرة
  void _showEditThoughtDialog(Thought thought) {
    final editTitleController = TextEditingController(text: thought.title);
    int editCategory = thought.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل الخاطرة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: editTitleController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال عنوان';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('تصنيف الخاطرة:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<int>(
                  title: const Text('دنيوي'),
                  value: 0,
                  groupValue: editCategory,
                  onChanged: (value) {
                    setDialogState(() => editCategory = value!);
                  },
                  activeColor: Colors.blue,
                ),
                RadioListTile<int>(
                  title: const Text('أخروي'),
                  value: 1,
                  groupValue: editCategory,
                  onChanged: (value) {
                    setDialogState(() => editCategory = value!);
                  },
                  activeColor: Colors.green,
                ),
                RadioListTile<int>(
                  title: const Text('دنيوي وأخروي'),
                  value: 2,
                  groupValue: editCategory,
                  onChanged: (value) {
                    setDialogState(() => editCategory = value!);
                  },
                  activeColor: Colors.purple,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                if (editTitleController.text.trim().isEmpty) {
                  Navigator.pop(context);
                  _showErrorSnackBar('يرجى إدخال عنوان للخاطرة');
                  return;
                }

                final updatedThought = Thought(
                  id: thought.id,
                  title: editTitleController.text.trim(),
                  date: thought.date,
                  category: editCategory,
                  isArchived: thought.isArchived,
                );

                try {
                  await DatabaseHelper.instance
                      .updateThought(updatedThought.toMap());
                  await _loadThoughts();

                  Navigator.pop(context);

                  if (_isSafeContext && mounted) {
                    _showSuccessSnackBar('تم تحديث الخاطرة بنجاح');
                  }
                } catch (e) {
                  if (_isSafeContext && mounted) {
                    _showErrorSnackBar('حدث خطأ أثناء تحديث الخاطرة: $e');
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  // تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // عرض رسالة خطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // عرض رسالة نجاح
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // بناء بطاقة خاطرة
  Widget _buildThoughtItem(Thought thought) {
    final categoryColor = _getCategoryColor(thought.category);
    final categoryText = _getCategoryName(thought.category);
    final categoryIcon = _getCategoryIcon(thought.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: categoryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(categoryIcon, color: categoryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    thought.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: categoryColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    categoryText,
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(thought.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () => _showThoughtDetails(thought),
                          tooltip: 'عرض الخاطرة',
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green),
                          onPressed: () => _showEditThoughtDialog(thought),
                          tooltip: 'تعديل الخاطرة',
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.archive_outlined,
                              color: Colors.amber),
                          onPressed: () => _archiveThought(thought.id!),
                          tooltip: 'أرشفة الخاطرة',
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(thought.id!),
                          tooltip: 'حذف الخاطرة',
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // عرض تأكيد الحذف
  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الخاطرة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteThought(id);
            },
            child: const Text('حذف'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // تصنيف الخواطر حسب النوع
    int worldlyCount = _thoughts.where((t) => t.category == 0).length;
    int religiousCount = _thoughts.where((t) => t.category == 1).length;
    int bothCount = _thoughts.where((t) => t.category == 2).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الخواطر'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: () {
              Navigator.pushNamed(context, '/archive')
                  .then((_) => _loadThoughts());
            },
            tooltip: 'الأرشيف',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadThoughts,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _thoughts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 80,
                        color: Colors.indigo.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'لا توجد خواطر مسجلة حتى الآن',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddThoughtDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة خاطرة جديدة'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // ملخص تصنيف الخواطر
                      if (_thoughts.isNotEmpty)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.grey[100],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ملخص الخواطر',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildCategorySummary(
                                        worldlyCount,
                                        _thoughts.length > 0
                                            ? (worldlyCount /
                                                    _thoughts.length) *
                                                100
                                            : 0,
                                        'دنيوي',
                                        Colors.blue),
                                    _buildCategorySummary(
                                        religiousCount,
                                        _thoughts.length > 0
                                            ? (religiousCount /
                                                    _thoughts.length) *
                                                100
                                            : 0,
                                        'أخروي',
                                        Colors.green),
                                    _buildCategorySummary(
                                        bothCount,
                                        _thoughts.length > 0
                                            ? (bothCount / _thoughts.length) *
                                                100
                                            : 0,
                                        'مشترك',
                                        Colors.purple),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // قائمة الخواطر
                      Expanded(
                        child: ListView.builder(
                          itemCount: _thoughts.length,
                          itemBuilder: (context, index) {
                            return _buildThoughtItem(_thoughts[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddThoughtDialog,
        tooltip: 'إضافة خاطرة جديدة',
        child: const Icon(Icons.add),
      ),
    );
  }

  // بناء ملخص للتصنيف
  Widget _buildCategorySummary(
      int count, double percentage, String label, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$label ($count)',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
