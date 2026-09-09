import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/usecases/update_emergency_contact_usecase.dart';

@injectable
class SaveEmergencyContactCubit extends Cubit<ResultState<Unit>> {
  SaveEmergencyContactCubit(this._updateEmergencyContact)
    : super(const ResultState.initial());

  final UpdateEmergencyContactUseCase _updateEmergencyContact;

  Future<void> save({
    required String name,
    required String phone,
    String? relationship,
  }) async {
    emit(const ResultState.loading());
    final result = await _updateEmergencyContact(
      name: name,
      phone: phone,
      relationship: relationship,
    );
    emit(
      result.fold(
        (error) => ResultState.error(error: error),
        (_) => const ResultState.data(data: unit),
      ),
    );
  }
}
