import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../widgets/message_bubble.dart';
import '../../../widgets/orb_widget.dart';
import '../bloc/assistant_bloc.dart';

/// Main HUD screen: orb, status readout, live transcript and controls.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Gemini API Key',
            icon: Icon(
              Icons.settings_rounded,
              color: Injector.isConfigured
                  ? JarvisColors.neonCyan
                  : JarvisColors.danger,
            ),
            onPressed: () => _showApiKeyDialog(context),
          ),
          IconButton(
            tooltip: 'Reset conversation',
            icon: const Icon(Icons.restart_alt_rounded,
                color: JarvisColors.neonCyan),
            onPressed: () =>
                context.read<AssistantBloc>().add(const AssistantResetConversation()),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.4,
            colors: [
              JarvisColors.neonBlue.withValues(alpha: 0.08),
              JarvisColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Hands-free toggle
              const _HandsFreeToggle(),
              // Live status + transcript
              Expanded(child: _TranscriptPanel()),
              // Orb
              _OrbSection(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================= HANDS-FREE TOGGLE =========================

class _HandsFreeToggle extends StatelessWidget {
  const _HandsFreeToggle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: BlocBuilder<AssistantBloc, AssistantState>(
        builder: (context, state) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: JarvisColors.card,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: JarvisColors.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sensors_rounded,
                      size: 18,
                      color: state.handsFree
                          ? JarvisColors.success
                          : JarvisColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'HANDS-FREE MODE',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                        color: state.handsFree
                            ? JarvisColors.textPrimary
                            : JarvisColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: state.handsFree,
                  onChanged: (value) => context.read<AssistantBloc>().add(
                        AssistantToggleHandsFree(value),
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =========================== TRANSCRIPT PANEL ===========================

class _TranscriptPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssistantBloc, AssistantState>(
      builder: (context, state) {
        final messages = state.messages;
        return ListView.builder(
          reverse: false,
          padding: const EdgeInsets.only(top: 8),
          itemCount:
              messages.length + (state.interimTranscript.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == messages.length) {
              // Live interim transcript while listening.
              return Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: JarvisColors.card.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: JarvisColors.neonCyan.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: JarvisColors.neonCyan,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          state.interimTranscript,
                          style: TextStyle(
                            color: JarvisColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return MessageBubble(message: messages[index]);
          },
        );
      },
    );
  }
}

// ============================== ORB SECTION ==============================

class _OrbSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssistantBloc, AssistantState>(
      builder: (context, state) {
        return Column(
          children: [
            OrbWidget(
              phase: state.phase,
              onTap: () {
                // Gate on API key before starting the voice loop.
                if (!Injector.isConfigured) {
                  _showApiKeyDialog(
                    context,
                    notice:
                        'A Gemini API key is required before Jarvis can think. '
                        'Please enter it to continue.',
                  );
                  return;
                }
                if (state.phase == AssistantPhase.listening) {
                  context
                      .read<AssistantBloc>()
                      .add(const AssistantStopListening());
                } else {
                  context
                      .read<AssistantBloc>()
                      .add(const AssistantStartListening());
                }
              },
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _statusText(state.phase),
                key: ValueKey(state.phase),
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 2,
                  color: _statusColor(state.phase),
                ),
              ),
            ),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 32, right: 32),
                child: Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: JarvisColors.danger,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _statusText(AssistantPhase phase) {
    switch (phase) {
      case AssistantPhase.idle:
        return AppConstants.idleHint.toUpperCase();
      case AssistantPhase.listening:
        return AppConstants.listeningHint.toUpperCase();
      case AssistantPhase.processing:
        return AppConstants.processingHint.toUpperCase();
      case AssistantPhase.speaking:
        return AppConstants.speakingHint.toUpperCase();
      case AssistantPhase.error:
        return 'SYSTEM FAULT — TAP ORB TO RETRY'.toUpperCase();
    }
  }

  Color _statusColor(AssistantPhase phase) {
    switch (phase) {
      case AssistantPhase.idle:
        return JarvisColors.textSecondary;
      case AssistantPhase.listening:
        return JarvisColors.neonCyan;
      case AssistantPhase.processing:
        return JarvisColors.neonBlue;
      case AssistantPhase.speaking:
        return JarvisColors.success;
      case AssistantPhase.error:
        return JarvisColors.danger;
    }
  }
}

// ============================ API KEY DIALOG ============================

/// In-app dialog for entering/updating the Gemini API key.
/// The key is persisted via SharedPreferences and hot-swapped into
/// the Gemini datasource immediately — no restart required.
Future<void> _showApiKeyDialog(
  BuildContext context, {
  String? notice,
}) {
  final controller = TextEditingController(
    text: Injector.isConfigured ? '•••••••• (saved)' : '',
  );
  var edited = false;
  controller.addListener(() => edited = true);

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: JarvisColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: JarvisColors.neonCyan.withValues(alpha: 0.4)),
      ),
      title: Row(
        children: [
          const Icon(Icons.key_rounded, color: JarvisColors.neonCyan),
          const SizedBox(width: 10),
          Text(
            'Gemini API Key',
            style: TextStyle(
              color: JarvisColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notice != null) ...[
            Text(
              notice,
              style: const TextStyle(
                color: JarvisColors.danger,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: controller,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            style: const TextStyle(color: JarvisColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Paste your API key',
              hintStyle: const TextStyle(color: JarvisColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: JarvisColors.neonCyan.withValues(alpha: 0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: JarvisColors.neonCyan),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Stored only on this device. Get a free key at '
            'aistudio.google.com/app/apikey',
            style: TextStyle(color: JarvisColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: JarvisColors.textSecondary),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: JarvisColors.neonBlue,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Save'),
          onPressed: () async {
            // Ignore the masked placeholder; only save real edits.
            final key =
                edited ? controller.text.trim() : '';
            await Injector.applyApiKey(key);
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    key.isEmpty
                        ? 'API key cleared.'
                        : 'API key saved. Jarvis is online, Sir.',
                  ),
                ),
              );
            }
          },
        ),
      ],
    ),
  );
}