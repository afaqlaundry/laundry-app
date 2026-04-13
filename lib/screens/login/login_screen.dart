import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';

/// شاشة تسجيل الدخول
///
/// شاشة احترافية بتدرج أخضر داكن مع لمسات ذهبية،
/// تدعم RTL وتستخدم GetX لإدارة الحالة.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ===== المتحكمات =====
  final AuthService _auth = AuthService.to;
  final LaundrySettingsService _settings = LaundrySettingsService.to;

  // ===== حقول النموذج =====
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ===== الحالة المحلية =====
  final RxBool _obscurePassword = true.obs;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // ===== دورة حياة العنصر =====

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAutoLogin();
  }

  /// تهيئة الرسوم المتحركة
  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // تأخير بسيط قبل بدء الأنيميشن
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _animationController.forward();
    });
  }

  /// التحقق من جلسة موجودة وتسجيل الدخول تلقائياً
  void _checkAutoLogin() {
    ever(_auth.isLoggedIn, (loggedIn) {
      if (loggedIn) {
        Get.offAllNamed('/home');
      }
    });

    // التحقق من الجلسة عند فتح الشاشة
    if (_auth.isLoggedIn.value) {
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.offAllNamed('/home');
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ===== تسجيل الدخول =====

  /// تنفيذ عملية تسجيل الدخول
  Future<void> _performLogin() async {
    // إخفاء لوحة المفاتيح
    FocusScope.of(context).unfocus();

    // التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) return;

    final success = await _auth.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (success) {
      Get.offAllNamed('/home');
    }
  }

  // ===== بناء الواجهة =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF061A12), // أغمق في الأعلى
              Color(0xFF0B3D2E), // اللون الأساسي
              Color(0xFF0E4A38), // أفتح قليلاً في الأسفل
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl.w,
                ).copyWith(
                  top: 20.h,
                  bottom: 20.h,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 30.h),

                    // ===== أيقونة التطبيق =====
                    _buildLogoSection(),

                    SizedBox(height: 12.h),

                    // ===== اسم المغسلة =====
                    _buildLaundryName(),

                    SizedBox(height: 8.h),

                    // ===== العنوان الفرعي =====
                    _buildSubtitle(),

                    SizedBox(height: 40.h),

                    // ===== نموذج تسجيل الدخول =====
                    _buildLoginForm(),

                    SizedBox(height: 24.h),

                    // ===== رسالة الخطأ =====
                    _buildErrorMessage(),

                    SizedBox(height: 20.h),

                    // ===== زر تسجيل الدخول =====
                    _buildLoginButton(),

                    SizedBox(height: 36.h),

                    // ===== بيانات الدخول الافتراضية =====
                    _buildDefaultCredentialsHint(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== أقسام الواجهة =====

  /// بناء قسم أيقونة التطبيق (مكنسة داخل دائرة ذهبية)
  Widget _buildLogoSection() {
    return Container(
      width: 110.w,
      height: 110.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD4A853), // ذهبي فاتح
            Color(0xFFC8963E), // ذهبي أساسي
            Color(0xFFB07D2E), // ذهبي داكن
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          FontAwesomeIcons.broom,
          size: 44.sp,
          color: Colors.white,
        ),
      ),
    );
  }

  /// بناء قسم اسم المغسلة (ديناميكي من الإعدادات)
  Widget _buildLaundryName() {
    return Obx(() {
      return Text(
        _settings.laundryName.value,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 26.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      );
    });
  }

  /// بناء العنوان الفرعي
  Widget _buildSubtitle() {
    return Text(
      'نظام إدارة الطلبات والمناديب',
      style: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.65),
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// بناء نموذج تسجيل الدخول
  Widget _buildLoginForm() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.w,
        vertical: AppSpacing.xl.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // حقل اسم المستخدم
            _buildUsernameField(),
            SizedBox(height: AppSpacing.lg.h),
            // حقل كلمة المرور
            _buildPasswordField(),
          ],
        ),
      ),
    );
  }

  /// بناء حقل اسم المستخدم
  Widget _buildUsernameField() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextFormField(
        controller: _usernameController,
        focusNode: _usernameFocus,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) {
          FocusScope.of(context).requestFocus(_passwordFocus);
        },
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 15.sp,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'اسم المستخدم',
          labelStyle: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14.sp,
            color: Colors.white.withOpacity(0.55),
          ),
          hintText: 'أدخل اسم المستخدم',
          hintStyle: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13.sp,
            color: Colors.white.withOpacity(0.35),
          ),
          prefixIcon: Container(
            margin: EdgeInsetsDirectional.only(
              start: 4.w,
              end: 12.w,
            ),
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              FontAwesomeIcons.user,
              size: 16.sp,
              color: AppColors.accent,
            ),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(
              color: AppColors.accent,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(
              color: AppColors.danger,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(
              color: AppColors.danger,
              width: 1.5,
            ),
          ),
          errorStyle: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12.sp,
            color: AppColors.danger,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md.w,
            vertical: 16.h,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'يرجى إدخال اسم المستخدم';
          }
          if (value.trim().length < 3) {
            return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
          }
          return null;
        },
      ),
    );
  }

  /// بناء حقل كلمة المرور
  Widget _buildPasswordField() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Obx(() {
        return TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword.value,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _performLogin(),
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 15.sp,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: 'كلمة المرور',
            labelStyle: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.55),
            ),
            hintText: 'أدخل كلمة المرور',
            hintStyle: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13.sp,
              color: Colors.white.withOpacity(0.35),
            ),
            prefixIcon: Container(
              margin: EdgeInsetsDirectional.only(
                start: 4.w,
                end: 12.w,
              ),
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                FontAwesomeIcons.lock,
                size: 16.sp,
                color: AppColors.accent,
              ),
            ),
            suffixIcon: GestureDetector(
              onTap: () => _obscurePassword.value = !_obscurePassword.value,
              child: Container(
                margin: EdgeInsetsDirectional.only(
                  start: 12.w,
                  end: 4.w,
                ),
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  _obscurePassword.value
                      ? FontAwesomeIcons.eyeSlash
                      : FontAwesomeIcons.eye,
                  size: 14.sp,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(
                color: AppColors.accent,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(
                color: AppColors.danger,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(
                color: AppColors.danger,
                width: 1.5,
              ),
            ),
            errorStyle: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12.sp,
              color: AppColors.danger,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md.w,
              vertical: 16.h,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال كلمة المرور';
            }
            if (value.trim().length < 4) {
              return 'كلمة المرور يجب أن تكون 4 أحرف على الأقل';
            }
            return null;
          },
        );
      }),
    );
  }

  /// بناء رسالة الخطأ
  Widget _buildErrorMessage() {
    return Obx(() {
      final error = _auth.errorMessage.value;
      if (error.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md.w,
          vertical: 12.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.danger.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              FontAwesomeIcons.circleExclamation,
              size: 16.sp,
              color: AppColors.danger,
            ),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: Text(
                error,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.danger,
                  height: 1.5,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// بناء زر تسجيل الدخول بتدرج ذهبي
  Widget _buildLoginButton() {
    return Obx(() {
      final isLoading = _auth.isLoading.value;

      return SizedBox(
        width: double.infinity,
        height: 54.h,
        child: ElevatedButton(
          onPressed: isLoading ? null : _performLogin,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
            backgroundColor: Colors.transparent,
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Color(0xFFC8963E), // ذهبي أساسي
                  Color(0xFFD4A853), // ذهبي فاتح
                ],
              ),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              alignment: Alignment.center,
              child: isLoading
                  ? SizedBox(
                      width: 22.sp,
                      height: 22.sp,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm.w),
                        Icon(
                          FontAwesomeIcons.arrowLeftToBracket,
                          size: 15.sp,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    });
  }

  /// بناء تلميح بيانات الدخول الافتراضية
  Widget _buildDefaultCredentialsHint() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.w,
        vertical: 14.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.circleInfo,
            size: 13.sp,
            color: Colors.white.withOpacity(0.4),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Text(
            'بيانات الدخول الافتراضية:',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.45),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 6.w),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 4.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'admin',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 4.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'admin123',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
