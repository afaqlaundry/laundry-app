import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../services/push_notification_service.dart';
import '../../models/settings_model.dart';

// ============================================================================
// المتحكم - SettingsController
// ============================================================================

/// متحكم الإعدادات
class SettingsController extends GetxController {
  static SettingsController get to => Get.find();

  final ApiService _api = ApiService.to;
  final ThemeService _theme = ThemeService.to;
  final _storage = GetStorage();

  // ===== حالة التحميل =====
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString successMessage = ''.obs;
  final RxString errorMessage = ''.obs;

  // ===== إعدادات الفاتورة =====
  final invoiceHeaderText = TextEditingController();
  final invoiceFooterText = TextEditingController();
  final invoiceTaxNumber = TextEditingController();
  final showInvoiceLogo = true.obs;
  final showQrCode = true.obs;

  // ===== إعدادات المغسلة =====
  final laundryName = TextEditingController();
  final RxString logoUrl = ''.obs;
  final RxString iconUrl = ''.obs;
  final Rx<File?> selectedLogoFile = Rx<File?>(null);
  final Rx<File?> selectedIconFile = Rx<File?>(null);

  // ===== إعدادات واتساب =====
  final whatsappTemplate = TextEditingController();

  // ===== وضع ليلي =====
  final RxBool isDarkMode = false.obs;

  // ===== إعدادات الألوان =====
  final colorItems = <_ColorItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadAllSettings();
  }

  @override
  void onClose() {
    invoiceHeaderText.dispose();
    invoiceFooterText.dispose();
    invoiceTaxNumber.dispose();
    laundryName.dispose();
    whatsappTemplate.dispose();
    super.onClose();
  }

  /// تحميل جميع الإعدادات
  void _loadAllSettings() {
    // إعدادات الفاتورة
    final invSettings = _storage.read<Map<String, dynamic>>('invoiceSettings');
    if (invSettings != null) {
      invoiceHeaderText.text = invSettings['headerText'] ?? '';
      invoiceFooterText.text = invSettings['footerText'] ?? '';
      invoiceTaxNumber.text = invSettings['taxNumber'] ?? '';
      showInvoiceLogo.value = invSettings['showLogo'] ?? true;
      showQrCode.value = invSettings['showQrCode'] ?? true;
    }

    // إعدادات المغسلة
    laundryName.text = _storage.read<String>('laundryName') ?? 'مغسلة السجاد';
    logoUrl.value = _storage.read<String>('laundryLogoUrl') ?? '';
    iconUrl.value = _storage.read<String>('laundryIconUrl') ?? '';

    // إعدادات واتساب
    whatsappTemplate.text = _storage.read<String>('whatsappTemplate') ??
        LaundrySettingsService.to.defaultWhatsappTemplate;

    // وضع ليلي
    isDarkMode.value = _theme.isDarkMode.value;

    // بناء قائمة الألوان
    _buildColorItems();
  }

  /// بناء قائمة عناصر الألوان
  void _buildColorItems() {
    colorItems.value = [
      _ColorItem(name: 'اللون الأساسي الداكن', key: 'primaryDark', value: _theme.primaryDark.value),
      _ColorItem(name: 'اللون الأساسي', key: 'primary', value: _theme.primary.value),
      _ColorItem(name: 'اللون الأساسي المتوسط', key: 'primaryMid', value: _theme.primaryMid.value),
      _ColorItem(name: 'اللون الأساسي الفاتح', key: 'primaryLight', value: _theme.primaryLight.value),
      _ColorItem(name: 'اللون المميز', key: 'accent', value: _theme.accent.value),
      _ColorItem(name: 'اللون المميز الفاتح', key: 'accentLight', value: _theme.accentLight.value),
      _ColorItem(name: 'لون الخلفية', key: 'bg', value: _theme.bg.value),
      _ColorItem(name: 'لون البطاقة', key: 'card', value: _theme.card.value),
      _ColorItem(name: 'لون النص', key: 'text', value: _theme.text.value),
      _ColorItem(name: 'لون النص الخافت', key: 'textMuted', value: _theme.textMuted.value),
      _ColorItem(name: 'لون الحدود', key: 'border', value: _theme.border.value),
      _ColorItem(name: 'لون النجاح', key: 'success', value: _theme.success.value),
      _ColorItem(name: 'لون التحذير', key: 'warning', value: _theme.warning.value),
      _ColorItem(name: 'لون الخطر', key: 'danger', value: _theme.danger.value),
      _ColorItem(name: 'لون المعلومات', key: 'info', value: _theme.info.value),
      _ColorItem(name: 'لون واتساب', key: 'whatsapp', value: _theme.whatsapp.value),
    ];
  }

  // ====================================================================
  // حفظ إعدادات الفاتورة
  // ====================================================================
  Future<void> saveInvoiceSettings() async {
    isSaving.value = true;
    try {
      final settings = {
        'headerText': invoiceHeaderText.text.trim(),
        'footerText': invoiceFooterText.text.trim(),
        'taxNumber': invoiceTaxNumber.text.trim(),
        'showLogo': showInvoiceLogo.value,
        'showQrCode': showQrCode.value,
      };

      _storage.write('invoiceSettings', settings);

      // إرسال للسيرفر
      await _api.post('settings/invoice', data: settings);

      _showSuccess('تم حفظ إعدادات الفاتورة بنجاح');
    } catch (e) {
      debugPrint('Save invoice settings error: $e');
      _showError('فشل في حفظ إعدادات الفاتورة');
    } finally {
      isSaving.value = false;
    }
  }

  // ====================================================================
  // حفظ إعدادات المغسلة
  // ====================================================================
  Future<void> saveLaundrySettings() async {
    isSaving.value = true;
    try {
      final name = laundryName.text.trim();

      // رفع الشعار إذا تم اختياره
      if (selectedLogoFile.value != null) {
        final response = await _api.uploadFile(
          'settings/upload-logo',
          selectedLogoFile.value!.path,
          field: 'logo',
        );
        if (response != null && response.data != null) {
          logoUrl.value = response.data['url'] ?? '';
        }
        selectedLogoFile.value = null;
      }

      // رفع الأيقونة إذا تم اختيارارها
      if (selectedIconFile.value != null) {
        final response = await _api.uploadFile(
          'settings/upload-icon',
          selectedIconFile.value!.path,
          field: 'icon',
        );
        if (response != null && response.data != null) {
          iconUrl.value = response.data['url'] ?? '';
        }
        selectedIconFile.value = null;
      }

      // حفظ البيانات
      _storage.write('laundryName', name);
      _storage.write('laundryLogoUrl', logoUrl.value);
      _storage.write('laundryIconUrl', iconUrl.value);

      await _api.post('settings/laundry', data: {
        'laundryName': name,
        'logoUrl': logoUrl.value,
        'iconUrl': iconUrl.value,
      });

      // تحديث الخدمة
      LaundrySettingsService.to.laundryName.value = name;
      LaundrySettingsService.to.logoUrl.value = logoUrl.value;
      LaundrySettingsService.to.iconUrl.value = iconUrl.value;

      _showSuccess('تم حفظ إعدادات المغسلة بنجاح');
    } catch (e) {
      debugPrint('Save laundry settings error: $e');
      _showError('فشل في حفظ إعدادات المغسلة');
    } finally {
      isSaving.value = false;
    }
  }

  /// اختيار صورة شعار
  Future<void> pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
      if (picked != null) {
        selectedLogoFile.value = File(picked.path);
      }
    } catch (e) {
      debugPrint('Pick logo error: $e');
    }
  }

  /// اختيار صورة أيقونة
  Future<void> pickIcon() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
      if (picked != null) {
        selectedIconFile.value = File(picked.path);
      }
    } catch (e) {
      debugPrint('Pick icon error: $e');
    }
  }

  // ====================================================================
  // إعدادات الألوان
  // ====================================================================

  /// تحديث لون
  void updateColor(String key, String hexValue) {
    switch (key) {
      case 'primaryDark': _theme.primaryDark.value = hexValue;
      case 'primary': _theme.primary.value = hexValue;
      case 'primaryMid': _theme.primaryMid.value = hexValue;
      case 'primaryLight': _theme.primaryLight.value = hexValue;
      case 'accent': _theme.accent.value = hexValue;
      case 'accentLight': _theme.accentLight.value = hexValue;
      case 'bg': _theme.bg.value = hexValue;
      case 'card': _theme.card.value = hexValue;
      case 'text': _theme.text.value = hexValue;
      case 'textMuted': _theme.textMuted.value = hexValue;
      case 'border': _theme.border.value = hexValue;
      case 'success': _theme.success.value = hexValue;
      case 'warning': _theme.warning.value = hexValue;
      case 'danger': _theme.danger.value = hexValue;
      case 'info': _theme.info.value = hexValue;
      case 'whatsapp': _theme.whatsapp.value = hexValue;
    }
    // تحديث القائمة
    final index = colorItems.indexWhere((item) => item.key == key);
    if (index >= 0) {
      colorItems[index] = _ColorItem(
        name: colorItems[index].name,
        key: key,
        value: hexValue,
      );
      colorItems.refresh();
    }
  }

  /// حفظ الألوان
  Future<void> saveThemeColors() async {
    isSaving.value = true;
    try {
      _theme.saveTheme();
      _showSuccess('تم حفظ الألوان بنجاح');
    } catch (e) {
      _showError('فشل في حفظ الألوان');
    } finally {
      isSaving.value = false;
    }
  }

  /// إعادة الألوان الافتراضية
  Future<void> resetThemeColors() async {
    isSaving.value = true;
    try {
      _theme.resetToDefault();
      _buildColorItems();
      _showSuccess('تم إعادة الألوان الافتراضية');
    } catch (e) {
      _showError('فشل في إعادة الألوان');
    } finally {
      isSaving.value = false;
    }
  }

  /// تبديل الوضع الليلي
  void toggleDarkMode() {
    _theme.toggleDarkMode();
    isDarkMode.value = _theme.isDarkMode.value;
  }

  // ====================================================================
  // إعدادات واتساب
  // ====================================================================
  Future<void> saveWhatsappTemplate() async {
    isSaving.value = true;
    try {
      _storage.write('whatsappTemplate', whatsappTemplate.text.trim());
      LaundrySettingsService.to.saveWhatsappTemplate(whatsappTemplate.text.trim());

      await _api.post('settings/whatsapp', data: {
        'template': whatsappTemplate.text.trim(),
      });

      _showSuccess('تم حفظ قالب واتساب بنجاح');
    } catch (e) {
      _showError('فشل في حفظ القالب');
    } finally {
      isSaving.value = false;
    }
  }

  /// استعادة القالب الافتراضي
  void resetWhatsappTemplate() {
    whatsappTemplate.text = LaundrySettingsService.to.defaultWhatsappTemplate;
  }

  /// معاينة رسالة واتساب
  String getPreviewMessage() {
    return whatsappTemplate.text
        .replaceAll('{customerName}', 'أحمد محمد')
        .replaceAll('{invoiceNumber}', 'INV-2024-0156')
        .replaceAll('{status}', 'جاهز للتسليم')
        .replaceAll('{trackUrl}', 'https://afaqlaundry.com/track/156')
        .replaceAll('{laundryName}', laundryName.text)
        .replaceAll('{totalPrice}', '450.00')
        .replaceAll('{pickupDate}', '2024/06/15');
  }

  // ====================================================================
  // النسخ الاحتياطي
  // ====================================================================

  /// تصدير البيانات
  Future<void> exportData() async {
    isLoading.value = true;
    try {
      final backupData = {
        'version': '1.0.0',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'invoiceSettings': _storage.read('invoiceSettings') ?? {},
        'laundryName': _storage.read('laundryName') ?? '',
        'laundryLogoUrl': _storage.read('laundryLogoUrl') ?? '',
        'laundryIconUrl': _storage.read('laundryIconUrl') ?? '',
        'whatsappTemplate': _storage.read('whatsappTemplate') ?? '',
        'appTheme': _storage.read('appTheme') ?? {},
        'isDarkMode': _storage.read('isDarkMode') ?? false,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);
      final bytes = utf8.encode(jsonStr);

      final fileName = 'laundry_backup_${DateTime.now().millisecondsSinceEpoch ~/ 1000}.json';

      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: 'application/json')],
        subject: 'نسخة احتياطية - إدارة المغسلة',
      );

      _showSuccess('تم تصدير النسخة الاحتياطية بنجاح');
    } catch (e) {
      debugPrint('Export data error: $e');
      _showError('فشل في تصدير البيانات');
    } finally {
      isLoading.value = false;
    }
  }

  /// استيراد البيانات
  Future<void> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        isLoading.value = true;
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        // التحقق من النسخة
        if (data['version'] == null) {
          _showError('ملف نسخ احتياطي غير صالح');
          isLoading.value = false;
          return;
        }

        // استعادة البيانات
        if (data['invoiceSettings'] != null) {
          _storage.write('invoiceSettings', data['invoiceSettings']);
          final inv = data['invoiceSettings'] as Map<String, dynamic>;
          invoiceHeaderText.text = inv['headerText'] ?? '';
          invoiceFooterText.text = inv['footerText'] ?? '';
          invoiceTaxNumber.text = inv['taxNumber'] ?? '';
          showInvoiceLogo.value = inv['showLogo'] ?? true;
          showQrCode.value = inv['showQrCode'] ?? true;
        }

        if (data['laundryName'] != null) {
          _storage.write('laundryName', data['laundryName']);
          laundryName.text = data['laundryName'];
        }

        if (data['laundryLogoUrl'] != null) {
          _storage.write('laundryLogoUrl', data['laundryLogoUrl']);
          logoUrl.value = data['laundryLogoUrl'];
        }

        if (data['laundryIconUrl'] != null) {
          _storage.write('laundryIconUrl', data['laundryIconUrl']);
          iconUrl.value = data['laundryIconUrl'];
        }

        if (data['whatsappTemplate'] != null) {
          _storage.write('whatsappTemplate', data['whatsappTemplate']);
          whatsappTemplate.text = data['whatsappTemplate'];
        }

        if (data['appTheme'] != null) {
          _storage.write('appTheme', data['appTheme']);
          _theme._loadTheme();
          _buildColorItems();
        }

        if (data['isDarkMode'] != null) {
          _storage.write('isDarkMode', data['isDarkMode']);
          _theme.isDarkMode.value = data['isDarkMode'];
          isDarkMode.value = data['isDarkMode'];
        }

        _theme.update();
        _showSuccess('تم استيراد النسخة الاحتياطية بنجاح');
      }
    } catch (e) {
      debugPrint('Import data error: $e');
      _showError('فشل في استيراد البيانات، تأكد من صحة الملف');
    } finally {
      isLoading.value = false;
    }
  }

  // ====================================================================
  // مساعدة
  // ====================================================================
  void _showSuccess(String msg) {
    successMessage.value = msg;
    Get.snackbar(
      'تم بنجاح',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
    Future.delayed(const Duration(seconds: 2), () {
      successMessage.value = '';
    });
  }

  void _showError(String msg) {
    errorMessage.value = msg;
    Get.snackbar(
      'خطأ',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.danger,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
    Future.delayed(const Duration(seconds: 3), () {
      errorMessage.value = '';
    });
  }
}

/// عنصر لون
class _ColorItem {
  final String name;
  final String key;
  final String value;

  const _ColorItem({required this.name, required this.key, required this.value});
}

// ============================================================================
// الشاشة الرئيسية - SettingsScreen
// ============================================================================

/// شاشة الإعدادات
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(child: _buildSettingsList()),
          ],
        ),
      ),
    );
  }

  // ===== شريط العنوان =====
  Widget _buildAppBar(BuildContext context) {
    return Container(
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
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md.w,
            vertical: AppSpacing.sm.h,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    FontAwesomeIcons.arrowRight,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm.w),
              Expanded(
                child: Text(
                  'الإعدادات',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // زر الوضع الليلي
              Obx(() {
                final controller = Get.find<SettingsController>();
                return GestureDetector(
                  onTap: controller.toggleDarkMode,
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      controller.isDarkMode.value
                          ? FontAwesomeIcons.sun
                          : FontAwesomeIcons.moon,
                      color: AppColors.accentLight,
                      size: 16.sp,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ===== قائمة الإعدادات =====
  Widget _buildSettingsList() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.sm.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // القسم الأول: إعدادات الفاتورة
          _SettingsSectionHeader(title: 'الفاتورة', icon: FontAwesomeIcons.fileInvoice),
          _SettingsCard(
            title: 'إعدادات الفاتورة',
            subtitle: 'نص الرأس، التذييل، الرقم الضريبي، الشعار، QR',
            icon: FontAwesomeIcons.receipt,
            color: AppColors.primary,
            onTap: () => Get.to(() => const _InvoiceSettingsPage()),
          ),
          SizedBox(height: AppSpacing.md.h),

          // القسم الثاني: إعدادات المغسلة
          _SettingsSectionHeader(title: 'المغسلة', icon: FontAwesomeIcons.store),
          _SettingsCard(
            title: 'إعدادات المغسلة',
            subtitle: 'الاسم، الشعار، الأيقونة',
            icon: FontAwesomeIcons.building,
            color: AppColors.accent,
            onTap: () => Get.to(() => const _LaundrySettingsPage()),
          ),
          SizedBox(height: AppSpacing.md.h),

          // القسم الثالث: تخصيص الألوان
          _SettingsSectionHeader(title: 'المظهر', icon: FontAwesomeIcons.palette),
          _SettingsCard(
            title: 'تخصيص الألوان',
            subtitle: 'ألوان الثيم والواجهة',
            icon: FontAwesomeIcons.swatchbook,
            color: AppColors.info,
            onTap: () => Get.to(() => const _ThemeSettingsPage()),
          ),
          SizedBox(height: AppSpacing.md.h),

          // القسم الرابع: إعدادات واتساب
          _SettingsSectionHeader(title: 'التواصل', icon: FontAwesomeIcons.commentSms),
          _SettingsCard(
            title: 'إعدادات واتساب',
            subtitle: 'قالب الرسائل والمعاينة',
            icon: FontAwesomeIcons.whatsapp,
            color: AppColors.whatsapp,
            onTap: () => Get.to(() => const _WhatsAppSettingsPage()),
          ),
          SizedBox(height: AppSpacing.md.h),

          // القسم الخامس: النسخ الاحتياطي
          _SettingsSectionHeader(title: 'البيانات', icon: FontAwesomeIcons.database),
          _SettingsCard(
            title: 'النسخ الاحتياطي',
            subtitle: 'تصدير واستيراد بيانات التطبيق',
            icon: FontAwesomeIcons.cloudArrowUp,
            color: AppColors.success,
            onTap: () => Get.to(() => const _BackupSettingsPage()),
          ),
          SizedBox(height: AppSpacing.xl.h),
        ],
      ),
    );
  }
}

// ============================================================================
// مكونات الإعدادات الرئيسية
// ============================================================================

/// عنوان قسم الإعدادات
class _SettingsSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SettingsSectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs.h),
      child: Row(
        children: [
          Icon(icon, size: 12.sp, color: AppColors.textMuted),
          SizedBox(width: 6.w),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة إعداد
class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, size: 18.sp, color: color),
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              FontAwesomeIcons.chevronLeft,
              size: 14.sp,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// صفحة إعدادات الفاتورة
// ============================================================================

class _InvoiceSettingsPage extends StatelessWidget {
  const _InvoiceSettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'إعدادات الفاتورة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Icon(FontAwesomeIcons.arrowRight, size: 18.sp),
        ),
      ),
      body: GetBuilder<SettingsController>(
        builder: (controller) => SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // نص الرأس
              _SettingsTextField(
                controller: controller.invoiceHeaderText,
                label: 'نص رأس الفاتورة',
                hint: 'مثال: مغسلة الأفق للسجاد - فاتورة',
                icon: FontAwesomeIcons.heading,
                maxLines: 2,
              ),
              SizedBox(height: AppSpacing.md.h),

              // نص التذييل
              _SettingsTextField(
                controller: controller.invoiceFooterText,
                label: 'نص تذييل الفاتورة',
                hint: 'مثال: شكراً لتعاملكم معنا',
                icon: FontAwesomeIcons.paragraph,
                maxLines: 2,
              ),
              SizedBox(height: AppSpacing.md.h),

              // الرقم الضريبي
              _SettingsTextField(
                controller: controller.invoiceTaxNumber,
                label: 'الرقم الضريبي',
                hint: 'مثال: 300000000000003',
                icon: FontAwesomeIcons.hashtag,
                inputType: TextInputType.number,
              ),
              SizedBox(height: AppSpacing.lg.h),

              // إظهار الشعار
              Obx(() => _SettingsToggle(
                title: 'إظهار الشعار في الفاتورة',
                subtitle: 'عرض شعار المغسلة في رأس الفاتورة',
                icon: FontAwesomeIcons.image,
                value: controller.showInvoiceLogo.value,
                onChanged: (v) => controller.showInvoiceLogo.value = v,
                activeColor: AppColors.primary,
              )),
              SizedBox(height: AppSpacing.sm.h),

              // إظهار QR
              Obx(() => _SettingsToggle(
                title: 'إظهار رمز QR',
                subtitle: 'عرض رمز QR لرابط تتبع الطلب',
                icon: FontAwesomeIcons.qrcode,
                value: controller.showQrCode.value,
                onChanged: (v) => controller.showQrCode.value = v,
                activeColor: AppColors.primary,
              )),
              SizedBox(height: AppSpacing.xl.h),

              // زر الحفظ
              Obx(() => _SaveButton(
                isLoading: controller.isSaving.value,
                label: 'حفظ إعدادات الفاتورة',
                onTap: controller.saveInvoiceSettings,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// صفحة إعدادات المغسلة
// ============================================================================

class _LaundrySettingsPage extends StatelessWidget {
  const _LaundrySettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'إعدادات المغسلة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Icon(FontAwesomeIcons.arrowRight, size: 18.sp),
        ),
      ),
      body: GetBuilder<SettingsController>(
        builder: (controller) => SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اسم المغسلة
              _SettingsTextField(
                controller: controller.laundryName,
                label: 'اسم المغسلة',
                hint: 'أدخل اسم المغسلة',
                icon: FontAwesomeIcons.store,
              ),
              SizedBox(height: AppSpacing.lg.h),

              // رفع الشعار
              Text(
                'شعار المغسلة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              _ImageUploadSection(
                currentUrl: controller.logoUrl.value,
                selectedFile: controller.selectedLogoFile,
                onPick: controller.pickLogo,
                onRemove: () {
                  controller.selectedLogoFile.value = null;
                  controller.logoUrl.value = '';
                },
                placeholder: 'اختر شعار المغسلة',
              ),
              SizedBox(height: AppSpacing.lg.h),

              // رفع الأيقونة
              Text(
                'أيقونة التطبيق',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              _ImageUploadSection(
                currentUrl: controller.iconUrl.value,
                selectedFile: controller.selectedIconFile,
                onPick: controller.pickIcon,
                onRemove: () {
                  controller.selectedIconFile.value = null;
                  controller.iconUrl.value = '';
                },
                placeholder: 'اختر أيقونة التطبيق',
                isSquare: true,
              ),
              SizedBox(height: AppSpacing.xl.h),

              // زر الحفظ
              Obx(() => _SaveButton(
                isLoading: controller.isSaving.value,
                label: 'حفظ إعدادات المغسلة',
                onTap: controller.saveLaundrySettings,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// صفحة تخصيص الألوان
// ============================================================================

class _ThemeSettingsPage extends StatelessWidget {
  const _ThemeSettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'تخصيص الألوان',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Icon(FontAwesomeIcons.arrowRight, size: 18.sp),
        ),
        actions: [
          // زر إعادة تعيين
          GestureDetector(
            onTap: () {
              Get.find<SettingsController>().resetThemeColors();
            },
            child: Container(
              margin: EdgeInsets.only(left: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'إعادة ضبط',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: GetBuilder<SettingsController>(
        builder: (controller) => Column(
          children: [
            // معاينة مباشرة
            _buildThemePreview(controller),
            // قائمة الألوان
            Expanded(child: _buildColorList(controller)),
            // أزرار الحفظ
            _buildThemeActions(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreview(SettingsController controller) {
    return Obx(() {
      final bg = _tryParseColor(controller.colorItems.firstWhereOrNull((c) => c.key == 'bg')?.value ?? '#F5F0E8');
      final card = _tryParseColor(controller.colorItems.firstWhereOrNull((c) => c.key == 'card')?.value ?? '#FFFFFF');
      final primary = _tryParseColor(controller.colorItems.firstWhereOrNull((c) => c.key == 'primary')?.value ?? '#0B3D2E');
      final accent = _tryParseColor(controller.colorItems.firstWhereOrNull((c) => c.key == 'accent')?.value ?? '#C8963E');
      final text = _tryParseColor(controller.colorItems.firstWhereOrNull((c) => c.key == 'text')?.value ?? '#1C1917');
      final textMuted = _tryParseColor(controller.colorItems.firstWhereOrNull((c) => c.key == 'textMuted')?.value ?? '#78716C');

      return Container(
        margin: EdgeInsets.all(AppSpacing.md.w),
        padding: EdgeInsets.all(AppSpacing.md.r),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معاينة مباشرة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: textMuted,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'شريط العنوان',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'عنوان البطاقة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: text,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'هذا نص توضيحي بلون النص الخافت',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12.sp,
                      color: textMuted,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'زر مميز',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildColorList(SettingsController controller) {
    return Obx(() {
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
        itemCount: controller.colorItems.length,
        itemBuilder: (context, index) {
          final item = controller.colorItems[index];
          return _ColorPickerRow(
            name: item.name,
            hexValue: item.value,
            onChanged: (color) => controller.updateColor(item.key, color),
          );
        },
      );
    });
  }

  Widget _buildThemeActions(SettingsController controller) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.resetThemeColors,
                icon: Icon(FontAwesomeIcons.rotateLeft, size: 14.sp),
                label: Text(
                  'افتراضي',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: Obx(() => _SaveButton(
                isLoading: controller.isSaving.value,
                label: 'حفظ الألوان',
                onTap: controller.saveThemeColors,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// صفحة إعدادات واتساب
// ============================================================================

class _WhatsAppSettingsPage extends StatelessWidget {
  const _WhatsAppSettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'إعدادات واتساب',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Icon(FontAwesomeIcons.arrowRight, size: 18.sp),
        ),
      ),
      body: GetBuilder<SettingsController>(
        builder: (controller) => SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // شرح المتغيرات
              Container(
                padding: EdgeInsets.all(AppSpacing.md.r),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(FontAwesomeIcons.circleInfo, size: 14.sp, color: AppColors.info),
                        SizedBox(width: 6.w),
                        Text(
                          'المتغيرات المتاحة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: [
                        '{customerName}',
                        '{invoiceNumber}',
                        '{status}',
                        '{trackUrl}',
                        '{laundryName}',
                        '{totalPrice}',
                        '{pickupDate}',
                      ].map((var) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          var,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),

              // حقل القالب
              Text(
                'قالب الرسالة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              TextField(
                controller: controller.whatsappTemplate,
                maxLines: 8,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13.sp,
                  color: AppColors.text,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: 'أدخل قالب رسالة واتساب...',
                  hintStyle: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppColors.accent, width: 2),
                  ),
                  contentPadding: EdgeInsets.all(12.r),
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),

              // زر استعادة الافتراضي
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: controller.resetWhatsappTemplate,
                  icon: Icon(FontAwesomeIcons.rotateLeft, size: 12.sp),
                  label: Text(
                    'استعادة القالب الافتراضي',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),

              // المعاينة
              Text(
                'معاينة الرسالة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.md.r),
                decoration: BoxDecoration(
                  color: AppColors.whatsapp.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                    bottomLeft: Radius.circular(16.r),
                  ),
                  border: Border.all(color: AppColors.whatsapp.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // واتساب header
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.whatsapp.withValues(alpha: 0.15)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(FontAwesomeIcons.whatsapp, size: 16.sp, color: AppColors.whatsapp),
                          SizedBox(width: 8.w),
                          Text(
                            'معاينة واتساب',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.whatsapp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // محتوى الرسالة
                    GetBuilder<SettingsController>(
                      builder: (c) => Text(
                        c.getPreviewMessage(),
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13.sp,
                          color: AppColors.text,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),

              // أزرار الحفظ
              Obx(() => _SaveButton(
                isLoading: controller.isSaving.value,
                label: 'حفظ قالب واتساب',
                onTap: controller.saveWhatsappTemplate,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// صفحة النسخ الاحتياطي
// ============================================================================

class _BackupSettingsPage extends StatelessWidget {
  const _BackupSettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'النسخ الاحتياطي',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Icon(FontAwesomeIcons.arrowRight, size: 18.sp),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.md.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // تنبيه
            Container(
              padding: EdgeInsets.all(AppSpacing.md.r),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(FontAwesomeIcons.triangleExclamation, size: 16.sp, color: AppColors.warning),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'تأكد من عمل نسخة احتياطية دورية لحفظ جميع إعداداتك وبياناتك. عند الاستيراد سيتم استبدال جميع الإعدادات الحالية.',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12.sp,
                        color: AppColors.text,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xl.h),

            // زر التصدير
            Obx(() {
              final controller = Get.find<SettingsController>();
              return _BackupActionCard(
                icon: FontAwesomeIcons.cloudArrowUp,
                title: 'تصدير النسخة الاحتياطية',
                subtitle: 'حفظ جميع الإعدادات والبيانات في ملف JSON',
                color: AppColors.success,
                isLoading: controller.isLoading.value,
                onTap: controller.exportData,
                buttonText: 'تصدير الآن',
              );
            }),
            SizedBox(height: AppSpacing.lg.h),

            // زر الاستيراد
            Obx(() {
              final controller = Get.find<SettingsController>();
              return _BackupActionCard(
                icon: FontAwesomeIcons.cloudArrowDown,
                title: 'استيراد نسخة احتياطية',
                subtitle: 'استعادة الإعدادات من ملف JSON محفوظ',
                color: AppColors.info,
                isLoading: controller.isLoading.value,
                onTap: controller.importData,
                buttonText: 'اختر ملف',
              );
            }),
            SizedBox(height: AppSpacing.xl.h),

            // معلومات إضافية
            Container(
              padding: EdgeInsets.all(AppSpacing.md.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ما يتم تضمينه في النسخة الاحتياطية:',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ...[
                    'إعدادات الفاتورة (الرأس، التذييل، الرقم الضريبي)',
                    'إعدادات المغسلة (الاسم، الشعار)',
                    'قالب رسائل واتساب',
                    'تخصيص الألوان والثيم',
                    'تفضيلات الوضع الليلي',
                  ].map((item) => Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Row(
                      children: [
                        Icon(FontAwesomeIcons.check, size: 10.sp, color: AppColors.success),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12.sp,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// مكونات مساعدة للصفحات الفرعية
// ============================================================================

/// حقل نصي للإعدادات
class _SettingsTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType inputType;

  const _SettingsTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13.sp, color: AppColors.primary),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          keyboardType: inputType,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14.sp,
            color: AppColors.text,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12.sp,
              color: AppColors.textMuted,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }
}

/// مفتاح تبديل للإعدادات
class _SettingsToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _SettingsToggle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 14.sp, color: activeColor),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            activeTrackColor: activeColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

/// قسم رفع الصور
class _ImageUploadSection extends StatelessWidget {
  final String currentUrl;
  final Rx<File?> selectedFile;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final String placeholder;
  final bool isSquare;

  const _ImageUploadSection({
    required this.currentUrl,
    required this.selectedFile,
    required this.onPick,
    required this.onRemove,
    required this.placeholder,
    this.isSquare = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasImage = selectedFile.value != null || currentUrl.isNotEmpty;

      return GestureDetector(
        onTap: onPick,
        child: Container(
          width: double.infinity,
          height: isSquare ? 150.h : 120.h,
          decoration: BoxDecoration(
            color: hasImage ? null : AppColors.bg,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: hasImage ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
              width: hasImage ? 2 : 1,
              style: BorderStyle.solid,
            ),
            image: hasImage
                ? (selectedFile.value != null
                    ? DecorationImage(
                        image: FileImage(selectedFile.value!),
                        fit: BoxFit.cover,
                      )
                    : currentUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(currentUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => null,
                          )
                        : null)
                : null,
          ),
          child: hasImage
              ? Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: EdgeInsets.all(8.r),
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Icon(
                        FontAwesomeIcons.xmark,
                        size: 10.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.cloudArrowUp,
                        size: 28.sp,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        placeholder,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    });
  }
}

/// صف منتقي الألوان
class _ColorPickerRow extends StatelessWidget {
  final String name;
  final String hexValue;
  final ValueChanged<String> onChanged;

  const _ColorPickerRow({
    required this.name,
    required this.hexValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = _tryParseColor(hexValue);

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // معاينة اللون
          GestureDetector(
            onTap: () => _showColorPicker(context, hexValue, onChanged),
            child: Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // اسم اللون والقيمة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  hexValue.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11.sp,
                    fontFamilyFallback: const ['monospace'],
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // زر الاختيار
          GestureDetector(
            onTap: () => _showColorPicker(context, hexValue, onChanged),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'تغيير',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// عرض منتقي الألوان
  void _showColorPicker(BuildContext context, String currentColor, ValueChanged<String> onChanged) {
    showDialog(
      context: context,
      builder: (ctx) => _ColorPickerDialog(
        currentColor: currentColor,
        onColorChanged: onChanged,
      ),
    );
  }
}

/// حوار منتقي الألوان
class _ColorPickerDialog extends StatefulWidget {
  final String currentColor;
  final ValueChanged<String> onColorChanged;

  const _ColorPickerDialog({
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late TextEditingController _hexController;
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = _tryParseColor(widget.currentColor);
    _hexController = TextEditingController(text: widget.currentColor.toUpperCase());
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _updateFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      setState(() {
        _currentColor = Color(int.parse('FF$cleaned', radix: 16));
      });
    }
  }

  void _save() {
    final hex = '#${_currentColor.toHex().substring(2)}'.toUpperCase();
    widget.onColorChanged(hex);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(
        'اختر اللون',
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // معاينة اللون
          Container(
            width: double.infinity,
            height: 60.h,
            decoration: BoxDecoration(
              color: _currentColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          // ألوان سريعة
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _quickColor('#0B3D2E'),
              _quickColor('#C8963E'),
              _quickColor('#DC2626'),
              _quickColor('#16A34A'),
              _quickColor('#2563EB'),
              _quickColor('#7C3AED'),
              _quickColor('#D97706'),
              _quickColor('#0891B2'),
              _quickColor('#1C1917'),
              _quickColor('#F5F0E8'),
              _quickColor('#FFFFFF'),
              _quickColor('#78716C'),
            ].map((item) => GestureDetector(
              onTap: () {
                setState(() {
                  _currentColor = _tryParseColor(item);
                  _hexController.text = item.toUpperCase();
                });
              },
              child: Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: _tryParseColor(item),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
            )).toList(),
          ),
          SizedBox(height: AppSpacing.md.h),
          // حقل إدخال Hex
          TextField(
            controller: _hexController,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.text,
            onChanged: (v) => _updateFromHex(v),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              hintText: '#000000',
              hintStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14.sp,
                color: AppColors.textMuted,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.all(10.r),
                child: Container(
                  width: 20.r,
                  height: 20.r,
                  decoration: BoxDecoration(
                    color: _currentColor,
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'إلغاء',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          ),
          child: Text(
            'تأكيد',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _quickColor(String hex) => hex;
}

/// بطاقة إجراء النسخ الاحتياطي
class _BackupActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;
  final String buttonText;

  const _BackupActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isLoading,
    required this.onTap,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 20.sp, color: color),
              ),
              SizedBox(width: AppSpacing.sm.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onTap,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(icon, size: 14.sp),
              label: Text(
                buttonText,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// زر حفظ
class _SaveButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback onTap;

  const _SaveButton({
    required this.isLoading,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.check, size: 18),
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          elevation: 2,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// دوال مساعدة
// ============================================================================

/// تحويل hex string إلى Color
Color _tryParseColor(String hex) {
  try {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    } else if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
  } catch (_) {}
  return const Color(0xFF000000);
}

/// توسيع Color لتحويل إلى hex
extension ColorExtension on Color {
  String toHex() {
    return value.toRadixString(16).padLeft(8, '0');
  }
}
