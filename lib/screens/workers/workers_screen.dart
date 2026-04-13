import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../models/worker_model.dart';
import '../../services/api_service.dart';

// ============================================================
// وحدة تحكم العمال
// ============================================================

class WorkersController extends GetxController {
  final ApiService _api = ApiService.to;

  // ===== حالة البيانات =====
  final RxList<WorkerModel> workers = <WorkerModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;

  // ===== حقول نموذج العامل =====
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final RxString statusValue = 'active'.obs;

  // ===== حقول دفع الراتب =====
  final TextEditingController payAmountController = TextEditingController();
  final TextEditingController payMonthController = TextEditingController();
  final TextEditingController payYearController = TextEditingController();
  final TextEditingController payDateController = TextEditingController();
  final TextEditingController payNotesController = TextEditingController();

  // ===== العامل المحدد لدفع الراتب =====
  final Rx<WorkerModel?> selectedWorker = Rx<WorkerModel?>(null);

  // ===== حالة عرض السجل =====
  final RxString expandedWorkerId = ''.obs;

  // ===== خيارات الحالة =====
  static const Map<String, String> statusOptions = {
    'active': 'نشط',
    'vacation': 'في إجازة',
    'inactive': 'غير نشط',
  };

  // ===== ألوان الحالة =====
  static const Map<String, Color> statusColors = {
    'active': AppColors.success,
    'vacation': AppColors.warning,
    'inactive': AppColors.danger,
  };

  @override
  void onInit() {
    super.onInit();
    _setDefaultPayDate();
    fetchWorkers();
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    salaryController.dispose();
    payAmountController.dispose();
    payMonthController.dispose();
    payYearController.dispose();
    payDateController.dispose();
    payNotesController.dispose();
    super.onClose();
  }

  void _setDefaultPayDate() {
    final now = DateTime.now();
    payDateController.text = DateFormat('yyyy-MM-dd').format(now);
    payMonthController.text = DateFormat('MM').format(now);
    payYearController.text = DateFormat('yyyy').format(now);
  }

  // ===== جلب العمال =====
  Future<void> fetchWorkers() async {
    isLoading.value = true;
    try {
      final response = await _api.get('workers');
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
        workers.assignAll(
          list.map((e) => WorkerModel.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }
    } catch (e) {
      debugPrint('خطأ في جلب العمال: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ===== إضافة عامل =====
  Future<void> addWorker() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال اسم العامل',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
      return;
    }

    isSubmitting.value = true;
    try {
      final response = await _api.post('workers', data: {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'salary': double.tryParse(salaryController.text.trim()) ?? 0,
        'status': statusValue.value,
      });

      if (response != null && response.statusCode == 200 || response?.statusCode == 201) {
        _clearWorkerForm();
        await fetchWorkers();
        Get.snackbar('تم', 'تمت إضافة العامل بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إضافة العامل',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===== حذف عامل =====
  Future<void> deleteWorker(String id) async {
    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العامل؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              Get.back();
              try {
                final response = await _api.delete('workers/$id');
                if (response != null && response.statusCode == 200) {
                  workers.removeWhere((w) => w.id == id);
                  Get.snackbar('تم الحذف', 'تم حذف العامل بنجاح',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.success, colorText: Colors.white);
                }
              } catch (e) {
                Get.snackbar('خطأ', 'فشل في حذف العامل',
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

  // ===== عرض نافذة دفع الراتب =====
  void showPaySalaryDialog(WorkerModel worker) {
    selectedWorker.value = worker;
    payAmountController.text = worker.salary.toStringAsFixed(0);
    _setDefaultPayDate();
    payNotesController.clear();

    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.account_balance_wallet, color: AppColors.accent, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'دفع راتب: ${worker.name}',
                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: payAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'المبلغ (ر.س)',
                    prefixIcon: const Icon(Icons.money),
                    isDense: true,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: payMonthController.text,
                        decoration: const InputDecoration(
                          labelText: 'الشهر',
                          isDense: true,
                        ),
                        items: List.generate(12, (i) {
                          final m = (i + 1).toString().padLeft(2, '0');
                          return DropdownMenuItem(value: m, child: Text(m));
                        }),
                        onChanged: (v) {
                          if (v != null) payMonthController.text = v;
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: payYearController.text,
                        decoration: const InputDecoration(
                          labelText: 'السنة',
                          isDense: true,
                        ),
                        items: List.generate(5, (i) {
                          final y = (DateTime.now().year - 2 + i).toString();
                          return DropdownMenuItem(value: y, child: Text(y));
                        }),
                        onChanged: (v) {
                          if (v != null) payYearController.text = v;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                TextField(
                  controller: payDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'تاريخ الدفع',
                    prefixIcon: const Icon(Icons.calendar_today),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.edit_calendar),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: Get.context!,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          payDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: payNotesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    prefixIcon: Icon(Icons.note),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
            ),
            ElevatedButton.icon(
              onPressed: isSubmitting.value ? null : () => paySalary(worker.id),
              icon: isSubmitting.value
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.payment),
              label: const Text('تأكيد الدفع', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== دفع الراتب =====
  Future<void> paySalary(String workerId) async {
    final amount = double.tryParse(payAmountController.text.trim());
    if (amount == null || amount <= 0) {
      Get.snackbar('خطأ', 'يرجى إدخال مبلغ صحيح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
      return;
    }

    isSubmitting.value = true;
    try {
      final response = await _api.post('workers/$workerId/pay-salary', data: {
        'amount': amount,
        'month': payMonthController.text,
        'year': payYearController.text,
        'date': payDateController.text,
        'notes': payNotesController.text.trim(),
      });

      if (response != null && response.statusCode == 200 || response?.statusCode == 201) {
        Get.back(); // إغلاق النافذة
        await fetchWorkers();
        Get.snackbar('تم', 'تم دفع الراتب بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في دفع الراتب',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===== تبديل عرض سجل الرواتب =====
  void toggleSalaryHistory(String workerId) {
    if (expandedWorkerId.value == workerId) {
      expandedWorkerId.value = '';
    } else {
      expandedWorkerId.value = workerId;
    }
  }

  // ===== تنظيف النموذج =====
  void _clearWorkerForm() {
    nameController.clear();
    phoneController.clear();
    salaryController.clear();
    statusValue.value = 'active';
  }

  // ===== إحصائيات =====
  int get totalWorkers => workers.length;
  int get activeWorkers => workers.where((w) => w.status == 'active').length;
  int get vacationWorkers => workers.where((w) => w.status == 'vacation').length;
  int get inactiveWorkers => workers.where((w) => w.status == 'inactive').length;
  double get totalSalaries => workers.fold(0.0, (sum, w) => sum + w.salary);
}

// ============================================================
// شاشة إدارة العمال
// ============================================================

class WorkersScreen extends GetView<WorkersController> {
  const WorkersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Get.theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('إدارة العمال',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              onPressed: controller.fetchWorkers,
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
            onRefresh: controller.fetchWorkers,
            color: AppColors.accent,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
              children: [
                _buildStatsGrid(),
                SizedBox(height: 20.h),
                _buildAddWorkerForm(),
                SizedBox(height: 20.h),
                _buildWorkersHeader(),
                SizedBox(height: 12.h),
                _buildWorkersList(),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ===== شبكة الإحصائيات =====
  Widget _buildStatsGrid() {
    return Obx(() {
      return Container(
        padding: EdgeInsets.all(14.w),
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
          children: [
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.group,
                  label: 'إجمالي العمال',
                  value: '${controller.totalWorkers}',
                  color: AppColors.info,
                ),
                SizedBox(width: 10.w),
                _buildStatCard(
                  icon: Icons.check_circle,
                  label: 'نشط',
                  value: '${controller.activeWorkers}',
                  color: AppColors.success,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.beach_access,
                  label: 'في إجازة',
                  value: '${controller.vacationWorkers}',
                  color: AppColors.warning,
                ),
                SizedBox(width: 10.w),
                _buildStatCard(
                  icon: Icons.cancel,
                  label: 'غير نشط',
                  value: '${controller.inactiveWorkers}',
                  color: AppColors.danger,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            _buildStatCard(
              icon: Icons.account_balance_wallet,
              label: 'إجمالي الرواتب',
              value: '${controller.totalSalaries.toStringAsFixed(0)} ر.س',
              color: AppColors.accent,
              expanded: true,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool expanded = false,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: color),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(fontSize: 10.sp, color: AppColors.textMuted)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== نموذج إضافة عامل =====
  Widget _buildAddWorkerForm() {
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
              Icon(Icons.person_add_alt_1, size: 20.sp, color: AppColors.accent),
              SizedBox(width: 8.w),
              Text('إضافة عامل جديد',
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent)),
            ],
          ),
          SizedBox(height: 14.h),
          _buildTextField(controller.nameController, 'اسم العامل', Icons.person),
          SizedBox(height: 10.h),
          _buildTextField(controller.phoneController, 'رقم الهاتف', Icons.phone, keyboardType: TextInputType.phone),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                    controller.salaryController, 'الراتب الشهري (ر.س)', Icons.money,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                flex: 1,
                child: Obx(() => DropdownButtonFormField<String>(
                  value: controller.statusValue.value,
                  decoration: InputDecoration(
                    labelText: 'الحالة',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  ),
                  items: WorkersController.statusOptions.entries
                      .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, style: TextStyle(fontSize: 13.sp))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.statusValue.value = v;
                  },
                )),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.isSubmitting.value ? null : controller.addWorker,
                  icon: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.person_add),
                  label: const Text('إضافة العامل'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ===== عنوان القائمة =====
  Widget _buildWorkersHeader() {
    return Obx(() => Row(
          children: [
            Icon(Icons.people_outline, size: 20.sp, color: AppColors.accent),
            SizedBox(width: 8.w),
            Text('قائمة العمال',
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
                '${controller.totalWorkers}',
                style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent),
              ),
            ),
          ],
        ));
  }

  // ===== قائمة العمال =====
  Widget _buildWorkersList() {
    return Obx(() {
      if (controller.workers.isEmpty) {
        return _buildEmptyState();
      }
      return Column(
        children: controller.workers.map((worker) => _buildWorkerCard(worker)).toList(),
      );
    });
  }

  // ===== بطاقة العامل =====
  Widget _buildWorkerCard(WorkerModel worker) {
    final statusColor = WorkersController.statusColors[worker.status] ?? AppColors.textMuted;
    final isExpanded = controller.expandedWorkerId.value == worker.id;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Get.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // المحتوى الرئيسي
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              children: [
                // الصف الأول: الاسم + شارة الحالة + أزرار
                Row(
                  children: [
                    // صورة رمزية
                    CircleAvatar(
                      radius: 22.w,
                      backgroundColor: statusColor.withOpacity(0.15),
                      child: Text(
                        worker.name.isNotEmpty ? worker.name[0] : '?',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // الاسم والهاتف
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker.name,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (worker.phone.isNotEmpty)
                            Text(
                              worker.phone,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // شارة الحالة
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        worker.statusText,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    // زر الحذف
                    InkWell(
                      onTap: () => controller.deleteWorker(worker.id),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.delete_outline, size: 16.sp, color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // الصف الثاني: الراتب + أزرار الإجراءات
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.bg.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.monetization_on, size: 18.sp, color: AppColors.accent),
                      SizedBox(width: 6.w),
                      Text(
                        'الراتب: ',
                        style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
                      ),
                      Text(
                        '${worker.salary.toStringAsFixed(0)} ر.س',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                      const Spacer(),
                      // زر عرض السجل
                      _buildActionButton(
                        icon: Icons.history,
                        label: 'السجل',
                        color: AppColors.info,
                        onTap: () => controller.toggleSalaryHistory(worker.id),
                      ),
                      SizedBox(width: 8.w),
                      // زر دفع الراتب
                      _buildActionButton(
                        icon: Icons.payment,
                        label: 'دفع راتب',
                        color: AppColors.success,
                        onTap: () => controller.showPaySalaryDialog(worker),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // سجل الرواتب (قابل للتوسيع)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: isExpanded ? _buildSalaryHistory(worker) : null,
          ),
        ],
      ),
    );
  }

  // ===== سجل الرواتب =====
  Widget _buildSalaryHistory(WorkerModel worker) {
    final payments = worker.salaryPayments ?? [];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: 10.h),
          Text(
            'سجل المدفوعات',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
          SizedBox(height: 8.h),
          if (payments.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Center(
                child: Text(
                  'لا توجد مدفوعات سابقة',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...payments.map((payment) => _buildPaymentItem(payment)),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(SalaryPayment payment) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, size: 16.sp, color: AppColors.success),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${payment.amount.toStringAsFixed(0)} ر.س',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${payment.month}/${payment.year}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (payment.date.isNotEmpty)
                  Text(
                    payment.date,
                    style: TextStyle(fontSize: 10.sp, color: AppColors.textMuted),
                  ),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  Text(
                    payment.notes!,
                    style: TextStyle(fontSize: 11.sp, color: AppColors.primaryLight),
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

  // ===== زر إجراء =====
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15.sp, color: color),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ===== حالة فارغة =====
  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 60.sp, color: AppColors.textMuted.withOpacity(0.4)),
          SizedBox(height: 16.h),
          Text(
            'لا يوجد عمال مسجلين',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'أضف عمال جدد من النموذج أعلاه',
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
