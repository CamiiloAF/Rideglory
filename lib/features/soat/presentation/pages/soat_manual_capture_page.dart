import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/services/image_storage_service.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_extraction.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/domain/models/soat_scan_result.dart';
import 'package:rideglory/features/soat/domain/usecases/save_soat_usecase.dart';
import 'package:rideglory/features/soat/domain/usecases/scan_soat_usecase.dart';
import 'package:rideglory/features/soat/presentation/scan/soat_document_picker.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_add_document_sheet.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_autofill_banner.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_document_section.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_not_recognized_warning.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_validity_card.dart';

/// Formulario unificado para **registrar o editar** el SOAT manualmente.
///
/// **Modo creación** (`vehicle == null` o sin `id`):
/// - No llama a la API. Retorna un [PendingManualSoat] via `context.pop()`.
/// - La imagen local (si se seleccionó) se incluye en [PendingManualSoat] para
///   ser subida al backend después de que el vehículo sea creado.
///
/// **Modo edición** (`vehicle.id != null`):
/// - Precarga los campos con [existingSoat].
/// - Sube la imagen (si hay nueva) y guarda en el backend al confirmar.
/// - Retorna `true` via `Navigator.pop(context, true)` al éxito.
class SoatManualCapturePage extends StatefulWidget {
  const SoatManualCapturePage({
    super.key,
    this.vehicle,
    this.existingSoat,
    this.initialLocalImagePath,
    this.extraction,
  });

  /// Vehículo al que pertenece el SOAT.
  /// - `null` o sin `id` → modo creación.
  /// - Con `id` → modo edición (guarda en el backend).
  final VehicleModel? vehicle;

  /// Datos del SOAT a precargar en los campos. Solo aplica en modo edición.
  final SoatModel? existingSoat;

  /// Ruta local de un archivo (imagen o PDF) ya seleccionado antes de abrir
  /// este formulario. Si se pasa, el documento queda pre-cargado en la sección
  /// superior y el usuario puede cambiarlo o eliminarlo desde aquí.
  final String? initialLocalImagePath;

  /// Resultado del OCR. Cuando llega y supera el umbral de prellenado, los
  /// campos se inicializan con sus valores y se marcan como auto-rellenados.
  final SoatExtraction? extraction;

  @override
  State<SoatManualCapturePage> createState() => _SoatManualCapturePageState();
}

class _SoatManualCapturePageState extends State<SoatManualCapturePage> {
  final _formKey = GlobalKey<FormBuilderState>();
  DateTime? _startDate;
  DateTime? _expiryDate;
  String? _localImagePath;
  bool _saving = false;
  bool _scanning = false;
  bool _autofillApplied = false;
  bool _documentNotRecognized = false;
  String? _error;
  SoatExtraction? _extraction;

  bool get _isEditMode => widget.vehicle?.id != null;

  /// The form was opened with a document/scan already attached, so the user is
  /// confirming detected (or to-be-entered) data rather than starting from
  /// scratch.
  bool get _isConfirmationMode =>
      widget.initialLocalImagePath != null || widget.extraction != null;

  String _appBarTitle(BuildContext context) {
    if (widget.existingSoat != null) return context.l10n.soat_edit_title;
    if (_isConfirmationMode) return context.l10n.vehicle_soat_confirm_title;
    return context.l10n.vehicle_soat_form_title;
  }

  /// The scan detected a valid SOAT and the user has not autofilled yet, so the
  /// opt-in banner should be offered (the user decides whether to autofill).
  bool get _canOfferAutofill =>
      !_autofillApplied && (_extraction?.shouldPrefill ?? false);

  @override
  void initState() {
    super.initState();
    _extraction = widget.extraction;
    _startDate = widget.existingSoat?.startDate;
    _expiryDate = widget.existingSoat?.expiryDate;
    _localImagePath = widget.initialLocalImagePath;

    // Si llegamos con un documento ya elegido (p.ej. desde el bottom sheet de
    // creación de vehículo) pero sin OCR previo, escanéalo al abrir para ofrecer
    // el autocompletado. Cuando venimos del escaneo, [extraction] ya viene y no
    // se re-escanea.
    final initialPath = _localImagePath;
    // No re-escanear si ya hay datos pre-llenados (edición de pendiente).
    if (initialPath != null && _extraction == null && widget.existingSoat == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scanDocument(
            initialPath,
            _sourceForPath(initialPath),
            autoApply: true,
          );
        }
      });
    }
  }

  SoatScanSource _sourceForPath(String path) =>
      path.toLowerCase().endsWith('.pdf')
      ? SoatScanSource.pdf
      : SoatScanSource.gallery;

  String? _initialPolicyNumber() => widget.existingSoat?.policyNumber;

  String? _initialInsurer() => widget.existingSoat?.insurer;

  /// Fills the form with the detected SOAT data. Patches every field through
  /// the form (incl. dates) so existing values are overwritten when editing,
  /// and mirrors the dates into state for the validity card.
  void _applyAutofill() {
    final extraction = _extraction;
    if (extraction == null) return;
    _formKey.currentState?.patchValue({
      if (extraction.policyNumber != null)
        'policyNumber': extraction.policyNumber,
      if (extraction.insurer != null) 'insurer': extraction.insurer,
      if (extraction.startDate != null) 'startDate': extraction.startDate,
      if (extraction.expiryDate != null) 'expiryDate': extraction.expiryDate,
    });
    setState(() {
      _startDate = extraction.startDate ?? _startDate;
      _expiryDate = extraction.expiryDate ?? _expiryDate;
      _autofillApplied = true;
    });
  }

  // ── Selección de imagen ──────────────────────────────────────────────────

  // 1 = galería, 2 = PDF
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

    String? pickedPath;
    final SoatScanSource scanSource;

    if (choice == 2) {
      // Seleccionar PDF
      scanSource = SoatScanSource.pdf;
      pickedPath = await SoatDocumentPicker.pickPdf();
    } else {
      // Galería (la captura con cámara se retiró: peor lectura OCR).
      scanSource = SoatScanSource.gallery;
      pickedPath = await SoatDocumentPicker.pickImageFromGallery();
    }

    if (pickedPath == null || !mounted) return;
    setState(() {
      _localImagePath = pickedPath;
      _documentNotRecognized = false;
    });
    await _scanDocument(pickedPath, scanSource);
  }

  /// Best-effort OCR over a document. When [autoApply] is true (document already
  /// chosen, e.g. from the vehicle-creation bottom sheet) the fields are filled
  /// automatically; otherwise the opt-in autofill banner is offered. The
  /// document stays attached even when nothing readable is found.
  Future<void> _scanDocument(
    String path,
    SoatScanSource source, {
    bool autoApply = false,
  }) async {
    setState(() => _scanning = true);
    try {
      final result = await getIt<ScanSoatUseCase>()(
        file: File(path),
        source: source,
      );
      if (!mounted) return;
      setState(() {
        _extraction = result.extraction;
        _autofillApplied = false;
        _documentNotRecognized = false;
      });
      if (autoApply) _applyAutofill();
    } on SoatScanException {
      if (!mounted) return;
      // No bloqueamos al usuario: el documento queda adjunto y mostramos un
      // aviso inline para que verifique el archivo o complete los datos a mano.
      setState(() => _documentNotRecognized = true);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  // ── Envío del formulario ─────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final startDate = _startDate;
    final expiryDate = _expiryDate;
    if (startDate == null || expiryDate == null) return;

    if (!expiryDate.isAfter(startDate)) {
      setState(() => _error = context.l10n.soat_expiry_after_start_error);
      return;
    }

    final values = _formKey.currentState!.value;
    final policyNumber = (values['policyNumber'] as String?)?.trim();
    final insurer = (values['insurer'] as String?)?.trim() ?? '';

    if (_isEditMode) {
      await _saveToBackend(
        policyNumber: policyNumber,
        insurer: insurer,
        startDate: startDate,
        expiryDate: expiryDate,
      );
    } else {
      context.pop(
        PendingManualSoat(
          policyNumber: policyNumber,
          insurer: insurer,
          startDate: startDate,
          expiryDate: expiryDate,
          localImagePath: _localImagePath,
        ),
      );
    }
  }

  Future<void> _saveToBackend({
    String? policyNumber,
    required String insurer,
    required DateTime startDate,
    required DateTime expiryDate,
  }) async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final vehicleId = widget.vehicle!.id!;

    // Subir archivo local si hay uno nuevo seleccionado (imagen o PDF)
    String? documentUrl = widget.existingSoat?.documentUrl;
    if (_localImagePath != null) {
      final ext = _localImagePath!.split('.').last.toLowerCase();
      try {
        documentUrl = await getIt<ImageStorageService>().uploadImage(
          image: XFile(_localImagePath!),
          storagePath:
              'soat/$vehicleId/${DateTime.now().millisecondsSinceEpoch}.$ext',
        );
      } catch (_) {
        if (mounted) {
          setState(() {
            _saving = false;
            _error = context.l10n.soat_upload_error;
          });
        }
        return;
      }
    }

    final soat = SoatModel(
      id: widget.existingSoat?.id ?? '',
      vehicleId: vehicleId,
      policyNumber: policyNumber,
      insurer: insurer,
      startDate: startDate,
      expiryDate: expiryDate,
      documentUrl: documentUrl,
    );

    final result = await getIt<SaveSoatUseCase>()(
      vehicleId: vehicleId,
      soat: soat,
    );

    if (!mounted) return;

    result.fold(
      (error) => setState(() {
        _saving = false;
        _error = error.message;
      }),
      (_) => context.pop(true),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

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
          _appBarTitle(context),
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          FormBuilder(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.vehicle != null) ...[
                    Text(
                      context.l10n.soat_manual_subtitle(widget.vehicle!.name),
                      style: const TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_canOfferAutofill) ...[
                    SoatAutofillBanner(onAutofill: _applyAutofill),
                    const SizedBox(height: 16),
                  ],
                  SoatDocumentSection(
                    localImagePath: _localImagePath,
                    remoteDocumentUrl: _localImagePath == null
                        ? widget.existingSoat?.documentUrl
                        : null,
                    onPickImage: _pickImage,
                    onRemoveLocalImage: () => setState(() {
                      _localImagePath = null;
                      _documentNotRecognized = false;
                    }),
                  ),
                  if (_documentNotRecognized) ...[
                    const SizedBox(height: 10),
                    const SoatNotRecognizedWarning(),
                  ],
                  const SizedBox(height: 20),
                  AppTextField(
                    name: 'policyNumber',
                    labelText: context.l10n.vehicle_soat_policy_number_label,
                    hintText: context.l10n.vehicle_soat_policy_number_hint,
                    initialValue: _initialPolicyNumber(),
                    textInputAction: TextInputAction.next,
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    name: 'insurer',
                    labelText: context.l10n.vehicle_soat_insurer_label,
                    hintText: context.l10n.vehicle_soat_insurer_hint,
                    initialValue: _initialInsurer(),
                    isRequired: true,
                    textInputAction: TextInputAction.done,
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
                          labelText: context.l10n.vehicle_soat_start_date_label,
                          hintText: context.l10n.vehicle_soat_start_date_hint,
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
                              context.l10n.vehicle_soat_expiry_date_label,
                          hintText: context.l10n.vehicle_soat_expiry_date_hint,
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
                  SoatValidityCard(
                    startDate: _startDate,
                    expiryDate: _expiryDate,
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
                        ? context.l10n.soat_saving
                        : _isEditMode
                        ? context.l10n.soat_save_data_btn
                        : context.l10n.vehicle_soat_confirm_button,
                    onPressed: _saving ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
          if (_scanning)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xCC0D0D0F),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.soat_scan_loading,
                        style: const TextStyle(
                          color: AppColors.textOnDarkPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
