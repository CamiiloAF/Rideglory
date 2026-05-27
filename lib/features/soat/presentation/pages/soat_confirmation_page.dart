import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_form_cubit.dart';

class SoatConfirmationPage extends StatelessWidget {
  const SoatConfirmationPage({
    super.key,
    required this.vehicle,
    this.documentImage,
    this.isFromVehicleCreation = false,
  });

  final VehicleModel vehicle;
  final XFile? documentImage;

  /// `true` cuando la página fue abierta vía `Navigator.pushReplacement` desde
  /// `VehicleFormPage` al crear un vehículo nuevo con foto de SOAT. En ese caso
  /// el éxito solo necesita UN pop (vuelve directamente al garage); no se debe
  /// llamar `router.pop()` adicional.
  final bool isFromVehicleCreation;

  bool get _isManual => documentImage == null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<SoatFormCubit>();
        if (vehicle.soatStatus != null) {
          cubit.loadExistingSoat(vehicle.id!);
        }
        return cubit;
      },
      child: _SoatConfirmationView(
        vehicle: vehicle,
        documentImage: documentImage,
        isManual: _isManual,
        isFromVehicleCreation: isFromVehicleCreation,
      ),
    );
  }
}

class _SoatConfirmationView extends StatefulWidget {
  const _SoatConfirmationView({
    required this.vehicle,
    required this.documentImage,
    required this.isManual,
    required this.isFromVehicleCreation,
  });

  final VehicleModel vehicle;
  final XFile? documentImage;
  final bool isManual;
  final bool isFromVehicleCreation;

  @override
  State<_SoatConfirmationView> createState() => _SoatConfirmationViewState();
}

class _SoatConfirmationViewState extends State<_SoatConfirmationView> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<SoatFormCubit, SoatFormState>(
      listener: (context, state) {
        state.whenOrNull(
          soatLoaded: (soat) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<SoatFormCubit>().formKey.currentState?.patchValue({
                'policyNumber': soat.policyNumber ?? '',
                'insurer': soat.insurer,
                'startDate': soat.startDate,
                'expiryDate': soat.expiryDate,
              });
            });
          },
          success: (soat) {
            final vehicleId = widget.vehicle.id;
            if (vehicleId != null) {
              context.read<VehicleCubit>().updateSoatLocally(
                vehicleId,
                expiryDate: soat.expiryDate,
              );
            }
            final router = GoRouter.of(context);
            final messenger = ScaffoldMessenger.of(context);
            final successMsg = context.l10n.vehicle_soat_saved_successfully;
            // Cuando proviene de la creación de un vehículo (Navigator.pushReplacement),
            // SoatConfirmationPage reemplazó a VehicleFormPage en el stack de GoRouter.
            // Un solo pop regresa al garage; el segundo pop adicional sobresaldría un nivel.
            Navigator.of(context).pop();
            if (!widget.isFromVehicleCreation) {
              router.pop();
            }
            messenger.showSnackBar(
              SnackBar(
                content: Text(successMsg),
                backgroundColor: AppColors.success,
              ),
            );
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
            widget.isManual
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
                    if (!widget.isManual) ...[
                      _SoatDocPreview(imageFile: widget.documentImage!),
                      const SizedBox(height: 20),
                    ],
                    _FormSectionHeader(
                      title: widget.isManual
                          ? context.l10n.vehicle_soat_manual_section_title
                          : context.l10n.vehicle_soat_confirm_verify,
                      subtitle: widget.isManual
                          ? context.l10n.vehicle_soat_manual_section_sub
                          : context.l10n.vehicle_soat_confirm_verify_sub,
                    ),
                    const SizedBox(height: 16),
                    _SoatFormFields(
                      formKey: context.read<SoatFormCubit>().formKey,
                    ),
                    const SizedBox(height: 16),
                    const _SoatValidAlert(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _SoatConfirmCtaBar(
              vehicleId: widget.vehicle.id!,
              documentImage: widget.documentImage,
              isManual: widget.isManual,
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
    final cubit = context.read<SoatFormCubit>();
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
                  onChanged: (date) => cubit.onDatesChanged(startDate: date),
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
                  onChanged: (date) => cubit.onDatesChanged(expiryDate: date),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Inlined from soat_doc_preview.dart (deleted file) ────────────────────────

class _SoatDocPreview extends StatelessWidget {
  const _SoatDocPreview({required this.imageFile});

  final XFile imageFile;

  bool get _isPdf => imageFile.path.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    if (_isPdf) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.picture_as_pdf_outlined,
              size: 44,
              color: AppColors.info,
            ),
            const SizedBox(height: 8),
            Text(
              imageFile.path.split('/').last,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textOnDarkSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(imageFile.path), fit: BoxFit.cover),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.darkCard],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  context.l10n.vehicle_soat_doc_uploaded,
                  style: const TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Inlined from soat_valid_alert.dart (deleted file) ────────────────────────

class _SoatValidAlert extends StatelessWidget {
  const _SoatValidAlert();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SoatFormCubit, SoatFormState>(
      builder: (context, state) {
        final cubit = context.read<SoatFormCubit>();
        final startDate = cubit.currentStartDate;
        final expiryDate = cubit.currentExpiryDate;

        if (startDate == null || expiryDate == null) {
          return _AlertRow(
            icon: Icons.shield_outlined,
            iconColor: AppColors.textOnDarkTertiary,
            bgColor: AppColors.darkTertiary,
            title: context.l10n.vehicle_soat_status_pending,
            subtitle: '—',
            subtitleColor: AppColors.textOnDarkTertiary,
          );
        }

        if (!startDate.isBefore(expiryDate)) {
          return _AlertRow(
            icon: Icons.error_outline,
            iconColor: AppColors.error,
            bgColor: AppColors.error.withAlpha(26),
            title: context.l10n.vehicle_soat_status_invalid_dates_title,
            subtitle: context.l10n.vehicle_soat_status_invalid_dates_desc,
            subtitleColor: AppColors.textOnDarkSecondary,
          );
        }

        final daysRemaining = expiryDate.difference(DateTime.now()).inDays;

        if (daysRemaining < 0) {
          return _AlertRow(
            icon: Icons.shield_outlined,
            iconColor: AppColors.error,
            bgColor: AppColors.error.withAlpha(26),
            title: context.l10n.vehicle_soat_status_expired_title,
            subtitle: context.l10n
                .vehicle_soat_status_expired_desc(daysRemaining.abs()),
            subtitleColor: AppColors.textOnDarkSecondary,
          );
        }

        return _AlertRow(
          icon: Icons.verified_user_outlined,
          iconColor: const Color(0xFF22C55E),
          bgColor: const Color(0xFF22C55E).withAlpha(26),
          title: context.l10n.vehicle_soat_status_valid,
          subtitle: daysRemaining == 0
              ? context.l10n.vehicle_soat_status_expires_today
              : context.l10n.vehicle_soat_status_valid_desc(daysRemaining),
          subtitleColor: AppColors.textOnDarkSecondary,
        );
      },
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inlined from soat_confirm_cta_bar.dart (deleted file) ────────────────────

class _SoatConfirmCtaBar extends StatelessWidget {
  const _SoatConfirmCtaBar({
    required this.vehicleId,
    required this.isManual,
    this.documentImage,
  });

  final String vehicleId;
  final bool isManual;
  final XFile? documentImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.darkBgPrimary,
        border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
      ),
      child: BlocBuilder<SoatFormCubit, SoatFormState>(
        builder: (context, state) {
          final isLoading =
              state.maybeWhen(loading: () => true, orElse: () => false);
          final cubit = context.read<SoatFormCubit>();
          final canSave = cubit.areDatesValid;
          return AppButton(
            label: isManual
                ? context.l10n.vehicle_soat_save_button
                : context.l10n.vehicle_soat_confirm_button,
            isLoading: isLoading,
            onPressed: canSave
                ? () => cubit.submit(vehicleId, documentImage: documentImage)
                : null,
          );
        },
      ),
    );
  }
}
