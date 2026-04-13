import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';

// ============================================================
// وحدة الإشعار المحلية (نموذج بسيط للشاشة)
// ============================================================
class NotificationRecord {
  final String id;
  final String title;
  final String body;
  final String? senderName;
  final int createdAt;
  final bool isRead;

  NotificationRecord({
    this.id = '',
    this.title = '',
    this.body = '',
    this.senderName,
    int? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory NotificationRecord.fromJson(Map<String, dynamic> json) {
    return NotificationRecord(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      senderName: json['senderName'],
      createdAt: json['createdAt'] is int
          ? json['createdAt']
          : int.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now().millisecondsSinceEpoch,
      isRead: json['isRead'] ?? false,
    );
  }
}

// ============================================================
// إحصائيات المندوب
// ============================================================
class DelegateStats {
  final int totalOrders;
  final int pendingOrders;
  final int pickedOrders;
  final int completedOrders;
  final double totalRevenue;

  DelegateStats({
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.pickedOrders = 0,
    this.completedOrders = 0,
    this.totalRevenue = 0.0,
  });

  factory DelegateStats.fromJson(Map<String, dynamic> json) {
    return DelegateStats(
      totalOrders: json['totalOrders'] ?? json['total_orders'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? json['pending_orders'] ?? 0,
      pickedOrders: json['pickedOrders'] ?? json['picked_orders'] ?? 0,
      completedOrders:
          json['completedOrders'] ?? json['completed_orders'] ?? 0,
      totalRevenue: _toDouble(json['totalRevenue'] ?? json['total_revenue']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// ============================================================
// بيانات المندوب مع الإحصائيات
// ============================================================
class DelegateWithStats {
  final UserModel delegate;
  DelegateStats stats;

  DelegateWithStats({required this.delegate, required this.stats});
}

// ============================================================
// وحدة التحكم في المندوبين
// ============================================================
class DelegatesController extends GetxController {
  final ApiService _api = ApiService.to;

  // ---- الحقول ----
  final delegates = <DelegateWithStats>[].obs;
  final notifications = <NotificationRecord>[].obs;
  final isLoading = false.obs;
  final isFormVisible = false.obs;
  final isSendingNotification = false.obs;
  final isDeleting = ''.obs; // id المندوب قيد الحذف
  final searchQuery = ''.obs;

  // ---- محررات النموذج ----
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final invoiceStartController = TextEditingController();
  final notificationTitleController = TextEditingController();
  final notificationBodyController = TextEditingController();

  // ---- المفاتيح ----
  final formKey = GlobalKey<FormState>();
  final notifFormKey = GlobalKey<FormState>();

  // ---- المندوب المحدد ----
  final selectedDelegate = Rx<UserModel?>(null);
  final showDelegateOrders = false.obs;
  final delegateOrders = <OrderModel>[].obs;
  final isLoadingOrders = false.obs;

  // ---- تعيين المندوب المحدد للتعديل ----
  final editingDelegateId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDelegates();
    fetchNotifications();
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    invoiceStartController.dispose();
    notificationTitleController.dispose();
    notificationBodyController.dispose();
    super.onClose();
  }

  // ---- جلب المندوبين ----
  Future<void> fetchDelegates() async {
    isLoading.value = true;
    try {
      final response = await _api.get('delegates');
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> list =
            data is List ? data : (data['delegates'] ?? data['data'] ?? []);
        delegates.value = list.map((e) {
          final user = UserModel.fromJson(e);
          final stats =
              e['stats'] != null ? DelegateStats.fromJson(e['stats']) : DelegateStats();
          return DelegateWithStats(delegate: user, stats: stats);
        }).toList();
      }
    } catch (e) {
      debugPrint('خطأ في جلب المندوبين: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---- جلب الإشعارات ----
  Future<void> fetchNotifications() async {
    try {
      final response = await _api.get('notifications/delegates');
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> list =
            data is List ? data : (data['notifications'] ?? data['data'] ?? []);
        notifications.value =
            list.map((e) => NotificationRecord.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('خطأ في جلب الإشعارات: $e');
    }
  }

  // ---- تبديل حالة النموذج ----
  void toggleForm() {
    isFormVisible.value = !isFormVisible.value;
    if (!isFormVisible.value) clearForm();
  }

  // ---- مسح النموذج ----
  void clearForm() {
    usernameController.clear();
    passwordController.clear();
    fullNameController.clear();
    phoneController.clear();
    invoiceStartController.clear();
    editingDelegateId.value = '';
    formKey.currentState?.reset();
  }

  // ---- تعبئة النموذج للتعديل ----
  void editDelegate(DelegateWithStats item) {
    editingDelegateId.value = item.delegate.id;
    usernameController.text = item.delegate.username;
    passwordController.text = item.delegate.password;
    fullNameController.text = item.delegate.fullName;
    phoneController.text = item.delegate.phone;
    invoiceStartController.text = item.delegate.invoicePrefix ?? '';
    isFormVisible.value = true;
  }

  // ---- إضافة / تعديل مندوب ----
  Future<void> submitDelegate() async {
    if (!formKey.currentState!.validate()) return;

    final data = {
      'username': usernameController.text.trim(),
      'password': passwordController.text.trim(),
      'fullName': fullNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'role': 'delegate',
      'invoicePrefix': invoiceStartController.text.trim(),
      'isActive': true,
    };

    try {
      if (editingDelegateId.value.isNotEmpty) {
        // تعديل
        final response =
            await _api.put('delegates/${editingDelegateId.value}', data: data);
        if (response != null && response.statusCode == 200) {
          Get.snackbar(
            'تم التحديث',
            'تم تحديث بيانات المندوب بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: Colors.white,
            margin: EdgeInsets.all(16.r),
            borderRadius: 12.r,
          );
        }
      } else {
        // إضافة
        final response = await _api.post('delegates', data: data);
        if (response != null && response.statusCode == 200 || response?.statusCode == 201) {
          Get.snackbar(
            'تمت الإضافة',
            'تمت إضافة المندوب بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: Colors.white,
            margin: EdgeInsets.all(16.r),
            borderRadius: 12.r,
          );
        }
      }
      clearForm();
      isFormVisible.value = false;
      await fetchDelegates();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء حفظ البيانات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        margin: EdgeInsets.all(16.r),
        borderRadius: 12.r,
      );
    }
  }

  // ---- حذف مندوب ----
  Future<void> deleteDelegate(String delegateId, String name) async {
    final confirmed = await Get.defaultDialog<bool>(
      title: 'تأكيد الحذف',
      middleText: 'هل أنت متأكد من حذف المندوب "$name"؟',
      textCancel: 'إلغاء',
      textConfirm: 'حذف',
      confirmTextColor: Colors.white,
      cancelTextColor: AppColors.primary,
      buttonColor: AppColors.danger,
      radius: 16,
    );

    if (confirmed != true) return;

    isDeleting.value = delegateId;
    try {
      final response = await _api.delete('delegates/$delegateId');
      if (response != null && response.statusCode == 200) {
        delegates.removeWhere((e) => e.delegate.id == delegateId);
        Get.snackbar(
          'تم الحذف',
          'تم حذف المندوب بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          margin: EdgeInsets.all(16.r),
          borderRadius: 12.r,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء حذف المندوب',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        margin: EdgeInsets.all(16.r),
        borderRadius: 12.r,
      );
    } finally {
      isDeleting.value = '';
    }
  }

  // ---- إرسال إشعار ----
  Future<void> sendNotification() async {
    if (notificationTitleController.text.trim().isEmpty ||
        notificationBodyController.text.trim().isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى كتابة عنوان ونص الإشعار',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
        margin: EdgeInsets.all(16.r),
        borderRadius: 12.r,
      );
      return;
    }

    isSendingNotification.value = true;
    try {
      final response = await _api.post('notifications/send', data: {
        'title': notificationTitleController.text.trim(),
        'body': notificationBodyController.text.trim(),
        'target': 'all_delegates',
      });

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        Get.snackbar(
          'تم الإرسال',
          'تم إرسال الإشعار لجميع المندوبين',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          margin: EdgeInsets.all(16.r),
          borderRadius: 12.r,
        );
        notificationTitleController.clear();
        notificationBodyController.clear();
        await fetchNotifications();
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء إرسال الإشعار',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        margin: EdgeInsets.all(16.r),
        borderRadius: 12.r,
      );
    } finally {
      isSendingNotification.value = false;
    }
  }

  // ---- عرض طلبات المندوب ----
  Future<void> viewDelegateOrders(DelegateWithStats item) async {
    selectedDelegate.value = item.delegate;
    showDelegateOrders.value = true;
    isLoadingOrders.value = true;
    try {
      final response = await _api.get('delegates/${item.delegate.id}/orders');
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> list =
            data is List ? data : (data['orders'] ?? data['data'] ?? []);
        delegateOrders.value =
            list.map((e) => OrderModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('خطأ في جلب طلبات المندوب: $e');
    } finally {
      isLoadingOrders.value = false;
    }
  }

  // ---- إغلاق عرض الطلبات ----
  void closeDelegateOrders() {
    showDelegateOrders.value = false;
    selectedDelegate.value = null;
    delegateOrders.clear();
  }

  // ---- الاتصال بالمندوب ----
  Future<void> callDelegate(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ---- واتساب ----
  Future<void> whatsappDelegate(String phone) async {
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ---- تحديث البحث ----
  void updateSearch(String query) {
    searchQuery.value = query;
  }

  // ---- قائمة المندوبين المفلترة ----
  List<DelegateWithStats> get filteredDelegates {
    if (searchQuery.value.isEmpty) return delegates;
    final q = searchQuery.value.toLowerCase();
    return delegates
        .where((e) =>
            e.delegate.fullName.toLowerCase().contains(q) ||
            e.delegate.username.toLowerCase().contains(q) ||
            e.delegate.phone.contains(q))
        .toList();
  }

  // ---- تحديث للسحب ----
  Future<void> refreshData() async {
    await Future.wait([fetchDelegates(), fetchNotifications()]);
  }
}

// ============================================================
// شاشة إدارة المندوبين
// ============================================================
class DelegatesScreen extends GetView<DelegatesController> {
  const DelegatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        appBar: _buildAppBar(),
        body: Obx(() {
          if (controller.showDelegateOrders.value) {
            return _buildDelegateOrdersView();
          }
          return RefreshIndicator(
            onRefresh: controller.refreshData,
            color: AppColors.accent,
            backgroundColor: Colors.white,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              children: [
                _buildStatsSummary(),
                SizedBox(height: 12.h),
                _buildAddDelegateCard(),
                SizedBox(height: 12.h),
                _buildNotificationSection(),
                SizedBox(height: 16.h),
                _buildSearchBar(),
                SizedBox(height: 12.h),
                _buildDelegatesList(),
              ],
            ),
          );
        }),
        floatingActionButton: Obx(() => controller.showDelegateOrders.value
            ? const SizedBox.shrink()
            : FloatingActionButton(
                onPressed: () {
                  controller.isFormVisible.value
                      ? controller.toggleForm()
                      : null;
                  if (!controller.isFormVisible.value) {
                    controller.toggleForm();
                    _scrollToForm(context);
                  }
                },
                backgroundColor: AppColors.accent,
                child: const Icon(Icons.person_add, color: Colors.white),
              )),
      ),
    );
  }

  // ---- شريط التطبيق ----
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'إدارة المندوبين',
        style: TextStyle(fontFamily: 'Tajawal'),
      ),
      actions: [
        Obx(() => controller.showDelegateOrders.value
            ? IconButton(
                onPressed: controller.closeDelegateOrders,
                icon: const Icon(Icons.close),
                tooltip: 'رجوع',
              )
            : IconButton(
                onPressed: () => Get.to(() => const TrackingScreen()),
                icon: const FaIcon(FontAwesomeIcons.locationDot),
                tooltip: 'تتبع المندوبين',
              )),
      ],
      leading: Obx(() => controller.showDelegateOrders.value
          ? IconButton(
              onPressed: controller.closeDelegateOrders,
              icon: const Icon(Icons.arrow_forward),
            )
          : const SizedBox.shrink()),
    );
  }

  // ---- ملخص الإحصائيات ----
  Widget _buildStatsSummary() {
    return Obx(() {
      final total = controller.delegates.length;
      final active = controller.delegates
          .where((e) => e.delegate.isActive)
          .length;
      final totalOrders = controller.delegates.fold<int>(
          0, (sum, e) => sum + e.stats.totalOrders);
      final totalRevenue = controller.delegates.fold<double>(
          0, (sum, e) => sum + e.stats.totalRevenue);

      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B3D2E), Color(0xFF1B5E3B)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B3D2E).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem(Icons.people, 'المندوبين', '$total', Colors.white),
            _statItem(Icons.check_circle, 'النشطين', '$active',
                AppColors.accentLight),
            _statItem(Icons.receipt, 'الطلبات', '$totalOrders', Colors.white),
            _statItem(Icons.attach_money, 'الإيرادات',
                '${totalRevenue.toStringAsFixed(0)}', AppColors.accentLight),
          ],
        ),
      );
    });
  }

  Widget _statItem(IconData icon, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22.r),
        SizedBox(height: 6.h),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal')),
        SizedBox(height: 2.h),
        Text(label,
            style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 11.sp,
                fontFamily: 'Tajawal')),
      ],
    );
  }

  // ---- بطاقة إضافة مندوب ----
  Widget _buildAddDelegateCard() {
    return Obx(() {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // رأس البطاقة
            InkWell(
              onTap: controller.toggleForm,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(controller.isFormVisible.value ? 0 : 16.r),
                  bottom: Radius.circular(
                      controller.isFormVisible.value ? 0 : 16.r)),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: controller.isFormVisible.value
                      ? AppColors.primary
                      : AppColors.accent,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16.r),
                    bottom: Radius.circular(controller.isFormVisible.value ? 0 : 16.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          controller.isFormVisible.value
                              ? Icons.close
                              : Icons.person_add,
                          color: Colors.white,
                          size: 22.r,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          controller.editingDelegateId.value.isNotEmpty
                              ? 'تعديل بيانات المندوب'
                              : 'إضافة مندوب جديد',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      controller.isFormVisible.value
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 26.r,
                    ),
                  ],
                ),
              ),
            ),

            // محتوى النموذج
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              child: controller.isFormVisible.value
                  ? Container(
                      padding: EdgeInsets.all(16.r),
                      child: Form(
                        key: controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildFormRow([
                              _buildTextField(
                                label: 'اسم المستخدم',
                                hint: 'مثال: delegate1',
                                icon: Icons.person,
                                controller: controller.usernameController,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'اسم المستخدم مطلوب';
                                  }
                                  if (v.trim().length < 3) {
                                    return '3 أحرف على الأقل';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(width: 12.w),
                              _buildTextField(
                                label: 'كلمة المرور',
                                hint: '••••••••',
                                icon: Icons.lock,
                                controller: controller.passwordController,
                                isPassword: true,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'كلمة المرور مطلوبة';
                                  }
                                  if (v.trim().length < 4) {
                                    return '4 أحرف على الأقل';
                                  }
                                  return null;
                                },
                              ),
                            ]),
                            SizedBox(height: 12.h),
                            _buildFormRow([
                              _buildTextField(
                                label: 'الاسم الكامل',
                                hint: 'مثال: أحمد محمد',
                                icon: Icons.badge,
                                controller: controller.fullNameController,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'الاسم الكامل مطلوب';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(width: 12.w),
                              _buildTextField(
                                label: 'رقم الهاتف',
                                hint: 'مثال: 0512345678',
                                icon: Icons.phone_android,
                                controller: controller.phoneController,
                                keyboardType: TextInputType.phone,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'رقم الهاتف مطلوب';
                                  }
                                  if (v.trim().length < 10) {
                                    return 'رقم غير صحيح';
                                  }
                                  return null;
                                },
                              ),
                            ]),
                            SizedBox(height: 12.h),
                            _buildTextField(
                              label: 'رقم بداية الفاتورة',
                              hint: 'مثال: A1000',
                              icon: Icons.receipt_long,
                              controller: controller.invoiceStartController,
                              keyboardType: TextInputType.text,
                            ),
                            SizedBox(height: 16.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: controller.submitDelegate,
                                icon: Icon(
                                  controller.editingDelegateId.value.isNotEmpty
                                      ? Icons.save
                                      : Icons.person_add,
                                  size: 20.r,
                                ),
                                label: Text(
                                  controller.editingDelegateId.value.isNotEmpty
                                      ? 'حفظ التعديلات'
                                      : 'إضافة المندوب',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFormRow(List<Widget> children) {
    return Row(
      children: children.map((c) => Expanded(child: c)).toList(),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      textDirection: TextDirection.rtl,
      style: TextStyle(
          fontSize: 14.sp, fontFamily: 'Tajawal', color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintTextDirection: TextDirection.rtl,
        prefixIcon: Icon(icon, size: 20.r, color: AppColors.textMuted),
        suffixIcon: isPassword
            ? Icon(Icons.visibility_off_outlined, size: 20.r, color: AppColors.textMuted)
            : null,
        filled: true,
        fillColor: const Color(0xFFF9F6F1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: TextStyle(
            fontFamily: 'Tajawal', color: AppColors.textMuted, fontSize: 13.sp),
        hintStyle: TextStyle(
            fontFamily: 'Tajawal', color: AppColors.textMuted, fontSize: 12.sp),
      ),
    );
  }

  // ---- قسم الإشعارات ----
  Widget _buildNotificationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // رأس القسم
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.info,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إرسال إشعار للمندوبين',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const FaIcon(FontAwesomeIcons.bell, color: Colors.white, size: 18),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(14.r),
            child: Column(
              children: [
                TextField(
                  controller: controller.notificationTitleController,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                      fontSize: 14.sp, fontFamily: 'Tajawal', color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'عنوان الإشعار',
                    hintText: 'أدخل عنوان الإشعار',
                    hintTextDirection: TextDirection.rtl,
                    prefixIcon: const Icon(Icons.title, color: AppColors.textMuted),
                    filled: true,
                    fillColor: const Color(0xFFF9F6F1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppColors.accent, width: 2),
                    ),
                    labelStyle: TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppColors.textMuted,
                        fontSize: 13.sp),
                  ),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: controller.notificationBodyController,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  style: TextStyle(
                      fontSize: 14.sp, fontFamily: 'Tajawal', color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'نص الإشعار',
                    hintText: 'أدخل نص الإشعار',
                    hintTextDirection: TextDirection.rtl,
                    prefixIcon:
                        const Icon(Icons.message, color: AppColors.textMuted),
                    filled: true,
                    fillColor: const Color(0xFFF9F6F1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppColors.accent, width: 2),
                    ),
                    labelStyle: TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppColors.textMuted,
                        fontSize: 13.sp),
                  ),
                ),
                SizedBox(height: 12.h),
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.isSendingNotification.value
                        ? null
                        : controller.sendNotification,
                    icon: controller.isSendingNotification.value
                        ? SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const FaIcon(FontAwesomeIcons.paperPlane, size: 16),
                    label: Text(
                      controller.isSendingNotification.value
                          ? 'جارٍ الإرسال...'
                          : 'إرسال الإشعار',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                )),

                // سجل الإشعارات
                if (controller.notifications.isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  const Divider(color: AppColors.border),
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'سجل الإشعارات',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ...controller.notifications
                      .take(3)
                      .map((n) => _buildNotificationItem(n)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationRecord notif) {
    final time = DateTime.fromMillisecondsSinceEpoch(notif.createdAt);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: notif.isRead
            ? const Color(0xFFF9F6F1)
            : AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
            color: notif.isRead ? AppColors.border : AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: const Icon(Icons.notifications, color: AppColors.info, size: 18),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textMuted,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  notif.body,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                    fontFamily: 'Tajawal',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- شريط البحث ----
  Widget _buildSearchBar() {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: controller.updateSearch,
        textDirection: TextDirection.rtl,
        style: TextStyle(fontSize: 14.sp, fontFamily: 'Tajawal'),
        decoration: InputDecoration(
          hintText: 'بحث عن مندوب...',
          hintTextDirection: TextDirection.rtl,
          prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 22.r),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    controller.searchQuery.value = '';
                    controller.searchQuery.refresh();
                  },
                  icon: Icon(Icons.close, color: AppColors.textMuted, size: 20.r),
                )
              : const SizedBox.shrink()),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          hintStyle: TextStyle(
              fontFamily: 'Tajawal', color: AppColors.textMuted, fontSize: 13.sp),
        ),
      ),
    );
  }

  // ---- قائمة المندوبين ----
  Widget _buildDelegatesList() {
    return Obx(() {
      if (controller.isLoading.value && controller.delegates.isEmpty) {
        return _buildShimmerList();
      }
      if (controller.filteredDelegates.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        children: controller.filteredDelegates
            .map((item) => _buildDelegateCard(item))
            .toList(),
      );
    });
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                        width: 48.r,
                        height: 48.r,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        )),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              height: 16.h,
                              width: double.infinity,
                              color: Colors.white),
                          SizedBox(height: 8.h),
                          Container(
                              height: 12.h, width: 120.w, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    4,
                    (_) => Container(
                        height: 40.h, width: 60.w, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 80.r, color: AppColors.textMuted),
          SizedBox(height: 16.h),
          Text(
            'لا يوجد مندوبين',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'اضغط على زر الإضافة لإنشاء مندوب جديد',
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: 'Tajawal',
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---- بطاقة المندوب ----
  Widget _buildDelegateCard(DelegateWithStats item) {
    final d = item.delegate;
    final s = item.stats;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: d.isActive
              ? AppColors.success.withOpacity(0.3)
              : AppColors.textMuted.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // رأس البطاقة - معلومات المندوب
          InkWell(
            onTap: () => controller.viewDelegateOrders(item),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            child: Padding(
              padding: EdgeInsets.all(14.r),
              child: Row(
                children: [
                  // صورة رمزية
                  Container(
                    width: 50.r,
                    height: 50.r,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: d.isActive
                            ? [AppColors.primary, AppColors.primaryLight]
                            : [Colors.grey, Colors.grey[400]!],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Center(
                      child: Text(
                        d.fullName.isNotEmpty ? d.fullName[0] : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // المعلومات
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              d.fullName,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                                color: AppColors.text,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: d.isActive
                                    ? AppColors.success.withOpacity(0.12)
                                    : AppColors.danger.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                d.isActive ? 'نشط' : 'معطّل',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Tajawal',
                                  color: d.isActive
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 14.r, color: AppColors.textMuted),
                            SizedBox(width: 4.w),
                            Text(
                              d.username,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontFamily: 'Tajawal',
                                color: AppColors.textMuted,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Icon(Icons.phone_outlined,
                                size: 14.r, color: AppColors.textMuted),
                            SizedBox(width: 4.w),
                            Text(
                              d.phone,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontFamily: 'Tajawal',
                                color: AppColors.textMuted,
                              ),
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // سهم عرض الطلبات
                  Icon(Icons.chevron_left,
                      size: 24.r, color: AppColors.primary),
                ],
              ),
            ),
          ),

          // فاتورة
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6F1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            margin: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long,
                        size: 16.r, color: AppColors.accent),
                    SizedBox(width: 6.w),
                    Text(
                      'بداية الفاتورة: ${d.invoicePrefix ?? "-"}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontFamily: 'Tajawal',
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.receipt,
                        size: 16.r, color: AppColors.accent),
                    SizedBox(width: 6.w),
                    Text(
                      'الحالية: ${d.currentInvoiceNumber ?? "-"}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontFamily: 'Tajawal',
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // إحصائيات سريعة
          Padding(
            padding: EdgeInsets.all(14.r),
            child: Row(
              children: [
                _miniStat(
                    'الطلبات',
                    '${s.totalOrders}',
                    AppColors.info,
                    Icons.receipt),
                SizedBox(width: 4.w),
                _miniStat('معلّق', '${s.pendingOrders}',
                    AppColors.warning, Icons.pending),
                SizedBox(width: 4.w),
                _miniStat('مُلتقط', '${s.pickedOrders}',
                    AppColors.statusPicked, Icons.inventory_2),
                SizedBox(width: 4.w),
                _miniStat('مكتمل', '${s.completedOrders}',
                    AppColors.success, Icons.check_circle),
                SizedBox(width: 4.w),
                Expanded(
                  child: _miniStat('الإيرادات',
                      '${s.totalRevenue.toStringAsFixed(0)}', AppColors.accent, Icons.attach_money),
                ),
              ],
            ),
          ),

          // أزرار الإجراءات
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(
                  label: 'الطلبات',
                  icon: Icons.list_alt,
                  color: AppColors.info,
                  onTap: () => controller.viewDelegateOrders(item),
                ),
                _actionButton(
                  label: 'اتصال',
                  icon: Icons.phone,
                  color: AppColors.success,
                  onTap: () => controller.callDelegate(d.phone),
                ),
                _actionButton(
                  label: 'واتساب',
                  icon: FontAwesomeIcons.whatsapp,
                  color: AppColors.whatsapp,
                  onTap: () => controller.whatsappDelegate(d.phone),
                ),
                _actionButton(
                  label: 'تعديل',
                  icon: Icons.edit_outlined,
                  color: AppColors.accent,
                  onTap: () => controller.editDelegate(item),
                ),
                Obx(() => _actionButton(
                      label: 'حذف',
                      icon: controller.isDeleting.value == d.id
                          ? Icons.hourglass_empty
                          : Icons.delete_outline,
                      color: AppColors.danger,
                      onTap: controller.isDeleting.value == d.id
                          ? null
                          : () => controller.deleteDelegate(d.id, d.fullName),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13.r, color: color),
                SizedBox(width: 3.w),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.sp,
                fontFamily: 'Tajawal',
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.r, color: color),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontFamily: 'Tajawal',
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- عرض طلبات المندوب ----
  Widget _buildDelegateOrdersView() {
    final delegate = controller.selectedDelegate.value;
    return Column(
      children: [
        // شريط معلومات المندوب
        Container(
          padding: EdgeInsets.all(16.r),
          margin: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B3D2E), Color(0xFF1B5E3B)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Container(
                width: 50.r,
                height: 50.r,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: Text(
                    delegate?.fullName.isNotEmpty == true
                        ? delegate!.fullName[0]
                        : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طلبات المندوب: ${delegate?.fullName ?? ""}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'إجمالي الطلبات: ${controller.delegateOrders.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13.sp,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // قائمة الطلبات
        Expanded(
          child: Obx(() {
            if (controller.isLoadingOrders.value) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }
            if (controller.delegateOrders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 64.r, color: AppColors.textMuted),
                    SizedBox(height: 16.h),
                    Text(
                      'لا توجد طلبات',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontFamily: 'Tajawal',
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: controller.delegateOrders.length,
              itemBuilder: (context, index) {
                final order = controller.delegateOrders[index];
                return _buildOrderCard(order);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusColor =
        AppColors.statusColors[order.orderStatus] ?? AppColors.textMuted;
    final statusLightColor =
        AppColors.statusLightColors[order.orderStatus] ?? const Color(0xFFF5F0E8);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '#${order.invoiceNumber}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: statusLightColor,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6.r,
                          height: 6.r,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          order.statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                '${order.totalPrice.toStringAsFixed(2)} ر.س',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 14.r, color: AppColors.textMuted),
              SizedBox(width: 4.w),
              Text(order.customerName,
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontFamily: 'Tajawal',
                      color: AppColors.text)),
              SizedBox(width: 16.w),
              Icon(Icons.location_on_outlined,
                  size: 14.r, color: AppColors.textMuted),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(order.neighborhood,
                    style: TextStyle(
                        fontSize: 12.sp,
                        fontFamily: 'Tajawal',
                        color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- التمرير للنموذج ----
  void _scrollToForm(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 400), () {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }
}

// ============================================================
// شاشة التتبع (استيراد مسبق)
// ============================================================
// TrackingController و TrackingScreen في ملف tracking_screen.dart

// استيراد التتبع
export 'tracking_screen.dart';
