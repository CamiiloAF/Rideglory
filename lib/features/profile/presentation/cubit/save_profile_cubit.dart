import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/blood_type.dart';
import '../../domain/usecases/update_profile_usecase.dart';

/// Estado de guardado de la pantalla "Editar perfil".
@injectable
class SaveProfileCubit extends Cubit<ResultState<Unit>> {
  SaveProfileCubit(this._updateProfile) : super(const ResultState.initial());

  final UpdateProfileUseCase _updateProfile;

  Future<void> save({
    String? fullName,
    String? phone,
    DateTime? birthDate,
    String? residenceCity,
    String? eps,
    String? medicalInsurance,
    BloodType? bloodType,
  }) async {
    emit(const ResultState.loading());
    final result = await _updateProfile(
      fullName: fullName,
      phone: phone,
      birthDate: birthDate,
      residenceCity: residenceCity,
      eps: eps,
      medicalInsurance: medicalInsurance,
      bloodType: bloodType,
    );
    emit(
      result.fold(
        (error) => ResultState.error(error: error),
        (_) => const ResultState.data(data: unit),
      ),
    );
  }
}
