class ServiceModel {
  final String id;
  final String businessId;
  final String name;
  final String description;
  final int durationMinutes;
  final double price;
  final String category;
  final bool isActive;

  ServiceModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
    required this.category,
    required this.isActive,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      businessId: json['businessId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 30,
      price: (json['price'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'description': description,
      'durationMinutes': durationMinutes,
      'price': price,
      'category': category,
      'isActive': isActive,
    };
  }
}
