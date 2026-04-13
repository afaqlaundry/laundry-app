import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../models/expense_model.dart';
import '../../services/api_service.dart';

// ============================================================
// وحدة تحكم المصروفات
// ============================================================

class ExpensesController extends GetxController {
  final ApiService _api = ApiService.to;

  // ===== حالة البيانات =====
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final RxList<CashReceiptModel> cashReceipts = <CashReceiptModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;

  // ===== حقول نموذج المصروف =====
  final TextEditingController expTypeController = TextEditingController();
  final TextEditingController expAmountController = TextEditingController();
  final TextEditingController expDescController = TextEditingController();
  final TextEditingController expDateController = TextEditingController();
  final RxString expPayMethod = 'cash'.obs;

  // ===== حقول نموذج مصروف المدير =====
  final TextEditingController mgrTypeController = TextEditingController();
  final TextEditingController mgrAmountController = TextEditingController();
  final TextEditingController mgrDescController = TextEditingController();
  final TextEditingController mgrDateController = TextEditingController();
  final RxString mgrDeductFrom = 'cash'.obs;

  // ===== حقول استلام الكاش =====
  final TextEditingController rcptDescController = TextEditingController();
  final TextEditingController rcptAmountController = TextEditingController();
  final TextEditingController rcptDateController = TextEditingController();

  // ===== حقول التقرير الشهري =====
  final RxString selectedMonth = DateFormat('MM').format(DateTime.now()).obs;
  final RxString selectedYear = DateFormat('yyyy').format(DateTime.now()).obs;
  final RxString monthlyReport = ''.obs;
  final RxBool isGeneratingReport = false.obs;

  // ===== خيارات طريقة الدفع =====
  static const Map<String, String> payMethodOptions = {
    'cash': 'كاش',
    'network': 'شبكة',
    'transfer': 'تحويل',
  };

  // ===== خيارات الخصم =====
  static const Map<String, String> deductFromOptions = {
    'cash': 'الكاش',
    'network': 'الشبكة',
    'transfer': 'التحويل',
    'report': 'تقرير فقط',
  };

  @override
  void onInit() {
    super.onInit();
    _setDefaultDates();
    fetchExpenses();
    fetchCashReceipts();
  }

  @override
  void onClose() {
    expTypeController.dispose();
    expAmountController.dispose();
    expDescController.dispose();
    expDateController.dispose();
    mgrTypeController.dispose();
    mgrAmountController.dispose();
    mgrDescController.dispose();
    mgrDateController.dispose();
    rcptDescController.dispose();
    rcptAmountController.dispose();
    rcptDateController.dispose();
    super.onClose();
  }

  void _setDefaultDates() {
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    expDateController.text = now;
    mgrDateController.text = now;
    rcptDateController.text = now;
  }

  // ===== جلب المصروفات =====
  Future<void> fetchExpenses() async {
    isLoading.value = true;
    try {
      final response = await _api.get('expenses');
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
        expenses.assignAll(
          list.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }
    } catch (e) {
      debugPrint('خطأ في جلب المصروفات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ===== جلب إيصالات الكاش =====
  Future<void> fetchCashReceipts() async {
    try {
      final response = await _api.get('cash-receipts');
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
        cashReceipts.assignAll(
          list.map((e) => CashReceiptModel.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }
    } catch (e) {
      debugPrint('خطأ في جلب إيصالات الكاش: $e');
    }
  }

  // ===== إضافة مصروف عادي =====
  Future<void> addExpense() async {
    if (expTypeController.text.trim().isEmpty ||
        expAmountController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى تعبئة النوع والمبلغ',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
      return;
    }

    isSubmitting.value = true;
    try {
      final response = await _api.post('expenses', data: {
        'type': expTypeController.text.trim(),
        'amount': double.tryParse(expAmountController.text.trim()) ?? 0,
        'payMethod': expPayMethod.value,
        'description': expDescController.text.trim(),
        'date': expDateController.text.trim(),
        'isManagerExpense': false,
        'isReportOnly': false,
      });

      if (response != null && response.statusCode == 200 || response?.statusCode == 201) {
        _clearExpenseForm();
        await fetchExpenses();
        Get.snackbar('تم', 'تمت إضافة المصروف بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إضافة المصروف',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===== إضافة مصروف مدير =====
  Future<void> addManagerExpense() async {
    if (mgrTypeController.text.trim().isEmpty ||
        mgrAmountController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى تعبئة النوع والمبلغ',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
      return;
    }

    isSubmitting.value = true;
    final isReport = mgrDeductFrom.value == 'report';
    try {
      final response = await _api.post('expenses', data: {
        'type': mgrTypeController.text.trim(),
        'amount': double.tryParse(mgrAmountController.text.trim()) ?? 0,
        'payMethod': 'cash',
        'description': mgrDescController.text.trim(),
        'date': mgrDateController.text.trim(),
        'isManagerExpense': true,
        'deductFrom': isReport ? null : mgrDeductFrom.value,
        'isReportOnly': isReport,
      });

      if (response != null && response.statusCode == 200 || response?.statusCode == 201) {
        _clearManagerForm();
        await fetchExpenses();
        Get.snackbar('تم', 'تمت إضافة مصروف المدير بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إضافة مصروف المدير',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===== إضافة استلام كاش =====
  Future<void> addCashReceipt() async {
    if (rcptDescController.text.trim().isEmpty ||
        rcptAmountController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى تعبئة البيانات',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
      return;
    }

    isSubmitting.value = true;
    try {
      final response = await _api.post('cash-receipts', data: {
        'description': rcptDescController.text.trim(),
        'amount': double.tryParse(rcptAmountController.text.trim()) ?? 0,
        'date': rcptDateController.text.trim(),
      });

      if (response != null && response.statusCode == 200 || response?.statusCode == 201) {
        _clearReceiptForm();
        await fetchCashReceipts();
        Get.snackbar('تم', 'تمت إضافة استلام الكاش بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إضافة استلام الكاش',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===== حذف مصروف =====
  Future<void> deleteExpense(String id) async {
    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المصروف؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              Get.back();
              try {
                final response = await _api.delete('expenses/$id');
                if (response != null && response.statusCode == 200) {
                  expenses.removeWhere((e) => e.id == id);
                  Get.snackbar('تم الحذف', 'تم حذف المصروف بنجاح',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.success, colorText: Colors.white);
                }
              } catch (e) {
                Get.snackbar('خطأ', 'فشل في حذف المصروف',
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

  // ===== إنشاء تقرير شهري =====
  Future<void> generateMonthlyReport() async {
    isGeneratingReport.value = true;
    try {
      final response = await _api.get('expenses/report', queryParams: {
        'month': selectedMonth.value,
        'year': selectedYear.value,
      });

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['report'] != null) {
          monthlyReport.value = data['report'].toString();
        } else if (data is Map) {
          final sb = StringBuffer();
          sb.writeln('━━━ تقرير الإيرادات الشهرية ━━━');
          sb.writeln('الشهر: ${selectedMonth.value}/${selectedYear.value}');
          sb.writeln('');

          final revCash = (data['revenueCash'] as num?)?.toDouble() ?? 0;
          final revBank = (data['revenueBank'] as num?)?.toDouble() ?? 0;
          final revCard = (data['revenueCard'] as num?)?.toDouble() ?? 0;
          final totalRev = revCash + revBank + revCard;

          sb.writeln('💰 إجمالي الإيرادات: $totalRev ر.س');
          sb.writeln('   كاش: $revCash ر.س');
          sb.writeln('   بنك: $revBank ر.س');
          sb.writeln('   شبكة: $revCard ر.س');
          sb.writeln('');

          final expCash = (data['expensesCash'] as num?)?.toDouble() ?? 0;
          final expBank = (data['expensesBank'] as num?)?.toDouble() ?? 0;
          final expCard = (data['expensesCard'] as num?)?.toDouble() ?? 0;
          final totalExp = expCash + expBank + expCard;

          sb.writeln('📊 إجمالي المصروفات: $totalExp ر.س');
          sb.writeln('   كاش: $expCash ر.س');
          sb.writeln('   بنك: $expBank ر.س');
          sb.writeln('   شبكة: $expCard ر.س');
          sb.writeln('');
          sb.writeln('✅ صافي الربح: ${totalRev - totalExp} ر.س');

          monthlyReport.value = sb.toString();
        } else {
          monthlyReport.value = 'لا تتوفر بيانات لهذا الشهر';
        }
      }
    } catch (e) {
      monthlyReport.value = 'حدث خطأ أثناء إنشاء التقرير';
    } finally {
      isGeneratingReport.value = false;
    }
  }

  // ===== تنظيف النماذج =====
  void _clearExpenseForm() {
    expTypeController.clear();
    expAmountController.clear();
    expDescController.clear();
    expPayMethod.value = 'cash';
    _setDefaultDates();
  }

  void _clearManagerForm() {
    mgrTypeController.clear();
    mgrAmountController.clear();
    mgrDescController.clear();
    mgrDeductFrom.value = 'cash';
    _setDefaultDates();
  }

  void _clearReceiptForm() {
    rcptDescController.clear();
    rcptAmountController.clear();
    _setDefaultDates();
  }

  // ===== إحصائيات =====
  double get totalCash {
    return expenses
        .where((e) => !e.isReportOnly && (e.payMethod == 'cash' || e.deductFrom == 'cash'))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalBank {
    return expenses
        .where((e) => !e.isReportOnly && (e.payMethod == 'transfer' || e.deductFrom == 'transfer'))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalCard {
    return expenses
        .where((e) => !e.isReportOnly && (e.payMethod == 'network' || e.deductFrom == 'network'))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalRevenue {
    return cashReceipts.fold(0.0, (sum, r) => sum + r.amount);
  }

  double get deductedExpenses {
    return expenses
        .where((e) => !e.isReportOnly && !e.isManagerExpense)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get remainingCash {
    return totalRevenue - deductedExpenses;
  }

  double get reportOnlyExpenses {
    return expenses
        .where((e) => e.isReportOnly)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalExpenses {
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  double get netProfit {
    return totalRevenue - expenses.where((e) => !e.isReportOnly).fold(0.0, (sum, e) => sum + e.amount);
  }
}

// ============================================================
// شاشة إدارة المصروفات
// ============================================================

class ExpensesScreen extends GetView<ExpensesController> {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Get.theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('إدارة المصروفات',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              onPressed: () async {
                await controller.fetchExpenses();
                await controller.fetchCashReceipts();
              },
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
            onRefresh: () async {
              await controller.fetchExpenses();
              await controller.fetchCashReceipts();
            },
            color: AppColors.accent,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
              children: [
                _buildStatsGrid(),
                SizedBox(height: 20.h),
                _buildMonthlyReportSection(),
                SizedBox(height: 20.h),
                _buildAddExpenseSection(),
                SizedBox(height: 20.h),
                _buildManagerExpenseSection(),
                SizedBox(height: 20.h),
                _buildCashReceiptSection(),
                SizedBox(height: 20.h),
                _buildExpensesTable(),
                SizedBox(height: 20.h),
                _buildBottomStats(),
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
      final cards = [
        _StatCard(
          title: 'إجمالي الكاش',
          value: '${controller.totalCash.toStringAsFixed(2)} ر.س',
          icon: Icons.money,
          color: AppColors.success,
        ),
        _StatCard(
          title: 'إجمالي البنك',
          value: '${controller.totalBank.toStringAsFixed(2)} ر.س',
          icon: Icons.account_balance,
          color: AppColors.info,
        ),
        _StatCard(
          title: 'إجمالي الشبكة',
          value: '${controller.totalCard.toStringAsFixed(2)} ر.س',
          icon: Icons.credit_card,
          color: AppColors.warning,
        ),
        _StatCard(
          title: 'إجمالي الإيرادات',
          value: '${controller.totalRevenue.toStringAsFixed(2)} ر.س',
          icon: Icons.trending_up,
          color: AppColors.accent,
        ),
        _StatCard(
          title: 'المصروفات المخصومة',
          value: '${controller.deductedExpenses.toStringAsFixed(2)} ر.س',
          icon: Icons.remove_circle_outline,
          color: AppColors.danger,
        ),
        _StatCard(
          title: 'الكاش المتبقي',
          value: '${controller.remainingCash.toStringAsFixed(2)} ر.س',
          icon: Icons.wallet,
          color: AppColors.primaryLight,
        ),
        _StatCard(
          title: 'مصروفات تقرير فقط',
          value: '${controller.reportOnlyExpenses.toStringAsFixed(2)} ر.س',
          icon: Icons.description_outlined,
          color: AppColors.textMuted,
        ),
      ];

      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
        childAspectRatio: 1.6,
        children: cards,
      );
    });
  }

  // ===== قسم التقرير الشهري =====
  Widget _buildMonthlyReportSection() {
    return _buildSectionCard(
      title: 'التقرير الشهري للإيرادات',
      icon: Icons.calendar_month,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedMonth.value,
                  decoration: InputDecoration(
                    labelText: 'الشهر',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  ),
                  items: List.generate(12, (i) {
                    final m = (i + 1).toString().padLeft(2, '0');
                    return DropdownMenuItem(value: m, child: Text('$m'));
                  }),
                  onChanged: (v) {
                    if (v != null) controller.selectedMonth.value = v;
                  },
                )),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedYear.value,
                  decoration: InputDecoration(
                    labelText: 'السنة',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  ),
                  items: List.generate(5, (i) {
                    final y = (DateTime.now().year - 2 + i).toString();
                    return DropdownMenuItem(value: y, child: Text(y));
                  }),
                  onChanged: (v) {
                    if (v != null) controller.selectedYear.value = v;
                  },
                )),
              ),
              SizedBox(width: 8.w),
              Obx(() => ElevatedButton(
                onPressed: controller.isGeneratingReport.value
                    ? null
                    : controller.generateMonthlyReport,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                ),
                child: controller.isGeneratingReport.value
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.assessment, size: 20.sp),
              )),
            ],
          ),
          SizedBox(height: 12.h),
          Obx(() {
            if (controller.monthlyReport.value.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Text('اضغط على زر التقرير لعرض النتائج',
                      style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted)),
                ),
              );
            }
            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: SelectableText(
                controller.monthlyReport.value,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontFamily: 'Tajawal',
                  color: Get.theme.colorScheme.onSurface,
                  height: 1.8,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===== قسم إضافة مصروف =====
  Widget _buildAddExpenseSection() {
    return _buildSectionCard(
      title: 'إضافة مصروف',
      icon: Icons.add_circle_outline,
      child: Column(
        children: [
          _buildTextField(controller.expTypeController, 'نوع المصروف', Icons.category),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(controller.expAmountController, 'المبلغ', Icons.money, keyboardType: TextInputType.number),
              ),
              SizedBox(width: 10.w),
              Expanded(
                flex: 2,
                child: Obx(() => DropdownButtonFormField<String>(
                  value: controller.expPayMethod.value,
                  decoration: InputDecoration(
                    labelText: 'طريقة الدفع',
                    isDense: true,
                    prefixIcon: const Icon(Icons.payment, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  ),
                  items: ExpensesController.payMethodOptions.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: TextStyle(fontSize: 13.sp))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.expPayMethod.value = v;
                  },
                )),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _buildTextField(controller.expDescController, 'الوصف', Icons.description),
          SizedBox(height: 10.h),
          _buildDateField(controller.expDateController, 'التاريخ'),
          SizedBox(height: 14.h),
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isSubmitting.value ? null : controller.addExpense,
              icon: controller.isSubmitting.value
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add),
              label: const Text('إضافة المصروف'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ===== قسم مصروف المدير =====
  Widget _buildManagerExpenseSection() {
    return _buildSectionCard(
      title: 'مصروف المدير',
      icon: Icons.admin_panel_settings,
      child: Column(
        children: [
          _buildTextField(controller.mgrTypeController, 'نوع المصروف', Icons.category),
          SizedBox(height: 10.h),
          _buildTextField(controller.mgrAmountController, 'المبلغ', Icons.money, keyboardType: TextInputType.number),
          SizedBox(height: 10.h),
          _buildTextField(controller.mgrDescController, 'الوصف', Icons.description),
          SizedBox(height: 10.h),
          Obx(() => DropdownButtonFormField<String>(
            value: controller.mgrDeductFrom.value,
            decoration: InputDecoration(
              labelText: 'الخصم من',
              isDense: true,
              prefixIcon: const Icon(Icons.account_balance_wallet, size: 20),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            ),
            items: ExpensesController.deductFromOptions.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: TextStyle(fontSize: 13.sp))))
                .toList(),
            onChanged: (v) {
              if (v != null) controller.mgrDeductFrom.value = v;
            },
          )),
          SizedBox(height: 10.h),
          _buildDateField(controller.mgrDateController, 'التاريخ'),
          SizedBox(height: 14.h),
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isSubmitting.value ? null : controller.addManagerExpense,
              icon: controller.isSubmitting.value
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.person_add),
              label: const Text('إضافة مصروف المدير'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                backgroundColor: AppColors.accent,
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ===== قسم استلام الكاش =====
  Widget _buildCashReceiptSection() {
    return _buildSectionCard(
      title: 'استلام كاش',
      icon: Icons.receipt,
      child: Column(
        children: [
          _buildTextField(controller.rcptDescController, 'الوصف', Icons.description),
          SizedBox(height: 10.h),
          _buildTextField(controller.rcptAmountController, 'المبلغ', Icons.money, keyboardType: TextInputType.number),
          SizedBox(height: 10.h),
          _buildDateField(controller.rcptDateController, 'التاريخ'),
          SizedBox(height: 14.h),
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isSubmitting.value ? null : controller.addCashReceipt,
              icon: controller.isSubmitting.value
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.receipt_long),
              label: const Text('تسجيل الاستلام'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                backgroundColor: AppColors.primaryLight,
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ===== جدول المصروفات =====
  Widget _buildExpensesTable() {
    return _buildSectionCard(
      title: 'سجل المصروفات',
      icon: Icons.list_alt,
      child: Obx(() {
        if (controller.expenses.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: Center(
              child: Text('لا توجد مصروفات بعد',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.textMuted)),
            ),
          );
        }
        return Column(
          children: [
            // رأس الجدول
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _tableHeader('التاريخ', 2),
                  _tableHeader('النوع', 2),
                  _tableHeader('الوصف', 3),
                  _tableHeader('المبلغ', 1.5),
                  _tableHeader('الدفع', 1.5),
                  _tableHeader('مدير', 1),
                  _tableHeader('خصم من', 1.5),
                  const SizedBox(width: 36.w),
                ],
              ),
            ),
            SizedBox(height: 6.h),
            // صفوف الجدول
            ...controller.expenses.map((expense) => _buildExpenseRow(expense)),
          ],
        );
      }),
    );
  }

  Widget _tableHeader(String text, double flex) {
    return Expanded(
      flex: flex.toInt(),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.accent,
        ),
      ),
    );
  }

  Widget _buildExpenseRow(ExpenseModel expense) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Get.theme.cardTheme.color?.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(expense.date, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.sp))),
          Expanded(flex: 2, child: Text(expense.type, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600))),
          Expanded(
            flex: 3,
            child: Text(
              expense.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.sp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(flex: 1, child: Text('${expense.amount.toStringAsFixed(0)}', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.danger))),
          Expanded(flex: 1, child: Text(expense.payMethodText, textAlign: TextAlign.center, style: TextStyle(fontSize: 10.sp))),
          Expanded(flex: 1, child: Text(expense.isManagerExpense ? 'نعم' : 'لا', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.sp, color: expense.isManagerExpense ? AppColors.accent : AppColors.textMuted))),
          Expanded(flex: 1, child: Text(expense.deductFromText, textAlign: TextAlign.center, style: TextStyle(fontSize: 10.sp))),
          SizedBox(
            width: 32.w,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(maxWidth: 32.w),
              icon: Icon(Icons.delete_outline, size: 16.sp, color: AppColors.danger),
              onPressed: () => controller.deleteExpense(expense.id),
            ),
          ),
        ],
      ),
    );
  }

  // ===== إحصائيات سفلية =====
  Widget _buildBottomStats() {
    return Obx(() {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text('إجمالي المصروفات',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted)),
                  SizedBox(height: 4.h),
                  Text(
                    '${controller.totalExpenses.toStringAsFixed(2)} ر.س',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 40.h, color: AppColors.border),
            Expanded(
              child: Column(
                children: [
                  Text('صافي الربح',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted)),
                  SizedBox(height: 4.h),
                  Text(
                    '${controller.netProfit.toStringAsFixed(2)} ر.س',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: controller.netProfit >= 0 ? AppColors.success : AppColors.danger,
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

  // ===== أدوات مساعدة =====
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
              Icon(icon, size: 20.sp, color: AppColors.accent),
              SizedBox(width: 8.w),
              Text(title,
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent)),
            ],
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }

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

  Widget _buildDateField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today, size: 20),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: Get.context!,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      },
    );
  }
}

// ===== بطاقة إحصائية =====
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Get.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: color),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
