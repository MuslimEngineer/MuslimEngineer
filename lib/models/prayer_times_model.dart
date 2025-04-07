// نموذج بيانات أوقات الصلاة
class PrayerTimesModel {
  final int? id;
  final String date;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final int? cityId;

  PrayerTimesModel({
    this.id,
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.cityId,
  });

  // تحويل النموذج إلى Map لتخزينه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'location_id': cityId,
    };
  }

  // إنشاء نموذج من Map مستردة من قاعدة البيانات
  factory PrayerTimesModel.fromMap(Map<String, dynamic> map) {
    return PrayerTimesModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      fajr: map['fajr'] as String,
      sunrise: map['sunrise'] as String,
      dhuhr: map['dhuhr'] as String,
      asr: map['asr'] as String,
      maghrib: map['maghrib'] as String,
      isha: map['isha'] as String,
      cityId: map['location_id'] as int?,
    );
  }

  // إنشاء نسخة معدلة من النموذج
  PrayerTimesModel copyWith({
    int? id,
    String? date,
    String? fajr,
    String? sunrise,
    String? dhuhr,
    String? asr,
    String? maghrib,
    String? isha,
    int? cityId,
  }) {
    return PrayerTimesModel(
      id: id ?? this.id,
      date: date ?? this.date,
      fajr: fajr ?? this.fajr,
      sunrise: sunrise ?? this.sunrise,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
      cityId: cityId ?? this.cityId,
    );
  }

  @override
  String toString() {
    return 'PrayerTimes{id: $id, date: $date, fajr: $fajr, sunrise: $sunrise, dhuhr: $dhuhr, asr: $asr, maghrib: $maghrib, isha: $isha}';
  }
}
