import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Callbacks emitted by [SpeechService].
typedef SpeechResultCallback = void Function(String text);
typedef SpeechErrorCallback = void Function(String error);
typedef SpeechStatusCallback = void Function(bool listening);

/// Wraps `speech_to_text` with permission handling and stream-style callbacks.
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  /// Whether the device speech recognizer is available.
  bool get isAvailable => _initialized && _speech.isAvailable;

  /// Initializes the underlying recognizer. Requests mic permission first.
  Future<bool> initialize() async {
    if (_initialized) return _speech.isAvailable;

    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) return false;
    }

    try {
      _initialized = await _speech.initialize(
        onError: (error) => _onError?.call(error.errorMsg),
      );
    } catch (_) {
      _initialized = false;
    }
    return _initialized;
  }

  SpeechErrorCallback? _onError;
  SpeechStatusCallback? _onStatus;

  /// Starts listening. Results arrive via callbacks.
  ///
  /// [partialResults] enables live interim transcripts.
  Future<void> listen({
    required SpeechResultCallback onResult,
    required SpeechErrorCallback onError,
    required SpeechStatusCallback onStatus,
    bool partialResults = true,
  }) async {
    _onError = onError;
    _onStatus = onStatus;

    if (!_initialized) {
      final ok = await initialize();
      if (!ok) {
        onError('Speech recognition unavailable. Check microphone permission.');
        return;
      }
    }

    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isNotEmpty) onResult(text);
        // Final recognition ends the session.
        if (result.finalResult) onStatus(false);
      },
      localeId: 'en_US',
      listenOptions: stt.SpeechListenOptions(
        partialResults: partialResults,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      ),
    );
    onStatus(true);
  }

  /// Stops active listening.
  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {/* already stopped */}
    _onStatus?.call(false);
  }

  /// Cancels active listening and discards results.
  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {/* nothing to cancel */}
    _onStatus?.call(false);
  }

  void dispose() => _speech.cancel();
}