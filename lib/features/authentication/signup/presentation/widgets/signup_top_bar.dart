import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/design_system.dart';

class SignupTopBar extends StatelessWidget {
  const SignupTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppCircleIconButton.back(
          hasBorder: true,
          onTap: () {
            if (context.canPop()) context.pop();
          },
        ),
      ],
    );
  }
}
