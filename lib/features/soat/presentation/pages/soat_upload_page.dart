import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_scan_result.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_manual_capture_params.dart';
import 'package:rideglory/features/soat/presentation/scan/soat_scan_launcher.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_manual_option_card.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_upload_option_card.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_upload_question_header.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_vehicle_info_card.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class SoatUploadPage extends StatefulWidget {
  const SoatUploadPage({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  State<SoatUploadPage> createState() => _SoatUploadPageState();
}

class _SoatUploadPageState extends State<SoatUploadPage> {
  bool _scanning = false;

  /// Picks the document from [source], runs the OCR scan, then opens the
  /// confirmation form with whatever was detected so the user can review and
  /// optionally autofill.
  Future<void> _scanWithSource(SoatScanSource source) async {
    setState(() => _scanning = true);
    final outcome = await SoatScanLauncher.launch(context, source: source);
    if (!mounted) return;
    setState(() => _scanning = false);
    if (outcome == null) return;

    final saved = await context.push<bool>(
      AppRoutes.soatManualCapture,
      extra: SoatManualCaptureParams(
        vehicle: widget.vehicle,
        extraction: outcome.extraction,
        initialLocalImagePath: outcome.filePath,
      ),
    );
    if (saved == true && mounted) context.pop(true);
  }

  Future<void> _navigateToManualForm() async {
    final saved = await context.push<bool>(
      AppRoutes.soatManualCapture,
      extra: SoatManualCaptureParams(vehicle: widget.vehicle),
    );
    if (saved == true && mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnDarkPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.vehicle_doc_soat_label,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SoatVehicleInfoCard(vehicle: widget.vehicle),
            const SizedBox(height: 20),
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.darkBorderPrimary,
            ),
            const SizedBox(height: 20),
            const SoatUploadQuestionHeader(),
            const SizedBox(height: 20),
            SoatUploadOptionCard(
              isLoading: _scanning,
              onCameraTap: () => _scanWithSource(SoatScanSource.camera),
              onGalleryTap: () => _scanWithSource(SoatScanSource.gallery),
              onFileTap: () => _scanWithSource(SoatScanSource.pdf),
            ),
            const SizedBox(height: 20),
            SoatManualOptionCard(onTap: _navigateToManualForm),
          ],
        ),
      ),
    );
  }
}
