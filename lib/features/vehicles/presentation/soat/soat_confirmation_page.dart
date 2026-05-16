import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/soat/cubit/soat_form_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/soat/widgets/soat_confirm_cta_bar.dart';
import 'package:rideglory/features/vehicles/presentation/soat/widgets/soat_doc_preview.dart';
import 'package:rideglory/features/vehicles/presentation/soat/widgets/soat_valid_alert.dart';

class SoatConfirmationPage extends StatelessWidget {
  const SoatConfirmationPage({
    super.key,
    required this.vehicle,
    this.documentImage,
    this.onSuccess,
  });

  final VehicleModel vehicle;
  final XFile? documentImage;
  final VoidCallback? onSuccess;

  bool get _isManual => documentImage == null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SoatFormCubit>(),
      child: _SoatConfirmationView(
        vehicle: vehicle,
        documentImage: documentImage,
        isManual: _isManual,
        onSuccess: onSuccess,
      ),
    );
  }
}

class _SoatConfirmationView extends StatelessWidget {
  const _SoatConfirmationView({
    required this.vehicle,
    required this.documentImage,
    required this.isManual,
    this.onSuccess,
  });

  final VehicleModel vehicle;
  final XFile? documentImage;
  final bool isManual;
  final VoidCallback? onSuccess;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SoatFormCubit, SoatFormState>(
      listener: (context, state) {
        state.whenOrNull(
          success: (soat) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.vehicle_soat_saved_successfully),
                backgroundColor: AppColors.success,
              ),
            );
            if (onSuccess != null) {
              onSuccess!();
            } else {
              Navigator.of(context).popUntil(
                (route) => route.settings.name == '/vehicles/soat' || route.isFirst,
              );
            }
          },
          error: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.message),
                backgroundColor: AppColors.error,
              ),
            );
          },
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.darkBgPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textOnDarkPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            isManual
                ? context.l10n.vehicle_soat_form_title
                : context.l10n.vehicle_soat_confirm_title,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isManual) ...[
                      SoatDocPreview(imageFile: documentImage!),
                      const SizedBox(height: 20),
                    ],
                    _FormSectionHeader(
                      title: isManual
                          ? context.l10n.vehicle_soat_manual_section_title
                          : context.l10n.vehicle_soat_confirm_verify,
                      subtitle: isManual
                          ? context.l10n.vehicle_soat_manual_section_sub
                          : context.l10n.vehicle_soat_confirm_verify_sub,
                    ),
                    const SizedBox(height: 16),
                    _SoatFormFields(
                      formKey: context.read<SoatFormCubit>().formKey,
                    ),
                    const SizedBox(height: 16),
                    const SoatValidAlert(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SoatConfirmCtaBar(
              vehicleId: vehicle.id!,
              documentImage: documentImage,
              isManual: isManual,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SoatFormFields extends StatelessWidget {
  const _SoatFormFields({required this.formKey});

  final GlobalKey<FormBuilderState> formKey;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      child: Column(
        children: [
          AppTextField(
            name: 'policyNumber',
            labelText: context.l10n.vehicle_soat_policy_number_label,
            hintText: context.l10n.vehicle_soat_policy_number_hint,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AppTextField(
            name: 'insurer',
            labelText: context.l10n.vehicle_soat_insurer_label,
            hintText: context.l10n.vehicle_soat_insurer_hint,
            textInputAction: TextInputAction.done,
            isRequired: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppDatePicker(
                  fieldName: 'startDate',
                  labelText: context.l10n.vehicle_soat_start_date_label,
                  isRequired: true,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppDatePicker(
                  fieldName: 'expiryDate',
                  labelText: context.l10n.vehicle_soat_expiry_date_label,
                  isRequired: true,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
