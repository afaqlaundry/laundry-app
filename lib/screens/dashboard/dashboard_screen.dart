import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';

// ============================================================================
// المتحكم - DashboardController
// ============================================================================

/// نموذج بيانات لوحة المعلومات
class DashboardStats {
  final int pendingCount;
  final int pickedCount;
  final int completedCount;
  final int notReceivedCount;
  final double netProfit;
  final double totalMeters;
  final int unreadNotifications;
  final List<OrderModel> recentOrders;
  final List<double> weeklyProfitData;

  const DashboardStats({
    this.pendingCount = 0,
    this.pickedCount = 0,
    this.completedCount = 0,
    this.notReceivedCount = 0,
    this.netProfit = 0.0,
    this.totalMeters = 0.0,
    this.unreadNotifications = 0,
    this.recentOrders = const [],
    this.weeklyProfitData = const [0, 0, 0, 0, 0, 0, 0],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      pendingCount: _parseInt(json['pendingCount']),
      pickedCount: _parseInt(json['pickedCount']),
      completedCount: _parseInt(json['completedCount']),
      notReceivedCount: _parseInt(json['notReceivedCount']),
      netProfit: _parseDouble(json['netProfit']),
      totalMeters: _parseDouble(json['totalMeters']),
      unreadNotifications: _parseInt(json['unreadNotifications']),
      recentOrders: json['recentOrders'] != null
          ? (json['recentOrders'] as List)
              .take(5)
              .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      weeklyProfitData: json['weeklyProfitData'] != null
          ? (json['weeklyProfitData'] as List)
              .map((e) => _parseDouble(e))
              .toList()
          : [0, 0, 0, 0, 0, 0, 0],
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

/// المتحكم الرئيسي للوحة المعلومات
class DashboardController extends GetxController {
  static DashboardController get to => Get.find();

  final ApiService _api = ApiService.to;

  // ===== حالة التحميل =====
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;

  // ===== بيانات الإحصائيات =====
  final Rx<DashboardStats> stats = const DashboardStats().obs;

  // ===== مؤقت التحديث التلقائي =====
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 30);

  // ===== الفهرس الحالي للشريط السفلي =====
  final RxInt currentTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchDashboardData();
    _startPolling();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  /// بدء التحديث التلقائي كل 30 ثانية
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _fetchDashboardData(silent: true);
    });
  }

  /// جلب بيانات لوحة المعلومات من API
  Future<void> _fetchDashboardData({bool silent = false}) async {
    if (!silent) {
      isLoading.value = true;
    }

    errorMessage.value = '';

    try {
      final response = await _api.get('dashboard');

      if (response != null && response.statusCode == 200) {
        final data = response.data;

        // دعم أنواع مختلفة من الاستجابة
        if (data is Map<String, dynamic>) {
          final statsData = data['data'] ?? data['stats'] ?? data;
          if (statsData is Map<String, dynamic>) {
            stats.value = DashboardStats.fromJson(statsData);
          }
        }

        errorMessage.value = '';
      } else {
        if (!silent) {
          errorMessage.value = 'فشل في تحميل البيانات';
        }
      }
    } catch (e) {
      debugPrint('Dashboard fetch error: $e');
      if (!silent) {
        errorMessage.value = 'حدث خطأ أثناء تحميل البيانات';
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث البيانات (للسحب للتحديث)
  Future<void> refreshData() async {
    isRefreshing.value = true;
    await _fetchDashboardData(silent: false);
    isRefreshing.value = false;
  }

  /// إعادة المحاولة عند الخطأ
  Future<void> retry() async {
    await _fetchDashboardData();
  }

  // ===== Getters مريحة =====
  int get pendingCount => stats.value.pendingCount;
  int get pickedCount => stats.value.pickedCount;
  int get completedCount => stats.value.completedCount;
  int get notReceivedCount => stats.value.notReceivedCount;
  double get netProfit => stats.value.netProfit;
  double get totalMeters => stats.value.totalMeters;
  int get unreadNotifications => stats.value.unreadNotifications;
  List<OrderModel> get recentOrders => stats.value.recentOrders;
  List<double> get weeklyProfitData => stats.value.weeklyProfitData;
  bool get hasError => errorMessage.value.isNotEmpty;
  String get profitDisplay {
    if (netProfit >= 1000) {
      return '${(netProfit / 1000).toStringAsFixed(1)}K';
    }
    return netProfit.toStringAsFixed(0);
  }

  String get metersDisplay {
    return totalMeters.toStringAsFixed(1);
  }

  int get totalOrders =>
      pendingCount + pickedCount + completedCount + notReceivedCount;
}

// ============================================================================
// الشاشة الرئيسية - DashboardScreen
// ============================================================================

/// شاشة لوحة المعلومات الرئيسية
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  // مفاتيح الرسوم المتحركة
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardAnimations = [];

  late AnimationController _headerController;
  late AnimationController _actionsController;
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // رسوم متحركة لشريط العنوان
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // رسوم متحركة لأزرار الإجراءات السريعة
    _actionsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // رسوم متحركة لقائمة الطلبات الأخيرة
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // إنشاء رسوم متحركة متدرجة لبطاقات الإحصائيات (6 بطاقات)
    for (int i = 0; i < 6; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      );
      _cardControllers.add(controller);
      _cardAnimations.add(animation);
    }

    // بدء التسلسل المتدرج
    _runStaggeredAnimations();
  }

  void _runStaggeredAnimations() {
    // شريط العنوان أولاً
    _headerController.forward();

    // بطاقات الإحصائيات متدرجة
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(
        Duration(milliseconds: 200 + (i * 80)),
        () {
          if (mounted) {
            _cardControllers[i].forward();
          }
        },
      );
    }

    // أزرار الإجراءات بعد البطاقات
    Future.delayed(
      const Duration(milliseconds: 700),
      () {
        if (mounted) _actionsController.forward();
      },
    );

    // قائمة الطلبات الأخيرة أخيراً
    Future.delayed(
      const Duration(milliseconds: 900),
      () {
        if (mounted) _listController.forward();
      },
    );
  }

  @override
  void dispose() {
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    _headerController.dispose();
    _actionsController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: Obx(() {
                final controller = Get.put(DashboardController());
                if (controller.isLoading.value) {
                  return _buildShimmerLoading();
                }
                if (controller.hasError) {
                  return _buildErrorState(controller);
                }
                return RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: Colors.white,
                  displacement: 40.h,
                  strokeWidth: 2.5.w,
                  onRefresh: () => controller.refreshData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: AppSpacing.md.h),
                        _buildGreetingSection(),
                        SizedBox(height: AppSpacing.lg.h),
                        _buildMiniChart(),
                        SizedBox(height: AppSpacing.lg.h),
                        _buildStatsGrid(),
                        SizedBox(height: AppSpacing.lg.h),
                        _buildQuickActions(),
                        SizedBox(height: AppSpacing.lg.h),
                        _buildRecentOrders(),
                        SizedBox(height: 100.h),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ===== شريط العنوان =====
  Widget _buildAppBar(BuildContext context) {
    return FadeTransition(
      opacity: _headerController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _headerController,
          curve: Curves.easeOutCubic,
        )),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24.r),
              bottomRight: Radius.circular(24.r),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md.w,
              vertical: AppSpacing.sm.h,
            ),
            child: Row(
              children: [
                // أيقونة التطبيق
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    FontAwesomeIcons.rug,
                    color: AppColors.accentLight,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: AppSpacing.sm.w),
                // اسم المغسلة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مغسلة الأفق',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'إدارة السجاد',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11.sp,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.sm.w),
                // زر البحث
                _buildAppBarIconButton(
                  icon: FontAwesomeIcons.magnifyingGlass,
                  onTap: () {
                    // TODO: التنقل لصفحة البحث
                  },
                ),
                SizedBox(width: 4.w),
                // زر الإشعارات مع الشارة
                Obx(() {
                  final controller = Get.find<DashboardController>();
                  return _buildNotificationButton(
                    unreadCount: controller.unreadNotifications,
                    onTap: () {
                      // TODO: التنقل لصفحة الإشعارات
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// زر أيقونة في شريط العنوان
  Widget _buildAppBarIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16.sp,
        ),
      ),
    );
  }

  /// زر الإشعارات مع شارة العدد
  Widget _buildNotificationButton({
    required int unreadCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Badge(
          isLabelVisible: unreadCount > 0,
          label: Text(
            unreadCount > 99 ? '99+' : '$unreadCount',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.danger,
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
          offset: Offset(-4.w, -4.h),
          child: Icon(
            FontAwesomeIcons.bell,
            color: Colors.white,
            size: 16.sp,
          ),
        ),
      ),
    );
  }

  // ===== قسم التحية =====
  Widget _buildGreetingSection() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'صباح الخير';
    } else if (hour < 17) {
      greeting = 'مساء الخير';
    } else {
      greeting = 'مساء الخير';
    }

    return Obx(() {
      final controller = Get.find<DashboardController>();
      return FadeTransition(
        opacity: _headerController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  FontAwesomeIcons.handSparkles,
                  color: AppColors.accent,
                  size: 18.sp,
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'لديك ${controller.totalOrders} طلب نشط',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: AppFontSizes.md.sp,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ===== الرسم البياني المصغر =====
  Widget _buildMiniChart() {
    return FadeTransition(
      opacity: _headerController,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'أرباح الأسبوع',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: AppFontSizes.md.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.arrowTrendUp,
                        size: 10.sp,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '+12%',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: AppFontSizes.xs.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm.h),
            SizedBox(
              height: 120.h,
              child: Obx(() {
                final controller = Get.find<DashboardController>();
                return LineChart(
                  _buildWeeklyChartData(controller.weeklyProfitData),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// إعدادات الرسم البياني الأسبوعي
  LineChartData _buildWeeklyChartData(List<double> data) {
    final maxVal = data.isEmpty
        ? 1.0
        : data.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1.0 : maxVal;

    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const days = ['سبت', 'أحد', 'اثن', 'ثلا', 'أرب', 'خمي', 'جمع'];
              final index = value.toInt();
              if (index < 0 || index >= days.length) return const SizedBox();
              return Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  days[index],
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 9.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              );
            },
            reservedSize: 28.h,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(
            data.length.clamp(0, 7),
            (i) => FlSpot(i.toDouble(), data[i]),
          ),
          isCurved: true,
          curveSmoothness: 0.4,
          color: AppColors.accent,
          barWidth: 2.5.w,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3.r,
                color: Colors.white,
                strokeWidth: 2.w,
                strokeColor: AppColors.accent,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.2),
                AppColors.accent.withValues(alpha: 0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      minY: 0,
      maxY: safeMax * 1.2,
    );
  }

  // ===== شبكة بطاقات الإحصائيات =====
  Widget _buildStatsGrid() {
    return Obx(() {
      final controller = Get.find<DashboardController>();
      final cards = _buildStatCards(controller);

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm.w,
        mainAxisSpacing: AppSpacing.sm.h,
        childAspectRatio: 0.85,
        children: List.generate(cards.length, (index) {
          if (index < _cardAnimations.length) {
            return ScaleTransition(
              scale: _cardAnimations[index],
              child: FadeTransition(
                opacity: _cardAnimations[index],
                child: cards[index],
              ),
            );
          }
          return cards[index];
        }),
      );
    });
  }

  /// بناء قائمة بطاقات الإحصائيات
  List<Widget> _buildStatCards(DashboardController controller) {
    return [
      // قيد الانتظار - Amber
      _StatCard(
        title: 'قيد الانتظار',
        value: '${controller.pendingCount}',
        icon: FontAwesomeIcons.clock,
        color: AppColors.warning,
        lightColor: const Color(0xFFFEF3C7),
        onTap: () => _navigateToFilteredOrders('pending'),
      ),
      // بانتظار البيانات - Blue
      _StatCard(
        title: 'بانتظار البيانات',
        value: '${controller.pickedCount}',
        icon: FontAwesomeIcons.truckRampBox,
        color: AppColors.info,
        lightColor: const Color(0xFFDBEAFE),
        onTap: () => _navigateToFilteredOrders('picked'),
      ),
      // تم التسليم - Green
      _StatCard(
        title: 'تم التسليم',
        value: '${controller.completedCount}',
        icon: FontAwesomeIcons.circleCheck,
        color: AppColors.success,
        lightColor: const Color(0xFFD1FAE5),
        onTap: () => _navigateToFilteredOrders('completed'),
      ),
      // غير مستلم - Red
      _StatCard(
        title: 'غير مستلم',
        value: '${controller.notReceivedCount}',
        icon: FontAwesomeIcons.circleXmark,
        color: AppColors.danger,
        lightColor: const Color(0xFFFEE2E2),
        onTap: () => _navigateToFilteredOrders('no'),
      ),
      // صافي الربح - Gold gradient
      _StatCard(
        title: 'صافي الربح',
        value: '${controller.profitDisplay} ر.س',
        icon: FontAwesomeIcons.coins,
        color: AppColors.accent,
        lightColor: AppColors.accentLight.withValues(alpha: 0.15),
        isGradient: true,
        onTap: () {
          // TODO: التنقل لتقرير الأرباح
        },
      ),
      // الأمتار م² - Indigo
      _StatCard(
        title: 'الأمتار م\u00B2',
        value: controller.metersDisplay,
        icon: FontAwesomeIcons.rulerCombined,
        color: const Color(0xFF4F46E5),
        lightColor: const Color(0xFFEEF2FF),
        onTap: () {
          // TODO: التنقل لتقرير الأمتار
        },
      ),
    ];
  }

  // ===== أزرار الإجراءات السريعة =====
  Widget _buildQuickActions() {
    return FadeTransition(
      opacity: _actionsController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _actionsController,
          curve: Curves.easeOutCubic,
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إجراءات سريعة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: AppFontSizes.lg.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: AppSpacing.md.h),
            Row(
              children: [
                // زر طلبات اليوم - بارز بالذهبي
                Expanded(
                  child: _QuickActionButton(
                    label: 'طلبات اليوم',
                    icon: FontAwesomeIcons.calendarDay,
                    isPrimary: true,
                    onTap: () {
                      // TODO: التنقل لطلبات اليوم
                    },
                  ),
                ),
                SizedBox(width: AppSpacing.sm.w),
                // زر إضافة طلب
                Expanded(
                  child: _QuickActionButton(
                    label: 'إضافة طلب',
                    icon: FontAwesomeIcons.plus,
                    onTap: () {
                      // TODO: التنقل لإضافة طلب جديد
                    },
                  ),
                ),
                SizedBox(width: AppSpacing.sm.w),
                // زر تتبع المناديب
                Expanded(
                  child: _QuickActionButton(
                    label: 'تتبع المناديب',
                    icon: FontAwesomeIcons.locationDot,
                    onTap: () {
                      // TODO: التنقل لتتبع المناديب
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== قائمة الطلبات الأخيرة =====
  Widget _buildRecentOrders() {
    return FadeTransition(
      opacity: _listController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _listController,
          curve: Curves.easeOutCubic,
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'أحدث الطلبات',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: AppFontSizes.lg.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: التنقل لجميع الطلبات
                  },
                  child: Text(
                    'عرض الكل',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: AppFontSizes.sm.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md.h),
            Obx(() {
              final controller = Get.find<DashboardController>();
              final orders = controller.recentOrders;

              if (orders.isEmpty) {
                return _buildEmptyOrdersState();
              }

              return Column(
                children: orders.map((order) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                    child: _RecentOrderCard(order: order),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// حالة عدم وجود طلبات
  Widget _buildEmptyOrdersState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(
            FontAwesomeIcons.inbox,
            size: 40.sp,
            color: AppColors.textMuted.withValues(alpha: 0.4),
          ),
          SizedBox(height: AppSpacing.md.h),
          Text(
            'لا توجد طلبات حتى الآن',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: AppFontSizes.md.sp,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ===== حالة الخطأ =====
  Widget _buildErrorState(DashboardController controller) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.triangleExclamation,
              size: 48.sp,
              color: AppColors.danger.withValues(alpha: 0.6),
            ),
            SizedBox(height: AppSpacing.lg.h),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: AppFontSizes.lg.sp,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            ElevatedButton.icon(
              onPressed: controller.retry,
              icon: Icon(Icons.refresh, size: 18.sp),
              label: Text(
                'إعادة المحاولة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: AppFontSizes.md.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg.w,
                  vertical: AppSpacing.md.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== تأثير التحميل الوهمي (Shimmer) =====
  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.md.h),
            // تحية وهمية
            Container(
              width: 120.w,
              height: 24.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              width: 180.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            // رسم بياني وهمي
            Container(
              width: double.infinity,
              height: 180.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            // بطاقات إحصائيات وهمية
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm.w,
              mainAxisSpacing: AppSpacing.sm.h,
              childAspectRatio: 0.85,
              children: List.generate(
                6,
                (_) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            // عنوان وهمي
            Container(
              width: 100.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            SizedBox(height: AppSpacing.md.h),
            // بطاقات طلبات وهمية
            ...List.generate(
              3,
              (_) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                child: Container(
                  width: double.infinity,
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  // ===== الشريط السفلي =====
  Widget _buildBottomNav() {
    final controller = Get.put(DashboardController());

    return Obx(() {
      final currentIndex = controller.currentTabIndex.value;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md.w,
              vertical: AppSpacing.xs.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // الرئيسية
                _BottomNavItem(
                  icon: FontAwesomeIcons.house,
                  label: 'الرئيسية',
                  isActive: currentIndex == 0,
                  onTap: () => controller.currentTabIndex.value = 0,
                ),
                // الطلبات
                _BottomNavItem(
                  icon: FontAwesomeIcons.clipboardList,
                  label: 'الطلبات',
                  isActive: currentIndex == 1,
                  onTap: () => controller.currentTabIndex.value = 1,
                ),
                // مساحة للزر العائم
                SizedBox(width: 56.w),
                // الإضافة
                _BottomNavItem(
                  icon: FontAwesomeIcons.fileCirclePlus,
                  label: 'الإضافة',
                  isActive: currentIndex == 2,
                  onTap: () => controller.currentTabIndex.value = 2,
                ),
                // المزيد
                _BottomNavItem(
                  icon: FontAwesomeIcons.ellipsisVertical,
                  label: 'المزيد',
                  isActive: currentIndex == 3,
                  badgeCount: controller.unreadNotifications,
                  onTap: () => controller.currentTabIndex.value = 3,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// الزر العائم المركزي
  Widget _buildFloatingActionButton() {
    return Container(
      height: 56.h,
      width: 56.w,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            // TODO: فتح صفحة إضافة طلب جديد
            HapticFeedback.lightImpact();
          },
          child: Icon(
            FontAwesomeIcons.plus,
            color: Colors.white,
            size: 22.sp,
          ),
        ),
      ),
    );
  }

  // ===== التنقل =====
  void _navigateToFilteredOrders(String status) {
    HapticFeedback.lightImpact();
    // TODO: Get.toNamed('/orders', arguments: {'status': status});
  }
}

// ============================================================================
// مكونات مخصصة
// ============================================================================

/// بطاقة إحصائية
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color lightColor;
  final bool isGradient;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.lightColor,
    this.isGradient = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isGradient ? null : Colors.white,
          gradient: isGradient
              ? LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
              : null,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الأيقونة
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: isGradient
                      ? Colors.white.withValues(alpha: 0.2)
                      : lightColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: isGradient ? Colors.white : color,
                  size: 16.sp,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              // القيمة
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isGradient ? Colors.white : AppColors.text,
                    height: 1.1,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              // العنوان
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: isGradient
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر إجراء سريع
class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm.w,
          vertical: AppSpacing.md.h,
        ),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentLight],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
              : null,
          color: isPrimary ? null : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? AppColors.accent.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : AppColors.primary,
                size: 18.sp,
              ),
            ),
            SizedBox(height: AppSpacing.sm.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.white : AppColors.text,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة طلب حديث
class _RecentOrderCard extends StatelessWidget {
  final OrderModel order;

  const _RecentOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor =
        AppColors.statusColors[order.orderStatus] ?? AppColors.textMuted;
    final statusLightColor =
        AppColors.statusLightColors[order.orderStatus] ?? AppColors.bg;
    final timeAgo = _getTimeAgo(order.createdAt);

    return Container(
      padding: EdgeInsets.all(AppSpacing.md.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // شارة الحالة على اليمين
          Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              color: statusLightColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(order.orderStatus),
                  color: statusColor,
                  size: 16.sp,
                ),
                SizedBox(height: 2.h),
                Container(
                  width: 6.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          // تفاصيل الطلب
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.customerName.isNotEmpty
                            ? order.customerName
                            : 'عميل بدون اسم',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: AppFontSizes.md.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: AppFontSizes.xs.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    if (order.neighborhood.isNotEmpty) ...[
                      Icon(
                        FontAwesomeIcons.locationDot,
                        size: 10.sp,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          order.neighborhood,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: AppFontSizes.sm.sp,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    // شارة الحالة
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusLightColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        order.statusText,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm.w),
                    if (order.totalPrice > 0) ...[
                      Icon(
                        FontAwesomeIcons.moneyBillWave,
                        size: 10.sp,
                        color: AppColors.accent,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${order.totalPrice.toStringAsFixed(0)} ر.س',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: AppFontSizes.sm.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (order.totalMeters > 0)
                      Text(
                        '${order.totalMeters.toStringAsFixed(1)} م\u00B2',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: AppFontSizes.xs.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // سهم التنقل
          Icon(
            FontAwesomeIcons.chevronLeft,
            size: 12.sp,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  /// أيقونة الحالة
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return FontAwesomeIcons.clock;
      case 'picked':
        return FontAwesomeIcons.truckRampBox;
      case 'data_ready':
      case 'ready_for_delivery':
        return FontAwesomeIcons.boxOpen;
      case 'completed':
        return FontAwesomeIcons.circleCheck;
      case 'cancelled':
      case 'no':
        return FontAwesomeIcons.circleXmark;
      default:
        return FontAwesomeIcons.circleQuestion;
    }
  }

  /// حساب الوقت المنقضي
  String _getTimeAgo(int timestamp) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'الآن';
    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} د';
    }
    if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} س';
    }
    if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} ي';
    }
    return '${date.day}/${date.month}';
  }
}

/// عنصر الشريط السفلي
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int? badgeCount;
  final VoidCallback? onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.badgeCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.textMuted.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 4.h),
          Badge(
            isLabelVisible: badgeCount != null && badgeCount! > 0 && !isActive,
            label: Text(
              badgeCount! > 99 ? '99+' : '$badgeCount',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 8.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.danger,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            offset: Offset(-6.w, -6.h),
            child: Icon(
              icon,
              size: 20.sp,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10.sp,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
