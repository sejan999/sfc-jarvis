import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  static late final AssistantRepository assistantRepository;
  static late final SpeechService speechService;
  static late final TTSService ttsService;
  static late final WebSearchService webSearchService;
  static late final DeviceActionService deviceActionService;

  /// Initializes all services. Call once from main() after dotenv load.
  static void initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final model = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.0-flash';

    final gemini = GeminiDatasource(apiKey: apiKey, model: model);
    assistantRepository = AssistantRepositoryImpl(gemini);
    speechService = SpeechService();
    ttsService = TTSService();
    webSearchService = WebSearchService(repository: assistantRepository);
    deviceActionService = DeviceActionService();
  }
}