class QueueItem {
  final String bookingId;
  final String customerName;
  final String serviceName;
  final int position;
  final String status;
  final int waitMinutes;

  QueueItem({
    required this.bookingId,
    required this.customerName,
    required this.serviceName,
    required this.position,
    required this.status,
    required this.waitMinutes,
  });

  factory QueueItem.fromJson(Map<String, dynamic> json) {
    return QueueItem(
      bookingId: json['bookingId'] ?? '',
      customerName: json['customerName'] ?? '',
      serviceName: json['serviceName'] ?? '',
      position: json['position'] ?? 0,
      status: json['status'] ?? 'waiting',
      waitMinutes: json['waitMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'customerName': customerName,
      'serviceName': serviceName,
      'position': position,
      'status': status,
      'waitMinutes': waitMinutes,
    };
  }
}

class QueueModel {
  final String businessId;
  final String currentServingToken;
  final String currentServingName;
  final String currentServingService;
  final int totalWaiting;
  final int avgWaitMinutes;
  final List<QueueItem> items;

  QueueModel({
    required this.businessId,
    required this.currentServingToken,
    this.currentServingName = 'None',
    this.currentServingService = '-',
    required this.totalWaiting,
    required this.avgWaitMinutes,
    required this.items,
  });

  factory QueueModel.fromJson(Map<String, dynamic> json) {
    return QueueModel(
      businessId: json['businessId'] ?? '',
      currentServingToken: json['currentServingToken'] ?? '-',
      currentServingName: json['currentServingName'] ?? 'None',
      currentServingService: json['currentServingService'] ?? '-',
      totalWaiting: json['totalWaiting'] ?? 0,
      avgWaitMinutes: json['avgWaitMinutes'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => QueueItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'currentServingToken': currentServingToken,
      'currentServingName': currentServingName,
      'currentServingService': currentServingService,
      'totalWaiting': totalWaiting,
      'avgWaitMinutes': avgWaitMinutes,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
