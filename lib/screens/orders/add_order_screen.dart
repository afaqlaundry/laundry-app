import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';

// ============================================================
// وحدة تحكم إضافة طلب
// ============================================================

class AddOrderController extends GetxController {
  final ApiService _api = ApiService.to;
  final ImagePicker _imagePicker = ImagePicker();

  // ===== حالة النموذج =====
  final RxBool isSaving = false.obs;
  final RxBool isLoadingCustomers = false.obs;
  final RxBool showCustomerSuggestions = false.obs;
  final RxString selectedImagePath = ''.obs;

  // ===== حقول النموذج =====
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController neighborhoodController = TextEditingController();
  final TextEditingController locationLinkController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController pickupDateController = TextEditingController();

  // ===== القيم المختارة =====
  final RxString selectedDelegateId = ''.obs;
  final RxString selectedDelegateName = ''.obs;
  final RxString selectedStatus = 'pending'.obs;
  final Rx<DateTime?> selectedPickupDate = Rx<DateTime?>(null);

  // ===== بيانات الإكمال التلقائي =====
  final RxList<Map<String, String>> customerSuggestions = <Map<String, String>>[].obs;
  final RxList<String> neighborhoods = <String>[].obs;
  final RxList<Map<String, dynamic>> delegates = <Map<String, dynamic>>[].obs;

  // ===== مفتاح النموذج =====
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // ===== خيارات حالة الطلب =====
  static const Map<String, String> statusOptions = {
    'pending': 'قيد الانتظار',
    'cancelled': 'ملغي',
  };

  @override
  void onInit() {
    super.onInit();
    fetchNeighborhoods();
    fetchDelegates();

    phoneController.addListener(_onPhoneChanged);
  }

  @override
  void onClose() {
    phoneController.dispose();
    nameController.dispose();
    neighborhoodController.dispose();
    locationLinkController.dispose();
    notesController.dispose();
    pickupDateController.dispose();
    super.onClose();
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

  // ===== جلب المندوبين =====
  Future<void> fetchDelegates() async {
    try {
      final response = await _api.get('delegates');
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> items;

        if (data is Map && data['data'] != null) {
          items = data['data'] as List<dynamic>;
        } else if (data is List) {
          items = data;
        } else {
          items = [];
        }

        delegates.assignAll(
          items.map((e) => {
            'id': (e as Map<String, dynamic>)['id']?.toString() ?? '',
            'name': e['name'] ?? '',
          }).toList(),
        );
      }
    } catch (e) {
      debugPrint('خطأ في جلب المندوبين: $e');
    }
  }

  // ===== البحث عن العملاء بالهاتف =====
  void _onPhoneChanged() {
    final phone = phoneController.text.trim();
    if (phone.length >= 4) {
      _searchCustomerByPhone(phone);
    } else {
      customerSuggestions.clear();
      showCustomerSuggestions.value = false;
    }
  }

  Future<void> _searchCustomerByPhone(String phone) async {
    isLoadingCustomers.value = true;
    try {
      final response = await _api.get(
        'customers/search',
        queryParams: {'phone': phone},
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> items;

        if (data is Map && data['data'] != null) {
          items = data['data'] as List<dynamic>;
        } else if (data is List) {
          items = data;
        } else {
          items = [];
        }

        customerSuggestions.assignAll(
          items.map((e) => {
            'id': (e as Map<String, dynamic>)['id']?.toString() ?? '',
            'name': e['name'] ?? '',
            'phone': e['phone'] ?? '',
            'neighborhood': e['neighborhood'] ?? '',
            'locationLink': e['locationLink'] ?? '',
          }).toList(),
        );

        showCustomerSuggestions.value = customerSuggestions.isNotEmpty;
      }
    } catch (e) {
      debugPrint('خطأ في البحث عن العميل: $e');
    } finally {
      isLoadingCustomers.value = false;
    }
  }

  // ===== اختيار عميل من الاقتراحات =====
  void selectCustomer(Map<String, String> customer) {
    phoneController.text = customer['phone'] ?? '';
    nameController.text = customer['name'] ?? '';
    neighborhoodController.text = customer['neighborhood'] ?? '';
    locationLinkController.text = customer['locationLink'] ?? '';
    showCustomerSuggestions.value = false;
    customerSuggestions.clear();
  }

  // ===== اختيار صورة المنزل =====
  Future<void> pickHouseImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImagePath.value = image.path;
      }
    } catch (e) {
      debugPrint('خطأ في اختيار الصورة: $e');
      Get.snackbar(
        'خطأ',
        'تعذر اختيار الصورة',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ===== إظهار قائمة اختيار الصورة =====
  void showImagePickerOptions() {
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
              'اختر صورة المنزل',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.info,
                  size: 22.sp,
                ),
              ),
              title: Text(
                'التقاط صورة',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'استخدم الكاميرا لالتقاط صورة',
                style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
              ),
              onTap: () {
                Get.back();
                pickHouseImage(ImageSource.camera);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            SizedBox(height: 8.h),
            ListTile(
              leading: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.accent,
                  size: 22.sp,
                ),
              ),
              title: Text(
                'اختيار من المعرض',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'اختر صورة من معرض الصور',
                style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
              ),
              onTap: () {
                Get.back();
                pickHouseImage(ImageSource.gallery);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
                  'إلغاء',
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

  // ===== اختيار تاريخ الاستلام =====
  Future<void> selectPickupDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: selectedPickupDate.value ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.text,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedPickupDate.value = picked;
      pickupDateController.text = DateFormat('yyyy/MM/dd').format(picked);
    }
  }

  // ===== التحقق من صحة النموذج =====
  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    if (value.trim().length < 9) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم العميل مطلوب';
    }
    if (value.trim().length < 2) {
      return 'الاسم قصير جداً';
    }
    return null;
  }

  String? validateNeighborhood(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الحي مطلوب';
    }
    return null;
  }

  // ===== حفظ الطلب =====
  Future<void> saveOrder() async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar(
        'تنبيه',
        'يرجى ملء جميع الحقول المطلوبة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
      return;
    }

    if (selectedDelegateId.value.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى اختيار المندوب',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
      return;
    }

    isSaving.value = true;

    try {
      // رفع الصورة إذا وجدت
      String? imageUrl;
      if (selectedImagePath.value.isNotEmpty) {
        final imageResponse = await _api.uploadFile(
          'upload',
          selectedImagePath.value,
          field: 'image',
        );
        if (imageResponse != null && imageResponse.data is Map) {
          imageUrl = imageResponse.data['url']?.toString() ??
              imageResponse.data['imageUrl']?.toString();
        }
      }

      // إنشاء بيانات الطلب
      final orderData = {
        'customerName': nameController.text.trim(),
        'customerPhone': phoneController.text.trim(),
        'neighborhood': neighborhoodController.text.trim(),
        'locationLink': locationLinkController.text.trim(),
        'delegateId': selectedDelegateId.value,
        'orderStatus': selectedStatus.value,
        'pickupDate': selectedPickupDate.value != null
            ? DateFormat('yyyy-MM-dd').format(selectedPickupDate.value!)
            : null,
        'notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        'houseImageUrl': imageUrl,
        'payment': {
          'cash': 0,
          'bank': 0,
          'card': 0,
          'discount': 0,
        },
      };

      final response = await _api.post('orders', data: orderData);

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        Get.snackbar(
          'تم بنجاح',
          'تم إنشاء الطلب بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        Get.back(result: true);
      } else {
        Get.snackbar(
          'خطأ',
          'فشل في إنشاء الطلب، حاول مرة أخرى',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('خطأ في حفظ الطلب: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء حفظ الطلب',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ===== إعادة تعيين النموذج =====
  void resetForm() {
    formKey.currentState?.reset();
    phoneController.clear();
    nameController.clear();
    neighborhoodController.clear();
    locationLinkController.clear();
    notesController.clear();
    pickupDateController.clear();
    selectedDelegateId.value = '';
    selectedDelegateName.value = '';
    selectedStatus.value = 'pending';
    selectedPickupDate.value = null;
    selectedImagePath.value = '';
    showCustomerSuggestions.value = false;
    customerSuggestions.clear();
  }

  // ===== تأكيد إعادة التعيين =====
  void confirmReset() {
    Get.dialog(
      AlertDialog(
        title: const Text('إعادة تعيين'),
        content: const Text('هل تريد مسح جميع البيانات المدخلة؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              resetForm();
            },
            child: const Text('مسح', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// شاشة إضافة طلب جديد
// ============================================================

class AddOrderScreen extends GetView<AddOrderController> {
  const AddOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Get.theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 120.h),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== معلومات العميل =====
                    _buildSectionTitle(
                      icon: FontAwesomeIcons.userCircle,
                      title: 'معلومات العميل',
                    ),
                    SizedBox(height: 12.h),
                    _buildPhoneField(),
                    _buildCustomerSuggestions(),
                    SizedBox(height: 12.h),
                    _buildNameField(),
                    SizedBox(height: 12.h),
                    _buildNeighborhoodField(),
                    SizedBox(height: 12.h),
                    _buildLocationLinkField(),

                    SizedBox(height: 24.h),

                    // ===== تفاصيل الطلب =====
                    _buildSectionTitle(
                      icon: FontAwesomeIcons.clipboardList,
                      title: 'تفاصيل الطلب',
                    ),
                    SizedBox(height: 12.h),
                    _buildDelegateDropdown(),
                    SizedBox(height: 12.h),
                    _buildStatusDropdown(),
                    SizedBox(height: 12.h),
                    _buildPickupDateField(),
                    SizedBox(height: 12.h),
                    _buildNotesField(),

                    SizedBox(height: 24.h),

                    // ===== صورة المنزل =====
                    _buildSectionTitle(
                      icon: FontAwesomeIcons.image,
                      title: 'صورة المنزل',
                    ),
                    SizedBox(height: 12.h),
                    _buildHouseImageSection(),
                  ],
                ),
              ),
            ),
            // ===== أزرار الحفظ والإعادة =====
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  // ===== شريط التطبيق =====
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'طلب جديد',
        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.arrow_forward),
      ),
      actions: [
        TextButton(
          onPressed: controller.confirmReset,
          child: Text(
            'مسح الكل',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }

  // ===== عنوان القسم =====
  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16.sp, color: AppColors.primary),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  // ===== حقل رقم الهاتف =====
  Widget _buildPhoneField() {
    return TextFormField(
      controller: controller.phoneController,
      validator: controller.validatePhone,
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: 'رقم الهاتف *',
        hintText: '05xxxxxxxx',
        hintStyle: TextStyle(
          fontSize: 13.sp,
          color: AppColors.textMuted,
        ),
        prefixIcon: Container(
          width: 44.w,
          alignment: Alignment.center,
          child: Icon(Icons.phone_outlined, size: 20.sp),
        ),
        suffixIcon: Obx(() => controller.isLoadingCustomers.value
            ? Padding(
                padding: EdgeInsets.all(12.w),
                child: SizedBox(
                  width: 18.sp,
                  height: 18.sp,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const SizedBox.shrink()),
      ),
    );
  }

  // ===== اقتراحات العملاء =====
  Widget _buildCustomerSuggestions() {
    return Obx(() {
      if (!controller.showCustomerSuggestions.value) {
        return const SizedBox.shrink();
      }

      if (controller.customerSuggestions.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: EdgeInsets.only(top: 4.h),
        decoration: BoxDecoration(
          color: Get.theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'عملاء متطابقون (${controller.customerSuggestions.length})',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            ...controller.customerSuggestions.map((customer) {
              return InkWell(
                onTap: () => controller.selectCustomer(customer),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16.sp,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          (customer['name'] ?? '?')[0],
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer['name'] ?? '',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              customer['phone'] ?? '',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textMuted,
                              ),
                              textDirection: TextDirection.ltr,
                            ),
                            if ((customer['neighborhood'] ?? '').isNotEmpty)
                              Text(
                                customer['neighborhood'] ?? '',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.accent,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_back_ios_new,
                          size: 14.sp, color: AppColors.textMuted),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  // ===== حقل اسم العميل =====
  Widget _buildNameField() {
    return TextFormField(
      controller: controller.nameController,
      validator: controller.validateName,
      keyboardType: TextInputType.name,
      decoration: InputDecoration(
        labelText: 'اسم العميل *',
        hintText: 'أدخل اسم العميل',
        hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
        prefixIcon: Container(
          width: 44.w,
          alignment: Alignment.center,
          child: Icon(Icons.person_outline, size: 20.sp),
        ),
      ),
    );
  }

  // ===== حقل الحي =====
  Widget _buildNeighborhoodField() {
    return Obx(() => Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return controller.neighborhoods;
            }
            return controller.neighborhoods
                .where((n) => n.contains(textEditingValue.text));
          },
          onSelected: (value) {
            controller.neighborhoodController.text = value;
          },
          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
            controller.neighborhoodController.text =
                controller.neighborhoodController.text;
            return TextFormField(
              controller: controller.neighborhoodController,
              focusNode: focusNode,
              validator: controller.validateNeighborhood,
              decoration: InputDecoration(
                labelText: 'الحي *',
                hintText: 'اختر أو أدخل اسم الحي',
                hintStyle:
                    TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
                prefixIcon: Container(
                  width: 44.w,
                  alignment: Alignment.center,
                  child: Icon(Icons.location_city_outlined, size: 20.sp),
                ),
              ),
              onChanged: (value) {
                textController.text = value;
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: AlignmentDirectional.topStart,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: BoxConstraints(maxHeight: 200.h, maxWidth: 320.w),
                  decoration: BoxDecoration(
                    color: Get.theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 10.h,
                          ),
                          child: Text(
                            option,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ));
  }

  // ===== حقل رابط الموقع =====
  Widget _buildLocationLinkField() {
    return TextFormField(
      controller: controller.locationLinkController,
      keyboardType: TextInputType.url,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: 'رابط الموقع',
        hintText: 'رابط Google Maps',
        hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
        prefixIcon: Container(
          width: 44.w,
          alignment: Alignment.center,
          child: Icon(Icons.link, size: 20.sp),
        ),
        suffixIcon: Obx(() {
          final link = controller.locationLinkController.text.trim();
          if (link.isNotEmpty && (link.startsWith('http') || link.startsWith('maps'))) {
            return IconButton(
              icon: Icon(Icons.open_in_new, size: 18.sp, color: AppColors.info),
              onPressed: () async {
                final uri = Uri.parse(link);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            );
          }
          return const SizedBox.shrink();
        }),
      ),
    );
  }

  // ===== قائمة منسدلة للمندوبين =====
  Widget _buildDelegateDropdown() {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedDelegateId.value.isEmpty
              ? null
              : controller.selectedDelegateId.value,
          decoration: InputDecoration(
            labelText: 'المندوب *',
            labelStyle: TextStyle(fontSize: 13.sp),
            hintText: 'اختر المندوب',
            hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
            prefixIcon: Container(
              width: 44.w,
              alignment: Alignment.center,
              child: Icon(
                FontAwesomeIcons.userTie,
                size: 18.sp,
                color: AppColors.textMuted,
              ),
            ),
          ),
          items: controller.delegates.isEmpty
              ? [
                  DropdownMenuItem(
                    value: '',
                    child: Text(
                      'لا يوجد مندوبين',
                      style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
                    ),
                  ),
                ]
              : [
                  DropdownMenuItem(
                    value: '',
                    child: Text(
                      'اختر المندوب',
                      style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
                    ),
                  ),
                  ...controller.delegates.map((delegate) {
                    return DropdownMenuItem(
                      value: delegate['id'] as String,
                      child: Text(
                        delegate['name'] as String,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    );
                  }),
                ],
          onChanged: (value) {
            if (value != null && value.isNotEmpty) {
              controller.selectedDelegateId.value = value;
              final delegate = controller.delegates.firstWhereOrNull(
                (d) => d['id'] == value,
              );
              controller.selectedDelegateName.value =
                  delegate?['name']?.toString() ?? '';
            } else {
              controller.selectedDelegateId.value = '';
              controller.selectedDelegateName.value = '';
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى اختيار المندوب';
            }
            return null;
          },
        ));
  }

  // ===== قائمة منسدلة للحالة =====
  Widget _buildStatusDropdown() {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedStatus.value,
          decoration: InputDecoration(
            labelText: 'حالة الطلب',
            labelStyle: TextStyle(fontSize: 13.sp),
            prefixIcon: Container(
              width: 44.w,
              alignment: Alignment.center,
              child: Icon(
                Icons.status,
                size: 20.sp,
                color: AppColors.textMuted,
              ),
            ),
          ),
          items: AddOrderController.statusOptions.entries
              .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Row(
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.statusColors[entry.key] ??
                                AppColors.textMuted,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          entry.value,
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              controller.selectedStatus.value = value;
            }
          },
        ));
  }

  // ===== حقل تاريخ الاستلام =====
  Widget _buildPickupDateField() {
    return Obx(() => TextFormField(
          controller: controller.pickupDateController,
          readOnly: true,
          onTap: controller.selectPickupDate,
          decoration: InputDecoration(
            labelText: 'تاريخ الاستلام المتوقع',
            labelStyle: TextStyle(fontSize: 13.sp),
            hintText: 'اختر التاريخ',
            hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
            prefixIcon: Container(
              width: 44.w,
              alignment: Alignment.center,
              child: Icon(
                Icons.calendar_today_outlined,
                size: 20.sp,
                color: AppColors.textMuted,
              ),
            ),
            suffixIcon: controller.pickupDateController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 18.sp, color: AppColors.textMuted),
                    onPressed: () {
                      controller.pickupDateController.clear();
                      controller.selectedPickupDate.value = null;
                    },
                  )
                : null,
          ),
        ));
  }

  // ===== حقل الملاحظات =====
  Widget _buildNotesField() {
    return TextFormField(
      controller: controller.notesController,
      keyboardType: TextInputType.multiline,
      maxLines: 3,
      minLines: 2,
      decoration: InputDecoration(
        labelText: 'ملاحظات',
        hintText: 'أضف أي ملاحظات إضافية...',
        hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 40.h),
          child: Container(
            width: 44.w,
            alignment: Alignment.topCenter,
            padding: EdgeInsets.only(top: 14.h),
            child: Icon(Icons.notes, size: 20.sp, color: AppColors.textMuted),
          ),
        ),
        alignLabelWithHint: true,
      ),
    );
  }

  // ===== قسم صورة المنزل =====
  Widget _buildHouseImageSection() {
    return Obx(() {
      final hasImage = controller.selectedImagePath.value.isNotEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // منطقة الصورة أو الزر
          if (hasImage) ...[
            Container(
              width: double.infinity,
              height: 200.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accent, width: 2),
                image: DecorationImage(
                  image: FileImage(
                    File(controller.selectedImagePath.value),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildImageAction(
                        icon: Icons.camera_alt,
                        label: 'إعادة',
                        onTap: () => controller.pickHouseImage(ImageSource.camera),
                        bgColor: AppColors.info,
                      ),
                      SizedBox(width: 8.w),
                      _buildImageAction(
                        icon: Icons.delete_outline,
                        label: 'حذف',
                        onTap: () {
                          controller.selectedImagePath.value = '';
                        },
                        bgColor: AppColors.danger,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            // زر رفع الصورة
            GestureDetector(
              onTap: controller.showImagePickerOptions,
              child: Container(
                width: double.infinity,
                height: 160.h,
                decoration: BoxDecoration(
                  color: Get.theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 26.sp,
                        color: AppColors.accent,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'إضافة صورة المنزل',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'اضغط لالتقاط صورة أو اختيارها',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  // ===== زر إجراء على الصورة =====
  Widget _buildImageAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color bgColor,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.sp, color: Colors.white),
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== أزرار الحفظ والإعادة في الأسفل =====
  Widget _buildBottomButtons() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Get.theme.scaffoldBackgroundColor.withOpacity(0),
              Get.theme.scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.2],
          ),
        ),
        child: Obx(() => Row(
              children: [
                // زر إعادة تعيين
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.confirmReset,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: AppColors.textMuted.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 18.sp, color: AppColors.textMuted),
                        SizedBox(width: 6.w),
                        Text(
                          'مسح',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // زر الحفظ
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                        begin: AlignmentDirectional.centerStart,
                        end: AlignmentDirectional.centerEnd,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: controller.isSaving.value
                            ? null
                            : controller.saveOrder,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: controller.isSaving.value
                              ? SizedBox(
                                  width: 22.sp,
                                  height: 22.sp,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        size: 20.sp, color: Colors.white),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'حفظ الطلب',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
