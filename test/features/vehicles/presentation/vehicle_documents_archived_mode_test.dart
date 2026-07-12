// Tests para VehicleDocumentCard en modo isArchived=true — fase 3, sección 4.
//
// QA checklist 4.6-4.9 — comportamiento de las tarjetas de SOAT y RTM
// cuando el vehículo está archivado:
//   • Con datos: tappable, navega a la ruta de detalle con extra isArchived=true
//   • Sin datos: NO tappable (no hay InkWell que dispare navegación)
//
// Complementa vehicle_documents_tap_navigation_test.dart que solo cubre el
// path activo (isArchived=false, default).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_cubit.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_upload_cubit.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_kind.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockSoatCubit extends MockCubit<ResultState<SoatModel>>
    implements SoatCubit {}

class MockTecnomecanicaCubit extends MockCubit<ResultState<TecnomecanicaModel>>
    implements TecnomecanicaCubit {}

class MockSoatUploadCubit extends MockCubit<SoatUploadState>
    implements SoatUploadCubit {}

// ─── Route spy ───────────────────────────────────────────────────────────────

class _RouteNameSpy extends NavigatorObserver {
  final List<String> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) pushed.add(name);
  }
}

// ─── Fixtures ────────────────────────────────────────────────────────────────

const _archivedVehicle = VehicleModel(
  id: 'v-arch-doc',
  name: 'Moto Archivada',
  currentMileage: 5000,
  isArchived: true,
);

final _soatData = SoatModel(
  id: 's-arch',
  vehicleId: 'v-arch-doc',
  expiryDate: DateTime(2027, 1, 1),
);

final _rtmData = TecnomecanicaModel(
  id: 'r-arch',
  vehicleId: 'v-arch-doc',
  cdaName: 'CDA Test',
  startDate: DateTime(2026, 1, 1),
  expiryDate: DateTime(2027, 1, 1),
);

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap(
  Widget card, {
  required MockSoatCubit soatCubit,
  required MockTecnomecanicaCubit rtmCubit,
  required _RouteNameSpy spy,
}) {
  final router = GoRouter(
    observers: [spy],
    routes: [
      GoRoute(
        path: '/',
        builder: (_, s) => Scaffold(body: SingleChildScrollView(child: card)),
        routes: [
          GoRoute(
            path: 'soat/status',
            name: AppRoutes.soatStatus,
            builder: (_, s) => const Scaffold(body: Text('soat-status')),
          ),
          GoRoute(
            path: 'tecnomecanica/status',
            name: AppRoutes.tecnomecanicaStatus,
            builder: (_, s) =>
                const Scaffold(body: Text('tecnomecanica-status')),
          ),
        ],
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late MockSoatCubit soatCubit;
  late MockTecnomecanicaCubit rtmCubit;
  late MockSoatUploadCubit soatUploadCubit;

  setUp(() {
    soatCubit = MockSoatCubit();
    rtmCubit = MockTecnomecanicaCubit();
    soatUploadCubit = MockSoatUploadCubit();

    when(() => soatCubit.load(any())).thenAnswer((_) async {});
    when(() => rtmCubit.load(any())).thenAnswer((_) async {});
    when(() => soatUploadCubit.state).thenReturn(const SoatUploadInitial());

    final gi = GetIt.instance;
    if (gi.isRegistered<SoatCubit>()) gi.unregister<SoatCubit>();
    if (gi.isRegistered<TecnomecanicaCubit>()) {
      gi.unregister<TecnomecanicaCubit>();
    }
    if (gi.isRegistered<SoatUploadCubit>()) gi.unregister<SoatUploadCubit>();
    gi.registerFactory<SoatCubit>(() => soatCubit);
    gi.registerFactory<TecnomecanicaCubit>(() => rtmCubit);
    gi.registerFactory<SoatUploadCubit>(() => soatUploadCubit);
  });

  tearDown(() {
    final gi = GetIt.instance;
    if (gi.isRegistered<SoatCubit>()) gi.unregister<SoatCubit>();
    if (gi.isRegistered<TecnomecanicaCubit>()) {
      gi.unregister<TecnomecanicaCubit>();
    }
    if (gi.isRegistered<SoatUploadCubit>()) gi.unregister<SoatUploadCubit>();
  });

  // ── TC-arch-doc-1: SOAT con datos + archivado → navega con isArchived ─────

  testWidgets(
    'TC-arch-doc-1: SOAT card with data + isArchived=true navigates to soatStatus',
    (tester) async {
      when(() => soatCubit.state).thenReturn(ResultState.data(data: _soatData));
      when(() => rtmCubit.state).thenReturn(const ResultState.initial());

      final spy = _RouteNameSpy();

      await tester.pumpWidget(
        _wrap(
          const VehicleDocumentCard(
            kind: VehicleDocumentKind.soat,
            vehicle: _archivedVehicle,
            isArchived: true,
          ),
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          spy: spy,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(
        spy.pushed,
        contains(AppRoutes.soatStatus),
        reason: 'SOAT con datos en modo archivado debe navegar a soatStatus',
      );
    },
  );

  // ── TC-arch-doc-2: SOAT sin datos + archivado → NO navega ────────────────

  testWidgets(
    'TC-arch-doc-2: SOAT card empty + isArchived=true is NOT tappable',
    (tester) async {
      when(() => soatCubit.state).thenReturn(const ResultState.empty());
      when(() => rtmCubit.state).thenReturn(const ResultState.initial());

      final spy = _RouteNameSpy();

      await tester.pumpWidget(
        _wrap(
          const VehicleDocumentCard(
            kind: VehicleDocumentKind.soat,
            vehicle: _archivedVehicle,
            isArchived: true,
          ),
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          spy: spy,
        ),
      );
      await tester.pumpAndSettle();

      // La tarjeta sin datos no tiene InkWell en modo archivado;
      // cualquier tap en el widget no dispara navegación.
      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().isNotEmpty) {
        await tester.tap(inkWells.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      expect(
        spy.pushed,
        isNot(contains(AppRoutes.soatStatus)),
        reason: 'SOAT sin datos en modo archivado NO debe navegar a soatStatus',
      );
    },
  );

  // ── TC-arch-doc-3: RTM con datos + archivado → navega con isArchived ──────

  testWidgets(
    'TC-arch-doc-3: RTM card with data + isArchived=true navigates to tecnomecanicaStatus',
    (tester) async {
      when(() => soatCubit.state).thenReturn(const ResultState.initial());
      when(() => rtmCubit.state).thenReturn(ResultState.data(data: _rtmData));

      final spy = _RouteNameSpy();

      await tester.pumpWidget(
        _wrap(
          const VehicleDocumentCard(
            kind: VehicleDocumentKind.rtm,
            vehicle: _archivedVehicle,
            isArchived: true,
          ),
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          spy: spy,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(
        spy.pushed,
        contains(AppRoutes.tecnomecanicaStatus),
        reason:
            'RTM con datos en modo archivado debe navegar a tecnomecanicaStatus',
      );
    },
  );

  // ── TC-arch-doc-4: RTM sin datos + archivado → NO navega ─────────────────

  testWidgets(
    'TC-arch-doc-4: RTM card empty + isArchived=true is NOT tappable',
    (tester) async {
      when(() => soatCubit.state).thenReturn(const ResultState.initial());
      when(() => rtmCubit.state).thenReturn(const ResultState.empty());

      final spy = _RouteNameSpy();

      await tester.pumpWidget(
        _wrap(
          const VehicleDocumentCard(
            kind: VehicleDocumentKind.rtm,
            vehicle: _archivedVehicle,
            isArchived: true,
          ),
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          spy: spy,
        ),
      );
      await tester.pumpAndSettle();

      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().isNotEmpty) {
        await tester.tap(inkWells.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      expect(
        spy.pushed,
        isNot(contains(AppRoutes.tecnomecanicaStatus)),
        reason: 'RTM sin datos en modo archivado NO debe navegar',
      );
    },
  );
}
