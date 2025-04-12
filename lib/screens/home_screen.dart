import 'package:flutter/material.dart';
import 'dart:async';
import 'second_screen.dart';
import 'third_screen.dart';
import 'empty_screen_one.dart';
import 'islamic_info_screen.dart';
import '../database/database_helper.dart';
import '../models/daily_task.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'database_admin_screen.dart';
import 'thoughts_journal_screen.dart';
import 'quran_screen.dart';
import 'options_screen.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../widgets/next_prayer_widget.dart';
import '../theme/app_colors.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final Map<String, bool> _options = {};
  List<DailyTask> _dailyTasks = [];
  Timer? _timer;
  bool _isLoading = true;
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _cityNameController = TextEditingController();

  // متغيرات أوقات الصلاة
  Map<String, dynamic>? _defaultLocation;
  Map<String, dynamic>? _prayerTimesData;
  bool _isLoadingPrayerTimes = false;
  double? _qiblaDirection; // إضافة متغير لاتجاه القبلة

  // إضافة متغير للرسالة اليومية
  Map<String, dynamic>? _latestDailyMessage;
  bool _isLoadingDailyMessage = false;
  
  // متغيرات شريط التنقل السفلي
  int _currentNavIndex = 0;
  
  // متغيرات للتأثيرات المتحركة
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar', null); // تهيئة تنسيق التواريخ العربية
    
    // تهيئة التأثيرات المتحركة
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
    
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

      // إصلاح وتهيئة جدول القبلة
      print('بدء إصلاح وتهيئة جدول القبلة...');
      await DatabaseHelper.instance.repairQiblaTable();
      print('تم إصلاح وتهيئة جدول القبلة بنجاح');

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

  // تحميل البيانات
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
    _animationController.dispose();
    super.dispose();
  }

  // التنقل بين شاشات التطبيق عبر شريط التنقل السفلي
  void _onNavItemTapped(int index) {
    if (index == _currentNavIndex) return;
    
    switch (index) {
      case 0: // الرئيسية - نحن بالفعل هنا
        setState(() {
          _currentNavIndex = index;
        });
        break;
      case 1: // العبادات
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SecondScreen()),
        ).then((_) => _loadData());
        break;
      case 2: // المهام
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ThirdScreen()),
        ).then((_) => _loadData());
        break;
      case 3: // القرآن
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuranScreen()),
        ).then((_) => _loadData());
        break;
      case 4: // الإعدادات
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OptionsScreen()),
        ).then((_) => _loadData());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode 
          ? AppColors.darkBackgroundColor 
          : AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavItemTapped,
        isDarkMode: widget.isDarkMode,
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: widget.isDarkMode 
          ? AppColors.darkSurfaceColor
          : AppColors.primaryColor,
      centerTitle: true,
      title: const Text(
        'المهندس المسلم',
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
          ),
          onPressed: () => widget.toggleTheme(),
          tooltip: widget.isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshApp,
          tooltip: 'تحديث',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primaryColor,
      backgroundColor: widget.isDarkMode ? AppColors.darkSurfaceColor : Colors.white,
      child: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/loading.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 24),
          Shimmer.fromColors(
            baseColor: widget.isDarkMode
                ? Colors.grey[700]!
                : Colors.grey[300]!,
            highlightColor: widget.isDarkMode
                ? Colors.grey[600]!
                : Colors.grey[100]!,
            child: Container(
              width: 200,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return AnimationLimiter(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 400),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              // ويدجت الصلاة التالية مع عداد تنازلي
              if (!_isLoadingPrayerTimes && _prayerTimesData != null)
                NextPrayerWidget(
                  prayerTimesData: _prayerTimesData!,
                  isDarkMode: widget.isDarkMode,
                ),
              
              const SizedBox(height: 20),
              
              // بطاقة الرسالة اليومية
              _buildDailyMessageCard(),
              
              const SizedBox(height: 20),
              
              // الشعارات السريعة
              _buildQuickActions(),
              
              const SizedBox(height: 16),
              
              // عنوان القسم - ملخص المهام
              _buildSectionTitle('ملخص المهام'),
              
              const SizedBox(height: 12),
              
              // بطاقة ملخص المهام
              _buildDailyTasksSummaryCard(),
              
              const SizedBox(height: 20),
              
              // عنوان القسم - ملخص العبادات
              _buildSectionTitle('ملخص العبادات'),
              
              const SizedBox(height: 12),
              
              // بطاقة ملخص العبادات
              _buildWorshipSummaryCard(),
              
              const SizedBox(height: 20),

              // عنوان القسم - التنقل السريع
              _buildSectionTitle('التنقل السريع'),
              
              const SizedBox(height: 12),
              
              // بطاقات التنقل السريع
              _buildQuickNavigationCards(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode 
                  ? Colors.white 
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildQuickActionItem(
            icon: Icons.mosque_outlined,
            title: 'العبادات',
            color: AppColors.mosqueGreen,
            onTap: () {
              _onNavItemTapped(1);
            },
          ),
          _buildQuickActionItem(
            icon: Icons.task_alt_outlined,
            title: 'المهام',
            color: AppColors.prayerBlue,
            onTap: () {
              _onNavItemTapped(2);
            },
          ),
          _buildQuickActionItem(
            icon: Icons.menu_book_outlined,
            title: 'القرآن',
            color: AppColors.quranGold,
            onTap: () {
              _onNavItemTapped(3);
            },
          ),
          _buildQuickActionItem(
            icon: Icons.comment_outlined,
            title: 'الأذكار',
            color: AppColors.accentColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IslamicInfoScreen()),
              );
            },
          ),
          _buildQuickActionItem(
            icon: Icons.book_outlined,
            title: 'الخواطر',
            color: AppColors.bothTasksColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ThoughtsJournalScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(widget.isDarkMode ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNavigationCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNavCard(
                icon: Icons.menu_book,
                title: 'القرآن الكريم',
                description: 'قراءة وتلاوة القرآن',
                color: AppColors.quranGold,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuranScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNavCard(
                icon: Icons.info_outline,
                title: 'معلومات إسلامية',
                description: 'أذكار وأدعية وقبلة',
                color: AppColors.mosqueGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IslamicInfoScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNavCard(
                icon: Icons.book_outlined,
                title: 'سجل الخواطر',
                description: 'تدوين وحفظ الخواطر',
                color: AppColors.bothTasksColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ThoughtsJournalScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNavCard(
                icon: Icons.archive_outlined,
                title: 'الأرشيف',
                description: 'عرض وإدارة الأرشيف',
                color: AppColors.secondaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EmptyScreenOne()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: widget.isDarkMode ? AppColors.darkSurfaceColor : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDarkMode ? Colors.grey[400] : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // بطاقة الرسالة اليومية
  Widget _buildDailyMessageCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: widget.isDarkMode 
          ? AppColors.darkSurfaceColor 
          : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: widget.isDarkMode 
                          ? AppColors.darkPrimaryColor 
                          : AppColors.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'رسالة اليوم',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode 
                            ? Colors.white 
                            : AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: widget.isDarkMode 
                        ? AppColors.darkPrimaryColor 
                        : AppColors.primaryColor,
                  ),
                  onPressed: _loadLatestDailyMessage,
                  tooltip: 'تحديث',
                ),
              ],
            ),
            const Divider(),
            if (_isLoadingDailyMessage)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    color: widget.isDarkMode 
                        ? AppColors.darkPrimaryColor 
                        : AppColors.primaryColor,
                  ),
                ),
              )
            else if (_latestDailyMessage == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'لم يتم العثور على رسائل يومية',
                    style: TextStyle(
                      color: widget.isDarkMode 
                          ? Colors.grey[400] 
                          : Colors.grey[700],
                    ),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _latestDailyMessage!['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode 
                          ? Colors.white 
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _latestDailyMessage!['content'],
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isDarkMode 
                          ? Colors.grey[300] 
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode 
                              ? AppColors.darkPrimaryColor.withOpacity(0.3) 
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _latestDailyMessage!['category'],
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDarkMode 
                                ? AppColors.darkPrimaryColor 
                                : AppColors.primaryColor,
                          ),
                        ),
                      ),
                      Text(
                        'المصدر: ${_latestDailyMessage!['source']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: widget.isDarkMode 
                              ? Colors.grey[400] 
                              : AppColors.textSecondary,
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

  // بطاقة ملخص المهام
  Widget _buildDailyTasksSummaryCard() {
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
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: widget.isDarkMode 
          ? AppColors.darkSurfaceColor 
          : Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ملخص الأهداف اليومية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode 
                        ? Colors.white 
                        : AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: widget.isDarkMode 
                        ? Colors.amber[300] 
                        : Colors.amber,
                  ),
                  onPressed: _loadData,
                  tooltip: 'تحديث',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // نسبة الإنجاز الكلية
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: widget.isDarkMode 
                    ? Colors.grey[850] 
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.isDarkMode 
                        ? Colors.black.withOpacity(0.3) 
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'نسبة إنجاز الأهداف:',
                        style: TextStyle(
                          color: widget.isDarkMode 
                              ? Colors.white 
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${completionPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: completionPercentage / 100,
                      backgroundColor: widget.isDarkMode 
                          ? Colors.grey[700] 
                          : Colors.grey[200],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.green),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'نسبة العمل على الأهداف المتبقية:',
                        style: TextStyle(
                          color: widget.isDarkMode 
                              ? Colors.white 
                              : AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${progressPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressPercentage / 100,
                      backgroundColor: widget.isDarkMode 
                          ? Colors.grey[700] 
                          : Colors.grey[200],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.orange),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ملخص حسب نوع الهدف
            Row(
              children: [
                Expanded(
                  child: _buildGoalTypeItem(
                    'أهداف دنيوية',
                    completedWorldly,
                    totalWorldly,
                    AppColors.worldlyTaskColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGoalTypeItem(
                    'أهداف أخروية',
                    completedReligious,
                    totalReligious,
                    AppColors.religiousTaskColor,
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
                    AppColors.bothTasksColor,
                  ),
                ),
                const Expanded(
                  child: SizedBox(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // إحصائيات إضافية
            Center(
              child: Text(
                'عدد الأهداف: $totalTasks، مكتمل: $completedTasks، قيد الإنجاز: $inProgressTasks',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDarkMode 
                      ? Colors.grey[400] 
                      : AppColors.textSecondary,
                ),
              ),
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
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.isDarkMode 
            ? Colors.grey[850] 
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode 
                ? Colors.black.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              backgroundColor: widget.isDarkMode 
                  ? Colors.grey[700] 
                  : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
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
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: widget.isDarkMode 
          ? AppColors.darkSurfaceColor 
          : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ملخص العبادات اليومية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode 
                        ? Colors.white 
                        : AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh, 
                    color: widget.isDarkMode 
                        ? Colors.green[300] 
                        : Colors.green,
                  ),
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
                    AppColors.prayerBlue,
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
                    AppColors.quranGold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryItem(
                    'قيام الليل',
                    completedNightPrayers,
                    totalNightPrayers,
                    AppColors.bothTasksColor,
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
                    AppColors.mosqueGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: widget.isDarkMode 
                          ? Colors.grey[850] 
                          : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: widget.isDarkMode 
                              ? Colors.black.withOpacity(0.3) 
                              : Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'التقدم الكلي',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: totalProgress / 100,
                            backgroundColor: widget.isDarkMode 
                                ? Colors.grey[700] 
                                : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.mosqueGreen),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${totalProgress.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.mosqueGreen,
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
  Widget _buildSummaryItem(String title, int completed, int total, Color color) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.isDarkMode 
            ? Colors.grey[850] 
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode 
                ? Colors.black.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              backgroundColor: widget.isDarkMode 
                  ? Colors.grey[700] 
                  : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
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

  // الدالة التي تعرض عند الضغط على زر إعادة تحميل
  void _refreshApp() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('جاري تحديث البيانات...'),
        backgroundColor: widget.isDarkMode 
            ? AppColors.darkPrimaryColor 
            : AppColors.primaryColor,
      ),
    );

    // إعادة تحميل البيانات
    await _loadData();

    // عرض رسالة تأكيد
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تحديث البيانات بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
