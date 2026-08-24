import 'package:equatable/equatable.dart';

/// Role of a participant in the conversation.
enum ChatRole { user, jarvis, system }

/// A single turn in the conversation with SFC Jarvis.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.timestamp,
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime? timestamp;

  ChatMessage copyWith({String? text}) => ChatMessage(
        id: id,
        role: role,
        text: text ?? this.text,
        timestamp: timestamp,
      );

  factory ChatMessage.user(String text) => ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: ChatRole.user,
        text: text,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.jarvis(String text) => ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: ChatRole.jarvis,
        text: text,
        timestamp: DateTime.now(),
      );

  @override
  List<Object?> get props => [id, role, text];
}