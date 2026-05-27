import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/events/presentation/form/widgets/cover_placeholder_view.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/form/app_text_button.dart';

class CoverPreviewWidget extends StatelessWidget {
  const CoverPreviewWidget({
    super.key,
    required this.coverGenerationResult,
    required this.imageUrl,
    required this.isGenerating,
    required this.onGenerateTap,
    required this.onRegenerateTap,
    required this.onUploadTap,
  });

  final ResultState<String> coverGenerationResult;
  final String? imageUrl;
  final bool isGenerating;
  final VoidCallback onGenerateTap;
  final VoidCallback onRegenerateTap;
  final VoidCallback onUploadTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final isData = coverGenerationResult is Data<String>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.event_addEventCover.toUpperCase(),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    errorWidget: (context, url, error) => CoverPlaceholderView(
                      colorScheme: colorScheme,
                    ),
                  )
                else
                  CoverPlaceholderView(colorScheme: colorScheme),
                if (isGenerating)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.event_coverGeneratingOverlay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isData) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppTextButton(
                label: context.l10n.event_coverRegenerate,
                onPressed: isGenerating ? null : onRegenerateTap,
                icon: Icons.refresh,
              ),
            ],
          ),
        ],
        if (!isData) ...[
          const SizedBox(height: 12),
          AppButton(
            label: context.l10n.event_generateWithAI,
            onPressed: isGenerating ? null : onGenerateTap,
            icon: Icons.auto_awesome,
            isLoading: isGenerating,
          ),
        ],
        const SizedBox(height: 8),
        AppTextButton(
          label: context.l10n.event_uploadImage,
          onPressed: onUploadTap,
          icon: Icons.upload_outlined,
        ),
      ],
    );
  }
}

