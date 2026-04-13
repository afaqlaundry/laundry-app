import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';

// ============================================================
// نموذج موقع المندوب على الخريطة
// ============================================================
class DelegateLocation {
  final UserModel delegate;
  double latitude;
  double longitude;
  double? accuracy;
  double? speed;
  double? heading;
  int? lastUpdate;
  bool isOnline;

  DelegateLocation({
    required this.delegate,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.lastUpdate,
    this.isOnline = false,
  });

  factory DelegateLocation.fromJson(Map<String, dynamic> json) {
    return DelegateLocation(
      delegate: UserModel.fromJson(json['delegate'] ?? json),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      accuracy: json['accuracy'] != null ? _toDouble(json['accuracy']) : null,
      speed: json['speed'] != null ? _toDouble(json['speed']) : null,
      heading: json['heading'] != null ? _toDouble(json['heading']) : null,
      lastUpdate: json['lastUpdate'] ?? json['last_update'] ?? json['timestamp'],
      isOnline: json['isOnline'] ?? json['is_online'] ?? false,
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);

  String get lastUpdateText {
    if (lastUpdate == null) return 'غير متوفر';
    final dt = DateTime.fromMillisecondsSinceEpoch(lastUpdate!);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${(diff.inDays)} يوم';
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// ============================================================
// وحدة التحكم في التتبع
// ============================================================
class TrackingController extends GetxController {
  final ApiService _api = ApiService.to;

  // ---- الخريطة ----
  final Rx<GoogleMapController?> mapController = Rx<GoogleMapController?>(null);
  final CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(24.7136, 46.6753), // الرياض افتراضياً
    zoom: 12.0,
  );

  // ---- البيانات ----
  final delegateLocations = <DelegateLocation>[].obs;
  final markers = <Marker>{}.obs;
  final isLoading = false.obs;
  final isMapLoading = true.obs;

  // ---- الموقع الحالي ----
  final currentLocation = Rx<LatLng?>(null);
  final currentLocationEnabled = false.obs;

  // ---- المندوب المحدد ----
  final selectedDelegate = Rx<DelegateLocation?>(null);
  final showBottomSheet = false.obs;

  // ---- المؤقت ----
  Timer? _refreshTimer;
  final autoRefreshInterval = 10; // ثواني

  // ---- التحكم بالتكبير ----
  final currentZoom = 12.0.obs;

  // ---- المسافات ----
  final distances = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initLocation();
    fetchDelegateLocations();
    _startAutoRefresh();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    mapController.value?.dispose();
    super.onClose();
  }

  // ---- تهيئة الموقع ----
  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      currentLocation.value = LatLng(position.latitude, position.longitude);
      currentLocationEnabled.value = true;

      // تحريك الكاميرا للموقع الحالي
      mapController.value?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation.value!,
            zoom: 12.0,
          ),
        ),
      );
    } catch (e) {
      debugPrint('خطأ في تحديد الموقع: $e');
    }
  }

  // ---- بدء التحديث التلقائي ----
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      Duration(seconds: autoRefreshInterval),
      (_) => fetchDelegateLocations(silent: true),
    );
  }

  // ---- تحديث الخريطة عند جاهزيتها ----
  void onMapCreated(GoogleMapController controller) {
    mapController.value = controller;
    isMapLoading.value = false;

    // نقل الكاميرا للموقع الحالي إن وجد
    if (currentLocation.value != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation.value!,
            zoom: 12.0,
          ),
        ),
      );
    } else if (delegateLocations.isNotEmpty) {
      _fitAllMarkers();
    }
  }

  // ---- جلب مواقع المندوبين ----
  Future<void> fetchDelegateLocations({bool silent = false}) async {
    if (!silent) isLoading.value = true;

    try {
      final response = await _api.get('delegates/locations');
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> list =
            data is List ? data : (data['locations'] ?? data['data'] ?? []);

        delegateLocations.value =
            list.map((e) => DelegateLocation.fromJson(e)).toList();

        _updateMarkers();
        _calculateDistances();

        // التحقق إذا كانت هناك بيانات
        if (delegateLocations.isNotEmpty && mapController.value != null) {
          if (!silent) _fitAllMarkers();
        }
      }
    } catch (e) {
      debugPrint('خطأ في جلب المواقع: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---- تحديث العلامات ----
  void _updateMarkers() {
    final Set<Marker> newMarkers = {};

    for (final loc in delegateLocations) {
      final isActive = loc.isOnline && loc.latitude != 0.0 && loc.longitude != 0.0;
      final markerColor = isActive ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueGray;

      newMarkers.add(
        Marker(
          markerId: MarkerId(loc.delegate.id),
          position: loc.latLng,
          icon: isActive
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGray),
          infoWindow: InfoWindow(
            title: loc.delegate.fullName,
            snippet: isActive
                ? 'نشط - ${loc.lastUpdateText}'
                : 'غير نشط - ${loc.lastUpdateText}',
            onTap: () => selectDelegate(loc),
          ),
          onTap: () => selectDelegate(loc),
          alpha: isActive ? 1.0 : 0.5,
        ),
      );
    }

    // إضافة علامة الموقع الحالي
    if (currentLocation.value != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLocation.value!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'موقعك الحالي',
            snippet: 'أنت هنا',
          ),
          alpha: 0.8,
        ),
      );
    }

    markers.value = newMarkers;
  }

  // ---- حساب المسافات ----
  void _calculateDistances() {
    if (currentLocation.value == null) return;

    for (final loc in delegateLocations) {
      final distance = Geolocator.distanceBetween(
        currentLocation.value!.latitude,
        currentLocation.value!.longitude,
        loc.latitude,
        loc.longitude,
      );
      distances[loc.delegate.id] = distance;
    }
  }

  // ---- تحديد مندوب ----
  void selectDelegate(DelegateLocation? loc) {
    selectedDelegate.value = loc;
    showBottomSheet.value = loc != null;

    if (loc != null && mapController.value != null) {
      mapController.value!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: loc.latLng,
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  // ---- إغلاق القائمة السفلية ----
  void closeBottomSheet() {
    showBottomSheet.value = false;
    selectedDelegate.value = null;
  }

  // ---- تكبير / تصغير ----
  Future<void> zoomIn() async {
    final ctrl = mapController.value;
    if (ctrl == null) return;
    currentZoom.value = (currentZoom.value + 1.5).clamp(5.0, 21.0);
    await ctrl.animateCamera(CameraUpdate.zoomTo(currentZoom.value));
  }

  Future<void> zoomOut() async {
    final ctrl = mapController.value;
    if (ctrl == null) return;
    currentZoom.value = (currentZoom.value - 1.5).clamp(5.0, 21.0);
    await ctrl.animateCamera(CameraUpdate.zoomTo(currentZoom.value));
  }

  // ---- عرض جميع العلامات ----
  Future<void> _fitAllMarkers() async {
    final ctrl = mapController.value;
    if (ctrl == null || delegateLocations.isEmpty) return;

    final activeLocations = delegateLocations
        .where((loc) =>
            loc.isOnline &&
            loc.latitude != 0.0 &&
            loc.longitude != 0.0)
        .toList();

    if (activeLocations.isEmpty) return;

    LatLngBounds bounds;
    if (activeLocations.length == 1) {
      bounds = LatLngBounds(
        southwest: LatLng(
          activeLocations[0].latitude - 0.01,
          activeLocations[0].longitude - 0.01,
        ),
        northeast: LatLng(
          activeLocations[0].latitude + 0.01,
          activeLocations[0].longitude + 0.01,
        ),
      );
    } else {
      double minLat = activeLocations[0].latitude;
      double maxLat = activeLocations[0].latitude;
      double minLng = activeLocations[0].longitude;
      double maxLng = activeLocations[0].longitude;

      for (final loc in activeLocations) {
        if (loc.latitude < minLat) minLat = loc.latitude;
        if (loc.latitude > maxLat) maxLat = loc.latitude;
        if (loc.longitude < minLng) minLng = loc.longitude;
        if (loc.longitude > maxLng) maxLng = loc.longitude;
      }

      bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
    }

    await ctrl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Future<void> fitAllMarkers() async {
    await _fitAllMarkers();
  }

  // ---- الانتقال للموقع الحالي ----
  Future<void> goToMyLocation() async {
    if (currentLocation.value != null && mapController.value != null) {
      await mapController.value!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation.value!,
            zoom: 15.0,
          ),
        ),
      );
    } else {
      await _initLocation();
    }
  }

  // ---- فتح خرائط جوجل للتنقل ----
  Future<void> navigateToDelegate(DelegateLocation loc) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${loc.latitude},${loc.longitude}&travelmode=driving&dir_action=navigate';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'خطأ',
        'لا يمكن فتح خرائط جوجل',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        margin: EdgeInsets.all(16.r),
        borderRadius: 12.r,
      );
    }
  }

  // ---- اتصال بالمندوب ----
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

  // ---- حساب المسافة بين مندوبين ----
  double distanceBetween(DelegateLocation a, DelegateLocation b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  // ---- تحديث للسحب ----
  Future<void> refreshData() async {
    await fetchDelegateLocations();
    if (currentLocation.value == null) {
      await _initLocation();
    }
  }

  // ---- عداد المندوبين النشطين ----
  int get activeCount =>
      delegateLocations.where((loc) => loc.isOnline).length;

  int get inactiveCount =>
      delegateLocations.where((loc) => !loc.isOnline).length;

  // ---- تنسيق المسافة ----
  String formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} م';
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }
}

// ============================================================
// شاشة التتبع
// ============================================================
class TrackingScreen extends GetView<TrackingController> {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // الخريطة
            _buildMap(),

            // مؤشر التحميل
            Obx(() => controller.isLoading.value && controller.delegateLocations.isEmpty
                ? _buildMapShimmer()
                : const SizedBox.shrink()),

            // أزرار التحكم
            _buildMapControls(),

            // مؤشر التحديث التلقائي
            _buildAutoRefreshIndicator(),

            // القائمة السفلية
            Obx(() => controller.showBottomSheet.value
                ? _buildDelegateDetailSheet()
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  // ---- شريط التطبيق ----
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'تتبع المندوبين',
        style: TextStyle(fontFamily: 'Tajawal'),
      ),
      actions: [
        Obx(() => Padding(
              padding: EdgeInsetsDirectional.only(start: 8.w, end: 8.w),
              child: Center(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${controller.activeCount} نشط',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  // ---- الخريطة ----
  Widget _buildMap() {
    return Obx(() {
      return GoogleMap(
        onMapCreated: controller.onMapCreated,
        initialCameraPosition: controller.initialCameraPosition,
        markers: controller.markers.toSet(),
        myLocationEnabled: controller.currentLocationEnabled.value,
        myLocationButtonEnabled: false,
        mapType: MapType.normal,
        zoomControlsEnabled: false,
        compassEnabled: true,
        trafficEnabled: true,
        buildingsEnabled: true,
        indoorViewEnabled: false,
        padding: EdgeInsets.only(bottom: controller.showBottomSheet.value ? 340.h : 0),
        onCameraMove: (position) {
          controller.currentZoom.value = position.zoom;
        },
        onCameraIdle: () {},
      );
    });
  }

  // ---- شيمر التحميل ----
  Widget _buildMapShimmer() {
    return Positioned.fill(
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE0E0E0),
        highlightColor: const Color(0xFFF5F5F5),
        child: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 64.r, color: Colors.grey[400]),
                SizedBox(height: 16.h),
                Text(
                  'جارٍ تحميل مواقع المندوبين...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontFamily: 'Tajawal',
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- أزرار التحكم بالخريطة ----
  Widget _buildMapControls() {
    return Positioned(
      left: 16.w,
      bottom: 24.h,
      child: Column(
        children: [
          // تكبير
          _mapControlButton(
            icon: Icons.add,
            onTap: controller.zoomIn,
          ),
          SizedBox(height: 8.h),
          // تصغير
          _mapControlButton(
            icon: Icons.remove,
            onTap: controller.zoomOut,
          ),
          SizedBox(height: 8.h),
          // موقعي
          _mapControlButton(
            icon: Icons.my_location,
            onTap: controller.goToMyLocation,
            color: AppColors.info,
          ),
          SizedBox(height: 8.h),
          // عرض الكل
          _mapControlButton(
            icon: Icons.fit_screen,
            onTap: controller.fitAllMarkers,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _mapControlButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 44.r,
            height: 44.r,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: color ?? AppColors.primary,
              size: 22.r,
            ),
          ),
        ),
      ),
    );
  }

  // ---- مؤشر التحديث التلقائي ----
  Widget _buildAutoRefreshIndicator() {
    return Positioned(
      top: 8.h,
      right: 16.w,
      child: Obx(() {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: controller.isLoading.value
                ? AppColors.warning.withOpacity(0.9)
                : AppColors.success.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14.r,
                height: 14.r,
                child: controller.isLoading.value
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Icon(Icons.refresh, size: 14.r, color: Colors.white),
              ),
              SizedBox(width: 6.w),
              Text(
                controller.isLoading.value
                    ? 'جارٍ التحديث...'
                    : 'تحديث تلقائي كل ${controller.autoRefreshInterval}ث',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ---- القائمة السفلية لتفاصيل المندوب ----
  Widget _buildDelegateDetailSheet() {
    final loc = controller.selectedDelegate.value;
    if (loc == null) return const SizedBox.shrink();

    final distance = controller.distances[loc.delegate.id];
    final distText = distance != null
        ? controller.formatDistance(distance)
        : 'غير محدد';

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // مقبض السحب
            Container(
              margin: EdgeInsets.only(top: 10.h, bottom: 4.h),
              width: 40.r,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // محتوى المندوب
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                children: [
                  // معلومات المندوب الأساسية
                  Row(
                    children: [
                      // الصورة الرمزية
                      Container(
                        width: 56.r,
                        height: 56.r,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: loc.isOnline
                                ? [AppColors.primary, AppColors.primaryLight]
                                : [Colors.grey, Colors.grey[400]!],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: Text(
                            loc.delegate.fullName.isNotEmpty
                                ? loc.delegate.fullName[0]
                                : '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),

                      // الاسم والحالة
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    loc.delegate.fullName,
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Tajawal',
                                      color: AppColors.text,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Container(
                                  width: 10.r,
                                  height: 10.r,
                                  decoration: BoxDecoration(
                                    color: loc.isOnline
                                        ? AppColors.success
                                        : AppColors.textMuted,
                                    shape: BoxShape.circle,
                                    boxShadow: loc.isOnline
                                        ? [
                                            BoxShadow(
                                              color: AppColors.success
                                                  .withOpacity(0.4),
                                              blurRadius: 4,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  loc.isOnline ? 'متصل الآن' : 'غير متصل',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontFamily: 'Tajawal',
                                    color: loc.isOnline
                                        ? AppColors.success
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Icon(Icons.access_time,
                                    size: 14.r, color: AppColors.textMuted),
                                SizedBox(width: 4.w),
                                Text(
                                  loc.lastUpdateText,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontFamily: 'Tajawal',
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // زر الإغلاق
                      InkWell(
                        onTap: controller.closeBottomSheet,
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              size: 20.r, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // بطاقات المعلومات
                  Row(
                    children: [
                      _infoCard(
                        icon: Icons.phone_android,
                        label: 'الهاتف',
                        value: loc.delegate.phone,
                        onTap: () => controller.callDelegate(loc.delegate.phone),
                      ),
                      SizedBox(width: 10.w),
                      _infoCard(
                        icon: Icons.location_on,
                        label: 'المسافة',
                        value: distText,
                        color: AppColors.accent,
                      ),
                      SizedBox(width: 10.w),
                      _infoCard(
                        icon: Icons.speed,
                        label: 'السرعة',
                        value: loc.speed != null
                            ? '${loc.speed!.toStringAsFixed(0)} كم/س'
                            : '-',
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // أزرار الإجراءات
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: 'اتصال',
                          icon: Icons.phone,
                          color: AppColors.success,
                          onTap: () =>
                              controller.callDelegate(loc.delegate.phone),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _actionButton(
                          label: 'واتساب',
                          icon: FontAwesomeIcons.whatsapp,
                          color: AppColors.whatsapp,
                          onTap: () =>
                              controller.whatsappDelegate(loc.delegate.phone),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _actionButton(
                          label: 'تنقل',
                          icon: Icons.navigation,
                          color: AppColors.info,
                          onTap: () => controller.navigateToDelegate(loc),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: (color ?? AppColors.primary).withOpacity(0.15),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18.r,
                  color: color ?? AppColors.primary),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  color: color ?? AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontFamily: 'Tajawal',
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18.r),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// شاشة قائمة المندوبين (قائمة سفلية كاملة)
// ============================================================
class DelegatesBottomSheet extends GetView<TrackingController> {
  const DelegatesBottomSheet({super.key});

  static Future<void> show() async {
    await Get.bottomSheet(
      const DelegatesBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // رأس
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: const BoxDecoration(
                color: Color(0xFF0B3D2E),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.locationDot,
                          color: AppColors.accent, size: 18),
                      SizedBox(width: 10.w),
                      Text(
                        'مندوبين على الخريطة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                  Obx(() => Text(
                        '${controller.activeCount}/${controller.delegateLocations.length}',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      )),
                ],
              ),
            ),

            // مقبض
            Container(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              width: 40.r,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // القائمة
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.delegateLocations.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }

                if (controller.delegateLocations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off,
                            size: 64.r, color: AppColors.textMuted),
                        SizedBox(height: 16.h),
                        Text(
                          'لا يوجد مندوبين متاحين حالياً',
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

                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: controller.delegateLocations.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final loc = controller.delegateLocations[index];
                    return _buildDelegateListItem(loc);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDelegateListItem(DelegateLocation loc) {
    final distance = controller.distances[loc.delegate.id];
    final distText = distance != null
        ? controller.formatDistance(distance)
        : '-';

    return InkWell(
      onTap: () {
        Get.back();
        controller.selectDelegate(loc);
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: loc.isOnline
              ? AppColors.success.withOpacity(0.06)
              : AppColors.bg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: loc.isOnline
                ? AppColors.success.withOpacity(0.2)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // صورة رمزية
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: loc.isOnline
                      ? [AppColors.primary, AppColors.primaryLight]
                      : [Colors.grey, Colors.grey[400]!],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  loc.delegate.fullName.isNotEmpty
                      ? loc.delegate.fullName[0]
                      : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
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
                      Expanded(
                        child: Text(
                          loc.delegate.fullName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: loc.isOnline
                              ? AppColors.success.withOpacity(0.12)
                              : AppColors.textMuted.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.r,
                              height: 6.r,
                              decoration: BoxDecoration(
                                color: loc.isOnline
                                    ? AppColors.success
                                    : AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              loc.isOnline ? 'نشط' : 'غير نشط',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w600,
                                color: loc.isOnline
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12.r, color: AppColors.textMuted),
                      SizedBox(width: 4.w),
                      Text(
                        loc.lastUpdateText,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontFamily: 'Tajawal',
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(Icons.straighten,
                          size: 12.r, color: AppColors.textMuted),
                      SizedBox(width: 4.w),
                      Text(
                        distText,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontFamily: 'Tajawal',
                          color: AppColors.textMuted,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                      if (loc.speed != null && loc.speed! > 0) ...[
                        SizedBox(width: 12.w),
                        Icon(Icons.speed,
                            size: 12.r, color: AppColors.textMuted),
                        SizedBox(width: 4.w),
                        Text(
                          '${loc.speed!.toStringAsFixed(0)} كم/س',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontFamily: 'Tajawal',
                            color: AppColors.textMuted,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // سهم
            Icon(Icons.chevron_left,
                size: 22.r, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
