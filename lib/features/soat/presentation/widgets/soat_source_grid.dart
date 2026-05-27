import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_manual_capture_params.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_source_option.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class SoatSourceGrid extends StatelessWidget {
  const SoatSourceGrid({super.key, required this.vehicle});

  final VehicleModel vehicle;

  void _onSourceSelected(BuildContext context, String source) {
    // Image picker and PDF picker deferred — navigate to manual entry as fallback
    // TODO: wire image_picker when enabled in pubspec
    _navigateToManual(context);
  }

  void _navigateToManual(BuildContext context) {
    context
        .push<bool>(
          AppRoutes.soatManualCapture,
          extra: SoatManualCaptureParams(vehicle: vehicle),
        )
        .then((result) {
      if (result == true && context.mounted) {
        context.pop(true);
      }
    });
  }

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
        SoatSourceOption(
          icon: Icons.camera_alt_outlined,
          label: context.l10n.soat_source_camera,
          onTap: () => _onSourceSelected(context, 'camera'),
        ),
        SoatSourceOption(
          icon: Icons.photo_library_outlined,
          label: context.l10n.soat_source_gallery,
          onTap: () => _onSourceSelected(context, 'gallery'),
        ),
        SoatSourceOption(
          icon: Icons.picture_as_pdf_outlined,
          label: context.l10n.soat_source_pdf,
          onTap: () => _onSourceSelected(context, 'pdf'),
        ),
        SoatSourceOption(
          icon: Icons.edit_note_outlined,
          label: context.l10n.soat_source_manual,
          onTap: () => _navigateToManual(context),
        ),
      ],
    );
  }
}
