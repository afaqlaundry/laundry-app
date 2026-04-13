import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// خدمة الاتصال بالـ API
class ApiService extends GetxController {
  static ApiService get to => Get.find();

  late Dio _dio;
  final _storage = GetStorage();
  final isConnected = true.obs;

  String get baseUrl {
    return _storage.read<String>('apiBaseUrl') ?? 'https://afaqlaundry.com/11/api/api.php/';
  }

  @override
  void onInit() {
    super.onInit();
    _setupDio();
  }

  void _setupDio() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // إضافة اعتراض للتسجيل
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) {
        // تسجيل محدود لمنع التشوش
        if (obj.length > 500) {
          debugPrint('API Response: ${obj.substring(0, 500)}...');
        } else {
          debugPrint('API: $obj');
        }
      },
    ));

    // إضافة اعتراض للتوثيق
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _storage.read<String>('authToken');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final userId = _storage.read<String>('currentUserId');
        if (userId != null) {
          options.headers['X-User-Id'] = userId;
        }
        handler.next(options);
      },
      onError: (error, handler) {
        isConnected.value = false;
        handler.next(error);
      },
    ));
  }

  /// تحديث عنوان الـ API
  void updateBaseUrl(String newUrl) {
    _storage.write('apiBaseUrl', newUrl);
    _dio.options.baseUrl = newUrl;
  }

  /// طلب GET
  Future<Response?> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      isConnected.value = true;
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// طلب POST
  Future<Response?> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      isConnected.value = true;
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// طلب PUT
  Future<Response?> put(
    String endpoint, {
    dynamic data,
  }) async {
    try {
      isConnected.value = true;
      final response = await _dio.put(endpoint, data: data);
      return response;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// طلب DELETE
  Future<Response?> delete(String endpoint) async {
    try {
      isConnected.value = true;
      final response = await _dio.delete(endpoint);
      return response;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// رفع ملف
  Future<Response?> uploadFile(
    String endpoint,
    String filePath, {
    String field = 'file',
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final formData = FormData.fromMap({
        field: await MultipartFile.fromFile(filePath),
        if (extraData != null) ...extraData,
      });
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// رفع ملف من البايتات
  Future<Response?> uploadBytes(
    String endpoint,
    List<int> bytes,
    String filename, {
    String field = 'file',
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final formData = FormData.fromMap({
        field: MultipartFile.fromBytes(bytes, filename: filename),
        if (extraData != null) ...extraData,
      });
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// معالجة الأخطاء
  void _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        isConnected.value = false;
        Get.snackbar(
          'خطأ في الاتصال',
          'تأكد من اتصالك بالإنترنت وحاول مرة أخرى',
          snackPosition: SnackPosition.BOTTOM,
        );
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          // تسجيل خروج تلقائي
          _storage.remove('currentUserId');
          _storage.remove('authToken');
          Get.offAllNamed('/login');
        } else if (statusCode == 403) {
          Get.snackbar('خطأ', 'ليس لديك صلاحية للقيام بهذا الإجراء');
        } else if (statusCode == 500) {
          Get.snackbar('خطأ', 'حدث خطأ في السيرفر، حاول لاحقاً');
        }
        break;
      case DioExceptionType.connectionError:
        isConnected.value = false;
        Get.snackbar(
          'غير متصل',
          'لا يوجد اتصال بالإنترنت',
          snackPosition: SnackPosition.BOTTOM,
        );
        break;
      default:
        debugPrint('Dio Error: ${error.message}');
    }
  }
}
