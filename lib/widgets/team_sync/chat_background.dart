import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../model/chat_theme_model.dart';

class ChatBackground extends StatelessWidget {
  final ChatTheme theme;
  final Widget child;

  const ChatBackground({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Background (Color/Gradient)
        Container(
          decoration: BoxDecoration(
            color: theme.id == 'default' 
                ? Theme.of(context).scaffoldBackgroundColor 
                : theme.backgroundColor,
            gradient: theme.backgroundType == ChatBackgroundType.gradient &&
                    theme.backgroundGradient != null
                ? LinearGradient(
                    colors: theme.backgroundGradient!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
        ),


        // Specialized Decorations
        if (theme.id == 'galaxy') const GalaxyBackground(),
        if (theme.id == 'love') const LoveBackground(),
        if (theme.id == 'tie_dye') const TieDyeBackground(),

        // Content
        child,
      ],
    );
  }
}

class GalaxyBackground extends StatelessWidget {
  const GalaxyBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GalaxyPainter(),
      size: Size.infinite,
    );
  }
}

class GalaxyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Seed for consistency
    final paint = Paint()..color = Colors.white.withOpacity(0.3);

    for (var i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Add some "nebula" glows
    final nebulaPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    for (var i = 0; i < 3; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 100.0 + random.nextDouble() * 100.0;
      nebulaPaint.color = [
        Colors.purple.withOpacity(0.1),
        Colors.blue.withOpacity(0.1),
        Colors.indigo.withOpacity(0.1),
      ][i % 3];
      canvas.drawCircle(Offset(x, y), radius, nebulaPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoveBackground extends StatelessWidget {
  const LoveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: LovePainter(),
      size: Size.infinite,
    );
  }
}

class LovePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(123);
    final paint = Paint()..color = Colors.white.withOpacity(0.15);

    for (var i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final heartSize = 10.0 + random.nextDouble() * 20.0;
      _drawHeart(canvas, Offset(x, y), heartSize, paint);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final width = size;
    final height = size;

    path.moveTo(center.dx, center.dy + height * 0.35);
    path.cubicTo(center.dx + width * 0.1, center.dy, center.dx + width * 0.45,
        center.dy, center.dx + width * 0.45, center.dy + height * 0.35);
    path.cubicTo(
        center.dx + width * 0.45,
        center.dy + height * 0.55,
        center.dx + width * 0.25,
        center.dy + height * 0.75,
        center.dx,
        center.dy + height);
    path.cubicTo(
        center.dx - width * 0.25,
        center.dy + height * 0.75,
        center.dx - width * 0.45,
        center.dy + height * 0.55,
        center.dx - width * 0.45,
        center.dy + height * 0.35);
    path.cubicTo(center.dx - width * 0.45, center.dy, center.dx - width * 0.1,
        center.dy, center.dx, center.dy + height * 0.35);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TieDyeBackground extends StatelessWidget {
  const TieDyeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Colors.orange.withOpacity(0.2),
            Colors.purple.withOpacity(0.2),
            Colors.blue.withOpacity(0.2),
            Colors.pink.withOpacity(0.2),
          ],
          stops: const [0.1, 0.4, 0.7, 1.0],
        ),
      ),
    );
  }
}
