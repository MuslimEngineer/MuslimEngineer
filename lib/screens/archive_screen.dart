import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/daily_task.dart';

// تعريف فئة Idea مباشرة هنا بدلاً من استيرادها
class ArchivedIdea {
  final int? id;
  final String title;
  final String description;
  final int type; // 0: دنيوية، 1: أخروية، 2: الاثنان معًا
  final DateTime createdAt;
  final bool isArchive;

  ArchivedIdea({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    this.isArchive = true,
  });

  factory ArchivedIdea.fromMap(Map<String, dynamic> map) {
    return ArchivedIdea(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      type: map['type'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      isArchive: map.containsKey('is_archive')
          ? (map['is_archive'] as int) == 1
          : true,
    );
  }
}

// تعريف فئة للخواطر المؤرشفة
class ArchivedThought {
  final int? id;
  final String title;
  final String content;
  final DateTime date;
  final int category; // 0: دنيوي، 1: أخروي، 2: كلاهما
  final bool isArchived;

  ArchivedThought({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.category,
    this.isArchived = true,
  });

  factory ArchivedThought.fromMap(Map<String, dynamic> map) {
    return ArchivedThought(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      date: DateTime.parse(map['date'] as String),
      category: (map['category'] as int?) ?? 0,
      isArchived: (map['is_archived'] as int?) == 1,
    );
  }
}

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({Key? key}) : super(key: key);

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // قوائم للعناصر المؤرشفة
  List<ArchivedIdea> _archivedIdeas = [];
  List<ArchivedThought> _archivedThoughts = [];
  List<DailyTask> _archivedDailyTasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadArchivedItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // تحميل جميع العناصر المؤرشفة من قاعدة البيانات
  Future<void> _loadArchivedItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // تحميل المهام اليومية المؤرشفة
      final archivedDailyTasksMap =
          await DatabaseHelper.instance.getArchivedDailyTasks();
      final archivedDailyTasks =
          archivedDailyTasksMap.map((map) => DailyTask.fromMap(map)).toList();

      // تحميل الأفكار المؤرشفة (مباشرة من جدول ideas)
      final db = await DatabaseHelper.instance.database;
      final archivedIdeasMap = await db.query(
        'ideas',
        where: 'is_archive = ?',
        whereArgs: [1], // 1 يعني مؤرشف
        orderBy: 'created_at DESC',
      );
      final archivedIdeas =
          archivedIdeasMap.map((map) => ArchivedIdea.fromMap(map)).toList();

      // تحميل الخواطر المؤرشفة
      final archivedThoughtsMap =
          await DatabaseHelper.instance.getArchivedThoughts();
      final archivedThoughts = archivedThoughtsMap
          .map((map) => ArchivedThought.fromMap(map))
          .toList();

      setState(() {
        _archivedDailyTasks = archivedDailyTasks;
        _archivedIdeas = archivedIdeas;
        _archivedThoughts = archivedThoughts;
        _isLoading = false;
      });
    } catch (e) {
      print('خطأ في تحميل العناصر المؤرشفة: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل العناصر المؤرشفة');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأرشيف'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'الخواطر'),
            Tab(text: 'الأفكار'),
            Tab(text: 'المهام اليومية'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildThoughtsTab(),
                _buildIdeasTab(),
                _buildDailyTasksTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadArchivedItems,
        tooltip: 'تحديث',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // بناء علامة تبويب الخواطر المؤرشفة
  Widget _buildThoughtsTab() {
    if (_archivedThoughts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد خواطر مؤرشفة حالياً',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // حساب عدد كل فئة من الخواطر
    int worldlyThoughts = 0; // الخواطر الدنيوية
    int afterlifeThoughts = 0; // الخواطر الأخروية
    int bothThoughts = 0; // الخواطر المشتركة

    for (var thought in _archivedThoughts) {
      switch (thought.category) {
        case 0:
          worldlyThoughts++;
          break;
        case 1:
          afterlifeThoughts++;
          break;
        case 2:
          bothThoughts++;
          break;
      }
    }

    // إجمالي عدد الخواطر
    int totalThoughts = _archivedThoughts.length;

    // حساب النسب المئوية
    double worldlyPercentage =
        totalThoughts > 0 ? (worldlyThoughts / totalThoughts) * 100 : 0;
    double afterlifePercentage =
        totalThoughts > 0 ? (afterlifeThoughts / totalThoughts) * 100 : 0;
    double bothPercentage =
        totalThoughts > 0 ? (bothThoughts / totalThoughts) * 100 : 0;

    // قائمة الخواطر الدنيوية
    List<ArchivedThought> worldlyThoughtsList =
        _archivedThoughts.where((thought) => thought.category == 0).toList();

    // قائمة الخواطر الأخروية
    List<ArchivedThought> afterlifeThoughtsList =
        _archivedThoughts.where((thought) => thought.category == 1).toList();

    // قائمة الخواطر المشتركة
    List<ArchivedThought> bothThoughtsList =
        _archivedThoughts.where((thought) => thought.category == 2).toList();

    return Column(
      children: [
        // زر مسح جميع الخواطر المؤرشفة
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: Colors.grey[200],
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            label: const Text(
              'مسح جميع الخواطر المؤرشفة',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _clearArchivedThoughts,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // قسم الملخص
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ملخص الخواطر المؤرشفة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                              worldlyThoughts,
                              worldlyPercentage.toStringAsFixed(1) + '%',
                              'دنيوية',
                              Colors.blue),
                          _buildSummaryItem(
                              afterlifeThoughts,
                              afterlifePercentage.toStringAsFixed(1) + '%',
                              'أخروية',
                              Colors.green),
                          _buildSummaryItem(
                              bothThoughts,
                              bothPercentage.toStringAsFixed(1) + '%',
                              'مشتركة',
                              Colors.purple),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // عنوان الخواطر الدنيوية
              if (worldlyThoughts > 0) ...[
                const SizedBox(height: 16),
                _buildCategoryHeader(
                    'الخواطر الدنيوية', worldlyThoughts, Colors.blue),
                ...worldlyThoughtsList
                    .map((thought) => _buildThoughtCard(thought)),
              ],

              // عنوان الخواطر الأخروية
              if (afterlifeThoughts > 0) ...[
                const SizedBox(height: 16),
                _buildCategoryHeader(
                    'الخواطر الأخروية', afterlifeThoughts, Colors.green),
                ...afterlifeThoughtsList
                    .map((thought) => _buildThoughtCard(thought)),
              ],

              // عنوان الخواطر المشتركة
              if (bothThoughts > 0) ...[
                const SizedBox(height: 16),
                _buildCategoryHeader(
                    'الخواطر المشتركة', bothThoughts, Colors.purple),
                ...bothThoughtsList
                    .map((thought) => _buildThoughtCard(thought)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // بناء بطاقة خاطرة
  Widget _buildThoughtCard(ArchivedThought thought) {
    // تحديد لون ونص التصنيف
    String categoryText = _getThoughtCategoryName(thought.category);
    Color categoryColor = _getThoughtCategoryColor(thought.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              thought.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  thought.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      label: Text(
                        categoryText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: categoryColor,
                    ),
                    Text(
                      _formatDate(thought.date),
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
                  icon: const Icon(Icons.unarchive, color: Colors.blue),
                  tooltip: 'إلغاء الأرشفة',
                  onPressed: () => _confirmUnarchiveThought(thought.id!),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  tooltip: 'حذف نهائي',
                  onPressed: () => _confirmDeleteThought(thought.id!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دالة لمسح الخواطر المؤرشفة
  Future<void> _clearArchivedThoughts() async {
    // تأكيد العملية عبر مربع حوار
    bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('تأكيد المسح'),
              content: const Text(
                'هل أنت متأكد من رغبتك في مسح جميع الخواطر المؤرشفة؟ هذه العملية لا يمكن التراجع عنها.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'مسح الخواطر',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // مسح جميع الخواطر المؤرشفة
      await db.delete(
        DatabaseHelper.thoughtsTable,
        where: 'is_archived = ?',
        whereArgs: [1],
      );

      // إعادة تحميل البيانات
      await _loadArchivedItems();

      _showSuccessSnackBar('تم مسح جميع الخواطر المؤرشفة بنجاح');
    } catch (e) {
      print('خطأ في مسح الخواطر المؤرشفة: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء مسح الخواطر المؤرشفة');
    }
  }

  // تأكيد إلغاء أرشفة خاطرة
  void _confirmUnarchiveThought(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد إلغاء الأرشفة'),
        content: const Text(
            'هل تريد إلغاء أرشفة هذه الخاطرة؟ ستظهر مرة أخرى في سجل الخواطر.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _unarchiveThought(id);
            },
            child: const Text('إلغاء الأرشفة'),
          ),
        ],
      ),
    );
  }

  // تأكيد حذف خاطرة
  void _confirmDeleteThought(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
            'هل تريد حذف هذه الخاطرة نهائياً؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteThought(id);
            },
            child: const Text('حذف نهائياً'),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة للحصول على لون تصنيف الخاطرة
  Color _getThoughtCategoryColor(int category) {
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

  // دالة مساعدة للحصول على اسم تصنيف الخاطرة
  String _getThoughtCategoryName(int category) {
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

  // تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // بناء علامة تبويب الأفكار المؤرشفة
  Widget _buildIdeasTab() {
    if (_archivedIdeas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد أفكار مؤرشفة',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // حساب عدد كل نوع من الأفكار
    int worldlyIdeas = 0; // الأفكار الدنيوية
    int afterlifeIdeas = 0; // الأفكار الأخروية
    int bothIdeas = 0; // الأفكار المشتركة (الاثنان معاً)

    for (var idea in _archivedIdeas) {
      switch (idea.type) {
        case 0:
          worldlyIdeas++;
          break;
        case 1:
          afterlifeIdeas++;
          break;
        default:
          bothIdeas++;
      }
    }

    // إجمالي عدد الأفكار
    int totalIdeas = _archivedIdeas.length;

    // حساب النسب المئوية
    double worldlyPercentage = (worldlyIdeas / totalIdeas) * 100;
    double afterlifePercentage = (afterlifeIdeas / totalIdeas) * 100;
    double bothPercentage = (bothIdeas / totalIdeas) * 100;

    // قائمة الأفكار الدنيوية
    List<ArchivedIdea> worldlyIdeasList =
        _archivedIdeas.where((idea) => idea.type == 0).toList();

    // قائمة الأفكار الأخروية
    List<ArchivedIdea> afterlifeIdeasList =
        _archivedIdeas.where((idea) => idea.type == 1).toList();

    // قائمة الأفكار المشتركة
    List<ArchivedIdea> bothIdeasList =
        _archivedIdeas.where((idea) => idea.type == 2).toList();

    return Column(
      children: [
        // زر مسح جميع الأفكار المؤرشفة
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: Colors.grey[200],
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            label: const Text(
              'مسح جميع الأفكار المؤرشفة',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _clearArchivedIdeas,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // قسم الملخص
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ملخص الأفكار المؤرشفة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                              worldlyIdeas,
                              worldlyPercentage.toStringAsFixed(1) + '%',
                              'دنيوية',
                              Colors.blue),
                          _buildSummaryItem(
                              afterlifeIdeas,
                              afterlifePercentage.toStringAsFixed(1) + '%',
                              'أخروية',
                              Colors.green),
                          _buildSummaryItem(
                              bothIdeas,
                              bothPercentage.toStringAsFixed(1) + '%',
                              'مشتركة',
                              Colors.purple),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // عنوان الأفكار الدنيوية
              if (worldlyIdeas > 0) ...[
                const SizedBox(height: 16),
                _buildCategoryHeader(
                    'الأفكار الدنيوية', worldlyIdeas, Colors.blue),
                ...worldlyIdeasList.map((idea) => _buildIdeaCard(idea)),
              ],

              // عنوان الأفكار الأخروية
              if (afterlifeIdeas > 0) ...[
                const SizedBox(height: 16),
                _buildCategoryHeader(
                    'الأفكار الأخروية', afterlifeIdeas, Colors.green),
                ...afterlifeIdeasList.map((idea) => _buildIdeaCard(idea)),
              ],

              // عنوان الأفكار المشتركة
              if (bothIdeas > 0) ...[
                const SizedBox(height: 16),
                _buildCategoryHeader(
                    'الأفكار المشتركة', bothIdeas, Colors.purple),
                ...bothIdeasList.map((idea) => _buildIdeaCard(idea)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // بناء عنصر ملخص
  Widget _buildSummaryItem(
      int count, String percentage, String label, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                value: double.parse(percentage.replaceAll('%', '')) / 100,
                strokeWidth: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              percentage,
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

  // بناء عنوان فئة
  Widget _buildCategoryHeader(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // بناء بطاقة فكرة
  Widget _buildIdeaCard(ArchivedIdea idea) {
    // تحديد لون ونص نوع الفكرة
    String typeText;
    Color typeColor;

    switch (idea.type) {
      case 0:
        typeText = 'دنيوية';
        typeColor = Colors.blue;
        break;
      case 1:
        typeText = 'أخروية';
        typeColor = Colors.green;
        break;
      default:
        typeText = 'الاثنان معاً';
        typeColor = Colors.purple;
    }

    final createdDate = idea.createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 8, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              idea.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
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
                        style: const TextStyle(
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
                  icon: const Icon(Icons.unarchive, color: Colors.blue),
                  tooltip: 'إلغاء الأرشفة',
                  onPressed: () => _unarchiveIdea(idea.id!),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  tooltip: 'حذف نهائي',
                  onPressed: () => _deleteIdea(idea.id!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دالة لمسح الأفكار المؤرشفة فقط
  Future<void> _clearArchivedIdeas() async {
    // تأكيد العملية عبر مربع حوار
    bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('تأكيد المسح'),
              content: const Text(
                'هل أنت متأكد من رغبتك في مسح جميع الأفكار المؤرشفة؟ هذه العملية لا يمكن التراجع عنها.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'مسح الأفكار',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // مسح جميع الأفكار المؤرشفة
      await db.delete(
        'ideas',
        where: 'is_archive = ?',
        whereArgs: [1],
      );

      // إعادة تحميل البيانات
      await _loadArchivedItems();

      _showSuccessSnackBar('تم مسح جميع الأفكار المؤرشفة بنجاح');
    } catch (e) {
      print('خطأ في مسح الأفكار المؤرشفة: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء مسح الأفكار المؤرشفة');
    }
  }

  // دالة إلغاء أرشفة فكرة
  Future<void> _unarchiveIdea(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // تحديث حالة الأرشفة للفكرة
      await db.update(
        'ideas',
        {'is_archive': 0},
        where: 'id = ?',
        whereArgs: [id],
      );

      // إعادة تحميل العناصر
      await _loadArchivedItems();

      _showSuccessSnackBar('تم إلغاء أرشفة الفكرة بنجاح');
    } catch (e) {
      print('خطأ في إلغاء أرشفة الفكرة: $e');
      _showErrorSnackBar('حدث خطأ أثناء إلغاء أرشفة الفكرة');
    }
  }

  // دالة حذف فكرة نهائي
  Future<void> _deleteIdea(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // حذف الفكرة من قاعدة البيانات
      await db.delete(
        'ideas',
        where: 'id = ?',
        whereArgs: [id],
      );

      // إعادة تحميل العناصر
      await _loadArchivedItems();

      _showSuccessSnackBar('تم حذف الفكرة نهائياً');
    } catch (e) {
      print('خطأ في حذف الفكرة: $e');
      _showErrorSnackBar('حدث خطأ أثناء حذف الفكرة');
    }
  }

  // دالة إلغاء أرشفة خاطرة
  Future<void> _unarchiveThought(int id) async {
    try {
      await DatabaseHelper.instance.archiveThought(id, false);
      await _loadArchivedItems();
      _showSuccessSnackBar('تم إلغاء أرشفة الخاطرة بنجاح');
    } catch (e) {
      print('خطأ في إلغاء أرشفة الخاطرة: $e');
      _showErrorSnackBar('حدث خطأ أثناء إلغاء أرشفة الخاطرة');
    }
  }

  // دالة حذف خاطرة نهائي
  Future<void> _deleteThought(int id) async {
    try {
      await DatabaseHelper.instance.deleteThought(id);
      await _loadArchivedItems();
      _showSuccessSnackBar('تم حذف الخاطرة نهائياً');
    } catch (e) {
      print('خطأ في حذف الخاطرة: $e');
      _showErrorSnackBar('حدث خطأ أثناء حذف الخاطرة');
    }
  }

  // بناء علامة تبويب المهام اليومية المؤرشفة
  Widget _buildDailyTasksTab() {
    if (_archivedDailyTasks.isEmpty) {
      // إذا لم تكن هناك مهام مؤرشفة، نعرض نموذج مثال للمهام المحتملة
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد مهام يومية مؤرشفة حالياً',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أمثلة على المهام اليومية التي يمكن أرشفتها:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildExampleTaskItem('صلة الرحم',
                        'زيارة الأقارب والاطمئنان عليهم', TaskType.religious),
                    const SizedBox(height: 8),
                    _buildExampleTaskItem('تمارين رياضية',
                        'ممارسة الرياضة لمدة 30 دقيقة', TaskType.worldly),
                    const SizedBox(height: 8),
                    _buildExampleTaskItem(
                        'قراءة كتاب', 'قراءة كتاب مفيد يوميًا', TaskType.both),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // حساب عدد كل نوع من المهام اليومية
    int worldlyTasks = 0; // المهام الدنيوية
    int religiousTasks = 0; // المهام الأخروية
    int bothTasks = 0; // المهام المشتركة

    for (var task in _archivedDailyTasks) {
      switch (task.taskType) {
        case TaskType.worldly:
          worldlyTasks++;
          break;
        case TaskType.religious:
          religiousTasks++;
          break;
        case TaskType.both:
          bothTasks++;
          break;
      }
    }

    // إجمالي عدد المهام
    int totalTasks = _archivedDailyTasks.length;

    // حساب النسب المئوية
    double worldlyPercentage =
        totalTasks > 0 ? (worldlyTasks / totalTasks) * 100 : 0;
    double religiousPercentage =
        totalTasks > 0 ? (religiousTasks / totalTasks) * 100 : 0;
    double bothPercentage = totalTasks > 0 ? (bothTasks / totalTasks) * 100 : 0;

    return Column(
      children: [
        // زر مسح جميع المهام اليومية المؤرشفة
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: Colors.grey[200],
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            label: const Text(
              'مسح جميع المهام اليومية المؤرشفة',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _clearArchivedDailyTasks,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // قسم الملخص
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ملخص المهام اليومية المؤرشفة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                              worldlyTasks,
                              worldlyPercentage.toStringAsFixed(1) + '%',
                              'دنيوية',
                              Colors.blue),
                          _buildSummaryItem(
                              religiousTasks,
                              religiousPercentage.toStringAsFixed(1) + '%',
                              'أخروية',
                              Colors.green),
                          _buildSummaryItem(
                              bothTasks,
                              bothPercentage.toStringAsFixed(1) + '%',
                              'مشتركة',
                              Colors.purple),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // قائمة المهام اليومية
              ...List.generate(_archivedDailyTasks.length, (index) {
                final task = _archivedDailyTasks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: task.taskType.color.withOpacity(0.2),
                      child: Icon(
                        task.completed
                            ? Icons.check_circle
                            : task.inProgress
                                ? Icons.timelapse
                                : Icons.circle_outlined,
                        color: task.taskType.color,
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration:
                            task.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      'النوع: ${task.taskType.arabicName}',
                      style: TextStyle(color: task.taskType.color),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.unarchive, color: Colors.blue),
                          tooltip: 'إلغاء الأرشفة',
                          onPressed: () => _unarchiveDailyTask(task.id!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.red),
                          tooltip: 'حذف نهائي',
                          onPressed: () => _deleteDailyTask(task.id!),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // بناء عنصر مهمة كمثال
  Widget _buildExampleTaskItem(
      String title, String description, TaskType type) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: type.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                type == TaskType.religious
                    ? Icons.favorite
                    : type == TaskType.worldly
                        ? Icons.sports_gymnastics
                        : Icons.menu_book,
                color: type.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: type.color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: type.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type.arabicName,
                  style: TextStyle(
                    fontSize: 12,
                    color: type.color,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 28),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // دالة لمسح المهام اليومية المؤرشفة فقط
  Future<void> _clearArchivedDailyTasks() async {
    // تأكيد العملية عبر مربع حوار
    bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('تأكيد المسح'),
              content: const Text(
                'هل أنت متأكد من رغبتك في مسح جميع المهام اليومية المؤرشفة؟ هذه العملية لا يمكن التراجع عنها.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'مسح المهام اليومية',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // مسح جميع المهام اليومية المؤرشفة
      await db.delete(
        'daily_tasks',
        where: 'is_archived = ?',
        whereArgs: [1],
      );

      // إعادة تحميل البيانات
      await _loadArchivedItems();

      _showSuccessSnackBar('تم مسح جميع المهام اليومية المؤرشفة بنجاح');
    } catch (e) {
      print('خطأ في مسح المهام اليومية المؤرشفة: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء مسح المهام اليومية المؤرشفة');
    }
  }

  // إلغاء أرشفة مهمة يومية
  Future<void> _unarchiveDailyTask(int id) async {
    try {
      await DatabaseHelper.instance.archiveDailyTask(id, false);
      await _loadArchivedItems();
      _showSuccessSnackBar('تم إلغاء أرشفة المهمة اليومية بنجاح');
    } catch (e) {
      print('خطأ في إلغاء أرشفة المهمة اليومية: $e');
      _showErrorSnackBar('حدث خطأ أثناء إلغاء أرشفة المهمة اليومية');
    }
  }

  // حذف مهمة يومية نهائياً
  Future<void> _deleteDailyTask(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'daily_tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
      await _loadArchivedItems();
      _showSuccessSnackBar('تم حذف المهمة اليومية نهائياً');
    } catch (e) {
      print('خطأ في حذف المهمة اليومية: $e');
      _showErrorSnackBar('حدث خطأ أثناء حذف المهمة اليومية');
    }
  }
}
