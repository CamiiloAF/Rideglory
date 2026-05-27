import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// OWNER — DRAFT state: full-width primary "Publicar" CTA.
class EventDetailOwnerDraftBar extends StatelessWidget {
  const EventDetailOwnerDraftBar({
    super.key,
    required this.isLoading,
    required this.onPublish,
  });

  final bool isLoading;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPublish,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        decoration: BoxDecoration(
          color: isLoading
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(AppColors.darkBgPrimary),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.publish_rounded,
                    color: AppColors.darkBgPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.draft_publish,
                    style: const TextStyle(
                      color: AppColors.darkBgPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
