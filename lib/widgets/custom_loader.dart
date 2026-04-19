import 'package:flutter/material.dart';
import 'dart:ui';

class CustomLoader extends StatefulWidget {
  final double size;
  final String? message;

  const CustomLoader({
    super.key,
    this.size = 220,
    this.message,
  });

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _drawAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    )..repeat();

    _drawAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.linear),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 🖌️ Tracing Lines (Mendekati Logo)
                AnimatedBuilder(
                  animation: _drawAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: TraceLogoPainter(progress: _drawAnimation.value),
                    );
                  },
                ),
                // ✨ Logo Asli
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Image.asset(
                    'assets/images/logo_student.png',
                    width: widget.size * 0.85,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 30),
            Text(
              widget.message!.toUpperCase(),
              style: TextStyle(
                color: const Color(0xFF001F5B).withValues(alpha: 0.8), // Biru Logo
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TraceLogoPainter extends CustomPainter {
  final double progress;
  TraceLogoPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bluePaint = Paint()
      ..color = const Color(0xFF001F5B).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final goldPaint = Paint()
      ..color = const Color(0xFFE5A823).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final redPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    double w = size.width;
    double h = size.height;
    double cx = w * 0.5;
    double cy = h * 0.5;

    // 🛡️ 1. PALANG BIRU (KOTAK PRESISI)
    final bluePath = Path();
    double crossSize = w * 0.15;
    bluePath.moveTo(cx - crossSize, cy - crossSize * 2.5); // Top
    bluePath.lineTo(cx + crossSize, cy - crossSize * 2.5);
    bluePath.lineTo(cx + crossSize, cy - crossSize);
    bluePath.lineTo(cx + crossSize * 2.5, cy - crossSize); // Right
    bluePath.lineTo(cx + crossSize * 2.5, cy + crossSize);
    bluePath.lineTo(cx + crossSize, cy + crossSize);
    bluePath.lineTo(cx + crossSize, cy + crossSize * 2.5); // Bottom
    bluePath.lineTo(cx - crossSize, cy + crossSize * 2.5);
    bluePath.lineTo(cx - crossSize, cy + crossSize);
    bluePath.lineTo(cx - crossSize * 2.5, cy + crossSize); // Left
    bluePath.lineTo(cx - crossSize * 2.5, cy - crossSize);
    bluePath.lineTo(cx - crossSize, cy - crossSize);
    bluePath.close();

    // 🩺 2. STETOSKOP (KAITAN J DI KIRI)
    final goldPath = Path();
    goldPath.moveTo(w * 0.35, h * 0.45);
    goldPath.cubicTo(w * 0.1, h * 0.45, w * 0.05, h * 0.8, w * 0.3, h * 0.85); // Stethoscope curve
    goldPath.lineTo(w * 0.4, h * 0.7); // Stethoscope head

    // 👩‍🍼 3. TANGAN / BAYI (KURVA BAWAH)
    final redPath = Path();
    redPath.moveTo(w * 0.45, h * 0.85);
    redPath.quadraticBezierTo(w * 0.8, h * 0.9, w * 0.9, h * 0.6); // Hand curve

    // DRAWING LOGIC
    _draw(canvas, bluePath, bluePaint, progress * 1.5);
    if (progress > 0.4) _draw(canvas, goldPath, goldPaint, (progress - 0.4) * 2);
    if (progress > 0.6) _draw(canvas, redPath, redPaint, (progress - 0.6) * 2.5);
  }

  void _draw(Canvas canvas, Path p, Paint pt, double prog) {
    if (prog <= 0) return;
    for (final m in p.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * prog.clamp(0, 1)), pt);
    }
  }

  @override
  bool shouldRepaint(TraceLogoPainter old) => old.progress != progress;
}
