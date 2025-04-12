import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'database/database_helper.dart';
import 'screens/options_screen.dart';
import 'screens/database_admin_screen.dart';
import 'screens/thoughts_journal_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/islamic_info_screen.dart';
import 'theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // ضمان تهيئة Flutter Engine بشكل كامل قبل استخدام أي قناة بين Flutter و Platform
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة تنسيق التواريخ العربية
  await initializeDateFormatting('ar', null);

  // التحقق من قاعدة البيانات وإصلاحها قبل تشغيل التطبيق
  try {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.checkOptionsTableStructure();
    await dbHelper.recreateOptionsTable();
    print('تم التحقق من قاعدة البيانات وإصلاحها عند بدء التطبيق');
  } catch (e) {
    print('خطأ أثناء التحقق من قاعدة البيانات عند بدء التطبيق: $e');
  }

  // تهيئة قاعدة البيانات
  await DatabaseHelper.instance.database;

  // تحقق مما إذا كان المستخدم قد فتح التطبيق من قبل
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(MyApp(isFirstLaunch: isFirstLaunch, isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isFirstLaunch;
  final bool isDarkMode;

  const MyApp({super.key, required this.isFirstLaunch, required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  // تغيير وضع السمة
  void toggleThemeMode() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    
    // حفظ إعداد السمة
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // إزالة شريط التصحيح
      title: 'تطبيق المهندس المسلم',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''), // Arabic
      ],
      locale: const Locale('ar', ''),
      home: widget.isFirstLaunch ? 
        WelcomeScreen(onBoardingComplete: () async {
          // تحديث حالة التشغيل الأول
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isFirstLaunch', false);
          
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => HomeScreen(toggleTheme: toggleThemeMode, isDarkMode: _isDarkMode)),
            );
          }
        }) : 
        HomeScreen(toggleTheme: toggleThemeMode, isDarkMode: _isDarkMode),
      routes: {
        '/home': (context) => HomeScreen(toggleTheme: toggleThemeMode, isDarkMode: _isDarkMode),
        '/options': (context) => const OptionsScreen(),
        '/database_admin': (context) => const DatabaseAdminScreen(),
        '/thoughts_journal': (context) => const ThoughtsJournalScreen(),
        '/archive': (context) => const ArchiveScreen(),
        '/quran': (context) => const QuranScreen(),
        '/islamic_info': (context) => const IslamicInfoScreen(),
      },
    );
  }
}
