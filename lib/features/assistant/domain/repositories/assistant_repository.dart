/// Abstract contract for the conversational AI brain.
abstract class AssistantRepository {
  /// Sends a user message with multi-turn context and returns Jarvis's reply.
  Future<String> sendMessage(String message);

  /// Synthesizes a spoken-style answer from raw search context.
  Future<String> synthesizeAnswer(String query, String searchContext);

  /// Clears the conversation history (starts a fresh session).
  void resetConversation();
}