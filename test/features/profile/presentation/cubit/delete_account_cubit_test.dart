// Tests de DeleteAccountCubit: máquina de estados + guard de doble-tap (AC4).

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/profile/presentation/cubits/delete_account_cubit.dart';
import 'package:rideglory/features/users/domain/use_cases/delete_account_use_case.dart';

class MockDeleteAccountUseCase extends Mock implements DeleteAccountUseCase {}

void main() {
  late MockDeleteAccountUseCase mockUseCase;
  late DeleteAccountCubit cubit;

  setUp(() {
    mockUseCase = MockDeleteAccountUseCase();
    cubit = DeleteAccountCubit(mockUseCase);
  });

  tearDown(() => cubit.close());

  blocTest<DeleteAccountCubit, ResultState<Nothing>>(
    'deleteAccount exitoso emite loading -> data(Nothing)',
    build: () {
      when(() => mockUseCase()).thenAnswer((_) async => const Right(Nothing()));
      return cubit;
    },
    act: (cubit) => cubit.deleteAccount(),
    expect: () => [
      const ResultState<Nothing>.loading(),
      const ResultState<Nothing>.data(data: Nothing()),
    ],
  );

  blocTest<DeleteAccountCubit, ResultState<Nothing>>(
    'deleteAccount fallido emite loading -> error',
    build: () {
      when(() => mockUseCase()).thenAnswer(
        (_) async =>
            const Left(DomainException(message: 'No se pudo eliminar')),
      );
      return cubit;
    },
    act: (cubit) => cubit.deleteAccount(),
    expect: () => [
      const ResultState<Nothing>.loading(),
      const ResultState<Nothing>.error(
        error: DomainException(message: 'No se pudo eliminar'),
      ),
    ],
  );

  test(
    'guard de doble-tap — un segundo llamado mientras loading no dispara otra call',
    () async {
      when(() => mockUseCase()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const Right(Nothing());
      });

      final first = cubit.deleteAccount();
      final second = cubit.deleteAccount();

      await Future.wait([first, second]);

      verify(() => mockUseCase()).called(1);
    },
  );
}
