import 'package:http/http.dart' as http;
import 'dart:convert';

class MLPredictionService {
  static const String _baseUrl = 'https://your-ml-api.com/predict';

  Future<Map<String, dynamic>> predictWaitTime(
      int dayOfWeek, int hour, int queueLength, String serviceType) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'day_of_week': dayOfWeek,
          'hour': hour,
          'queue_length': queueLength,
          'service_type': serviceType,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    // Local estimation fallback
    return _estimateLocally(dayOfWeek, hour, queueLength, serviceType);
  }

  Map<String, dynamic> _estimateLocally(
      int dayOfWeek, int hour, int queueLength, String serviceType) {
    // Hour factor: peak hours 10-12 and 17-20
    double hourFactor = 1.0;
    if ((hour >= 10 && hour <= 12) || (hour >= 17 && hour <= 20)) {
      hourFactor = 1.4;
    } else if (hour >= 13 && hour <= 15) {
      hourFactor = 0.8;
    }

    // Day factor: Mon-Fri busier
    double dayFactor = dayOfWeek < 5 ? 1.0 : 1.3;

    // Service duration base
    int baseMinutes = switch (serviceType) {
      'Haircut' => 25,
      'Consultation' => 15,
      'Full Checkup' => 45,
      'Massage' => 60,
      'Facial' => 50,
      _ => 20,
    };

    final predicted = ((queueLength * baseMinutes + hour) * hourFactor * dayFactor).round();

    // Best time suggestion
    String bestTime;
    if (hour < 9) {
      bestTime = '9:00 AM - less crowded';
    } else if (hour >= 10 && hour <= 12) {
      bestTime = '2:00 PM - post-lunch lull';
    } else if (hour >= 13 && hour <= 16) {
      bestTime = 'Now is a good time!';
    } else {
      bestTime = 'Tomorrow at 9:00 AM';
    }

    final confidence = (75 + (10 - queueLength).clamp(0, 10) * 2).clamp(60, 95);

    return {
      'predicted_minutes': predicted,
      'confidence': confidence,
      'suggestion': predicted > 30
          ? 'High wait time. Consider booking for later.'
          : 'Short wait. Good time to visit!',
      'best_time': bestTime,
      'hourly_data': List.generate(
          12,
          (i) => {
                'hour': '${9 + i}:00',
                'wait': ((baseMinutes + i * 3) * (i >= 1 && i <= 3 ? 1.5 : 1.0)).round(),
              }),
    };
  }
}
