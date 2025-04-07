import 'package:flutter/material.dart';
import '../database/database_helper.dart';

// لا يمكن استخدام CityData من home_screen.dart لأنه لا يحتوي على دالة toMap()
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'timeZoneOffset': timeZoneOffset,
    };
  }

  factory CityData.fromMap(Map<String, dynamic> map) {
    return CityData(
      id: map['id'] as int?,
      name: map['name'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timeZoneOffset: map['time_zone_offset'] as double,
    );
  }
}

class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({Key? key}) : super(key: key);

  @override
  State<LocationManagementScreen> createState() =>
      _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  List<Map<String, dynamic>> _allCities = [];
  bool _isLoading = true;
  String _databaseInfo = '';

  @override
  void initState() {
    super.initState();
    _loadCities();
    _loadDatabaseInfo();
  }

  // تحميل معلومات قاعدة البيانات
  Future<void> _loadDatabaseInfo() async {
    try {
      // قم بجلب معلومات قاعدة البيانات
      final cities = await DatabaseHelper.instance.getDefaultCities();
      setState(() {
        _databaseInfo = 'عدد المواقع في قاعدة البيانات: ${cities.length}';
      });
    } catch (e) {
      print('خطأ أثناء تحميل معلومات قاعدة البيانات: $e');
    }
  }

  // تحميل جميع المدن من قاعدة البيانات
  Future<void> _loadCities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cities = await DatabaseHelper.instance.getDefaultCities();
      setState(() {
        _allCities = cities;
        _isLoading = false;
      });

      await _loadDatabaseInfo();
      print('تم تحميل ${_allCities.length} مدينة من قاعدة البيانات');
    } catch (e) {
      print('خطأ أثناء تحميل المدن: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل المدن');
    }
  }

  // حذف مدينة
  Future<void> _deleteCity(int id) async {
    try {
      await DatabaseHelper.instance.deleteDefaultCity(id);
      _showSuccessSnackBar('تم حذف المدينة بنجاح');
      _loadCities();
    } catch (e) {
      print('خطأ أثناء حذف المدينة: $e');
      _showErrorSnackBar('حدث خطأ أثناء حذف المدينة');
    }
  }

  // إضافة موقع جديد
  void _showAddLocationDialog() {
    final _nameController = TextEditingController();
    final _latitudeController = TextEditingController();
    final _longitudeController = TextEditingController();
    final _timeZoneOffsetController = TextEditingController(text: '3.0');
    //String errorMessage = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة موقع جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المدينة',
                    hintText: 'مثال: مدينتي',
                  ),
                  textAlign: TextAlign.right,
                ),
                TextField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(
                    labelText: 'خط العرض',
                    hintText: 'مثال: 21.3891',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(
                    labelText: 'خط الطول',
                    hintText: 'مثال: 39.8579',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: _timeZoneOffsetController,
                  decoration: const InputDecoration(
                    labelText: 'فارق التوقيت',
                    hintText: 'مثال: 3.0',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ملاحظة: يمكنك الحصول على إحداثيات موقعك من خرائط Google.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
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
                _addNewLocation(
                  _nameController.text.trim(),
                  _latitudeController.text.trim(),
                  _longitudeController.text.trim(),
                  double.parse(_timeZoneOffsetController.text),
                );
                Navigator.of(context).pop();
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  // إضافة موقع جديد
  Future<void> _addNewLocation(
    String name,
    String latitudeStr,
    String longitudeStr,
    double timeZoneOffset,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // التحقق من صحة البيانات
      if (name.isEmpty) {
        _showErrorSnackBar('يرجى إدخال اسم المدينة');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // تحويل الإحداثيات إلى أرقام
      double? latitude = double.tryParse(latitudeStr);
      double? longitude = double.tryParse(longitudeStr);

      if (latitude == null || longitude == null) {
        _showErrorSnackBar('يرجى إدخال إحداثيات صحيحة');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // التحقق من صحة الإحداثيات
      if (latitude < -90 || latitude > 90) {
        _showErrorSnackBar('خط العرض يجب أن يكون بين -90 و 90');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (longitude < -180 || longitude > 180) {
        _showErrorSnackBar('خط الطول يجب أن يكون بين -180 و 180');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // إنشاء كائن المدينة الجديدة
      CityData newCity = CityData(
        name: name,
        latitude: latitude,
        longitude: longitude,
        timeZoneOffset: timeZoneOffset,
      );

      // حفظ في جدول المدن الافتراضية
      await DatabaseHelper.instance.addDefaultCity(newCity.toMap());

      // إعادة تحميل المدن
      await _loadCities();

      _showSuccessSnackBar('تمت إضافة $name بنجاح');
    } catch (e) {
      print('خطأ أثناء إضافة الموقع: $e');
      _showErrorSnackBar('حدث خطأ أثناء إضافة الموقع: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // عرض رسالة خطأ
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // عرض رسالة نجاح
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
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
        title: const Text('إدارة المواقع'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCities,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCities,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات قاعدة البيانات
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_city,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'معلومات قاعدة البيانات',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_databaseInfo),
                          const SizedBox(height: 4),
                          Text('عدد المواقع المعروضة: ${_allCities.length}'),
                          const Text(
                              'ملاحظة: يتم استخدام هذه المواقع لحساب أوقات الصلاة')
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // عنوان الصفحة
                    Row(
                      children: [
                        Icon(Icons.list, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'قائمة المواقع',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // قائمة المواقع
                    _allCities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'لا توجد مواقع مضافة بعد',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _showAddLocationDialog,
                                  icon: const Icon(Icons.add_location),
                                  label: const Text('إضافة موقع جديد'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildCitiesList(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLocationDialog,
        tooltip: 'إضافة موقع جديد',
        icon: const Icon(Icons.add_location),
        label: const Text('إضافة موقع'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // بناء قائمة المدن
  Widget _buildCitiesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_allCities.isEmpty) {
      return const Center(
        child: Text('لا توجد مدن مضافة بعد.'),
      );
    }

    return ListView.builder(
      itemCount: _allCities.length,
      itemBuilder: (context, index) {
        final city = _allCities[index];
        final cityId = city['id'] ?? 'غير معروف';

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text('${city['name']} (معرف: $cityId)'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('خط العرض: ${city['latitude']}'),
                Text('خط الطول: ${city['longitude']}'),
                Text('فارق التوقيت: ${city['time_zone_offset']} ساعة'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: () {
                    _setAsDefault(city['id']);
                  },
                  tooltip: 'تعيين كموقع افتراضي',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _deleteCity(city['id']);
                  },
                  tooltip: 'حذف المدينة',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // تعيين المدينة كموقع افتراضي
  Future<void> _setAsDefault(int cityId) async {
    try {
      await DatabaseHelper.instance.setDefaultLocationById(cityId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تعيين المدينة كموقع افتراضي بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('خطأ في تعيين الموقع الافتراضي: $e');
    }
  }
}
