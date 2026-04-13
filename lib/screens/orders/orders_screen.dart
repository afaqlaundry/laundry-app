import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_xlsx/xlsx.dart' as xlsx;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';

// ============================================================
// وحدة تحكم الطلبات
// ============================================================

class OrdersController extends GetxController {
  final ApiService _api = ApiService.to;

  // ===== حالة البيانات =====
  final RxList<OrderModel> allOrders = <OrderModel>[].obs;
  final RxList<OrderModel> filteredOrders = <OrderModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isFilterVisible = false.obs;
  final RxBool hasMore = true.obs;
  final RxInt currentPage = 1.obs;
  final int pageSize = 20;

  // ===== حالة الفلاتر =====
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedNeighborhood = 'all'.obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  // ===== الحارات المتاحة =====
  final RxList<String> neighborhoods = <String>[].obs;

  // ===== حالات الطلب =====
  static const Map<String, String> statusOptions = {
    'all': 'جميع الحالات',
    'pending': 'قيد الانتظار',
    'picked': 'بانتظار البيانات',
    'data_ready': 'جاهز للتسليم',
    'ready_for_delivery': 'جاهز للاستلام',
    'completed': 'تم التسليم',
    'cancelled': 'ملغي',
    'no': 'غير مستلم',
  };

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
    fetchNeighborhoods();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // ===== جلب الطلبات =====
  Future<void> fetchOrders() async {
    isLoading.value = true;
    currentPage.value = 1;
    hasMore.value = true;

    try {
      final response = await _api.get('orders');

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> ordersJson;

        if (data is Map && data['data'] != null) {
          ordersJson = data['data'] as List<dynamic>;
        } else if (data is List) {
          ordersJson = data;
        } else {
          ordersJson = [];
        }

        allOrders.assignAll(
          ordersJson.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList(),
        );
        _applyFilters();
      }
    } catch (e) {
      debugPrint('خطأ في جلب الطلبات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ===== تحديث الطلبات =====
  Future<void> refreshOrders() async {
    await fetchOrders();
  }

  // ===== جلب الحارات =====
  Future<void> fetchNeighborhoods() async {
    try {
      final response = await _api.get('neighborhoods');
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          neighborhoods.assignAll(data.map((e) => e.toString()).toList());
        } else if (data is Map && data['data'] != null) {
          neighborhoods.assignAll(
            (data['data'] as List).map((e) => e.toString()).toList(),
          );
        }
      }
    } catch (e) {
      debugPrint('خطأ في جلب الحارات: $e');
    }
  }

  // ===== تحميل المزيد =====
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    currentPage.value++;

    try {
      final response = await _api.get(
        'orders',
        queryParams: {'page': currentPage.value, 'limit': pageSize},
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> ordersJson;

        if (data is Map && data['data'] != null) {
          ordersJson = data['data'] as List<dynamic>;
        } else if (data is List) {
          ordersJson = data;
        } else {
          ordersJson = [];
        }

        if (ordersJson.length < pageSize) {
          hasMore.value = false;
        }

        final newOrders = ordersJson
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
        allOrders.addAll(newOrders);
        _applyFilters();
      }
    } catch (e) {
      debugPrint('خطأ في تحميل المزيد: $e');
      currentPage.value--;
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ===== تطبيق الفلاتر =====
  void _applyFilters() {
    List<OrderModel> result = List.from(allOrders);

    // فلتر الحالة
    if (selectedStatus.value != 'all') {
      result = result
          .where((o) => o.orderStatus == selectedStatus.value)
          .toList();
    }

    // فلتر الحي
    if (selectedNeighborhood.value != 'all') {
      result = result
          .where((o) => o.neighborhood == selectedNeighborhood.value)
          .toList();
    }

    // فلتر البحث
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((o) {
        return o.customerName.toLowerCase().contains(query) ||
            o.customerPhone.toLowerCase().contains(query) ||
            o.invoiceNumber.toLowerCase().contains(query);
      }).toList();
    }

    filteredOrders.assignAll(result);
  }

  void applyFilters() {
    _applyFilters();
    isFilterVisible.value = false;
  }

  void resetFilters() {
    selectedStatus.value = 'all';
    selectedNeighborhood.value = 'all';
    searchQuery.value = '';
    searchController.clear();
    _applyFilters();
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    _applyFilters();
  }

  void toggleFilter() {
    isFilterVisible.value = !isFilterVisible.value;
  }

  // ===== حذف طلب =====
  Future<void> deleteOrder(String orderId) async {
    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              try {
                final response = await _api.delete('orders/$orderId');
                if (response != null && response.statusCode == 200) {
                  allOrders.removeWhere((o) => o.id == orderId);
                  _applyFilters();
                  Get.snackbar(
                    'تم الحذف',
                    'تم حذف الطلب بنجاح',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.success,
                    colorText: Colors.white,
                  );
                }
              } catch (e) {
                Get.snackbar(
                  'خطأ',
                  'فشل في حذف الطلب',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.danger,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  // ===== تغيير حالة الطلب =====
  Future<void> changeOrderStatus(String orderId, String newStatus) async {
    try {
      final response = await _api.put(
        'orders/$orderId',
        data: {'orderStatus': newStatus},
      );

      if (response != null && response.statusCode == 200) {
        final index = allOrders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          allOrders[index].orderStatus = newStatus;
          allOrders.refresh();
          _applyFilters();
        }
        Get.back();
        Get.snackbar(
          'تم التحديث',
          'تم تغيير حالة الطلب بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحديث حالة الطلب',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
    }
  }

  // ===== عرض شريط تغيير الحالة =====
  void showStatusBottomSheet(OrderModel order) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'تغيير حالة الطلب',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'العميل: ${order.customerName}',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 20.h),
            ...statusOptions.entries
                .where((e) => e.key != 'all')
                .map((entry) {
              final isActive = order.orderStatus == entry.key;
              final statusColor = AppColors.statusColors[entry.key] ?? AppColors.textMuted;

              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isActive
                        ? null
                        : () => changeOrderStatus(order.id, entry.key),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isActive
                            ? statusColor.withOpacity(0.15)
                            : Get.theme.cardTheme.color,
                        border: Border.all(
                          color: isActive
                              ? statusColor
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isActive
                                    ? statusColor
                                    : AppColors.text,
                              ),
                            ),
                          ),
                          if (isActive)
                            Icon(
                              Icons.check_circle,
                              color: statusColor,
                              size: 20.sp,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'إغلاق',
                  style: TextStyle(fontSize: 15.sp),
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ===== واتساب =====
  Future<void> openWhatsApp(String phone, OrderModel order) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final message = 'مرحباً ${order.customerName}\n'
        'طلبكم رقم: ${order.invoiceNumber}\n'
        'الحالة: ${order.statusText}\n'
        'المبلغ: ${order.totalPrice.toStringAsFixed(2)} ر.س';

    final url = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'خطأ',
        'تعذر فتح واتساب',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ===== تصدير إلى إكسل =====
  Future<void> exportToExcel() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        barrierDismissible: false,
      );

      final workbook = xlsx.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'الطلبات';

      // تنسيق العنوان
      final headerStyle = xlsx.Style(
        fontColorHex: '#FFFFFF',
        fontSize: 12,
        bold: true,
        hAlign: xlsx.HAlignType.center,
        backColorHex: '#0B3D2E',
      );

      final cellStyle = xlsx.Style(
        fontSize: 11,
        hAlign: xlsx.HAlignType.center,
        vAlign: xlsx.VAlignType.center,
        border: xlsx.Border(
          top: xlsx.BorderSide(style: xlsx.BorderStyleType.thin),
          bottom: xlsx.BorderSide(style: xlsx.BorderStyleType.thin),
          left: xlsx.BorderSide(style: xlsx.BorderStyleType.thin),
          right: xlsx.BorderSide(style: xlsx.BorderStyleType.thin),
        ),
      );

      // العناوين
      final headers = [
        'رقم الفاتورة',
        'اسم العميل',
        'الهاتف',
        'الحي',
        'المندوب',
        'الحالة',
        'المبلغ الإجمالي',
        'المتر المربع',
        'طريقة الدفع',
        'تاريخ الطلب',
      ];

      for (var i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
        sheet.getRangeByIndex(1, i + 1).cellStyle = headerStyle;
      }

      // البيانات
      final ordersToExport =
          filteredOrders.isEmpty ? allOrders : filteredOrders;

      for (var i = 0; i < ordersToExport.length; i++) {
        final order = ordersToExport[i];
        final row = i + 2;
        final dateFormat = DateFormat('yyyy/MM/dd hh:mm a');

        sheet.getRangeByIndex(row, 1).setText(order.invoiceNumber);
        sheet.getRangeByIndex(row, 2).setText(order.customerName);
        sheet.getRangeByIndex(row, 3).setText(order.customerPhone);
        sheet.getRangeByIndex(row, 4).setText(order.neighborhood);
        sheet.getRangeByIndex(row, 5).setText(order.delegateName);
        sheet.getRangeByIndex(row, 6).setText(order.statusText);
        sheet.getRangeByIndex(row, 7).setNumber(order.totalPrice);
        sheet.getRangeByIndex(row, 8).setNumber(order.totalMeters);
        sheet.getRangeByIndex(row, 9).setText(order.payment.displayText);
        sheet.getRangeByIndex(row, 10).setText(
              dateFormat.format(
                DateTime.fromMillisecondsSinceEpoch(order.createdAt),
              ),
            );

        for (var col = 1; col <= headers.length; col++) {
          sheet.getRangeByIndex(row, col).cellStyle = cellStyle;
        }
      }

      // ضبط عرض الأعمدة
      for (var col = 1; col <= headers.length; col++) {
        sheet.getRangeByIndex(1, col).columnWidth = 20;
      }

      // حفظ الملف
      final bytes = workbook.saveAsStream();
      workbook.dispose();

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/orders_export.xlsx';
      final file = File(path);
      await file.writeAsBytes(bytes);

      Get.back(); // إغلاق مؤشر التحميل

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'تصدير الطلبات - مغسلة السجاد',
      );
    } catch (e) {
      Get.back();
      debugPrint('خطأ في التصدير: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تصدير البيانات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
    }
  }

  // ===== إحصائيات =====
  int get totalOrdersCount => filteredOrders.length;
  int get pendingCount =>
      filteredOrders.where((o) => o.orderStatus == 'pending').length;
  int get completedCount =>
      filteredOrders.where((o) => o.orderStatus == 'completed').length;
  double get totalRevenue =>
      filteredOrders.fold(0.0, (sum, o) => sum + o.totalPrice);
  double get totalMeters =>
      filteredOrders.fold(0.0, (sum, o) => sum + o.totalMeters);

  // ===== تنسيق التاريخ =====
  String formatOrderDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';

    return DateFormat('dd/MM/yyyy').format(date);
  }

  // ===== تنسيق طريقة الدفع =====
  String getPaymentMethodText(PaymentInfo payment) {
    final methods = <String>[];
    if (payment.cash > 0) methods.add('كاش');
    if (payment.bank > 0) methods.add('تحويل');
    if (payment.card > 0) methods.add('شبكة');
    return methods.isEmpty ? 'غير محدد' : methods.join(' + ');
  }
}

// ============================================================
// شاشة إدارة الطلبات
// ============================================================

class OrdersScreen extends GetView<OrdersController> {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Get.theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            _buildFilterSection(),
            _buildStatsBar(),
            Expanded(child: _buildOrdersList()),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.toNamed('/orders/add'),
          backgroundColor: AppColors.accent,
          icon: Icon(Icons.add, size: 22.sp),
          label: Text(
            'طلب جديد',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ===== شريط التطبيق =====
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'إدارة الطلبات',
        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
      ),
      actions: [
        // زر التصدير
        IconButton(
          onPressed: controller.isLoading.value
              ? null
              : () => controller.exportToExcel(),
          icon: const Icon(Icons.file_download),
          tooltip: 'تصدير إكسل',
        ),
        // زر الفلتر
        IconButton(
          onPressed: controller.toggleFilter,
          icon: Obx(() => Icon(
                controller.isFilterVisible.value
                    ? Icons.filter_list_off
                    : Icons.filter_list,
              )),
          tooltip: 'فلتر',
        ),
      ],
    );
  }

  // ===== قسم الفلاتر =====
  Widget _buildFilterSection() {
    return Obx(() => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: controller.isFilterVisible.value ? null : 0,
          child: controller.isFilterVisible.value
              ? Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  decoration: BoxDecoration(
                    color: Get.theme.cardTheme.color,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // حقل البحث
                      TextField(
                        controller: controller.searchController,
                        onChanged: controller.onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'بحث بالاسم، الهاتف، أو رقم الفاتورة...',
                          hintStyle: TextStyle(fontSize: 13.sp),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 40.w,
                            minHeight: 40.h,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      // صف الفلاتر المنسدلة
                      Row(
                        children: [
                          // فلتر الحالة
                          Expanded(
                            child: _buildFilterDropdown(
                              label: 'الحالة',
                              value: controller.selectedStatus.value,
                              items: OrdersController.statusOptions,
                              onChanged: (val) {
                                if (val != null) {
                                  controller.selectedStatus.value = val;
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 10.w),
                          // فلتر الحي
                          Expanded(
                            child: Obx(() => _buildFilterDropdown(
                                  label: 'الحي',
                                  value:
                                      controller.selectedNeighborhood.value,
                                  items: {
                                    'all': 'جميع الأحياء',
                                    for (var n in controller.neighborhoods)
                                      n: n,
                                  },
                                  onChanged: (val) {
                                    if (val != null) {
                                      controller
                                          .selectedNeighborhood.value = val;
                                    }
                                  },
                                )),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      // أزرار التطبيق والإعادة
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: controller.applyFilters,
                              icon: Icon(Icons.check, size: 18.sp),
                              label: Text(
                                'تطبيق',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: controller.resetFilters,
                              icon: Icon(Icons.refresh, size: 18.sp),
                              label: Text(
                                'إعادة تعيين',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ));
  }

  // ===== قائمة منسدلة للفلتر =====
  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12.sp),
        isDense: true,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
      items: items.entries
          .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  style: TextStyle(fontSize: 12.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  // ===== شريط الإحصائيات =====
  Widget _buildStatsBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Get.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() => Row(
            children: [
              _buildStatItem(
                icon: Icons.receipt_long,
                label: 'الكل',
                value: '${controller.totalOrdersCount}',
                color: AppColors.info,
              ),
              _buildStatItem(
                icon: Icons.schedule,
                label: 'معلّق',
                value: '${controller.pendingCount}',
                color: AppColors.warning,
              ),
              _buildStatItem(
                icon: Icons.check_circle_outline,
                label: 'مكتمل',
                value: '${controller.completedCount}',
                color: AppColors.success,
              ),
              _buildStatItem(
                icon: Icons.attach_money,
                label: 'الإيرادات',
                value: '${controller.totalRevenue.toStringAsFixed(0)}',
                color: AppColors.accent,
              ),
            ],
          )),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(height: 2.h),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ===== قائمة الطلبات =====
  Widget _buildOrdersList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildShimmerList();
      }

      if (controller.filteredOrders.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: controller.refreshOrders,
        color: AppColors.accent,
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification is ScrollEndNotification &&
                scrollNotification.metrics.pixels >=
                    scrollNotification.metrics.maxScrollExtent - 200) {
              controller.loadMore();
            }
            return false;
          },
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 90.h),
            itemCount: controller.filteredOrders.length +
                (controller.hasMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.filteredOrders.length) {
                return _buildLoadingMoreIndicator();
              }
              return _buildOrderCard(controller.filteredOrders[index]);
            },
          ),
        ),
      );
    });
  }

  // ===== بطاقة الطلب =====
  Widget _buildOrderCard(OrderModel order) {
    final statusColor =
        AppColors.statusColors[order.orderStatus] ?? AppColors.textMuted;

    return Dismissible(
      key: ValueKey(order.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          controller.showStatusBottomSheet(order);
          return false;
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24.w),
        decoration: BoxDecoration(
          color: AppColors.info,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz, color: Colors.white, size: 24.sp),
            SizedBox(height: 4.h),
            Text(
              'تغيير الحالة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 24.w),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 24.sp),
            SizedBox(height: 4.h),
            Text(
              'حذف',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          controller.deleteOrder(order.id);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: Get.theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: statusColor.withOpacity(0.2),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Get.toNamed('/orders/details', arguments: order),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الصف الأول: الاسم + الحالة
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.customerName,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(order.orderStatus),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // الصف الثاني: الهاتف + المندوب
                  Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 14.sp, color: AppColors.textMuted),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          order.customerPhone,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (order.delegateName.isNotEmpty) ...[
                        Icon(Icons.person_outline,
                            size: 14.sp, color: AppColors.textMuted),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            order.delegateName,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // الصف الثالث: المبلغ + المتر + الدفع
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildInfoChip(
                          icon: FontAwesomeIcons.moneyBillWave,
                          label: '${order.totalPrice.toStringAsFixed(0)} ر.س',
                          color: AppColors.accent,
                        ),
                        SizedBox(width: 12.w),
                        if (order.totalMeters > 0)
                          _buildInfoChip(
                            icon: FontAwesomeIcons.rulerCombined,
                            label:
                                '${order.totalMeters.toStringAsFixed(1)} م²',
                            color: AppColors.info,
                          ),
                        SizedBox(width: 12.w),
                        _buildInfoChip(
                          icon: FontAwesomeIcons.creditCard,
                          label: controller
                              .getPaymentMethodText(order.payment),
                          color: AppColors.primaryLight,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // الصف الرابع: الوقت + أزرار الإجراءات
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12.sp, color: AppColors.textMuted),
                      SizedBox(width: 4.w),
                      Text(
                        controller.formatOrderDate(order.createdAt),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (order.invoiceNumber.isNotEmpty) ...[
                        SizedBox(width: 8.w),
                        Text(
                          '(${order.invoiceNumber})',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Spacer(),
                      _buildActionButton(
                        icon: FontAwesomeIcons.whatsapp,
                        color: AppColors.whatsapp,
                        onTap: () => controller.openWhatsApp(
                              order.customerPhone,
                              order,
                            ),
                      ),
                      SizedBox(width: 4.w),
                      _buildActionButton(
                        icon: Icons.swap_horiz,
                        color: AppColors.info,
                        onTap: () =>
                            controller.showStatusBottomSheet(order),
                      ),
                      SizedBox(width: 4.w),
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        color: AppColors.accent,
                        onTap: () => Get.toNamed(
                          '/orders/edit',
                          arguments: order,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        color: AppColors.danger,
                        onTap: () => controller.deleteOrder(order.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== شارة الحالة =====
  Widget _buildStatusBadge(String status) {
    final color = AppColors.statusColors[status] ?? AppColors.textMuted;
    final text = OrderModel(
      orderStatus: status,
    ).statusText;
    final emoji = OrderModel(
      orderStatus: status,
    ).statusEmoji;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: 12.sp)),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ===== معلومة صغيرة =====
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11.sp, color: color),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ===== زر إجراء =====
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Icon(icon, size: 14.sp, color: color),
        ),
      ),
    );
  }

  // ===== حالة فارغة =====
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 60.h),
              Icon(
                Icons.inbox_outlined,
                size: 100.sp,
                color: AppColors.textMuted.withOpacity(0.4),
              ),
              SizedBox(height: 20.h),
              Text(
                'لا توجد طلبات',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'لم يتم العثور على طلبات تطابق البحث أو الفلتر المحدد',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              OutlinedButton.icon(
                onPressed: () {
                  controller.resetFilters();
                  controller.refreshOrders();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة تحميل'),
                style: OutlinedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 60.h),
            ],
          ),
        ),
      ),
    );
  }

  // ===== قائمة شيمر للتحميل =====
  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 90.h),
        itemCount: 8,
        itemBuilder: (context, index) => _buildShimmerCard(),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 120.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 80.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            height: 12.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: 180.w,
            height: 12.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            height: 36.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Container(width: 60.w, height: 12.h, color: Colors.white),
              const Spacer(),
              Container(width: 30.w, height: 30.h, color: Colors.white),
              SizedBox(width: 6.w),
              Container(width: 30.w, height: 30.h, color: Colors.white),
              SizedBox(width: 6.w),
              Container(width: 30.w, height: 30.h, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  // ===== مؤشر تحميل المزيد =====
  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: SizedBox(
          width: 24.sp,
          height: 24.sp,
          child: const CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}
