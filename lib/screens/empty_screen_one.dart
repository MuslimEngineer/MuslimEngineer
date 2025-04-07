import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class Idea {
  final int? id;
  final String title;
  final String description;
  final int type; // 0: دنيوية، 1: أخروية، 2: الاثنان معًا
  final DateTime createdAt;
  final bool isArchive;

  Idea({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    this.isArchive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_archive': isArchive ? 1 : 0,
    };
  }

  factory Idea.fromMap(Map<String, dynamic> map) {
    return Idea(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      type: map['type'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      isArchive: map.containsKey('is_archive')
          ? (map['is_archive'] as int) == 1
          : false,
    );
  }
}

class EmptyScreenOne extends StatefulWidget {
  const EmptyScreenOne({Key? key}) : super(key: key);

  @override
  State<EmptyScreenOne> createState() => _EmptyScreenOneState();
}

class _EmptyScreenOneState extends State<EmptyScreenOne> {
  final List<Idea> _ideas = [];
  bool _isLoading = false;
  int _selectedFilter = -1; // -1: الكل، 0: دنيوية، 1: أخروية، 2: الاثنان معًا

  @override
  void initState() {
    super.initState();
    _loadIdeas();
  }

  // دالة لتحميل الأفكار من قاعدة البيانات (غير المؤرشفة فقط)
  Future<void> _loadIdeas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // التأكد من وجود جدول الأفكار
      await _ensureIdeasTableExists();

      // تحميل الأفكار غير المؤرشفة من قاعدة البيانات
      final db = await DatabaseHelper.instance.database;
      final ideas = await db.query(
        'ideas',
        where: 'is_archive = ?',
        whereArgs: [0], // 0 يعني غير مؤرشف
        orderBy: 'created_at DESC',
      );

      setState(() {
        _ideas.clear();
        _ideas.addAll(ideas.map((map) => Idea.fromMap(map)));
        _isLoading = false;
      });
    } catch (e) {
      print('خطأ أثناء تحميل الأفكار: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل الأفكار');
    }
  }

  // التأكد من وجود جدول الأفكار
  Future<void> _ensureIdeasTableExists() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='ideas'");

      if (tables.isEmpty) {
        // إنشاء جدول الأفكار إذا لم يكن موجودًا
        await db.execute('''
          CREATE TABLE ideas(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            type INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            is_archive INTEGER NOT NULL DEFAULT 0
          )
        ''');
        print('تم إنشاء جدول الأفكار بنجاح');
      } else {
        // التحقق من وجود عمود is_archive وإضافته إذا لم يكن موجودًا
        final columns = await db.rawQuery('PRAGMA table_info(ideas)');
        bool hasArchiveColumn = false;
        for (var column in columns) {
          if (column['name'] == 'is_archive') {
            hasArchiveColumn = true;
            break;
          }
        }

        if (!hasArchiveColumn) {
          await db.execute(
              'ALTER TABLE ideas ADD COLUMN is_archive INTEGER NOT NULL DEFAULT 0');
          print('تمت إضافة عمود الأرشفة إلى جدول الأفكار');
        }

        // التحقق من وجود عمود type بدلاً من category
        bool hasTypeColumn = false;
        bool hasCategoryColumn = false;
        for (var column in columns) {
          if (column['name'] == 'type') {
            hasTypeColumn = true;
          }
          if (column['name'] == 'category') {
            hasCategoryColumn = true;
          }
        }

        // إذا كان هناك عمود category ولا يوجد عمود type، قم بنسخ البيانات
        if (hasCategoryColumn && !hasTypeColumn) {
          // إضافة العمود الجديد
          await db.execute('ALTER TABLE ideas ADD COLUMN type INTEGER');

          // نسخ البيانات من category إلى type
          final ideasWithCategory = await db.query('ideas');
          for (var idea in ideasWithCategory) {
            final id = idea['id'];
            String categoryStr = idea['category']?.toString() ?? '2';
            int typeValue = 2; // افتراضي: كلاهما

            // محاولة تحويل النص إلى عدد صحيح
            try {
              typeValue = int.parse(categoryStr);
              if (typeValue < 0 || typeValue > 2) {
                typeValue =
                    2; // إذا كانت القيمة غير صالحة، استخدم القيمة الافتراضية
              }
            } catch (e) {
              // في حالة حدوث خطأ في التحويل، استخدم القيمة الافتراضية
            }

            // تحديث القيمة في قاعدة البيانات
            await db.update(
              'ideas',
              {'type': typeValue},
              where: 'id = ?',
              whereArgs: [id],
            );
          }

          print('تم تحويل البيانات من حقل category إلى حقل type بنجاح');
        }
      }
    } catch (e) {
      print('خطأ أثناء التأكد من وجود جدول الأفكار: $e');
      throw e;
    }
  }

  // إضافة فكرة جديدة
  Future<void> _addIdea(String title, String description, int type) async {
    try {
      final idea = Idea(
        title: title,
        description: description,
        type: type,
        createdAt: DateTime.now(),
      );

      final db = await DatabaseHelper.instance.database;
      await db.insert('ideas', idea.toMap());

      // إعادة تحميل الأفكار بعد الإضافة
      await _loadIdeas();
      _showSuccessSnackBar('تمت إضافة الفكرة بنجاح');
    } catch (e) {
      print('خطأ أثناء إضافة الفكرة: $e');
      _showErrorSnackBar('حدث خطأ أثناء إضافة الفكرة');
    }
  }

  // حذف فكرة
  Future<void> _deleteIdea(int index) async {
    // تأكيد العملية
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text(
                'هل تريد حذف هذه الفكرة؟ لا يمكن التراجع عن هذا الإجراء.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final idea = _ideas[index];
      if (idea.id == null) return;

      final db = await DatabaseHelper.instance.database;

      // حذف الفكرة من قاعدة البيانات مباشرة باستخدام المعرف
      await db.delete('ideas', where: 'id = ?', whereArgs: [idea.id]);

      // إعادة تحميل الأفكار
      await _loadIdeas();
      _showSuccessSnackBar('تم حذف الفكرة بنجاح');
    } catch (e) {
      print('خطأ أثناء حذف الفكرة: $e');
      _showErrorSnackBar('حدث خطأ أثناء حذف الفكرة');
    }
  }

  // أرشفة فكرة
  Future<void> _archiveIdea(int index) async {
    // تأكيد العملية
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الأرشفة'),
            content:
                const Text('هل تريد أرشفة هذه الفكرة؟ ستظهر في صفحة الأرشيف.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('أرشفة'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final idea = _ideas[index];
      if (idea.id == null) return;

      final db = await DatabaseHelper.instance.database;

      // تحديث حالة الأرشفة للفكرة
      await db.update(
        'ideas',
        {'is_archive': 1},
        where: 'id = ?',
        whereArgs: [idea.id],
      );

      // إعادة تحميل الأفكار
      await _loadIdeas();
      _showSuccessSnackBar('تمت أرشفة الفكرة بنجاح');
    } catch (e) {
      print('خطأ أثناء أرشفة الفكرة: $e');
      _showErrorSnackBar('حدث خطأ أثناء أرشفة الفكرة');
    }
  }

  // عرض مربع حوار لإضافة فكرة جديدة
  void _showAddIdeaDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    int selectedType = 2; // الاثنان معًا كقيمة افتراضية

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('إضافة فكرة جديدة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان الفكرة',
                        hintText: 'أدخل عنوان الفكرة',
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'وصف الفكرة',
                        hintText: 'أدخل وصف الفكرة',
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'نوع الفكرة:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    RadioListTile<int>(
                      title: const Text('دنيوية'),
                      value: 0,
                      groupValue: selectedType,
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('أخروية'),
                      value: 1,
                      groupValue: selectedType,
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('الاثنان معًا'),
                      value: 2,
                      groupValue: selectedType,
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final description = descriptionController.text.trim();

                    if (title.isEmpty) {
                      _showErrorSnackBar('يرجى إدخال عنوان للفكرة');
                      return;
                    }

                    Navigator.of(context).pop();
                    _addIdea(title, description, selectedType);
                  },
                  child: const Text('إضافة'),
                ),
              ],
            );
          },
        );
      },
    );
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

  // دالة مساعدة للحصول على لون حسب نوع الفكرة
  Color _getColorByType(int type) {
    switch (type) {
      case 0:
        return Colors.blue; // دنيوية
      case 1:
        return Colors.green; // أخروية
      case 2:
        return Colors.purple; // الاثنان معًا
      default:
        return Colors.grey;
    }
  }

  // دالة مساعدة للحصول على نص حسب نوع الفكرة
  String _getTypeText(int type) {
    switch (type) {
      case 0:
        return 'دنيوية';
      case 1:
        return 'أخروية';
      case 2:
        return 'دنيوية وأخروية';
      default:
        return 'غير محدد';
    }
  }

  // دالة مساعدة للحصول على أيقونة حسب نوع الفكرة
  IconData _getIconByType(int type) {
    switch (type) {
      case 0:
        return Icons.work_outline; // دنيوية
      case 1:
        return Icons.brightness_7; // أخروية
      case 2:
        return Icons.all_inclusive; // الاثنان معًا
      default:
        return Icons.help_outline;
    }
  }

  // عرض فكرة بتفاصيلها
  Widget _buildIdeaItem(int index) {
    final idea = _ideas[index];
    final createdDate = idea.createdAt;
    Color typeColor;
    String typeText;

    // تحديد لون ونص نوع الفكرة
    switch (idea.type) {
      case 0:
        typeColor = Colors.blue;
        typeText = 'دنيوية';
        break;
      case 1:
        typeColor = Colors.green;
        typeText = 'أخروية';
        break;
      default:
        typeColor = Colors.purple;
        typeText = 'دنيوية وأخروية';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              idea.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  idea.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      label: Text(
                        typeText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: typeColor,
                    ),
                    Text(
                      '${createdDate.day}/${createdDate.month}/${createdDate.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.archive_outlined, color: Colors.blue),
                  onPressed: () => _archiveIdea(index),
                  tooltip: 'أرشفة الفكرة',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteIdea(index),
                  tooltip: 'حذف الفكرة',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // تطبيق الفلتر على قائمة الأفكار
    List<Idea> filteredIdeas = _selectedFilter == -1
        ? _ideas
        : _ideas.where((idea) => idea.type == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('بنك الأفكار'),
        actions: [
          // زر الفلترة
          PopupMenuButton<int>(
            tooltip: 'فلترة الأفكار',
            icon: const Icon(Icons.filter_list),
            onSelected: (int value) {
              setState(() {
                _selectedFilter = value == _selectedFilter ? -1 : value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              PopupMenuItem<int>(
                value: -1,
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      color: _selectedFilter == -1
                          ? Colors.grey.shade800
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    const Text('الكل'),
                    if (_selectedFilter == -1)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, size: 18),
                      ),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 0,
                child: Row(
                  children: [
                    Icon(
                      Icons.work_outline,
                      color: _selectedFilter == 0
                          ? Colors.blue
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    const Text('دنيوية'),
                    if (_selectedFilter == 0)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, size: 18, color: Colors.blue),
                      ),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Icon(
                      Icons.brightness_7,
                      color: _selectedFilter == 1
                          ? Colors.green
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    const Text('أخروية'),
                    if (_selectedFilter == 1)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, size: 18, color: Colors.green),
                      ),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 2,
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      color: _selectedFilter == 2
                          ? Colors.purple
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    const Text('الاثنان معًا'),
                    if (_selectedFilter == 2)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child:
                            Icon(Icons.check, size: 18, color: Colors.purple),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // زر لعرض شاشة الأرشيف
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: () {
              Navigator.pushNamed(context, '/archive')
                  .then((_) => _loadIdeas());
            },
            tooltip: 'عرض الأرشيف',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIdeas,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // إظهار شريط الفلترة الحالي
          if (_selectedFilter != -1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: _getColorByType(_selectedFilter).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(_getIconByType(_selectedFilter),
                      color: _getColorByType(_selectedFilter), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'تم الفلترة حسب: ${_getTypeText(_selectedFilter)}',
                    style: TextStyle(
                      color: _getColorByType(_selectedFilter),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedFilter = -1;
                      });
                    },
                    child: Row(
                      children: [
                        Text(
                          'إزالة الفلتر',
                          style: TextStyle(
                            color: _getColorByType(_selectedFilter),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.close,
                          color: _getColorByType(_selectedFilter),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredIdeas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 80,
                              color: Colors.amber.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilter == -1
                                  ? 'لا توجد أفكار حتى الآن'
                                  : 'لا توجد أفكار من هذا النوع',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _showAddIdeaDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة فكرة جديدة'),
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
                        child: ListView.builder(
                          itemCount: filteredIdeas.length,
                          itemBuilder: (context, index) {
                            return _buildIdeaItem(
                                _ideas.indexOf(filteredIdeas[index]));
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddIdeaDialog,
        tooltip: 'إضافة فكرة جديدة',
        child: const Icon(Icons.add),
      ),
    );
  }
}
