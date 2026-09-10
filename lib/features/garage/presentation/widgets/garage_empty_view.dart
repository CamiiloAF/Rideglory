import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Garaje vacío: invita a agregar la primera moto.
///
/// Pencil: rgLwm
class GarageEmptyView extends StatelessWidget {
  const GarageEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bike, size: 48, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(
              context.l10n.garage_empty_title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.garage_empty_body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: context.l10n.garage_add_vehicle_button,
              icon: LucideIcons.plus,
              onPressed: () => context.pushNamed(AppRoutes.vehicleAdd),
            ),
          ],
        ),
      ),
    );
  }
}
