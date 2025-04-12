import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart' as intl;

class NextPrayerWidget extends StatefulWidget {
  final Map<String, dynamic> prayerTimesData;
  final bool isDarkMode;

  const NextPrayerWidget({
    Key? key,
    required this.prayerTimesData,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<NextPrayerWidget> createState() => _NextPrayerWidgetState();
}

class _NextPrayerWidgetState extends State<NextPrayerWidget> {
  late Timer _timer;
  late String _nextPrayer;
  late DateTime _nextPrayerTime;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _calculateNextPrayer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateRemainingTime();
        });
      }
    });
  }

  @override
  void didUpdateWidget(NextPrayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prayerTimesData != widget.prayerTimesData) {
      _calculateNextPrayer();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateNextPrayer() {
    final prayers = [
      {'name': 'fajr', 'arabicName': 'الفجر'},
      {'name': 'sunrise', 'arabicName': 'الشروق'},
      {'name': 'dhuhr', 'arabicName': 'الظهر'},
      {'name': 'asr', 'arabicName': 'العصر'},
      {'name': 'maghrib', 'arabicName': 'المغرب'},
      {'name': 'isha', 'arabicName': 'العشاء'},
    ];

    final now = DateTime.now();
    DateTime? nextTime;
    String? nextPrayerName;
    String? arabicName;

    for (var prayer in prayers) {
      final String timeStr = widget.prayerTimesData[prayer['name']!];
      final time = _parseTime(timeStr);

      if (time.isAfter(now)) {
        if (nextTime == null || time.isBefore(nextTime)) {
          nextTime = time;
          nextPrayerName = prayer['name']!;
          arabicName = prayer['arabicName']!;
        }
      }
    }

    // إذا تجاوزنا جميع الصلوات، فالصلاة التالية هي صلاة الفجر غداً
    if (nextTime == null) {
      final String fajrTimeStr = widget.prayerTimesData['fajr'];
      nextTime = _parseTime(fajrTimeStr).add(const Duration(days: 1));
      nextPrayerName = 'fajr';
      arabicName = 'الفجر';
    }

    _nextPrayer = arabicName!;
    _nextPrayerTime = nextTime;
    _calculateRemainingTime();
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    _remainingTime = _nextPrayerTime.difference(now);
  }

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final format = intl.DateFormat('hh:mm a');
    final time = format.parse(timeStr);
    
    return DateTime(
      now.year, 
      now.month, 
      now.day, 
      time.hour, 
      time.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remainingTime.inHours;
    final minutes = _remainingTime.inMinutes.remainder(60);
    final seconds = _remainingTime.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppColors.getPrayerGradient(_nextPrayer.toLowerCase()),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode 
                ? Colors.black.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Colors.white.withOpacity(0.9),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'الصلاة القادمة',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _nextPrayer,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'الوقت المتبقي',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatTimeUnit(hours)}:${_formatTimeUnit(minutes)}:${_formatTimeUnit(seconds)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            'موعد صلاة $_nextPrayer: ${intl.DateFormat('hh:mm a').format(_nextPrayerTime)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    // حساب نسبة التقدم (من 0 إلى 1)
    final totalSeconds = const Duration(hours: 24).inSeconds;
    final remainingSeconds = _remainingTime.inSeconds;
    final elapsedSeconds = totalSeconds - remainingSeconds;
    final progress = elapsedSeconds / totalSeconds;

    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerRight,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 5,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeUnit(int value) {
    return value.toString().padLeft(2, '0');
  }
}