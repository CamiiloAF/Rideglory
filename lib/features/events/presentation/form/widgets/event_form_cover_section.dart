import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/design_system/design_system.dart';

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
      title: EventStrings.addEventCover,
      hint: EventStrings.addEventCoverHint,
      uploadButtonLabel: EventStrings.uploadImage,
      showGenerateWithAI: true,
      onGenerateWithAITap: onGenerateWithAITap,
      generateWithAILabel: EventStrings.generateWithAI,
    );
  }
}
