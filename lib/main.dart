import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
import 'services/push_notification_service.dart';

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('=== رسالة خلفية Firebase ===');
  debugPrint('العنوان: ${message.notification?.title}');
  debugPrint('المحتوى: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF0B3D2E),
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  // ضعف الشاشة دائماً عمودي
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تهيئة التخزين المحلي
  await GetStorage.init();

  // تهيئة Firebase
  await Firebase.initializeApp();

  // إعداد الإشعارات
  final PushNotificationService pushService = PushNotificationService();
  await pushService.initialize();

  // Firebase Messaging - الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  runApp(const LaundryApp());
}
