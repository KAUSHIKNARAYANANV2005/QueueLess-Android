import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/ai/services/gemini_service.dart';

class VoiceBookingScreen extends StatefulWidget {
  const VoiceBookingScreen({super.key});

  @override
  State<VoiceBookingScreen> createState() => _VoiceBookingScreenState();
}

class _VoiceBookingScreenState extends State<VoiceBookingScreen>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _handleVoiceInput() async {
    setState(() => _isListening = true);
    
    // Simulate speech to text delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() => _isListening = false);

    // Show text input fallback since web/desktop doesn't support speech_to_text well
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Voice Input Unavailable'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Voice recognition is currently disabled. Please type your request:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'e.g., Book Dr. Sharma tomorrow at 10 AM',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Send to QueueBot'),
            ),
          ],
        );
      },
    );

    if (text != null && text.isNotEmpty && mounted) {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processing with AI...')));
      
      // Process with Gemini
      final response = await GeminiService.instance.sendMessage(text, []);
      
      if (!mounted) return;
      
      // Show result
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('QueueBot AI'),
          ]),
          content: Text(response['message'] ?? 'Done'),
          actions: [
            if (response['intent'] == 'booking')
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/search');
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('Continue Booking'),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(children: [
                  GestureDetector(onTap: () => context.pop(), child: Container(width: 36, height: 36, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16))),
                  const Expanded(child: Text('Voice Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18), textAlign: TextAlign.center)),
                  const SizedBox(width: 36),
                ]),
              ),
              const Spacer(),
              Text(_isListening ? 'Listening...' : 'Tap to speak', style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 20),
              if (_isListening)
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) => Container(
                    width: 140 + _pulseCtrl.value * 20,
                    height: 140 + _pulseCtrl.value * 20,
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: child,
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() => _isListening = false),
                    child: Container(width: 120, height: 120, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 56)),
                  ),
                )
              else
                GestureDetector(
                  onTap: _handleVoiceInput,
                  child: Container(width: 120, height: 120, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 56)),
                ),
              const SizedBox(height: 24),
              if (_isListening)
                const Text('"Book Dr. Sharma tomorrow at 10 AM..."', style: TextStyle(color: Colors.white, fontSize: 15, fontStyle: FontStyle.italic)),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Text('Try saying:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                    '"Book Dr. Sharma tomorrow at 10 AM"',
                    '"Find a salon near me"',
                    '"Cancel my appointment"',
                  ].map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(AppRadius.full)), child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 12)))).toList()),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
