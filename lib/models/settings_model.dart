/// نموذج الإشعار
class NotificationModel {
  String id;
  String title;
  String body;
  String? data;
  bool isRead;
  int createdAt;
  String? senderName;
  String? type;

  NotificationModel({
    this.id = '',
    this.title = '',
    this.body = '',
    this.data,
    this.isRead = false,
    int? createdAt,
    this.senderName,
    this.type,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data']?.toString(),
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      createdAt: _toInt(json['createdAt']),
      senderName: json['senderName'],
      type: json['type'],
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return DateTime.now().millisecondsSinceEpoch;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? DateTime.now().millisecondsSinceEpoch;
  }
}

/// نموذج موقع المندوب
class LocationModel {
  String userId;
  double latitude;
  double longitude;
  double accuracy;
  int timestamp;
  double? speed;
  double? heading;

  LocationModel({
    this.userId = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.accuracy = 0.0,
    int? timestamp,
    this.speed,
    this.heading,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      userId: json['userId'] ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      accuracy: _toDouble(json['accuracy']),
      timestamp: _toInt(json['timestamp']),
      speed: json['speed'] != null ? _toDouble(json['speed']) : null,
      heading: json['heading'] != null ? _toDouble(json['heading']) : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

/// نموذج إعدادات التطبيق
class AppSettingsModel {
  String laundryName;
  String logoUrl;
  String iconUrl;
  String whatsappTemplate;
  InvoiceSettings invoiceSettings;
  LaundryThemeSettings themeSettings;

  AppSettingsModel({
    this.laundryName = 'مغسلة السجاد',
    this.logoUrl = '',
    this.iconUrl = '',
    this.whatsappTemplate = '',
    InvoiceSettings? invoiceSettings,
    LaundryThemeSettings? themeSettings,
  })  : invoiceSettings = invoiceSettings ?? InvoiceSettings(),
        themeSettings = themeSettings ?? LaundryThemeSettings();

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      laundryName: json['laundryName'] ?? 'مغسلة السجاد',
      logoUrl: json['logoUrl'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      whatsappTemplate: json['whatsappTemplate'] ?? '',
      invoiceSettings: json['invoiceSettings'] != null
          ? InvoiceSettings.fromJson(json['invoiceSettings'])
          : InvoiceSettings(),
    );
  }
}

/// إعدادات الفاتورة
class InvoiceSettings {
  String headerText;
  String footerText;
  bool showLogo;
  bool showQrCode;
  String taxNumber;

  InvoiceSettings({
    this.headerText = '',
    this.footerText = '',
    this.showLogo = true,
    this.showQrCode = true,
    this.taxNumber = '',
  });

  factory InvoiceSettings.fromJson(Map<String, dynamic> json) {
    return InvoiceSettings(
      headerText: json['headerText'] ?? '',
      footerText: json['footerText'] ?? '',
      showLogo: json['showLogo'] ?? true,
      showQrCode: json['showQrCode'] ?? true,
      taxNumber: json['taxNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headerText': headerText,
      'footerText': footerText,
      'showLogo': showLogo,
      'showQrCode': showQrCode,
      'taxNumber': taxNumber,
    };
  }
}

/// إعدادات الثيم (الألوان)
class LaundryThemeSettings {
  String primaryDark;
  String primary;
  String primaryMid;
  String primaryLight;
  String accent;
  String accentLight;
  String bg;
  String card;
  String text;
  String textMuted;
  String border;
  String success;
  String warning;
  String danger;
  String info;
  String whatsapp;

  LaundryThemeSettings({
    this.primaryDark = '#071F17',
    this.primary = '#0B3D2E',
    this.primaryMid = '#1B5E3B',
    this.primaryLight = '#2D8659',
    this.accent = '#C8963E',
    this.accentLight = '#D4A853',
    this.bg = '#F5F0E8',
    this.card = '#FFFFFF',
    this.text = '#1C1917',
    this.textMuted = '#78716C',
    this.border = '#E7E0D5',
    this.success = '#16A34A',
    this.warning = '#D97706',
    this.danger = '#DC2626',
    this.info = '#0284C7',
    this.whatsapp = '#25D366',
  });

  factory LaundryThemeSettings.fromJson(Map<String, dynamic> json) {
    return LaundryThemeSettings(
      primaryDark: json['primaryDark'] ?? '#071F17',
      primary: json['primary'] ?? '#0B3D2E',
      primaryMid: json['primaryMid'] ?? '#1B5E3B',
      primaryLight: json['primaryLight'] ?? '#2D8659',
      accent: json['accent'] ?? '#C8963E',
      accentLight: json['accentLight'] ?? '#D4A853',
      bg: json['bg'] ?? '#F5F0E8',
      card: json['card'] ?? '#FFFFFF',
      text: json['text'] ?? '#1C1917',
      textMuted: json['textMuted'] ?? '#78716C',
      border: json['border'] ?? '#E7E0D5',
      success: json['success'] ?? '#16A34A',
      warning: json['warning'] ?? '#D97706',
      danger: json['danger'] ?? '#DC2626',
      info: json['info'] ?? '#0284C7',
      whatsapp: json['whatsapp'] ?? '#25D366',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryDark': primaryDark,
      'primary': primary,
      'primaryMid': primaryMid,
      'primaryLight': primaryLight,
      'accent': accent,
      'accentLight': accentLight,
      'bg': bg,
      'card': card,
      'text': text,
      'textMuted': textMuted,
      'border': border,
      'success': success,
      'warning': warning,
      'danger': danger,
      'info': info,
      'whatsapp': whatsapp,
    };
  }
}

/// نموذج عنصر معرض الأعمال
class GalleryItemModel {
  String id;
  String imageUrl;
  String title;
  String description;
  int sortOrder;
  bool isActive;
  int? createdAt;

  GalleryItemModel({
    this.id = '',
    this.imageUrl = '',
    this.title = '',
    this.description = '',
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory GalleryItemModel.fromJson(Map<String, dynamic> json) {
    return GalleryItemModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'],
    );
  }
}

/// نموذج محتوى الصفحة
class PageContentModel {
  String id;
  String pageId;
  String sectionType;
  String title;
  String content;
  String? imageUrl;
  int sortOrder;
  bool isActive;

  PageContentModel({
    this.id = '',
    this.pageId = '',
    this.sectionType = 'text',
    this.title = '',
    this.content = '',
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory PageContentModel.fromJson(Map<String, dynamic> json) {
    return PageContentModel(
      id: json['id']?.toString() ?? '',
      pageId: json['pageId'] ?? '',
      sectionType: json['sectionType'] ?? 'text',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }
}
