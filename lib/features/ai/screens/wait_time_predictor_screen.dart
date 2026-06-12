import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/ai/services/ml_prediction_service.dart';

class WaitTimePredictorScreen extends StatefulWidget {
  const WaitTimePredictorScreen({super.key});

  @override
  State<WaitTimePredictorScreen> createState() => _WaitTimePredictorScreenState();
}

class _WaitTimePredictorScreenState extends State<WaitTimePredictorScreen> {
  final _predictor = MLPredictionService();
  int _predictedWait = 0;
  bool _loading = false;
  
  String _selectedService = 'General Consultation';
  int _selectedDay = DateTime.now().weekday;
  int _selectedHour = DateTime.now().hour;
  int _queueLength = 5;

  final List<String> _services = ['General Consultation', 'Blood Test', 'ECG', 'Haircut', 'Spa Treatment'];
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  Future<void> _predict() async {
    setState(() => _loading = true);
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    final result = await _predictor.predictWaitTime(
      _selectedDay,
      _selectedHour,
      _queueLength,
      _selectedService,
    );
    final waitTime = (result['predicted_minutes'] as int?) ?? 15;
    if (mounted) setState(() { _predictedWait = waitTime; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wait Time Predictor'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppGradients.teal, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.e2),
              child: Column(children: [
                const Icon(Icons.timer_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                Text(_loading ? 'Calculating...' : _predictedWait == 0 ? 'Press Predict' : '~$_predictedWait min', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('ML-Powered Wait Time Estimate', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 24),
            // Selectors
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.e1),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Prediction Parameters', style: AppTextStyles.h4),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  decoration: const InputDecoration(labelText: 'Select Service', border: OutlineInputBorder()),
                  items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedService = v ?? 'General Consultation'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _selectedDay,
                  decoration: const InputDecoration(labelText: 'Day of Week', border: OutlineInputBorder()),
                  items: List.generate(7, (i) => DropdownMenuItem(value: i + 1, child: Text(_days[i]))),
                  onChanged: (v) => setState(() => _selectedDay = v ?? 1),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _selectedHour,
                  decoration: const InputDecoration(labelText: 'Time of Day', border: OutlineInputBorder()),
                  items: List.generate(13, (i) => DropdownMenuItem(value: i + 8, child: Text('${i + 8}:00'))),
                  onChanged: (v) => setState(() => _selectedHour = v ?? 9),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('Current Queue Length: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.remove_circle_outline), color: AppColors.primary,
                      onPressed: () => setState(() => _queueLength = (_queueLength - 1).clamp(0, 50))),
                  Text('$_queueLength', style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                  IconButton(icon: const Icon(Icons.add_circle_outline), color: AppColors.primary,
                      onPressed: () => setState(() => _queueLength = (_queueLength + 1).clamp(0, 50))),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _loading ? null : _predict,
              icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              label: Text(_loading ? 'Running ML Model...' : 'Predict Wait Time', style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
            )),
          ],
        ),
      ),
    );
  }
}
