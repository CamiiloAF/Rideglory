import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_cubit.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_section_header.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class SoatManualFormView extends StatefulWidget {
  const SoatManualFormView({
    super.key,
    required this.vehicle,
    this.existingSoat,
  });

  final VehicleModel vehicle;
  final SoatModel? existingSoat;

  @override
  State<SoatManualFormView> createState() => _SoatManualFormViewState();
}

class _SoatManualFormViewState extends State<SoatManualFormView> {
  final _formKey = GlobalKey<FormBuilderState>();
  static const _policyField = 'policyNumber';
  static const _insurerField = 'insurer';
  static const _startField = 'startDate';
  static const _expiryField = 'expiryDate';

  DateTime? _parseDateInput(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  Future<void> _submit(BuildContext context) async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;

    final expiryDate = _parseDateInput(values[_expiryField] as String?);
    if (expiryDate == null) return;

    final startDate = _parseDateInput(values[_startField] as String?);
    final soat = SoatModel(
      id: widget.existingSoat?.id ?? '',
      vehicleId: widget.vehicle.id ?? '',
      policyNumber: values[_policyField] as String?,
      startDate: startDate,
      expiryDate: expiryDate,
      insurer: values[_insurerField] as String?,
    );

    final cubit = context.read<SoatCubit>();
    final navigator = Navigator.of(context);
    final success = await cubit.save(
      vehicleId: widget.vehicle.id ?? '',
      soat: soat,
    );
    if (!mounted) return;
    if (success) {
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        title: Text(
          context.l10n.soat_page_manual_title,
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
      body: BlocBuilder<SoatCubit, ResultState<SoatModel>>(
        builder: (context, state) {
          final isLoading = state is Loading;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.soat_manual_subtitle(widget.vehicle.name),
                    style: const TextStyle(
                      color: AppColors.textOnDarkSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SoatSectionHeader(label: context.l10n.soat_section_data),
                  const SizedBox(height: 12),
                  AppTextField(
                    name: _policyField,
                    labelText: context.l10n.soat_field_policy_number,
                    hintText: context.l10n.soat_field_policy_placeholder,
                    initialValue: widget.existingSoat?.policyNumber,
                    keyboardType: TextInputType.text,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    name: _insurerField,
                    labelText: context.l10n.soat_field_insurer,
                    hintText: context.l10n.soat_field_insurer_placeholder,
                    initialValue: widget.existingSoat?.insurer,
                    keyboardType: TextInputType.text,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    name: _startField,
                    labelText: context.l10n.soat_field_start_date,
                    hintText: context.l10n.soat_field_date_format,
                    initialValue: _formatDate(widget.existingSoat?.startDate),
                    keyboardType: TextInputType.datetime,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    name: _expiryField,
                    labelText: context.l10n.soat_field_expiry_date,
                    hintText: context.l10n.soat_field_date_format,
                    initialValue: _formatDate(widget.existingSoat?.expiryDate),
                    keyboardType: TextInputType.datetime,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.l10n.soat_field_expiry_required;
                      }
                      if (_parseDateInput(value) == null) {
                        return context.l10n.soat_field_date_invalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.soat_manual_note,
                    style: const TextStyle(
                      color: AppColors.textOnDarkTertiary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  if (state is Error<SoatModel>) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        state.error.message,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  AppButton(
                    label: isLoading
                        ? context.l10n.soat_saving
                        : context.l10n.soat_save_data_btn,
                    onPressed: isLoading ? null : () => _submit(context),
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: AppTextButton(
                      label: context.l10n.soat_switch_to_upload,
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
