import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Titled card used in [EventFormStep4Review] for a review section.
///
/// Design spec (Pencil FW3Hd):
/// - Header: 32×32 orange-dark icon box (cornerRadius 8, fill #2D2117) +
///   title 14px w700 + spacer + "Editar" AppTextButton primary
/// - Top border between header and rows: #2A2A32 1px
/// - Each row: padding [11,16], label-value space_between
/// - Card: cornerRadius 12, fill #1E1E24, border #2A2A32 1px
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnDarkPrimary,
                  ),
                ),
                const Spacer(),
                AppTextButton(
                  label: context.l10n.event_step_review_editButton,
                  onPressed: onEdit,
                  variant: AppTextButtonVariant.primary,
                  icon: Icons.edit_outlined,
                  iconSize: 14,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.darkBorderPrimary),
          Column(children: rows),
        ],
      ),
    );
  }
}
