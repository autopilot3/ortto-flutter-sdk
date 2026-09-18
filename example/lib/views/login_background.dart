import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Animated organic gradient behind the login screen, mirroring the iOS
/// demo's layering: a CPU-painted gradient renders immediately as the loading
/// state / fallback, and the mesh-gradient fragment shader (swirl +
/// distortion, FCM palette) fades in over it once compiled.
class LoginBackground extends StatefulWidget {
  const LoginBackground({super.key});

  @override
  State<LoginBackground> createState() => _LoginBackgroundState();
}

class _LoginBackgroundState extends State<LoginBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/mesh_gradient.frag');
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (_) {
      // Shader unavailable (e.g. old engine) — the painted gradient stays.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final time = _controller.value * 120;
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _FallbackMeshPainter(time: time),
              size: Size.infinite,
            ),
            // The shader fades in over the painted gradient once it has
            // compiled, matching the iOS WebGL fade-in. It renders at half
            // resolution and upscales — imperceptible for a soft gradient,
            // and ~4x cheaper on weak GPUs (e.g. the Android emulator).
            AnimatedOpacity(
              opacity: _shader == null ? 0 : 1,
              duration: const Duration(milliseconds: 800),
              child: _shader == null
                  ? const SizedBox.shrink()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth / 2;
                        final height = constraints.maxHeight / 2;
                        return FittedBox(
                          fit: BoxFit.fill,
                          child: SizedBox(
                            width: width,
                            height: height,
                            child: CustomPaint(
                              painter:
                                  _ShaderPainter(shader: _shader!, time: time),
                              size: Size(width, height),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ShaderPainter extends CustomPainter {
  _ShaderPainter({required this.shader, required this.time});

  final ui.FragmentShader shader;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ShaderPainter oldDelegate) => oldDelegate.time != time;
}

/// Immediate-render fallback: drifting blurred color blobs approximating the
/// mesh, shown until (or instead of) the fragment shader.
class _FallbackMeshPainter extends CustomPainter {
  _FallbackMeshPainter({required this.time});

  final double time;

  // The iOS demo's FCM light mesh colors.
  static const List<Color> _colors = [
    Color(0xFFC28AFF),
    Color(0xFFFF94B8),
    Color(0xFFFFE657),
    Color(0xFFF594FF),
    Color(0xFFFFB32E),
    Color(0xFFF5FFED),
    Color(0xFFFFA3C2),
    Color(0xFFB36BFF),
    Color(0xFFFFE05C),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = time;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    // Mesh control points matching the iOS demo's animated 3x3 grid.
    final points = <Offset>[
      const Offset(0.00, 0.00),
      Offset(0.48 + 0.12 * math.sin(t * 0.36), 0.00),
      const Offset(1.00, 0.00),
      Offset(0.00, 0.46 + 0.12 * math.cos(t * 0.31)),
      Offset(
          0.50 + 0.18 * math.sin(t * 0.28), 0.50 + 0.16 * math.cos(t * 0.25)),
      Offset(1.00, 0.54 + 0.13 * math.sin(t * 0.33)),
      const Offset(0.00, 1.00),
      Offset(0.52 + 0.13 * math.cos(t * 0.27), 1.00),
      const Offset(1.00, 1.00),
    ];

    final radius = size.longestSide * 0.62;
    for (var i = 0; i < points.length; i++) {
      final center =
          Offset(points[i].dx * size.width, points[i].dy * size.height);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            _colors[i].withValues(alpha: 0.85),
            _colors[i].withValues(alpha: 0.0)
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    // Fluid white highlight drifting across the top, ported from
    // FluidHighlight (FCM drifts right-to-left).
    final progress = (math.sin(t * 0.42) + 1) / 2;
    final drift = 1 - progress;
    final highlightCenter = Offset(
      size.width * (0.22 + 0.56 * drift),
      size.height * (0.20 + 0.18 * math.sin(drift * math.pi * 2)),
    );
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawOval(
      Rect.fromCenter(
        center: highlightCenter,
        width: size.width * 0.82,
        height: size.height * 0.34,
      ),
      highlight,
    );

    // Soft veil, matching the iOS backgroundVeil.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(_FallbackMeshPainter oldDelegate) =>
      oldDelegate.time != time;
}
