import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';
import 'package:rideglory/features/tecnomecanica/presentation/widgets/tecnomecanica_exemption_notice.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

/// Formulario para **registrar o editar** la RTM de un vehículo.
///
/// **Modo creación** (`existingRtm == null`): formulario vacío.
/// **Modo edición** (`existingRtm != null`): campos precargados con datos existentes.
///
/// Al guardar exitosamente retorna `true` via `context.pop(true)` para que
/// la [TecnomecanicaStatusPage] pueda recargar el estado del cubit.
class TecnomecanicaManualCapturePage extends StatefulWidget {
  const TecnomecanicaManualCapturePage({
    super.key,
    this.vehicle,
    this.existingRtm,
  });

  final VehicleModel? vehicle;
  final TecnomecanicaModel? existingRtm;

  @override
  State<TecnomecanicaManualCapturePage> createState() =>
      _TecnomecanicaManualCapturePageState();
}

class _TecnomecanicaManualCapturePageState
    extends State<TecnomecanicaManualCapturePage> {
  final _formKey = GlobalKey<FormBuilderState>();
  DateTime? _startDate;
  DateTime? _expiryDate;
  bool _saving = false;
  String? _error;

  bool get _isEditMode => widget.existingRtm != null;

  @override
  void initState() {
    super.initState();
    _startDate = widget.existingRtm?.startDate;
    _expiryDate = widget.existingRtm?.expiryDate;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final expiryDate = _expiryDate;
    if (expiryDate == null) return;

    final values = _formKey.currentState!.value;
    final certificateNumber =
        ((values['certificateNumber'] as String?) ?? '').trim();
    final cdaName = ((values['cdaName'] as String?) ?? '').trim();
    final cdaCode = (values['cdaCode'] as String?)?.trim();
    final documentUrl = (values['documentUrl'] as String?)?.trim();

    if (certificateNumber.isEmpty || cdaName.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final vehicleId = widget.vehicle?.id ?? '';

    final rtm = TecnomecanicaModel(
      id: widget.existingRtm?.id ?? '',
      vehicleId: vehicleId,
      certificateNumber: certificateNumber,
      cdaName: cdaName,
      cdaCode: cdaCode?.isEmpty == true ? null : cdaCode,
      startDate: _startDate,
      expiryDate: expiryDate,
      documentUrl: documentUrl?.isEmpty == true ? null : documentUrl,
    );

    final success = await context.read<TecnomecanicaCubit>().save(
      vehicleId: vehicleId,
      tecnomecanica: rtm,
    );

    if (!mounted) return;

    if (success) {
      context.pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = context.l10n.tecnomecanica_save_error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TecnomecanicaCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.darkBgPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textOnDarkPrimary,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            _isEditMode
                ? context.l10n.tecnomecanica_edit_title
                : context.l10n.tecnomecanica_form_create_title,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: FormBuilder(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.vehicle != null) ...[
                  Text(
                    context.l10n.tecnomecanica_form_subtitle(
                      widget.vehicle!.name,
                    ),
                    style: const TextStyle(
                      color: AppColors.textOnDarkSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TecnomecanicaExemptionNotice(vehicle: widget.vehicle!),
                  const SizedBox(height: 16),
                ],
                AppTextField(
                  name: 'certificateNumber',
                  labelText: context.l10n.tecnomecanica_field_certificate_number,
                  hintText: context.l10n.tecnomecanica_certificate_number_hint,
                  initialValue: widget.existingRtm?.certificateNumber,
                  isRequired: true,
                  textInputAction: TextInputAction.next,
                  enabled: !_saving,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  name: 'cdaName',
                  labelText: context.l10n.tecnomecanica_field_cda_name,
                  hintText: context.l10n.tecnomecanica_cda_name_hint,
                  initialValue: widget.existingRtm?.cdaName,
                  isRequired: true,
                  textInputAction: TextInputAction.next,
                  enabled: !_saving,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  name: 'cdaCode',
                  labelText: context.l10n.tecnomecanica_field_cda_code,
                  hintText: context.l10n.tecnomecanica_cda_code_hint,
                  initialValue: widget.existingRtm?.cdaCode,
                  textInputAction: TextInputAction.next,
                  enabled: !_saving,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppDatePicker(
                        key: ValueKey(
                          'startDate_${_startDate?.toIso8601String()}',
                        ),
                        fieldName: 'startDate',
                        labelText: context.l10n.tecnomecanica_field_start_date,
                        hintText: context.l10n.tecnomecanica_date_hint,
                        initialValue: _startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        onChanged: (date) =>
                            setState(() => _startDate = date),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDatePicker(
                        key: ValueKey(
                          'expiryDate_${_expiryDate?.toIso8601String()}',
                        ),
                        fieldName: 'expiryDate',
                        labelText:
                            context.l10n.tecnomecanica_field_expiry_date,
                        hintText: context.l10n.tecnomecanica_date_hint,
                        initialValue: _expiryDate,
                        isRequired: true,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        onChanged: (date) =>
                            setState(() => _expiryDate = date),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  name: 'documentUrl',
                  labelText: context.l10n.tecnomecanica_field_document_url,
                  hintText: context.l10n.tecnomecanica_document_url_hint,
                  initialValue: widget.existingRtm?.documentUrl,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.url,
                  enabled: !_saving,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                AppButton(
                  label: _saving
                      ? context.l10n.tecnomecanica_saving
                      : context.l10n.tecnomecanica_save_data_btn,
                  onPressed: _saving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
