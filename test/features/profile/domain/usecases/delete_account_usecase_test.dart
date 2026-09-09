import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/profile/domain/profile_error_code.dart';
import 'package:rideglory/features/profile/domain/profile_repository.dart';
import 'package:rideglory/features/profile/domain/usecases/delete_account_usecase.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepository repository;
  late DeleteAccountUseCase useCase;

  setUp(() {
    repository = _MockProfileRepository();
    useCase = DeleteAccountUseCase(repository);
  });

  test('returns Right on success', () async {
    when(
      () => repository.deleteAccount(),
    ).thenAnswer((_) async => const Right(null));

    final result = await useCase();

    expect(result, const Right<DomainException, void>(null));
  });

  test('propagates the active-event-organizer block', () async {
    when(() => repository.deleteAccount()).thenAnswer(
      (_) async => const Left(
        DomainException(message: ProfileErrorCode.activeEventOrganizer),
      ),
    );

    final result = await useCase();

    expect(
      result,
      const Left<DomainException, void>(
        DomainException(message: ProfileErrorCode.activeEventOrganizer),
      ),
    );
  });
}
