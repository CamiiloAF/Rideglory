import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/features/tecnomecanica/data/dto/tecnomecanica_dto.dart';
import 'package:rideglory/features/tecnomecanica/data/repository/tecnomecanica_repository_impl.dart';
import 'package:rideglory/features/tecnomecanica/data/service/tecnomecanica_service.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';

class MockTecnomecanicaService extends Mock implements TecnomecanicaService {}

class FakeMap extends Fake implements Map<String, dynamic> {}

DioException _dioException({int? statusCode}) => DioException(
  requestOptions: RequestOptions(path: '/vehicles/v1/tecnomecanica'),
  type: statusCode == null
      ? DioExceptionType.connectionError
      : DioExceptionType.badResponse,
  response: statusCode == null
      ? null
      : Response(
          requestOptions: RequestOptions(path: '/vehicles/v1/tecnomecanica'),
          statusCode: statusCode,
        ),
);

void main() {
  late MockTecnomecanicaService mockService;
  late TecnomecanicaRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeMap());
  });

  setUp(() {
    mockService = MockTecnomecanicaService();
    repository = TecnomecanicaRepositoryImpl(mockService);
  });

  final dto = TecnomecanicaDto(
    id: 'rtm-1',
    vehicleId: 'v1',
    cdaName: 'CDA Bogotá',
    startDate: DateTime(2026, 1, 1),
    expiryDate: DateTime(2027, 1, 1),
  );

  final model = TecnomecanicaModel(
    id: '',
    vehicleId: 'v1',
    cdaName: 'CDA Bogotá',
    startDate: DateTime(2026, 1, 1),
    expiryDate: DateTime(2027, 1, 1),
  );

  group('getTecnomecanica', () {
    test('camino feliz — retorna el RTM del vehículo', () async {
      when(
        () => mockService.getTecnomecanica('v1'),
      ).thenAnswer((_) async => dto);

      final result = await repository.getTecnomecanica('v1');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (data) => expect(data?.id, 'rtm-1'),
      );
    });

    test('404 — retorna Right(null) (vehículo sin RTM o exento)', () async {
      when(
        () => mockService.getTecnomecanica('v1'),
      ).thenThrow(_dioException(statusCode: 404));

      final result = await repository.getTecnomecanica('v1');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (data) => expect(data, isNull));
    });

    test('otro DioException — retorna Left', () async {
      when(
        () => mockService.getTecnomecanica('v1'),
      ).thenThrow(_dioException());

      final result = await repository.getTecnomecanica('v1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('saveTecnomecanica', () {
    test('camino feliz — construye el request DTO y retorna el modelo guardado', () async {
      when(
        () => mockService.saveTecnomecanica('v1', any()),
      ).thenAnswer((_) async => dto);

      final result = await repository.saveTecnomecanica(
        vehicleId: 'v1',
        tecnomecanica: model,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (data) => expect(data.id, 'rtm-1'),
      );

      final captured = verify(
        () => mockService.saveTecnomecanica('v1', captureAny()),
      ).captured;
      final requestBody = captured.single as Map<String, dynamic>;
      expect(requestBody['cdaName'], 'CDA Bogotá');
    });

    test('camino de error — DioException retorna Left', () async {
      when(
        () => mockService.saveTecnomecanica('v1', any()),
      ).thenThrow(_dioException());

      final result = await repository.saveTecnomecanica(
        vehicleId: 'v1',
        tecnomecanica: model,
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('deleteTecnomecanica', () {
    test('camino feliz — retorna Right(unit)', () async {
      when(() => mockService.deleteTecnomecanica('v1')).thenAnswer((_) async {});

      final result = await repository.deleteTecnomecanica('v1');

      expect(result.isRight(), isTrue);
      verify(() => mockService.deleteTecnomecanica('v1')).called(1);
    });

    test('camino de error — DioException retorna Left', () async {
      when(
        () => mockService.deleteTecnomecanica('v1'),
      ).thenThrow(_dioException());

      final result = await repository.deleteTecnomecanica('v1');

      expect(result.isLeft(), isTrue);
    });
  });
}
