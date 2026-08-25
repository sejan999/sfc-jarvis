import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// SharedPreferences key under which user-entered keys are stored.
  static const String prefKeyName = 'gemini_api_key';

  /// Stable default model for the google_generative_ai SDK.
  static const String fallbackModel = 'gemini-1.5-flash';

  /// Whether a usable API key has been provided.
  bool get isConfigured =>
      _apiKey.trim().isNotEmpty && _apiKey.trim() != placeholderKeys;

  /// Hot-swaps the API key at runtime (from the in-app settings dialog)
  /// and rebuilds the conversation session synchronously.
  void updateApiKey(String apiKey) {
    _apiKey = apiKey.trim();
    _chat = _createChatSession();
    _sessionKey = _apiKey;
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

  /// The credential the current [_chat] session was built with.
  String? _sessionKey;

  void _ensureConfigured() {
    if (!isConfigured) {
      throw GeminiException(
        'Gemini API key is not configured. Tap the gear icon to set your key.',
      );
    }
  }

  /// Re-reads the freshest credential before EVERY request.
  /// Priority: user-entered key (SharedPreferences) -> dotenv/env key.
  Future<String> _latestApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefKeyName)?.trim();
      if (saved != null && saved.isNotEmpty && saved != placeholderKeys) {
        return saved;
      }
    } catch (_) {/* prefs unavailable — fall back to in-memory/dotenv key */}
    return _apiKey;
  }

  /// Rebuilds the chat session whenever the active key has changed,
  /// picking up new credentials while preserving multi-turn behavior.
  void _ensureSession(String key) {
    if (_sessionKey != key) {
      debugPrint('[SFC Jarvis] API key changed — rebuilding chat session.');
      _apiKey = key;
      _chat = _createChatSession();
      _sessionKey = key;
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

  /// Maps SDK/network failures to detailed, actionable messages.
  String _explain(Object error) {
    if (error is GenerativeAIException) {
      debugPrint('[SFC Jarvis] Gemini API error: ${error.message}');
      final m = error.message.toLowerCase();
      if (m.contains('api key') ||
          m.contains('api_key') ||
          m.contains('permission denied') ||
          m.contains('unauthenticated') ||
          m.contains('401') ||
          m.contains('403')) {
        return 'Invalid or unauthorized Gemini API key: ${error.message} '
            '(Tap the gear icon to update it.)';
      }
      if (m.contains('quota') ||
          m.contains('resource_exhausted') ||
          m.contains('429')) {
        return 'Gemini quota exceeded: ${error.message}';
      }
      if (m.contains('404') || m.contains('not found')) {
        return 'Gemini model "$_model" not available for this key: '
            '${error.message}';
      }
      if (m.contains('500') || m.contains('503') || m.contains('unavailable')) {
        return 'Gemini service temporarily unavailable: ${error.message}';
      }
      return 'Gemini API error: ${error.message}';
    }
    debugPrint('[SFC Jarvis] Gemini transport error: $error');
    final s = error.toString().toLowerCase();
    if (s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('connection')) {
      return 'Network error reaching Gemini — check internet connectivity. '
          '($error)';
    }
    return 'Gemini request failed: $error';
  }

  /// Sends [prompt] to Gemini with full conversational context.
  /// Returns Jarvis's textual reply.
  Future<String> sendMessage(String prompt) async {
    _ensureConfigured();
    final key = await _latestApiKey();
    _ensureSession(key);
    try {
      final response = await _chat.sendMessage(Content.text(prompt));
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw GeminiException('Empty response from $_model');
      }
      return text.trim();
    } on GeminiException {
      rethrow;
    } on GenerativeAIException catch (e) {
      throw GeminiException(_explain(e));
    } catch (e) {
      throw GeminiException(_explain(e));
    }
  }

  /// One-shot synthesis call (used by web search summarization).
  Future<String> synthesize(String prompt) async {
    _ensureConfigured();
    final key = await _latestApiKey();
    try {
      final model = GenerativeModel(
        model: _model,
        apiKey: key,
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
    } on GeminiException {
      rethrow;
    } on GenerativeAIException catch (e) {
      throw GeminiException(_explain(e));
    } catch (e) {
      throw GeminiException(_explain(e));
    }
  }

  /// Resets conversation context (new session).
  void resetSession() => _chat = _createChatSession();
}