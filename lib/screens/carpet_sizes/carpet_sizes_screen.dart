import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../theme/app_theme.dart';
import '../../models/carpet_size_model.dart';
import '../../services/api_service.dart';

// ============================================================
// وحدة تحكم مقاسات السجاد
// ============================================================

class CarpetSizesController extends GetxController {
  final ApiService _api = ApiService.to;

  // ===== حالة البيانات =====
  final RxList<CarpetSizeModel> sizes = <CarpetSizeModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;

  // ===== حقول النموذج =====
  final TextEditingController descController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  // ===== عنصر قيد التعديل =====
  final Rx<CarpetSizeModel?> editingSize = Rx<CarpetSizeModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchSizes();
  }

  @override
  void onClose() {
    descController.dispose();
    widthController.dispose();
    lengthController.dispose();
    priceController.dispose();
    super.onClose();
  }

  // ===== جلب المقاسات =====
  Future<void> fetchSizes() async {
    isLoading.value = true;
    try {
      final response = await _api.get('carpet-sizes');
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> list;
        if (data is Map && data['data'] != null) {
          list = data['data'] as List<dynamic>;
        } else if (data is List) {
          list = data;
        } else {
          list = [];
        }
        sizes.assignAll(
          list.map((e) => CarpetSizeModel.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }
    } catch (e) {
      debugPrint('خطأ في جلب المقاسات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ===== إضافة / تعديل مقاس =====
  Future<void> saveSize() async {
    final desc = descController.text.trim();
    final width = double.tryParse(widthController.text.trim());
    final length = double.tryParse(lengthController.text.trim());
    final price = double.tryParse(priceController.text.trim());

    if (desc.isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال الوصف',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
      return;
    }
    if (width == null || width <= 0) {
      Get.snackbar('خطأ', 'يرجى إدخال العرض بشكل صحيح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
      return;
    }
    if (length == null || length <= 0) {
      Get.snackbar('خطأ', 'يرجى إدخال الطول بشكل صحيح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
      return;
    }
    if (price == null || price <= 0) {
      Get.snackbar('خطأ', 'يرجى إدخال سعر المتر بشكل صحيح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
      return;
    }

    isSubmitting.value = true;
    try {
      final body = {
        'description': desc,
        'width': width,
        'length': length,
        'pricePerMeter': price,
      };

      Response? response;
      if (editingSize.value != null) {
        response = await _api.put('carpet-sizes/${editingSize.value!.id}', data: body);
      } else {
        response = await _api.post('carpet-sizes', data: body);
      }

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        clearForm();
        await fetchSizes();
        Get.snackbar(
          'تم',
          editingSize.value != null ? 'تم تعديل المقاس بنجاح' : 'تمت إضافة المقاس بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حفظ المقاس',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===== تعديل مقاس =====
  void editSize(CarpetSizeModel size) {
    editingSize.value = size;
    descController.text = size.description;
    widthController.text = size.width.toStringAsFixed(2);
    lengthController.text = size.length.toStringAsFixed(2);
    priceController.text = size.pricePerMeter.toStringAsFixed(2);
  }

  // ===== إلغاء التعديل =====
  void cancelEdit() {
    editingSize.value = null;
    clearForm();
  }

  // ===== حذف مقاس =====
  Future<void> deleteSize(String id) async {
    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المقاس؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              Get.back();
              try {
                final response = await _api.delete('carpet-sizes/$id');
                if (response != null && response.statusCode == 200) {
                  sizes.removeWhere((s) => s.id == id);
                  if (editingSize.value?.id == id) {
                    cancelEdit();
                  }
                  Get.snackbar('تم الحذف', 'تم حذف المقاس بنجاح',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.success, colorText: Colors.white);
                }
              } catch (e) {
                Get.snackbar('خطأ', 'فشل في حذف المقاس',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.danger, colorText: Colors.white);
              }
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  // ===== تنظيف النموذج =====
  void clearForm() {
    descController.clear();
    widthController.clear();
    lengthController.clear();
    priceController.clear();
    editingSize.value = null;
  }

  // ===== إحصائيات =====
  int get totalSizes => sizes.length;
}

// ============================================================
// شاشة إدارة مقاسات السجاد
// ============================================================

class CarpetSizesScreen extends GetView<CarpetSizesController> {
  const CarpetSizesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Get.theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('مقاسات السجاد',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              onPressed: controller.fetchSizes,
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
          }
          return RefreshIndicator(
            onRefresh: controller.fetchSizes,
            color: AppColors.accent,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
              children: [
                _buildFormCard(),
                SizedBox(height: 20.h),
                _buildSizesHeader(),
                SizedBox(height: 12.h),
                _buildSizesList(),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ===== بطاقة النموذج =====
  Widget _buildFormCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_box_outlined, size: 20.sp, color: AppColors.accent),
              SizedBox(width: 8.w),
              Obx(() => Text(
                    controller.editingSize.value != null ? 'تعديل المقاس' : 'إضافة مقاس جديد',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent),
                  )),
              const Spacer(),
              Obx(() {
                if (controller.editingSize.value == null) return const SizedBox.shrink();
                return TextButton.icon(
                  onPressed: controller.cancelEdit,
                  icon: Icon(Icons.close, size: 16.sp),
                  label: Text('إلغاء', style: TextStyle(fontSize: 12.sp)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                );
              }),
            ],
          ),
          SizedBox(height: 14.h),
          _buildTextField(controller.descController, 'الوصف (مثال: سجاد صغير)', Icons.description),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                    controller.widthController, 'العرض (متر)', Icons.straighten,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildTextField(
                    controller.lengthController, 'الطول (متر)', Icons.height,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildTextField(
              controller.priceController, 'سعر المتر (ر.س)', Icons.monetization_on,
              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          SizedBox(height: 16.h),
          Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.isSubmitting.value ? null : controller.saveSize,
                  icon: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(controller.editingSize.value != null ? 'حفظ التعديلات' : 'إضافة المقاس'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    backgroundColor: controller.editingSize.value != null
                        ? AppColors.accent
                        : AppColors.primary,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ===== عنوان القائمة =====
  Widget _buildSizesHeader() {
    return Obx(() => Row(
          children: [
            Icon(Icons.grid_view_outlined, size: 20.sp, color: AppColors.accent),
            SizedBox(width: 8.w),
            Text('المقاسات المحددة',
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent)),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${controller.totalSizes}',
                style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent),
              ),
            ),
          ],
        ));
  }

  // ===== قائمة المقاسات =====
  Widget _buildSizesList() {
    return Obx(() {
      if (controller.sizes.isEmpty) {
        return _buildEmptyState();
      }
      return Column(
        children: controller.sizes.map((size) => _buildSizeCard(size)).toList(),
      );
    });
  }

  // ===== بطاقة المقاس =====
  Widget _buildSizeCard(CarpetSizeModel size) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Get.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => controller.editSize(size),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الصف الأول: الوصف + أزرار الإجراءات
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.layers_outlined, size: 16.sp, color: AppColors.primary),
                          SizedBox(width: 6.w),
                          Text(
                            size.description,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // زر التعديل
                    _buildIconButton(Icons.edit_outlined, AppColors.accent, () => controller.editSize(size)),
                    SizedBox(width: 6.w),
                    // زر الحذف
                    _buildIconButton(Icons.delete_outline, AppColors.danger, () => controller.deleteSize(size.id)),
                  ],
                ),
                SizedBox(height: 12.h),

                // تفاصيل المقاس
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.bg.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildDetailChip(
                        icon: Icons.square_foot,
                        label: 'المقاس',
                        value: size.sizeText,
                        color: AppColors.info,
                      ),
                      SizedBox(width: 12.w),
                      _buildDetailChip(
                        icon: Icons.monetization_on,
                        label: 'سعر المتر',
                        value: size.priceText,
                        color: AppColors.accent,
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'الإجمالي',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '${size.totalPrice.toStringAsFixed(2)} ر.س',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.sp, color: color),
        SizedBox(width: 4.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10.sp, color: AppColors.textMuted)),
            Text(value,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 18.sp, color: color),
      ),
    );
  }

  // ===== حالة فارغة =====
  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Column(
        children: [
          Icon(Icons.layers_clear, size: 60.sp, color: AppColors.textMuted.withOpacity(0.4)),
          SizedBox(height: 16.h),
          Text(
            'لا توجد مقاسات محددة',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'أضف مقاسات السجاد المتاحة من النموذج أعلاه',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textMuted.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ===== حقل نصي =====
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      ),
    );
  }
}
