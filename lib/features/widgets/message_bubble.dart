import 'package:flutter/material.dart';

import '../assistant/data/models/chat_message.dart';
import '../../core/theme/app_theme.dart';

/// HUD-styled chat bubble for the conversation transcript.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  bool get _isUser => message.role == ChatRole.user;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: _isUser ? JarvisColors.card : JarvisColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(_isUser ? 16 : 4),
            bottomRight: Radius.circular(_isUser ? 4 : 16),
          ),
          border: Border.all(
            color: (_isUser ? JarvisColors.neonBlue : JarvisColors.neonCyan)
                .withOpacity(0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: (_isUser ? JarvisColors.neonBlue : JarvisColors.neonCyan)
                  .withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isUser ? 'YOU' : 'JARVIS',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
                color: _isUser
                    ? JarvisColors.neonBlue
                    : JarvisColors.neonCyan,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              message.text,
              style: const TextStyle(
                color: JarvisColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}