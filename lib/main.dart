import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'database/database_helper.dart';
import 'screens/options_screen.dart';
import 'screens/database_admin_screen.dart';
import 'screens/thoughts_journal_screen.dart';
import 'screens/archive_screen.dart';

void main() async {
  // ضمان تهيئة Flutter Engine بشكل كامل قبل استخدام أي قناة بين Flutter و Platform
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق المسلم',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        '/options': (context) => const OptionsScreen(),
        '/database_admin': (context) => const DatabaseAdminScreen(),
        '/thoughts_journal': (context) => const ThoughtsJournalScreen(),
        '/archive': (context) => const ArchiveScreen(),
      },
    );
  }
}
