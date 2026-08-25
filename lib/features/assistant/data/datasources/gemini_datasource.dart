import 'package:google_generative_ai/google_generative_ai.dart';

/// Exception thrown when the Gemini backend fails.
class GeminiException implements Exception {
  GeminiException(this.message);
  final String message;

  @override
  String toString() => 'GeminiException: $message';
}

/// Remote datasource wrapping the Google Generative AI SDK.
///
/// Maintains a multi-turn chat session with the SFC Jarvis system persona.
class GeminiDatasource {
  GeminiDatasource({required String apiKey, required String model})
      : _apiKey = apiKey,
        _model = model {
    // NOTE: intentionally does NOT throw when the key is missing —
    // the app must still start so the user can enter a key in-app.
    // Callers check [isConfigured] before making network calls.
    _chat = _createChatSession();
  }

  static const String placeholderKeys = 'your_gemini_api_key_here';

  /// Whether a usable API key has been provided.
  bool get isConfigured =>
      _apiKey.trim().isNotEmpty && _apiKey.trim() != placeholderKeys;

  /// Hot-swaps the API key at runtime (from the in-app settings dialog)
  /// and resets the conversation session.
  void updateApiKey(String apiKey) {
    _apiKey = apiKey.trim();
    _chat = _createChatSession();
  }

  static const String _systemPersona =
      'You are SFC Jarvis, a high-tech, loyal, efficient AI assistant inspired '
      "by Tony Stark's J.A.R.V.I.S. You are calm, witty, precise and professional. "
      'Keep spoken answers concise (2-4 sentences) because they are read aloud via TTS. '
      'Address the user respectfully ("Sir" is acceptable). Never mention being a '
      'language model; you are SFC Jarvis. If you lack real-time data, say so and '
      'suggest the user say "Jarvis, search for <topic>".';

  String _apiKey;
  final String _model;
  late ChatSession _chat;

  void _ensureConfigured() {
    if (!isConfigured) {
      throw GeminiException(
        'Gemini API key is not configured. Tap the gear icon to set your key.',
      );
    }
  }

  ChatSession _createChatSession() {
    final generativeModel = GenerativeModel(
      model: _model,
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemPersona),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 512,
      ),
    );
    return generativeModel.startChat();
  }

  /// Sends [prompt] to Gemini with full conversational context.
  /// Returns Jarvis's textual reply.
  Future<String> sendMessage(String prompt) async {
    _ensureConfigured();
    try {
      final response = await _chat.sendMessage(Content.text(prompt));
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw GeminiException('Empty response from $_model');
      }
      return text.trim();
    } on GeminiException {
      rethrow;
    } catch (e) {
      throw GeminiException('Gemini request failed: $e');
    }
  }

  /// One-shot synthesis call (used by web search summarization).
  Future<String> synthesize(String prompt) async {
    _ensureConfigured();
    try {
      final model = GenerativeModel(
        model: _model,
        apiKey: _apiKey,
        systemInstruction: Content.system(
          'You are SFC Jarvis. Summarize the provided search context into a '
          'concise, natural spoken answer (2-4 sentences). No markdown.',
        ),
      );
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw GeminiException('Empty synthesis response');
      }
      return text.trim();
    } catch (e) {
      throw GeminiException('Gemini synthesis failed: $e');
    }
  }

  /// Resets conversation context (new session).
  void resetSession() => _chat = _createChatSession();
}