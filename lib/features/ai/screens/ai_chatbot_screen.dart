import 'package:flutter/material.dart';
import 'ai_queue_bot_screen.dart';

// AIChatbotScreen is an alias for AIQueueBotScreen
// The router and other files import this class name
class AIChatbotScreen extends StatelessWidget {
  const AIChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AIQueueBotScreen();
  }
}
