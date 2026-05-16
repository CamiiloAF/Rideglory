import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/soat/cubit/soat_form_cubit.dart';

class SoatFormPage extends StatelessWidget {
  final VehicleModel vehicle;

  const SoatFormPage({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SoatFormCubit>(),
      child: _SoatFormView(vehicle: vehicle),
    );
  }
}

class _SoatFormView extends StatelessWidget {
  final VehicleModel vehicle;

  const _SoatFormView({required this.vehicle});

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
            Navigator.of(context).pop(soat);
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
            context.l10n.vehicle_soat_form_title,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: _SoatFormBody(vehicle: vehicle),
      ),
    );
  }
}

class _SoatFormBody extends StatelessWidget {
  final VehicleModel vehicle;

  const _SoatFormBody({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SoatFormCubit>();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: FormBuilder(
              key: cubit.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _VehicleChip(vehicle: vehicle),
                  const SizedBox(height: 24),
                  _SectionLabel(context.l10n.vehicle_soat_section_title),
                  const SizedBox(height: 12),
                  AppTextField(
                    name: 'policyNumber',
                    labelText: context.l10n.vehicle_soat_policy_number_label,
                    hintText: context.l10n.vehicle_soat_policy_number_hint,
                    textInputAction: TextInputAction.next,
                    isRequired: true,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    name: 'insurer',
                    labelText: context.l10n.vehicle_soat_insurer_label,
                    hintText: context.l10n.vehicle_soat_insurer_hint,
                    textInputAction: TextInputAction.done,
                    isRequired: true,
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Fechas'),
                  const SizedBox(height: 12),
                  AppDatePicker(
                    fieldName: 'startDate',
                    labelText: context.l10n.vehicle_soat_start_date_label,
                    isRequired: true,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  ),
                  const SizedBox(height: 12),
                  AppDatePicker(
                    fieldName: 'expiryDate',
                    labelText: context.l10n.vehicle_soat_expiry_date_label,
                    isRequired: true,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  ),
                ],
              ),
            ),
          ),
        ),
        _SoatCtaBar(vehicleId: vehicle.id!),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnDarkTertiary,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _VehicleChip extends StatelessWidget {
  final VehicleModel vehicle;

  const _VehicleChip({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.two_wheeler,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.name,
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (vehicle.licensePlate != null)
                  Text(
                    vehicle.licensePlate!,
                    style: const TextStyle(
                      color: AppColors.textOnDarkTertiary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoatCtaBar extends StatelessWidget {
  final String vehicleId;

  const _SoatCtaBar({required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.darkBgPrimary,
        border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
      ),
      child: BlocBuilder<SoatFormCubit, SoatFormState>(
        builder: (context, state) {
          final isLoading = state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );
          return AppButton(
            label: context.l10n.vehicle_soat_save_button,
            isLoading: isLoading,
            onPressed: () => context.read<SoatFormCubit>().submit(vehicleId),
          );
        },
      ),
    );
  }
}
