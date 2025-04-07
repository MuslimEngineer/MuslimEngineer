import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  // دالة تهيئة قاعدة البيانات وفحصها
  Future<void> _initDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // فحص هيكل جدول الخيارات
      await DatabaseHelper.instance.checkOptionsTableStructure();

      // إصلاح هيكل الجدول إذا كان هناك مشكلة
      await DatabaseHelper.instance.recreateOptionsTable();

      print('تم التحقق من قاعدة البيانات وإصلاحها بنجاح');
    } catch (e) {
      print('خطأ أثناء تهيئة قاعدة البيانات: $e');
    } finally {
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
        title: const Text('الصفحة الرئيسية'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'مرحباً بك في التطبيق',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/tasks');
                    },
                    child: const Text('المهام اليومية'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/options');
                    },
                    child: const Text('الخيارات'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // إعادة تهيئة قاعدة البيانات
                        await DatabaseHelper.instance.resetOptions();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('تم إعادة تعيين قاعدة البيانات بنجاح')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطأ: $e')),
                        );
                      }
                    },
                    child: const Text('إعادة تعيين الخيارات'),
                  ),
                ],
              ),
            ),
    );
  }
}
