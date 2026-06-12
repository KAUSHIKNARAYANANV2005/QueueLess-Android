
class BusinessModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String address;
  final double lat;
  final double lng;
  final String phone;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final String plan; // 'free', 'pro', 'enterprise'
  final String? coverImage;
  final String? logoImage;
  final Map<String, dynamic>? hours;
  final String ownerId; // single owner UID
  // Live status fields (computed or from queue subcollection)
  final bool isOpen;
  final int currentQueue;
  final double distance; // metres from search origin

  BusinessModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.lat,
    required this.lng,
    required this.phone,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.plan = 'free',
    this.coverImage,
    this.logoImage,
    this.hours,
    required this.ownerId,
    this.isOpen = true,
    this.currentQueue = 0,
    this.distance = 0.0,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      phone: json['phone'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      plan: json['plan'] ?? 'free',
      coverImage: json['coverImage'],
      logoImage: json['logoImage'],
      hours: json['hours'],
      ownerId: json['ownerId'] ?? '',
      isOpen: json['isOpen'] as bool? ?? true,
      currentQueue: json['currentQueue'] as int? ?? 0,
      distance: (json['distance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'address': address,
      'lat': lat,
      'lng': lng,
      'phone': phone,
      'rating': rating,
      'reviewCount': reviewCount,
      'isVerified': isVerified,
      'plan': plan,
      'coverImage': coverImage,
      'logoImage': logoImage,
      'hours': hours,
      'ownerId': ownerId,
    };
  }
}
