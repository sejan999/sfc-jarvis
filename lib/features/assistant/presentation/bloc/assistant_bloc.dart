import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../commands/command_parser.dart';
import '../../../commands/device_action_service.dart';
import '../../../search/web_search_service.dart';
import '../../../voice/services/speech_service.dart';
import '../../../voice/services/tts_service.dart';
import '../../data/models/chat_message.dart';
import '../../domain/entities/assistant_entities.dart';
import '../../domain/repositories/assistant_repository.dart';

// ============================== EVENTS ==============================

abstract class AssistantEvent extends Equatable {
  const AssistantEvent();

  @override
  List<Object?> get props => [];
}

/// Toggle hands-free wake/listening mode on or off.
class AssistantToggleHandsFree extends AssistantEvent {
  const AssistantToggleHandsFree(this.enabled);
  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

/// Start a single listening session (orb tap).
class AssistantStartListening extends AssistantEvent {
  const AssistantStartListening();
}

/// Stop the current listening session.
class AssistantStopListening extends AssistantEvent {
  const AssistantStopListening();
}

/// A voice transcript was recognized (interim or final).
class AssistantTranscriptReceived extends AssistantEvent {
  const AssistantTranscriptReceived(this.text, {this.isFinal = false});
  final String text;
  final bool isFinal;

  @override
  List<Object?> get props => [text, isFinal];
}

/// Process a finalized user command.
class AssistantProcessCommand extends AssistantEvent {
  const AssistantProcessCommand(this.command);
  final String command;

  @override
  List<Object?> get props => [command];
}

/// TTS finished speaking; resume listening if hands-free is active.
class AssistantSpeechCompleted extends AssistantEvent {
  const AssistantSpeechCompleted();
}

/// Clear conversation history.
class AssistantResetConversation extends AssistantEvent {
  const AssistantResetConversation();
}

// ============================== STATES ==============================

enum AssistantPhase { idle, listening, processing, speaking, error }

abstract class AssistantState extends Equatable {
  const AssistantState({
    this.phase = AssistantPhase.idle,
    this.messages = const [],
    this.interimTranscript = '',
    this.handsFree = false,
    this.errorMessage,
  });

  final AssistantPhase phase;
  final List<ChatMessage> messages;
  final String interimTranscript;
  final bool handsFree;
  final String? errorMessage;

  @override
  List<Object?> get props =>
      [phase, messages, interimTranscript, handsFree, errorMessage];
}

class AssistantInitial extends AssistantState {}

class AssistantUpdated extends AssistantState {
  const AssistantUpdated({
    required super.phase,
    required super.messages,
    super.interimTranscript = '',
    super.handsFree = false,
    super.errorMessage,
  });
}

// =============================== BLOC ===============================

/// Orchestrates the full hands-free loop:
/// listen -> parse -> route (LLM / search / device action) -> speak -> repeat.
class AssistantBloc extends Bloc<AssistantEvent, AssistantState> {
  AssistantBloc({
    required SpeechService speechService,
    required TTSService ttsService,
    required AssistantRepository repository,
    required WebSearchService webSearchService,
    required DeviceActionService deviceActionService,
  })  : _speech = speechService,
        _tts = ttsService,
        _repository = repository,
        _search = webSearchService,
        _actions = deviceActionService,
        super(AssistantInitial()) {
    on<AssistantToggleHandsFree>(_onToggleHandsFree);
    on<AssistantStartListening>(_onStartListening);
    on<AssistantStopListening>(_onStopListening);
    on<AssistantTranscriptReceived>(_onTranscriptReceived);
    on<AssistantProcessCommand>(_onProcessCommand);
    on<AssistantSpeechCompleted>(_onSpeechCompleted);
    on<AssistantResetConversation>(_onResetConversation);
  }

  final SpeechService _speech;
  final TTSService _tts;
  final AssistantRepository _repository;
  final WebSearchService _search;
  final DeviceActionService _actions;
  final CommandParser _parser = CommandParser();

  // ============================ HANDLERS ============================

  Future<void> _onToggleHandsFree(
    AssistantToggleHandsFree event,
    Emitter<AssistantState> emit,
  ) async {
    if (event.enabled) {
      emit(_copyWith(handsFree: true));
      add(const AssistantStartListening());
    } else {
      await _speech.stop();
      await _tts.stop();
      emit(_copyWith(
        handsFree: false,
        phase: AssistantPhase.idle,
      ));
    }
  }

  Future<void> _onStartListening(
    AssistantStartListening event,
    Emitter<AssistantState> emit,
  ) async {
    if (_tts.isSpeaking) return; // don't talk over Jarvis
    emit(_copyWith(phase: AssistantPhase.listening, interimTranscript: ''));

    await _speech.listen(
      onResult: (text) =>
          add(AssistantTranscriptReceived(text)),
      onError: (error) => add(AssistantProcessCommand('')),
      onStatus: (listening) {
        if (!listening) {
          // Session ended without final result handled elsewhere.
        }
      },
    );
  }

  Future<void> _onStopListening(
    AssistantStopListening event,
    Emitter<AssistantState> emit,
  ) async {
    await _speech.stop();
    emit(_copyWith(phase: state.handsFree ? AssistantPhase.idle : AssistantPhase.idle));
  }

  void _onTranscriptReceived(
    AssistantTranscriptReceived event,
    Emitter<AssistantState> emit,
  ) {
    emit(_copyWith(interimTranscript: event.text));
    // Debounce: process once we have a stable transcript. STT emits
    // continuously; treat each update as candidate and process after
    // short silence via timer reset.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1200), () {
      final text = event.text.trim();
      if (text.isNotEmpty) {
        add(AssistantProcessCommand(text));
      } else {
        add(const AssistantStartListening());
      }
    });
  }

  Timer? _debounceTimer;

  Future<void> _onProcessCommand(
    AssistantProcessCommand event,
    Emitter<AssistantState> emit,
  ) async {
    final command = event.command.trim();

    // Empty command (e.g., recognition error): recover gracefully.
    if (command.isEmpty) {
      await _speakAndContinue('I did not catch that, Sir.', emit);
      return;
    }

    await _speech.stop();
    emit(_copyWith(
      phase: AssistantPhase.processing,
      messages: [...state.messages, ChatMessage.user(command)],
      interimTranscript: '',
    ));

    final parsed = _parser.parse(command);

    try {
      switch (parsed.type) {
        case IntentType.deviceAction:
          final result = await _actions.execute(parsed.payload);
          await _respond(result.spokenReply, emit);
          break;

        case IntentType.webSearch:
          final result = await _search.search(parsed.payload);
          await _respond(result.summary, emit);
          break;

        case IntentType.conversation:
        case IntentType.unknown:
          final reply = await _repository.sendMessage(parsed.payload);
          await _respond(reply, emit);
          break;
      }
    } catch (e) {
      await _respond(
        'Apologies Sir, I encountered an error: ${_friendlyError(e)}',
        emit,
        isError: true,
      );
    }
  }

  Future<void> _onSpeechCompleted(
    AssistantSpeechCompleted event,
    Emitter<AssistantState> emit,
  ) async {
    if (state.handsFree) {
      add(const AssistantStartListening());
    } else {
      emit(_copyWith(phase: AssistantPhase.idle));
    }
  }

  Future<void> _onResetConversation(
    AssistantResetConversation event,
    Emitter<AssistantState> emit,
  ) async {
    _repository.resetConversation();
    emit(_copyWith(messages: [], phase: AssistantPhase.idle));
  }

  // ============================= HELPERS =============================

  /// Speaks [reply], appends it to the transcript, then continues the loop.
  Future<void> _respond(
    String reply,
    Emitter<AssistantState> emit, {
    bool isError = false,
  }) async {
    emit(_copyWith(
      phase: AssistantPhase.speaking,
      messages: [...state.messages, ChatMessage.jarvis(reply)],
      errorMessage: isError ? reply : null,
    ));
    await _tts.speak(reply);
    add(const AssistantSpeechCompleted());
  }

  /// Short-circuit helper for immediate spoken feedback.
  Future<void> _speakAndContinue(
    String text,
    Emitter<AssistantState> emit,
  ) async {
    emit(_copyWith(
      phase: AssistantPhase.speaking,
      messages: [...state.messages, ChatMessage.jarvis(text)],
    ));
    await _tts.speak(text);
    add(const AssistantSpeechCompleted());
  }

  AssistantUpdated _copyWith({
    AssistantPhase? phase,
    List<ChatMessage>? messages,
    String? interimTranscript,
    bool? handsFree,
    String? errorMessage,
  }) {
    return AssistantUpdated(
      phase: phase ?? state.phase,
      messages: messages ?? state.messages,
      interimTranscript: interimTranscript ?? state.interimTranscript,
      handsFree: handsFree ?? state.handsFree,
      errorMessage: errorMessage,
    );
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('API_KEY') || msg.contains('api key')) {
      return 'my Gemini API key is not configured.';
    }
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'I cannot reach the network right now.';
    }
    return 'an unexpected fault occurred.';
  }

  @override
  Future<void> close() async {
    _debounceTimer?.cancel();
    _speech.dispose();
    _tts.dispose();
    await super.close();
  }
}