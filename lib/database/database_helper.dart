import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // اسم جداول قاعدة البيانات
  static const String optionsTable = 'options';
  static const String dailyTasksTable = 'daily_tasks';
  static const String taskOptionsTable = 'task_options';
  static const String worshipArchiveTable = 'worship_archive';
  static const String dailyTasksArchiveTable = 'daily_tasks_archive';
  static const String locationsTable = 'locations';
  static const String defaultLocationTable = 'default_location';
  static const String thoughtsTable = 'thoughts_journal';
  static const String athkarTable = 'athkar'; // جدول الأذكار
  static const String hadithsTable = 'hadiths'; // جدول الأحاديث
  static const String quranDuaTable = 'quran_dua'; // جدول أدعية القرآن
  static const String prayerTimesTable = 'prayer_times';
  static const String qiblaTable = 'qibla'; // جدول القبلة
  static const String dailyMessagesTable =
      'daily_messages'; // جدول الرسائل اليومية
  static const String surahsTable = 'surahs';
  static const String surahsTableCreate = '''
    CREATE TABLE $surahsTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      number INTEGER NOT NULL,
      name TEXT NOT NULL,
      verses_count INTEGER NOT NULL,
      revelation_place TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  DatabaseHelper._init();

  Future<Database> get database async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app.db');

    if (_database != null) return _database!;

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $optionsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            value INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $dailyTasksTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            task_type INTEGER NOT NULL DEFAULT 0,
            completed INTEGER NOT NULL DEFAULT 0,
            in_progress INTEGER NOT NULL DEFAULT 0,
            is_archived INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // إنشاء جدول الأفكار
        await db.execute('''
          CREATE TABLE ideas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            type INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            is_archive INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE $worshipArchiveTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            completion_rate INTEGER NOT NULL,
            fard_completed INTEGER NOT NULL,
            fard_total INTEGER NOT NULL,
            sunnah_completed INTEGER NOT NULL,
            sunnah_total INTEGER NOT NULL,
            quran_completed INTEGER NOT NULL,
            quran_total INTEGER NOT NULL,
            night_completed INTEGER NOT NULL,
            night_total INTEGER NOT NULL,
            athkar_completed INTEGER NOT NULL,
            athkar_total INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $dailyTasksArchiveTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            total_tasks INTEGER NOT NULL,
            completed_tasks INTEGER NOT NULL,
            in_progress_tasks INTEGER NOT NULL,
            in_progress_percentage INTEGER NOT NULL,
            completion_percentage INTEGER NOT NULL,
            worldly_total INTEGER NOT NULL,
            worldly_completed INTEGER NOT NULL,
            religious_total INTEGER NOT NULL,
            religious_completed INTEGER NOT NULL,
            both_total INTEGER NOT NULL,
            both_completed INTEGER NOT NULL,
            details TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $locationsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            time_zone_offset REAL NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $defaultLocationTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            location_id INTEGER NOT NULL,
            FOREIGN KEY (location_id) REFERENCES $locationsTable (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE $thoughtsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            date TEXT NOT NULL,
            is_archived INTEGER NOT NULL DEFAULT 0,
            category INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $athkarTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL
          )
        ''');

        // إنشاء جدول الأحاديث
        await db.execute('''
          CREATE TABLE $hadithsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            narrator TEXT NOT NULL,
            topic TEXT NOT NULL
          )
        ''');

        // إنشاء جدول أدعية القرآن
        await db.execute('''
          CREATE TABLE $quranDuaTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            source TEXT NOT NULL,
            theme TEXT NOT NULL
          )
        ''');

        // إدراج أذكار افتراضية
        await _insertDefaultAthkar(db);

        // إدراج أحاديث افتراضية
        await _insertDefaultHadiths(db);

        // إدراج أدعية القرآن الافتراضية
        await _insertDefaultQuranDua(db);

        // إنشاء جدول القبلة
        await db.execute('''
          CREATE TABLE $qiblaTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            location_id INTEGER NOT NULL,
            qibla_direction REAL NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (location_id) REFERENCES $locationsTable (id) ON DELETE CASCADE
          )
        ''');

        // إنشاء جدول أوقات الصلاة
        await db.execute('''
CREATE TABLE $prayerTimesTable(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  location_id INTEGER,
  fajr TEXT NOT NULL,
  sunrise TEXT NOT NULL,
  dhuhr TEXT NOT NULL,
  asr TEXT NOT NULL,
  maghrib TEXT NOT NULL,
  isha TEXT NOT NULL,
  UNIQUE(date, location_id),
  FOREIGN KEY (location_id) REFERENCES $locationsTable (id) ON DELETE SET NULL
)
''');

        // إنشاء جدول الرسائل اليومية
        await db.execute('''
          CREATE TABLE $dailyMessagesTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            category TEXT NOT NULL,
            source TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onOpen: (db) async {
        try {
          // التحقق من وجود جدول المهام وإنشائه إذا لم يكن موجودًا

          // التحقق من وجود جدول الرسائل اليومية وإنشائه إذا لم يكن موجوداً
          final dailyMessagesTableExists = await db.query(
            'sqlite_master',
            where: 'type = ? AND name = ?',
            whereArgs: ['table', DatabaseHelper.dailyMessagesTable],
          );

          if (dailyMessagesTableExists.isEmpty) {
            await db.execute('''
              CREATE TABLE ${DatabaseHelper.dailyMessagesTable} (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                category TEXT NOT NULL,
                source TEXT NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');
            print('تم إنشاء جدول الرسائل اليومية بنجاح');
          }

          // التحقق من وجود جدول المواقع وإنشائه إذا لم يكن موجودًا
          final locationsTableExists = await db.query(
            'sqlite_master',
            where: 'type = ? AND name = ?',
            whereArgs: ['table', DatabaseHelper.locationsTable],
          );

          if (locationsTableExists.isEmpty) {
            await db.execute('''
              CREATE TABLE ${DatabaseHelper.locationsTable} (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                time_zone_offset REAL NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');
          }

          // إضافة مواقع افتراضية إذا كان الجدول فارغًا
          final locationCount = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM ${DatabaseHelper.locationsTable}'));
          if (locationCount == 0) {
            final now = DateTime.now().toIso8601String();
            await db.insert(DatabaseHelper.locationsTable, {
              'name': 'مكة المكرمة',
              'latitude': 21.4225,
              'longitude': 39.8262,
              'time_zone_offset': 3.0,
              'created_at': now,
            });
            await db.insert(DatabaseHelper.locationsTable, {
              'name': 'المدينة المنورة',
              'latitude': 24.5247,
              'longitude': 39.5692,
              'time_zone_offset': 3.0,
              'created_at': now,
            });
            await db.insert(DatabaseHelper.locationsTable, {
              'name': 'الرياض',
              'latitude': 24.7136,
              'longitude': 46.6753,
              'time_zone_offset': 3.0,
              'created_at': now,
            });
            await db.insert(DatabaseHelper.locationsTable, {
              'name': 'جدة',
              'latitude': 21.4858,
              'longitude': 39.1925,
              'time_zone_offset': 3.0,
              'created_at': now,
            });
          }

          // التحقق من وجود جدول الموقع الافتراضي وإنشائه إذا لم يكن موجودًا
          final defaultLocationTableExists = await db.query(
            'sqlite_master',
            where: 'type = ? AND name = ?',
            whereArgs: ['table', DatabaseHelper.defaultLocationTable],
          );

          if (defaultLocationTableExists.isEmpty) {
            await db.execute('''
              CREATE TABLE ${DatabaseHelper.defaultLocationTable} (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                location_id INTEGER NOT NULL,
                FOREIGN KEY (location_id) REFERENCES ${DatabaseHelper.locationsTable} (id) ON DELETE CASCADE
              )
            ''');
          }

          // التحقق من وجود موقع افتراضي وإنشائه إذا لم يكن موجودًا
          final defaultLocationCount = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM ${DatabaseHelper.defaultLocationTable}'));
          if (defaultLocationCount == 0) {
            // البحث عن مكة المكرمة في جدول المواقع
            final makkahLocation = await db.query(
              DatabaseHelper.locationsTable,
              where: 'name = ?',
              whereArgs: ['مكة المكرمة'],
              limit: 1,
            );

            if (makkahLocation.isNotEmpty) {
              // إذا وجدنا مكة المكرمة، نستخدمها كموقع افتراضي
              await db.insert(DatabaseHelper.defaultLocationTable, {
                'location_id': makkahLocation.first['id'],
              });
            } else {
              // إذا لم نجد مكة المكرمة، نستخدم أول موقع متاح
              final anyLocation = await db.query(
                DatabaseHelper.locationsTable,
                limit: 1,
              );

              if (anyLocation.isNotEmpty) {
                await db.insert(DatabaseHelper.defaultLocationTable, {
                  'location_id': anyLocation.first['id'],
                });
              }
            }
          }

          // التحقق من وجود جدول الخواطر وإنشائه إذا لم يكن موجوداً
          final thoughtsTableExists = await db.query(
            'sqlite_master',
            where: 'type = ? AND name = ?',
            whereArgs: ['table', DatabaseHelper.thoughtsTable],
          );

          if (thoughtsTableExists.isEmpty) {
            await db.execute('''
              CREATE TABLE ${DatabaseHelper.thoughtsTable} (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                date TEXT NOT NULL,
                is_archived INTEGER NOT NULL DEFAULT 0,
                category INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL
              )
            ''');
          } else {
            // التحقق من وجود عمود category في الجدول
            final tableInfo = await db
                .rawQuery('PRAGMA table_info(${DatabaseHelper.thoughtsTable})');
            bool hasCategoryColumn =
                tableInfo.any((column) => column['name'] == 'category');

            if (!hasCategoryColumn) {
              // إضافة عمود category إلى الجدول إذا لم يكن موجوداً
              await db.execute(
                  'ALTER TABLE ${DatabaseHelper.thoughtsTable} ADD COLUMN category INTEGER NOT NULL DEFAULT 0');
            }
          }
        } catch (e) {
          print('خطأ أثناء التحقق من الجداول وإنشائها: $e');
        }
      },
    );

    return _database!;
  }

  // دالة للتحقق من وجود جدول في قاعدة البيانات
  Future<bool> _checkIfTableExists(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  // إنشاء جدول أرشيف العبادات إذا لم يكن موجودًا
  Future<void> _ensureWorshipArchiveTableExists(Database db) async {
    final worshipArchiveTableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$worshipArchiveTable'");

    if (worshipArchiveTableCheck.isEmpty) {
      print('جدول أرشيف العبادات غير موجود، جاري إنشاؤه...');
      await db.execute('''
        CREATE TABLE $worshipArchiveTable(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          completion_rate INTEGER NOT NULL,
          fard_completed INTEGER NOT NULL,
          fard_total INTEGER NOT NULL,
          sunnah_completed INTEGER NOT NULL,
          sunnah_total INTEGER NOT NULL,
          quran_completed INTEGER NOT NULL,
          quran_total INTEGER NOT NULL,
          night_completed INTEGER NOT NULL,
          night_total INTEGER NOT NULL,
          athkar_completed INTEGER NOT NULL,
          athkar_total INTEGER NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  // إنشاء جدول أرشيف الأهداف اليومية إذا لم يكن موجودًا
  Future<void> _ensureTasksArchiveTableExists(Database db) async {
    final tasksArchiveTableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$dailyTasksArchiveTable'");

    if (tasksArchiveTableCheck.isEmpty) {
      print('جدول أرشيف المهام غير موجود، جاري إنشاؤه...');
      await db.execute('''
        CREATE TABLE $dailyTasksArchiveTable(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          total_tasks INTEGER NOT NULL DEFAULT 0,
          completed_tasks INTEGER NOT NULL DEFAULT 0,
          in_progress_tasks INTEGER NOT NULL DEFAULT 0,
          in_progress_percentage INTEGER NOT NULL DEFAULT 0,
          completion_percentage INTEGER NOT NULL DEFAULT 0,
          worldly_total INTEGER NOT NULL DEFAULT 0,
          worldly_completed INTEGER NOT NULL DEFAULT 0,
          religious_total INTEGER NOT NULL DEFAULT 0,
          religious_completed INTEGER NOT NULL DEFAULT 0,
          both_total INTEGER NOT NULL DEFAULT 0,
          both_completed INTEGER NOT NULL DEFAULT 0,
          details TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  // إنشاء جدول أرشيف الأفكار إذا لم يكن موجودًا
  Future<void> _ensureIdeasArchiveTableExists(Database db) async {
    final ideasArchiveTableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='ideas_archive'");

    if (ideasArchiveTableCheck.isEmpty) {
      print('جدول أرشيف الأفكار غير موجود، جاري إنشاؤه...');
      await db.execute('''
        CREATE TABLE ideas_archive(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          category TEXT,
          created_at TEXT NOT NULL,
          is_archived INTEGER NOT NULL DEFAULT 1
        )
      ''');
    }

    // إنشاء جدول بنك الأفكار إذا لم يكن موجودًا
    final ideasBankTableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='ideas_bank'");

    if (ideasBankTableCheck.isEmpty) {
      print('جدول بنك الأفكار غير موجود، جاري إنشاؤه...');
      await db.execute('''
        CREATE TABLE ideas_bank(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          category TEXT,
          created_at TEXT NOT NULL,
          is_archived INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
  }

  // إضافة سجل جديد إلى أرشيف العبادات
  Future<int> addWorshipArchive(Map<String, dynamic> archive) async {
    final db = await database;
    archive['created_at'] = DateTime.now().toIso8601String();
    return await db.insert(worshipArchiveTable, archive);
  }

  // الحصول على أرشيف العبادات
  Future<List<Map<String, dynamic>>> getWorshipArchive() async {
    final db = await database;
    return await db.query(
      worshipArchiveTable,
      orderBy: 'created_at DESC',
    );
  }

  // حذف سجل من أرشيف العبادات
  Future<int> deleteWorshipArchive(int id) async {
    final db = await database;
    return await db.delete(
      worshipArchiveTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // إضافة سجل جديد إلى أرشيف المهام
  Future<int> addDailyTasksArchive(Map<String, dynamic> archive) async {
    final db = await database;
    archive['created_at'] = DateTime.now().toIso8601String();
    return await db.insert(dailyTasksArchiveTable, archive);
  }

  // الحصول على أرشيف المهام
  Future<List<Map<String, dynamic>>> getDailyTasksArchive() async {
    final db = await database;
    return await db.query(
      dailyTasksArchiveTable,
      orderBy: 'created_at DESC',
    );
  }

  // حذف سجل من أرشيف المهام
  Future<int> deleteDailyTasksArchive(int id) async {
    final db = await database;
    return await db.delete(
      dailyTasksArchiveTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // إضافة سجل جديد إلى أرشيف الأفكار
  Future<int> addIdeaToArchive(Map<String, dynamic> idea) async {
    final db = await database;
    idea['created_at'] = DateTime.now().toIso8601String();
    idea['is_archived'] = 1;
    return await db.insert('ideas_archive', idea);
  }

  // إضافة سجل جديد إلى بنك الأفكار
  Future<int> addIdeaToBank(Map<String, dynamic> idea) async {
    final db = await database;
    idea['created_at'] = DateTime.now().toIso8601String();
    idea['is_archived'] = 0;
    return await db.insert('ideas_bank', idea);
  }

  // الحصول على أرشيف الأفكار
  Future<List<Map<String, dynamic>>> getIdeasArchive() async {
    final db = await database;
    return await db.query(
      'ideas_archive',
      where: 'is_archived = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
  }

  // الحصول على بنك الأفكار
  Future<List<Map<String, dynamic>>> getIdeasBank() async {
    final db = await database;
    return await db.query(
      'ideas_bank',
      where: 'is_archived = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
  }

  // نقل فكرة من بنك الأفكار إلى الأرشيف
  Future<int> moveIdeaToBankToArchive(int id) async {
    final db = await database;
    final idea = await db.query(
      'ideas_bank',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (idea.isNotEmpty) {
      final ideaData = Map<String, dynamic>.from(idea.first);
      ideaData.remove('id');
      ideaData['is_archived'] = 1;
      ideaData['created_at'] = DateTime.now().toIso8601String();

      await db.insert('ideas_archive', ideaData);
      return await db.delete(
        'ideas_bank',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return 0;
  }

  // نقل فكرة من الأرشيف إلى بنك الأفكار
  Future<int> moveIdeaFromArchiveToBank(int id) async {
    final db = await database;
    final idea = await db.query(
      'ideas_archive',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (idea.isNotEmpty) {
      final ideaData = Map<String, dynamic>.from(idea.first);
      ideaData.remove('id');
      ideaData['is_archived'] = 0;
      ideaData['created_at'] = DateTime.now().toIso8601String();

      await db.insert('ideas_bank', ideaData);
      return await db.delete(
        'ideas_archive',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return 0;
  }

  // حذف فكرة في أرشيف الأفكار
  Future<int> deleteIdea(int id, bool fromArchive) async {
    final db = await database;
    if (fromArchive) {
      return await db.delete(
        'ideas_archive',
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      return await db.delete(
        'ideas_bank',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // البحث عن الأفكار
  Future<List<Map<String, dynamic>>> searchIdeas(String query) async {
    final db = await database;
    return await db.query(
      'ideas_bank',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
  }

  // الحصول على جميع المواقع
  Future<List<Map<String, dynamic>>> getLocations() async {
    final db = await database;
    return await db.query(locationsTable);
  }

  // الحصول على الموقع الافتراضي
  Future<Map<String, dynamic>?> getDefaultLocation() async {
    final db = await database;

    try {
      // لطباعة معلومات التصحيح
      print('جاري البحث عن الموقع الافتراضي...');

      final defaultLocations = await db.query(defaultLocationTable, limit: 1);

      if (defaultLocations.isEmpty) {
        print('لم يتم العثور على موقع افتراضي في جدول $defaultLocationTable');
        return null;
      }

      final locationId = defaultLocations.first['location_id'];
      print(
          'تم العثور على معرف الموقع: $locationId في جدول $defaultLocationTable');

      final locations = await db.query(
        locationsTable,
        where: 'id = ?',
        whereArgs: [locationId],
        limit: 1,
      );

      if (locations.isEmpty) {
        print(
            'لم يتم العثور على الموقع في جدول $locationsTable باستخدام المعرف: $locationId');
        return null;
      }

      print('تم العثور على الموقع: ${locations.first['name']}');
      return locations.first;
    } catch (e) {
      print('خطأ في البحث عن الموقع الافتراضي: $e');
      return null;
    }
  }

  // إضافة موقع جديد (يقبل المعلمات بشكل منفصل)
  Future<int> addLocation(String name, double latitude, double longitude,
      double timeZoneOffset) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    try {
      final locationId = await db.insert(
        locationsTable,
        {
          'name': name,
          'latitude': latitude,
          'longitude': longitude,
          'time_zone_offset': timeZoneOffset,
          'created_at': now,
        },
      );

      // إضافة سجل قبلة افتراضي للموقع الجديد
      await addDefaultQiblaForLocation(locationId);

      print('تم إضافة موقع جديد: $name');
      return locationId;
    } catch (e) {
      print('خطأ أثناء إضافة موقع جديد: $e');
      return -1;
    }
  }

  // إضافة موقع جديد (يقبل Map للتوافق مع الكود القديم)
  Future<int> addLocationFromMap(Map<String, dynamic> location) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    try {
      print('بدء إضافة موقع جديد: ${location['name']}');

      // تحويل timeZoneOffset إلى time_zone_offset في حالة استخدام الاسم القديم
      double timeZoneOffset = 0.0;
      if (location.containsKey('timeZoneOffset')) {
        timeZoneOffset = location['timeZoneOffset'] as double;
      } else if (location.containsKey('time_zone_offset')) {
        timeZoneOffset = location['time_zone_offset'] as double;
      }

      final locationData = {
        'name': location['name'],
        'latitude': location['latitude'],
        'longitude': location['longitude'],
        'time_zone_offset': timeZoneOffset,
        'created_at': now,
      };

      print('بيانات الموقع الذي سيتم إضافته: $locationData');

      final locationId = await db.insert(locationsTable, locationData);
      print('تم إضافة الموقع بنجاح، المعرف: $locationId');

      if (locationId > 0) {
        // إضافة سجل قبلة افتراضي للموقع الجديد
        await addDefaultQiblaForLocation(locationId);

        // التحقق مرة أخرى من إضافة القبلة
        final qiblaRecord = await db.query(
          qiblaTable,
          where: 'location_id = ?',
          whereArgs: [locationId],
        );

        if (qiblaRecord.isEmpty) {
          print(
              'تنبيه: فشل في العثور على سجل القبلة بعد إضافته، محاولة إضافة مرة أخرى...');
          // محاولة إضافة سجل القبلة مرة أخرى
          final retryResult = await db.insert(
            qiblaTable,
            {
              'location_id': locationId,
              'qibla_direction': 360.0,
              'created_at': now,
            },
          );
          print('نتيجة محاولة إعادة إضافة سجل القبلة: $retryResult');
        } else {
          print('تم التحقق من وجود سجل القبلة للموقع الجديد');
        }
      }

      return locationId;
    } catch (e) {
      print('خطأ أثناء إضافة موقع جديد: $e');
      return -1;
    }
  }

  // تعيين موقع افتراضي حسب المعرف
  Future<void> setDefaultLocationById(int locationId) async {
    final db = await database;

    try {
      print('بدء عملية تعيين الموقع $locationId كافتراضي...');

      // التحقق من وجود الموقع في جدول المواقع
      final locationCheck = await db.query(
        locationsTable,
        where: 'id = ?',
        whereArgs: [locationId],
        limit: 1,
      );

      if (locationCheck.isEmpty) {
        print('خطأ: لم يتم العثور على الموقع في جدول المواقع');
        throw Exception('لم يتم العثور على الموقع المحدد');
      }

      // تفريغ جدول الموقع الافتراضي أولاً
      await db.delete(defaultLocationTable);
      print('تم تفريغ جدول الموقع الافتراضي بنجاح');

      // إضافة الموقع الجديد كافتراضي
      final result = await db.insert(defaultLocationTable, {
        'location_id': locationId,
      });

      print('تم تعيين الموقع كافتراضي برقم التسجيل: $result');
    } catch (e) {
      print('خطأ أثناء تعيين الموقع الافتراضي: $e');
      throw e;
    }
  }

  // حذف موقع
  Future<bool> deleteLocation(int locationId) async {
    final db = await database;

    // التحقق أولاً من أن هذا الموقع ليس هو الموقع الافتراضي
    final defaultLocation = await getDefaultLocation();
    if (defaultLocation != null && defaultLocation['id'] == locationId) {
      return false; // لا يمكن حذف الموقع الافتراضي
    }

    final rowsAffected = await db.delete(
      locationsTable,
      where: 'id = ?',
      whereArgs: [locationId],
    );

    return rowsAffected > 0;
  }

  // بحث عن موقع حسب الاسم
  Future<List<Map<String, dynamic>>> searchLocation(String name) async {
    final db = await database;
    return await db.query(
      locationsTable,
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
      orderBy: 'name ASC',
    );
  }

  // تحديث بيانات موقع
  Future<int> updateLocation(int id, Map<String, dynamic> location) async {
    final db = await database;
    return await db.update(
      locationsTable,
      location,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // للحفاظ على التوافق مع الكود القديم
  // هذه الدوال تستخدم الدوال الجديدة من الداخل
  Future<List<Map<String, dynamic>>> getAllCustomLocations() async {
    return await getLocations();
  }

  Future<List<Map<String, dynamic>>> getCustomLocations() async {
    return await getLocations();
  }

  Future<List<Map<String, dynamic>>> getDefaultCities() async {
    return await getLocations();
  }

  Future<List<Map<String, dynamic>>> fetchCustomLocations() async {
    return await getLocations();
  }

  Future<int> addCustomLocation(Map<String, dynamic> location) async {
    return await addLocationFromMap(location);
  }

  Future<int> addDefaultCity(Map<String, dynamic> city) async {
    return await addLocationFromMap(city);
  }

  Future<bool> deleteCustomLocation(int id) async {
    return await deleteLocation(id);
  }

  Future<bool> deleteDefaultCity(int id) async {
    return await deleteLocation(id);
  }

  Future<int> removeCustomLocation(int id) async {
    final success = await deleteLocation(id);
    return success ? 1 : 0;
  }

  Future<int> clearCustomLocations() async {
    final db = await database;
    // لا نحذف المواقع المحددة كافتراضية
    final defaultLocation = await getDefaultLocation();
    if (defaultLocation == null) {
      return await db.delete(locationsTable);
    } else {
      return await db.delete(
        locationsTable,
        where: 'id != ?',
        whereArgs: [defaultLocation['id']],
      );
    }
  }

  Future<int> saveCustomLocation(Map<String, dynamic> location) async {
    return await addLocationFromMap(location);
  }

  // إضافة الدوال المفقودة

  // فحص هيكل جدول الخيارات
  Future<bool> checkOptionsTableStructure() async {
    final db = await database;
    try {
      final result = await db.rawQuery('PRAGMA table_info($optionsTable)');

      // التحقق من وجود الأعمدة المطلوبة
      bool hasIdColumn = false;
      bool hasNameColumn = false;
      bool hasValueColumn = false;

      for (var column in result) {
        if (column['name'] == 'id') hasIdColumn = true;
        if (column['name'] == 'name') hasNameColumn = true;
        if (column['name'] == 'value') hasValueColumn = true;
      }

      return hasIdColumn && hasNameColumn && hasValueColumn;
    } catch (e) {
      return false;
    }
  }

  // إعادة إنشاء جدول الخيارات
  Future<void> recreateOptionsTable() async {
    final db = await database;
    try {
      // التحقق من هيكل الجدول أولاً
      final isStructureValid = await checkOptionsTableStructure();

      if (!isStructureValid) {
        // حفظ البيانات الحالية في الذاكرة قبل إعادة الإنشاء
        List<Map<String, dynamic>> existingOptions = [];
        try {
          existingOptions = await db.query(optionsTable);
        } catch (e) {
          // إذا لم يكن الجدول موجوداً أو كان هناك مشكلة في الاستعلام
        }

        // حذف الجدول إذا كان موجوداً
        await db.execute('DROP TABLE IF EXISTS $optionsTable');

        // إعادة إنشاء الجدول بالهيكل الصحيح
        await db.execute('''
          CREATE TABLE $optionsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            value INTEGER NOT NULL
          )
        ''');

        // استعادة البيانات إذا كانت متوفرة
        for (var option in existingOptions) {
          if (option.containsKey('name') && option.containsKey('value')) {
            await db.insert(optionsTable, {
              'name': option['name'],
              'value': option['value'],
            });
          }
        }
      }
    } catch (e) {
      // معالجة الأخطاء
    }
  }

  // الحصول على معلومات قاعدة البيانات
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app.db');
    final file = File(path);

    bool exists = await file.exists();
    String size = '0 KB';
    String lastModified = '';

    if (exists) {
      final fileStats = await file.stat();
      // تحويل الحجم إلى كيلوبايت
      size = '${(fileStats.size / 1024).toStringAsFixed(2)} KB';
      lastModified = DateTime.fromMillisecondsSinceEpoch(
              fileStats.modified.millisecondsSinceEpoch)
          .toString();
    }

    return {
      'location': path,
      'exists': exists,
      'size': size,
      'lastModified': lastModified,
    };
  }

  // الحصول على جميع الخيارات
  Future<Map<String, bool>> getOptions() async {
    final db = await database;
    final options = await db.query(optionsTable);

    Map<String, bool> optionsMap = {};
    for (var option in options) {
      final name = option['name'] as String;
      final value = option['value'] as int;
      optionsMap[name] = value == 1;
    }

    return optionsMap;
  }

  // تحديث الخيارات
  Future<void> updateOptions(Map<String, bool> options) async {
    final db = await database;

    // حفظ كل خيار في قاعدة البيانات
    for (var entry in options.entries) {
      final name = entry.key;
      final value = entry.value ? 1 : 0;

      // التحقق من وجود الخيار
      final existingOption = await db.query(
        optionsTable,
        where: 'name = ?',
        whereArgs: [name],
      );

      if (existingOption.isNotEmpty) {
        // تحديث الخيار الموجود
        await db.update(
          optionsTable,
          {'value': value},
          where: 'name = ?',
          whereArgs: [name],
        );
      } else {
        // إضافة خيار جديد
        await db.insert(optionsTable, {
          'name': name,
          'value': value,
        });
      }
    }
  }

  // إعادة تعيين الخيارات إلى القيم الافتراضية
  Future<void> resetOptions() async {
    final db = await database;

    // حذف جميع الخيارات
    await db.delete(optionsTable);

    // إضافة الخيارات الافتراضية
    final defaultOptions = {
      'show_notifications': true,
      'dark_mode': false,
      'auto_sync': true,
      'sound_enabled': true,
    };

    await updateOptions(defaultOptions);
  }

  // الحصول على المهام المؤرشفة

  // الحصول على المهام اليومية المؤرشفة
  Future<List<Map<String, dynamic>>> getArchivedDailyTasks() async {
    final db = await database;
    return await db.query(
      dailyTasksTable,
      where: 'is_archived = ?',
      whereArgs: [1], // 1 = مؤرشف
      orderBy: 'created_at DESC',
    );
  }

  // أرشفة أو إلغاء أرشفة مهمة

  // أرشفة أو إلغاء أرشفة مهمة يومية
  Future<int> archiveDailyTask(int id, bool archive) async {
    final db = await database;
    return await db.update(
      dailyTasksTable,
      {'is_archived': archive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // حذف مهمة

  // حذف مهمة يومية
  Future<int> deleteDailyTask(int id) async {
    final db = await database;
    return await db.delete(
      dailyTasksTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
/**/
/**/
/**/

  // الحصول على جميع الأفكار (من الأرشيف والبنك)
  Future<List<Map<String, dynamic>>> getAllIdeas() async {
    //final db = await database;

    // الحصول على الأفكار من جدول أرشيف الأفكار
    final archivedIdeas = await getIdeasArchive();

    // الحصول على الأفكار من جدول بنك الأفكار
    final bankIdeas = await getIdeasBank();

    // دمج القائمتين
    return [...archivedIdeas, ...bankIdeas];
  }

/**/
  // إضافة فكرة جديدة
  Future<int> addIdea(Map<String, dynamic> idea, bool toArchive) async {
    if (toArchive) {
      return await addIdeaToArchive(idea);
    } else {
      return await addIdeaToBank(idea);
    }
  }

  // دالة لتحديث حالة المهمة اليومية (مكتمل)
  Future<int> updateDailyTaskCompleted(int id, bool completed) async {
    final db = await database;
    return await db.update(
      dailyTasksTable,
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // دالة لتحديث حالة المهمة اليومية (قيد التنفيذ)
  Future<int> updateDailyTaskInProgress(int id, bool inProgress) async {
    final db = await database;
    return await db.update(
      dailyTasksTable,
      {'in_progress': inProgress ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // دالة للحصول على المهام اليومية
  Future<List<Map<String, dynamic>>> getDailyTasks() async {
    final db = await database;

    // التأكد من وجود مهام في الجدول
    final tasksCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $dailyTasksTable WHERE is_archived = 0'));

    // إذا لم تكن هناك مهام، قم بإضافة بعض المهام الافتراضية
    if (tasksCount == 0) {
      await _insertDefaultDailyTasks();
    }

    return await db.query(
      dailyTasksTable,
      where: 'is_archived = ?',
      whereArgs: [0], // 0 = غير مؤرشف
      orderBy: 'created_at DESC',
    );
  }

  // إضافة مهام افتراضية للاختبار
  Future<void> _insertDefaultDailyTasks() async {
    print('إضافة مهام يومية افتراضية...');
    final db = await database;

    final defaultTasks = [
      {
        'title': 'قراءة القرآن',
        'task_type': 1, // أخروي
        'completed': 0,
        'in_progress': 0,
        'created_at': DateTime.now().toIso8601String(),
        'is_archived': 0,
      },
      {
        'title': 'ممارسة الرياضة',
        'task_type': 0, // دنيوي
        'completed': 0,
        'in_progress': 0,
        'created_at': DateTime.now().toIso8601String(),
        'is_archived': 0,
      },
      {
        'title': 'صلة الرحم',
        'task_type': 2, // كلاهما
        'completed': 0,
        'in_progress': 0,
        'created_at': DateTime.now().toIso8601String(),
        'is_archived': 0,
      },
      {
        'title': 'قراءة كتاب',
        'task_type': 2, // كلاهما
        'completed': 0,
        'in_progress': 0,
        'created_at': DateTime.now().toIso8601String(),
        'is_archived': 0,
      },
      {
        'title': 'عمل تطوعي',
        'task_type': 1, // أخروي
        'completed': 0,
        'in_progress': 0,
        'created_at': DateTime.now().toIso8601String(),
        'is_archived': 0,
      },
    ];

    for (var task in defaultTasks) {
      await db.insert(dailyTasksTable, task);
    }

    print('تم إضافة المهام الافتراضية بنجاح');
  }

  // دالة لإضافة مهمة يومية جديدة
  Future<int> insertDailyTask(Map<String, dynamic> task) async {
    final db = await database;
    task['created_at'] = DateTime.now().toIso8601String();
    task['is_archived'] = 0; // غير مؤرشف افتراضياً
    return await db.insert(dailyTasksTable, task);
  }

  // دالة لإعادة تعيين جدول المهام اليومية
  Future<void> resetDailyTasksTable() async {
    final db = await database;

    try {
      // حذف جميع المهام غير المؤرشفة
      await db.delete(
        dailyTasksTable,
        where: 'is_archived = ?',
        whereArgs: [0],
      );

      print('تم حذف جميع المهام اليومية الغير مؤرشفة بنجاح');

      // إضافة المهام الافتراضية
      await _insertDefaultDailyTasks();

      print(
          'تم إعادة تعيين جدول المهام اليومية وإضافة المهام الافتراضية بنجاح');
    } catch (e) {
      print('خطأ في إعادة تعيين جدول المهام اليومية: $e');
      rethrow;
    }
  }

  // دالة لتصفير حالة المهام اليومية (بدون حذفها)
  Future<void> resetDailyTasksStatus() async {
    final db = await database;

    try {
      // تحديث جميع المهام وتعيين completed و in_progress إلى 0
      await db.update(
        dailyTasksTable,
        {'completed': 0, 'in_progress': 0},
        where: 'is_archived = ?',
        whereArgs: [0], // تحديث المهام غير المؤرشفة فقط
      );

      print('تم تصفير حالة جميع المهام اليومية بنجاح');
    } catch (e) {
      print('خطأ في تصفير حالة المهام اليومية: $e');
      rethrow;
    }
  }

  // دالة لحذف الموقع الافتراضي بالاسم
  Future<int> deleteDefaultCityByName(String name) async {
    final db = await database;

    // البحث عن الموقع بالاسم
    final locations = await db.query(
      locationsTable,
      where: 'name = ?',
      whereArgs: [name],
    );

    if (locations.isEmpty) {
      return 0; // لم يتم العثور على الموقع
    }

    final locationId = locations.first['id'] as int;

    // التحقق من أن الموقع ليس هو الموقع الافتراضي
    final defaultLocation = await getDefaultLocation();
    if (defaultLocation != null && defaultLocation['id'] == locationId) {
      return 0; // لا يمكن حذف الموقع الافتراضي
    }

    // حذف الموقع
    return await db.delete(
      locationsTable,
      where: 'id = ?',
      whereArgs: [locationId],
    );
  }

  // دالة لتعيين الموقع الافتراضي
  Future<void> setDefaultLocation(int locationId) async {
    await setDefaultLocationById(locationId);
  }

  // استعلام جميع الجداول الموجودة في قاعدة البيانات
  Future<List<String>> getAllTables() async {
    final db = await database;

    final result = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ?',
      whereArgs: ['table'],
    );

    // استثناء جداول النظام مثل sqlite_sequence
    return result
        .map((row) => row['name'] as String)
        .where((name) =>
            !name.startsWith('sqlite_') && !name.startsWith('android_'))
        .toList();
  }

  // استعلام أسماء الأعمدة في جدول معين
  Future<List<String>> getTableColumns(String tableName) async {
    final db = await database;

    // استعلام عن معلومات الجدول باستخدام PRAGMA
    final result = await db.rawQuery('PRAGMA table_info($tableName)');

    // استخراج أسماء الأعمدة
    return result.map((column) => column['name'] as String).toList();
  }

  // استعلام جميع البيانات من جدول معين
  Future<List<Map<String, dynamic>>> getTableData(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  // إدراج سجل جديد في جدول معين
  Future<int> insertRecordIntoTable(
      String tableName, Map<String, dynamic> data) async {
    final db = await database;

    // إذا كان الجدول يحتوي على حقل created_at، قم بإضافة الوقت الحالي
    if ((await getTableColumns(tableName)).contains('created_at')) {
      data['created_at'] = DateTime.now().toIso8601String();
    }

    return await db.insert(tableName, data);
  }

  // تحديث سجل في جدول معين
  Future<int> updateRecordInTable(
      String tableName, Map<String, dynamic> data) async {
    final db = await database;

    // يجب أن يحتوي data على حقل id للتعرف على السجل المراد تحديثه
    final id = data['id'];
    if (id == null) {
      throw Exception('يجب توفير معرف السجل للتحديث');
    }

    // إزالة حقل id من البيانات المراد تحديثها
    final Map<String, dynamic> updateData = Map.from(data);
    updateData.remove('id');

    return await db.update(
      tableName,
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // حذف سجل من جدول معين
  Future<int> deleteRecordFromTable(String tableName, int id) async {
    final db = await database;

    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // استعلام عن سجل معين بواسطة المعرف
  Future<Map<String, dynamic>?> getRecordById(String tableName, int id) async {
    final db = await database;

    final results = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  // تنفيذ استعلام خاص (لعمليات أكثر تعقيدًا)
  Future<List<Map<String, dynamic>>> executeRawQuery(String query,
      [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(query, arguments);
  }

  // تنفيذ أمر خاص (مثل UPDATE، DELETE، إلخ)
  Future<int> executeRawUpdate(String query, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(query, arguments);
  }

  // الحصول على جميع الخواطر غير المؤرشفة
  Future<List<Map<String, dynamic>>> getAllThoughts() async {
    final db = await database;
    return await db.query(
      thoughtsTable,
      where: 'is_archived = ?',
      whereArgs: [0],
      orderBy: 'date DESC',
    );
  }

  // الحصول على جميع الخواطر المؤرشفة
  Future<List<Map<String, dynamic>>> getArchivedThoughts() async {
    final db = await database;
    return await db.query(
      thoughtsTable,
      where: 'is_archived = ?',
      whereArgs: [1],
      orderBy: 'date DESC',
    );
  }

  // إضافة خاطرة جديدة
  Future<int> insertThought(Map<String, dynamic> thought) async {
    final db = await database;

    // إضافة وقت الإنشاء
    thought['created_at'] = DateTime.now().toIso8601String();

    return await db.insert(thoughtsTable, thought);
  }

  // تحديث خاطرة موجودة
  Future<int> updateThought(Map<String, dynamic> thought) async {
    final db = await database;

    return await db.update(
      thoughtsTable,
      thought,
      where: 'id = ?',
      whereArgs: [thought['id']],
    );
  }

  // أرشفة خاطرة
  Future<int> archiveThought(int id, [bool archive = true]) async {
    final db = await database;

    return await db.update(
      thoughtsTable,
      {'is_archived': archive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // استعادة خاطرة من الأرشيف
  Future<int> unarchiveThought(int id) async {
    return archiveThought(id, false);
  }

  // حذف خاطرة
  Future<int> deleteThought(int id) async {
    final db = await database;

    return await db.delete(
      thoughtsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // إدراج أذكار افتراضية
  Future<void> _insertDefaultAthkar(Database db) async {
    print('إضافة أذكار افتراضية...');

    final defaultAthkar = [
      {
        'title': 'أذكار الصباح',
        'content':
            'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
      },
      {
        'title': 'أذكار الصباح',
        'content':
            'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      },
      {
        'title': 'أذكار الصباح',
        'content':
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذَا الْيَوْمِ: فَتْحَهُ، وَنَصْرَهُ، وَنُورَهُ، وَبَرَكَتَهُ، وَهُدَاهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهِ وَشَرِّ مَا بَعْدَهُ',
      },
      {
        'title': 'أذكار المساء',
        'content':
            'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
      },
      {
        'title': 'أذكار المساء',
        'content':
            'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      },
      {
        'title': 'أذكار النوم',
        'content': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      },
      {
        'title': 'أذكار النوم',
        'content':
            'اللَّهُمَّ إِنِّي أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ',
      },
      {
        'title': 'أذكار الاستيقاظ',
        'content':
            'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      },
      {
        'title': 'أذكار دخول المنزل',
        'content':
            'بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى رَبِّنَا تَوَكَّلْنَا',
      },
      {
        'title': 'أذكار الخروج من المنزل',
        'content':
            'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      },
    ];

    Batch batch = db.batch();
    for (var athkar in defaultAthkar) {
      batch.insert(athkarTable, athkar);
    }
    await batch.commit();

    print('تم إضافة ${defaultAthkar.length} ذكر افتراضي بنجاح');
  }

  // دوال إدارة جدول الأذكار

  // جلب جميع الأذكار
  Future<List<Map<String, dynamic>>> getAllAthkar() async {
    final db = await database;
    try {
      // التحقق من وجود الجدول
      final tableExists = await _checkIfTableExists(athkarTable);

      if (!tableExists) {
        print('جدول الأذكار غير موجود، جاري إنشاؤه...');
        await db.execute('''
          CREATE TABLE $athkarTable(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL
          )
        ''');

        // إضافة أذكار افتراضية
        await _insertDefaultAthkar(db);
      }

      // جلب الأذكار
      final athkarList = await db.query(athkarTable);
      print('تم جلب ${athkarList.length} ذكر');
      return athkarList;
    } catch (e) {
      print('خطأ في جلب الأذكار: $e');
      return [];
    }
  }

  // جلب الأذكار حسب العنوان
  Future<List<Map<String, dynamic>>> getAthkarByTitle(String title) async {
    final db = await database;
    try {
      return await db.query(
        athkarTable,
        where: 'title = ?',
        whereArgs: [title],
      );
    } catch (e) {
      print('خطأ في جلب الأذكار بالعنوان: $e');
      return [];
    }
  }

  // إضافة ذكر جديد
  Future<int> addAthkar(String title, String content) async {
    final db = await database;
    try {
      return await db.insert(athkarTable, {
        'title': title,
        'content': content,
      });
    } catch (e) {
      print('خطأ في إضافة ذكر جديد: $e');
      return -1;
    }
  }

  // تحديث ذكر
  Future<int> updateAthkar(int id, String title, String content) async {
    final db = await database;
    try {
      return await db.update(
        athkarTable,
        {
          'title': title,
          'content': content,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('خطأ في تحديث الذكر: $e');
      return 0;
    }
  }

  // حذف ذكر
  Future<int> deleteAthkar(int id) async {
    final db = await database;
    try {
      return await db.delete(
        athkarTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('خطأ في حذف الذكر: $e');
      return 0;
    }
  }

  // حذف جميع الأذكار
  Future<int> deleteAllAthkar() async {
    final db = await database;
    try {
      return await db.delete(athkarTable);
    } catch (e) {
      print('خطأ في حذف جميع الأذكار: $e');
      return 0;
    }
  }

  // إدراج أذكار من قائمة
  Future<void> insertAthkarList(List<Map<String, dynamic>> athkarList) async {
    final db = await database;
    try {
      // حذف كل الأذكار الموجودة
      await db.delete(athkarTable);

      // إضافة الأذكار الجديدة
      Batch batch = db.batch();
      for (var athkar in athkarList) {
        batch.insert(athkarTable, {
          'title': athkar['title'],
          'content': athkar['content'],
        });
      }
      await batch.commit();
      print('تم إدراج ${athkarList.length} ذكر بنجاح');
    } catch (e) {
      print('خطأ في إدراج قائمة الأذكار: $e');
    }
  }

  // تنفيذ إدراج الأذكار من الجدول المقدم
  Future<void> initializeAthkarTable() async {
    final db = await database;

    try {
      // التحقق من وجود الجدول
      final tableExists = await _checkIfTableExists(athkarTable);

      if (!tableExists) {
        print('جدول الأذكار غير موجود، جاري إنشاؤه...');
        await db.execute('''
          CREATE TABLE $athkarTable(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL
          )
        ''');
      }

      // حذف الأذكار الموجودة
      await db.delete(athkarTable);

      // إدراج الأذكار المعدة مسبقاً
      final athkarList = [
        {
          'title': 'أذكار الصباح',
          'content':
              'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
        },
        {
          'title': 'أذكار الصباح',
          'content':
              'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        },
        {
          'title': 'أذكار الصباح',
          'content':
              'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذَا الْيَوْمِ: فَتْحَهُ، وَنَصْرَهُ، وَنُورَهُ، وَبَرَكَتَهُ، وَهُدَاهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهِ وَشَرِّ مَا بَعْدَهُ',
        },
        {
          'title': 'أذكار المساء',
          'content':
              'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
        },
        {
          'title': 'أذكار المساء',
          'content':
              'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        },
        {
          'title': 'أذكار النوم',
          'content': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
        },
        {
          'title': 'أذكار النوم',
          'content':
              'اللَّهُمَّ إِنِّي أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ',
        },
        {
          'title': 'أذكار الاستيقاظ',
          'content':
              'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
        },
        {
          'title': 'أذكار دخول المنزل',
          'content':
              'بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى رَبِّنَا تَوَكَّلْنَا',
        },
        {
          'title': 'أذكار الخروج من المنزل',
          'content':
              'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
        },
      ];

      // إدراج الأذكار
      Batch batch = db.batch();
      for (var athkar in athkarList) {
        batch.insert(athkarTable, athkar);
      }
      await batch.commit();

      print('تم إدراج ${athkarList.length} ذكر في قاعدة البيانات');
    } catch (e) {
      print('خطأ في تهيئة جدول الأذكار: $e');
    }
  }

  // إدراج أحاديث افتراضية
  Future<void> _insertDefaultHadiths(Database db) async {
    print('إضافة أحاديث افتراضية...');

    final defaultHadiths = [
      {
        'text':
            'عن أبي العباس عبد الله بن عباس رضي الله عنهما قال: كنت خلف النبي صلى الله عليه وسلم يومًا، فقال: "يا غلام، إني أُعلمك كلمات: احفظ الله يحفظك، احفظ الله تجده تجاهك، إذا سأَلت فاسأَل الله، وإذا استعنت فاستعن بالله، واعلم أن الأُمة لو اجتمعت على أَن ينفعوك بشيء، لم ينفعوك إلا بشيء قد كتبه الله لك، وإن اجتمعوا على أن يضروك بشيء، لم يضروك إلا بشيء قد كتبه الله عليك، رفعت الأقلام وجفت الصحف"',
        'narrator': 'رواه الترمذي وقال: حديث حسن صحيح',
        'topic': 'توكل على الله'
      },
      {
        'text':
            'إنما الأعمال بالنيات، وإنما لكل امرئ ما نوى، فمن كانت هجرته إلى الله ورسوله فهجرته إلى الله ورسوله، ومن كانت هجرته لدنيا يصيبها أو امرأة ينكحها فهجرته إلى ما هاجر إليه.',
        'narrator': 'متفق عليه',
        'topic': 'النية والإخلاص'
      },
      {
        'text':
            'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ.',
        'narrator': 'رواه مسلم',
        'topic': 'طلب العلم'
      },
      {
        'text':
            'المسلم من سلم المسلمون من لسانه ويده، والمهاجر من هجر ما نهى الله عنه.',
        'narrator': 'متفق عليه',
        'topic': 'أخلاق المسلم'
      },
      {
        'text': 'لا يؤمن أحدكم حتى يحب لأخيه ما يحب لنفسه.',
        'narrator': 'متفق عليه',
        'topic': 'الإيمان'
      },
      {
        'text':
            'اتق الله حيثما كنت، وأتبع السيئة الحسنة تمحها، وخالق الناس بخلق حسن.',
        'narrator': 'رواه الترمذي',
        'topic': 'التقوى وحسن الخلق'
      },
    ];

    Batch batch = db.batch();
    for (var hadith in defaultHadiths) {
      batch.insert(hadithsTable, hadith);
    }
    await batch.commit();

    print('تم إضافة ${defaultHadiths.length} حديث افتراضي بنجاح');
  }

  // دوال إدارة جدول الأحاديث

  // جلب جميع الأحاديث
  Future<List<Map<String, dynamic>>> getAllHadiths() async {
    final db = await database;
    try {
      // التحقق من وجود الجدول
      final tableExists = await _checkIfTableExists(hadithsTable);

      if (!tableExists) {
        print('جدول الأحاديث غير موجود، جاري إنشاؤه...');
        await db.execute('''
          CREATE TABLE $hadithsTable(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            narrator TEXT NOT NULL,
            topic TEXT NOT NULL
          )
        ''');

        // إضافة أحاديث افتراضية
        await _insertDefaultHadiths(db);
      }

      // جلب الأحاديث
      final hadithsList = await db.query(hadithsTable);
      print('تم جلب ${hadithsList.length} حديث');
      return hadithsList;
    } catch (e) {
      print('خطأ في جلب الأحاديث: $e');
      return [];
    }
  }

  // جلب الأحاديث حسب الموضوع
  Future<List<Map<String, dynamic>>> getHadithsByTopic(String topic) async {
    final db = await database;
    try {
      return await db.query(
        hadithsTable,
        where: 'topic = ?',
        whereArgs: [topic],
      );
    } catch (e) {
      print('خطأ في جلب الأحاديث بالموضوع: $e');
      return [];
    }
  }

  // إضافة حديث جديد
  Future<int> addHadith(String text, String narrator, String topic) async {
    final db = await database;
    try {
      return await db.insert(hadithsTable, {
        'text': text,
        'narrator': narrator,
        'topic': topic,
      });
    } catch (e) {
      print('خطأ في إضافة حديث جديد: $e');
      return -1;
    }
  }

  // تحديث حديث
  Future<int> updateHadith(
      int id, String text, String narrator, String topic) async {
    final db = await database;
    try {
      return await db.update(
        hadithsTable,
        {
          'text': text,
          'narrator': narrator,
          'topic': topic,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('خطأ في تحديث الحديث: $e');
      return 0;
    }
  }

  // حذف حديث
  Future<int> deleteHadith(int id) async {
    final db = await database;
    try {
      return await db.delete(
        hadithsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('خطأ في حذف الحديث: $e');
      return 0;
    }
  }

  // حذف جميع الأحاديث
  Future<int> deleteAllHadiths() async {
    final db = await database;
    try {
      return await db.delete(hadithsTable);
    } catch (e) {
      print('خطأ في حذف جميع الأحاديث: $e');
      return 0;
    }
  }

  // تهيئة جدول الأحاديث
  Future<void> initializeHadithsTable() async {
    final db = await database;

    try {
      // التحقق من وجود الجدول
      final tableExists = await _checkIfTableExists(hadithsTable);

      if (!tableExists) {
        print('جدول الأحاديث غير موجود، جاري إنشاؤه...');
        await db.execute('''
          CREATE TABLE $hadithsTable(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            narrator TEXT NOT NULL,
            topic TEXT NOT NULL
          )
        ''');
      }

      // حذف الأحاديث الموجودة
      await db.delete(hadithsTable);

      // إدراج الأحاديث المعدة مسبقاً
      final hadithsList = [
        {
          'text':
              'عن أبي العباس عبد الله بن عباس رضي الله عنهما قال: كنت خلف النبي صلى الله عليه وسلم يومًا، فقال: "يا غلام، إني أُعلمك كلمات: احفظ الله يحفظك، احفظ الله تجده تجاهك، إذا سأَلت فاسأَل الله، وإذا استعنت فاستعن بالله، واعلم أن الأُمة لو اجتمعت على أَن ينفعوك بشيء، لم ينفعوك إلا بشيء قد كتبه الله لك، وإن اجتمعوا على أن يضروك بشيء، لم يضروك إلا بشيء قد كتبه الله عليك، رفعت الأقلام وجفت الصحف"',
          'narrator': 'رواه الترمذي وقال: حديث حسن صحيح',
          'topic': 'توكل على الله'
        },
        {
          'text':
              'إنما الأعمال بالنيات، وإنما لكل امرئ ما نوى، فمن كانت هجرته إلى الله ورسوله فهجرته إلى الله ورسوله، ومن كانت هجرته لدنيا يصيبها أو امرأة ينكحها فهجرته إلى ما هاجر إليه.',
          'narrator': 'متفق عليه',
          'topic': 'النية والإخلاص'
        },
        {
          'text':
              'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ.',
          'narrator': 'رواه مسلم',
          'topic': 'طلب العلم'
        },
        {
          'text':
              'المسلم من سلم المسلمون من لسانه ويده، والمهاجر من هجر ما نهى الله عنه.',
          'narrator': 'متفق عليه',
          'topic': 'أخلاق المسلم'
        },
        {
          'text': 'لا يؤمن أحدكم حتى يحب لأخيه ما يحب لنفسه.',
          'narrator': 'متفق عليه',
          'topic': 'الإيمان'
        },
        {
          'text':
              'اتق الله حيثما كنت، وأتبع السيئة الحسنة تمحها، وخالق الناس بخلق حسن.',
          'narrator': 'رواه الترمذي',
          'topic': 'التقوى وحسن الخلق'
        },
      ];

      // إدراج الأحاديث
      Batch batch = db.batch();
      for (var hadith in hadithsList) {
        batch.insert(hadithsTable, hadith);
      }
      await batch.commit();

      print('تم إدراج ${hadithsList.length} حديث في قاعدة البيانات');
    } catch (e) {
      print('خطأ في تهيئة جدول الأحاديث: $e');
    }
  }

  // إدراج أدعية القرآن الافتراضية
  Future<void> _insertDefaultQuranDua(Database db) async {
    print('إضافة أدعية القرآن الافتراضية...');

    final defaultQuranDua = [
      {
        'text':
            'قَالَ أَفَرَأَيْتُم مَّا كُنتُمْ تَعْبُدُونَ (75) أَنتُمْ وَآبَاؤُكُمُ الْأَقْدَمُونَ (76) فَإِنَّهُمْ عَدُوٌّ لِّي إِلَّا رَبَّ الْعَالَمِينَ (77) الَّذِي خَلَقَنِي فَهُوَ يَهْدِينِ (78) وَالَّذِي هُوَ يُطْعِمُنِي وَيَسْقِينِ (79) وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ (80) وَالَّذِي يُمِيتُنِي ثُمَّ يُحْيِينِ (81) وَالَّذِي أَطْمَعُ أَن يَغْفِرَ لِي خَطِيئَتِي يَوْمَ الدِّينِ (82) رَبِّ هَبْ لِي حُكْمًا وَأَلْحِقْنِي بِالصَّالِحِينَ (83) وَاجْعَل لِّي لِسَانَ صِدْقٍ فِي الْآخِرِينَ (84) وَاجْعَلْنِي مِن وَرَثَةِ جَنَّةِ النَّعِيمِ (85) وَاغْفِرْ لِأَبِي إِنَّهُ كَانَ مِنَ الضَّالِّينَ (86) وَلَا تُخْزِنِي يَوْمَ يُبْعَثُونَ (87) يَوْمَ لَا يَنفَعُ مَالٌ وَلَا بَنُونَ (88) إِلَّا مَنْ أَتَى اللَّهَ بِقَلْبٍ سَلِيمٍ',
        'source': 'سورة الشعراء',
        'theme': 'دعاء سيدنا إبراهيم عليه السلام'
      },
      {
        'text':
            'رَبِّ أَدخِلني مُدخَلَ صِدقٍ وَأَخرِجني مُخرَجَ صِدقٍ وَاجعَل لي مِن لَدُنكَ سُلطانًا نَصيرًا',
        'source': 'سورة الإسراء: 80',
        'theme': 'طلب التوفيق والنصر'
      },
      {
        'text':
            'رَبِّ اشرَح لي صَدري* وَيَسِّر لي أَمري* وَاحلُل عُقدَةً مِن لِساني',
        'source': 'سورة طه: 25-27',
        'theme': 'دعاء سيدنا موسى عليه السلام'
      },
      {
        'text':
            'رَّبِّ أَنزِلْنِي مُنزَلًا مُّبَارَكًا وَأَنتَ خَيْرُ الْمُنزِلِينَ',
        'source': 'سورة المؤمنون: 29',
        'theme': 'طلب البركة في المكان'
      },
      {
        'text':
            'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
        'source': 'سورة البقرة: 201',
        'theme': 'الدعاء الجامع لخيري الدنيا والآخرة'
      },
      {
        'text':
            'رَّبَّنَا إِنَّنَا سَمِعْنَا مُنَادِيًا يُنَادِي لِلْإِيمَانِ أَنْ آمِنُوا بِرَبِّكُمْ فَآمَنَّا ۚ رَبَّنَا فَاغْفِرْ لَنَا ذُنُوبَنَا وَكَفِّرْ عَنَّا سَيِّئَاتِنَا وَتَوَفَّنَا مَعَ الْأَبْرَارِ (193) رَبَّنَا وَآتِنَا مَا وَعَدتَّنَا عَلَىٰ رُسُلِكَ وَلَا تُخْزِنَا يَوْمَ الْقِيَامَةِ ۗ إِنَّكَ لَا تُخْلِفُ الْمِيعَادَ (194)',
        'source': 'سورة آل عمران: 193-194',
        'theme': 'دعاء المؤمنين'
      },
      {
        'text':
            'رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنْتَ السَّمِيعُ الْعَلِيمُ* رَبَّنَا وَاجْعَلْنَا مُسْلِمَيْنِ لَكَ وَمِنْ ذُرِّيَّتِنَا أُمَّةً مُسْلِمَةً لَكَ وَأَرِنَا مَنَاسِكَنَا وَتُبْ عَلَيْنَا إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
        'source': 'سورة البقرة: 127-128',
        'theme': 'دعاء إبراهيم وإسماعيل عليهما السلام'
      },
    ];

    Batch batch = db.batch();
    for (var dua in defaultQuranDua) {
      batch.insert(quranDuaTable, dua);
    }
    await batch.commit();

    print('تم إضافة ${defaultQuranDua.length} دعاء قرآني افتراضي بنجاح');
  }

  // دوال إدارة جدول أدعية القرآن

  // جلب جميع أدعية القرآن
  Future<List<Map<String, dynamic>>> getAllQuranDuas() async {
    final db = await database;
    try {
      // التحقق من وجود الجدول
      final tableExists = await _checkIfTableExists(quranDuaTable);

      if (!tableExists) {
        print('جدول أدعية القرآن غير موجود، جاري إنشاؤه...');
        await db.execute('''
          CREATE TABLE $quranDuaTable(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            source TEXT NOT NULL,
            theme TEXT NOT NULL
          )
        ''');

        // إضافة أدعية القرآن الافتراضية
        await _insertDefaultQuranDua(db);
      }

      // جلب أدعية القرآن
      final quranDuaList = await db.query(quranDuaTable);
      print('تم جلب ${quranDuaList.length} دعاء قرآني');
      return quranDuaList;
    } catch (e) {
      print('خطأ في جلب أدعية القرآن: $e');
      return [];
    }
  }

  // جلب أدعية القرآن حسب الموضوع
  Future<List<Map<String, dynamic>>> getQuranDuasByTheme(String theme) async {
    final db = await database;
    try {
      return await db.query(
        quranDuaTable,
        where: 'theme = ?',
        whereArgs: [theme],
      );
    } catch (e) {
      print('خطأ في جلب أدعية القرآن بالموضوع: $e');
      return [];
    }
  }

  // إضافة دعاء قرآني جديد
  Future<int> addQuranDua(String text, String source, String theme) async {
    final db = await database;
    try {
      return await db.insert(quranDuaTable, {
        'text': text,
        'source': source,
        'theme': theme,
      });
    } catch (e) {
      print('خطأ في إضافة دعاء قرآني جديد: $e');
      return -1;
    }
  }

  // تحديث دعاء قرآني
  Future<int> updateQuranDua(
      int id, String text, String source, String theme) async {
    final db = await database;
    try {
      return await db.update(
        quranDuaTable,
        {
          'text': text,
          'source': source,
          'theme': theme,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('خطأ في تحديث الدعاء القرآني: $e');
      return 0;
    }
  }

  // حذف دعاء قرآني
  Future<int> deleteQuranDua(int id) async {
    final db = await database;
    try {
      return await db.delete(
        quranDuaTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('خطأ في حذف الدعاء القرآني: $e');
      return 0;
    }
  }

  // حذف جميع أدعية القرآن
  Future<int> deleteAllQuranDuas() async {
    final db = await database;
    try {
      return await db.delete(quranDuaTable);
    } catch (e) {
      print('خطأ في حذف جميع أدعية القرآن: $e');
      return 0;
    }
  }

  // تهيئة جدول أدعية القرآن
  Future<void> initializeQuranDuaTable() async {
    final db = await database;

    try {
      // التحقق من وجود الجدول
      final tableExists = await _checkIfTableExists(quranDuaTable);

      if (!tableExists) {
        print('جدول أدعية القرآن غير موجود، جاري إنشاؤه...');
        await db.execute('''
          CREATE TABLE $quranDuaTable(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            source TEXT NOT NULL,
            theme TEXT NOT NULL
          )
        ''');
      }

      // حذف أدعية القرآن الموجودة
      await db.delete(quranDuaTable);

      // إدراج أدعية القرآن المعدة مسبقاً
      final quranDuaList = [
        {
          'text':
              'قَالَ أَفَرَأَيْتُم مَّا كُنتُمْ تَعْبُدُونَ (75) أَنتُمْ وَآبَاؤُكُمُ الْأَقْدَمُونَ (76) فَإِنَّهُمْ عَدُوٌّ لِّي إِلَّا رَبَّ الْعَالَمِينَ (77) الَّذِي خَلَقَنِي فَهُوَ يَهْدِينِ (78) وَالَّذِي هُوَ يُطْعِمُنِي وَيَسْقِينِ (79) وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ (80) وَالَّذِي يُمِيتُنِي ثُمَّ يُحْيِينِ (81) وَالَّذِي أَطْمَعُ أَن يَغْفِرَ لِي خَطِيئَتِي يَوْمَ الدِّينِ (82) رَبِّ هَبْ لِي حُكْمًا وَأَلْحِقْنِي بِالصَّالِحِينَ (83) وَاجْعَل لِّي لِسَانَ صِدْقٍ فِي الْآخِرِينَ (84) وَاجْعَلْنِي مِن وَرَثَةِ جَنَّةِ النَّعِيمِ (85) وَاغْفِرْ لِأَبِي إِنَّهُ كَانَ مِنَ الضَّالِّينَ (86) وَلَا تُخْزِنِي يَوْمَ يُبْعَثُونَ (87) يَوْمَ لَا يَنفَعُ مَالٌ وَلَا بَنُونَ (88) إِلَّا مَنْ أَتَى اللَّهَ بِقَلْبٍ سَلِيمٍ',
          'source': 'سورة الشعراء',
          'theme': 'دعاء سيدنا إبراهيم عليه السلام'
        },
        {
          'text':
              'رَبِّ أَدخِلني مُدخَلَ صِدقٍ وَأَخرِجني مُخرَجَ صِدقٍ وَاجعَل لي مِن لَدُنكَ سُلطانًا نَصيرًا',
          'source': 'سورة الإسراء: 80',
          'theme': 'طلب التوفيق والنصر'
        },
        {
          'text':
              'رَبِّ اشرَح لي صَدري* وَيَسِّر لي أَمري* وَاحلُل عُقدَةً مِن لِساني',
          'source': 'سورة طه: 25-27',
          'theme': 'دعاء سيدنا موسى عليه السلام'
        },
        {
          'text':
              'رَّبِّ أَنزِلْنِي مُنزَلًا مُّبَارَكًا وَأَنتَ خَيْرُ الْمُنزِلِينَ',
          'source': 'سورة المؤمنون: 29',
          'theme': 'طلب البركة في المكان'
        },
        {
          'text':
              'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
          'source': 'سورة البقرة: 201',
          'theme': 'الدعاء الجامع لخيري الدنيا والآخرة'
        },
        {
          'text':
              'رَّبَّنَا إِنَّنَا سَمِعْنَا مُنَادِيًا يُنَادِي لِلْإِيمَانِ أَنْ آمِنُوا بِرَبِّكُمْ فَآمَنَّا ۚ رَبَّنَا فَاغْفِرْ لَنَا ذُنُوبَنَا وَكَفِّرْ عَنَّا سَيِّئَاتِنَا وَتَوَفَّنَا مَعَ الْأَبْرَارِ (193) رَبَّنَا وَآتِنَا مَا وَعَدتَّنَا عَلَىٰ رُسُلِكَ وَلَا تُخْزِنَا يَوْمَ الْقِيَامَةِ ۗ إِنَّكَ لَا تُخْلِفُ الْمِيعَادَ (194)',
          'source': 'سورة آل عمران: 193-194',
          'theme': 'دعاء المؤمنين'
        },
        {
          'text':
              'رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنْتَ السَّمِيعُ الْعَلِيمُ* رَبَّنَا وَاجْعَلْنَا مُسْلِمَيْنِ لَكَ وَمِنْ ذُرِّيَّتِنَا أُمَّةً مُسْلِمَةً لَكَ وَأَرِنَا مَنَاسِكَنَا وَتُبْ عَلَيْنَا إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
          'source': 'سورة البقرة: 127-128',
          'theme': 'دعاء إبراهيم وإسماعيل عليهما السلام'
        },
      ];

      // إدراج أدعية القرآن
      Batch batch = db.batch();
      for (var dua in quranDuaList) {
        batch.insert(quranDuaTable, dua);
      }
      await batch.commit();

      print('تم إدراج ${quranDuaList.length} دعاء قرآني في قاعدة البيانات');
    } catch (e) {
      print('خطأ في تهيئة جدول أدعية القرآن: $e');
    }
  }

  // ========================
  // دوال خاصة بجدول أوقات الصلاة
  // ========================

  // إدخال أوقات صلاة جديدة
  Future<int> savePrayerTimes(Map<String, dynamic> prayerTimesData) async {
    final db = await instance.database;

    // التحقق من وجود سجل بنفس التاريخ
    final existingData = await db.query(
      prayerTimesTable,
      where: 'date = ?',
      whereArgs: [prayerTimesData['date']],
    );

    if (existingData.isNotEmpty) {
      // تحديث السجل الموجود
      return await db.update(
        prayerTimesTable,
        prayerTimesData,
        where: 'date = ?',
        whereArgs: [prayerTimesData['date']],
      );
    } else {
      // إدخال سجل جديد
      return await db.insert(prayerTimesTable, prayerTimesData);
    }
  }

  // الحصول على أوقات الصلاة لتاريخ معين
  Future<Map<String, dynamic>?> getPrayerTimesByDate(String date,
      {int? locationId}) async {
    final db = await instance.database;

    try {
      final whereClause =
          'date = ? ${locationId != null ? 'AND location_id = ?' : ''}';
      final whereArgs = locationId != null ? [date, locationId] : [date];

      final result = await db.query(
        prayerTimesTable,
        where: whereClause,
        whereArgs: whereArgs,
      );

      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('خطأ أثناء استرجاع أوقات الصلاة: $e');
      return null;
    }
  }

  // الحصول على جميع أوقات الصلاة المخزنة
  Future<List<Map<String, dynamic>>> getAllPrayerTimes() async {
    final db = await instance.database;
    return await db.query(prayerTimesTable, orderBy: 'date DESC');
  }

  // حذف أوقات الصلاة لتاريخ معين
  Future<int> deletePrayerTimesByDate(String date, {int? locationId}) async {
    final db = await instance.database;

    try {
      final whereClause =
          'date = ? ${locationId != null ? 'AND location_id = ?' : ''}';
      final whereArgs = locationId != null ? [date, locationId] : [date];

      return await db.delete(
        prayerTimesTable,
        where: whereClause,
        whereArgs: whereArgs,
      );
    } catch (e) {
      print('خطأ أثناء حذف أوقات الصلاة لتاريخ معين: $e');
      return -1;
    }
  }

  // حذف جميع أوقات الصلاة
  Future<int> deleteAllPrayerTimes() async {
    final db = await instance.database;

    try {
      return await db.delete(prayerTimesTable);
    } catch (e) {
      print('خطأ أثناء حذف جميع أوقات الصلاة: $e');
      return -1;
    }
  }

  // التحقق من وجود جدول أوقات الصلاة وإنشائه إذا لم يكن موجوداً
  Future<void> initializePrayerTimesTable() async {
    final db = await database;

    try {
      // التحقق من وجود جدول أوقات الصلاة
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$prayerTimesTable'");

      if (tables.isEmpty) {
        // إنشاء جدول أوقات الصلاة إذا لم يكن موجوداً
        await db.execute('''
          CREATE TABLE $prayerTimesTable(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            location_id INTEGER,
            fajr TEXT NOT NULL,
            sunrise TEXT NOT NULL,
            dhuhr TEXT NOT NULL,
            asr TEXT NOT NULL,
            maghrib TEXT NOT NULL,
            isha TEXT NOT NULL,
            UNIQUE(date, location_id),
            FOREIGN KEY (location_id) REFERENCES $locationsTable (id) ON DELETE SET NULL
          )
        ''');
        print('تم إنشاء جدول أوقات الصلاة بنجاح');

        // إضافة أوقات صلاة افتراضية
        await addDefaultPrayerTimes();
      } else {
        print('جدول أوقات الصلاة موجود بالفعل');

        // التحقق من وجود أوقات صلاة افتراضية وإضافتها إذا لم تكن موجودة
        await addDefaultPrayerTimes();
      }
    } catch (e) {
      print('خطأ أثناء التحقق من جدول أوقات الصلاة وإنشائه: $e');
    }
  }

  // التحقق من وجود جدول القبلة وإنشاؤه إذا لم يكن موجوداً
  Future<void> initializeQiblaTable() async {
    final db = await database;

    try {
      final qiblaTableExists = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', qiblaTable],
      );

      if (qiblaTableExists.isEmpty) {
        await db.execute('''
          CREATE TABLE $qiblaTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            location_id INTEGER NOT NULL,
            qibla_direction REAL NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (location_id) REFERENCES $locationsTable (id) ON DELETE CASCADE
          )
        ''');
        print('تم إنشاء جدول القبلة بنجاح');

        // إضافة سجلات افتراضية للقبلة لكل موقع موجود
        await syncQiblaWithLocations();
      } else {
        print('جدول القبلة موجود بالفعل');

        // مزامنة جدول القبلة مع جدول المواقع
        await syncQiblaWithLocations();
      }
    } catch (e) {
      print('خطأ أثناء التحقق من جدول القبلة وإنشائه: $e');
    }
  }

  // مزامنة جدول القبلة مع جدول المواقع
  Future<void> syncQiblaWithLocations() async {
    final db = await database;

    try {
      print('بدء مزامنة جدول القبلة مع جدول المواقع...');

      // التحقق من وجود جدول المواقع
      final locationsExists = await _checkIfTableExists(locationsTable);
      if (!locationsExists) {
        print('تنبيه: جدول المواقع غير موجود');
        return;
      }

      // التحقق من وجود جدول القبلة
      final qiblaExists = await _checkIfTableExists(qiblaTable);
      if (!qiblaExists) {
        print('تنبيه: جدول القبلة غير موجود، جاري إنشاؤه...');
        await db.execute('''
          CREATE TABLE $qiblaTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            location_id INTEGER NOT NULL,
            qibla_direction REAL NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (location_id) REFERENCES $locationsTable (id) ON DELETE CASCADE
          )
        ''');
      }

      // الحصول على جميع المواقع
      final locations = await db.query(locationsTable);
      print('عدد المواقع المتوفرة: ${locations.length}');

      if (locations.isEmpty) {
        print('لا توجد مواقع لإضافتها إلى جدول القبلة');
        return;
      }

      final now = DateTime.now().toIso8601String();
      int syncCount = 0;

      // لكل موقع، التحقق من وجود سجل في جدول القبلة
      for (var location in locations) {
        final locationId = location['id'] as int;
        final locationName = location['name'] as String;

        print(
            'جاري التحقق من وجود سجل قبلة للموقع: $locationName (ID: $locationId)');

        // التحقق من وجود سجل للموقع في جدول القبلة
        final qiblaRecord = await db.query(
          qiblaTable,
          where: 'location_id = ?',
          whereArgs: [locationId],
        );

        if (qiblaRecord.isEmpty) {
          // إضافة سجل جديد للقبلة بقيمة افتراضية 360
          final result = await db.insert(
            qiblaTable,
            {
              'location_id': locationId,
              'qibla_direction': 360.0, // قيمة افتراضية
              'created_at': now,
            },
          );

          if (result > 0) {
            syncCount++;
            print(
                'تمت إضافة سجل قبلة افتراضي للموقع $locationName (ID: $locationId)');
          } else {
            print(
                'فشل في إضافة سجل قبلة للموقع $locationName (ID: $locationId)');
          }
        } else {
          print(
              'سجل القبلة موجود بالفعل للموقع $locationName (ID: $locationId)');
        }
      }

      print('اكتملت مزامنة جدول القبلة: تمت إضافة $syncCount سجل جديد');
    } catch (e) {
      print('خطأ أثناء مزامنة جدول القبلة مع جدول المواقع: $e');
    }
  }

  // إضافة سجل قبلة افتراضي عند إضافة موقع جديد
  Future<void> addDefaultQiblaForLocation(int locationId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    try {
      print('إضافة سجل قبلة افتراضي للموقع الجديد (ID: $locationId)');

      // التحقق من وجود الموقع في جدول المواقع
      final locationExists = await db.query(
        locationsTable,
        where: 'id = ?',
        whereArgs: [locationId],
      );

      if (locationExists.isEmpty) {
        print('تنبيه: الموقع غير موجود (ID: $locationId)');
        return;
      }

      // التحقق من وجود سجل للموقع في جدول القبلة
      final qiblaRecord = await db.query(
        qiblaTable,
        where: 'location_id = ?',
        whereArgs: [locationId],
      );

      if (qiblaRecord.isEmpty) {
        // إضافة سجل جديد للقبلة بقيمة افتراضية 360
        final result = await db.insert(
          qiblaTable,
          {
            'location_id': locationId,
            'qibla_direction': 360.0, // قيمة فتراضية
            'created_at': now,
          },
        );

        if (result > 0) {
          print('تمت إضافة سجل قبلة افتراضي للموقع الجديد (ID: $locationId)');
        } else {
          print('فشل في إضافة سجل قبلة للموقع الجديد (ID: $locationId)');
        }
      } else {
        print('سجل القبلة موجود بالفعل للموقع (ID: $locationId)');
      }
    } catch (e) {
      print('خطأ أثناء إضافة سجل قبلة افتراضي: $e');
    }
  }

  // حفظ اتجاه القبلة لموقع معين
  Future<int> saveQiblaDirection(int locationId, double qiblaDirection) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    try {
      // التحقق من وجود سجل لهذا الموقع
      final existingRecord = await db.query(
        qiblaTable,
        where: 'location_id = ?',
        whereArgs: [locationId],
      );

      if (existingRecord.isNotEmpty) {
        // تحديث السجل الموجود
        return await db.update(
          qiblaTable,
          {
            'qibla_direction': qiblaDirection,
            'created_at': now,
          },
          where: 'location_id = ?',
          whereArgs: [locationId],
        );
      } else {
        // إنشاء سجل جديد
        return await db.insert(
          qiblaTable,
          {
            'location_id': locationId,
            'qibla_direction': qiblaDirection,
            'created_at': now,
          },
        );
      }
    } catch (e) {
      print('خطأ أثناء حفظ اتجاه القبلة: $e');
      return -1;
    }
  }

  // الحصول على اتجاه القبلة لموقع معين
  Future<double?> getQiblaDirection(int locationId) async {
    final db = await database;

    try {
      final result = await db.query(
        qiblaTable,
        columns: ['qibla_direction'],
        where: 'location_id = ?',
        whereArgs: [locationId],
      );

      if (result.isNotEmpty) {
        return result.first['qibla_direction'] as double?;
      }
      return null;
    } catch (e) {
      print('خطأ أثناء استرجاع اتجاه القبلة: $e');
      return null;
    }
  }

  // حذف اتجاه القبلة لموقع معين
  Future<int> deleteQiblaDirection(int locationId) async {
    final db = await database;

    try {
      return await db.delete(
        qiblaTable,
        where: 'location_id = ?',
        whereArgs: [locationId],
      );
    } catch (e) {
      print('خطأ أثناء حذف اتجاه القبلة: $e');
      return -1;
    }
  }

  // الحصول على أوقات الصلاة لموقع معين
  Future<List<Map<String, dynamic>>> getPrayerTimesByLocation(
      int locationId) async {
    final db = await database;

    try {
      return await db.query(
        prayerTimesTable,
        where: 'location_id = ?',
        whereArgs: [locationId],
        orderBy: 'date DESC',
      );
    } catch (e) {
      print('خطأ أثناء استرجاع أوقات الصلاة للموقع: $e');
      return [];
    }
  }

  // استعلام عن جميع سجلات القبلة
  Future<List<Map<String, dynamic>>> getAllQiblaDirections() async {
    final db = await database;

    try {
      print('استعلام عن جميع سجلات القبلة...');

      // التحقق من وجود جدول القبلة
      final tableExists = await _checkIfTableExists(qiblaTable);
      if (!tableExists) {
        print('تنبيه: جدول القبلة غير موجود');
        return [];
      }

      final results = await db.query(qiblaTable);
      print('عدد سجلات القبلة المسترجعة: ${results.length}');

      // طباعة تفاصيل كل سجل
      if (results.isNotEmpty) {
        for (var record in results) {
          final locationId = record['location_id'] as int;
          final qiblaDirection = record['qibla_direction'] as double;

          // استرجاع اسم الموقع
          final locationName = await _getLocationNameById(locationId);

          print(
              'سجل قبلة: الموقع=$locationName (ID=$locationId), اتجاه القبلة=$qiblaDirection');
        }
      }

      return results;
    } catch (e) {
      print('خطأ أثناء استعلام عن سجلات القبلة: $e');
      return [];
    }
  }

  // استرجاع اسم الموقع حسب المعرف
  Future<String> _getLocationNameById(int locationId) async {
    final db = await database;

    try {
      final location = await db.query(
        locationsTable,
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [locationId],
        limit: 1,
      );

      return location.isNotEmpty
          ? location.first['name'] as String
          : 'موقع غير معروف';
    } catch (e) {
      return 'موقع غير معروف';
    }
  }

  // إصلاح جدول القبلة وإعادة مزامنته مع المواقع
  Future<void> repairQiblaTable() async {
    final db = await database;

    try {
      print('بدء عملية إصلاح جدول القبلة...');

      // 1. التحقق من وجود جدول القبلة
      final qiblaTableExists = await _checkIfTableExists(qiblaTable);

      // 2. إذا كان الجدول موجوداً، نحذفه لإعادة إنشائه من الصفر
      if (qiblaTableExists) {
        print('جدول القبلة موجود، جاري حذفه لإعادة الإنشاء...');
        await db.execute('DROP TABLE IF EXISTS $qiblaTable');
        print('تم حذف جدول القبلة');
      }

      // 3. إنشاء جدول القبلة من جديد
      print('جاري إنشاء جدول القبلة من جديد...');
      await db.execute('''
        CREATE TABLE $qiblaTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          location_id INTEGER NOT NULL,
          qibla_direction REAL NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (location_id) REFERENCES $locationsTable (id) ON DELETE CASCADE
        )
      ''');
      print('تم إنشاء جدول القبلة بنجاح');

      // 4. مزامنة جدول القبلة مع جدول المواقع
      print('جاري مزامنة جدول القبلة مع المواقع...');
      await syncQiblaWithLocations();

      // 5. التحقق من نتيجة المزامنة
      final qiblaRecords = await getAllQiblaDirections();
      print(
          'اكتملت عملية إصلاح جدول القبلة: تم إنشاء ${qiblaRecords.length} سجل');
    } catch (e) {
      print('خطأ أثناء إصلاح جدول القبلة: $e');
    }
  }

  // إضافة أوقات صلاة افتراضية للتطبيق (النسخة المحسنة)
  Future<void> addDefaultPrayerTimes() async {
    final db = await database;

    try {
      print('بدء إضافة أوقات صلاة افتراضية لكل مدينة...');

      // الحصول على جميع المدن
      final locations = await db.query(locationsTable);
      print('عدد المدن المتاحة: ${locations.length}');

      if (locations.isEmpty) {
        print('تنبيه: لا توجد مدن في قاعدة البيانات!');
        return;
      }

      // التاريخ الافتراضي
      final defaultDate = '2000/01/01';
      // الوقت الافتراضي
      final defaultTime = '11:11';

      // عداد الإضافات الناجحة
      int successCount = 0;

      // إضافة أوقات صلاة لكل مدينة
      for (var location in locations) {
        final locationId = location['id'] as int;
        final locationName = location['name'] as String;

        print(
            'جاري التحقق من أوقات الصلاة للمدينة: $locationName (ID: $locationId)');

        // التحقق من وجود أوقات صلاة لهذه المدينة والتاريخ
        final existingRecord = await db.query(
          prayerTimesTable,
          where: 'date = ? AND location_id = ?',
          whereArgs: [defaultDate, locationId],
        );

        if (existingRecord.isEmpty) {
          // إنشاء سجل جديد بأوقات افتراضية لهذه المدينة
          final result = await db.insert(
            prayerTimesTable,
            {
              'date': defaultDate,
              'location_id': locationId,
              'fajr': defaultTime,
              'sunrise': defaultTime,
              'dhuhr': defaultTime,
              'asr': defaultTime,
              'maghrib': defaultTime,
              'isha': defaultTime,
            },
          );

          if (result > 0) {
            successCount++;
            print('✓ تم إضافة أوقات صلاة افتراضية للمدينة: $locationName');
          } else {
            print('✗ فشل في إضافة أوقات صلاة افتراضية للمدينة: $locationName');
          }
        } else {
          print('! أوقات الصلاة موجودة بالفعل للمدينة: $locationName');
        }
      }

      print(
          'اكتملت إضافة أوقات الصلاة: تمت إضافة $successCount سجل من أصل ${locations.length} مدينة');

      // التحقق من إجمالي سجلات أوقات الصلاة في قاعدة البيانات
      final allPrayerTimes = await db.query(prayerTimesTable);
      print(
          'إجمالي سجلات أوقات الصلاة في قاعدة البيانات: ${allPrayerTimes.length}');
    } catch (e) {
      print('خطأ أثناء إضافة أوقات صلاة افتراضية: $e');
    }
  }

  // إضافة أوقات صلاة افتراضية لموقع محدد حسب المعرف
  Future<bool> addDefaultPrayerTimesForLocation(int locationId) async {
    final db = await database;

    try {
      print('إضافة أوقات صلاة افتراضية للموقع بمعرف: $locationId');

      // التحقق من وجود الموقع
      final location = await db.query(
        locationsTable,
        where: 'id = ?',
        whereArgs: [locationId],
        limit: 1,
      );

      if (location.isEmpty) {
        print('خطأ: الموقع غير موجود');
        return false;
      }

      final locationName = location.first['name'] as String;

      // التاريخ والوقت الافتراضي
      final defaultDate = '2000/01/01';
      final defaultTime = '11:11';

      // التحقق من وجود أوقات صلاة لهذا الموقع والتاريخ
      final existingRecord = await db.query(
        prayerTimesTable,
        where: 'date = ? AND location_id = ?',
        whereArgs: [defaultDate, locationId],
      );

      if (existingRecord.isEmpty) {
        // إنشاء سجل جديد بأوقات افتراضية
        final result = await db.insert(
          prayerTimesTable,
          {
            'date': defaultDate,
            'location_id': locationId,
            'fajr': defaultTime,
            'sunrise': defaultTime,
            'dhuhr': defaultTime,
            'asr': defaultTime,
            'maghrib': defaultTime,
            'isha': defaultTime,
          },
        );

        if (result > 0) {
          print(
              'تم إضافة أوقات صلاة افتراضية للموقع: $locationName (ID: $locationId)');
          return true;
        } else {
          print('فشل في إضافة أوقات صلاة افتراضية للموقع: $locationName');
          return false;
        }
      } else {
        print(
            'أوقات الصلاة موجودة بالفعل للموقع: $locationName (ID: $locationId)');
        return true; // نعتبرها نجاح لأن البيانات موجودة بالفعل
      }
    } catch (e) {
      print('خطأ أثناء إضافة أوقات صلاة افتراضية للموقع: $e');
      return false;
    }
  }

  // ========================
  // دوال خاصة بجدول الرسائل اليومية
  // ========================

  // جلب جميع الرسائل اليومية
  Future<List<Map<String, dynamic>>> getAllDailyMessages() async {
    final db = await instance.database;
    try {
      return await db.query(dailyMessagesTable, orderBy: 'id DESC');
    } catch (e) {
      print('خطأ في جلب الرسائل اليومية: $e');
      return [];
    }
  }

  // جلب الرسائل اليومية حسب الفئة
  Future<List<Map<String, dynamic>>> getDailyMessagesByCategory(
      String category) async {
    final db = await instance.database;
    try {
      return await db.query(
        dailyMessagesTable,
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'id DESC',
      );
    } catch (e) {
      print('خطأ في جلب الرسائل اليومية حسب الفئة: $e');
      return [];
    }
  }

  // إضافة رسالة يومية جديد
  Future<int> addDailyMessage(
      String title, String content, String category, String source) async {
    final db = await instance.database;
    try {
      final now = DateTime.now().toIso8601String();
      return await db.insert(dailyMessagesTable, {
        'title': title,
        'content': content,
        'category': category,
        'source': source,
        'created_at': now,
      });
    } catch (e) {
      print('خطأ في إضافة رسالة يومية جديدة: $e');
      return -1;
    }
  }

  // تحديث رسالة يومية
  Future<int> updateDailyMessage(int id, String title, String content,
      String category, String source) async {
    final db = await instance.database;
    try {
      return await db.update(
        dailyMessagesTable,
        {
          'title': title,
          'content': content,
          'category': category,
          'source': source,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('خطأ في تحديث الرسالة اليومية: $e');
      return 0;
    }
  }

  // حذف رسالة يومية
  Future<int> deleteDailyMessage(int id) async {
    final db = await instance.database;
    try {
      return await db.delete(
        dailyMessagesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('خطأ في حذف الرسالة اليومية: $e');
      return 0;
    }
  }

  // حذف جميع الرسائل اليومية
  Future<int> deleteAllDailyMessages() async {
    final db = await instance.database;
    try {
      return await db.delete(dailyMessagesTable);
    } catch (e) {
      print('خطأ في حذف جميع الرسائل اليومية: $e');
      return 0;
    }
  }

  // إضافة رسائل يومية افتراضية
  Future<void> addDefaultDailyMessages() async {
    final db = await instance.database;
    try {
      // التحقق من وجود رسائل سابقة
      final messagesCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $dailyMessagesTable'));

      if (messagesCount == 0) {
        print('إضافة رسائل يومية افتراضية...');

        final now = DateTime.now().toIso8601String();
        final defaultMessages = [
          {
            'title': 'فضل الذكر',
            'content':
                'قال رسول الله ﷺ: «مثل الذي يذكر ربه والذي لا يذكر ربه مثل الحي والميت»',
            'category': 'الأذكار',
            'source': 'صحيح البخاري',
            'created_at': now,
          },
          {
            'title': 'فضل الصلاة',
            'content':
                'قال رسول الله ﷺ: «الصلوات الخمس، والجمعة إلى الجمعة، كفارة لما بينهن، ما لم تغش الكبائر»',
            'category': 'الصلاة',
            'source': 'صحيح مسلم',
            'created_at': now,
          },
          {
            'title': 'من آداب الصيام',
            'content':
                'قال رسول الله ﷺ: «إذا كان يوم صوم أحدكم فلا يرفث ولا يصخب، فإن سابه أحد أو قاتله فليقل: إني صائم»',
            'category': 'الصيام',
            'source': 'صحيح البخاري',
            'created_at': now,
          },
        ];

        Batch batch = db.batch();
        for (var message in defaultMessages) {
          batch.insert(dailyMessagesTable, message);
        }
        await batch.commit();

        print('تم إضافة ${defaultMessages.length} رسالة يومية افتراضية بنجاح');
      } else {
        print('توجد رسائل يومية بالفعل في قاعدة البيانات');
      }
    } catch (e) {
      print('خطأ في إضافة رسائل يومية افتراضية: $e');
    }
  }

  // تهيئة جدول الرسائل اليومية
  Future<void> initializeDailyMessagesTable() async {
    final db = await database;
    try {
      // التحقق من وجود الجدول
      final tableExists = await _checkIfTableExists(dailyMessagesTable);

      if (!tableExists) {
        print('جدول الرسائل اليومية غير موجود، جاري إنشاؤه...');
        await db.execute('''
          CREATE TABLE $dailyMessagesTable(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            category TEXT NOT NULL,
            source TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      }

      // إضافة رسائل يومية افتراضية
      await addDefaultDailyMessages();

      print('تم تهيئة جدول الرسائل اليومية بنجاح');
    } catch (e) {
      print('خطأ في تهيئة جدول الرسائل اليومية: $e');
    }
  }

  // دالة لإنشاء جدول السور
  Future<void> initializeSurahsTable() async {
    final db = await database;
    try {
      await db.execute(surahsTableCreate);
      print('تم إنشاء جدول السور بنجاح');
      await _addDefaultSurahs();
    } catch (e) {
      print('خطأ في إنشاء جدول السور: $e');
    }
  }

  // دالة لإضافة السور الافتراضية
  Future<void> _addDefaultSurahs() async {
    final db = await database;
    try {
      // التحقق من وجود سور بالفعل
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $surahsTable'),
      );

      if (count == 0) {
        // إضافة السور الافتراضية
        final surahs = [
          {
            'number': 1,
            'name': 'الفاتحة',
            'verses_count': 7,
            'revelation_place': 'مكة'
          },
          {
            'number': 2,
            'name': 'البقرة',
            'verses_count': 286,
            'revelation_place': 'المدينة'
          },
          {
            'number': 3,
            'name': 'آل عمران',
            'verses_count': 200,
            'revelation_place': 'المدينة'
          },
          {
            'number': 4,
            'name': 'النساء',
            'verses_count': 176,
            'revelation_place': 'المدينة'
          },
          {
            'number': 5,
            'name': 'المائدة',
            'verses_count': 120,
            'revelation_place': 'المدينة'
          },
          {
            'number': 6,
            'name': 'الأنعام',
            'verses_count': 165,
            'revelation_place': 'مكة'
          },
          {
            'number': 7,
            'name': 'الأعراف',
            'verses_count': 206,
            'revelation_place': 'مكة'
          },
          {
            'number': 8,
            'name': 'الأنفال',
            'verses_count': 75,
            'revelation_place': 'المدينة'
          },
          {
            'number': 9,
            'name': 'التوبة',
            'verses_count': 129,
            'revelation_place': 'المدينة'
          },
          {
            'number': 10,
            'name': 'يونس',
            'verses_count': 109,
            'revelation_place': 'مكة'
          },
        ];

        for (var surah in surahs) {
          await db.insert(surahsTable, surah);
        }
        print('تم إضافة السور الافتراضية بنجاح');
      }
    } catch (e) {
      print('خطأ في إضافة السور الافتراضية: $e');
    }
  }

  // دالة للحصول على جميع السور
  Future<List<Map<String, dynamic>>> getAllSurahs() async {
    final db = await database;
    return await db.query(
      surahsTable,
      orderBy: 'number ASC',
    );
  }

  // دالة للحصول على سورة معينة
  Future<Map<String, dynamic>?> getSurah(int number) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      surahsTable,
      where: 'number = ?',
      whereArgs: [number],
    );
    return results.isNotEmpty ? results.first : null;
  }
}
