/// نموذج المستخدم (مدير / مندوب / عميل)
class UserModel {
  String id;
  String username;
  String password;
  String fullName;
  String phone;
  String role; // admin, delegate, customer
  double commission;
  String? invoicePrefix;
  String? currentInvoiceNumber;
  int? createdAt;
  bool isActive;
  String? profileImageUrl;
  String? fcmToken;

  UserModel({
    this.id = '',
    this.username = '',
    this.password = '',
    this.fullName = '',
    this.phone = '',
    this.role = 'customer',
    this.commission = 0.0,
    this.invoicePrefix,
    this.currentInvoiceNumber,
    this.createdAt,
    this.isActive = true,
    this.profileImageUrl,
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      commission: _toDouble(json['commission']),
      invoicePrefix: json['invoicePrefix'] ?? json['invoice_prefix'],
      currentInvoiceNumber: json['currentInvoiceNumber'] ?? json['current_invoice_number'],
      createdAt: _toInt(json['createdAt']),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      profileImageUrl: json['profileImageUrl'],
      fcmToken: json['fcmToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'commission': commission,
      'invoicePrefix': invoicePrefix,
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'fcmToken': fcmToken,
    };
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  String get roleText {
    const Map<String, String> roles = {
      'admin': 'مدير النظام',
      'delegate': 'مندوب',
      'customer': 'عميل',
    };
    return roles[role] ?? role;
  }

  bool get isAdmin => role == 'admin';
  bool get isDelegate => role == 'delegate';
}
