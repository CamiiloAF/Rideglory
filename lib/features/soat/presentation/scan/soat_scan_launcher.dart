import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/l10n/rideglory_l10n.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_extraction.dart';
import 'package:rideglory/features/soat/domain/models/soat_scan_result.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_scan_params.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_scan_source_sheet.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Outcome of a completed scan launch: the parsed [extraction] plus the local
/// [filePath] of the document the user picked (so the caller can also attach it
/// to the SOAT record).
class SoatScanOutcome {
  const SoatScanOutcome({required this.extraction, required this.filePath});

  final SoatExtraction extraction;
  final String filePath;
}

/// Coordinates the "Escanear SOAT" flow: pick source → pick file → run the
/// [SoatScanPage] → return the extraction. Returns `null` if the user cancels
/// at any step or the scan does not yield prefillable data (the caller falls
/// back silently to the manual flow).
abstract final class SoatScanLauncher {
  static Future<SoatScanOutcome?> launch(BuildContext context) async {
    final source = await SoatScanSourceSheet.show(context);
    if (source == null || !context.mounted) return null;

    final String? filePath;
    try {
      filePath = await _pickFile(source);
    } on PlatformException catch (exception) {
      if (!_isPermissionDenied(exception)) rethrow;
      await _logFailure(SoatScanFailureReason.permissionDenied);
      if (context.mounted) _showPermissionDenied(context);
      return null;
    }
    if (filePath == null || !context.mounted) return null;

    final extraction = await context.push<SoatExtraction>(
      AppRoutes.soatScan,
      extra: SoatScanParams(filePath: filePath, source: source),
    );

    if (extraction == null) return null;
    return SoatScanOutcome(extraction: extraction, filePath: filePath);
  }

  static Future<String?> _pickFile(SoatScanSource source) async {
    switch (source) {
      case SoatScanSource.pdf:
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        return result?.files.single.path;
      case SoatScanSource.camera:
      case SoatScanSource.gallery:
        final imageSource = source == SoatScanSource.camera
            ? ImageSource.camera
            : ImageSource.gallery;
        final file = await ImagePicker().pickImage(
          source: imageSource,
          imageQuality: 90,
        );
        return file?.path;
    }
  }

  /// image_picker / file_picker surface a denied OS permission as a
  /// [PlatformException] whose code names the denied resource. We match those
  /// codes so the flow can report [SoatScanFailureReason.permissionDenied]
  /// instead of swallowing it as an unknown error.
  static bool _isPermissionDenied(PlatformException exception) {
    const permissionCodes = {
      'camera_access_denied',
      'photo_access_denied',
      'photo_library_unavailable',
      'read_external_storage_denied',
      'permission',
    };
    final code = exception.code.toLowerCase();
    return permissionCodes.contains(code) || code.contains('denied');
  }

  static Future<void> _logFailure(SoatScanFailureReason reason) {
    return getIt<AnalyticsService>().logEvent('soat_scan_failed', {
      'failure_reason': reason.analyticsValue,
    });
  }

  static void _showPermissionDenied(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(RidegloryL10n.current.soat_scan_error_permission),
        backgroundColor: AppColors.darkCard,
      ),
    );
  }
}
