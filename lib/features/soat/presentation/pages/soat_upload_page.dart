import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_manual_form_page.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class SoatUploadPage extends StatelessWidget {
  const SoatUploadPage({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        title: Text(
          context.l10n.soat_page_upload_title,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.darkBgPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textOnDarkPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.soat_upload_subtitle(vehicle.name),
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _SoatSourceGrid(vehicle: vehicle),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SoatSourceGrid extends StatelessWidget {
  const _SoatSourceGrid({required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _SourceOption(
          icon: Icons.camera_alt_outlined,
          label: context.l10n.soat_source_camera,
          onTap: () => _onSourceSelected(context, 'camera'),
        ),
        _SourceOption(
          icon: Icons.photo_library_outlined,
          label: context.l10n.soat_source_gallery,
          onTap: () => _onSourceSelected(context, 'gallery'),
        ),
        _SourceOption(
          icon: Icons.picture_as_pdf_outlined,
          label: context.l10n.soat_source_pdf,
          onTap: () => _onSourceSelected(context, 'pdf'),
        ),
        _SourceOption(
          icon: Icons.edit_note_outlined,
          label: context.l10n.soat_source_manual,
          onTap: () => _navigateToManual(context),
        ),
      ],
    );
  }

  void _onSourceSelected(BuildContext context, String source) {
    // Image picker and PDF picker deferred — navigate to manual entry as fallback
    // TODO: wire image_picker when enabled in pubspec
    _navigateToManual(context);
  }

  void _navigateToManual(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => SoatManualFormPage(vehicle: vehicle),
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        context.pop(true);
      }
    });
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorderPrimary),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.primary, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
