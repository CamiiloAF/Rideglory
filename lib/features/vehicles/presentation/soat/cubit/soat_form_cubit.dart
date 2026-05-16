import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/soat_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

part 'soat_form_cubit.freezed.dart';

@freezed
class SoatFormState with _$SoatFormState {
  const factory SoatFormState.initial() = _Initial;
  const factory SoatFormState.loading() = _Loading;
  const factory SoatFormState.success(SoatModel soat) = _Success;
  const factory SoatFormState.error(DomainException error) = _Error;
}

@injectable
class SoatFormCubit extends Cubit<SoatFormState> {
  SoatFormCubit(this._vehicleRepository) : super(const SoatFormState.initial());

  final VehicleRepository _vehicleRepository;
  final formKey = GlobalKey<FormBuilderState>();

  Future<void> submit(String vehicleId) async {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;

    emit(const SoatFormState.loading());

    final values = form.value;
    final soat = SoatModel(
      vehicleId: vehicleId,
      policyNumber: values['policyNumber'] as String,
      insurer: values['insurer'] as String,
      startDate: values['startDate'] as DateTime,
      expiryDate: values['expiryDate'] as DateTime,
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
