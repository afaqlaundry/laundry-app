import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/order_model.dart';

// ============================================================================
// نماذج البيانات
// ============================================================================

/// نموذج تقرير الأوامر الشهرية
class MonthlyOrdersReport {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int pendingOrders;
  final double totalRevenue;
  final double totalDiscount;
  final double totalMeters;
  final List<double> monthlyRevenue;
  final List<int> monthlyOrders;
  final List<String> monthLabels;

  const MonthlyOrdersReport({
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.pendingOrders = 0,
    this.totalRevenue = 0.0,
    this.totalDiscount = 0.0,
    this.totalMeters = 0.0,
    this.monthlyRevenue = const [],
    this.monthlyOrders = const [],
    this.monthLabels = const [],
  });

  factory MonthlyOrdersReport.fromJson(Map<String, dynamic> json) {
    return MonthlyOrdersReport(
      totalOrders: _parseInt(json['totalOrders']),
      completedOrders: _parseInt(json['completedOrders']),
      cancelledOrders: _parseInt(json['cancelledOrders']),
      pendingOrders: _parseInt(json['pendingOrders']),
      totalRevenue: _parseDouble(json['totalRevenue']),
      totalDiscount: _parseDouble(json['totalDiscount']),
      totalMeters: _parseDouble(json['totalMeters']),
      monthlyRevenue: (json['monthlyRevenue'] as List?)
              ?.map((e) => _parseDouble(e))
              .toList() ??
          [],
      monthlyOrders: (json['monthlyOrders'] as List?)
              ?.map((e) => _parseInt(e))
              .toList() ??
          [],
      monthLabels: (json['monthLabels'] as List?)?.cast<String>() ??
          ['يناير', 'فبراير', 'مارس'],
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

/// نموذج تقرير مالي
class FinancialReport {
  final double totalCash;
  final double totalBank;
  final double totalCard;
  final double totalDiscount;
  final double netRevenue;
  final double totalExpenses;
  final double netProfit;
  final double totalMetersCleaned;
  final double avgOrderValue;
  final int totalTransactions;

  const FinancialReport({
    this.totalCash = 0.0,
    this.totalBank = 0.0,
    this.totalCard = 0.0,
    this.totalDiscount = 0.0,
    this.netRevenue = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.totalMetersCleaned = 0.0,
    this.avgOrderValue = 0.0,
    this.totalTransactions = 0,
  });

  factory FinancialReport.fromJson(Map<String, dynamic> json) {
    return FinancialReport(
      totalCash: _parseDouble(json['totalCash']),
      totalBank: _parseDouble(json['totalBank']),
      totalCard: _parseDouble(json['totalCard']),
      totalDiscount: _parseDouble(json['totalDiscount']),
      netRevenue: _parseDouble(json['netRevenue']),
      totalExpenses: _parseDouble(json['totalExpenses']),
      netProfit: _parseDouble(json['netProfit']),
      totalMetersCleaned: _parseDouble(json['totalMetersCleaned']),
      avgOrderValue: _parseDouble(json['avgOrderValue']),
      totalTransactions: _parseInt(json['totalTransactions']),
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

/// نموذج بيانات مندوب للتقرير
class DelegateReportData {
  final String delegateId;
  final String delegateName;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final double totalCommission;
  final double avgDeliveryTime;

  const DelegateReportData({
    this.delegateId = '',
    this.delegateName = '',
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.totalRevenue = 0.0,
    this.totalCommission = 0.0,
    this.avgDeliveryTime = 0.0,
  });

  factory DelegateReportData.fromJson(Map<String, dynamic> json) {
    return DelegateReportData(
      delegateId: json['delegateId']?.toString() ?? '',
      delegateName: json['delegateName'] ?? '',
      totalOrders: _parseInt(json['totalOrders']),
      completedOrders: _parseInt(json['completedOrders']),
      cancelledOrders: _parseInt(json['cancelledOrders']),
      totalRevenue: _parseDouble(json['totalRevenue']),
      totalCommission: _parseDouble(json['totalCommission']),
      avgDeliveryTime: _parseDouble(json['avgDeliveryTime']),
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

/// نموذج بيانات الحالات (للرسم الدائري)
class StatusCount {
  final String status;
  final String label;
  final int count;
  final Color color;

  const StatusCount({
    required this.status,
    required this.label,
    required this.count,
    required this.color,
  });
}

// ============================================================================
// المتحكم - ReportsController
// ============================================================================

/// متحكم التقارير
class ReportsController extends GetxController {
  static ReportsController get to => Get.find();

  final ApiService _api = ApiService.to;
  final _storage = GetStorage();

  // ===== حالة التحميل =====
  final RxBool isLoading = false.obs;
  final RxBool isExporting = false.obs;
  final RxString errorMessage = ''.obs;

  // ===== التبويب المختار =====
  final RxInt selectedTabIndex = 0.obs;

  // ===== نطاق التاريخ =====
  final Rx<DateTime> startDate = DateTime(DateTime.now().year, DateTime.now().month - 1, 1).obs;
  final Rx<DateTime> endDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).obs;
  final RxString dateRangeLabel = 'الشهر الحالي'.obs;

  // ===== بيانات التقارير =====
  final Rx<MonthlyOrdersReport> monthlyReport = const MonthlyOrdersReport().obs;
  final Rx<FinancialReport> financialReport = const FinancialReport().obs;
  final RxList<DelegateReportData> delegateReport = <DelegateReportData>[].obs;
  final RxList<StatusCount> statusCounts = <StatusCount>[].obs;

  @override
  void onInit() {
    super.onInit();
    _setDefaultDateRange();
    fetchReportData();
  }

  /// تعيين نطاق التاريخ الافتراضي (الشهر الحالي)
  void _setDefaultDateRange() {
    final now = DateTime.now();
    startDate.value = DateTime(now.year, now.month, 1);
    endDate.value = DateTime(now.year, now.month + 1, 0);
    dateRangeLabel.value = _formatMonthYear(now);
  }

  /// تنسيق الشهر والسنة
  String _formatMonthYear(DateTime date) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  /// اختيار نطاق تاريخ مخصص
  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate.value, end: endDate.value),
      locale: const Locale('ar', 'SA'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      startDate.value = picked.start;
      endDate.value = picked.end;

      final diff = picked.end.difference(picked.start).inDays;
      if (diff <= 31) {
        dateRangeLabel.value =
            '${picked.start.day}/${picked.start.month} - ${picked.end.day}/${picked.end.month}';
      } else {
        dateRangeLabel.value =
            '${_formatMonthYear(picked.start)} - ${_formatMonthYear(picked.end)}';
      }

      await fetchReportData();
    }
  }

  /// اختيار شهر محدد
  Future<void> pickMonth() async {
    final picked = await showMonthPicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      startDate.value = DateTime(picked.year, picked.month, 1);
      endDate.value = DateTime(picked.year, picked.month + 1, 0);
      dateRangeLabel.value = _formatMonthYear(picked);
      await fetchReportData();
    }
  }

  /// جلب بيانات التقرير حسب التبويب المختار
  Future<void> fetchReportData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final params = {
        'startDate': startDate.value.millisecondsSinceEpoch.toString(),
        'endDate': endDate.value.millisecondsSinceEpoch.toString(),
      };

      switch (selectedTabIndex.value) {
        case 0:
          await _fetchMonthlyReport(params);
          break;
        case 1:
          await _fetchFinancialReport(params);
          break;
        case 2:
          await _fetchDelegateReport(params);
          break;
      }
    } catch (e) {
      debugPrint('Reports fetch error: $e');
      errorMessage.value = 'حدث خطأ أثناء تحميل التقرير';
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب تقرير الطلبات الشهرية
  Future<void> _fetchMonthlyReport(Map<String, String> params) async {
    final response = await _api.get('reports/monthly-orders', queryParams: params);

    if (response != null && response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final reportData = data['data'] ?? data;
        if (reportData is Map<String, dynamic>) {
          monthlyReport.value = MonthlyOrdersReport.fromJson(reportData);
        }
      }
      _buildStatusCounts();
    } else {
      // بيانات تجريبية للتطوير
      _loadDemoMonthlyData();
    }
  }

  /// جلب التقرير المالي
  Future<void> _fetchFinancialReport(Map<String, String> params) async {
    final response = await _api.get('reports/financial', queryParams: params);

    if (response != null && response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final reportData = data['data'] ?? data;
        if (reportData is Map<String, dynamic>) {
          financialReport.value = FinancialReport.fromJson(reportData);
        }
      }
    } else {
      _loadDemoFinancialData();
    }
  }

  /// جلب تقرير المناديب
  Future<void> _fetchDelegateReport(Map<String, String> params) async {
    final response = await _api.get('reports/delegates', queryParams: params);

    if (response != null && response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final list = data['data'] ?? data['delegates'] ?? [];
        if (list is List) {
          delegateReport.value = list
              .map((e) => DelegateReportData.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } else {
      _loadDemoDelegateData();
    }
  }

  /// بناء بيانات الحالات للرسم الدائري
  void _buildStatusCounts() {
    statusCounts.value = [
      StatusCount(status: 'completed', label: 'مكتمل', count: monthlyReport.value.completedOrders, color: AppColors.statusCompleted),
      StatusCount(status: 'pending', label: 'قيد الانتظار', count: monthlyReport.value.pendingOrders, color: AppColors.statusPending),
      StatusCount(status: 'picked', label: 'تم الاستلام', count: 0, color: AppColors.statusPicked),
      StatusCount(status: 'cancelled', label: 'ملغي', count: monthlyReport.value.cancelledOrders, color: AppColors.statusCancelled),
      StatusCount(status: 'ready_for_delivery', label: 'جاهز للتسليم', count: 0, color: AppColors.statusReadyDelivery),
    ];
  }

  // ===== بيانات تجريبية =====
  void _loadDemoMonthlyData() {
    monthlyReport.value = MonthlyOrdersReport(
      totalOrders: 156,
      completedOrders: 128,
      cancelledOrders: 12,
      pendingOrders: 16,
      totalRevenue: 24580.0,
      totalDiscount: 1230.0,
      totalMeters: 892.5,
      monthlyRevenue: [3200, 4100, 3800, 4500, 5200, 3770],
      monthlyOrders: [18, 24, 22, 28, 34, 30],
      monthLabels: ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو'],
    );
    _buildStatusCounts();
  }

  void _loadDemoFinancialData() {
    financialReport.value = FinancialReport(
      totalCash: 14500.0,
      totalBank: 6800.0,
      totalCard: 3280.0,
      totalDiscount: 1230.0,
      netRevenue: 23350.0,
      totalExpenses: 8500.0,
      netProfit: 14850.0,
      totalMetersCleaned: 892.5,
      avgOrderValue: 157.6,
      totalTransactions: 156,
    );
  }

  void _loadDemoDelegateData() {
    delegateReport.value = [
      DelegateReportData(
        delegateId: '1',
        delegateName: 'أحمد محمد',
        totalOrders: 45,
        completedOrders: 38,
        cancelledOrders: 3,
        totalRevenue: 7200.0,
        totalCommission: 720.0,
        avgDeliveryTime: 2.5,
      ),
      DelegateReportData(
        delegateId: '2',
        delegateName: 'خالد عبدالله',
        totalOrders: 38,
        completedOrders: 32,
        cancelledOrders: 2,
        totalRevenue: 6100.0,
        totalCommission: 610.0,
        avgDeliveryTime: 3.1,
      ),
      DelegateReportData(
        delegateId: '3',
        delegateName: 'سعد العمري',
        totalOrders: 35,
        completedOrders: 30,
        cancelledOrders: 4,
        totalRevenue: 5600.0,
        totalCommission: 560.0,
        avgDeliveryTime: 2.8,
      ),
      DelegateReportData(
        delegateId: '4',
        delegateName: 'عمر الحربي',
        totalOrders: 28,
        completedOrders: 24,
        cancelledOrders: 2,
        totalRevenue: 4400.0,
        totalCommission: 440.0,
        avgDeliveryTime: 3.5,
      ),
      DelegateReportData(
        delegateId: '5',
        delegateName: 'فهد القحطاني',
        totalOrders: 10,
        completedOrders: 4,
        cancelledOrders: 1,
        totalRevenue: 1280.0,
        totalCommission: 128.0,
        avgDeliveryTime: 4.0,
      ),
    ];
  }

  /// تغيير التبويب
  void changeTab(int index) {
    if (selectedTabIndex.value != index) {
      selectedTabIndex.value = index;
      fetchReportData();
    }
  }

  /// تصدير التقرير إلى PDF
  Future<void> exportToPdf() async {
    isExporting.value = true;
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            // عنوان التقرير
            pw.Header(
              level: 0,
              child: pw.Text(
                _getReportTitle(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'الفترة: ${dateRangeLabel.value}',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 16),

            // محتوى حسب نوع التقرير
            ..._buildPdfContent(),

            // تذييل
            pw.SizedBox(height: 32),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'تم إنشاء هذا التقرير تلقائياً - إدارة المغسلة',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
              ),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'تقرير_${_getReportTitle()}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // مشاركة الملف
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf')],
        subject: _getReportTitle(),
      );

      Get.snackbar(
        'تم التصدير',
        'تم تصدير التقرير بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      debugPrint('PDF export error: $e');
      Get.snackbar(
        'خطأ في التصدير',
        'فشل في تصدير التقرير، حاول مرة أخرى',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isExporting.value = false;
    }
  }

  String _getReportTitle() {
    switch (selectedTabIndex.value) {
      case 0: return 'تقرير الطلبات الشهرية';
      case 1: return 'التقرير المالي';
      case 2: return 'تقرير المناديب';
      default: return 'تقرير';
    }
  }

  List<pw.Widget> _buildPdfContent() {
    switch (selectedTabIndex.value) {
      case 0:
        final r = monthlyReport.value;
        return [
          _pdfRow('إجمالي الطلبات', '${r.totalOrders}'),
          _pdfRow('الطلبات المكتملة', '${r.completedOrders}'),
          _pdfRow('الطلبات الملغية', '${r.cancelledOrders}'),
          _pdfRow('الطلبات المعلقة', '${r.pendingOrders}'),
          _pdfRow('إجمالي الإيرادات', '${r.totalRevenue.toStringAsFixed(2)} ر.س'),
          _pdfRow('إجمالي الخصومات', '${r.totalDiscount.toStringAsFixed(2)} ر.س'),
          _pdfRow('إجمالي الأمتار', '${r.totalMeters.toStringAsFixed(1)} م\u00B2'),
        ];
      case 1:
        final r = financialReport.value;
        return [
          _pdfRow('المدفوعات نقداً', '${r.totalCash.toStringAsFixed(2)} ر.س'),
          _pdfRow('التحويلات البنكية', '${r.totalBank.toStringAsFixed(2)} ر.س'),
          _pdfRow('الدفع بالشبكة', '${r.totalCard.toStringAsFixed(2)} ر.س'),
          _pdfRow('إجمالي الخصومات', '${r.totalDiscount.toStringAsFixed(2)} ر.س'),
          _pdfRow('صافي الإيرادات', '${r.netRevenue.toStringAsFixed(2)} ر.س'),
          _pdfRow('إجمالي المصروفات', '${r.totalExpenses.toStringAsFixed(2)} ر.س'),
          _pdfRow('صافي الربح', '${r.netProfit.toStringAsFixed(2)} ر.س'),
          _pdfRow('متوسط قيمة الطلب', '${r.avgOrderValue.toStringAsFixed(2)} ر.س'),
          _pdfRow('عدد المعاملات', '${r.totalTransactions}'),
          _pdfRow('الأمتار المنظفة', '${r.totalMetersCleaned.toStringAsFixed(1)} م\u00B2'),
        ];
      case 2:
        return [
          for (final d in delegateReport.value) ...[
            pw.Text(
              d.delegateName,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            _pdfRow('إجمالي الطلبات', '${d.totalOrders}'),
            _pdfRow('المكتملة', '${d.completedOrders}'),
            _pdfRow('الملغاة', '${d.cancelledOrders}'),
            _pdfRow('الإيرادات', '${d.totalRevenue.toStringAsFixed(2)} ر.س'),
            _pdfRow('العمولة', '${d.totalCommission.toStringAsFixed(2)} ر.س'),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 12),
          ],
        ];
      default:
        return [pw.Text('لا توجد بيانات')];
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 13)),
          pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  /// مشاركة التقرير
  Future<void> shareReport() async {
    await exportToPdf();
  }

  // ===== Getters =====
  bool get hasData {
    switch (selectedTabIndex.value) {
      case 0: return monthlyReport.value.totalOrders > 0;
      case 1: return financialReport.value.totalTransactions > 0;
      case 2: return delegateReport.value.isNotEmpty;
      default: return false;
    }
  }

  int get totalOrdersCount => monthlyReport.value.totalOrders;
  double get totalRevenueAmount => monthlyReport.value.totalRevenue;
}

// ============================================================================
// اختيار الشهر
// ============================================================================

/// منتقي الشهر
class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _MonthPickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(
        'اختر الشهر',
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // اختيار السنة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  if (_selectedYear > widget.firstDate.year) {
                    setState(() => _selectedYear--);
                  }
                },
                icon: const Icon(Icons.chevron_right),
              ),
              Text(
                '$_selectedYear',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                onPressed: () {
                  if (_selectedYear < widget.lastDate.year) {
                    setState(() => _selectedYear++);
                  }
                },
                icon: const Icon(Icons.chevron_left),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // شبكة الأشهر
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 8.h,
            crossAxisSpacing: 8.w,
            childAspectRatio: 2.2,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(12, (index) {
              final month = index + 1;
              final months = [
                'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
                'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
              ];
              final isSelected = month == _selectedMonth;
              final isDisabled = DateTime(_selectedYear, month).isAfter(widget.lastDate) ||
                  DateTime(_selectedYear, month).isBefore(widget.firstDate);

              return Material(
                color: isSelected
                    ? AppColors.primary
                    : isDisabled
                        ? AppColors.border
                        : Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.r),
                  onTap: isDisabled
                      ? null
                      : () {
                          setState(() => _selectedMonth = month);
                          Navigator.pop(context, DateTime(_selectedYear, _selectedMonth));
                        },
                  child: Center(
                    child: Text(
                      months[index],
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : isDisabled ? AppColors.textMuted : AppColors.text,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// دالة مساعدة لعرض منتقي الشهر
Future<DateTime?> showMonthPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => _MonthPickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

// ============================================================================
// الشاشة الرئيسية - ReportsScreen
// ============================================================================

/// شاشة التقارير
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: _buildExportButton(),
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
          child: Column(
            children: [
              // الصف الأول: عنوان ونزول
              Row(
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
                      'التقارير والإحصائيات',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // زر تصدير
                  Obx(() {
                    final controller = Get.find<ReportsController>();
                    return GestureDetector(
                      onTap: controller.isExporting.value ? null : controller.shareReport,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (controller.isExporting.value)
                              SizedBox(
                                width: 14.r,
                                height: 14.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              Icon(FontAwesomeIcons.fileExport, size: 12.sp, color: Colors.white),
                            SizedBox(width: 6.w),
                            Text(
                              'تصدير',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              SizedBox(height: AppSpacing.sm.h),

              // الصف الثاني: اختيار نطاق التاريخ
              _buildDateRangeSelector(),
              SizedBox(height: AppSpacing.sm.h),
            ],
          ),
        ),
      ),
    );
  }

  /// منتقي نطاق التاريخ
  Widget _buildDateRangeSelector() {
    return Obx(() {
      final controller = Get.find<ReportsController>();
      return Row(
        children: [
          // زر الشهر
          Expanded(
            child: GestureDetector(
              onTap: controller.pickMonth,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.calendar, size: 12.sp, color: AppColors.accentLight),
                    SizedBox(width: 6.w),
                    Text(
                      controller.dateRangeLabel.value,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // زر نطاق مخصص
          GestureDetector(
            onTap: controller.pickDateRange,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FontAwesomeIcons.calendarDays, size: 12.sp, color: AppColors.accentLight),
                  SizedBox(width: 4.w),
                  Text(
                    'مخصص',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  // ===== الجسم =====
  Widget _buildBody() {
    return Column(
      children: [
        // تبويبات نوع التقرير
        _buildReportTabs(),
        // محتوى التبويب
        Expanded(child: _buildTabContent()),
      ],
    );
  }

  /// تبويبات نوع التقرير
  Widget _buildReportTabs() {
    const tabs = [
      _TabItem(icon: FontAwesomeIcons.clipboardList, label: 'الطلبات الشهرية'),
      _TabItem(icon: FontAwesomeIcons.coins, label: 'التقرير المالي'),
      _TabItem(icon: FontAwesomeIcons.truck, label: 'تقرير المناديب'),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: AppSpacing.sm.h),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final controller = Get.find<ReportsController>();
        return Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final isActive = controller.selectedTabIndex.value == index;

            return Expanded(
              child: GestureDetector(
                onTap: () => controller.changeTab(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 14.sp,
                        color: isActive ? Colors.white : AppColors.textMuted,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 9.sp,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                          color: isActive ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  /// محتوى التبويب
  Widget _buildTabContent() {
    return Obx(() {
      final controller = Get.find<ReportsController>();

      if (controller.isLoading.value) {
        return _buildLoadingState();
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return _buildErrorState(controller);
      }

      switch (controller.selectedTabIndex.value) {
        case 0:
          return _buildMonthlyOrdersTab(controller);
        case 1:
          return _buildFinancialTab(controller);
        case 2:
          return _buildDelegateTab(controller);
        default:
          return const SizedBox();
      }
    });
  }

  // ===== تبويب الطلبات الشهرية =====
  Widget _buildMonthlyOrdersTab(ReportsController controller) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: controller.fetchReportData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.sm.h),
            // بطاقات الإحصائيات
            _buildMonthlySummaryCards(controller),
            SizedBox(height: AppSpacing.lg.h),
            // رسم الإيرادات الشهرية
            _buildRevenueLineChart(controller),
            SizedBox(height: AppSpacing.lg.h),
            // رسم الطلبات حسب الحالة
            _buildOrdersPieChart(controller),
            SizedBox(height: AppSpacing.xl.h),
          ],
        ),
      ),
    );
  }

  /// بطاقات ملخص الطلبات الشهرية
  Widget _buildMonthlySummaryCards(ReportsController controller) {
    final r = controller.monthlyReport.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ملخص الشهر',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'إجمالي الطلبات',
                value: '${r.totalOrders}',
                icon: FontAwesomeIcons.clipboardList,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: _MetricCard(
                title: 'المكتملة',
                value: '${r.completedOrders}',
                icon: FontAwesomeIcons.circleCheck,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm.h),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'الإيرادات',
                value: '${r.totalRevenue.toStringAsFixed(0)} ر.س',
                icon: FontAwesomeIcons.coins,
                color: AppColors.accent,
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: _MetricCard(
                title: 'الأمتار م\u00B2',
                value: r.totalMeters.toStringAsFixed(1),
                icon: FontAwesomeIcons.rulerCombined,
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// رسم الإيرادات الشهرية (خطي)
  Widget _buildRevenueLineChart(ReportsController controller) {
    final data = controller.monthlyReport.value;
    final maxVal = data.monthlyRevenue.isEmpty
        ? 1.0
        : data.monthlyRevenue.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1.0 : maxVal;

    return Container(
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
                'الإيرادات الشهرية',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${data.totalRevenue.toStringAsFixed(0)} ر.س',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          SizedBox(
            height: 200.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMax / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50.w,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}K',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 9.sp,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.monthLabels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            data.monthLabels[index],
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
                      data.monthlyRevenue.length,
                      (i) => FlSpot(i.toDouble(), data.monthlyRevenue[i]),
                    ),
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: AppColors.accent,
                    barWidth: 3.w,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4.r,
                          color: Colors.white,
                          strokeWidth: 2.5.w,
                          strokeColor: AppColors.accent,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.25),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// رسم الطلبات حسب الحالة (دائري)
  Widget _buildOrdersPieChart(ReportsController controller) {
    final statuses = controller.statusCounts;
    final total = statuses.fold(0, (sum, s) => sum + s.count);
    if (total == 0) return const SizedBox();

    return Container(
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
          Text(
            'الطلبات حسب الحالة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          Row(
            children: [
              SizedBox(
                width: 160.w,
                height: 160.h,
                child: PieChart(
                  PieChartData(
                    sections: statuses
                        .where((s) => s.count > 0)
                        .map((s) => PieChartSectionData(
                              value: s.count.toDouble(),
                              title: '${((s.count / total) * 100).toStringAsFixed(0)}%',
                              titleStyle: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              color: s.color,
                              radius: 50.r,
                              borderSide: const BorderSide(color: Colors.white, width: 2),
                            ))
                        .toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 30.r,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: statuses
                      .where((s) => s.count > 0)
                      .map((s) => Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 10.r,
                                  height: 10.r,
                                  decoration: BoxDecoration(
                                    color: s.color,
                                    borderRadius: BorderRadius.circular(3.r),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    s.label,
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 11.sp,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${s.count}',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== تبويب التقرير المالي =====
  Widget _buildFinancialTab(ReportsController controller) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: controller.fetchReportData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.sm.h),
            // بطاقات ملخص مالية
            _buildFinancialSummaryCards(controller),
            SizedBox(height: AppSpacing.lg.h),
            // رسم الإيرادات حسب طريقة الدفع
            _buildPaymentMethodChart(controller),
            SizedBox(height: AppSpacing.lg.h),
            // تفاصيل مالية
            _buildFinancialDetails(controller),
            SizedBox(height: AppSpacing.xl.h),
          ],
        ),
      ),
    );
  }

  /// بطاقات ملخص مالية
  Widget _buildFinancialSummaryCards(ReportsController controller) {
    final r = controller.financialReport.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الملخص المالي',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        // صافي الربح - بطاقة بارزة
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.md.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryMid],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(FontAwesomeIcons.sackDollar, size: 16.sp, color: AppColors.accentLight),
                  SizedBox(width: 8.w),
                  Text(
                    'صافي الربح',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14.sp,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                '${r.netProfit.toStringAsFixed(2)} ر.س',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'صافي الإيرادات',
                value: '${r.netRevenue.toStringAsFixed(0)}',
                icon: FontAwesomeIcons.arrowTrendUp,
                color: AppColors.success,
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: _MetricCard(
                title: 'المصروفات',
                value: '${r.totalExpenses.toStringAsFixed(0)}',
                icon: FontAwesomeIcons.arrowTrendDown,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm.h),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'متوسط الطلب',
                value: '${r.avgOrderValue.toStringAsFixed(0)} ر.س',
                icon: FontAwesomeIcons.receipt,
                color: AppColors.info,
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: _MetricCard(
                title: 'المعاملات',
                value: '${r.totalTransactions}',
                icon: FontAwesomeIcons.hashtag,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// رسم الدفع حسب الطريقة (دائري مجوف)
  Widget _buildPaymentMethodChart(ReportsController controller) {
    final r = controller.financialReport.value;

    return Container(
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
          Text(
            'الإيرادات حسب طريقة الدفع',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          Row(
            children: [
              SizedBox(
                width: 160.w,
                height: 160.h,
                child: PieChart(
                  PieChartData(
                    sections: [
                      if (r.totalCash > 0)
                        PieChartSectionData(
                          value: r.totalCash,
                          title: '${((r.totalCash / (r.totalCash + r.totalBank + r.totalCard)) * 100).toStringAsFixed(0)}%',
                          titleStyle: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          color: AppColors.success,
                          radius: 50.r,
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                      if (r.totalBank > 0)
                        PieChartSectionData(
                          value: r.totalBank,
                          title: '${((r.totalBank / (r.totalCash + r.totalBank + r.totalCard)) * 100).toStringAsFixed(0)}%',
                          titleStyle: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          color: AppColors.info,
                          radius: 50.r,
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                      if (r.totalCard > 0)
                        PieChartSectionData(
                          value: r.totalCard,
                          title: '${((r.totalCard / (r.totalCash + r.totalBank + r.totalCard)) * 100).toStringAsFixed(0)}%',
                          titleStyle: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          color: AppColors.accent,
                          radius: 50.r,
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 40.r,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PaymentLegendItem(
                      color: AppColors.success,
                      label: 'نقدي',
                      value: '${r.totalCash.toStringAsFixed(0)} ر.س',
                    ),
                    SizedBox(height: 10.h),
                    _PaymentLegendItem(
                      color: AppColors.info,
                      label: 'تحويل بنكي',
                      value: '${r.totalBank.toStringAsFixed(0)} ر.س',
                    ),
                    SizedBox(height: 10.h),
                    _PaymentLegendItem(
                      color: AppColors.accent,
                      label: 'شبكة',
                      value: '${r.totalCard.toStringAsFixed(0)} ر.س',
                    ),
                    const SizedBox(height: 12),
                    Divider(color: AppColors.border),
                    const SizedBox(height: 8),
                    _PaymentLegendItem(
                      color: AppColors.danger,
                      label: 'الخصومات',
                      value: '${r.totalDiscount.toStringAsFixed(0)} ر.س',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// تفاصيل مالية إضافية
  Widget _buildFinancialDetails(ReportsController controller) {
    final r = controller.financialReport.value;

    return Container(
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
          Text(
            'تفاصيل إضافية',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          _DetailRow(
            label: 'إجمالي الأمتار المنظفة',
            value: '${r.totalMetersCleaned.toStringAsFixed(1)} م\u00B2',
          ),
          _DetailRow(
            label: 'عدد المعاملات',
            value: '${r.totalTransactions}',
          ),
          _DetailRow(
            label: 'متوسط قيمة الطلب',
            value: '${r.avgOrderValue.toStringAsFixed(2)} ر.س',
          ),
          _DetailRow(
            label: 'إجمالي الإيرادات',
            value: '${r.netRevenue.toStringAsFixed(2)} ر.س',
            valueColor: AppColors.success,
          ),
          _DetailRow(
            label: 'إجمالي المصروفات',
            value: '${r.totalExpenses.toStringAsFixed(2)} ر.س',
            valueColor: AppColors.danger,
          ),
          const Divider(color: AppColors.border),
          _DetailRow(
            label: 'صافي الربح',
            value: '${r.netProfit.toStringAsFixed(2)} ر.س',
            valueColor: AppColors.primary,
            isBold: true,
          ),
        ],
      ),
    );
  }

  // ===== تبويب تقرير المناديب =====
  Widget _buildDelegateTab(ReportsController controller) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: controller.fetchReportData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.sm.h),
            // ملخص المناديب
            Text(
              'أداء المناديب',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: AppSpacing.sm.h),
            // رسم أعمدة المناديب
            _buildDelegateBarChart(controller),
            SizedBox(height: AppSpacing.lg.h),
            // قائمة المناديب
            ...controller.delegateReport.map(
              (delegate) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                child: _DelegatePerformanceCard(delegate: delegate),
              ),
            ),
            SizedBox(height: AppSpacing.xl.h),
          ],
        ),
      ),
    );
  }

  /// رسم أعمدة المناديب
  Widget _buildDelegateBarChart(ReportsController controller) {
    final delegates = controller.delegateReport;
    if (delegates.isEmpty) return const SizedBox();

    final maxOrders = delegates.map((d) => d.totalOrders).reduce((a, b) => a > b ? a : b);
    final safeMax = maxOrders == 0 ? 1 : maxOrders;

    return Container(
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
          Text(
            'عدد الطلبات لكل مندوب',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          SizedBox(
            height: 200.h,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36.w,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 9.sp,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= delegates.length) {
                          return const SizedBox();
                        }
                        final name = delegates[index].delegateName;
                        final parts = name.split(' ');
                        return Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            parts.length > 1 ? '${parts[0]} ${parts[1][0]}.' : parts[0],
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 9.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40.h,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  delegates.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: delegates[index].totalOrders.toDouble(),
                        color: index.isEven ? AppColors.primary : AppColors.accent,
                        width: 20.w,
                        borderRadius: BorderRadius.circular(6.r),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: safeMax.toDouble(),
                          color: AppColors.border.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    ],
                  ),
                ),
                maxY: safeMax.toDouble() * 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== حالة التحميل =====
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            strokeWidth: 3,
          ),
          SizedBox(height: AppSpacing.md.h),
          Text(
            'جاري تحميل التقرير...',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14.sp,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ===== حالة الخطأ =====
  Widget _buildErrorState(ReportsController controller) {
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
                fontSize: 16.sp,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            ElevatedButton.icon(
              onPressed: controller.fetchReportData,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'إعادة المحاولة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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

  /// زر التصدير العائم
  Widget _buildExportButton() {
    return Obx(() {
      final controller = Get.find<ReportsController>();
      if (controller.isExporting.value) {
        return FloatingActionButton(
          onPressed: null,
          backgroundColor: AppColors.accent.withValues(alpha: 0.5),
          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        );
      }
      return FloatingActionButton(
        onPressed: controller.shareReport,
        backgroundColor: AppColors.accent,
        child: Icon(FontAwesomeIcons.filePdf, size: 20.sp, color: Colors.white),
      );
    });
  }
}

// ============================================================================
// مكونات مساعدة
// ============================================================================

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

/// بطاقة مقياس
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
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
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 12.sp, color: color),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 10.sp,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// عنصر وسيلة الدفع
class _PaymentLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _PaymentLegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10.r,
          height: 10.r,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12.sp,
              color: AppColors.text,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

/// صف تفصيلي
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13.sp,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w700,
              color: valueColor ?? AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة أداء المندوب
class _DelegatePerformanceCard extends StatelessWidget {
  final DelegateReportData delegate;

  const _DelegatePerformanceCard({required this.delegate});

  @override
  Widget build(BuildContext context) {
    final completionRate = delegate.totalOrders > 0
        ? ((delegate.completedOrders / delegate.totalOrders) * 100).toStringAsFixed(0)
        : '0';

    return Container(
      padding: EdgeInsets.all(AppSpacing.md.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // الرأس
          Row(
            children: [
              // أيقونة
              CircleAvatar(
                radius: 22.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  delegate.delegateName.isNotEmpty ? delegate.delegateName[0] : '?',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm.w),
              // الاسم والعمولة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delegate.delegateName,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'العمولة: ${delegate.totalCommission.toStringAsFixed(0)} ر.س',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11.sp,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // نسبة الإنجاز
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: int.parse(completionRate) >= 80
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$completionRate%',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: int.parse(completionRate) >= 80 ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm.h),
          // الإحصائيات
          Row(
            children: [
              Expanded(
                child: _DelegateStatItem(
                  label: 'الطلبات',
                  value: '${delegate.totalOrders}',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _DelegateStatItem(
                  label: 'المكتملة',
                  value: '${delegate.completedOrders}',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _DelegateStatItem(
                  label: 'الملغاة',
                  value: '${delegate.cancelledOrders}',
                  color: AppColors.danger,
                ),
              ),
              Expanded(
                child: _DelegateStatItem(
                  label: 'الإيرادات',
                  value: '${delegate.totalRevenue.toStringAsFixed(0)}',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// عنصر إحصائي مندوب
class _DelegateStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DelegateStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 10.sp,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
