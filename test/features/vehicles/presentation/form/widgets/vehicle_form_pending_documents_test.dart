// Sección 8 — orquestación SOAT/RTM en la creación de vehículo (casos 8.2,
// 8.3, 8.4 del QA checklist).
//
// Cubre el comportamiento real de `_savePendingDocumentsAndPop` en
// `VehicleFormView`: tras crear un vehículo con SOAT y/o RTM pendientes
// (`state.pendingManualSoat` / `state.pendingRtm`), el listener del form debe
// invocar `VehicleRepository.upsertSoat` y/o `SaveTecnomecanicaUseCase` antes
// de cerrar el formulario, sin necesidad de rellenar el formulario completo
// (se dispara directamente empujando el estado "vehicleResult data" al mock
// de `VehicleFormCubit`, que es exactamente lo que hace `saveVehicle()` tras
// un guardado exitoso).
//
// No cubre 8.1 (SOAT con imagen adjunta → navega a SoatManualCapturePage en
// vez de guardar directo) ni 8.5 (fallo de subida de imagen específico) — ver
// notas al final del archivo.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/image_storage_service.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/save_tecnomecanica_usecase.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_soat_form_data.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_view.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockVehicleFormCubit extends MockCubit<VehicleFormState>
    implements VehicleFormCubit {}

class MockVehicleCubit extends MockCubit<ResultState<List<VehicleModel>>>
    implements VehicleCubit {}

class MockFormImageCubit extends MockCubit<ResultState<FormImageData>>
    implements FormImageCubit {}

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockSaveTecnomecanicaUseCase extends Mock
    implements SaveTecnomecanicaUseCase {}

class MockImageStorageService extends Mock implements ImageStorageService {}

class FakeVehicleSoatFormData extends Fake implements VehicleSoatFormData {}

class FakeTecnomecanicaModel extends Fake implements TecnomecanicaModel {}

// ─── Fixtures ────────────────────────────────────────────────────────────────

const _savedVehicle = VehicleModel(
  id: 'v-new-1',
  name: 'Honda CB500',
  currentMileage: 100,
);

final _pendingSoat = PendingManualSoat(
  insurer: 'Sura',
  startDate: DateTime(2026, 1, 1),
  expiryDate: DateTime(2027, 1, 1),
);

final _pendingRtm = PendingRtm(
  cdaName: 'CDA Bogotá',
  startDate: DateTime(2026, 1, 1),
  expiryDate: DateTime(2027, 1, 1),
);

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrapWithProviders({
  required MockVehicleFormCubit formCubit,
  required MockVehicleCubit vehicleCubit,
  required MockFormImageCubit imageCubit,
}) {
  final router = GoRouter(
    initialLocation: '/form',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('home')),
        routes: [
          GoRoute(
            path: 'form',
            builder: (_, _) => MultiBlocProvider(
              providers: [
                BlocProvider<VehicleFormCubit>.value(value: formCubit),
                BlocProvider<VehicleCubit>.value(value: vehicleCubit),
                BlocProvider<FormImageCubit>.value(value: imageCubit),
              ],
              child: const VehicleFormView(),
            ),
          ),
        ],
      ),
    ],
  );

  return MaterialApp.router(
    theme: AppTheme.darkTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    routerConfig: router,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeVehicleSoatFormData());
    registerFallbackValue(FakeTecnomecanicaModel());
    registerFallbackValue(_savedVehicle);
  });

  late MockVehicleFormCubit formCubit;
  late MockVehicleCubit vehicleCubit;
  late MockFormImageCubit imageCubit;
  late MockVehicleRepository vehicleRepository;
  late MockSaveTecnomecanicaUseCase saveTecnomecanicaUseCase;
  late MockImageStorageService imageStorageService;
  late StreamController<VehicleFormState> stateController;

  setUp(() {
    formCubit = MockVehicleFormCubit();
    vehicleCubit = MockVehicleCubit();
    imageCubit = MockFormImageCubit();
    vehicleRepository = MockVehicleRepository();
    saveTecnomecanicaUseCase = MockSaveTecnomecanicaUseCase();
    imageStorageService = MockImageStorageService();
    stateController = StreamController<VehicleFormState>.broadcast();

    final initialState = VehicleFormState();
    when(() => formCubit.state).thenReturn(initialState);
    when(() => formCubit.formKey).thenReturn(GlobalKey());
    whenListen(
      formCubit,
      stateController.stream,
      initialState: initialState,
    );

    when(
      () => vehicleCubit.state,
    ).thenReturn(const ResultState<List<VehicleModel>>.initial());
    when(() => vehicleCubit.addVehicleLocally(any())).thenReturn(null);
    when(
      () => vehicleCubit.updateSoatLocally(any(), expiryDate: any(named: 'expiryDate')),
    ).thenReturn(null);

    when(
      () => imageCubit.state,
    ).thenReturn(const ResultState<FormImageData>.initial());

    when(
      () => vehicleRepository.upsertSoat(
        vehicleId: any(named: 'vehicleId'),
        soat: any(named: 'soat'),
      ),
    ).thenAnswer(
      (_) async => Right(
        VehicleSoatFormData(
          vehicleId: 'v-new-1',
          insurer: 'Sura',
          startDate: DateTime(2026, 1, 1),
          expiryDate: DateTime(2027, 1, 1),
        ),
      ),
    );

    when(
      () => saveTecnomecanicaUseCase(
        vehicleId: any(named: 'vehicleId'),
        tecnomecanica: any(named: 'tecnomecanica'),
      ),
    ).thenAnswer(
      (_) async => Right(
        TecnomecanicaModel(
          id: 'r-1',
          vehicleId: 'v-new-1',
          cdaName: 'CDA Bogotá',
          startDate: DateTime(2026, 1, 1),
          expiryDate: DateTime(2027, 1, 1),
        ),
      ),
    );

    final gi = GetIt.instance;
    if (gi.isRegistered<VehicleRepository>()) gi.unregister<VehicleRepository>();
    if (gi.isRegistered<SaveTecnomecanicaUseCase>()) {
      gi.unregister<SaveTecnomecanicaUseCase>();
    }
    if (gi.isRegistered<ImageStorageService>()) {
      gi.unregister<ImageStorageService>();
    }
    gi.registerFactory<VehicleRepository>(() => vehicleRepository);
    gi.registerFactory<SaveTecnomecanicaUseCase>(() => saveTecnomecanicaUseCase);
    gi.registerFactory<ImageStorageService>(() => imageStorageService);
  });

  tearDown(() async {
    await stateController.close();
    final gi = GetIt.instance;
    if (gi.isRegistered<VehicleRepository>()) gi.unregister<VehicleRepository>();
    if (gi.isRegistered<SaveTecnomecanicaUseCase>()) {
      gi.unregister<SaveTecnomecanicaUseCase>();
    }
    if (gi.isRegistered<ImageStorageService>()) {
      gi.unregister<ImageStorageService>();
    }
  });

  testWidgets(
    '8.2/8.4: on vehicle creation with pending manual SOAT, upsertSoat is '
    'invoked with the new vehicle id and success snackbar is shown',
    (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          formCubit: formCubit,
          vehicleCubit: vehicleCubit,
          imageCubit: imageCubit,
        ),
      );
      await tester.pumpAndSettle();

      stateController.add(
        VehicleFormState(
          vehicleResult: const ResultState.data(data: _savedVehicle),
          pendingManualSoat: _pendingSoat,
        ),
      );
      await tester.pumpAndSettle();

      final captured = verify(
        () => vehicleRepository.upsertSoat(
          vehicleId: captureAny(named: 'vehicleId'),
          soat: captureAny(named: 'soat'),
        ),
      ).captured;
      expect(captured[0], 'v-new-1');
      expect((captured[1] as VehicleSoatFormData).insurer, 'Sura');

      verifyNever(
        () => saveTecnomecanicaUseCase(
          vehicleId: any(named: 'vehicleId'),
          tecnomecanica: any(named: 'tecnomecanica'),
        ),
      );

      verify(() => vehicleCubit.addVehicleLocally(_savedVehicle)).called(1);
      expect(find.text('Guardado exitosamente'), findsOneWidget);
    },
  );

  testWidgets(
    '8.3/8.4: on vehicle creation with pending RTM, SaveTecnomecanicaUseCase '
    'is invoked with the new vehicle id',
    (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          formCubit: formCubit,
          vehicleCubit: vehicleCubit,
          imageCubit: imageCubit,
        ),
      );
      await tester.pumpAndSettle();

      stateController.add(
        VehicleFormState(
          vehicleResult: const ResultState.data(data: _savedVehicle),
          pendingRtm: _pendingRtm,
        ),
      );
      await tester.pumpAndSettle();

      final captured = verify(
        () => saveTecnomecanicaUseCase(
          vehicleId: captureAny(named: 'vehicleId'),
          tecnomecanica: captureAny(named: 'tecnomecanica'),
        ),
      ).captured;
      expect(captured[0], 'v-new-1');
      expect((captured[1] as TecnomecanicaModel).cdaName, 'CDA Bogotá');

      verifyNever(
        () => vehicleRepository.upsertSoat(
          vehicleId: any(named: 'vehicleId'),
          soat: any(named: 'soat'),
        ),
      );
    },
  );

  testWidgets(
    '8.4: on vehicle creation with BOTH pending manual SOAT and RTM, both '
    'upsertSoat and SaveTecnomecanicaUseCase are invoked in the same step',
    (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          formCubit: formCubit,
          vehicleCubit: vehicleCubit,
          imageCubit: imageCubit,
        ),
      );
      await tester.pumpAndSettle();

      stateController.add(
        VehicleFormState(
          vehicleResult: const ResultState.data(data: _savedVehicle),
          pendingManualSoat: _pendingSoat,
          pendingRtm: _pendingRtm,
        ),
      );
      await tester.pumpAndSettle();

      verify(
        () => vehicleRepository.upsertSoat(
          vehicleId: any(named: 'vehicleId'),
          soat: any(named: 'soat'),
        ),
      ).called(1);
      verify(
        () => saveTecnomecanicaUseCase(
          vehicleId: any(named: 'vehicleId'),
          tecnomecanica: any(named: 'tecnomecanica'),
        ),
      ).called(1);

      expect(find.text('Guardado exitosamente'), findsOneWidget);
    },
  );
}

// ─── Notas de cobertura ──────────────────────────────────────────────────────
//
// 8.1 (SOAT con imagen adjunta → navega a SoatManualCapturePage en lugar de
// crear el SOAT directamente) NO está cubierto aquí: ese branch depende de
// `state.soatLocalPath`, que es un flujo de navegación (pushReplacementNamed)
// distinto de `_savePendingDocumentsAndPop`. Se podría agregar como un test
// adicional de navegación (similar a vehicle_documents_tap_navigation_test.dart)
// si se prioriza.
//
// 8.5 (fallo específico de subida de imagen del documento) NO está cubierto:
// requeriría inyectar un `pendingManualSoat`/`pendingRtm` con `localImagePath`
// no nulo y forzar que `ImageStorageService.uploadImage` lance, luego
// verificar que `upsertSoat`/`SaveTecnomecanicaUseCase` igual se invoca sin
// `documentUrl` (catch silencioso) — es automatizable pero no se incluyó en
// esta pasada por alcance.
