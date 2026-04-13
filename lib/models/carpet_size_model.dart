/// نموذج مقاس السجاد
class CarpetSizeModel {
  String id;
  String description;
  double width;
  double length;
  double pricePerMeter;

  CarpetSizeModel({
    this.id = '',
    this.description = '',
    this.width = 0.0,
    this.length = 0.0,
    this.pricePerMeter = 0.0,
  });

  factory CarpetSizeModel.fromJson(Map<String, dynamic> json) {
    return CarpetSizeModel(
      id: json['id']?.toString() ?? '',
      description: json['description'] ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      length: (json['length'] as num?)?.toDouble() ?? 0.0,
      pricePerMeter: (json['pricePerMeter'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'width': width,
      'length': length,
      'pricePerMeter': pricePerMeter,
    };
  }

  double get totalMeters => width * length;
  double get totalPrice => totalMeters * pricePerMeter;

  String get sizeText => '${width.toStringAsFixed(2)} x ${length.toStringAsFixed(2)} م';
  String get priceText => '${pricePerMeter.toStringAsFixed(2)} ر.س/م\u00B2';
}
