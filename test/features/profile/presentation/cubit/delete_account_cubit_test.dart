import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/profile/domain/profile_error_code.dart';
import 'package:rideglory/features/profile/domain/usecases/delete_account_usecase.dart';
import 'package:rideglory/features/profile/presentation/cubit/delete_account_cubit.dart';
import 'package:rideglory/features/profile/presentation/cubit/delete_account_state.dart';

class _MockDeleteAccountUseCase extends Mock implements DeleteAccountUseCase {}

void main() {
  late _MockDeleteAccountUseCase deleteAccount;

  setUp(() {
    deleteAccount = _MockDeleteAccountUseCase();
  });

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'emits [inProgress, done] when the Edge Function confirms the deletion',
    setUp: () {
      when(() => deleteAccount()).thenAnswer((_) async => const Right(null));
    },
    build: () => DeleteAccountCubit(deleteAccount),
    act: (cubit) => cubit.confirm(),
    expect: () => const [
      DeleteAccountState.inProgress(),
      DeleteAccountState.done(),
    ],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'emits [inProgress, blocked] when the rider organizes an active event',
    setUp: () {
      when(() => deleteAccount()).thenAnswer(
        (_) async => const Left(
          DomainException(message: ProfileErrorCode.activeEventOrganizer),
        ),
      );
    },
    build: () => DeleteAccountCubit(deleteAccount),
    act: (cubit) => cubit.confirm(),
    expect: () => const [
      DeleteAccountState.inProgress(),
      DeleteAccountState.blocked(),
    ],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'emits [inProgress, error] on any other failure, never a silent logout',
    setUp: () {
      when(() => deleteAccount()).thenAnswer(
        (_) async =>
            const Left(DomainException(message: ProfileErrorCode.unknown)),
      );
    },
    build: () => DeleteAccountCubit(deleteAccount),
    act: (cubit) => cubit.confirm(),
    expect: () => const [
      DeleteAccountState.inProgress(),
      DeleteAccountState.error(
        error: DomainException(message: ProfileErrorCode.unknown),
      ),
    ],
  );
}
