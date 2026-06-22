import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String customerId;
  final String customerName;
  final String businessId;
  final String businessName;
  final String serviceId;
  final String serviceName;
  final String? staffId;
  final String? staffName;
  final DateTime dateTime;
  final String status; // 'pending','confirmed','active','served','cancelled'
  final int queuePosition;
  final int estimatedWaitMinutes;
  final double price;
  final String paymentStatus; // 'pending','paid','refunded'
  final String tokenNumber;
  final DateTime? createdAt;

  BookingModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.businessId,
    this.businessName = '',
    required this.serviceId,
    required this.serviceName,
    this.staffId,
    this.staffName,
    required this.dateTime,
    required this.status,
    required this.queuePosition,
    required this.estimatedWaitMinutes,
    required this.price,
    required this.paymentStatus,
    required this.tokenNumber,
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      businessId: json['businessId'] ?? '',
      businessName: json['businessName'] ?? '',
      serviceId: json['serviceId'] ?? '',
      serviceName: json['serviceName'] ?? '',
      staffId: json['staffId'],
      staffName: json['staffName'],
      dateTime: json['dateTime'] is Timestamp
          ? (json['dateTime'] as Timestamp).toDate()
          : DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'pending',
      queuePosition: json['queuePosition'] ?? 0,
      estimatedWaitMinutes: json['estimatedWaitMinutes'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? 'pending',
      tokenNumber: json['tokenNumber'] ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'businessId': businessId,
      'businessName': businessName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'staffId': staffId,
      'staffName': staffName,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
      'queuePosition': queuePosition,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'price': price,
      'paymentStatus': paymentStatus,
      'tokenNumber': tokenNumber,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}
