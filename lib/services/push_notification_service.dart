import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// خدمة الإشعارات
class PushNotificationService extends GetxController {
  static PushNotificationService get to => Get.find();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final _storage = GetStorage();

  final hasPermission = false.obs;
  final _lastNotificationKey = 'last_notification';

  @override
  void onInit() {
    super.onInit();
    _setupFirebaseListeners();
  }

  /// تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    // إعداد الإشعارات المحلية
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // إنشاء قناة إشعارات أندرويد
    await _createNotificationChannel();
  }

  /// إنشاء قناة الإشعارات
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'laundry_orders', // معرف القناة
      'طلبات المغسلة', // اسم القناة
      description: 'إشعارات الطلبات الجديدة والتحديثات',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// طلب إذن الإشعارات
  Future<bool> requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
      );

      hasPermission.value = settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (hasPermission.value) {
        await _subscribeToTopic();
        // إرسال إشعار تجريبي
        await showNotification(
          title: 'مغسلة السجاد',
          body: 'تم تفعيل الإشعارات بنجاح!',
        );
      }

      return hasPermission.value;
    } catch (e) {
      debugPrint('فشل طلب إذن الإشعارات: $e');
      return false;
    }
  }

  /// الاشتراك في موضوع
  Future<void> _subscribeToTopic() async {
    try {
      final userId = _storage.read<String>('currentUserId');
      if (userId != null) {
        await _firebaseMessaging.subscribeToTopic('user_$userId');
        await _firebaseMessaging.subscribeToTopic('all_admins');
      }
    } catch (e) {
      debugPrint('فشل الاشتراك في الموضوع: $e');
    }
  }

  /// إعداد مستمعي Firebase
  void _setupFirebaseListeners() {
    // عندما يكون التطبيق في المقدمة
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // عندما يكون التطبيق في الخلفية وتم فتحه من الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // عند فتح التطبيق من إشعار وهو مغلق
    _firebaseMessaging.getInitialMessage().then(_handleInitialMessage);
  }

  /// معالجة رسالة في المقدمة
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      showNotification(
        title: notification.title ?? 'إشعار جديد',
        body: notification.body ?? '',
        data: message.data,
      );
    }
  }

  /// معالجة فتح الرسالة من الخلفية
  void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('orderId')) {
      _navigateToOrder(data['orderId']);
    } else if (data.containsKey('screen')) {
      Get.toNamed(data['screen']);
    }
  }

  /// معالجة الرسالة الأولية
  void _handleInitialMessage(RemoteMessage? message) {
    if (message != null) {
      final data = message.data;
      if (data.containsKey('orderId')) {
        _navigateToOrder(data['orderId']);
      }
    }
  }

  /// التنقل لصفحة الطلب
  void _navigateToOrder(String orderId) {
    Future.delayed(const Duration(milliseconds: 500), () {
      // سيتم تنفيذ هذا بعد بناء الصفحة الرئيسية
      // Get.toNamed('/order-details', arguments: {'orderId': orderId});
    });
  }

  /// عرض إشعار محلي
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? payload,
  }) async {
    // منع الإشعارات المكررة
    final key = '${title}_${body}';
    final lastNotif = _storage.read<String>(_lastNotificationKey);
    if (lastNotif == key) return;
    _storage.write(_lastNotificationKey, key);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'laundry_orders',
      'طلبات المغسلة',
      channelDescription: 'إشعارات الطلبات الجديدة والتحديثات',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: DefaultStyleInformation(true, true),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload ?? data?.toString(),
      );
    } catch (e) {
      debugPrint('فشل عرض الإشعار: $e');
    }
  }

  /// عرض إشعار فوري (للطلبات الجديدة)
  Future<void> showNewOrderNotification({
    required String customerName,
    required String orderId,
  }) async {
    await showNotification(
      title: '\u{1F4E6} طلب جديد',
      body: 'طلب جديد من: $customerName',
      data: {'orderId': orderId, 'screen': '/orders'},
    );
  }

  /// عرض إشعار تحديث حالة الطلب
  Future<void> showStatusUpdateNotification({
    required String orderNumber,
    required String newStatus,
    required String customerName,
  }) async {
    await showNotification(
      title: '\u{1F4CB} تحديث طلب #$orderNumber',
      body: '$customerName - $newStatus',
      data: {'orderId': orderNumber, 'screen': '/orders'},
    );
  }

  /// الضغط على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        // محاولة تحليل البيانات
        if (payload.contains('orderId')) {
          final match = RegExp(r'orderId=([^,}]+)').firstMatch(payload);
          if (match != null) {
            _navigateToOrder(match.group(1)!);
          }
        }
      } catch (e) {
        debugPrint('فشل تحليل بيانات الإشعار: $e');
      }
    }
  }

  /// إلغاء جميع الإشعارات
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  /// تحديث رمز FCM على السيرفر
  Future<void> updateFcmToken(String userId) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null && userId.isNotEmpty) {
        // إرسال الرمز للسيرفر
        // await ApiService.to.post('notifications/subscribe', data: {
        //   'userId': int.parse(userId),
        //   'endpoint': token,
        // });
        debugPrint('تم تحديث FCM Token للمستخدم: $userId');
      }
    } catch (e) {
      debugPrint('فشل تحديث FCM Token: $e');
    }
  }
}
