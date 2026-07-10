import 'package:flutter/material.dart';

/// "G" multicolor oficial de Google, dibujada con los paths del branding
/// (guía "Sign in with Google") para no depender de assets rasterizados.
class GoogleLogoIcon extends StatelessWidget {
  const GoogleLogoIcon({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const Color _blue = Color(0xFF4285F4);
  static const Color _red = Color(0xFFEA4335);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = _blue;
    canvas.drawPath(
      Path()
        ..moveTo(23.49, 12.27)
        ..cubicTo(23.49, 11.48, 23.42, 10.73, 23.30, 10.00)
        ..lineTo(12, 10.00)
        ..lineTo(12, 14.51)
        ..lineTo(18.47, 14.51)
        ..cubicTo(18.18, 15.99, 17.33, 17.24, 16.07, 18.09)
        ..lineTo(16.07, 21.09)
        ..lineTo(19.93, 21.09)
        ..cubicTo(22.19, 19.00, 23.49, 15.92, 23.49, 12.27)
        ..close(),
      paint,
    );

    paint.color = _red;
    canvas.drawPath(
      Path()
        ..moveTo(12, 5.38)
        ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
        ..lineTo(19.36, 3.87)
        ..cubicTo(17.45, 2.09, 14.97, 1, 12, 1)
        ..cubicTo(7.70, 1, 3.99, 3.47, 2.18, 7.07)
        ..lineTo(5.84, 9.91)
        ..cubicTo(6.71, 7.31, 9.14, 5.38, 12, 5.38)
        ..close(),
      paint,
    );

    paint.color = _yellow;
    canvas.drawPath(
      Path()
        ..moveTo(5.84, 14.09)
        ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.00)
        ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
        ..lineTo(5.84, 7.07)
        ..lineTo(2.18, 7.07)
        ..cubicTo(1.43, 8.55, 1, 10.22, 1, 12)
        ..cubicTo(1, 13.78, 1.43, 15.45, 2.18, 16.93)
        ..lineTo(5.03, 14.71)
        ..lineTo(5.84, 14.09)
        ..close(),
      paint,
    );

    paint.color = _green;
    canvas.drawPath(
      Path()
        ..moveTo(12, 23)
        ..cubicTo(14.97, 23, 17.46, 22.02, 19.28, 20.34)
        ..lineTo(15.71, 17.57)
        ..cubicTo(14.73, 18.23, 13.48, 18.63, 12, 18.63)
        ..cubicTo(9.14, 18.63, 6.71, 16.70, 5.84, 14.10)
        ..lineTo(2.18, 14.10)
        ..lineTo(2.18, 17.19)
        ..cubicTo(3.99, 20.53, 7.70, 23, 12, 23)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
