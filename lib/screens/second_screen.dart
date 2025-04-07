import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'database_info_screen.dart';

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  State<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  // إزالة المتغير options لأنه غير مستخدم ويمكن أن يسبب مشاكل
  // Future<Map<String, bool>> options = DatabaseHelper.instance.getOptions();

  final Map<String, bool> _options = {
    'option1': false,
    'option2': false,
    'option3': false,
    'option4': false,
    'option5': false,
    'option6': false,
    'option7': false,
    'option8': false,
    'option9': false,
    'option10': false,
  };
  bool _isLoading = false;
  DateTime _lastSyncTime = DateTime.now();
  // متغير لتتبع ما إذا كان تم تحميل البيانات بالفعل
  bool _dataLoaded = false;
  // متغير لتتبع ما إذا كانت هناك تغييرات لم يتم حفظها
  bool _hasChanges = false;
  // حل مشكلة الاستثناء باستخدام متغير للإشارة إلى سياق آمن
  bool _isSafeContext = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _dataLoaded = true;
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      // إزالة السطر التالي
      // options = DatabaseHelper.instance.getOptions();
    });

    try {
      final options = await DatabaseHelper.instance.getOptions();
      if (mounted) {
        setState(() {
          _options.clear(); // مسح الخيارات الحالية قبل تحميل الخيارات الجديدة
          _options.addAll(options);
          _isLoading = false;
          _lastSyncTime = DateTime.now();
          _hasChanges = false; // إعادة تعيين حالة التغييرات عند التحميل
          print('تم تحميل الخيارات من قاعدة البيانات: $_options');
        });
      }
      // await DatabaseHelper.instance.printDatabaseContents(); // تم إزالة هذه الدالة غير الموجودة
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('خطأ أثناء تحميل الخيارات: $e');
    }
  }

  Future<void> _saveOptions() async {
    setState(() {
      _isLoading = true;
    });

    print('جاري حفظ الخيارات: $_options');
    try {
      await DatabaseHelper.instance.updateOptions(_options);

      setState(() {
        _isLoading = false;
        _lastSyncTime = DateTime.now();
        _hasChanges = false; // إعادة تعيين حالة التغييرات بعد الحفظ
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الخيارات بنجاح')),
        );
      }
      // await DatabaseHelper.instance.printDatabaseContents(); // تم إزالة هذه الدالة غير الموجودة

      // إعادة تحميل الخيارات من قاعدة البيانات لضمان المزامنة
      await _loadOptions();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('خطأ أثناء حفظ الخيارات: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء حفظ الخيارات')),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحميل الخيارات عند تغيير السياق فقط إذا لم يتم تحميلها بالفعل
    if (!_dataLoaded) {
      _loadOptions();
      _dataLoaded = true;
    }
  }

  @override
  void dispose() {
    _isSafeContext = false;
    // حفظ الخيارات قبل إغلاق الشاشة
    // لا تستدعي _saveOptions() في dispose لأنها تستخدم setState وتسبب خطأ
    // _saveOptions();  // إزالة هذا السطر
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('متابعة العبادات اليومية'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // حفظ البيانات قبل العودة للشاشة السابقة إذا كانت هناك تغييرات
            if (_hasChanges) {
              await _saveOptions();
            }
            if (mounted) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DatabaseInfoScreen()),
              );
            },
            tooltip: 'معلومات قاعدة البيانات',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: const [
                    Icon(Icons.refresh, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('إعادة تعيين'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: const [
                    Icon(Icons.download, color: Colors.green),
                    SizedBox(width: 8),
                    Text('تصدير البيانات'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: const [
                    Icon(Icons.analytics, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('عرض الإحصائيات'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: const [
                    Icon(Icons.archive, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('أرشفة البيانات الحالية'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'reset') {
                _showResetConfirmationDialog();
              } else if (value == 'export') {
                _showExportDialog();
              } else if (value == 'stats') {
                _showStatsDialog();
              } else if (value == 'archive') {
                await _archiveCurrentData();
              }
            },
            tooltip: 'المزيد من الخيارات',
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadOptions,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildCheckboxes(),
                  const SizedBox(height: 80), // مساحة للزر العائم
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
      floatingActionButton: _hasChanges
          ? FloatingActionButton.extended(
              onPressed: _saveOptions,
              icon: const Icon(Icons.save),
              label: const Text('حفظ التغييرات'),
              tooltip: 'حفظ جميع التغييرات',
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSummaryCard() {
    // حساب عدد المهام المكتملة

    // الفرائض (الصلوات الخمس)
    int totalFard = 5;
    int completedFard = 0;

    // السنن (3 قبلية و3 بعدية)
    int totalSunnahBefore = 3; // فجر، ظهر، عصر
    int totalSunnahAfter = 3; // ظهر، مغرب، عشاء
    int completedSunnahBefore = 0;
    int completedSunnahAfter = 0;

    // الورد القرآني (3 مستويات: آية، صفحة، جزء)
    int totalQuran = 3;
    int completedQuran = 0;

    // الأذكار (3 مستويات: صباح، مساء، نوم)
    int totalAthkar = 3;
    int completedAthkar = 0;
    if (_options['option10'] == true) completedAthkar++;
    if (_options['option10_level2'] == true) completedAthkar++;
    if (_options['option10_level3'] == true) completedAthkar++;

    // قيام الليل وما يتعلق به
    int totalNightPrayers = 3; // قيام الليل، التهجد، الوتر
    int completedNightPrayers = 0;

    // حساب الفرائض
    for (int i = 1; i <= 5; i++) {
      String key = 'option${i}_level2'; // الفرائض في المستوى 2
      if (_options[key] == true) {
        completedFard++;
      }
    }

    // حساب السنن
    if (_options['option1'] == true) completedSunnahBefore++; // فجر قبلية
    if (_options['option2'] == true) completedSunnahBefore++; // ظهر قبلية
    if (_options['option3'] == true) completedSunnahBefore++; // عصر قبلية

    if (_options['option2_level3'] == true) completedSunnahAfter++; // ظهر بعدية
    if (_options['option4_level3'] == true)
      completedSunnahAfter++; // مغرب بعدية
    if (_options['option5_level3'] == true)
      completedSunnahAfter++; // عشاء بعدية

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

    return Card(
      color: Colors.green.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخص العبادات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // الصف الأول: الفرائض والسنن
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'الفرائض',
                    completedFard,
                    totalFard,
                    Colors.orange,
                    Icons.access_time,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryItem(
                    'السنن',
                    completedSunnahBefore + completedSunnahAfter,
                    totalSunnahBefore + totalSunnahAfter,
                    Colors.blue,
                    Icons.access_time,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // الصف الثاني: الورد القرآني وقيام الليل
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'الورد القرآني',
                    completedQuran,
                    totalQuran,
                    Colors.teal,
                    Icons.menu_book,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryItem(
                    'قيام الليل',
                    completedNightPrayers,
                    totalNightPrayers,
                    Colors.purple,
                    Icons.nightlight_round,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // الصف الثالث: الأذكار
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'الأذكار',
                    completedAthkar,
                    totalAthkar,
                    Colors.green,
                    Icons.speaker_notes,
                  ),
                ),
                const Expanded(child: SizedBox()), // للمحافظة على التوازن
              ],
            ),

            const SizedBox(height: 16),

            // التفاصيل
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'السنن القبلية: $completedSunnahBefore/$totalSunnahBefore',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'السنن البعدية: $completedSunnahAfter/$totalSunnahAfter',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الورد القرآني: $completedQuran/$totalQuran',
                      style: const TextStyle(fontSize: 12, color: Colors.teal),
                    ),
                    Text(
                      'قيام الليل: $completedNightPrayers/$totalNightPrayers',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.purple),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // التقدم الكلي
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    'التقدم الكلي: ${((completedFard + completedSunnahBefore + completedSunnahAfter + completedQuran + completedAthkar + completedNightPrayers) / (totalFard + totalSunnahBefore + totalSunnahAfter + totalQuran + totalAthkar + totalNightPrayers) * 100).round()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // عنصر ملخص بشكل دائري
  Widget _buildSummaryItem(
      String title, int completed, int total, Color color, IconData icon) {
    double progress = total > 0 ? completed / total : 0;
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 70,
              width: 70,
              child: CircularProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 8,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color),
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
          ],
        ),
      ],
    );
  }

  // حوار تأكيد إعادة التعيين
  Future<void> _showResetConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد إعادة التعيين'),
          content: const Text(
              'هل أنت متأكد من رغبتك في إعادة تعيين جميع العبادات؟ سيتم مسح جميع تقدمك الحالي.'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('تأكيد'),
              onPressed: () async {
                Navigator.of(context).pop();
                await DatabaseHelper.instance.resetOptions();
                await _loadOptions();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'تم إعادة تعيين العبادات بنجاح. بارك الله في عملك.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // حوار تصدير البيانات
  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدير البيانات'),
        content: const Text('سيتم إضافة هذه الميزة في التحديثات القادمة.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  // حوار عرض الإحصائيات
  void _showStatsDialog() {
    // حساب الإحصائيات
    int totalTasks = 30; // 10 مهام × 3 مستويات
    int completedTasks = 0;

    // الصلوات الفرائض المكتملة
    int completedFard = 0;

    // السنن المكتملة
    int completedSunnahBefore = 0;
    int completedSunnahAfter = 0;

    // السنن المتاحة
    int availableSunnahBefore = 0;
    int availableSunnahAfter = 0;

    // الصلوات الخمس
    int prayersTotal = 15; // 5 صلوات × 3 مستويات
    int prayersCompleted = 0;

    // الأعمال الإضافية
    int additionalTotal = 15; // 5 أعمال إضافية × 3 مستويات (أو أقل)
    int additionalCompleted = 0;

    for (int i = 1; i <= 10; i++) {
      String baseKey = 'option$i';
      bool isMainPrayer = i <= 5; // الصلوات الخمس

      if (_options[baseKey] == true) {
        completedTasks++;
        if (isMainPrayer) {
          prayersCompleted++;
          completedSunnahBefore++;
        } else {
          additionalCompleted++;
        }
      }

      if (_options['${baseKey}_level2'] == true) {
        completedTasks++;
        if (isMainPrayer) {
          prayersCompleted++;
          completedFard++;
        } else {
          additionalCompleted++;
        }
      }

      if (_options['${baseKey}_level3'] == true) {
        completedTasks++;
        if (isMainPrayer) {
          prayersCompleted++;
          completedSunnahAfter++;
        } else {
          additionalCompleted++;
        }
      }

      // حساب السنن المتاحة
      if (i <= 5) {
        List<String> levelHints = _getLevelHints(i);
        if (!levelHints[0].contains("لا يوجد")) availableSunnahBefore++;
        if (!levelHints[2].contains("لا يوجد")) availableSunnahAfter++;
      }
    }

    int completionPercentage = ((completedTasks / totalTasks) * 100).round();
    int prayersPercentage = ((prayersCompleted / prayersTotal) * 100).round();
    int additionalPercentage =
        ((additionalCompleted / additionalTotal) * 100).round();
    int fardPercentage = ((completedFard / 5) * 100).round();

    int totalSunnahAvailable = availableSunnahBefore + availableSunnahAfter;
    int totalSunnahCompleted = completedSunnahBefore + completedSunnahAfter;
    int sunnahPercentage = totalSunnahAvailable > 0
        ? ((totalSunnahCompleted / totalSunnahAvailable) * 100).round()
        : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.mosque, color: Colors.green),
            SizedBox(width: 8),
            Text('إحصائيات العبادات'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // إحصائيات الصلوات
                _buildStatHeader('الصلوات الخمس'),
                _buildStatItem(
                    'الفرائض المكتملة', '$completedFard/5', fardPercentage),
                _buildStatItem(
                    'السنن القبلية',
                    '$completedSunnahBefore/$availableSunnahBefore',
                    availableSunnahBefore > 0
                        ? ((completedSunnahBefore / availableSunnahBefore) *
                                100)
                            .round()
                        : 0),
                _buildStatItem(
                    'السنن البعدية',
                    '$completedSunnahAfter/$availableSunnahAfter',
                    availableSunnahAfter > 0
                        ? ((completedSunnahAfter / availableSunnahAfter) * 100)
                            .round()
                        : 0),

                const Divider(),

                // إجمالي الصلوات
                _buildStatHeader('الإجمالي'),
                _buildStatItem('الصلوات والسنن',
                    '$prayersCompleted/$prayersTotal', prayersPercentage),
                _buildStatItem(
                    'العبادات الإضافية',
                    '$additionalCompleted/$additionalTotal',
                    additionalPercentage),
                _buildStatItem(
                    'السنن الإجمالية',
                    '$totalSunnahCompleted/$totalSunnahAvailable',
                    sunnahPercentage),
                _buildStatItem('كافة العبادات', '$completedTasks/$totalTasks',
                    completionPercentage),

                const SizedBox(height: 16),
                const Text(
                  'اللهم تقبل منا صالح الأعمال',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // عنوان قسم في الإحصائيات
  Widget _buildStatHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.green.shade800,
        ),
      ),
    );
  }

  // عنصر إحصائية
  Widget _buildStatItem(String title, String value, int percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage >= 75
                ? Colors.green
                : percentage >= 50
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // دالة أرشفة البيانات الحالية
  Future<void> _archiveCurrentData() async {
    bool confirm = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أرشفة بيانات العبادات'),
        content: const Text(
          'هل تريد أرشفة بيانات العبادات الحالية؟ سيتم حفظ ملخص للحالة الحالية في أرشيف العبادات.',
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
        // حساب إحصائيات العبادات
        int completedFard = 0;
        int completedSunnahBefore = 0;
        int completedSunnahAfter = 0;
        int completedQuran = 0;
        int completedNightPrayers = 0;
        int completedAthkar = 0;

        // حساب السنن المتاحة
        int availableSunnahBefore = 0;
        int availableSunnahAfter = 0;

        // الصلوات المكتملة
        for (int i = 1; i <= 5; i++) {
          if (_options['option${i}_level2'] == true) {
            completedFard++;
          }
          if (_options['option$i'] == true) {
            completedSunnahBefore++;
          }
          if (_options['option${i}_level3'] == true) {
            completedSunnahAfter++;
          }

          // حساب السنن المتاحة
          List<String> levelHints = _getLevelHints(i);
          if (!levelHints[0].contains("لا يوجد")) availableSunnahBefore++;
          if (!levelHints[2].contains("لا يوجد")) availableSunnahAfter++;
        }

        // القرآن
        if (_options['option6'] == true) completedQuran++;
        if (_options['option6_level2'] == true) completedQuran++;
        if (_options['option6_level3'] == true) completedQuran++;

        // قيام الليل
        if (_options['option7'] == true ||
            _options['option7_level2'] == true ||
            _options['option7_level3'] == true) {
          completedNightPrayers++;
        }
        if (_options['option8'] == true) completedNightPrayers++;
        if (_options['option9'] == true) completedNightPrayers++;

        // الأذكار
        if (_options['option10'] == true) completedAthkar++;
        if (_options['option10_level2'] == true) completedAthkar++;
        if (_options['option10_level3'] == true) completedAthkar++;

        // حساب النسبة المئوية للإكمال
        int totalFard = 5;
        int totalSunnah = availableSunnahBefore +
            availableSunnahAfter; // إجمالي السنن المتاحة
        int totalQuran = 3;
        int totalNight = 3;
        int totalAthkar = 3;

        int totalCompleted = completedFard +
            completedSunnahBefore +
            completedSunnahAfter +
            completedQuran +
            completedNightPrayers +
            completedAthkar;
        int totalItems =
            totalFard + totalSunnah + totalQuran + totalNight + totalAthkar;

        int completionRate = ((totalCompleted / totalItems) * 100).round();

        // إنشاء بيانات الأرشيف
        Map<String, dynamic> archiveData = {
          'date': DateTime.now().toIso8601String().split('T')[0],
          'completion_rate': completionRate,
          'fard_completed': completedFard,
          'fard_total': totalFard,
          'sunnah_completed': completedSunnahBefore + completedSunnahAfter,
          'sunnah_total': availableSunnahBefore + availableSunnahAfter,
          'quran_completed': completedQuran,
          'quran_total': totalQuran,
          'night_completed': completedNightPrayers,
          'night_total': totalNight,
          'athkar_completed': completedAthkar,
          'athkar_total': totalAthkar,
        };

        // حفظ البيانات في جدول الأرشيف
        await DatabaseHelper.instance.addWorshipArchive(archiveData);

        if (_isSafeContext && mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم أرشفة بيانات العبادات بنجاح'),
            ),
          );
        }
      } catch (e) {
        print('خطأ أثناء أرشفة بيانات العبادات: $e');

        if (_isSafeContext && mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ أثناء أرشفة بيانات العبادات'),
            ),
          );
        }
      }
    }
  }

  // دالة منفصلة لعرض قائمة الخيارات
  Widget _buildCheckboxes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'العبادات اليومية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // جدول المهام مع المستويات
            Table(
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              columnWidths: const {
                0: FlexColumnWidth(2.5), // عمود العنوان
                1: FlexColumnWidth(1), // المستوى 1
                2: FlexColumnWidth(1), // المستوى 2
                3: FlexColumnWidth(1), // المستوى 3
              },
              children: [
                // صف العناوين
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue.shade50),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'العبادة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'السنة القبلية',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'الفرض',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'السنة البعدية',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),

                // المهمة 1: صلاة الفجر
                _buildTaskTableRow(
                  taskTitle: 'صلاة الفجر',
                  optionKey: 'option1',
                ),

                // المهمة 2: صلاة الظهر
                _buildTaskTableRow(
                  taskTitle: 'صلاة الظهر',
                  optionKey: 'option2',
                ),

                // المهمة 3: صلاة العصر
                _buildTaskTableRow(
                  taskTitle: 'صلاة العصر',
                  optionKey: 'option3',
                ),

                // المهمة 4: صلاة المغرب
                _buildTaskTableRow(
                  taskTitle: 'صلاة المغرب',
                  optionKey: 'option4',
                ),

                // المهمة 5: صلاة العشاء
                _buildTaskTableRow(
                  taskTitle: 'صلاة العشاء',
                  optionKey: 'option5',
                ),

                // المهمة 6: ورد القرآن
                _buildTaskTableRow(
                  taskTitle: 'ورد القرآن',
                  optionKey: 'option6',
                ),

                // المهمة 7: قيام الليل
                _buildTaskTableRow(
                  taskTitle: 'قيام الليل (ساعة)',
                  optionKey: 'option7',
                ),

                // المهمة 8: صلاة التهجد
                _buildTaskTableRow(
                  taskTitle: 'صلاة التهجد',
                  optionKey: 'option8',
                ),

                // المهمة 9: صلاة الوتر
                _buildTaskTableRow(
                  taskTitle: 'صلاة الوتر',
                  optionKey: 'option9',
                ),

                // المهمة 10: الأذكار
                _buildTaskTableRow(
                  taskTitle: '(ثلث)الأذكار اليومية',
                  optionKey: 'option10',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  // إضافة شرح للمستويات
  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _buildLegendItem('أذكار الصلاة',
            ' ستغفر الله، أستغفر الله، أستغفر الله، اللهم أنت السلام، ومنك السلام، تباركت يا ذا الجلال والإكرام\n لا إله إلا الله، وحده لا شريك له، له الملك، وله الحمد، وهو على كل شيء قدير\n سبحان الله، والحمد لله، والله أكبر، ثلاثة وثلاثين مرة، '),
        _buildLegendItem('قيام الليل',
            'افضله قيام داوود عليه السلام ينام نصفه وقوم ثلثه وينام سدسه الاخير '),
        _buildLegendItem(
            'التهجد', ' ركعتان بعد الاستيقاظ من النوم في جوف الليل'),
        _buildLegendItem('الوتر', 'ركعة واحدة قبل النوم'),
      ],
    );
  }

  Widget _buildLegendItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // دالة للحصول على عدد الركعات فقط
  String _getRakaatCount(String hint) {
    if (hint.contains("ركعتان")) {
      return "2";
    } else if (hint.contains("3 ركعات")) {
      return "3";
    } else if (hint.contains("4 ركعات")) {
      return "4";
    } else if (hint.contains("لا يوجد")) {
      return "";
    } else {
      return "";
    }
  }

  // دالة للحصول على توضيحات المستويات حسب رقم المهمة
  List<String> _getLevelHints(int taskNumber) {
    if (taskNumber == 1) {
      // صلاة الفجر
      return ["ركعتان قبل الفرض", "الفرض (ركعتان)", "لا يوجد سنة بعدية"];
    } else if (taskNumber == 2) {
      // صلاة الظهر
      return ["4 ركعات قبل الفرض", "الفرض (4 ركعات)", "ركعتان بعد الفرض"];
    } else if (taskNumber == 3) {
      // صلاة العصر
      return ["4 ركعات قبل الفرض", "الفرض (4 ركعات)", "لا يوجد سنة بعدية"];
    } else if (taskNumber == 4) {
      // صلاة المغرب
      return ["لا يوجد سنة قبلية", "الفرض (3 ركعات)", "ركعتان بعد الفرض"];
    } else if (taskNumber == 5) {
      // صلاة العشاء
      return ["لا يوجد سنة قبلية", "الفرض (4 ركعات)", "ركعتان بعد الفرض"];
    } else if (taskNumber == 6) {
      // ورد القرآن
      return ["آية", "صفحة", "جزء"];
    } else if (taskNumber == 7) {
      // قيام الليل
      return ["1 ساعة", "2 ساعة", "4 ساعات"];
    } else if (taskNumber == 8) {
      // صلاة التهجد
      return ["التهجد", "غير متاح", "غير متاح"];
    } else if (taskNumber == 9) {
      // صلاة الوتر
      return ["الوتر", "غير متاح", "غير متاح"];
    } else {
      // الأذكار
      return ["أذكار الصباح", "أذكار المساء", "أذكار النوم"];
    }
  }

  // بناء صف في جدول المهام
  TableRow _buildTaskTableRow({
    required String taskTitle,
    required String optionKey,
  }) {
    // تحديد نوع المهمة للتمييز بالألوان
    final taskNumber = int.tryParse(optionKey.replaceAll('option', '')) ?? 0;
    Color rowColor;

    if (taskNumber <= 5) {
      // الصلوات الخمس باللون الأخضر الفاتح
      rowColor = Colors.green.shade50;
    } else if (taskNumber == 6) {
      // ورد القرآن باللون الأزرق الفاتح
      rowColor = Colors.blue.shade50;
    } else if (taskNumber >= 7 && taskNumber <= 9) {
      // صلوات الليل باللون البنفسجي الفاتح
      rowColor = Colors.purple.shade50;
    } else {
      // الأذكار باللون البرتقالي الفاتح
      rowColor = Colors.orange.shade50;
    }

    // تحديد حالة المهمة (مكتملة أم لا)
    final isLevel1Complete = _options[optionKey] ?? false;
    final isLevel2Complete = _options['${optionKey}_level2'] ?? false;
    final isLevel3Complete = _options['${optionKey}_level3'] ?? false;

    // نص المستويات حسب نوع العبادة
    List<String> levelHints = _getLevelHints(taskNumber);

    // تحديد ما إذا كان يوجد صلاة في كل مستوى
    bool hasLevel1 = !levelHints[0].contains("لا يوجد");
    bool hasLevel2 = !levelHints[1].contains("غير متاح");
    bool hasLevel3 = !levelHints[2].contains("لا يوجد") &&
        !levelHints[2].contains("غير متاح");

    // استخراج النص المناسب لكل مستوى
    String textLevel1 = "";
    String textLevel2 = "";
    String textLevel3 = "";

    if (taskNumber <= 5) {
      // الصلوات الخمس: عرض عدد الركعات
      textLevel1 = _getRakaatCount(levelHints[0]);
      textLevel2 = _getRakaatCount(levelHints[1]);
      textLevel3 = _getRakaatCount(levelHints[2]);
    } else if (taskNumber == 6) {
      // ورد القرآن: عرض آية/ص/ج
      textLevel1 = "ا";
      textLevel2 = "ص";
      textLevel3 = "ج";
    } else if (taskNumber == 7) {
      // قيام الليل: عرض ساعات
      textLevel1 = "1";
      textLevel2 = "2";
      textLevel3 = "4";
    } else if (taskNumber == 8) {
      // صلاة التهجد
      textLevel1 = "";
      textLevel2 = "";
      textLevel3 = "";
    } else if (taskNumber == 9) {
      // صلاة الوتر
      textLevel1 = "";
      textLevel2 = "";
      textLevel3 = "";
    } else if (taskNumber == 10) {
      // الأذكار
      textLevel1 = "1";
      textLevel2 = "2";
      textLevel3 = "3";
    }

    // أيقونة لنوع الصلاة
    IconData taskIcon = Icons.star_border;
    if (taskNumber <= 5) {
      taskIcon = Icons.access_time; // للصلوات
    } else if (taskNumber == 6) {
      taskIcon = Icons.menu_book; // للقرآن
    } else if (taskNumber >= 7 && taskNumber <= 9) {
      taskIcon = Icons.nightlight_round; // لصلاة الليل
    } else {
      taskIcon = Icons.speaker_notes; // للأذكار
    }

    return TableRow(
      decoration: BoxDecoration(
        color: rowColor,
      ),
      children: [
        // عنوان المهمة
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(
                taskIcon,
                size: 16,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  taskTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isLevel1Complete ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),

        // المستوى 1 - السنة القبلية
        hasLevel1
            ? Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _options[optionKey] ?? false,
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        _updateOption(optionKey, value ?? false);
                      },
                    ),
                    Text(
                      textLevel1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isLevel1Complete ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : const Center(
                child: Text("-", style: TextStyle(color: Colors.grey))),

        // المستوى 2 - الفرض
        hasLevel2
            ? Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _options['${optionKey}_level2'] ?? false,
                      activeColor: Colors.orange,
                      onChanged: (value) {
                        _updateOption('${optionKey}_level2', value ?? false);
                      },
                    ),
                    Text(
                      textLevel2,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isLevel2Complete ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : const Center(
                child: Text("-", style: TextStyle(color: Colors.grey))),

        // المستوى 3 - السنة البعدية
        hasLevel3
            ? Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _options['${optionKey}_level3'] ?? false,
                      activeColor: Colors.purple,
                      onChanged: (value) {
                        _updateOption('${optionKey}_level3', value ?? false);
                      },
                    ),
                    Text(
                      textLevel3,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isLevel3Complete ? Colors.purple : Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : const Center(
                child: Text("-", style: TextStyle(color: Colors.grey))),
      ],
    );
  }

  void _updateOption(String key, bool value) {
    setState(() {
      _options[key] = value;
      _hasChanges = true; // تعيين المتغير إلى true عند حدوث تغيير
    });
  }

  // بناء صندوق الاختيار
  Widget _buildCheckbox(String key, String title, bool? isTristate) {
    bool isChecked = _options[key] ?? false;
    return CheckboxListTile(
      title: Text(title),
      value: isChecked,
      tristate: isTristate ?? false,
      onChanged: (value) {
        _updateOption(key, value ?? false);
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
