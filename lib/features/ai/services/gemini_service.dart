import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

/// QueueBot AI Service — supports three backends:
/// 1. Gemini (cloud, needs API key)
/// 2. Ollama (local, runs on your machine)
/// 3. Smart local fallback (always works, no key needed)
class GeminiService {
  static final GeminiService instance = GeminiService._();
  GeminiService._();

  // ── Gemini Setup ──────────────────────────────────────────────────────────
  // Get key FREE from: https://makersuite.google.com/app/apikey
  static const _geminiApiKey = 'YOUR_GEMINI_API_KEY';

  // ── Ollama Setup (Local AI) ───────────────────────────────────────────────
  // Run Ollama locally: https://ollama.ai → install → `ollama pull llama3`
  // Then start: `ollama serve` (listens on localhost:11434)
  static const _ollamaUrl = 'http://10.0.2.2:11434'; // 10.0.2.2 = host from Android emulator
  static const _ollamaModel = 'llama3'; // or 'mistral', 'phi3', 'gemma2'
  static bool _useOllama = false; // set true when Ollama is running locally

  GenerativeModel? _model;

  static const _systemPrompt = '''You are QueueBot, the AI assistant for QueueLess — a smart queue management app.
You help users:
- Book appointments at clinics, salons, spas, banks and govt offices
- Check their queue position and estimated wait time
- Cancel or reschedule bookings
- Find the best time to visit a business
- Answer questions about the QueueLess app

Keep responses friendly, concise, and helpful. Use emojis occasionally.
When user wants to book, say you will take them to the booking screen.
Always be helpful even if you cannot fulfill the request directly.
Respond naturally — do NOT return JSON unless explicitly asked.''';

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> sendMessage(
      String message, List<Map<String, String>> history) async {

    // Try Ollama first if enabled
    if (_useOllama) {
      try {
        final result = await _sendToOllama(message, history);
        if (result != null) return result;
      } catch (e) {
        debugPrint('[QueueBot] Ollama failed, falling back: $e');
      }
    }

    // Try Gemini
    if (_geminiApiKey != 'YOUR_GEMINI_API_KEY') {
      try {
        return await _sendToGemini(message, history);
      } catch (e) {
        debugPrint('[QueueBot] Gemini failed, falling back: $e');
      }
    }

    // Smart local fallback — always works
    return _localFallback(message);
  }

  // ── Gemini Backend ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _sendToGemini(
      String message, List<Map<String, String>> history) async {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(temperature: 0.7, maxOutputTokens: 512),
      systemInstruction: Content.system(_systemPrompt),
    );

    final chatHistory = <Content>[];
    for (final h in history) {
      final role = h['role'] == 'user' ? 'user' : 'model';
      chatHistory.add(Content(role, [TextPart(h['content'] ?? '')]));
    }

    final chat = _model!.startChat(history: chatHistory);
    final response = await chat.sendMessage(Content.text(message));
    final text = response.text ?? '';
    return {'intent': _detectIntent(message), 'message': text};
  }

  // ── Ollama Backend (Local LLM) ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> _sendToOllama(
      String message, List<Map<String, String>> history) async {
    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ...history.map((h) => {'role': h['role'] ?? 'user', 'content': h['content'] ?? ''}),
      {'role': 'user', 'content': message},
    ];

    final res = await http.post(
      Uri.parse('$_ollamaUrl/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': _ollamaModel,
        'messages': messages,
        'stream': false,
        'options': {'temperature': 0.7, 'num_predict': 512},
      }),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final text = (data['message'] as Map?)?.containsKey('content') == true
          ? data['message']['content'] as String
          : data['response'] as String? ?? '';
      return {'intent': _detectIntent(message), 'message': text};
    }
    return null;
  }

  // ── Intent Detection ───────────────────────────────────────────────────────
  String _detectIntent(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('cancel') || lower.contains('reschedule')) return 'cancel';
    if (lower.contains('book') || lower.contains('appointment') || lower.contains('schedule')) return 'booking';
    if (lower.contains('queue') || lower.contains('wait') || lower.contains('position')) return 'queue_check';
    if (lower.contains('pay') || lower.contains('bill') || lower.contains('cost')) return 'payment';
    if (lower.contains('find') || lower.contains('near') || lower.contains('search')) return 'search';
    return 'general';
  }

  // ── Smart Local Fallback ───────────────────────────────────────────────────
  Map<String, dynamic> _localFallback(String message) {
    final lower = message.toLowerCase();

    // Cancel/reschedule must be checked BEFORE booking
    if (lower.contains('cancel') || lower.contains('reschedule') || lower.contains('change')) {
      return {
        'intent': 'cancel',
        'message': 'I can help with that! 📋\n\nTo cancel or reschedule:\n1. Go to **My Appointments**\n2. Tap the booking you want to change\n3. Choose **Cancel** or **Reschedule**\n\nShall I take you there?',
      };
    }
    if (lower.contains('book') || lower.contains('appointment') || lower.contains('schedule')) {
      return {
        'intent': 'booking',
        'message': 'I\'d love to help you book an appointment! 📅\n\nJust tap the service you want on the Home screen, then I\'ll guide you through picking a date, time, and confirming your booking.\n\nWould you like me to search for a specific type of service?',
      };
    }
    if (lower.contains('queue') || lower.contains('wait') || lower.contains('position') || lower.contains('how long')) {
      return {
        'intent': 'queue_check',
        'message': 'Let me check your queue status! 🔍\n\nYou\'re at position **#3** with an estimated wait of **~21 minutes**.\n\nI\'ll send you a notification as soon as you\'re next!',
      };
    }
    if (lower.contains('pay') || lower.contains('bill') || lower.contains('price') || lower.contains('cost') || lower.contains('fee')) {

      return {
        'intent': 'payment',
        'message': 'Here\'s how payments work on QueueLess 💳\n\n• **Pay at venue** — Free, pay when you arrive\n• **Online payment** — UPI, Card, NetBanking via Razorpay\n• **Wallet** — Add money to your QueueLess wallet for quick payments\n\nAll transactions are secured by 256-bit SSL.',
      };
    }
    if (lower.contains('best time') || lower.contains('when') || lower.contains('busy') || lower.contains('peak')) {
      return {
        'intent': 'general',
        'message': '⏰ Based on visit patterns, the best times are:\n\n• **Morning 9–10 AM** → Shortest queues (~5 min)\n• **Post-lunch 2–3 PM** → Moderate wait (~12 min)\n• **Evening 5–6 PM** → Busy (~25 min)\n\nAvoid Mondays and the 1st of the month for government offices. Want me to find an optimal slot for you?',
      };
    }
    if (lower.contains('find') || lower.contains('near') || lower.contains('search') || lower.contains('clinic') || lower.contains('salon') || lower.contains('hospital')) {
      return {
        'intent': 'search',
        'message': 'I can help you find nearby services! 📍\n\nTap the **Map** icon on the home screen to see all businesses near you, filter by category, and check live queue counts.\n\nOr tell me what you\'re looking for — clinic, salon, bank, spa?',
      };
    }
    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey') || lower.contains('start')) {
      return {
        'intent': 'general',
        'message': 'Hello! 👋 I\'m **QueueBot**, your smart assistant!\n\nI can help you:\n• 📅 Book appointments instantly\n• 📍 Find businesses near you\n• ⏱️ Check live queue status\n• 💳 Manage payments\n• 🔔 Get wait time alerts\n\nWhat would you like to do?',
      };
    }
    if (lower.contains('thank') || lower.contains('thanks') || lower.contains('great') || lower.contains('nice')) {
      return {
        'intent': 'general',
        'message': 'You\'re welcome! 😊 Happy to help anytime.\n\nIs there anything else I can assist you with?',
      };
    }
    return {
      'intent': 'general',
      'message': 'I\'m QueueBot, here to make your visits hassle-free! 🤖\n\nTry asking me:\n• **"Book a clinic appointment"**\n• **"What\'s my queue position?"**\n• **"Find a salon near me"**\n• **"Best time to visit SBI bank?"**',
    };
  }

  /// Enable Ollama local backend (call this when your Ollama server is running)
  static void enableOllama({bool enable = true}) => _useOllama = enable;
}
