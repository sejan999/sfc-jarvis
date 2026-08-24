import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/constants/app_constants.dart';

/// Callback fired when TTS finishes speaking a full utterance.
typedef SpeakCompletionCallback = void Function();

/// Wraps `flutter_tts` with Jarvis-tuned voice settings.
class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _speaking = false;

  /// Whether an utterance is currently being spoken.
  bool get isSpeaking => _speaking;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setPitch(AppConstants.ttsPitch);
      await _tts.setSpeechRate(AppConstants.ttsSpeechRate);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      await _tts.setStartHandler(() => _speaking = true);
      await _tts.setCompletionHandler(() => _speaking = false);
      await _tts.setCancelHandler(() => _speaking = false);
      await _tts.setErrorHandler((_) => _speaking = false);
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  /// Speaks [text] aloud. Returns when the utterance completes.
  Future<void> speak(String text) async {
    if (!_initialized) await initialize();
    if (text.trim().isEmpty) return;
    // Strip markdown artifacts that sound bad when spoken.
    final clean = text
        .replaceAll(RegExp(r'[*_#`>]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    try {
      await _tts.speak(clean);
    } catch (_) {/* TTS engine failure — fail silently, UI still shows text */}
  }

  /// Stops any ongoing speech.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {/* nothing playing */}
    _speaking = false;
  }

  void dispose() => _tts.stop();
}