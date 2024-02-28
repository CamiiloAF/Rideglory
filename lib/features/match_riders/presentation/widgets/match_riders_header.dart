import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../../shared/theme/app_dimens.dart';

class MatchRidersHeader extends StatelessWidget {
  const MatchRidersHeader({final Key? key}) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        CustomPaint(
          size: Size(double.infinity, screenSize.height * .25),
          painter: PathPainter(),
        ),
        Positioned(
          width: screenSize.width,
          top: 70,
          child: Container(
            margin: AppDimens.matchPageHorizontalMargin,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riders Nearby',
                  style: textTheme.headlineMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.settings),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PathPainter extends CustomPainter {
  @override
  void paint(final Canvas canvas, final Size size) {
    const curveHeight = 30;
    final controlPoint = Offset(size.width / 2, size.height + curveHeight);
    final endPoint = Offset(size.width, size.height - curveHeight);

    final paint = Paint()
      ..shader = ui.Gradient.linear(Offset.zero, endPoint, [
        Colors.orange,
        Colors.red,
      ])
      ..style = PaintingStyle.fill;

    final path = Path();

    path
      ..moveTo(0, size.height - curveHeight)
      ..quadraticBezierTo(
        controlPoint.dx,
        controlPoint.dy,
        endPoint.dx,
        endPoint.dy,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(final CustomPainter oldDelegate) => true;
}
