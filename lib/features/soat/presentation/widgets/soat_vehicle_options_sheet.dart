import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

sealed class SoatOptionsResult {}

final class SoatOptionsUpload extends SoatOptionsResult {
  SoatOptionsUpload(this.image);
  final XFile image;
}

final class SoatOptionsManual extends SoatOptionsResult {}

class SoatVehicleOptionsSheet extends StatefulWidget {
  const SoatVehicleOptionsSheet({super.key});

  @override
  State<SoatVehicleOptionsSheet> createState() =>
      _SoatVehicleOptionsSheetState();
}

class _SoatVehicleOptionsSheetState extends State<SoatVehicleOptionsSheet> {
  bool _isLoading = false;

  Future<void> _pickFromCamera() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        Navigator.of(context).pop(SoatOptionsUpload(file));
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.soat_upload_error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        Navigator.of(context).pop(SoatOptionsUpload(file));
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.soat_upload_error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFromFile() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null && mounted) {
        Navigator.of(context).pop(
          SoatOptionsUpload(XFile(result.files.single.path!)),
        );
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.soat_upload_error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBorderPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: context.l10n.soat_source_camera,
              icon: Icons.camera_alt_outlined,
              onPressed: _isLoading ? null : _pickFromCamera,
              isLoading: _isLoading,
              variant: AppButtonVariant.secondary,
              style: AppButtonStyle.outlined,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: context.l10n.soat_source_gallery,
              icon: Icons.photo_library_outlined,
              onPressed: _isLoading ? null : _pickFromGallery,
              isLoading: false,
              variant: AppButtonVariant.secondary,
              style: AppButtonStyle.outlined,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: context.l10n.soat_source_pdf,
              icon: Icons.picture_as_pdf_outlined,
              onPressed: _isLoading ? null : _pickFromFile,
              isLoading: false,
              variant: AppButtonVariant.secondary,
              style: AppButtonStyle.outlined,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: context.l10n.soat_source_manual,
              icon: Icons.edit_note_outlined,
              onPressed: _isLoading
                  ? null
                  : () => Navigator.of(context).pop(SoatOptionsManual()),
              variant: AppButtonVariant.secondary,
              style: AppButtonStyle.outlined,
            ),
          ],
        ),
      ),
    );
  }
}
