import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';

// ============================================================================
// نماذج البيانات
// ============================================================================

/// نموذج العميل مع إحصائيات
class CustomerWithStats {
  final UserModel customer;
  final int totalOrders;
  final double totalSpent;
  final int? lastOrderDate;
  final String? lastOrderStatus;
  final double totalMeters;
  final double avgOrderValue;

  const CustomerWithStats({
    required this.customer,
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    this.lastOrderDate,
    this.lastOrderStatus,
    this.totalMeters = 0.0,
    this.avgOrderValue = 0.0,
  });

  factory CustomerWithStats.fromJson(Map<String, dynamic> json) {
    return CustomerWithStats(
      customer: UserModel.fromJson(json['customer'] ?? json),
      totalOrders: _parseInt(json['totalOrders']),
      totalSpent: _parseDouble(json['totalSpent']),
      lastOrderDate: _parseInt(json['lastOrderDate']),
      lastOrderStatus: json['lastOrderStatus'],
      totalMeters: _parseDouble(json['totalMeters']),
      avgOrderValue: _parseDouble(json['avgOrderValue']),
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

  /// تنسيق تاريخ آخر طلب
  String get lastOrderDisplay {
    if (lastOrderDate == null || lastOrderDate == 0) return 'لا يوجد';
    final date = DateTime.fromMillisecondsSinceEpoch(lastOrderDate!);
    return '${date.day}/${date.month}/${date.year}';
  }

  /// تنسيق المبلغ المنفق
  String get totalSpentDisplay => '${totalSpent.toStringAsFixed(0)} ر.س';
}

// ============================================================================
// المتحكم - CustomersController
// ============================================================================

/// متحكم العملاء
class CustomersController extends GetxController {
  static CustomersController get to => Get.find();

  final ApiService _api = ApiService.to;
  final _storage = GetStorage();

  // ===== حالة التحميل =====
  final RxBool isLoading = true.obs;
  final RxBool isSearching = false.obs;
  final RxString errorMessage = ''.obs;

  // ===== بيانات العملاء =====
  final RxList<CustomerWithStats> customers = <CustomerWithStats>[].obs;
  final RxList<CustomerWithStats> filteredCustomers = <CustomerWithStats>[].obs;

  // ===== البحث =====
  final searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  // ===== العميل المحدد =====
  final Rx<CustomerWithStats?> selectedCustomer = Rx<CustomerWithStats?>(null);
  final RxList<OrderModel> customerOrders = <OrderModel>[].obs;
  final RxBool isLoadingOrders = false.obs;

  // ===== الفرز =====
  final RxString sortBy = 'name'.obs; // name, orders, spent, recent
  final RxBool sortAscending = true.obs;

  // ===== صفحة الترقيم =====
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasMore = false.obs;
  static const int _pageSize = 20;

  // ===== الإحصائيات =====
  final RxInt totalCustomersCount = 0.obs;
  final RxDouble allTimeRevenue = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// جلب قائمة العملاء
  Future<void> fetchCustomers({bool refresh = false}) async {
    if (refresh) {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final response = await _api.get(
        'customers',
        queryParams: {
          'page': currentPage.value.toString(),
          'limit': _pageSize.toString(),
          'search': searchQuery.value,
          'sortBy': sortBy.value,
          'sortDir': sortAscending.value ? 'asc' : 'desc',
        },
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final list = data['data'] ?? data['customers'] ?? [];
          if (list is List) {
            final parsed = list
                .map((e) => CustomerWithStats.fromJson(e as Map<String, dynamic>))
                .toList();
            if (refresh || currentPage.value == 1) {
              customers.value = parsed;
            } else {
              customers.addAll(parsed);
            }
            filteredCustomers.assignAll(customers);
          }

          // ترقيم الصفحات
          totalPages.value = _parseInt(data['totalPages']) ??
              (customers.length >= _pageSize ? currentPage.value + 1 : currentPage.value);
          totalCustomersCount.value = _parseInt(data['total']) ?? customers.length;
          hasMore.value = customers.length < totalCustomersCount.value;
          allTimeRevenue.value = _parseDouble(data['allTimeRevenue']);
        }
      } else {
        // بيانات تجريبية
        _loadDemoData();
      }
    } catch (e) {
      debugPrint('Customers fetch error: $e');
      _loadDemoData();
    } finally {
      isLoading.value = false;
    }
  }

  /// تحميل بيانات تجريبية
  void _loadDemoData() {
    customers.value = [
      CustomerWithStats(
        customer: UserModel(
          id: '1', fullName: 'أحمد بن سعد الدوسري', phone: '0501234567',
          role: 'customer', neighborhood: 'حي النزهة',
          createdAt: DateTime(2024, 1, 15).millisecondsSinceEpoch,
        ),
        totalOrders: 12, totalSpent: 3450.0,
        lastOrderDate: DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch,
        lastOrderStatus: 'completed', totalMeters: 45.5,
      ),
      CustomerWithStats(
        customer: UserModel(
          id: '2', fullName: 'محمد بن عبدالله القحطاني', phone: '0559876543',
          role: 'customer', neighborhood: 'حي الروضة',
          createdAt: DateTime(2024, 2, 20).millisecondsSinceEpoch,
        ),
        totalOrders: 8, totalSpent: 2100.0,
        lastOrderDate: DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch,
        lastOrderStatus: 'pending', totalMeters: 28.3,
      ),
      CustomerWithStats(
        customer: UserModel(
          id: '3', fullName: 'خالد بن فهد العمري', phone: '0541112233',
          role: 'customer', neighborhood: 'حي المروج',
          createdAt: DateTime(2024, 3, 5).millisecondsSinceEpoch,
        ),
        totalOrders: 15, totalSpent: 5800.0,
        lastOrderDate: DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        lastOrderStatus: 'data_ready', totalMeters: 72.0,
      ),
      CustomerWithStats(
        customer: UserModel(
          id: '4', fullName: 'عبدالرحمن بن سالم الحربي', phone: '0567891234',
          role: 'customer', neighborhood: 'حي العليا',
          createdAt: DateTime(2024, 4, 10).millisecondsSinceEpoch,
        ),
        totalOrders: 5, totalSpent: 1250.0,
        lastOrderDate: DateTime.now().subtract(const Duration(days: 15)).millisecondsSinceEpoch,
        lastOrderStatus: 'completed', totalMeters: 16.8,
      ),
      CustomerWithStats(
        customer: UserModel(
          id: '5', fullName: 'فهد بن ناصر الشمري', phone: '0534567890',
          role: 'customer', neighborhood: 'حي السليمانية',
          createdAt: DateTime(2024, 5, 1).millisecondsSinceEpoch,
        ),
        totalOrders: 20, totalSpent: 7200.0,
        lastOrderDate: DateTime.now().subtract(const Duration(hours: 5)).millisecondsSinceEpoch,
        lastOrderStatus: 'pending', totalMeters: 95.2,
      ),
      CustomerWithStats(
        customer: UserModel(
          id: '6', fullName: 'سلطان بن محمد المطيري', phone: '0511223344',
          role: 'customer', neighborhood: 'حي الورود',
          createdAt: DateTime(2024, 6, 8).millisecondsSinceEpoch,
        ),
        totalOrders: 3, totalSpent: 890.0,
        lastOrderDate: DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch,
        lastOrderStatus: 'completed', totalMeters: 11.5,
      ),
    ];
    filteredCustomers.assignAll(customers);
    totalCustomersCount.value = customers.length;
    allTimeRevenue.value = customers.fold(0.0, (sum, c) => sum + c.totalSpent);
  }

  /// تغيير البحث
  void _onSearchChanged() {
    searchQuery.value = searchController.text.trim();
    _applyFilters();
  }

  /// تطبيق الفلاتر
  void _applyFilters() {
    if (searchQuery.value.isEmpty) {
      filteredCustomers.assignAll(customers);
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredCustomers.value = customers.where((c) {
        return c.customer.fullName.toLowerCase().contains(query) ||
            c.customer.phone.contains(query) ||
            (c.customer.neighborhood ?? '').toLowerCase().contains(query);
      }).toList();
    }
  }

  /// تحديث البحث
  void updateSearch(String value) {
    searchQuery.value = value.trim();
    _applyFilters();
  }

  /// تغيير طريقة الفرز
  void changeSort(String newSortBy) {
    if (sortBy.value == newSortBy) {
      sortAscending.value = !sortAscending.value;
    } else {
      sortBy.value = newSortBy;
      sortAscending.value = true;
    }
    _sortCustomers();
  }

  /// فرز العملاء
  void _sortCustomers() {
    final list = List<CustomerWithStats>.from(filteredCustomers);
    switch (sortBy.value) {
      case 'name':
        list.sort((a, b) => sortAscending.value
            ? a.customer.fullName.compareTo(b.customer.fullName)
            : b.customer.fullName.compareTo(a.customer.fullName));
        break;
      case 'orders':
        list.sort((a, b) => sortAscending.value
            ? a.totalOrders.compareTo(b.totalOrders)
            : b.totalOrders.compareTo(a.totalOrders));
        break;
      case 'spent':
        list.sort((a, b) => sortAscending.value
            ? a.totalSpent.compareTo(b.totalSpent)
            : b.totalSpent.compareTo(a.totalSpent));
        break;
      case 'recent':
        list.sort((a, b) => sortAscending.value
            ? (a.lastOrderDate ?? 0).compareTo(b.lastOrderDate ?? 0)
            : (b.lastOrderDate ?? 0).compareTo(a.lastOrderDate ?? 0));
        break;
    }
    filteredCustomers.assignAll(list);
  }

  /// جلب طلبات العميل
  Future<void> fetchCustomerOrders(String customerId) async {
    isLoadingOrders.value = true;
    customerOrders.clear();

    try {
      final response = await _api.get('customers/$customerId/orders');

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final list = data['data'] ?? data['orders'] ?? [];
          if (list is List) {
            customerOrders.value = list
                .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      } else {
        _loadDemoCustomerOrders();
      }
    } catch (e) {
      debugPrint('Customer orders fetch error: $e');
      _loadDemoCustomerOrders();
    } finally {
      isLoadingOrders.value = false;
    }
  }

  /// بيانات طلبات تجريبية
  void _loadDemoCustomerOrders() {
    customerOrders.value = [
      OrderModel(
        id: '1001', customerName: 'خالد فهد', customerPhone: '0541112233',
        neighborhood: 'حي المروج', delegateName: 'أحمد محمد',
        invoiceNumber: 'INV-2024-0156', orderStatus: 'completed',
        totalPrice: 450.0, totalMeters: 5.2,
        payment: PaymentInfo(cash: 450.0),
        createdAt: DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
      ),
      OrderModel(
        id: '1002', customerName: 'خالد فهد', customerPhone: '0541112233',
        neighborhood: 'حي المروج', delegateName: 'خالد عبدالله',
        invoiceNumber: 'INV-2024-0148', orderStatus: 'pending',
        totalPrice: 320.0, totalMeters: 3.8,
        payment: PaymentInfo(bank: 320.0),
        createdAt: DateTime.now().subtract(const Duration(days: 5)).millisecondsSinceEpoch,
      ),
      OrderModel(
        id: '1003', customerName: 'خالد فهد', customerPhone: '0541112233',
        neighborhood: 'حي المروج', delegateName: 'سعد العمري',
        invoiceNumber: 'INV-2024-0132', orderStatus: 'data_ready',
        totalPrice: 580.0, totalMeters: 7.0,
        payment: PaymentInfo(cash: 300.0, card: 280.0),
        createdAt: DateTime.now().subtract(const Duration(days: 12)).millisecondsSinceEpoch,
      ),
      OrderModel(
        id: '1004', customerName: 'خالد فهد', customerPhone: '0541112233',
        neighborhood: 'حي المروج', delegateName: 'أحمد محمد',
        invoiceNumber: 'INV-2024-0115', orderStatus: 'completed',
        totalPrice: 210.0, totalMeters: 2.5,
        payment: PaymentInfo(cash: 210.0),
        createdAt: DateTime.now().subtract(const Duration(days: 20)).millisecondsSinceEpoch,
      ),
      OrderModel(
        id: '1005', customerName: 'خالد فهد', customerPhone: '0541112233',
        neighborhood: 'حي المروج', delegateName: 'عمر الحربي',
        invoiceNumber: 'INV-2024-0098', orderStatus: 'cancelled',
        totalPrice: 150.0, totalMeters: 1.8,
        payment: PaymentInfo(),
        createdAt: DateTime.now().subtract(const Duration(days: 35)).millisecondsSinceEpoch,
      ),
    ];
  }

  /// اختيار عميل وعرض طلباته
  Future<void> selectCustomer(CustomerWithStats customer) async {
    selectedCustomer.value = customer;
    await fetchCustomerOrders(customer.customer.id);
  }

  /// إغلاق تفاصيل العميل
  void clearSelection() {
    selectedCustomer.value = null;
    customerOrders.clear();
  }

  /// الاتصال بالعميل
  Future<void> callCustomer(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar(
        'خطأ',
        'لا يمكن الاتصال بالرقم',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  /// مراسلة العميل عبر واتساب
  Future<void> whatsappCustomer(String phone, {String? message}) async {
    var cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0') && cleaned.length >= 10) {
      cleaned = '966${cleaned.substring(1)}';
    }

    final msg = Uri.encodeComponent(message ?? 'مرحباً، نتمنى لكم يوماً سعيداً - مغسلة السجاد');
    final uri = Uri.parse('https://wa.me/$cleaned?text=$msg');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'خطأ',
        'لا يمكن فتح واتساب',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  /// تحميل المزيد
  Future<void> loadMore() async {
    if (hasMore.value && !isLoading.value) {
      currentPage.value++;
      await fetchCustomers();
    }
  }

  /// إعادة تحميل البيانات
  Future<void> refresh() async {
    currentPage.value = 1;
    await fetchCustomers(refresh: true);
  }

  // ===== Getters =====
  bool get hasError => errorMessage.value.isNotEmpty;
  int get customerCount => filteredCustomers.length;

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

// ============================================================================
// الشاشة الرئيسية - CustomersScreen
// ============================================================================

/// شاشة العملاء
class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

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
              // الصف الأول: عنوان وزر الرجوع
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
                      'العملاء',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Obx(() {
                    final controller = Get.find<CustomersController>();
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '${controller.totalCustomersCount} عميل',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentLight,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              SizedBox(height: AppSpacing.sm.h),
              // شريط البحث
              _buildSearchBar(),
              SizedBox(height: AppSpacing.sm.h),
            ],
          ),
        ),
      ),
    );
  }

  /// شريط البحث
  Widget _buildSearchBar() {
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 14.w),
          Icon(FontAwesomeIcons.magnifyingGlass, size: 14.sp, color: Colors.white.withValues(alpha: 0.6)),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: Get.find<CustomersController>().searchController,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14.sp,
                color: Colors.white,
              ),
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو الرقم...',
                hintStyle: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13.sp,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                isDense: true,
              ),
              onChanged: (value) {
                Get.find<CustomersController>().updateSearch(value);
              },
            ),
          ),
          Obx(() {
            final controller = Get.find<CustomersController>();
            if (controller.searchQuery.value.isNotEmpty) {
              return GestureDetector(
                onTap: () {
                  controller.searchController.clear();
                  controller.updateSearch('');
                },
                child: Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Icon(
                    FontAwesomeIcons.xmark,
                    size: 14.sp,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              );
            }
            return const SizedBox();
          }),
        ],
      ),
    );
  }

  // ===== الجسم =====
  Widget _buildBody() {
    return Column(
      children: [
        // شريط الفرز
        _buildSortBar(),
        // محتوى العملاء
        Expanded(child: _buildCustomerList()),
      ],
    );
  }

  /// شريط الفرز
  Widget _buildSortBar() {
    const sortOptions = [
      _SortOption(key: 'name', label: 'الاسم', icon: FontAwesomeIcons.font),
      _SortOption(key: 'orders', label: 'الطلبات', icon: FontAwesomeIcons.clipboardList),
      _SortOption(key: 'spent', label: 'المصروف', icon: FontAwesomeIcons.coins),
      _SortOption(key: 'recent', label: 'الأحدث', icon: FontAwesomeIcons.clock),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: AppSpacing.sm.h),
      child: Obx(() {
        final controller = Get.find<CustomersController>();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: sortOptions.map((option) {
              final isActive = controller.sortBy.value == option.key;
              return Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: GestureDetector(
                  onTap: () => controller.changeSort(option.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: isActive
                          ? null
                          : Border.all(color: AppColors.border),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          option.icon,
                          size: 10.sp,
                          color: isActive ? Colors.white : AppColors.textMuted,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          option.label,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11.sp,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                            color: isActive ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                        if (isActive) ...[
                          SizedBox(width: 2.w),
                          Icon(
                            controller.sortAscending.value
                                ? FontAwesomeIcons.arrowUpShortWide
                                : FontAwesomeIcons.arrowDownWideShort,
                            size: 9.sp,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  /// قائمة العملاء
  Widget _buildCustomerList() {
    return Obx(() {
      final controller = Get.find<CustomersController>();

      if (controller.isLoading.value && controller.customers.isEmpty) {
        return _buildLoadingState();
      }

      if (controller.hasError && controller.customers.isEmpty) {
        return _buildErrorState(controller);
      }

      if (controller.selectedCustomer.value != null) {
        return _buildCustomerDetails(controller);
      }

      if (controller.filteredCustomers.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        color: AppColors.accent,
        onRefresh: controller.refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
              controller.loadMore();
            }
            return false;
          },
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
            itemCount: controller.filteredCustomers.length + (controller.hasMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.filteredCustomers.length) {
                return Padding(
                  padding: EdgeInsets.all(AppSpacing.md.r),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                );
              }

              final customer = controller.filteredCustomers[index];
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                child: _CustomerCard(
                  customer: customer,
                  onTap: () => controller.selectCustomer(customer),
                  onCall: () => controller.callCustomer(customer.customer.phone),
                  onWhatsApp: () => controller.whatsappCustomer(customer.customer.phone),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  // ===== تفاصيل العميل =====
  Widget _buildCustomerDetails(CustomersController controller) {
    final customer = controller.selectedCustomer.value!;
    return Column(
      children: [
        // شريط عنوان التفاصيل
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: AppSpacing.sm.h),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: controller.clearSelection,
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    FontAwesomeIcons.arrowRight,
                    size: 14.sp,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm.w),
              Expanded(
                child: Text(
                  'طلبات ${customer.customer.fullName}',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
              // زر الاتصال
              _ActionButton(
                icon: FontAwesomeIcons.phone,
                color: AppColors.success,
                onTap: () => controller.callCustomer(customer.customer.phone),
              ),
              SizedBox(width: 6.w),
              // زر واتساب
              _ActionButton(
                icon: FontAwesomeIcons.whatsapp,
                color: AppColors.whatsapp,
                onTap: () => controller.whatsappCustomer(customer.customer.phone),
              ),
            ],
          ),
        ),
        // ملخص العميل
        _buildCustomerSummary(customer),
        // قائمة الطلبات
        Expanded(child: _buildOrdersList(controller)),
      ],
    );
  }

  /// ملخص العميل
  Widget _buildCustomerSummary(CustomerWithStats customer) {
    return Container(
      margin: EdgeInsets.all(AppSpacing.md.w),
      padding: EdgeInsets.all(AppSpacing.md.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryMid],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          // صورة العميل
          CircleAvatar(
            radius: 28.r,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              customer.customer.fullName.isNotEmpty
                  ? customer.customer.fullName[0]
                  : '?',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.customer.fullName,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  customer.customer.phone,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // الإحصائيات
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${customer.totalOrders} طلب',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentLight,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                customer.totalSpentDisplay,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12.sp,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// قائمة طلبات العميل
  Widget _buildOrdersList(CustomersController controller) {
    if (controller.isLoadingOrders.value) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (controller.customerOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.inbox,
              size: 40.sp,
              color: AppColors.textMuted.withValues(alpha: 0.4),
            ),
            SizedBox(height: AppSpacing.md.h),
            Text(
              'لا توجد طلبات لهذا العميل',
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

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
      itemCount: controller.customerOrders.length,
      itemBuilder: (context, index) {
        final order = controller.customerOrders[index];
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
          child: _OrderHistoryCard(order: order),
        );
      },
    );
  }

  // ===== حالات =====
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
            'جاري تحميل العملاء...',
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

  Widget _buildErrorState(CustomersController controller) {
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
              onPressed: controller.refresh,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.userGroup,
              size: 48.sp,
              color: AppColors.textMuted.withValues(alpha: 0.4),
            ),
            SizedBox(height: AppSpacing.lg.h),
            Text(
              'لا يوجد عملاء',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'لم يتم العثور على عملاء مطابقين للبحث',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13.sp,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// مكونات مساعدة
// ============================================================================

class _SortOption {
  final String key;
  final String label;
  final IconData icon;
  const _SortOption({required this.key, required this.label, required this.icon});
}

/// بطاقة العميل
class _CustomerCard extends StatelessWidget {
  final CustomerWithStats customer;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onCall,
    required this.onWhatsApp,
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
        child: Column(
          children: [
            // الصف الأول: بيانات العميل
            Row(
              children: [
                // أيقونة العميل
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  child: Text(
                    customer.customer.fullName.isNotEmpty
                        ? customer.customer.fullName[0]
                        : '?',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm.w),
                // الاسم والحارة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.customer.fullName,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.locationDot,
                            size: 9.sp,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            customer.customer.neighborhood,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            customer.lastOrderDisplay,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 10.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm.h),
            // الصف الثاني: إحصائيات وأزرار
            Row(
              children: [
                // عدد الطلبات
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.clipboardList, size: 10.sp, color: AppColors.primary),
                        SizedBox(width: 4.w),
                        Text(
                          '${customer.totalOrders} طلب',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                // المبلغ المنفق
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.coins, size: 10.sp, color: AppColors.accent),
                        SizedBox(width: 4.w),
                        Text(
                          customer.totalSpentDisplay,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                // أزرار الاتصال والواتساب
                GestureDetector(
                  onTap: onCall,
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      FontAwesomeIcons.phone,
                      size: 12.sp,
                      color: AppColors.success,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                GestureDetector(
                  onTap: onWhatsApp,
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.whatsapp.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      FontAwesomeIcons.whatsapp,
                      size: 12.sp,
                      color: AppColors.whatsapp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة طلب في السجل
class _OrderHistoryCard extends StatelessWidget {
  final OrderModel order;

  const _OrderHistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Container(
      padding: EdgeInsets.all(AppSpacing.md.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // الرأس: رقم الفاتورة والتاريخ والحالة
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.invoiceNumber,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(FontAwesomeIcons.calendar, size: 9.sp, color: AppColors.textMuted),
                        SizedBox(width: 4.w),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (order.delegateName.isNotEmpty) ...[
                          SizedBox(width: 10.w),
                          Icon(FontAwesomeIcons.truck, size: 9.sp, color: AppColors.textMuted),
                          SizedBox(width: 4.w),
                          Text(
                            order.delegateName,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // شارة الحالة
              _StatusBadge(status: order.orderStatus),
            ],
          ),
          SizedBox(height: AppSpacing.sm.h),
          // التفاصيل
          Row(
            children: [
              Expanded(
                child: _OrderDetailItem(
                  icon: FontAwesomeIcons.rulerCombined,
                  label: 'الأمتار',
                  value: '${order.totalMeters.toStringAsFixed(1)} م\u00B2',
                ),
              ),
              Expanded(
                child: _OrderDetailItem(
                  icon: FontAwesomeIcons.coins,
                  label: 'الإجمالي',
                  value: '${order.totalPrice.toStringAsFixed(0)} ر.س',
                  valueColor: AppColors.accent,
                ),
              ),
            ],
          ),
          // طريقة الدفع
          if (order.payment.cash > 0 || order.payment.bank > 0 || order.payment.card > 0) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                order.payment.displayText,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 10.sp,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// شارة الحالة
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColors[status] ?? AppColors.textMuted;
    final bgColor = AppColors.statusLightColors[status] ?? AppColors.bg;
    final text = OrderModel(orderStatus: status).statusText;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.r,
            height: 6.r,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// عنصر تفصيل الطلب
class _OrderDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _OrderDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 10.sp, color: AppColors.textMuted),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11.sp,
            color: AppColors.textMuted,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.text,
          ),
        ),
      ],
    );
  }
}

/// زر إجراء
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, size: 14.sp, color: color),
      ),
    );
  }
}
