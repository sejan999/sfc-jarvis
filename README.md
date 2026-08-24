# SFC Jarvis 🤖

A futuristic, hands-free mobile AI assistant built with **Flutter**.
Dark HUD/Jarvis aesthetic with a reactive neon voice orb, powered by
**Google Gemini**, real-time **Speech-to-Text / Text-to-Speech**, live
**web search synthesis**, and **voice-driven phone automation**.

---

## ✨ Features

| Feature | Details |
|---|---|
| 🎙️ Voice Interaction | `speech_to_text` STT + `flutter_tts` with Jarvis-tuned pitch/rate |
| 🔮 Reactive Orb UI | Animated HUD orb: breathing idle glow, waveform rings while listening/speaking, rotating arc while processing |
| 🧠 Conversational AI | Google Gemini (`google_generative_ai`) with multi-turn context and the SFC Jarvis system persona |
| 🌐 Voice Web Search | Say *"Jarvis, search for ..."* — DuckDuckGo Instant Answer context is synthesized by Gemini and spoken back |
| ⚡ Phone Automation | Open apps/settings, place calls, send SMS drafts, toggle flashlight (native platform channel), set session reminders |
| ♻️ Hands-Free Loop | Toggle hands-free mode: listen → parse → act → speak → repeat |

---

## 🏗 Architecture

Feature-first Clean Architecture with **BLoC** state management:

```
lib/
├── main.dart                          # Entrypoint (dotenv + DI + BlocProvider)
├── core/
│   ├── constants/app_constants.dart   # Persona, aliases, triggers, TTS tuning
│   ├── theme/app_theme.dart           # Neon cyan/blue dark HUD theme
│   └── di/injector.dart               # Dependency graph wiring
└── features/
    ├── assistant/
    │   ├── data/                      # Gemini datasource, repository impl, models
    │   ├── domain/                    # Entities (ParsedCommand, SearchResult), repo contract
    │   └── presentation/
    │       ├── bloc/assistant_bloc.dart  # Central orchestration loop
    │       └── screens/home_screen.dart  # HUD screen
    ├── commands/                      # Command parser + device action service
    ├── search/                        # Web search service (DDG + Gemini synthesis)
    ├── voice/                         # SpeechService (STT) + TTSService
    └── widgets/                       # OrbWidget, MessageBubble
```

### Command routing pipeline

```
Voice input → CommandParser
   ├─ Device action intent  → DeviceActionService (url_launcher / MethodChannel)
   ├─ Web search intent     → WebSearchService → Gemini synthesis → TTS
   └─ Conversation          → AssistantRepository → Gemini chat → TTS
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.19 (stable)
- Android SDK 34, minSdk 23
- A Google Gemini API key — [get one free](https://aistudio.google.com/app/apikey)

### Setup

```bash
# 1. Install dependencies
flutter pub get

# 2. Configure environment
cp .env.example .env
# then edit .env and set GEMINI_API_KEY=your_real_key

# 3. Run on a device (mic required)
flutter run
```

> ⚠️ The `.env` file is bundled as an asset; never commit the real key.

### Example voice commands

- *"Jarvis, what's the weather like today?"* → LLM conversation
- *"Jarvis, search for latest SpaceX launch"* → web search + spoken summary
- *"Open YouTube"* / *"Open settings"* → app/system intent
- *"Call 555-0123"* → dialer
- *"Send text to John"* → SMS draft
- *"Toggle the flashlight"* → native torch control

---

## 🔐 Android Permissions

Configured in `android/app/src/main/AndroidManifest.xml`:
`RECORD_AUDIO`, `INTERNET`, `CALL_PHONE`, `SEND_SMS`, `BLUETOOTH`,
`BLUETOOTH_CONNECT`, `CAMERA` (flashlight), `QUERY_ALL_PACKAGES`.

Runtime permission for the microphone is requested automatically on first use.

---

## 🛠 CI/CD (Codemagic)

A ready-to-use pipeline lives in [`codemagic.yaml`](codemagic.yaml):

1. `flutter pub get` → analyze → test
2. Builds a single universal release APK (debug-keystore signed by default)
3. Publishes artifacts & email notifications

No external Codemagic variable groups are required. If you want your Gemini
key baked into CI builds, commit a `.env` privately or add it as a secret
variable yourself — otherwise the app will simply surface a friendly
"API key not configured" message at runtime.

---

## 🧭 Roadmap ideas
- True wake-word detection ("Hey Jarvis") via Porcupine/sherpa-onnx
- Persistent reminders with local notifications
- Contact resolution for "Call John" via contacts plugin
- Multi-language STT/TTS locales