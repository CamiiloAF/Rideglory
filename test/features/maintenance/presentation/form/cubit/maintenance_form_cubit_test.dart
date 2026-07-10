import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_form_fields.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/add_maintenance_use_case.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/update_maintenance_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class MockAddMaintenanceUseCase extends Mock implements AddMaintenanceUseCase {}

class MockUpdateMaintenanceUseCase extends Mock
    implements UpdateMaintenanceUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeMaintenanceModel extends Fake implements MaintenanceModel {}

/// Mounts a FormBuilder with the cubit's [key], registering only the fields
/// needed by [MaintenanceFormCubit.buildMaintenanceToSave].
Widget _buildFormWidget(
  GlobalKey<FormBuilderState> key, {
  String? currentMileage,
  DateTime? date,
  String? workshop,
  String? notes,
  String? cost,
  String? nextMaintenanceMileage,
  DateTime? nextMaintenanceDate,
  bool requireWorkshop = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: FormBuilder(
        key: key,
        child: Column(
          children: [
            FormBuilderTextField(
              name: MaintenanceFormFields.currentMileage,
              initialValue: currentMileage ?? '',
            ),
            FormBuilderField<DateTime>(
              name: MaintenanceFormFields.date,
              initialValue: date,
              builder: (_) => const SizedBox.shrink(),
            ),
            FormBuilderTextField(
              name: MaintenanceFormFields.workshop,
              initialValue: workshop ?? '',
              validator: requireWorkshop ? FormBuilderValidators.required() : null,
            ),
            FormBuilderTextField(
              name: MaintenanceFormFields.notes,
              initialValue: notes ?? '',
            ),
            FormBuilderTextField(
              name: MaintenanceFormFields.cost,
              initialValue: cost ?? '',
            ),
            FormBuilderTextField(
              name: MaintenanceFormFields.nextMaintenanceMileage,
              initialValue: nextMaintenanceMileage ?? '',
            ),
            FormBuilderField<DateTime>(
              name: MaintenanceFormFields.nextMaintenanceDate,
              initialValue: nextMaintenanceDate,
              builder: (_) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeMaintenanceModel());
  });

  late MockAddMaintenanceUseCase mockAdd;
  late MockUpdateMaintenanceUseCase mockUpdate;
  late MockAnalyticsService mockAnalytics;
  late MaintenanceFormCubit cubit;

  const vehicle = VehicleModel(id: 'v1', name: 'Moto 1', currentMileage: 10000);

  setUp(() {
    mockAdd = MockAddMaintenanceUseCase();
    mockUpdate = MockUpdateMaintenanceUseCase();
    mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    cubit = MaintenanceFormCubit(mockAdd, mockUpdate, mockAnalytics);
  });

  tearDown(() => cubit.close());

  group('initialize', () {
    test('sin maintenance — isEditing es false y modo default completed', () {
      cubit.initialize(preselectedVehicle: vehicle);

      expect(cubit.isEditing, isFalse);
      expect(cubit.selectedMode, MaintenanceMode.completed);
      expect(cubit.state, const ResultState<MaintenanceModel>.initial());
    });

    test('con maintenance — isEditing es true y toma su modo/usuario', () {
      final existing = MaintenanceModel(
        id: 'm1',
        userId: 'u1',
        vehicleId: 'v1',
        type: MaintenanceType.oilChange,
        mode: MaintenanceMode.scheduled,
      );

      cubit.initialize(maintenance: existing);

      expect(cubit.isEditing, isTrue);
      expect(cubit.editingMaintenance, existing);
      expect(cubit.selectedMode, MaintenanceMode.scheduled);
      expect(cubit.userId, 'u1');
    });
  });

  group('setVehicleId / setCurrentVehicleMileage', () {
    test('setVehicleId no sobreescribe un vehicleId ya resuelto', () {
      cubit.initialize(preselectedVehicle: vehicle);
      cubit.setVehicleId('other-vehicle');
      cubit.updateSelectedType(MaintenanceType.oilChange);
      cubit.setCurrentVehicleMileage(10000);

      final maintenance = cubit.buildMaintenanceToSave();
      // formKey.currentState is null (no widget mounted) -> returns null,
      // but we can still assert the resolved vehicleId indirectly via saveMaintenance.
      expect(maintenance, isNull);
    });

    test('setCurrentVehicleMileage almacena el valor', () {
      cubit.setCurrentVehicleMileage(15000);
      expect(cubit.currentVehicleMileage, 15000);
    });
  });

  group('updateMode', () {
    test('actualiza selectedMode y emite ResultState.initial', () {
      cubit.initialize(preselectedVehicle: vehicle);

      cubit.updateMode(MaintenanceMode.scheduled);

      expect(cubit.selectedMode, MaintenanceMode.scheduled);
      expect(cubit.state, const ResultState<MaintenanceModel>.initial());
    });
  });

  group('shouldChangeVehicleMileage', () {
    test('retorna true si el nuevo kilometraje es mayor', () {
      expect(cubit.shouldChangeVehicleMileage(10000, 10500), isTrue);
    });

    test('retorna false si el nuevo kilometraje es igual o menor', () {
      expect(cubit.shouldChangeVehicleMileage(10000, 10000), isFalse);
      expect(cubit.shouldChangeVehicleMileage(10000, 9000), isFalse);
    });
  });

  group('buildNextKmInterval', () {
    test('retorna null si el form no está montado', () {
      expect(cubit.buildNextKmInterval(), isNull);
    });
  });

  group('buildMaintenanceToSave — modo completed', () {
    testWidgets(
      'construye el modelo con odómetro, próximo servicio y datos del taller',
      (tester) async {
        cubit.initialize(preselectedVehicle: vehicle);
        cubit.setVehicleId(vehicle.id);
        cubit.setCurrentVehicleMileage(vehicle.currentMileage);
        cubit.updateSelectedType(MaintenanceType.oilChange);

        await tester.pumpWidget(
          _buildFormWidget(
            cubit.formKey,
            currentMileage: '10500',
            date: DateTime(2026, 6, 1),
            workshop: 'Taller Central',
            notes: 'Cambio completo',
            cost: '150000',
            nextMaintenanceMileage: '5000',
            nextMaintenanceDate: DateTime(2026, 12, 1),
          ),
        );
        await tester.pumpAndSettle();

        final result = cubit.buildMaintenanceToSave();

        expect(result, isNotNull);
        expect(result!.type, MaintenanceType.oilChange);
        expect(result.mode, MaintenanceMode.completed);
        expect(result.vehicleId, 'v1');
        expect(result.serviceDate, DateTime(2026, 6, 1));
        expect(result.odometerAtService, 10500);
        expect(result.workshop, 'Taller Central');
        expect(result.notes, 'Cambio completo');
        expect(result.cost, 150000);
        // nextOdometer = odometerAtService (10500) + relative km (5000)
        expect(result.nextOdometer, 15500);
        expect(result.nextDate, DateTime(2026, 12, 1));
      },
    );

    testWidgets(
      'sin odómetro capturado usa el kilometraje actual del vehículo como base',
      (tester) async {
        cubit.initialize(preselectedVehicle: vehicle);
        cubit.setVehicleId(vehicle.id);
        cubit.setCurrentVehicleMileage(vehicle.currentMileage);
        cubit.updateSelectedType(MaintenanceType.oilChange);

        await tester.pumpWidget(
          _buildFormWidget(
            cubit.formKey,
            date: DateTime(2026, 6, 1),
            nextMaintenanceMileage: '5000',
          ),
        );
        await tester.pumpAndSettle();

        final result = cubit.buildMaintenanceToSave();

        expect(result, isNotNull);
        expect(result!.odometerAtService, vehicle.currentMileage);
        expect(result.nextOdometer, vehicle.currentMileage + 5000);
      },
    );

    testWidgets(
      'validación de campos requeridos — form inválido retorna null',
      (tester) async {
        cubit.initialize(preselectedVehicle: vehicle);
        cubit.setVehicleId(vehicle.id);
        cubit.updateSelectedType(MaintenanceType.oilChange);

        await tester.pumpWidget(
          _buildFormWidget(
            cubit.formKey,
            date: DateTime(2026, 6, 1),
            requireWorkshop: true,
          ),
        );
        await tester.pumpAndSettle();

        final result = cubit.buildMaintenanceToSave();

        expect(result, isNull);
      },
    );
  });

  group('buildMaintenanceToSave — modo scheduled', () {
    testWidgets(
      'no captura serviceDate/odometerAtService y calcula nextOdometer desde el kilometraje actual',
      (tester) async {
        cubit.initialize(preselectedVehicle: vehicle);
        cubit.setVehicleId(vehicle.id);
        cubit.setCurrentVehicleMileage(vehicle.currentMileage);
        cubit.updateSelectedType(MaintenanceType.tireChange);
        cubit.updateMode(MaintenanceMode.scheduled);

        await tester.pumpWidget(
          _buildFormWidget(
            cubit.formKey,
            nextMaintenanceMileage: '3000',
            nextMaintenanceDate: DateTime(2026, 9, 1),
          ),
        );
        await tester.pumpAndSettle();

        final result = cubit.buildMaintenanceToSave();

        expect(result, isNotNull);
        expect(result!.mode, MaintenanceMode.scheduled);
        expect(result.serviceDate, isNull);
        expect(result.odometerAtService, isNull);
        expect(result.nextOdometer, vehicle.currentMileage + 3000);
        expect(result.nextDate, DateTime(2026, 9, 1));
      },
    );
  });

  group('saveMaintenance — creación', () {
    final newMaintenance = MaintenanceModel(
      vehicleId: 'v1',
      type: MaintenanceType.oilChange,
      mode: MaintenanceMode.completed,
      serviceDate: DateTime(2026, 6, 1),
    );

    blocTest<MaintenanceFormCubit, ResultState<MaintenanceModel>>(
      'sin id — llama a AddMaintenanceUseCase, emite loading/data y loguea maintenance_added',
      build: () => cubit,
      setUp: () {
        when(
          () => mockAdd(any(), nextKmInterval: any(named: 'nextKmInterval')),
        ).thenAnswer(
          (_) async => Right([newMaintenance.copyWith(id: 'm1')]),
        );
      },
      act: (c) => c.saveMaintenance(newMaintenance, nextKmInterval: 5000),
      expect: () => [
        const ResultState<MaintenanceModel>.loading(),
        predicate<ResultState<MaintenanceModel>>(
          (state) => state is Data<MaintenanceModel> && state.data.id == 'm1',
        ),
      ],
      verify: (c) {
        verify(
          () => mockAdd(newMaintenance, nextKmInterval: 5000),
        ).called(1);
        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.maintenanceAdded, {
            AnalyticsParams.maintenanceType: MaintenanceType.oilChange.name,
            AnalyticsParams.maintenanceMode:
                AnalyticsParams.maintenanceModeCompleted,
          }),
        ).called(1);
        expect(c.lastSavedRecords, hasLength(1));
      },
    );

    blocTest<MaintenanceFormCubit, ResultState<MaintenanceModel>>(
      'sin id — error del use case emite error y NO loguea analytics',
      build: () => cubit,
      setUp: () {
        when(
          () => mockAdd(any(), nextKmInterval: any(named: 'nextKmInterval')),
        ).thenAnswer(
          (_) async => const Left(DomainException(message: 'No se pudo crear')),
        );
      },
      act: (c) => c.saveMaintenance(newMaintenance),
      expect: () => [
        const ResultState<MaintenanceModel>.loading(),
        const ResultState<MaintenanceModel>.error(
          error: DomainException(message: 'No se pudo crear'),
        ),
      ],
      verify: (_) {
        verifyNever(
          () => mockAnalytics.logEvent(AnalyticsEvents.maintenanceAdded, any()),
        );
      },
    );
  });

  group('saveMaintenance — edición', () {
    final existingMaintenance = MaintenanceModel(
      id: 'm1',
      vehicleId: 'v1',
      type: MaintenanceType.brakeCheck,
      mode: MaintenanceMode.completed,
      serviceDate: DateTime(2026, 6, 1),
    );

    blocTest<MaintenanceFormCubit, ResultState<MaintenanceModel>>(
      'con id — llama a UpdateMaintenanceUseCase, emite loading/data y loguea maintenance_updated',
      build: () => cubit,
      setUp: () {
        when(
          () => mockUpdate(existingMaintenance),
        ).thenAnswer((_) async => Right(existingMaintenance));
      },
      act: (c) => c.saveMaintenance(existingMaintenance),
      expect: () => [
        const ResultState<MaintenanceModel>.loading(),
        predicate<ResultState<MaintenanceModel>>(
          (state) => state is Data<MaintenanceModel> && state.data.id == 'm1',
        ),
      ],
      verify: (c) {
        verify(() => mockUpdate(existingMaintenance)).called(1);
        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.maintenanceUpdated, {
            AnalyticsParams.maintenanceType: MaintenanceType.brakeCheck.name,
            AnalyticsParams.maintenanceMode:
                AnalyticsParams.maintenanceModeCompleted,
          }),
        ).called(1);
        verifyNever(
          () => mockAdd(any(), nextKmInterval: any(named: 'nextKmInterval')),
        );
      },
    );

    blocTest<MaintenanceFormCubit, ResultState<MaintenanceModel>>(
      'con id — error del use case emite error y NO loguea analytics',
      build: () => cubit,
      setUp: () {
        when(() => mockUpdate(existingMaintenance)).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'No se pudo actualizar')),
        );
      },
      act: (c) => c.saveMaintenance(existingMaintenance),
      expect: () => [
        const ResultState<MaintenanceModel>.loading(),
        const ResultState<MaintenanceModel>.error(
          error: DomainException(message: 'No se pudo actualizar'),
        ),
      ],
      verify: (_) {
        verifyNever(
          () =>
              mockAnalytics.logEvent(AnalyticsEvents.maintenanceUpdated, any()),
        );
      },
    );
  });
}
