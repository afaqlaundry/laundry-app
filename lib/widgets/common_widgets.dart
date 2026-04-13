import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../utils/helpers.dart';

// ============================================================
// StatCard - بطاقة إحصائية
// ============================================================

/// بطاقة تعرض أيقونة وقيمة ووصف
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconBgColor;
  final Color? iconColor;
  final bool gradient;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconBgColor,
    this.iconColor,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = iconBgColor ?? AppColors.primary.withOpacity(0.1);
    final fgColor = iconColor ?? AppColors.primary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: gradient
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryMid,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: gradient
                    ? Colors.white.withOpacity(0.2)
                    : bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: gradient ? Colors.white : fgColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: gradient
                      ? Colors.white
                      : isDark
                          ? AppColors.accent
                          : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: AppFontSizes.sm,
                color: gradient
                    ? Colors.white70
                    : isDark
                        ? Colors.white60
                        : AppColors.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// StatusBadge - شارة الحالة
// ============================================================

/// شارة ملونة تعرض حالة الطلب
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    final text = statusText(status);
    final lightColor = statusLightColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: AppFontSizes.sm,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// لون خفيف خلفية الحالة
  static Color statusLightColor(String status) {
    const Map<String, Color> lightColors = {
      'pending': Color(0xFFFEF3C7),
      'picked': Color(0xFFDBEAFE),
      'data_ready': Color(0xFFCFFAFE),
      'ready_for_delivery': Color(0xFFD1FAE5),
      'completed': Color(0xFFBBF7D0),
      'cancelled': Color(0xFFFEE2E2),
      'no': Color(0xFFFDF4FF),
    };
    return lightColors[status] ?? const Color(0xFFF5F0E8);
  }
}

// ============================================================
// EmptyState - حالة فارغة
// ============================================================

/// ويدجت حالة فارغة مع أيقونة وعنوان وزر إعادة المحاولة
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle = '',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: isDark
                    ? AppColors.accent.withOpacity(0.6)
                    : AppColors.primary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.text,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: AppFontSizes.md,
                  color: isDark ? Colors.white60 : AppColors.textMuted,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LoadingOverlay - طبقة التحميل
// ============================================================

/// طبقة تحميل شفافة تغطي المحتوى
class LoadingOverlay extends StatelessWidget {
  final String message;
  final bool isLoading;

  const LoadingOverlay({
    super.key,
    this.message = 'جارٍ التحميل...',
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Stack(
      children: [
        // خلفية معتمة
        Positioned.fill(
          child: Container(
            color: Colors.black38,
            child: const SizedBox.expand(),
          ),
        ),
        // محتوى التحميل
        Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: AppFontSizes.md,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ConfirmDialog - نافذة تأكيد
// ============================================================

/// نافذة تأكيد قابلة لإعادة الاستخدام
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final IconData? icon;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'تأكيد',
    this.cancelText = 'إلغاء',
    this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.icon,
  });

  /// عرض نافذة التأكيد كـ dialog
  static Future<bool?> show({
    required String title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Color? confirmColor,
    IconData? icon,
  }) {
    return Get.dialog<bool>(
      ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmColor: confirmColor,
        icon: icon,
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dangerColor = confirmColor ?? AppColors.danger;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: dangerColor, size: 24),
            ),
          if (icon != null) const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: AppFontSizes.lg,
          color: AppColors.textMuted,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onCancel?.call();
            Get.back(result: false);
          },
          child: Text(
            cancelText,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm?.call();
            Get.back(result: true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: dangerColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: AppFontSizes.md,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CustomDrawer - القائمة الجانبية الرئيسية
// ============================================================

/// نموذج عنصر القائمة الجانبية
class _DrawerItem {
  final String label;
  final IconData icon;
  final String route;
  final String? group;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
    this.group,
  });
}

/// نموذج مجموعة في القائمة
class _DrawerGroup {
  final String title;
  final String icon;
  final List<_DrawerItem> items;

  const _DrawerGroup({
    required this.title,
    required this.icon,
    required this.items,
  });
}

/// القائمة الجانبية الرئيسية للتطبيق
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  /// مجموعات القائمة الجانبية
  static const List<_DrawerGroup> _groups = [
    _DrawerGroup(
      title: 'الرئيسية',
      icon: '🏠',
      items: [
        _DrawerItem(label: 'لوحة التحكم', icon: Icons.dashboard, route: '/home'),
        _DrawerItem(label: 'طلبات اليوم', icon: Icons.today, route: '/today-orders'),
      ],
    ),
    _DrawerGroup(
      title: 'الإدارة',
      icon: '⚙️',
      items: [
        _DrawerItem(label: 'إضافة طلب', icon: Icons.add_circle, route: '/add-order'),
        _DrawerItem(label: 'إدارة الطلبات', icon: Icons.list_alt, route: '/orders'),
        _DrawerItem(label: 'المندوبون', icon: Icons.delivery_dining, route: '/delegates'),
        _DrawerItem(label: 'المصروفات', icon: Icons.receipt_long, route: '/expenses'),
        _DrawerItem(label: 'مقاسات السجاد', icon: Icons.straighten, route: '/carpet-sizes'),
        _DrawerItem(label: 'العمال', icon: Icons.people, route: '/workers'),
      ],
    ),
    _DrawerGroup(
      title: 'التحليل',
      icon: '📊',
      items: [
        _DrawerItem(label: 'طلبات الشهر', icon: Icons.calendar_month, route: '/monthly-orders'),
        _DrawerItem(label: 'التقارير', icon: Icons.assessment, route: '/reports'),
        _DrawerItem(label: 'البحث', icon: Icons.search, route: '/search'),
        _DrawerItem(label: 'التتبع', icon: Icons.my_location, route: '/tracking'),
        _DrawerItem(label: 'العملاء', icon: Icons.contacts, route: '/customers'),
      ],
    ),
    _DrawerGroup(
      title: 'الإعدادات',
      icon: '🔧',
      items: [
        _DrawerItem(label: 'إعدادات الفاتورة', icon: Icons.receipt, route: '/invoice-settings'),
        _DrawerItem(label: 'إعدادات المغسلة', icon: Icons.local_laundry_service, route: '/laundry-settings'),
        _DrawerItem(label: 'المظهر', icon: Icons.palette, route: '/theme-settings'),
        _DrawerItem(label: 'واتساب', icon: Icons.chat, route: '/whatsapp-settings'),
        _DrawerItem(label: 'النسخ الاحتياطي', icon: Icons.cloud_upload, route: '/backup'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute;

    return Drawer(
      backgroundColor: AppColors.primaryDark,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _groups.length,
                itemBuilder: (context, groupIndex) {
                  return _buildGroup(
                    context,
                    _groups[groupIndex],
                    currentRoute,
                  );
                },
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  /// بناء رأس القائمة مع الشعار واسم المغسلة
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryMid,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        children: [
          // الشعار
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.local_laundry_service,
              size: 36,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'مغسلة السجاد',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'إدارة متكاملة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: AppFontSizes.sm,
              color: AppColors.accent.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء مجموعة من العناصر
  Widget _buildGroup(
    BuildContext context,
    _DrawerGroup group,
    String currentRoute,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان المجموعة
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Text(
                group.icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                group.title,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: AppFontSizes.sm,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // عناصر المجموعة
        ...group.items.map(
          (item) => _buildItem(context, item, currentRoute),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Divider(
            color: Colors.white.withOpacity(0.06),
            height: 1,
          ),
        ),
      ],
    );
  }

  /// بناء عنصر واحد في القائمة
  Widget _buildItem(
    BuildContext context,
    _DrawerItem item,
    String currentRoute,
  ) {
    final isActive = currentRoute == item.route;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // إغلاق القائمة أولاً ثم التنقل
            Get.back();
            if (!isActive) {
              Get.toNamed(item.route);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.accent.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(
                      color: AppColors.accent.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: isActive
                      ? AppColors.accent
                      : Colors.white.withOpacity(0.6),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: AppFontSizes.md,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AppColors.accent
                          : Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بناء ذيل القائمة مع معلومات المستخدم
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // معلومات المستخدم
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        final authService = _getAuthService();
                        final name = authService?.currentUser.value?.fullName ??
                            authService?.userName ??
                            'مستخدم';
                        return Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        );
                      }),
                      Obx(() {
                        final authService = _getAuthService();
                        final role = authService?.userRole ?? 'مستخدم';
                        return Text(
                          _roleText(role),
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: AppFontSizes.xs,
                            color: AppColors.accent.withOpacity(0.7),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // زر تسجيل الخروج
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final confirmed = await ConfirmDialog.show(
                    title: 'تسجيل الخروج',
                    message: 'هل أنت متأكد من تسجيل الخروج؟',
                    confirmText: 'خروج',
                    cancelText: 'إلغاء',
                    confirmColor: AppColors.danger,
                    icon: Icons.logout,
                  );
                  if (confirmed == true) {
                    final authService = _getAuthService();
                    authService?.logout();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.danger.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout,
                        size: 20,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: AppFontSizes.md,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// الحصول على خدمة المصادقة (بشكل آمن)
  /// يحاول إيجاد AuthService بدون تحميل مباشر
  dynamic _getAuthService() {
    try {
      // محاولة إيجاد AuthService المسجل في GetX
      return Get.find<AuthService>();
    } catch (_) {
      return null;
    }
  }

  /// نص الدور
  String _roleText(String role) {
    const Map<String, String> roles = {
      'admin': 'مدير النظام',
      'delegate': 'مندوب',
      'customer': 'عميل',
    };
    return roles[role] ?? role;
  }
}

// ============================================================
// OrderCard - بطاقة الطلب
// ============================================================

/// بطاقة عرض الطلب مع إجراءات
class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final void Function(String newStatus)? onStatusChange;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onDelete;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onStatusChange,
    this.onWhatsApp,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor(order.orderStatus).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي: اسم العميل والحالة
              Row(
                children: [
                  // أيقونة العميل
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // اسم العميل ورقم الفاتورة
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName.isEmpty
                              ? 'بدون اسم'
                              : order.customerName,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (order.invoiceNumber.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'فاتورة: ${order.invoiceNumber}',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: AppFontSizes.xs,
                              color: isDark
                                  ? Colors.white60
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // شارة الحالة
                  StatusBadge(status: order.orderStatus),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),

              // تفاصيل الطلب
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    // الحي
                    if (order.neighborhood.isNotEmpty) ...[
                      Expanded(
                        child: _buildDetailChip(
                          icon: Icons.location_on_outlined,
                          text: order.neighborhood,
                          isDark: isDark,
                        ),
                      ),
                    ],
                    // المندوب
                    if (order.delegateName.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildDetailChip(
                          icon: Icons.delivery_dining,
                          text: order.delegateName,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // المتراج والسعر والوقت
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    // المتراج
                    if (order.totalMeters > 0) ...[
                      _buildMiniChip(
                        icon: Icons.straighten,
                        text: '${order.totalMeters.toStringAsFixed(1)} م',
                        isDark: isDark,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    // السعر
                    _buildMiniChip(
                      icon: Icons.payments_outlined,
                      text: formatCurrency(order.totalPrice),
                      isDark: isDark,
                      color: AppColors.accent,
                    ),
                    const Spacer(),
                    // الوقت
                    Text(
                      formatTimeAgo(order.createdAt),
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: AppFontSizes.xs,
                        color: isDark ? Colors.white38 : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),
              const SizedBox(height: AppSpacing.xs),

              // أزرار الإجراءات
              Row(
                children: [
                  // زر واتساب
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'واتساب',
                    color: AppColors.whatsapp,
                    onTap: onWhatsApp ?? () => openWhatsApp(order.customerPhone),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // زر تغيير الحالة
                  _buildActionButton(
                    icon: Icons.swap_horiz,
                    label: 'الحالة',
                    color: AppColors.info,
                    onTap: () => _showStatusMenu(context),
                  ),
                  const Spacer(),
                  // زر الحذف
                  if (onDelete != null)
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'حذف',
                      color: AppColors.danger,
                      onTap: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء تفصيلة صغيرة
  Widget _buildDetailChip({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? Colors.white38 : AppColors.textMuted,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: AppFontSizes.sm,
              color: isDark ? Colors.white70 : AppColors.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// بناء شريحة صغيرة
  Widget _buildMiniChip({
    required IconData icon,
    required String text,
    required bool isDark,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: AppFontSizes.xs,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء زر إجراء
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: AppFontSizes.xs,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// عرض قائمة تغيير الحالة
  void _showStatusMenu(BuildContext context) async {
    final statuses = [
      ('pending', 'قيد الانتظار'),
      ('picked', 'بانتظار البيانات'),
      ('data_ready', 'جاهز للتسليم'),
      ('ready_for_delivery', 'جاهز للاستلام'),
      ('completed', 'تم التسليم'),
      ('cancelled', 'ملغي'),
      ('no', 'غير مستلم'),
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: context.theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'تغيير حالة الطلب',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...statuses.map((s) {
                final isActive = order.orderStatus == s.$1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        if (!isActive && onStatusChange != null) {
                          onStatusChange!(s.$1);
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: isActive
                          ? statusColor(s.$1).withOpacity(0.1)
                          : null,
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor(s.$1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        s.$2,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w500,
                          color: statusColor(s.$1),
                        ),
                      ),
                      trailing: isActive
                          ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                          : null,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// AppTextField - حقل نصي مخصص
// ============================================================

/// حقل إدخال نصي مخصص بتصميم موحد
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final IconData? icon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? maxLength;
  final Widget? suffixIcon;
  final Widget? prefix;
  final String? initialValue;
  final bool readOnly;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.icon,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.enabled = true,
    this.onChanged,
    this.onTap,
    this.maxLines = 1,
    this.maxLength,
    this.suffixIcon,
    this.prefix,
    this.initialValue,
    this.readOnly = false,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      onChanged: onChanged,
      onTap: onTap,
      maxLines: maxLines,
      maxLength: maxLength,
      initialValue: controller == null ? initialValue : null,
      readOnly: readOnly,
      textInputAction: textInputAction,
      style: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: AppFontSizes.lg,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, size: 22)
            : prefix,
        suffixIcon: suffixIcon,
        counterText: '',
        filled: true,
        fillColor: enabled
            ? null
            : context.theme.disabledColor.withOpacity(0.05),
      ),
    );
  }
}

// ============================================================
// ActionChip - شريحة إجراء
// ============================================================

/// زر صغير للإجراءات السريعة
class ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const ActionChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    final isDark = context.theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: chipColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: chipColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: AppFontSizes.sm,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? chipColor
                      : chipColor.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SectionHeader - عنوان القسم
// ============================================================

/// عنوان قسم مع أيقونة واختيارياً زر إجراء
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.text,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
