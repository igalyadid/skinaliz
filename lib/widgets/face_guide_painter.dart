import 'package:flutter/material.dart';

class FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.tealAccent.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height * 0.45);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.65,
      height: size.height * 0.55,
    );

    canvas.drawOval(ovalRect, paint);

    final eyeLinePaint = Paint()
      ..color = Colors.tealAccent.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(ovalRect.left + 20, center.dy - 20),
      Offset(ovalRect.right - 20, center.dy - 20),
      eyeLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
