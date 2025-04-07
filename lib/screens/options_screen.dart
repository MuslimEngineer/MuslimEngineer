import 'package:flutter/material.dart';
import 'package:template/database/database_helper.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({Key? key}) : super(key: key);

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  Map<String, bool> options = {};
  bool isLoading = true;
  String dbInfo = '';

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _checkDatabaseStructure(); // دالة لفحص هيكل قاعدة البيانات
  }

  // فحص هيكل قاعدة البيانات
  Future<void> _checkDatabaseStructure() async {
    try {
      // فحص هيكل جدول الخيارات
      await DatabaseHelper.instance.checkOptionsTableStructure();

      // إذا كان هناك مشاكل، قم بإعادة إنشاء الجدول
      await DatabaseHelper.instance.recreateOptionsTable();

      // إعادة تحميل الخيارات بعد الإصلاح
      await _loadOptions();
    } catch (e) {
      print('خطأ أثناء فحص وإصلاح هيكل قاعدة البيانات: $e');
    }
  }

  // تحميل الخيارات من قاعدة البيانات
  Future<void> _loadOptions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final info = await DatabaseHelper.instance.getDatabaseInfo();
      final loadedOptions = await DatabaseHelper.instance.getOptions();

      setState(() {
        options = loadedOptions;
        dbInfo = 'الموقع: ${info['location']}\n'
            'الحجم: ${info['size']}\n'
            'آخر تعديل: ${info['lastModified']}';
        isLoading = false;
      });

      print('تم تحميل الخيارات: $options');
    } catch (e) {
      print('خطأ في تحميل الخيارات: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // حفظ الخيارات في قاعدة البيانات
  Future<void> _saveOptions() async {
    setState(() {
      isLoading = true;
    });

    try {
      await DatabaseHelper.instance.updateOptions(options);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الخيارات بنجاح')),
      );
    } catch (e) {
      print('خطأ أثناء الحفظ: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الحفظ: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // إضافة دالة لإعادة تعيين الخيارات
  Future<void> _resetOptions() async {
    setState(() {
      isLoading = true;
    });

    try {
      await DatabaseHelper.instance.resetOptions();
      await _loadOptions(); // إعادة تحميل الخيارات بعد إعادة التعيين
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إعادة تعيين الخيارات بنجاح')),
      );
    } catch (e) {
      print('خطأ أثناء إعادة التعيين: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء إعادة التعيين: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخيارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetOptions,
            tooltip: 'إعادة تعيين الخيارات',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بطاقة معلومات قاعدة البيانات
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'معلومات قاعدة البيانات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(dbInfo),
                        ],
                      ),
                    ),
                  ),

                  // الخيارات
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الخيارات المتقدمة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...options.entries.map((entry) {
                            bool isSubOption = entry.key.contains('_level');
                            String displayName = entry.key
                                .replaceAll('_level2', ' (المستوى الثاني)')
                                .replaceAll('_level3', ' (المستوى الثالث)');
                            return Padding(
                              padding: EdgeInsets.only(
                                left: isSubOption ? 32.0 : 0.0,
                                bottom: 8.0,
                              ),
                              child: SwitchListTile(
                                title: Text(displayName),
                                value: entry.value,
                                onChanged: (value) {
                                  setState(() {
                                    options[entry.key] = value;
                                  });
                                },
                                dense: isSubOption,
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveOptions,
        child: const Icon(Icons.save),
        tooltip: 'حفظ الخيارات',
      ),
    );
  }
}
