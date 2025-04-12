import 'package:flutter/material.dart';

/// تعريف ألوان التطبيق الأساسية
class AppColors {
  // الألوان الأساسية
  static const primaryColor = Color(0xFF1F6E8C); // أزرق غامق
  static const secondaryColor = Color(0xFF0E2954); // أزرق داكن
  static const accentColor = Color(0xFF84A7A1); // أخضر فاتح
  
  // ألوان خاصة بالتطبيق
  static const mosqueGreen = Color(0xFF39A388); // أخضر المساجد
  static const quranGold = Color(0xFFD4B12F); // ذهبي للقرآن
  static const prayerBlue = Color(0xFF5089C6); // أزرق للصلاة
  static const dawnColor = Color(0xFFF8B195); // لون الفجر
  static const sunriseColor = Color(0xFFF67280); // لون الشروق
  static const noonColor = Color(0xFFC06C84); // لون الظهر
  static const afternoonColor = Color(0xFF6C5B7B); // لون العصر
  static const sunsetColor = Color(0xFF355C7D); // لون المغرب
  static const nightColor = Color(0xFF2A363B); // لون العشاء
  
  // ألوان وظيفية
  static const successColor = Color(0xFF4CAF50); // أخضر للنجاح
  static const warningColor = Color(0xFFFFC107); // أصفر للتحذير
  static const errorColor = Color(0xFFE53935); // أحمر للخطأ
  static const infoColor = Color(0xFF2196F3); // أزرق للمعلومات
  
  // ألوان المهام
  static const worldlyTaskColor = Color(0xFF5089C6); // أزرق للمهام الدنيوية
  static const religiousTaskColor = Color(0xFF39A388); // أخضر للمهام الأخروية
  static const bothTasksColor = Color(0xFF6C5B7B); // أرجواني للمهام المشتركة
  
  // ألوان محايدة
  static const backgroundColor = Color(0xFFF8F9FA);
  static const surfaceColor = Colors.white;
  static const lightGray = Color(0xFFEEEEEE);
  static const mediumGray = Color(0xFFBDBDBD);
  static const darkGray = Color(0xFF757575);
  
  // ألوان النص
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFF9E9E9E);
  
  // ألوان للسمة الداكنة
  static const darkBackgroundColor = Color(0xFF121212);
  static const darkSurfaceColor = Color(0xFF1E1E1E);
  static const darkPrimaryColor = Color(0xFF4FC3F7);
  static const darkAccentColor = Color(0xFF84A7A1);
  
  // حصول على تدرج لوني للخلفيات
  static LinearGradient getPrayerGradient(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return LinearGradient(
          colors: [dawnColor.withOpacity(0.8), prayerBlue.withOpacity(0.6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'sunrise':
        return LinearGradient(
          colors: [sunriseColor.withOpacity(0.8), quranGold.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'dhuhr':
        return LinearGradient(
          colors: [noonColor.withOpacity(0.8), mosqueGreen.withOpacity(0.6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'asr':
        return LinearGradient(
          colors: [afternoonColor.withOpacity(0.8), accentColor.withOpacity(0.6)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'maghrib':
        return LinearGradient(
          colors: [sunsetColor.withOpacity(0.8), quranGold.withOpacity(0.6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case 'isha':
        return LinearGradient(
          colors: [nightColor.withOpacity(0.8), primaryColor.withOpacity(0.6)],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );
      default:
        return LinearGradient(
          colors: [primaryColor.withOpacity(0.8), accentColor.withOpacity(0.6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }
}