import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:rideglory/shared/theme/app_dimens.dart';

class MatchRidersHeader extends StatelessWidget {
  const MatchRidersHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        )
      ],
    );
  }
}

class PathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    int curveHeight = 30;
    Offset controlPoint = Offset(size.width / 2, size.height + curveHeight);
    Offset endPoint = Offset(size.width, size.height - curveHeight);

    Paint paint = Paint()
      ..shader = ui.Gradient.linear(const Offset(0.0, 0.0), endPoint, [
        Colors.orange,
        Colors.red,
      ])
      ..style = PaintingStyle.fill;

    Path path = Path();

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
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
