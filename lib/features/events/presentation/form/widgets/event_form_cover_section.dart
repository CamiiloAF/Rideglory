import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventFormCoverSection extends StatelessWidget {
  const EventFormCoverSection({
    super.key,
    this.imageUrl,
    this.localImagePath,
    this.onUploadTap,
    this.onClearTap,
    this.onGenerateWithAITap,
  });

  final String? imageUrl;
  final String? localImagePath;
  final VoidCallback? onUploadTap;
  final VoidCallback? onClearTap;
  final VoidCallback? onGenerateWithAITap;

  @override
  Widget build(BuildContext context) {
    return AppImagePicker(
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      onPickImage: onUploadTap,
      onClearTap: onClearTap,
      title: context.l10n.event_addEventCover,
      hint: context.l10n.event_addEventCoverHint,
      uploadButtonLabel: context.l10n.event_uploadImage,
      showGenerateWithAI: true,
      onGenerateWithAITap: onGenerateWithAITap,
      generateWithAILabel: context.l10n.event_generateWithAI,
    );
  }
}
