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

/// Model for a single document slot.
class DocumentSlot {
  const DocumentSlot({
    required this.name,
    required this.state,
    this.expiryLabel,
    this.onDelete,
    this.isInfoType = false,
  });

  final String name;
  final DocumentSlotState state;
  final String? expiryLabel;
  final VoidCallback? onDelete;

  /// Whether this slot uses the info/blue icon bg (e.g. SOAT).
  final bool isInfoType;
}

/// Displays a document section with a header (title + count badge + "Opcional")
/// and up to 3 document slot cards, matching the aGqnv Pencil spec.
class DocumentSlotPill extends StatelessWidget {
  const DocumentSlotPill({
    required this.slots,
    this.totalSlots = 3,
    this.isOptional = true,
    super.key,
  });

  final List<DocumentSlot> slots;
  final int totalSlots;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DocumentHeader(
          count: slots.length,
          total: totalSlots,
          isOptional: isOptional,
        ),
        const SizedBox(height: 10),
        ...slots.map((slot) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DocumentSlotCard(slot: slot),
            )),
        const SizedBox(height: 2),
        const _DocumentInfoRow(),
      ],
    );
  }
}

class _DocumentHeader extends StatelessWidget {
  const _DocumentHeader({
    required this.count,
    required this.total,
    required this.isOptional,
  });

  final int count;
  final int total;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'DOCUMENTOS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.tabInactive,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 4),
        if (isOptional)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.darkBorderLight),
            ),
            child: const Text(
              'Opcional',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppColors.tabInactive,
              ),
            ),
          ),
        const Spacer(),
        Text(
          '$count/$total',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _DocumentSlotCard extends StatelessWidget {
  const _DocumentSlotCard({required this.slot});

  final DocumentSlot slot;

  Color _iconBg() {
    return switch (slot.state) {
      DocumentSlotState.valid => AppColors.successSubtle,
      DocumentSlotState.expiringSoon ||
      DocumentSlotState.expired ||
      DocumentSlotState.empty =>
        slot.isInfoType ? AppColors.infoSubtle : AppColors.darkTertiary,
    };
  }

  Color _iconColor() {
    return switch (slot.state) {
      DocumentSlotState.valid => AppColors.success,
      DocumentSlotState.expiringSoon => AppColors.textOnDarkSecondary,
      DocumentSlotState.expired => AppColors.error,
      DocumentSlotState.empty => AppColors.textOnDarkSecondary,
    };
  }

  Color _badgeBg() {
    return switch (slot.state) {
      DocumentSlotState.valid => AppColors.successSubtle,
      DocumentSlotState.expiringSoon => AppColors.warningSubtle,
      DocumentSlotState.expired => AppColors.errorSubtle,
      DocumentSlotState.empty => AppColors.darkTertiary,
    };
  }

  Color _badgeText() {
    return switch (slot.state) {
      DocumentSlotState.valid => AppColors.success,
      DocumentSlotState.expiringSoon => AppColors.warning,
      DocumentSlotState.expired => AppColors.error,
      DocumentSlotState.empty => AppColors.textOnDarkSecondary,
    };
  }

  String _badgeLabel() {
    return switch (slot.state) {
      DocumentSlotState.valid => 'Vigente',
      DocumentSlotState.expiringSoon => 'Por vencer',
      DocumentSlotState.expired => 'Vencido',
      DocumentSlotState.empty => 'Sin registrar',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconBg(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.description_outlined, size: 20, color: _iconColor()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (slot.expiryLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    slot.expiryLabel!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _badgeBg(),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _badgeLabel(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _badgeText(),
                  ),
                ),
              ),
              if (slot.onDelete != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: slot.onDelete,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.darkTertiary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.close, size: 14, color: AppColors.textOnDarkSecondary),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentInfoRow extends StatelessWidget {
  const _DocumentInfoRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.info_outline, size: 12, color: AppColors.tabInactive),
        SizedBox(width: 5),
        Text(
          'Máximo 3 documentos',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.tabInactive,
          ),
        ),
      ],
    );
  }
}
