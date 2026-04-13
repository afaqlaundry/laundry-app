import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// خدمة إدارة الثيم (الألوان)
class ThemeService extends GetxController {
  static ThemeService get to => Get.find();

  final _storage = GetStorage();

  final isDarkMode = false.obs;

  // ألوان الثيم
  final primaryDark = '#071F17'.obs;
  final primary = '#0B3D2E'.obs;
  final primaryMid = '#1B5E3B'.obs;
  final primaryLight = '#2D8659'.obs;
  final accent = '#C8963E'.obs;
  final accentLight = '#D4A853'.obs;
  final bg = '#F5F0E8'.obs;
  final card = '#FFFFFF'.obs;
  final text = '#1C1917'.obs;
  final textMuted = '#78716C'.obs;
  final border = '#E7E0D5'.obs;
  final success = '#16A34A'.obs;
  final warning = '#D97706'.obs;
  final danger = '#DC2626'.obs;
  final info = '#0284C7'.obs;
  final whatsapp = '#25D366'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  /// تحميل الثيم المحفوظ
  void _loadTheme() {
    final savedTheme = _storage.read<Map<String, dynamic>>('appTheme');
    if (savedTheme != null) {
      primaryDark.value = savedTheme['primaryDark'] ?? '#071F17';
      primary.value = savedTheme['primary'] ?? '#0B3D2E';
      primaryMid.value = savedTheme['primaryMid'] ?? '#1B5E3B';
      primaryLight.value = savedTheme['primaryLight'] ?? '#2D8659';
      accent.value = savedTheme['accent'] ?? '#C8963E';
      accentLight.value = savedTheme['accentLight'] ?? '#D4A853';
      bg.value = savedTheme['bg'] ?? '#F5F0E8';
      card.value = savedTheme['card'] ?? '#FFFFFF';
      text.value = savedTheme['text'] ?? '#1C1917';
      textMuted.value = savedTheme['textMuted'] ?? '#78716C';
      border.value = savedTheme['border'] ?? '#E7E0D5';
      success.value = savedTheme['success'] ?? '#16A34A';
      warning.value = savedTheme['warning'] ?? '#D97706';
      danger.value = savedTheme['danger'] ?? '#DC2626';
      info.value = savedTheme['info'] ?? '#0284C7';
      whatsapp.value = savedTheme['whatsapp'] ?? '#25D366';
    }
    isDarkMode.value = _storage.read<bool>('isDarkMode') ?? false;
  }

  /// حفظ الثيم
  void saveTheme() {
    _storage.write('appTheme', {
      'primaryDark': primaryDark.value,
      'primary': primary.value,
      'primaryMid': primaryMid.value,
      'primaryLight': primaryLight.value,
      'accent': accent.value,
      'accentLight': accentLight.value,
      'bg': bg.value,
      'card': card.value,
      'text': text.value,
      'textMuted': textMuted.value,
      'border': border.value,
      'success': success.value,
      'warning': warning.value,
      'danger': danger.value,
      'info': info.value,
      'whatsapp': whatsapp.value,
    });
    update();
  }

  /// إعادة تعيين الألوان الافتراضية
  void resetToDefault() {
    primaryDark.value = '#071F17';
    primary.value = '#0B3D2E';
    primaryMid.value = '#1B5E3B';
    primaryLight.value = '#2D8659';
    accent.value = '#C8963E';
    accentLight.value = '#D4A853';
    bg.value = '#F5F0E8';
    card.value = '#FFFFFF';
    text.value = '#1C1917';
    textMuted.value = '#78716C';
    border.value = '#E7E0D5';
    success.value = '#16A34A';
    warning.value = '#D97706';
    danger.value = '#DC2626';
    info.value = '#0284C7';
    whatsapp.value = '#25D366';
    isDarkMode.value = false;
    saveTheme();
  }

  /// تبديل الوضع الليلي
  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
    _storage.write('isDarkMode', isDarkMode.value);
    update();
  }
}

/// خدمة إعدادات المغسلة
class LaundrySettingsService extends GetxController {
  static LaundrySettingsService get to => Get.find();

  final _storage = GetStorage();

  final laundryName = 'مغسلة السجاد'.obs;
  final logoUrl = ''.obs;
  final iconUrl = ''.obs;
  final whatsappTemplate = ''.obs;

  String get defaultWhatsappTemplate => '''مرحباً {customerName}،
طلبك رقم {invoiceNumber} في {laundryName}.
الحالة: {status}
تاريخ الاستلام: {pickupDate}
الإجمالي: {totalPrice} ر.س

لتتبع طلبك: {trackUrl}
شكراً لثقتكم.''';

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    laundryName.value =
        _storage.read<String>('laundryName') ?? 'مغسلة السجاد';
    logoUrl.value = _storage.read<String>('laundryLogoUrl') ?? '';
    iconUrl.value = _storage.read<String>('laundryIconUrl') ?? '';
    whatsappTemplate.value =
        _storage.read<String>('whatsappTemplate') ?? defaultWhatsappTemplate;
  }

  Future<void> saveLaundrySettings({
    required String name,
    required String logo,
    required String icon,
  }) async {
    laundryName.value = name;
    logoUrl.value = logo;
    iconUrl.value = icon;

    _storage.write('laundryName', name);
    _storage.write('laundryLogoUrl', logo);
    _storage.write('laundryIconUrl', icon);
  }

  Future<void> saveWhatsappTemplate(String template) async {
    whatsappTemplate.value = template;
    _storage.write('whatsappTemplate', template);
  }

  /// بناء رسالة واتساب
  String buildWhatsappMessage({
    required String customerName,
    required String invoiceNumber,
    required String status,
    required String trackUrl,
    required String totalPrice,
    required String pickupDate,
  }) {
    return whatsappTemplate.value
        .replaceAll('{customerName}', customerName)
        .replaceAll('{invoiceNumber}', invoiceNumber)
        .replaceAll('{status}', status)
        .replaceAll('{trackUrl}', trackUrl)
        .replaceAll('{laundryName}', laundryName.value)
        .replaceAll('{totalPrice}', totalPrice)
        .replaceAll('{pickupDate}', pickupDate);
  }
}
