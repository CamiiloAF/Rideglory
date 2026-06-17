import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/services/image_storage_service.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/presentation/scan/soat_document_picker.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_add_document_sheet.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_document_section.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    this.initialLocalImagePath,
  });

  final VehicleModel? vehicle;
  final TecnomecanicaModel? existingRtm;

  /// Ruta local de un archivo ya seleccionado antes de abrir el formulario.
  /// Se usa al editar datos pendientes en modo creación de vehículo.
  final String? initialLocalImagePath;

  @override
  State<TecnomecanicaManualCapturePage> createState() =>
      _TecnomecanicaManualCapturePageState();
}

class _TecnomecanicaManualCapturePageState
    extends State<TecnomecanicaManualCapturePage> {
  final _formKey = GlobalKey<FormBuilderState>();
  DateTime? _startDate;
  DateTime? _expiryDate;
  String? _localImagePath;
  bool _saving = false;
  String? _error;

  bool get _isEditMode => widget.existingRtm != null;

  @override
  void initState() {
    super.initState();
    _startDate = widget.existingRtm?.startDate;
    _expiryDate = widget.existingRtm?.expiryDate;
    _localImagePath = widget.initialLocalImagePath;
  }

  Future<void> _pickImage() async {
    if (!mounted) return;
    final choice = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.darkBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SoatAddDocumentSheet(),
    );
    if (choice == null || !mounted) return;

    final String? pickedPath;
    if (choice == 2) {
      pickedPath = await SoatDocumentPicker.pickPdf();
    } else {
      pickedPath = await SoatDocumentPicker.pickImageFromGallery();
    }
    if (pickedPath == null || !mounted) return;
    setState(() => _localImagePath = pickedPath);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final startDate = _startDate;
    final expiryDate = _expiryDate;
    if (startDate == null || expiryDate == null) return;

    if (!expiryDate.isAfter(startDate)) {
      setState(() => _error = context.l10n.tecnomecanica_expiry_after_start_error);
      return;
    }

    final values = _formKey.currentState!.value;
    final cdaName = ((values['cdaName'] as String?) ?? '').trim();

    if (cdaName.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    // Modo creación (sin vehicle): devolver datos como pendientes sin guardar.
    if (widget.vehicle?.id == null) {
      context.pop(
        TecnomecanicaModel(
          id: '',
          vehicleId: '',
          cdaName: cdaName,
          startDate: startDate,
          expiryDate: expiryDate,
          documentUrl: _localImagePath,
        ),
      );
      return;
    }

    final vehicleId = widget.vehicle!.id!;
    final cubit = context.read<TecnomecanicaCubit>();

    String? documentUrl = widget.existingRtm?.documentUrl;
    if (_localImagePath != null) {
      final ext = _localImagePath!.split('.').last.toLowerCase();
      try {
        documentUrl = await getIt<ImageStorageService>().uploadImage(
          image: XFile(_localImagePath!),
          storagePath:
              'tecnomecanica/$vehicleId/${DateTime.now().millisecondsSinceEpoch}.$ext',
        );
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = context.l10n.imageUploadFailed;
        });
        return;
      }
    }

    final rtm = TecnomecanicaModel(
      id: widget.existingRtm?.id ?? '',
      vehicleId: vehicleId,
      cdaName: cdaName,
      startDate: startDate,
      expiryDate: expiryDate,
      documentUrl: documentUrl,
    );

    final success = await cubit.save(
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
    return Scaffold(
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
                    if (!_isEditMode) ...[
                      const TecnomecanicaExemptionNotice(),
                      const SizedBox(height: 16),
                    ],
                    SoatDocumentSection(
                      localImagePath: _localImagePath,
                      remoteDocumentUrl: widget.existingRtm?.documentUrl,
                      onPickImage: _pickImage,
                      onRemoveLocalImage: () =>
                          setState(() => _localImagePath = null),
                    ),
                    const SizedBox(height: 16),
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
                    Row(
                      children: [
                        Expanded(
                          child: AppDatePicker(
                            key: ValueKey(
                              'startDate_${_startDate?.toIso8601String()}',
                            ),
                            fieldName: 'startDate',
                            labelText:
                                context.l10n.tecnomecanica_field_start_date,
                            hintText: context.l10n.tecnomecanica_date_hint,
                            initialValue: _startDate,
                            isRequired: true,
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
    );
  }
}

