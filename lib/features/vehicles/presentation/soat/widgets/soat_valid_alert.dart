import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/presentation/soat/cubit/soat_form_cubit.dart';

class SoatValidAlert extends StatelessWidget {
  const SoatValidAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SoatFormCubit, SoatFormState>(
      builder: (context, state) {
        final cubit = context.read<SoatFormCubit>();
        final startDate = cubit.currentStartDate;
        final expiryDate = cubit.currentExpiryDate;

        if (startDate == null || expiryDate == null) {
          return _AlertRow(
            icon: Icons.shield_outlined,
            iconColor: AppColors.textOnDarkTertiary,
            bgColor: AppColors.darkTertiary,
            title: context.l10n.vehicle_soat_status_pending,
            subtitle: '—',
            subtitleColor: AppColors.textOnDarkTertiary,
          );
        }

        if (!startDate.isBefore(expiryDate)) {
          return _AlertRow(
            icon: Icons.error_outline,
            iconColor: AppColors.error,
            bgColor: AppColors.error.withAlpha(26),
            title: context.l10n.vehicle_soat_status_invalid_dates_title,
            subtitle: context.l10n.vehicle_soat_status_invalid_dates_desc,
            subtitleColor: AppColors.textOnDarkSecondary,
          );
        }

        final daysRemaining = expiryDate.difference(DateTime.now()).inDays;

        if (daysRemaining < 0) {
          return _AlertRow(
            icon: Icons.shield_outlined,
            iconColor: AppColors.error,
            bgColor: AppColors.error.withAlpha(26),
            title: context.l10n.vehicle_soat_status_expired_title,
            subtitle: context.l10n.vehicle_soat_status_expired_desc(daysRemaining.abs()),
            subtitleColor: AppColors.textOnDarkSecondary,
          );
        }

        return _AlertRow(
          icon: Icons.verified_user_outlined,
          iconColor: const Color(0xFF22C55E),
          bgColor: const Color(0xFF22C55E).withAlpha(26),
          title: context.l10n.vehicle_soat_status_valid,
          subtitle: daysRemaining == 0
              ? context.l10n.vehicle_soat_status_expires_today
              : context.l10n.vehicle_soat_status_valid_desc(daysRemaining),
          subtitleColor: AppColors.textOnDarkSecondary,
        );
      },
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
