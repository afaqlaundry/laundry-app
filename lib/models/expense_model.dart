/// نموذج المصروف
class ExpenseModel {
  String id;
  String type;
  double amount;
  String payMethod; // cash, network, transfer
  String description;
  String date;
  bool isManagerExpense;
  String? deductFrom; // cash, network, transfer, report
  bool isReportOnly;

  ExpenseModel({
    this.id = '',
    this.type = '',
    this.amount = 0.0,
    this.payMethod = 'cash',
    this.description = '',
    this.date = '',
    this.isManagerExpense = false,
    this.deductFrom,
    this.isReportOnly = false,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      amount: _toDouble(json['amount']),
      payMethod: json['payMethod'] ?? json['pay_method'] ?? 'cash',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      isManagerExpense: json['isManagerExpense'] ?? json['is_manager_expense'] ?? false,
      deductFrom: json['deductFrom'] ?? json['deduct_from'],
      isReportOnly: json['isReportOnly'] ?? json['is_report_only'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'payMethod': payMethod,
      'description': description,
      'date': date,
      'isManagerExpense': isManagerExpense,
      'deductFrom': deductFrom,
      'isReportOnly': isReportOnly,
    };
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  String get payMethodText {
    const Map<String, String> methods = {
      'cash': 'كاش',
      'network': 'شبكة',
      'transfer': 'تحويل',
    };
    return methods[payMethod] ?? payMethod;
  }

  String get deductFromText {
    if (isReportOnly) return 'تقرير فقط';
    if (deductFrom == null) return payMethodText;
    const Map<String, String> methods = {
      'cash': 'الكاش',
      'network': 'الشبكة',
      'transfer': 'التحويل',
      'report': 'تقرير فقط',
    };
    return methods[deductFrom!] ?? deductFrom!;
  }
}

/// نموذج استلام كاش
class CashReceiptModel {
  String id;
  String description;
  double amount;
  String date;

  CashReceiptModel({
    this.id = '',
    this.description = '',
    this.amount = 0.0,
    this.date = '',
  });

  factory CashReceiptModel.fromJson(Map<String, dynamic> json) {
    return CashReceiptModel(
      id: json['id']?.toString() ?? '',
      description: json['description'] ?? '',
      amount: _toDouble(json['amount']),
      date: json['date'] ?? '',
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
