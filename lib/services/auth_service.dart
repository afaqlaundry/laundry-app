import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// خدمة المصادقة وتسجيل الدخول
class AuthService extends GetxController {
  static AuthService get to => Get.find();

  final ApiService _api = ApiService.to;
  final _storage = GetStorage();

  // حالة تسجيل الدخول
  final isLoggedIn = false.obs;
  final isLoading = false.obs;
  final currentUser = Rxn<UserModel>();
  final errorMessage = ''.obs;

  // جلسة تسجيل الدخول
  String? get userId => _storage.read<String>('currentUserId');
  String? get userRole => _storage.read<String>('currentUserRole');
  String? get userName => _storage.read<String>('currentUserName');

  @override
  void onInit() {
    super.onInit();
    _checkExistingSession();
  }

  /// التحقق من جلسة موجودة
  void _checkExistingSession() {
    final savedUserId = _storage.read<String>('currentUserId');
    if (savedUserId != null && savedUserId.isNotEmpty) {
      isLoggedIn.value = true;
      _loadUserDetails(savedUserId);
    }
  }

  /// تحميل بيانات المستخدم
  Future<void> _loadUserDetails(String userId) async {
    try {
      final response = await _api.get('users/$userId');
      if (response?.statusCode == 200) {
        final data = response!.data;
        if (data is Map && data['user'] != null) {
          currentUser.value = UserModel.fromJson(data['user']);
          _storage.write('currentUserName', currentUser.value?.fullName);
          _storage.write('currentUserRole', currentUser.value?.role);
        }
      }
    } catch (e) {
      debugPrint('فشل تحميل بيانات المستخدم: $e');
    }
  }

  /// تسجيل الدخول
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // محاولة تسجيل الدخول عبر الـ API
      final response = await _api.post('auth/login', data: {
        'username': username,
        'password': password,
      });

      if (response?.statusCode == 200) {
        final data = response!.data;
        if (data is Map && data['success'] == true) {
          final user = UserModel.fromJson(data['user'] ?? {});
          currentUser.value = user;

          // حفظ الجلسة
          await _storage.write('currentUserId', user.id);
          await _storage.write('currentUserRole', user.role);
          await _storage.write('currentUserName', user.fullName);
          await _storage.write('authToken', data['token'] ?? '');

          isLoggedIn.value = true;

          // حفظ المستخدمين محلياً
          _saveLocalUser(user);

          return true;
        }
      }

      // فشل من السيرفر - جرب محلياً
      final localUser = _findLocalUser(username, password);
      if (localUser != null) {
        currentUser.value = localUser;
        await _storage.write('currentUserId', localUser.id);
        await _storage.write('currentUserRole', localUser.role);
        await _storage.write('currentUserName', localUser.fullName);
        isLoggedIn.value = true;
        return true;
      }

      errorMessage.value = 'اسم المستخدم أو كلمة المرور غير صحيحة';
      return false;
    } catch (e) {
      // محاولة تسجيل الدخول محلياً في حالة عدم الاتصال
      final localUser = _findLocalUser(username, password);
      if (localUser != null) {
        currentUser.value = localUser;
        await _storage.write('currentUserId', localUser.id);
        await _storage.write('currentUserRole', localUser.role);
        await _storage.write('currentUserName', localUser.fullName);
        isLoggedIn.value = true;
        return true;
      }

      errorMessage.value = 'حدث خطأ في الاتصال، تأكد من الإنترنت';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      await _api.post('auth/logout');
    } catch (e) {
      // تجاهل الأخطاء أثناء تسجيل الخروج
    }

    // مسح الجلسة
    await _storage.remove('currentUserId');
    await _storage.remove('currentUserRole');
    await _storage.remove('currentUserName');
    await _storage.remove('authToken');

    currentUser.value = null;
    isLoggedIn.value = false;

    Get.offAllNamed('/login');
  }

  /// التحقق من الجلسة
  Future<bool> checkSession() async {
    try {
      final response = await _api.post('auth/check');
      if (response?.statusCode == 200 && response!.data['valid'] == true) {
        return true;
      }
    } catch (e) {
      // إذا لم يكن هناك اتصال، نعتمد على الجلسة المحلية
      return userId != null;
    }
    return userId != null;
  }

  // ===== المستخدمون المحليون (احتياطي) =====

  static const String _localUsersKey = 'carpetLocalUsers';

  List<UserModel> _getLocalUsers() {
    try {
      final List<dynamic> data = _storage.read<List>(_localUsersKey) ?? [];
      return data.map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  void _saveLocalUsers(List<UserModel> users) {
    _storage.write(
      _localUsersKey,
      users.map((e) => e.toJson()).toList(),
    );
  }

  void _saveLocalUser(UserModel user) {
    final users = _getLocalUsers();
    final existingIndex = users.indexWhere((u) => u.id == user.id);
    if (existingIndex >= 0) {
      users[existingIndex] = user;
    } else {
      users.add(user);
    }
    _saveLocalUsers(users);
  }

  UserModel? _findLocalUser(String username, String password) {
    final users = _getLocalUsers();
    try {
      return users.firstWhere(
        (u) => u.username == username && u.password == password,
      );
    } catch (e) {
      return null;
    }
  }

  /// تهيئة المستخدم الافتراضي
  void _initDefaultUsers() {
    final users = _getLocalUsers();
    if (!users.any((u) => u.username == 'admin')) {
      users.add(UserModel(
        id: 'local_admin_001',
        username: 'admin',
        password: 'admin123',
        fullName: 'مدير النظام',
        phone: '',
        role: 'admin',
        commission: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      _saveLocalUsers(users);
    }
  }
}
