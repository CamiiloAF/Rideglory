import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/image_storage_service.dart';
import 'package:rideglory/features/vehicles/domain/models/soat_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

part 'soat_form_cubit.freezed.dart';

@freezed
class SoatFormState with _$SoatFormState {
  const factory SoatFormState.initial() = _Initial;
  const factory SoatFormState.datesUpdated({
    required DateTime? startDate,
    required DateTime? expiryDate,
  }) = _DatesUpdated;
  const factory SoatFormState.soatLoaded(SoatModel soat) = _SoatLoaded;
  const factory SoatFormState.loading() = _Loading;
  const factory SoatFormState.success(SoatModel soat) = _Success;
  const factory SoatFormState.error(DomainException error) = _Error;
}

@injectable
class SoatFormCubit extends Cubit<SoatFormState> {
  SoatFormCubit(this._vehicleRepository, this._imageStorageService)
    : super(const SoatFormState.initial());

  final VehicleRepository _vehicleRepository;
  final ImageStorageService _imageStorageService;
  final formKey = GlobalKey<FormBuilderState>();

  DateTime? _startDate;
  DateTime? _expiryDate;
  String? _existingDocumentUrl;

  DateTime? get currentStartDate => _startDate;
  DateTime? get currentExpiryDate => _expiryDate;

  bool get areDatesValid =>
      _startDate != null &&
      _expiryDate != null &&
      _startDate!.isBefore(_expiryDate!);

  void onDatesChanged({DateTime? startDate, DateTime? expiryDate}) {
    if (startDate != null) _startDate = startDate;
    if (expiryDate != null) _expiryDate = expiryDate;
    emit(
      SoatFormState.datesUpdated(
        startDate: _startDate,
        expiryDate: _expiryDate,
      ),
    );
  }

  Future<void> loadExistingSoat(String vehicleId) async {
    final result = await _vehicleRepository.getSoat(vehicleId);
    result.fold((_) {}, (soat) {
      _startDate = soat.startDate;
      _expiryDate = soat.expiryDate;
      _existingDocumentUrl = soat.documentUrl;
      emit(SoatFormState.soatLoaded(soat));
    });
  }

  Future<void> submit(String vehicleId, {XFile? documentImage}) async {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;

    if (_startDate == null || _expiryDate == null) return;

    if (!_startDate!.isBefore(_expiryDate!)) {
      emit(
        const SoatFormState.error(
          DomainException(
            message:
                'La fecha de inicio debe ser anterior a la fecha de vencimiento',
          ),
        ),
      );
      return;
    }

    emit(const SoatFormState.loading());

    String? documentUrl;
    if (documentImage != null) {
      try {
        documentUrl = await _imageStorageService.uploadImage(
          image: documentImage,
          storagePath:
              'soat/$vehicleId/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } catch (e) {
        final msg = e is DomainException
            ? e.message
            : 'Error al subir el documento';
        emit(SoatFormState.error(DomainException(message: msg)));
        return;
      }
    }

    final values = form.value;
    final soat = SoatModel(
      vehicleId: vehicleId,
      policyNumber: values['policyNumber'] as String?,
      insurer: values['insurer'] as String,
      startDate: _startDate!,
      expiryDate: _expiryDate!,
      documentUrl: documentUrl ?? _existingDocumentUrl,
    );

    final result = await _vehicleRepository.upsertSoat(
      vehicleId: vehicleId,
      soat: soat,
    );

    result.fold(
      (error) => emit(SoatFormState.error(error)),
      (saved) => emit(SoatFormState.success(saved)),
    );
  }
}
