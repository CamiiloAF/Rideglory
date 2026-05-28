import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_upload_cubit.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_confirmation_page.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_manual_capture_params.dart';
import 'package:rideglory/features/soat/presentation/scan/soat_scan_launcher.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_manual_option_card.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_scan_button.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_upload_option_card.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_upload_question_header.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_vehicle_info_card.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class SoatUploadPage extends StatelessWidget {
  const SoatUploadPage({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SoatUploadCubit>(),
      child: _SoatUploadView(vehicle: vehicle),
    );
  }
}

class _SoatUploadView extends StatefulWidget {
  const _SoatUploadView({required this.vehicle});

  final VehicleModel vehicle;

  @override
  State<_SoatUploadView> createState() => _SoatUploadViewState();
}

class _SoatUploadViewState extends State<_SoatUploadView> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<SoatUploadCubit, SoatUploadState>(
      listener: (context, state) {
        if (state is SoatUploadImagePicked) {
          _navigateToConfirmation(state.image);
        } else if (state is SoatUploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.darkBgPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.textOnDarkPrimary,
            ),
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
        body: BlocBuilder<SoatUploadCubit, SoatUploadState>(
          builder: (context, state) {
            final isLoading = state is SoatUploadPicking;
            return SingleChildScrollView(
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
                  SoatScanButton(onPressed: _scanSoat),
                  const SizedBox(height: 20),
                  SoatUploadOptionCard(
                    isLoading: isLoading,
                    onCameraTap: () =>
                        context.read<SoatUploadCubit>().pickFromCamera(),
                    onGalleryTap: () =>
                        context.read<SoatUploadCubit>().pickFromGallery(),
                    onFileTap: () =>
                        context.read<SoatUploadCubit>().pickFromFile(),
                  ),
                  const SizedBox(height: 20),
                  SoatManualOptionCard(onTap: _navigateToManualForm),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToConfirmation(XFile image) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SoatConfirmationPage(vehicle: widget.vehicle, documentImage: image),
      ),
    );
  }

  Future<void> _navigateToManualForm() async {
    final saved = await context.push<bool>(
      AppRoutes.soatManualCapture,
      extra: SoatManualCaptureParams(vehicle: widget.vehicle),
    );
    if (saved == true && mounted) {
      context.pop(true);
    }
  }

  Future<void> _scanSoat() async {
    final outcome = await SoatScanLauncher.launch(context);
    if (outcome == null || !mounted) return;

    final saved = await context.push<bool>(
      AppRoutes.soatManualCapture,
      extra: SoatManualCaptureParams(
        vehicle: widget.vehicle,
        extraction: outcome.extraction,
        initialLocalImagePath: outcome.filePath,
      ),
    );
    if (saved == true && mounted) {
      context.pop(true);
    }
  }
}
