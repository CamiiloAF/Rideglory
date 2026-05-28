import 'package:file_picker/file_picker.dart';
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
import 'package:rideglory/features/soat/domain/usecases/save_soat_usecase.dart';
import 'package:rideglory/features/soat/presentation/scan/soat_scan_launcher.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_autofill_badge.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_document_section.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_ocr_banner.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_scan_button.dart';
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
  String? _error;
  SoatExtraction? _extraction;

  bool get _isEditMode => widget.vehicle?.id != null;

  /// OCR data is only applied when it cleared the prefill threshold.
  SoatExtraction? get _prefill =>
      (_extraction?.shouldPrefill ?? false) ? _extraction : null;

  @override
  void initState() {
    super.initState();
    _extraction = widget.extraction;
    _startDate = _prefill?.startDate ?? widget.existingSoat?.startDate;
    _expiryDate = _prefill?.expiryDate ?? widget.existingSoat?.expiryDate;
    _localImagePath = widget.initialLocalImagePath;
  }

  String? _initialPolicyNumber() =>
      _prefill?.policyNumber ?? widget.existingSoat?.policyNumber;

  String? _initialInsurer() =>
      _prefill?.insurer ?? widget.existingSoat?.insurer;

  Future<void> _rescan() async {
    setState(() => _scanning = true);
    final outcome = await SoatScanLauncher.launch(context);
    if (!mounted) return;
    setState(() {
      _scanning = false;
      if (outcome != null) {
        _extraction = outcome.extraction;
        _localImagePath = outcome.filePath;
        if (_prefill != null) {
          _startDate = _prefill!.startDate ?? _startDate;
          _expiryDate = _prefill!.expiryDate ?? _expiryDate;
        }
      }
    });
  }

  // ── Selección de imagen ──────────────────────────────────────────────────

  // 0 = cámara, 1 = galería, 2 = PDF
  Future<void> _pickImage() async {
    if (!mounted) return;
    final choice = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.darkBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.darkBorderPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppButton(
                label: context.l10n.soat_source_camera,
                icon: Icons.camera_alt_outlined,
                onPressed: () =>
                    // Custom: sheetCtx.pop() — required pattern for showModalBottomSheet typed result return.
                    Navigator.of(sheetCtx).pop(0),
                variant: AppButtonVariant.secondary,
                style: AppButtonStyle.outlined,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: context.l10n.soat_source_gallery,
                icon: Icons.photo_library_outlined,
                onPressed: () =>
                    // Custom: sheetCtx.pop() — required pattern for showModalBottomSheet typed result return.
                    Navigator.of(sheetCtx).pop(1),
                variant: AppButtonVariant.secondary,
                style: AppButtonStyle.outlined,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: context.l10n.soat_source_pdf,
                icon: Icons.picture_as_pdf_outlined,
                onPressed: () =>
                    // Custom: sheetCtx.pop() — required pattern for showModalBottomSheet typed result return.
                    Navigator.of(sheetCtx).pop(2),
                variant: AppButtonVariant.secondary,
                style: AppButtonStyle.outlined,
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == 2) {
      // Seleccionar PDF
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null && mounted) {
        setState(() => _localImagePath = result.files.single.path!);
      }
    } else {
      // Cámara o galería
      final source = choice == 0 ? ImageSource.camera : ImageSource.gallery;
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        setState(() => _localImagePath = file.path);
      }
    }
  }

  // ── Envío del formulario ─────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final startDate = _startDate;
    final expiryDate = _expiryDate;
    if (startDate == null || expiryDate == null) return;
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
          _isEditMode
              ? context.l10n.soat_edit_title
              : context.l10n.vehicle_soat_form_title,
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
                  context.l10n.soat_manual_subtitle(widget.vehicle!.name),
                  style: const TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SoatScanButton(onPressed: _rescan, isLoading: _scanning),
              const SizedBox(height: 16),
              if (_prefill != null) ...[
                SoatOcrBanner(
                  needsCarefulReview: _prefill!.hasMediumConfidence,
                ),
                const SizedBox(height: 16),
              ],
              SoatDocumentSection(
                localImagePath: _localImagePath,
                remoteDocumentUrl: _localImagePath == null
                    ? widget.existingSoat?.documentUrl
                    : null,
                onPickImage: _pickImage,
                onRemoveLocalImage: () =>
                    setState(() => _localImagePath = null),
              ),
              const SizedBox(height: 20),
              AppTextField(
                key: ValueKey('policyNumber_${_prefill?.policyNumber}'),
                name: 'policyNumber',
                labelText: context.l10n.vehicle_soat_policy_number_label,
                hintText: context.l10n.vehicle_soat_policy_number_hint,
                initialValue: _initialPolicyNumber(),
                suffixIcon:
                    (_prefill?.isFieldAutofilled(SoatField.policyNumber) ??
                        false)
                    ? SoatAutofillBadge(
                        confidence: _prefill!.confidenceOf(
                          SoatField.policyNumber,
                        ),
                      )
                    : null,
                textInputAction: TextInputAction.next,
                enabled: !_saving,
              ),
              const SizedBox(height: 12),
              AppTextField(
                key: ValueKey('insurer_${_prefill?.insurer}'),
                name: 'insurer',
                labelText: context.l10n.vehicle_soat_insurer_label,
                hintText: context.l10n.vehicle_soat_insurer_hint,
                initialValue: _initialInsurer(),
                suffixIcon:
                    (_prefill?.isFieldAutofilled(SoatField.insurer) ?? false)
                    ? SoatAutofillBadge(
                        confidence: _prefill!.confidenceOf(SoatField.insurer),
                      )
                    : null,
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
                      onChanged: (date) => setState(() => _startDate = date),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppDatePicker(
                      key: ValueKey(
                        'expiryDate_${_expiryDate?.toIso8601String()}',
                      ),
                      fieldName: 'expiryDate',
                      labelText: context.l10n.vehicle_soat_expiry_date_label,
                      hintText: context.l10n.vehicle_soat_expiry_date_hint,
                      initialValue: _expiryDate,
                      isRequired: true,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      onChanged: (date) => setState(() => _expiryDate = date),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SoatValidityCard(startDate: _startDate, expiryDate: _expiryDate),
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
    );
  }
}
