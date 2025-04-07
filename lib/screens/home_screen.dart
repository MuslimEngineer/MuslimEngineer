import 'package:flutter/material.dart';
import 'dart:async';
import 'second_screen.dart';
import 'third_screen.dart';
import 'empty_screen_one.dart';
import 'archive_screen.dart';
import 'islamic_info_screen.dart';
import '../database/database_helper.dart';
import '../models/daily_task.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'database_admin_screen.dart';
import 'thoughts_journal_screen.dart';
import 'quran_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// بيانات المدن مع إحداثياتها
class CityData {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final double timeZoneOffset;

  CityData({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timeZoneOffset,
  });

  // تحويل الكائن إلى Map لتخزينه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'timeZoneOffset': timeZoneOffset,
    };
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, bool> _options = {};
  List<DailyTask> _dailyTasks = [];
  Timer? _timer;
  bool _isLoading = true;
  //Map<String, DateTime>? _prayerTimes;
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _cityNameController = TextEditingController();
  // متغيرات المدن والمواقع
  //List<CityData> _availableCities = [];
  //CityData? _selectedCity;

  // إضافة متغيرات أوقات الصلاة
  Map<String, dynamic>? _defaultLocation;
  Map<String, dynamic>? _prayerTimesData;
  bool _isLoadingPrayerTimes = false;
  double? _qiblaDirection; // إضافة متغير لاتجاه القبلة

  // إضافة متغير للرسالة اليومية
  Map<String, dynamic>? _latestDailyMessage;
  bool _isLoadingDailyMessage = false;

  // تعريف المتغيرات عند التهيئة
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar', null); // تهيئة تنسيق التواريخ العربية
    _initializeIslamicDatabase();
    _loadData();
    _loadPrayerTimes(); // تحميل أوقات الصلاة
    _loadLatestDailyMessage(); // تحميل آخر رسالة يومية
  }

  // تهيئة قواعد البيانات الإسلامية
  Future<void> _initializeIslamicDatabase() async {
    try {
      print('بدء تهيئة قواعد البيانات الإسلامية...');

      // تهيئة جدول الأذكار
      await DatabaseHelper.instance.initializeAthkarTable();
      print('تم تهيئة جدول الأذكار بنجاح');

      // تهيئة جدول الرسائل اليومية
      await DatabaseHelper.instance.initializeDailyMessagesTable();
      print('تم تهيئة جدول الرسائل اليومية بنجاح');

      // تهيئة جدول السور
      await DatabaseHelper.instance.initializeSurahsTable();
      print('تم تهيئة جدول السور بنجاح');

      // طباعة جميع مواقع المدن المتوفرة
      print('استعلام عن المدن المتوفرة...');
      final locations = await DatabaseHelper.instance.getLocations();
      print('المدن المتوفرة: ${locations.length}');
      for (var loc in locations) {
        print('- مدينة: ${loc['name']} - المعرف: ${loc['id']}');
      }

      // إصلاح وتهيئة جدول القبلة
      print('بدء إصلاح وتهيئة جدول القبلة...');
      await DatabaseHelper.instance.repairQiblaTable();
      print('تم إصلاح وتهيئة جدول القبلة بنجاح');

      // عرض جميع سجلات القبلة للتأكد
      print('استعلام عن جميع سجلات القبلة للتحقق...');
      await DatabaseHelper.instance.getAllQiblaDirections();

      // تهيئة جدول أوقات الصلاة
      await DatabaseHelper.instance.initializePrayerTimesTable();
      print('تم تهيئة جدول أوقات الصلاة بنجاح');

      // إضافة أوقات صلاة افتراضية
      await DatabaseHelper.instance.addDefaultPrayerTimes();

      print('اكتملت تهيئة قواعد البيانات الإسلامية');
    } catch (e) {
      print('خطأ أثناء تهيئة قواعد البيانات الإسلامية: $e');
    }
  }

  // تحميل بيانات أوقات الصلاة للموقع الافتراضي
  Future<void> _loadPrayerTimes() async {
    setState(() {
      _isLoadingPrayerTimes = true;
      _qiblaDirection = null; // إعادة تعيين قيمة اتجاه القبلة
    });

    try {
      // 1. الحصول على الموقع الافتراضي
      final defaultLocation =
          await DatabaseHelper.instance.getDefaultLocation();

      if (defaultLocation != null) {
        final locationId = defaultLocation['id'];
        print(
            'تم العثور على الموقع الافتراضي: ${defaultLocation['name']} (معرف: $locationId)');

        // 2. الحصول على اتجاه القبلة للموقع الافتراضي
        final qibla =
            await DatabaseHelper.instance.getQiblaDirection(locationId);
        if (qibla != null) {
          print('تم العثور على اتجاه القبلة للموقع الافتراضي: $qibla');
          _qiblaDirection = qibla;
        } else {
          print('لم يتم العثور على اتجاه القبلة للموقع الافتراضي');
        }

        // 3. الحصول على أوقات الصلاة لهذا الموقع
        final prayerTimesData = await DatabaseHelper.instance
            .getPrayerTimesByDate('2000/01/01', locationId: locationId);

        if (prayerTimesData != null) {
          print('تم العثور على أوقات الصلاة للموقع الافتراضي');

          setState(() {
            _defaultLocation = defaultLocation;
            _prayerTimesData = prayerTimesData;
            _isLoadingPrayerTimes = false;
          });
        } else {
          print(
              'لم يتم العثور على أوقات صلاة للموقع الافتراضي، جاري إضافة أوقات افتراضية');

          // محاولة إضافة أوقات صلاة افتراضية للموقع الافتراضي
          final success = await DatabaseHelper.instance
              .addDefaultPrayerTimesForLocation(locationId);

          if (success) {
            // إعادة محاولة الحصول على أوقات الصلاة
            final newPrayerTimesData = await DatabaseHelper.instance
                .getPrayerTimesByDate('2000/01/01', locationId: locationId);

            setState(() {
              _defaultLocation = defaultLocation;
              _prayerTimesData = newPrayerTimesData;
              _isLoadingPrayerTimes = false;
            });
          } else {
            print('فشل في إضافة أوقات صلاة افتراضية للموقع الافتراضي');
            setState(() {
              _defaultLocation = defaultLocation;
              _isLoadingPrayerTimes = false;
            });
          }
        }
      } else {
        print('لم يتم العثور على موقع افتراضي');
        setState(() {
          _isLoadingPrayerTimes = false;
        });
      }
    } catch (e) {
      print('خطأ أثناء تحميل أوقات الصلاة: $e');
      setState(() {
        _isLoadingPrayerTimes = false;
      });
    }
  }

  // تحميل آخر رسالة يومية
  Future<void> _loadLatestDailyMessage() async {
    setState(() {
      _isLoadingDailyMessage = true;
    });

    try {
      // جلب جميع الرسائل اليومية مرتبة تنازلياً حسب المعرف
      final messages = await DatabaseHelper.instance.getAllDailyMessages();

      if (messages.isNotEmpty) {
        // اختيار أحدث رسالة (الرسالة الأولى في القائمة لأننا رتبناها تنازلياً حسب المعرف)
        setState(() {
          _latestDailyMessage = messages.first;
          _isLoadingDailyMessage = false;
        });
        print('تم تحميل آخر رسالة يومية بنجاح');
      } else {
        setState(() {
          _latestDailyMessage = null;
          _isLoadingDailyMessage = false;
        });
        print('لم يتم العثور على رسائل يومية');
      }
    } catch (e) {
      setState(() {
        _isLoadingDailyMessage = false;
      });
      print('خطأ أثناء تحميل آخر رسالة يومية: $e');
    }
  }

  // تحميل دالة تحميل البيانات بإضافة استدعاء تحميل آخر رسالة يومية
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // تحميل الخيارات
      final options = await DatabaseHelper.instance.getOptions();
      // تحميل المهام اليومية
      final tasksMap = await DatabaseHelper.instance.getDailyTasks();

      // تحميل أوقات الصلاة أيضًا
      await _loadPrayerTimes();

      // تحميل آخر رسالة يومية
      await _loadLatestDailyMessage();

      if (mounted) {
        setState(() {
          _options.clear();
          _options.addAll(options);
          _dailyTasks = tasksMap.map((map) => DailyTask.fromMap(map)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('خطأ أثناء تحميل البيانات: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _cityNameController.dispose();
    super.dispose();
  }

  // إلى اسم عربي
  String _arabicPrayerName(String englishName) {
    final Map<String, String> prayerNames = {
      'fajr': 'الفجر',
      'sunrise': 'الشروق',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
      'none': 'لا يوجد',
    };

    return prayerNames[englishName.toLowerCase()] ?? englishName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تطبيق المسلم - الصفحة الرئيسية'),
        actions: [
          _buildOptionsButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildPrayerTimesCard(),
                const SizedBox(height: 16),
                _buildDailyMessageCard(),
                const SizedBox(height: 16),
                _buildWorshipSummaryCard(),
                const SizedBox(height: 16),
                _buildDailyTasksSummaryCard(),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  icon: Icons.mosque_outlined,
                  title: 'متابعة العبادات',
                  subtitle: 'تسجيل ومتابعة الصلوات والعبادات اليومية',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SecondScreen()),
                    ).then(
                        (_) => _loadData()); // إعادة تحميل البيانات بعد العودة
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  icon: Icons.star_outline,
                  title: 'المهام اليومية',
                  subtitle: 'تسجيل وتتبع مهامك اليومية والمستقبلية',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ThirdScreen()),
                    ).then(
                        (_) => _loadData()); // إعادة تحميل البيانات بعد العودة
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  icon: Icons.pages_outlined,
                  title: 'أفكاري ومشاريعي',
                  subtitle: 'تسجيل وإدارة الأفكار والمشاريع الشخصية',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmptyScreenOne()),
                    ).then(
                        (_) => _loadData()); // إعادة تحميل البيانات بعد العودة
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  icon: Icons.book_outlined,
                  title: 'سجل الخواطر',
                  subtitle: 'تدوين وحفظ الخواطر والأفكار اليومية',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ThoughtsJournalScreen()),
                    ).then(
                        (_) => _loadData()); // إعادة تحميل البيانات بعد العودة
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  icon: Icons.menu_book,
                  title: 'القرآن الكريم',
                  subtitle: 'قراءة وتلاوة القرآن الكريم',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const QuranScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  icon: Icons.archive_outlined,
                  title: 'الأرشيف',
                  subtitle: 'عرض وإدارة العناصر المؤرشفة من البيانات السابقة',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ArchiveScreen()),
                    ).then(
                        (_) => _loadData()); // إعادة تحميل البيانات بعد العودة
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  icon: Icons.info_outline,
                  title: 'المعلومات الإسلامية',
                  subtitle: 'الأذكار والأدعية والقبلة وأوقات الصلاة',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const IslamicInfoScreen()),
                    ).then(
                        (_) => _loadData()); // إعادة تحميل البيانات بعد العودة
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // بطاقة ملخص الأهداف اليومية
  Widget _buildDailyTasksSummaryCard() {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // حساب إحصائيات المهام اليومية
    int totalWorldly = 0;
    int completedWorldly = 0;
    int inProgressWorldly = 0;

    int totalReligious = 0;
    int completedReligious = 0;
    int inProgressReligious = 0;

    int totalBoth = 0;
    int completedBoth = 0;
    int inProgressBoth = 0;

    for (var task in _dailyTasks) {
      switch (task.taskType) {
        case TaskType.worldly:
          totalWorldly++;
          if (task.completed) completedWorldly++;
          if (task.inProgress) inProgressWorldly++;
          break;
        case TaskType.religious:
          totalReligious++;
          if (task.completed) completedReligious++;
          if (task.inProgress) inProgressReligious++;
          break;
        case TaskType.both:
          totalBoth++;
          if (task.completed) completedBoth++;
          if (task.inProgress) inProgressBoth++;
          break;
      }
    }

    // المجموع الكلي
    int totalTasks = totalWorldly + totalReligious + totalBoth;
    int completedTasks = completedWorldly + completedReligious + completedBoth;
    int inProgressTasks =
        inProgressWorldly + inProgressReligious + inProgressBoth;
    int incompleteTasks = totalTasks - completedTasks; // المهام غير المنجزة

    // نسبة الإنجاز
    double completionPercentage =
        totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;
    // حساب نسبة المهام قيد الإنجاز من المهام غير المنجزة فقط
    double progressPercentage =
        incompleteTasks > 0 ? (inProgressTasks / incompleteTasks) * 100 : 0;

    return Card(
      color: Colors.amber.shade50,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ملخص الأهداف اليومية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.amber),
                  onPressed: _loadData,
                  tooltip: 'تحديث',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // نسبة الإنجاز الكلية
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('نسبة إنجاز الأهداف:'),
                      Text(
                        '${completionPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: completionPercentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('نسبة العمل على الأهداف المتبقية:'),
                      Text(
                        '${progressPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progressPercentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ملخص حسب نوع الهدف
            Row(
              children: [
                Expanded(
                  child: _buildGoalTypeItem(
                    'أهداف دنيوية',
                    completedWorldly,
                    totalWorldly,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGoalTypeItem(
                    'أهداف أخروية',
                    completedReligious,
                    totalReligious,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildGoalTypeItem(
                    'أهداف مشتركة',
                    completedBoth,
                    totalBoth,
                    Colors.purple,
                  ),
                ),
                const Expanded(
                  child: SizedBox(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // إحصائيات إضافية
            Text(
              'عدد الأهداف: $totalTasks، مكتمل: $completedTasks، قيد الإنجاز: $inProgressTasks',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // عنصر عرض نوع الهدف
  Widget _buildGoalTypeItem(
      String title, int completed, int total, Color color) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: total > 0 ? completed / total : 0,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 4),
          Text(
            '$completed/$total',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة ملخص العبادات
  Widget _buildWorshipSummaryCard() {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // الفرائض (الصلوات الخمس)
    int totalFard = 5;
    int completedFard = 0;

    // السنن
    int availableSunnahBefore = 0;
    int availableSunnahAfter = 0;
    int completedSunnah = 0;

    // الورد القرآني (3 مستويات: آية، صفحة، جزء)
    int totalQuran = 3;
    int completedQuran = 0;

    // الأذكار - تصحيح ليعكس أن الأذكار هي الخيار 10 بمستوياته الثلاثة
    int totalAthkar = 3; // ثلاثة مستويات للأذكار
    int completedAthkar = 0;

    // حساب الأذكار المكتملة (الخيار 10 بمستوياته)
    if (_options['option10'] == true) completedAthkar++; // المستوى الأول
    if (_options['option10_level2'] == true)
      completedAthkar++; // المستوى الثاني
    if (_options['option10_level3'] == true)
      completedAthkar++; // المستوى الثالث

    // قيام الليل وما يتعلق به
    int totalNightPrayers = 3; // قيام الليل، التهجد، الوتر
    int completedNightPrayers = 0;

    // حساب الفرائض
    for (int i = 1; i <= 5; i++) {
      String key = 'option${i}_level2'; // الفرائض في المستوى 2
      if (_options[key] == true) {
        completedFard++;
      }

      // حساب السنن المتاحة
      if (i == 1 || i == 2 || i == 3) {
        // فجر، ظهر، عصر
        availableSunnahBefore++;
      }
      if (i == 2 || i == 4 || i == 5) {
        // ظهر، مغرب، عشاء
        availableSunnahAfter++;
      }
    }

    int totalSunnah =
        availableSunnahBefore + availableSunnahAfter; // إجمالي السنن المتاحة

    // حساب السنن المكتملة
    if (_options['option1'] == true) completedSunnah++; // فجر قبلية
    if (_options['option2'] == true) completedSunnah++; // ظهر قبلية
    if (_options['option3'] == true) completedSunnah++; // عصر قبلية
    if (_options['option2_level3'] == true) completedSunnah++; // ظهر بعدية
    if (_options['option4_level3'] == true) completedSunnah++; // مغرب بعدية
    if (_options['option5_level3'] == true) completedSunnah++; // عشاء بعدية

    // حساب الورد القرآني
    if (_options['option6'] == true) completedQuran++; // آية
    if (_options['option6_level2'] == true) completedQuran++; // صفحة
    if (_options['option6_level3'] == true) completedQuran++; // جزء

    // حساب صلاة الليل
    if (_options['option7'] == true ||
        _options['option7_level2'] == true ||
        _options['option7_level3'] == true) {
      completedNightPrayers++; // قيام الليل (يكفي مستوى واحد)
    }
    if (_options['option8'] == true) completedNightPrayers++; // التهجد
    if (_options['option9'] == true) completedNightPrayers++; // الوتر

    // حساب التقدم الكلي
    double totalProgress = ((completedFard +
                completedSunnah +
                completedQuran +
                completedAthkar +
                completedNightPrayers) /
            (totalFard +
                totalSunnah +
                totalQuran +
                totalAthkar +
                totalNightPrayers)) *
        100;

    return Card(
      color: Colors.green.shade50,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ملخص العبادات اليومية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.green),
                  onPressed: _loadData,
                  tooltip: 'تحديث',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // الصف الأول: الفرائض والسنن
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'الفرائض',
                    completedFard,
                    totalFard,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryItem(
                    'السنن',
                    completedSunnah,
                    totalSunnah,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // الصف الثاني: القرآن وقيام الليل
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'الورد القرآني',
                    completedQuran,
                    totalQuran,
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryItem(
                    'قيام الليل',
                    completedNightPrayers,
                    totalNightPrayers,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // الصف الثالث: الأذكار والتقدم الكلي
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'الأذكار',
                    completedAthkar,
                    totalAthkar,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'التقدم الكلي',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: totalProgress / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${totalProgress.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // خلية ملخص لكل نوع عبادة
  Widget _buildSummaryItem(
      String title, int completed, int total, Color color) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: total > 0 ? completed / total : 0,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 4),
          Text(
            '$completed/$total',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }

  // الدالة التي تعرض عند الضغط على زر إعادة تحميل
  void _refreshApp() async {
    // عرض نص "جاري التحميل"
    setState(() {
      _isLoading = true;
    });

    // إعادة تحميل البيانات
    await _loadData();

    // تحميل أوقات الصلاة
    await _loadPrayerTimes();

    // إخفاء نص "جاري التحميل"
    setState(() {
      _isLoading = false;
    });

    // عرض رسالة تأكيد
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
    );
  }

  // زر الخيارات في شريط التطبيق - محاذاة يسار
  Widget _buildOptionsButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'manage_database') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DatabaseAdminScreen(),
            ),
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'manage_database',
          child: Row(
            children: [
              Icon(Icons.storage, color: Colors.purple),
              SizedBox(width: 8),
              Text('إدارة قاعدة البيانات'),
            ],
          ),
        ),
      ],
    );
  }

  // بناء كارت أوقات الصلاة
  Widget _buildPrayerTimesCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'أوقات الصلاة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_defaultLocation != null)
                  Text(
                    '${_defaultLocation!['name']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            const Divider(),
            if (_isLoadingPrayerTimes)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_prayerTimesData == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'لم يتم العثور على أوقات الصلاة',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              )
            else
              Column(
                children: [
                  _buildPrayerTimeRow(
                      'fajr', 'الفجر', _prayerTimesData!['fajr']),
                  _buildPrayerTimeRow(
                      'sunrise', 'الشروق', _prayerTimesData!['sunrise']),
                  _buildPrayerTimeRow(
                      'dhuhr', 'الظهر', _prayerTimesData!['dhuhr']),
                  _buildPrayerTimeRow('asr', 'العصر', _prayerTimesData!['asr']),
                  _buildPrayerTimeRow(
                      'maghrib', 'المغرب', _prayerTimesData!['maghrib']),
                  _buildPrayerTimeRow(
                      'isha', 'العشاء', _prayerTimesData!['isha']),
                ],
              ),
            if (_defaultLocation != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'الإحداثيات: ${_defaultLocation!['latitude']}, ${_defaultLocation!['longitude']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  if (_qiblaDirection != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Text(
                            'اتجاه القبلة:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_qiblaDirection!.toStringAsFixed(2)}°',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Icon(
                            Icons.compass_calibration,
                            size: 16,
                            color: _qiblaDirection == 360
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // بناء صف لوقت صلاة معين
  Widget _buildPrayerTimeRow(String key, String name, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            time,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // بناء كرت الرسالة اليومية
  Widget _buildDailyMessageCard() {
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'رسالة اليوم',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  onPressed: _loadLatestDailyMessage,
                  tooltip: 'تحديث',
                ),
              ],
            ),
            const Divider(),
            if (_isLoadingDailyMessage)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_latestDailyMessage == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'لم يتم العثور على رسائل يومية',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _latestDailyMessage!['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _latestDailyMessage!['content'],
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _latestDailyMessage!['category'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                      Text(
                        'المصدر: ${_latestDailyMessage!['source']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
