import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

// ============================================================
// أنواع الإشعارات
// ============================================================

/// أنواع Toast / SnackBar
enum ToastType {
  success,
  error,
  warning,
  info,
}

// ============================================================
// تنسيق العملة
// ============================================================

/// تنسيق المبلغ بالريال السعودي
/// مثال: formatCurrency(1234.56) => "1,234.56 ر.س"
String formatCurrency(double amount) {
  if (amount == amount.truncateToDouble()) {
    // إذا كان عدد صحيح، لا نظهر الكسور
    final formatted = NumberFormat('#,##0', 'ar_SA').format(amount);
    return '$formatted ر.س';
  }
  final formatted = NumberFormat('#,##0.00', 'ar_SA').format(amount);
  return '$formatted ر.س';
}

// ============================================================
// تنسيق التاريخ
// ============================================================

/// تنسيق التاريخ بالعربية
/// مثال: formatDate(timestamp) => "١٥ يناير ٢٠٢٥"
String formatDate(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return DateFormat('d MMMM y', 'ar_SA').format(date);
}

/// تنسيق التاريخ والوقت بالعربية
/// مثال: formatDateTime(timestamp) => "١٥ يناير ٢٠٢٥ - ٠٣:٣٠ م"
String formatDateTime(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final dateStr = DateFormat('d MMMM y', 'ar_SA').format(date);
  final timeStr = DateFormat('h:mm a', 'ar_SA').format(date);
  return '$dateStr - $timeStr';
}

// ============================================================
// الوقت النسبي
// ============================================================

/// تنسيق الوقت بشكل نسبي بالعربية
/// مثال: "منذ 5 دقائق", "منذ ساعتين", "اليوم 03:30"
String formatTimeAgo(int timestamp) {
  final now = DateTime.now();
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final difference = now.difference(date);

  // إذا كان المستقبلياً
  if (difference.isNegative) {
    return DateFormat('h:mm a', 'ar_SA').format(date);
  }

  // أقل من دقيقة
  if (difference.inSeconds < 60) {
    return 'الآن';
  }

  // أقل من ساعة
  if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    if (minutes == 1) return 'منذ دقيقة';
    if (minutes == 2) return 'منذ دقيقتين';
    if (minutes <= 10) return 'منذ $minutes دقائق';
    return 'منذ $minutes دقيقة';
  }

  // أقل من يوم
  if (difference.inHours < 24) {
    final hours = difference.inHours;
    if (hours == 1) return 'منذ ساعة';
    if (hours == 2) return 'منذ ساعتين';
    if (hours <= 10) return 'منذ $hours ساعات';
    return 'منذ $hours ساعة';
  }

  // أقل من أسبوع
  if (difference.inDays < 7) {
    final days = difference.inDays;
    if (days == 1) return 'أمس';
    if (days == 2) return 'منذ يومين';
    if (days <= 10) return 'منذ $days أيام';
    return 'منذ $days يوماً';
  }

  // أقل من شهر (4 أسابيع تقريباً)
  if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    if (weeks == 1) return 'منذ أسبوع';
    if (weeks == 2) return 'منذ أسبوعين';
    return 'منذ $weeks أسابيع';
  }

  // أقل من سنة
  if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    if (months == 1) return 'منذ شهر';
    if (months == 2) return 'منذ شهرين';
    if (months <= 10) return 'منذ $months أشهر';
    return 'منذ $months شهراً';
  }

  // أكثر من سنة
  final years = (difference.inDays / 365).floor();
  if (years == 1) return 'منذ سنة';
  if (years == 2) return 'منذ سنتين';
  if (years <= 10) return 'منذ $years سنوات';
  return 'منذ $years سنة';
}

// ============================================================
// تنسيق رقم الهاتف
// ============================================================

/// تنسيق رقم الهاتف السعودي
/// يقبل: 05xxxxxxxx, 5xxxxxxxx, +9665xxxxxxxx, 9665xxxxxxxx
/// يُرجع: 05X XXX XXXX
String formatPhoneNumber(String phone) {
  // إزالة كل ما ليس أرقاماً
  final digits = phone.replaceAll(RegExp(r'[^\d]'), '');

  if (digits.isEmpty) return phone;

  String cleaned = digits;

  // تحويل 966 إلى 0
  if (cleaned.startsWith('966')) {
    cleaned = '0${cleaned.substring(3)}';
  }
  // إذا بدأ بـ 5 بدون 0
  else if (cleaned.startsWith('5') && cleaned.length == 9) {
    cleaned = '0$cleaned';
  }

  // التنسيق: 05X XXX XXXX
  if (cleaned.length == 10 && cleaned.startsWith('05')) {
    return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
  }

  return cleaned;
}

// ============================================================
// واتساب
// ============================================================

/// إنشاء رابط واتساب مع تنسيق 966
/// مثال: getWhatsAppUrl("0512345678", "مرحباً")
///       => "https://wa.me/966512345678?text=..."
String getWhatsAppUrl(String phone, String message) {
  // تنظيف الرقم
  String digits = phone.replaceAll(RegExp(r'[^\d]'), '');

  // تحويل للتنسيق الدولي بدون +
  if (digits.startsWith('05')) {
    digits = '966${digits.substring(1)}';
  } else if (digits.startsWith('5') && digits.length == 9) {
    digits = '966$digits';
  } else if (digits.startsWith('+966')) {
    digits = digits.substring(1);
  }

  final encodedMessage = Uri.encodeComponent(message);
  return 'https://wa.me/$digits?text=$encodedMessage';
}

/// فتح واتساب مع رسالة اختيارية
Future<void> openWhatsApp(String phone, {String? message}) async {
  final defaultMessage = message ?? '';
  final url = getWhatsAppUrl(phone, defaultMessage);

  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } else {
    // إذا فشل فتح الرابط، نحاول النسخ للحافظة
    showToast('تعذر فتح واتساب، تأكد من تثبيت التطبيق', type: ToastType.error);
  }
}

// ============================================================
// الخرائط
// ============================================================

/// فتح رابط موقع في خرائط جوجل
Future<void> openMap(String? locationLink) async {
  if (locationLink == null || locationLink.trim().isEmpty) {
    showToast('لا يوجد موقع محدد', type: ToastType.warning);
    return;
  }

  final trimmed = locationLink.trim();

  Uri uri;
  if (trimmed.startsWith('http')) {
    uri = Uri.parse(trimmed);
  } else if (trimmed.startsWith('geo:')) {
    uri = Uri.parse(trimmed);
  } else {
    // إذا كان إحداثيات أو نص بحث
    uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(trimmed)}');
  }

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    showToast('تعذر فتح الخريطة', type: ToastType.error);
  }
}

// ============================================================
// المكالمات الهاتفية
// ============================================================

/// إجراء مكالمة هاتفية
Future<void> makePhoneCall(String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');

  if (digits.isEmpty) {
    showToast('رقم الهاتف غير صالح', type: ToastType.error);
    return;
  }

  final uri = Uri.parse('tel:$digits');

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    showToast('تعذر إجراء المكالمة', type: ToastType.error);
  }
}

// ============================================================
// Toast / SnackBar
// ============================================================

/// عرض إشعار Toast / SnackBar
void showToast(String message, {ToastType type = ToastType.info}) {
  final context = Get.context;
  if (context == null) return;

  final isDark = Theme.of(context).brightness == Brightness.dark;

  Color bgColor;
  Color textColor;
  IconData icon;

  switch (type) {
    case ToastType.success:
      bgColor = const Color(0xFF16A34A);
      textColor = Colors.white;
      icon = Icons.check_circle_outline;
      break;
    case ToastType.error:
      bgColor = const Color(0xFFDC2626);
      textColor = Colors.white;
      icon = Icons.error_outline;
      break;
    case ToastType.warning:
      bgColor = const Color(0xFFD97706);
      textColor = Colors.white;
      icon = Icons.warning_amber_outlined;
      break;
    case ToastType.info:
      bgColor = isDark ? AppColors.primaryMid : AppColors.primary;
      textColor = Colors.white;
      icon = Icons.info_outline;
      break;
  }

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: textColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: AppFontSizes.md,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      duration: const Duration(seconds: 3),
      elevation: 6,
    ),
  );
}

// ============================================================
// نصوص الحالة
// ============================================================

/// الحصول على النص العربي للحالة
String statusText(String status) {
  const Map<String, String> map = {
    'pending': 'قيد الانتظار',
    'picked': 'بانتظار البيانات',
    'data_ready': 'جاهز للتسليم',
    'ready_for_delivery': 'جاهز للاستلام',
    'completed': 'تم التسليم',
    'cancelled': 'ملغي',
    'no': 'غير مستلم',
  };
  return map[status] ?? status;
}

/// الحصول على لون الحالة
Color statusColor(String status) {
  const Map<String, Color> map = {
    'pending': AppColors.statusPending,
    'picked': AppColors.statusPicked,
    'data_ready': AppColors.statusDataReady,
    'ready_for_delivery': AppColors.statusReadyDelivery,
    'completed': AppColors.statusCompleted,
    'cancelled': AppColors.statusCancelled,
    'no': AppColors.statusNotReceived,
  };
  return map[status] ?? AppColors.textMuted;
}

// ============================================================
// طرق الدفع
// ============================================================

/// الحصول على النص العربي لطريقة الدفع
String payMethodText(String method) {
  const Map<String, String> map = {
    'cash': 'كاش',
    'bank': 'تحويل بنكي',
    'card': 'شبكة مدى',
    'credit': 'آجل',
    'mixed': 'متعدد',
  };
  return map[method.toLowerCase()] ?? method;
}

// ============================================================
// أدوات مساعدة عامة
// ============================================================

/// تحويل آمن لقيمة إلى double
/// مثال: safeDouble(null) => 0.0
///       safeDouble("12.5") => 12.5
///       safeDouble(10) => 10.0
double safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// التحقق من صحة رقم الهاتف السعودي
/// يقبل: 05xxxxxxxx, 5xxxxxxxx, +9665xxxxxxxx, 9665xxxxxxxx
bool validatePhone(String phone) {
  if (phone.isEmpty) return false;

  final digits = phone.replaceAll(RegExp(r'[^\d]'), '');

  // 05XXXXXXXX (10 أرقام تبدأ بـ 05)
  if (RegExp(r'^05[0-9]{8}$').hasMatch(digits)) return true;

  // 5XXXXXXXX (9 أرقام تبدأ بـ 5)
  if (RegExp(r'^5[0-9]{8}$').hasMatch(digits)) return true;

  // 9665XXXXXXXX (12 رقم تبدأ بـ 9665)
  if (RegExp(r'^9665[0-9]{8}$').hasMatch(digits)) return true;

  return false;
}

/// اقتطاع النص مع علامة حذف
/// مثال: truncateText("نص طويل جداً", 5) => "نص طو..."
String truncateText(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  if (maxLength <= 3) return text.substring(0, maxLength);
  return '${text.substring(0, maxLength - 3)}...';
}
