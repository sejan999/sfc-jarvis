import '../../core/constants/app_constants.dart';
import '../assistant/domain/entities/assistant_entities.dart';

/// Parses raw voice transcripts into structured [ParsedCommand] intents.
///
/// Routing priority:
///  1. Device actions (open app, call, sms, flashlight, settings)
///  2. Web search triggers ("Jarvis, search for ...")
///  3. Everything else -> LLM conversation
class CommandParser {
  static final RegExp _callRegex = RegExp(
    r'^(?:jarvis[,\s]*)?(?:please\s+)?(?:make a call to|call|dial|phone)\s+(.+)$',
    caseSensitive: false,
  );

  static final RegExp _smsRegex = RegExp(
    r'^(?:jarvis[,\s]*)?(?:send (?:a )?(?:text|message|sms)(?:\s+to)?|text)\s+(.+)$',
    caseSensitive: false,
  );

  static final RegExp _openAppRegex = RegExp(
    r'^(?:jarvis[,\s]*)?(?:please\s+)?(?:launch|open|start)\s+(?:the\s+)?(.+?)(?:\s+app)?$',
    caseSensitive: false,
  );

  static final RegExp _reminderRegex = RegExp(
    r'^(?:jarvis[,\s]*)?(?:set|create)\s+(?:a\s+)?reminder\s+(?:to|for)\s+(.+)$',
    caseSensitive: false,
  );

  /// Parses [input] into a routed command.
  ParsedCommand parse(String input) {
    final text = input.trim().toLowerCase();

    // --- Flashlight ---
    if (_containsAny(text, ['flashlight', 'torch'])) {
      return ParsedCommand(
        type: IntentType.deviceAction,
        rawInput: input,
        payload: 'toggle_flashlight',
      );
    }

    // --- Phone calls ---
    final callMatch = _callRegex.firstMatch(text);
    if (callMatch != null) {
      return ParsedCommand(
        type: IntentType.deviceAction,
        rawInput: input,
        payload: 'call:${_cleanTarget(callMatch.group(1)!)}',
      );
    }

    // --- SMS ---
    final smsMatch = _smsRegex.firstMatch(text);
    if (smsMatch != null) {
      return ParsedCommand(
        type: IntentType.deviceAction,
        rawInput: input,
        payload: 'sms:${_cleanTarget(smsMatch.group(1)!)}',
      );
    }

    // --- Open apps / settings ---
    final openMatch = _openAppRegex.firstMatch(text);
    if (openMatch != null) {
      final target = openMatch.group(1)!.trim();
      if (_isKnownApp(target)) {
        return ParsedCommand(
          type: IntentType.deviceAction,
          rawInput: input,
          payload: 'open:$target',
        );
      }
    }

    // --- Reminders (spoken confirmation only in v1) ---
    if (_reminderRegex.hasMatch(text)) {
      return ParsedCommand(
        type: IntentType.deviceAction,
        rawInput: input,
        payload: 'reminder:$text',
      );
    }

    // --- Web search ---
    for (final trigger in AppConstants.searchTriggers) {
      if (text.startsWith('jarvis, $trigger') ||
          text.startsWith('jarvis $trigger') ||
          text.contains(trigger)) {
        final query = _extractAfterTrigger(text, trigger);
        if (query.isNotEmpty) {
          return ParsedCommand(
            type: IntentType.webSearch,
            rawInput: input,
            payload: query,
          );
        }
      }
    }

    // --- Default: conversational LLM ---
    return ParsedCommand(
      type: IntentType.conversation,
      rawInput: input,
      payload: input,
    );
  }

  bool _isKnownApp(String target) =>
      AppConstants.appAliases.keys.any((k) => k == target);

  String _cleanTarget(String raw) =>
      raw.replaceAll(RegExp(r'\b(app|now|please)\b'), '').trim();

  bool _containsAny(String text, List<String> keywords) =>
      keywords.any(text.contains);

  String _extractAfterTrigger(String text, String trigger) {
    final idx = text.indexOf(trigger);
    if (idx < 0) return '';
    return text.substring(idx + trigger.length).trim();
  }
}