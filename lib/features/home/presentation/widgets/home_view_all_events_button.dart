import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeViewAllEventsButton extends StatelessWidget {
  const HomeViewAllEventsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.events),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.transparent, // Intentional: outlined button with no fill
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.home_viewCatalog.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textOnDarkSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
