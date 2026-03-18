import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/home/constants/home_strings.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class HomeViewAllEventsButton extends StatelessWidget {
  const HomeViewAllEventsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => context.goNamed(AppRoutes.events),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                HomeStrings.viewAllEvents,
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.expand_more,
                color: AppColors.darkTextSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
