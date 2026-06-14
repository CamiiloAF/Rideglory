import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class RouteMapLinearPreview extends StatelessWidget {
  const RouteMapLinearPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _RoutePreviewPainter(width: w)),
                ),
                Positioned(
                  left: w * 0.4 - 11,
                  top: 40,
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RoutePreviewPainter extends CustomPainter {
  const _RoutePreviewPainter({required this.width});

  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF1A1A1F);
    canvas.drawRect(Offset.zero & size, bg);

    final grid = Paint()
      ..color = AppColors.darkBorderPrimary
      ..strokeWidth = 1;
    for (final y in [30.0, 60.0, 90.0]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (final x in [70.0, 140.0, 210.0, 280.0, 350.0]) {
      if (x < size.width) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
    }

    final startX = size.width * 0.09;
    final endX = size.width * 0.76;
    const routeY = 59.0;

    final line = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(startX, routeY), Offset(endX, routeY), line);

    canvas.drawCircle(
      Offset(startX, routeY),
      8,
      Paint()..color = const Color(0xFF22C55E),
    );
    canvas.drawCircle(
      Offset(endX, routeY),
      8,
      Paint()..color = const Color(0xFFEF4444),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
