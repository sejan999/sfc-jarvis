/// Central configuration constants for SFC Jarvis.
class AppConstants {
  AppConstants._();

  /// Jarvis system persona injected into every Gemini conversation.
  static const String jarvisSystemPersona = '''
You are SFC Jarvis, a high-tech, loyal, efficient AI assistant inspired by
Tony Stark's J.A.R.V.I.S. You are calm, witty, precise and professional.
Rules:
- Keep spoken answers concise (2-4 sentences) since they are read aloud via TTS.
- Address the user respectfully (e.g., "Sir" is acceptable).
- Never mention that you are a language model; you are SFC Jarvis.
- If you do not know something or lack real-time data, say so gracefully
  and suggest the user say "Jarvis, search for <topic>" for live information.
''';

  /// Wake-word style prefixes that trigger a web search intent.
  static const List<String> searchTriggers = [
    'search for',
    'search',
    'look up',
    'find out about',
    "what's the latest on",
    'google',
  ];

  /// Known app aliases -> Android package / deep-link targets.
  static const Map<String, String> appAliases = {
    'youtube': 'https://www.youtube.com',
    'camera': 'camera://open',
    'settings': 'android.settings.SETTINGS',
    'wifi settings': 'android.settings.WIFI_SETTINGS',
    'bluetooth settings': 'android.settings.BLUETOOTH_SETTINGS',
    'calculator': 'calculator://open',
    'chrome': 'https://www.google.com',
    'gmail': 'https://mail.google.com',
    'maps': 'https://maps.google.com',
    'whatsapp': 'https://wa.me/',
    'spotify': 'spotify://open',
    'play store': 'https://play.google.com/store',
  };

  /// Method channel used to talk to native Android features.
  static const String deviceChannel = 'sfc_jarvis/device';

  /// TTS voice tuning for the Jarvis persona.
  static const double ttsPitch = 0.9;
  static const double ttsSpeechRate = 0.5;

  /// UI copy.
  static const String appName = 'SFC JARVIS';
  static const String listeningHint = 'Listening... speak your command';
  static const String processingHint = 'Processing...';
  static const String speakingHint = 'Speaking...';
  static const String idleHint = 'Tap the orb or toggle hands-free mode';
}