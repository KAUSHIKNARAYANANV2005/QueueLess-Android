import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/ai/services/gemini_service.dart';
import '../../../shared/widgets/chat_bubble.dart';

class AIQueueBotScreen extends StatefulWidget {
  const AIQueueBotScreen({super.key});

  @override
  State<AIQueueBotScreen> createState() => _AIQueueBotScreenState();
}

class _AIQueueBotScreenState extends State<AIQueueBotScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _geminiService = GeminiService.instance;
  bool _isTyping = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Hi! I\'m **QueueBot** 🤖\n\nI can help you:\n• Book appointments\n• Check queue status\n• Find nearby services\n• Answer your questions\n\nWhat would you like to do today?',
      'time': DateTime.now(),
    },
  ];

  final List<String> _quickReplies = [
    'Book an appointment',
    'Check my queue',
    'Find a clinic near me',
    'What\'s the wait time?',
    'Cancel a booking',
  ];

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? quickReply]) async {
    final text = quickReply ?? _messageCtrl.text.trim();
    if (text.isEmpty) return;
    _messageCtrl.clear();

    setState(() {
      _messages.add({'isUser': true, 'text': text, 'time': DateTime.now()});
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final history = _messages
          .map((m) => {'role': m['isUser'] as bool ? 'user' : 'model', 'content': m['text'] as String})
          .toList();
      final result = await _geminiService.sendMessage(text, history);
      final response = (result['message'] as String?) ?? 'How can I help you?';
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({'isUser': false, 'text': response, 'time': DateTime.now()});
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({'isUser': false, 'text': 'Sorry, I couldn\'t process that. Please try again.', 'time': DateTime.now()});
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        child: Column(
          children: [
            // AppBar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      key: const Key('chatbot_back_btn'),
                      onTap: () {
                        if (context.canPop()) context.pop();
                        else context.go('/home');
                      },
                      child: Container(width: 36, height: 36, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16)),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 24)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('QueueBot', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                      Row(children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.tealSuccess, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('Powered by Gemini AI', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ]),
                    ])),
                    IconButton(icon: const Icon(Icons.more_vert_rounded, color: Colors.white), onPressed: () {}),
                  ],
                ),
              ),
            ),
            // Chat
            Expanded(
              child: Container(
                decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == _messages.length) {
                            return ChatBubble(
                              message: '...',
                              isUser: false,
                              timestamp: DateTime.now(),
                              isLoading: true,
                            );
                          }
                          final msg = _messages[i];
                          return ChatBubble(
                            message: msg['text'] as String,
                            isUser: msg['isUser'] as bool,
                            timestamp: (msg['time'] as DateTime?) ?? DateTime.now(),
                          );
                        },
                      ),
                    ),
                    // Quick replies
                    if (_messages.length <= 2)
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _quickReplies.length,
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => _sendMessage(_quickReplies[i]),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.full), border: Border.all(color: AppColors.primary), boxShadow: AppShadows.e1),
                              child: Text(_quickReplies[i], style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Input
                    Padding(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + MediaQuery.of(context).padding.bottom),
                      child: Row(children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.full), boxShadow: AppShadows.e1),
                            child: TextField(
                              controller: _messageCtrl,
                              textInputAction: TextInputAction.send,
                              onSubmitted: _sendMessage,
                              decoration: InputDecoration(
                                hintText: 'Ask QueueBot anything...',
                                hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                prefixIcon: const Icon(Icons.auto_fix_high_rounded, color: AppColors.primary, size: 20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _sendMessage(),
                          child: Container(
                            width: 48, height: 48,
                            decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle, boxShadow: AppShadows.e2),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
