/// نموذج العامل
class WorkerModel {
  String id;
  String name;
  String phone;
  double salary;
  String status; // active, vacation, inactive
  int? createdAt;
  List<SalaryPayment>? salaryPayments;

  WorkerModel({
    this.id = '',
    this.name = '',
    this.phone = '',
    this.salary = 0.0,
    this.status = 'active',
    this.createdAt,
    this.salaryPayments,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      salary: _toDouble(json['salary']),
      status: json['status'] ?? 'active',
      createdAt: _toInt(json['createdAt']),
      salaryPayments: json['salaryPayments'] != null
          ? (json['salaryPayments'] as List)
              .map((e) => SalaryPayment.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'salary': salary,
      'status': status,
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

  String get statusText {
    const Map<String, String> statuses = {
      'active': 'نشط',
      'vacation': 'في إجازة',
      'inactive': 'غير نشط',
    };
    return statuses[status] ?? status;
  }
}

/// دفعة راتب
class SalaryPayment {
  String id;
  double amount;
  String month;
  String year;
  String date;
  String? notes;

  SalaryPayment({
    this.id = '',
    this.amount = 0.0,
    this.month = '',
    this.year = '',
    this.date = '',
    this.notes,
  });

  factory SalaryPayment.fromJson(Map<String, dynamic> json) {
    return SalaryPayment(
      id: json['id']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      month: json['month'] ?? '',
      year: json['year'] ?? '',
      date: json['date'] ?? '',
      notes: json['notes'],
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
