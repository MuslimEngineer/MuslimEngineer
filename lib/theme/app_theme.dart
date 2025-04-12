import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'app_colors.dart';

/// توفير سمات التطبيق
class AppTheme {
  /// إنشاء سمة للوضع الفاتح
  static ThemeData lightTheme() {
    final base = FlexThemeData.light(
      scheme: FlexScheme.aquaBlue,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 9,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        inputDecoratorRadius: 12.0,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        fabRadius: 16.0,
        tooltipRadius: 4.0,
        popupMenuRadius: 6.0,
        bottomSheetRadius: 20.0,
        bottomSheetElevation: 8.0,
        dialogBackgroundSchemeColor: SchemeColor.surface,
        cardElevation: 2.0,
        drawerElevation: 2.0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        tertiary: AppColors.accentColor,
        surface: AppColors.surfaceColor,
        background: AppColors.backgroundColor,
      ),
      textTheme: _getArabicTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceColor,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.secondaryColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightGray,
        disabledColor: AppColors.lightGray.withOpacity(0.5),
        selectedColor: AppColors.primaryColor,
        secondarySelectedColor: AppColors.secondaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.lightGray,
        thickness: 1,
        space: 16,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
      ),
    );
  }

  /// إنشاء سمة للوضع الداكن
  static ThemeData darkTheme() {
    final base = FlexThemeData.dark(
      scheme: FlexScheme.aquaBlue,
      surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
      blendLevel: 15,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        inputDecoratorRadius: 12.0,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        fabRadius: 16.0,
        tooltipRadius: 4.0,
        popupMenuRadius: 6.0,
        bottomSheetRadius: 20.0,
        bottomSheetElevation: 8.0,
        dialogBackgroundSchemeColor: SchemeColor.surface,
        cardElevation: 2.0,
        drawerElevation: 2.0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.darkPrimaryColor,
        secondary: AppColors.secondaryColor.withOpacity(0.8),
        tertiary: AppColors.darkAccentColor,
        surface: AppColors.darkSurfaceColor,
        background: AppColors.darkBackgroundColor,
      ),
      textTheme: _getArabicTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurfaceColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurfaceColor,
        selectedItemColor: AppColors.darkPrimaryColor,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkSurfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.secondaryColor.withOpacity(0.8),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[800]!,
        disabledColor: Colors.grey[800]!.withOpacity(0.5),
        selectedColor: AppColors.darkPrimaryColor,
        secondarySelectedColor: AppColors.secondaryColor.withOpacity(0.8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[700]!,
        thickness: 1,
        space: 16,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.darkPrimaryColor,
        unselectedLabelColor: Colors.grey[400],
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.darkPrimaryColor, width: 2),
        ),
      ),
    );
  }

  /// إنشاء سمة نص للخطوط العربية
  static TextTheme _getArabicTextTheme(TextTheme base) {
    const fontFamily = 'Tajawal';
    
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: fontFamily),
      displayMedium: base.displayMedium?.copyWith(fontFamily: fontFamily),
      displaySmall: base.displaySmall?.copyWith(fontFamily: fontFamily),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: fontFamily),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: fontFamily),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: fontFamily),
      titleLarge: base.titleLarge?.copyWith(fontFamily: fontFamily),
      titleMedium: base.titleMedium?.copyWith(fontFamily: fontFamily),
      titleSmall: base.titleSmall?.copyWith(fontFamily: fontFamily),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: fontFamily),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: fontFamily),
      bodySmall: base.bodySmall?.copyWith(fontFamily: fontFamily),
      labelLarge: base.labelLarge?.copyWith(fontFamily: fontFamily),
      labelMedium: base.labelMedium?.copyWith(fontFamily: fontFamily),
      labelSmall: base.labelSmall?.copyWith(fontFamily: fontFamily),
    );
  }
}