import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/design_system.dart';

class ForgotPasswordBackButton extends StatelessWidget {
  const ForgotPasswordBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCircleIconButton.back(
      hasBorder: true,
      onTap: () {
        if (context.canPop()) context.pop();
      },
    );
  }
}
