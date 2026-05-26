import 'dart:ui';
import 'package:flutter/material.dart';

class SilkShaderWidget extends StatefulWidget {
  final double speed;
  final double scale;
  final Color color;
  final double noiseIntensity;
  final double rotation;
  final Widget? child;

  const SilkShaderWidget({
    super.key,
    this.speed = 1.0,
    this.scale = 1.0,
    this.color = const Color(0xFF7B7481),
    this.noiseIntensity = 1.5,
    this.rotation = 0.0,
    this.child,
  });

  @override
  State<SilkShaderWidget> createState() => _SilkShaderWidgetState();
}

class _SilkShaderWidgetState extends State<SilkShaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await FragmentProgram.fromAsset('shaders/silk.frag');
      if (mounted) {
        setState(() {
          _shader = program.fragmentShader();
        });
      }
    } catch (e) {
      debugPrint('Error loading silk shader: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) {
      return Container(
        color: widget.color.withOpacity(0.8),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: SilkPainter(
            shader: _shader!,
            time: _controller.value *
                50, // Reduced base time for smoother animation
            color: widget.color,
            speed: widget.speed,
            scale: widget.scale,
            noiseIntensity: widget.noiseIntensity,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class SilkPainter extends CustomPainter {
  final FragmentShader shader;
  final double time;
  final Color color;
  final double speed;
  final double scale;
  final double noiseIntensity;

  SilkPainter({
    required this.shader,
    required this.time,
    required this.color,
    required this.speed,
    required this.scale,
    required this.noiseIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, time); // uTime
    shader.setFloat(1, size.width); // uSize.x
    shader.setFloat(2, size.height); // uSize.y
    shader.setFloat(3, color.red / 255.0); // uColor.r
    shader.setFloat(4, color.green / 255.0); // uColor.g
    shader.setFloat(5, color.blue / 255.0); // uColor.b
    shader.setFloat(6, color.alpha / 255.0); // uColor.a
    shader.setFloat(7, speed); // uSpeed
    shader.setFloat(8, scale); // uScale
    shader.setFloat(9, noiseIntensity); // uNoiseIntensity

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(SilkPainter oldDelegate) => true;
}
