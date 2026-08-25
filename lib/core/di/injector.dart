import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/assistant/data/datasources/gemini_datasource.dart';
import '../../features/assistant/data/repositories/assistant_repository_impl.dart';
import '../../features/assistant/domain/repositories/assistant_repository.dart';
import '../../features/commands/device_action_service.dart';
import '../../features/search/web_search_service.dart';
import '../../features/voice/services/speech_service.dart';
import '../../features/voice/services/tts_service.dart';

/// Lightweight service locator wiring the whole dependency graph.
///
/// Kept intentionally simple (no codegen) — swap for get_it/Riverpod
/// if the project scales.
class Injector {
  Injector._();

  static const String apiKeyPrefKey = 'gemini_api_key';

  static late final GeminiDatasource geminiDatasource;
  static late final AssistantRepository assistantRepository;
  static late final SpeechService speechService;
  static late final TTSService ttsService;
  static late final WebSearchService webSearchService;
  static late final DeviceActionService deviceActionService;

  /// Whether a usable Gemini API key is currently loaded.
  static bool get isConfigured => geminiDatasource.isConfigured;

  /// Persists [key] locally and hot-swaps it into the Gemini datasource.
  /// An empty [key] clears the stored credential.
  static Future<void> applyApiKey(String key) async {
    final trimmed = key.trim();
    geminiDatasource.updateApiKey(trimmed);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (trimmed.isEmpty) {
        await prefs.remove(apiKeyPrefKey);
      } else {
        await prefs.setString(apiKeyPrefKey, trimmed);
      }
    } catch (_) {/* persistence failure must never crash the UI */}
  }

  /// Initializes all services without blocking or throwing — a missing
  /// API key is tolerated so the UI can prompt the user in-app instead.
  static void initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final model = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.0-flash';

    geminiDatasource = GeminiDatasource(apiKey: apiKey, model: model);
    assistantRepository = AssistantRepositoryImpl(geminiDatasource);
    speechService = SpeechService();
    ttsService = TTSService();
    webSearchService = WebSearchService(repository: assistantRepository);
    deviceActionService = DeviceActionService();
  }
}