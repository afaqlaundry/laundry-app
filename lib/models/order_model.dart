import 'package:get/get.dart';

/// نموذج الطلب
class OrderModel {
  String id;
  String customerName;
  String customerPhone;
  String neighborhood;
  String locationLink;
  String delegateId;
  String delegateName;
  String invoiceNumber;
  String orderStatus;
  double totalPrice;
  double totalMeters;
  PaymentInfo payment;
  String? houseImageUrl;
  String? pickupDate;
  String? notes;
  int createdAt;
  int? updatedAt;
  List<CarpetItem>? carpetItems;

  OrderModel({
    this.id = '',
    this.customerName = '',
    this.customerPhone = '',
    this.neighborhood = '',
    this.locationLink = '',
    this.delegateId = '',
    this.delegateName = '',
    this.invoiceNumber = '',
    this.orderStatus = 'pending',
    this.totalPrice = 0.0,
    this.totalMeters = 0.0,
    PaymentInfo? payment,
    this.houseImageUrl,
    this.pickupDate,
    this.notes,
    int? createdAt,
    this.updatedAt,
    this.carpetItems,
  }) : payment = payment ?? PaymentInfo();

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      neighborhood: json['neighborhood'] ?? '',
      locationLink: json['locationLink'] ?? '',
      delegateId: json['delegateId'] ?? '',
      delegateName: json['delegateName'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      orderStatus: json['orderStatus'] ?? 'pending',
      totalPrice: _parseDouble(json['totalPrice']),
      totalMeters: _parseDouble(json['totalMeters']),
      payment: json['payment'] != null
          ? PaymentInfo.fromJson(json['payment'])
          : PaymentInfo(),
      houseImageUrl: json['houseImageUrl'],
      pickupDate: json['pickupDate'],
      notes: json['notes'],
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      carpetItems: json['carpetItems'] != null
          ? (json['carpetItems'] as List)
              .map((e) => CarpetItem.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'neighborhood': neighborhood,
      'locationLink': locationLink,
      'delegateId': delegateId,
      'invoiceName': delegateName,
      'invoiceNumber': invoiceNumber,
      'orderStatus': orderStatus,
      'totalPrice': totalPrice,
      'totalMeters': totalMeters,
      'payment': payment.toJson(),
      'houseImageUrl': houseImageUrl,
      'pickupDate': pickupDate,
      'notes': notes,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now().millisecondsSinceEpoch;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? DateTime.now().millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  String get statusText {
    const Map<String, String> statusMap = {
      'pending': 'قيد الانتظار',
      'picked': 'بانتظار البيانات',
      'data_ready': 'جاهز للتسليم',
      'ready_for_delivery': 'جاهز للاستلام',
      'completed': 'تم التسليم',
      'cancelled': 'ملغي',
      'no': 'غير مستلم',
    };
    return statusMap[orderStatus] ?? orderStatus;
  }

  String get statusEmoji {
    const Map<String, String> emojiMap = {
      'pending': '\u{1F7E1}',
      'picked': '\u{1F4DD}',
      'data_ready': '\u{1F535}',
      'ready_for_delivery': '\u{1F7E2}',
      'completed': '\u{2705}',
      'cancelled': '\u{274C}',
      'no': '\u{274C}',
    };
    return emojiMap[orderStatus] ?? '\u{1F7E1}';
  }
}

/// معلومات الدفع
class PaymentInfo {
  double cash;
  double bank;
  double card;
  double discount;

  PaymentInfo({
    this.cash = 0.0,
    this.bank = 0.0,
    this.card = 0.0,
    this.discount = 0.0,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      cash: _toDouble(json['cash']),
      bank: _toDouble(json['bank']),
      card: _toDouble(json['card']),
      discount: _toDouble(json['discount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cash': cash,
      'bank': bank,
      'card': card,
      'discount': discount,
    };
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  double get total => cash + bank + card - discount;

  String get displayText {
    final List<String> parts = [];
    if (cash > 0) parts.add('كاش: ${cash.toStringAsFixed(2)}');
    if (bank > 0) parts.add('تحويل: ${bank.toStringAsFixed(2)}');
    if (card > 0) parts.add('شبكة: ${card.toStringAsFixed(2)}');
    if (discount > 0) parts.add('خصم: ${discount.toStringAsFixed(2)}');
    return parts.isEmpty ? '-' : parts.join(' | ');
  }
}

/// عنصر سجاد داخل الطلب
class CarpetItem {
  String id;
  String description;
  double width;
  double length;
  double pricePerMeter;
  double totalPrice;
  String? imageUrl;

  CarpetItem({
    this.id = '',
    this.description = '',
    this.width = 0.0,
    this.length = 0.0,
    this.pricePerMeter = 0.0,
    this.totalPrice = 0.0,
    this.imageUrl,
  });

  factory CarpetItem.fromJson(Map<String, dynamic> json) {
    return CarpetItem(
      id: json['id']?.toString() ?? '',
      description: json['description'] ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      length: (json['length'] as num?)?.toDouble() ?? 0.0,
      pricePerMeter: (json['pricePerMeter'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'width': width,
      'length': length,
      'pricePerMeter': pricePerMeter,
      'totalPrice': totalPrice,
      'imageUrl': imageUrl,
    };
  }

  double get meters => width * length;
}
