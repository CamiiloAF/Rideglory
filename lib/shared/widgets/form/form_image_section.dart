import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class FormImageSection extends StatelessWidget {
  const FormImageSection({
    super.key,
    this.imageUrl,
    this.localImagePath,
    this.onPickImage,
    this.onClearTap,
    required this.title,
    required this.hint,
    required this.uploadButtonLabel,
    this.showGenerateWithAI = false,
    this.onGenerateWithAITap,
    this.generateWithAILabel,
    this.labelText,
  });

  final String? imageUrl;
  final String? localImagePath;
  final VoidCallback? onPickImage;
  final VoidCallback? onClearTap;
  final String title;
  final String hint;
  final String uploadButtonLabel;
  final bool showGenerateWithAI;
  final VoidCallback? onGenerateWithAITap;
  final String? generateWithAILabel;
  final String? labelText;

  @override
  Widget build(BuildContext context) {
    return AppImagePicker(
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      onPickImage: onPickImage,
      onClearTap: onClearTap,
      title: title,
      hint: hint,
      uploadButtonLabel: uploadButtonLabel,
      showGenerateWithAI: showGenerateWithAI,
      onGenerateWithAITap: onGenerateWithAITap,
      generateWithAILabel: generateWithAILabel,
      labelText: labelText,
    );
  }
}
