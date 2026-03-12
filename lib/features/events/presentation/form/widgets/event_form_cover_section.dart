import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class EventFormCoverSection extends StatelessWidget {
  const EventFormCoverSection({
    super.key,
    this.imageUrl,
    this.onUploadTap,
    this.onGenerateWithAITap,
  });

  final String? imageUrl;
  final VoidCallback? onUploadTap;
  final VoidCallback? onGenerateWithAITap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onUploadTap,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        EventStrings.addEventCover,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          EventStrings.addEventCoverHint,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (onUploadTap != null || onGenerateWithAITap != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (onUploadTap != null)
                AppButton(
                  label: EventStrings.uploadImage,
                  variant: AppButtonVariant.outline,
                  icon: Icons.upload,
                  onPressed: onUploadTap,
                ),
              if (onUploadTap != null && onGenerateWithAITap != null)
                const SizedBox(width: 12),
              if (onGenerateWithAITap != null)
                AppButton(
                  label: EventStrings.generateWithAI,
                  variant: AppButtonVariant.outline,
                  icon: Icons.auto_awesome,
                  onPressed: onGenerateWithAITap,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
