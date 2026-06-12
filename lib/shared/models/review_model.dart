import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String customerId;
  final String customerName;
  final String businessId;
  final double rating;
  final String text;
  final String? reply;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.customerId,
    this.customerName = '',
    required this.businessId,
    required this.rating,
    required this.text,
    this.reply,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      businessId: json['businessId'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      text: json['text'] ?? '',
      reply: json['reply'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'businessId': businessId,
      'rating': rating,
      'text': text,
      'reply': reply,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
