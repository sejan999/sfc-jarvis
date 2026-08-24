import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assistant/presentation/bloc/assistant_bloc.dart';
import '../../core/theme/app_theme.dart';

/// The central reactive voice orb.
///
/// Visual states:
///  - idle:       slow breathing glow
///  - listening:  fast pulse + waveform rings reacting to mic
///  - processing: rotating arc spinner
///  - speaking:   energetic multi-ring pulse
class OrbWidget extends StatefulWidget {
  const OrbWidget({
    super.key,
    required this.phase,
    required this.onTap,
    this.size = 220,
  });

  final AssistantPhase phase;
  final VoidCallback onTap;
  final double size;

  @override
  State<OrbWidget> createState() => _OrbWidgetState();
}

class _OrbWidgetState extends State<OrbWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _phaseColor {
    switch (widget.phase) {
      case AssistantPhase.listening:
        return JarvisColors.neonCyan;
      case AssistantPhase.processing:
        return JarvisColors.neonBlue;
      case AssistantPhase.speaking:
        return JarvisColors.success;
      case AssistantPhase.idle:
      case AssistantPhase.error:
        return JarvisColors.neonDeep;
    }
  }

  double get _baseIntensity {
    switch (widget.phase) {
      case AssistantPhase.idle:
        return 0.35;
      case AssistantPhase.listening:
        return 0.9;
      case AssistantPhase.processing:
        return 0.7;
      case AssistantPhase.speaking:
        return 1.0;
      case AssistantPhase.error:
        return 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return SizedBox(
            width: widget.size * 1.6,
            height: widget.size * 1.6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer reactive waveform rings
                if (widget.phase == AssistantPhase.listening ||
                    widget.phase == AssistantPhase.speaking)
                  ...List.generate(3, (i) {
                    final delay = i / 3;
                    final ringT = (t + delay) % 1.0;
                    return Container(
                      width: widget.size + ringT * widget.size * 0.9,
                      height: widget.size + ringT * widget.size * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _phaseColor.withOpacity(
                            (1 - ringT) * 0.35 * _baseIntensity,
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  }),

                // Rotating HUD arc while processing
                if (widget.phase == AssistantPhase.processing)
                  CustomPaint(
                    size: Size.square(widget.size * 1.25),
                    painter: _ArcPainter(
                      progress: t,
                      color: _phaseColor,
                    ),
                  ),

                // Breathing glow halo
                Container(
                  width: widget.size * (1.05 + math.sin(t * 2 * math.pi) * 0.04),
                  height:
                      widget.size * (1.05 + math.sin(t * 2 * math.pi) * 0.04),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _phaseColor.withOpacity(0.45 * _baseIntensity),
                        blurRadius: 60,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                ),

                // Core orb with gradient
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.85),
                        _phaseColor.withOpacity(0.75),
                        JarvisColors.neonBlue.withOpacity(0.55),
                        JarvisColors.background.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.35, 0.7, 1.0],
                    ),
                    border: Border.all(
                      color: _phaseColor.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _phaseIcon,
                    size: widget.size * 0.28,
                    color: JarvisColors.background,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData get _phaseIcon {
    switch (widget.phase) {
      case AssistantPhase.listening:
        return Icons.graphic_eq_rounded;
      case AssistantPhase.processing:
        return Icons.psychology_rounded;
      case AssistantPhase.speaking:
        return Icons.volume_up_rounded;
      case AssistantPhase.idle:
      case AssistantPhase.error:
        return Icons.mic_none_rounded;
    }
  }
}

/// Rotating segmented arc used during processing.
class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.7);

    for (var i = 0; i < 4; i++) {
      final start = progress * 2 * math.pi + i * math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        math.pi / 5,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}