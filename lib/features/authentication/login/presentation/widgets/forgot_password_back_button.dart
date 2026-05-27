import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/design_system.dart';

class ForgotPasswordBackButton extends StatelessWidget {
  const ForgotPasswordBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (context.canPop()) context.pop();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: const Icon(
          Icons.arrow_back,
          color: AppColors.textOnDarkPrimary,
          size: 18,
        ),
      ),
    );
  }
}
