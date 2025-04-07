import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'dart:async';
import 'database_admin_screen.dart';

class DatabaseInfoScreen extends StatefulWidget {
  const DatabaseInfoScreen({super.key});

  @override
  State<DatabaseInfoScreen> createState() => _DatabaseInfoScreenState();
}

class _DatabaseInfoScreenState extends State<DatabaseInfoScreen>
    with SingleTickerProviderStateMixin {
  String _dbPath = '';
  bool _dbExists = false;
  String _dbSize = '';
  String _dbLastModified = '';
  bool _isLoading = false;
  DateTime _lastSyncTime = DateTime.now();

  // أرشيف العبادات
  List<Map<String, dynamic>> _worshipArchive = [];

  // أرشيف الأهداف اليومية
  List<Map<String, dynamic>> _dailyTasksArchive = [];

  // المواقع
  List<Map<String, dynamic>> _locations = [];
  Map<String, dynamic>? _defaultLocation;

  // متغيرات لعرض القوائم والتبويبات
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInfo();
    _loadArchiveData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    if (_isLoading) return; // منع تحميل متزامن

    setState(() {
      _isLoading = true;
    });

    try {
      // معلومات قاعدة البيانات
      final dbInfo = await DatabaseHelper.instance.getDatabaseInfo();
      final dbPath = dbInfo['location'] as String;
      final dbExists = dbInfo['exists'] as bool;
      final dbSize = dbInfo['size'] as String;
      final dbLastModified = dbInfo['lastModified'] as String;

      if (mounted) {
        setState(() {
          _dbPath = dbPath;
          _dbExists = dbExists;
          _dbSize = dbSize;
          _dbLastModified = dbLastModified;
          _lastSyncTime = DateTime.now();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('خطأ أثناء تحميل المعلومات: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadArchiveData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // تحميل أرشيف العبادات
      final worshipArchive = await DatabaseHelper.instance.getWorshipArchive();

      // تحميل أرشيف الأهداف اليومية
      final dailyTasksArchive =
          await DatabaseHelper.instance.getDailyTasksArchive();

      // تحميل المواقع
      final locations = await DatabaseHelper.instance.getDefaultCities();
      final defaultLocation =
          await DatabaseHelper.instance.getDefaultLocation();

      if (mounted) {
        setState(() {
          _worshipArchive = worshipArchive;
          _dailyTasksArchive = dailyTasksArchive;
          _locations = locations;
          _defaultLocation = defaultLocation;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('خطأ أثناء تحميل بيانات الأرشيف: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة قاعدة البيانات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            tooltip: 'إدارة كاملة لقاعدة البيانات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DatabaseAdminScreen(),
                ),
              ).then((_) {
                // إعادة تحميل البيانات عند العودة من شاشة الإدارة
                _loadInfo();
                _loadArchiveData();
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'معلومات عامة'),
            Tab(text: 'أرشيف العبادات'),
            Tab(text: 'أرشيف المهام'),
            Tab(text: 'المواقع الجغرافية'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildGeneralInfoTab(),
              _buildWorshipArchiveTab(),
              _buildTasksArchiveTab(),
              _buildLocationsTab(),
            ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // إذا كانت علامة التبويب الحالية هي علامة إدارة المواقع (الفهرس 3)، عرض نافذة إضافة موقع جديد
          if (_tabController.index == 3) {
            _showAddLocationDialog();
          } else {
            setState(() {
              _isLoading = true;
            });

            await _loadInfo();
            await _loadArchiveData();

            setState(() {
              _isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
            );
          }
        },
        child: Icon(
            _tabController.index == 3 ? Icons.add_location : Icons.refresh),
        tooltip:
            _tabController.index == 3 ? 'إضافة موقع جديد' : 'تحديث البيانات',
      ),
    );
  }

  // علامة التبويب الأولى: معلومات عامة
  Widget _buildGeneralInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSyncStatusCard(),
          const SizedBox(height: 10),
          _buildSectionTitle('معلومات قاعدة البيانات'),
          _buildInfoCard('مسار قاعدة البيانات', _dbPath),
          _buildInfoCard(
              'حالة قاعدة البيانات', _dbExists ? 'موجودة' : 'غير موجودة'),
          _buildInfoCard('حجم قاعدة البيانات', _dbSize),
          _buildInfoCard('آخر تعديل', _dbLastModified),
          const SizedBox(height: 20),
          _buildSectionTitle('إحصائيات قاعدة البيانات'),
          _buildStatisticsCard(),
        ],
      ),
    );
  }

  // علامة التبويب الثانية: أرشيف العبادات
  Widget _buildWorshipArchiveTab() {
    if (_worshipArchive.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد بيانات محفوظة في أرشيف العبادات',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _worshipArchive.length,
      itemBuilder: (context, index) {
        final archive = _worshipArchive[index];
        int completionRate = archive['completion_rate'] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تاريخ: ${archive['date'] ?? 'غير محدد'}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'الإتمام: $completionRate%',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('الفرائض', archive['fard_completed'] ?? 0,
                        archive['fard_total'] ?? 5),
                    _buildStatItem('السنن', archive['sunnah_completed'] ?? 0,
                        archive['sunnah_total'] ?? 6),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('الورد', archive['quran_completed'] ?? 0,
                        archive['quran_total'] ?? 3),
                    _buildStatItem(
                        'قيام الليل',
                        archive['night_completed'] ?? 0,
                        archive['night_total'] ?? 3),
                    _buildStatItem('الأذكار', archive['athkar_completed'] ?? 0,
                        archive['athkar_total'] ?? 1),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // علامة التبويب الثالثة: أرشيف المهام اليومية
  Widget _buildTasksArchiveTab() {
    if (_dailyTasksArchive.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد بيانات محفوظة في أرشيف المهام اليومية',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _dailyTasksArchive.length,
      itemBuilder: (context, index) {
        final archive = _dailyTasksArchive[index];
        final int totalTasks = archive['total_tasks'] ?? 0;
        final int completedTasks = archive['completed_tasks'] ?? 0;
        final int inProgressTasks = archive['in_progress_tasks'] ?? 0;
        final double completionRate =
            totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تاريخ: ${archive['date'] ?? 'غير محدد'}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'الإتمام: ${completionRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('المهام', completedTasks, totalTasks),
                    _buildStatItem('قيد الإنجاز', inProgressTasks,
                        totalTasks - completedTasks),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('دنيوي', archive['worldly_completed'] ?? 0,
                        archive['worldly_total'] ?? 0),
                    _buildStatItem('أخروي', archive['religious_completed'] ?? 0,
                        archive['religious_total'] ?? 0),
                    _buildStatItem('مشترك', archive['both_completed'] ?? 0,
                        archive['both_total'] ?? 0),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // علامة التبويب الرابعة: إدارة المواقع
  Widget _buildLocationsTab() {
    if (_locations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا يوجد مواقع جغرافية مضافة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'اضغط على زر + لإضافة موقع جديد',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              'المواقع الجغرافية تستخدم لحساب أوقات الصلاة وتحديد القبلة',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade300),
          ),
          child: const Text(
            'هذه قائمة بالمواقع الجغرافية المضافة للتطبيق. المواقع الجغرافية ليست عناصر أرشيفية ولكنها متاحة للاستخدام في التطبيق.',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        if (_defaultLocation != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الموقع الافتراضي',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text('الاسم: ${_defaultLocation!['name'] ?? 'غير محدد'}'),
                Text('خط العرض: ${_defaultLocation!['latitude'] ?? 0}'),
                Text('خط الطول: ${_defaultLocation!['longitude'] ?? 0}'),
                Text(
                    'المنطقة الزمنية: ${_defaultLocation!['timeZoneName'] ?? 'غير محدد'}'),
                Text(
                    'فارق التوقيت: ${_defaultLocation!['timeZoneOffset'] ?? 0} ساعة'),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _locations.length,
            itemBuilder: (context, index) {
              final location = _locations[index];
              final isDefault = _defaultLocation != null &&
                  _defaultLocation!['name'] == location['name'];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: isDefault ? Colors.green.shade50 : null,
                child: ListTile(
                  title: Text(location['name'] ?? 'غير معروف'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'الإحداثيات: ${location['latitude'] ?? 0}, ${location['longitude'] ?? 0}'),
                      Text(
                          'فارق التوقيت: ${location['timeZoneOffset'] ?? 0} ساعة'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isDefault)
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.green),
                          onPressed: () async {
                            await _setAsDefaultLocation(location);
                          },
                          tooltip: 'تعيين كموقع افتراضي',
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // التحقق ما إذا كان الموقع هو الافتراضي
                          if (isDefault) {
                            _showCannotDeleteDefaultLocationDialog();
                            return;
                          }

                          await _deleteLocation(location);
                        },
                        tooltip: 'حذف الموقع',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              _showAddLocationDialog();
            },
            icon: const Icon(Icons.add_location),
            label: const Text('إضافة موقع جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات قاعدة البيانات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('عدد سجلات أرشيف العبادات: ${_worshipArchive.length}'),
            Text('عدد سجلات أرشيف المهام: ${_dailyTasksArchive.length}'),
            Text('عدد المواقع المحفوظة: ${_locations.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'حالة المزامنة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      _isLoading ? Icons.sync : Icons.check_circle,
                      color: _isLoading ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(_isLoading ? 'جاري المزامنة...' : 'متزامن'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('آخر تحديث:'),
                Text(_getFormattedTimeDifference()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedTimeDifference() {
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime);

    if (difference.inSeconds < 60) {
      return 'منذ ${difference.inSeconds} ثانية';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'منذ ${difference.inHours} ساعة';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              content,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int completed, int total) {
    final double percentage = total > 0 ? (completed / total * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 75
                    ? Colors.green
                    : percentage > 50
                        ? Colors.blue
                        : percentage > 25
                            ? Colors.orange
                            : Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$completed/$total',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // دالة تعيين موقع افتراضي
  Future<void> _setAsDefaultLocation(Map<String, dynamic> location) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await DatabaseHelper.instance.setDefaultLocationById(location['id']);
      await _loadArchiveData(); // إعادة تحميل البيانات

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تعيين ${location['name']} كموقع افتراضي'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تعيين الموقع الافتراضي: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // حوار لا يمكن حذف الموقع الافتراضي
  void _showCannotDeleteDefaultLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('لا يمكن الحذف'),
        content: const Text(
            'لا يمكن حذف الموقع الافتراضي. قم بتعيين موقع آخر كافتراضي أولاً.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  // دالة حذف موقع
  Future<void> _deleteLocation(Map<String, dynamic> location) async {
    bool confirm = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف ${location['name']}؟'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm) {
      try {
        setState(() {
          _isLoading = true;
        });

        await DatabaseHelper.instance.deleteLocation(location['id']);
        await _loadArchiveData(); // إعادة تحميل البيانات

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الموقع بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء حذف الموقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // حوار إضافة موقع جديد
  void _showAddLocationDialog() {
    final nameController = TextEditingController();
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();
    final timeZoneOffsetController = TextEditingController();
    bool makeDefault = false;

    // تخزين مرجع للسياق الأصلي لاستخدامه بعد إغلاق الحوار
    final BuildContext originalContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('إضافة موقع جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المدينة',
                    hintText: 'مثال: الرياض',
                  ),
                ),
                TextField(
                  controller: latitudeController,
                  decoration: const InputDecoration(
                    labelText: 'خط العرض',
                    hintText: 'مثال: 24.7136',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: longitudeController,
                  decoration: const InputDecoration(
                    labelText: 'خط الطول',
                    hintText: 'مثال: 46.6753',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: timeZoneOffsetController,
                  decoration: const InputDecoration(
                    labelText: 'فارق التوقيت UTC',
                    hintText: 'مثال: +3',
                    prefixText: 'UTC ',
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('تعيين كموقع افتراضي'),
                  value: makeDefault,
                  onChanged: (value) {
                    setState(() {
                      makeDefault = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    latitudeController.text.isEmpty ||
                    longitudeController.text.isEmpty ||
                    timeZoneOffsetController.text.isEmpty) {
                  // استخدام سياق الحوار للرسائل داخل الحوار
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('جميع الحقول مطلوبة'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // تحويل النصوص إلى أرقام
                  final latitude = double.parse(latitudeController.text);
                  final longitude = double.parse(longitudeController.text);

                  // معالجة فارق التوقيت
                  String rawOffset = timeZoneOffsetController.text.trim();
                  if (!rawOffset.contains('+') && !rawOffset.contains('-')) {
                    rawOffset = '+$rawOffset'; // افتراض موجب إذا لم يتم تحديده
                  }

                  double timeZoneOffset;
                  try {
                    // محاولة التحليل المباشر
                    timeZoneOffset = double.parse(rawOffset);
                  } catch (e) {
                    // إزالة العلامة ثم التحليل
                    final sign = rawOffset.startsWith('-') ? -1.0 : 1.0;
                    timeZoneOffset = double.parse(
                            rawOffset.replaceAll(RegExp(r'[+\-]'), '')) *
                        sign;
                  }

                  // إنشاء كائن الموقع
                  final location = {
                    'name': nameController.text,
                    'latitude': latitude,
                    'longitude': longitude,
                    'timeZoneName': 'UTC$rawOffset',
                    'timeZoneOffset': timeZoneOffset,
                  };

                  // إغلاق الحوار أولاً
                  Navigator.of(dialogContext).pop();

                  // تحديث حالة الشاشة الرئيسية
                  this.setState(() {
                    _isLoading = true;
                  });

                  final locationId = await DatabaseHelper.instance
                      .addLocationFromMap(location);

                  // تعيين كموقع افتراضي إذا تم تحديد ذلك
                  if (makeDefault) {
                    await DatabaseHelper.instance
                        .setDefaultLocationById(locationId);
                  }

                  // إضافة أوقات صلاة افتراضية للموقع الجديد
                  try {
                    await DatabaseHelper.instance
                        .addDefaultPrayerTimesForLocation(locationId);
                  } catch (e) {
                    print('خطأ أثناء إضافة أوقات الصلاة للموقع الجديد: $e');
                  }

                  await _loadArchiveData(); // إعادة تحميل البيانات

                  this.setState(() {
                    _isLoading = false;
                  });

                  // استخدام السياق الأصلي للشاشة بدلاً من سياق الحوار
                  if (mounted) {
                    ScaffoldMessenger.of(originalContext).showSnackBar(
                      SnackBar(
                        content: Text(
                            'تم إضافة الموقع ${nameController.text} بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // استخدام السياق الأصلي للشاشة بدلاً من سياق الحوار
                  if (mounted) {
                    ScaffoldMessenger.of(originalContext).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ أثناء إضافة الموقع: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
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
}
