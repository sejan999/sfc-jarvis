import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'features/assistant/presentation/bloc/assistant_bloc.dart';
import 'features/assistant/presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment (.env). Fail fast with a clear message if missing.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env missing — app still boots; Gemini calls will surface a
    // friendly configuration error via the bloc's error handling.
    debugPrint(
      'WARNING: .env not found. Copy .env.example to .env and add your '
      'GEMINI_API_KEY for full functionality.',
    );
  }

  Injector.initialize();

  // Restore a user-entered API key (if any) before showing the UI.
  // This is a fast local read; it never blocks on network or permissions.
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(Injector.apiKeyPrefKey);
    if (savedKey != null && savedKey.trim().isNotEmpty) {
      Injector.geminiDatasource.updateApiKey(savedKey);
    }
  } catch (_) {/* app still opens even if prefs are unavailable */}

  runApp(const SfcJarvisApp());
}

class SfcJarvisApp extends StatelessWidget {
  const SfcJarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SFC Jarvis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: BlocProvider<AssistantBloc>(
        create: (_) => AssistantBloc(
          speechService: Injector.speechService,
          ttsService: Injector.ttsService,
          repository: Injector.assistantRepository,
          webSearchService: Injector.webSearchService,
          deviceActionService: Injector.deviceActionService,
        ),
        child: const HomeScreen(),
      ),
    );
  }
}