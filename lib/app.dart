import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/theme_service.dart';
import 'services/push_notification_service.dart';
import 'screens/login/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/orders/add_order_screen.dart';
import 'screens/delegates/delegates_screen.dart';
import 'screens/delegates/tracking_screen.dart';
import 'screens/expenses/expenses_screen.dart';
import 'screens/carpet_sizes/carpet_sizes_screen.dart';
import 'screens/workers/workers_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/settings/settings_screen.dart';

class LaundryApp extends StatelessWidget {
  const LaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = Get.put(ThemeService());
    final AuthService authService = Get.put(AuthService());
    final ApiService apiService = Get.put(ApiService());
    final PushNotificationService pushService = Get.put(PushNotificationService());
    final LaundrySettingsService settingsService = Get.put(LaundrySettingsService());

    return Obx(() {
      return GetMaterialApp(
        title: settingsService.laundryName.value,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeService.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,

        // اتجاه RTL
        textDirection: TextDirection.rtl,

        // خط عربي افتراضي
        defaultTextStyle: const TextStyle(fontFamily: 'Tajawal'),

        // ألوان التطبيق
        color: const Color(0xFF0B3D2E),

        // شريط الحالة
        builder: (context, child) {
          SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ));
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textDirection: TextDirection.rtl),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },

        // الصفحة الرئيسية
        initialRoute: authService.isLoggedIn.value ? '/home' : '/login',
        getPages: [
          // ===== تسجيل الدخول =====
          GetPage(
            name: '/login',
            page: () => const LoginScreen(),
            transition: Transition.fadeIn,
            transitionDuration: const Duration(milliseconds: 400),
          ),

          // ===== الصفحة الرئيسية / لوحة التحكم =====
          GetPage(
            name: '/home',
            page: () => const DashboardScreen(),
            transition: Transition.fadeIn,
          ),

          // ===== إدارة الطلبات =====
          GetPage(
            name: '/orders',
            page: () => const OrdersScreen(),
            transition: Transition.rightToLeft,
          ),
          GetPage(
            name: '/orders/add',
            page: () => const AddOrderScreen(),
            transition: Transition.rightToLeft,
          ),
          GetPage(
            name: '/orders/edit',
            page: () => const AddOrderScreen(),
            transition: Transition.rightToLeft,
          ),

          // ===== إدارة المندوبين =====
          GetPage(
            name: '/delegates',
            page: () => const DelegatesScreen(),
            transition: Transition.rightToLeft,
          ),
          GetPage(
            name: '/tracking',
            page: () => const TrackingScreen(),
            transition: Transition.rightToLeft,
          ),

          // ===== المصروفات =====
          GetPage(
            name: '/expenses',
            page: () => const ExpensesScreen(),
            transition: Transition.rightToLeft,
          ),

          // ===== مقاسات السجاد =====
          GetPage(
            name: '/carpet-sizes',
            page: () => const CarpetSizesScreen(),
            transition: Transition.rightToLeft,
          ),

          // ===== العمال والرواتب =====
          GetPage(
            name: '/workers',
            page: () => const WorkersScreen(),
            transition: Transition.rightToLeft,
          ),

          // ===== التقارير =====
          GetPage(
            name: '/reports',
            page: () => const ReportsScreen(),
            transition: Transition.rightToLeft,
          ),

          // ===== سجل العملاء =====
          GetPage(
            name: '/customers',
            page: () => const CustomersScreen(),
            transition: Transition.rightToLeft,
          ),

          // ===== الإعدادات =====
          GetPage(
            name: '/settings',
            page: () => const SettingsScreen(),
            transition: Transition.rightToLeft,
          ),
        ],

        // إعدادات اللغة
        locale: const Locale('ar', 'SA'),
        fallbackLocale: const Locale('ar', 'SA'),
      );
    });
  }
}
