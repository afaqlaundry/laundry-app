import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme_service.dart';

/// ثيم التطبيق
class AppTheme {
  static ThemeService get _theme => ThemeService.to;

  // ===== الثيم الفاتح =====
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Tajawal',
      scaffoldBackgroundColor: const Color(0xFFF5F0E8),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF0B3D2E),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFF1B5E3B),
        secondary: const Color(0xFFC8963E),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFD4A853),
        surface: Colors.white,
        onSurface: const Color(0xFF1C1917),
        error: const Color(0xFFDC2626),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B3D2E),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF0B3D2E),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE7E0D5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE7E0D5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC8963E), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: Color(0xFF78716C),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: Color(0xFF78716C),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFC8963E),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF0B3D2E),
        unselectedItemColor: Color(0xFF78716C),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
        unselectedLabelStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF0B3D2E),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE7E0D5),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF5F0E8),
        selectedColor: const Color(0xFF0B3D2E),
        labelStyle: const TextStyle(fontFamily: 'Tajawal'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // ===== الثيم الداكن =====
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Tajawal',
      scaffoldBackgroundColor: const Color(0xFF0B3D2E),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF2D8659),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFF1B5E3B),
        secondary: const Color(0xFFD4A853),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFC8963E),
        surface: const Color(0xFF134D3A),
        onSurface: const Color(0xFFF5F0E8),
        error: const Color(0xFFEF4444),
        onError: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF134D3A),
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF071F17),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF134D3A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B5E3B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B5E3B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC8963E), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: Color(0xFF78716C),
        ),
      ),
    );
  }
}

/// ألوان التطبيق
class AppColors {
  // الألوان الأساسية
  static const Color primaryDark = Color(0xFF071F17);
  static const Color primary = Color(0xFF0B3D2E);
  static const Color primaryMid = Color(0xFF1B5E3B);
  static const Color primaryLight = Color(0xFF2D8659);

  // ألوان التمييز
  static const Color accent = Color(0xFFC8963E);
  static const Color accentLight = Color(0xFFD4A853);

  // ألوان الخلفية
  static const Color bg = Color(0xFFF5F0E8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1C1917);
  static const Color textMuted = Color(0xFF78716C);
  static const Color border = Color(0xFFE7E0D5);

  // ألوان الحالة
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);
  static const Color whatsapp = Color(0xFF25D366);

  // ألوان حالة الطلب
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusPicked = Color(0xFF2563EB);
  static const Color statusDataReady = Color(0xFF0891B2);
  static const Color statusReadyDelivery = Color(0xFF059669);
  static const Color statusCompleted = Color(0xFF16A34A);
  static const Color statusCancelled = Color(0xFFDC2626);
  static const Color statusNotReceived = Color(0xFF9333EA);

  // ألوان حالة الطلب مع الخلفية
  static const Map<String, Color> statusColors = {
    'pending': statusPending,
    'picked': statusPicked,
    'data_ready': statusDataReady,
    'ready_for_delivery': statusReadyDelivery,
    'completed': statusCompleted,
    'cancelled': statusCancelled,
    'no': statusNotReceived,
  };

  // ألوان خلفية خفيفة للحالات
  static const Map<String, Color> statusLightColors = {
    'pending': Color(0xFFFEF3C7),
    'picked': Color(0xFFDBEAFE),
    'data_ready': Color(0xFFCFFAFE),
    'ready_for_delivery': Color(0xFFD1FAE5),
    'completed': Color(0xFFD1FAE5),
    'cancelled': Color(0xFFFEE2E2),
    'no': Color(0xFFFDF4FF),
  };
}

/// مسافات وأبعاد ثابتة
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// أحجام الخطوط
class AppFontSizes {
  static const double xs = 10.0;
  static const double sm = 12.0;
  static const double md = 14.0;
  static const double lg = 16.0;
  static const double xl = 18.0;
  static const double xxl = 24.0;
  static const double title = 28.0;
  static const double display = 36.0;
}
