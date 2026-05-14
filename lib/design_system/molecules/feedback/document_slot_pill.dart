import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';

/// State variants for a document slot (SOAT, tech-review, etc.)
enum DocumentSlotState {
  /// Document not registered.
  empty,

  /// Document is valid / vigente.
  valid,

  /// Document is nearing expiry.
  expiringSoon,

  /// Document is expired.
  expired,
}

/// A pill-shaped row that shows a document slot label and its current state.
///
/// Design spec:
/// - Minimum height 44 px (touch target).
/// - Background: [AppColors.darkSurfaceHighest].
/// - Border radius: 8 px.
/// - State accent: success / warning / error per [state].
/// - Reusable in iter-2 SOAT badge context; not coupled to vehicle types.
class DocumentSlotPill extends StatelessWidget {
  const DocumentSlotPill({
    required this.label,
    required this.state,
    this.stateLabel,
    this.onTap,
    this.leading,
    super.key,
  });

  /// Document name, e.g. "SOAT" or "Técnico-mecánica".
  final String label;

  /// Current validity state of the document.
  final DocumentSlotState state;

  /// Human-readable state label. If null, a default is shown per [state].
  final String? stateLabel;

  /// Optional tap handler. Shows chevron when provided.
  final VoidCallback? onTap;

  /// Optional leading icon.
  final IconData? leading;

  Color _accentColor() {
    return switch (state) {
      DocumentSlotState.empty => AppColors.darkTextSecondary,
      DocumentSlotState.valid => AppColors.success,
      DocumentSlotState.expiringSoon => AppColors.warning,
      DocumentSlotState.expired => AppColors.error,
    };
  }

  IconData _stateIcon() {
    return switch (state) {
      DocumentSlotState.empty => Icons.add_circle_outline_rounded,
      DocumentSlotState.valid => Icons.check_circle_rounded,
      DocumentSlotState.expiringSoon => Icons.warning_amber_rounded,
      DocumentSlotState.expired => Icons.cancel_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final effectiveLeading = leading ?? Icons.description_outlined;
    final effectiveStateLabel = stateLabel ??
        switch (state) {
          DocumentSlotState.empty => 'Sin registrar',
          DocumentSlotState.valid => 'Vigente',
          DocumentSlotState.expiringSoon => 'Por vencer',
          DocumentSlotState.expired => 'Vencido',
        };

    final content = Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(effectiveLeading, size: 18, color: AppColors.darkTextSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.darkTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(_stateIcon(), size: 16, color: accent),
          const SizedBox(width: 4),
          Text(
            effectiveStateLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.darkTextSecondary),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }
}
