// C6 strengthened — tap navigation tests (auditor requirement)
//
// Taps each badge and asserts the correct destination is reached by kind:
//   • SOAT with data  → pushNamed(AppRoutes.soatStatus)
//   • SOAT empty      → SoatEntryFlow.start invoked (shows bottom sheet / pushes soatManualCapture)
//   • RTM             → pushNamed(AppRoutes.tecnomecanicaStatus)
//
// Uses a real GoRouter with stub routes that write observed route names to a
// list, so a wrong-kind navigation bug is reliably caught.
//
// SoatEntryFlow.start shows a ModalBottomSheet first (SoatVehicleOptionsSheet)
// before navigating — so we verify that tapping SOAT-empty opens a bottom
// sheet layer rather than a named route (which would be a routing regression).

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

/// Records every [Route.settings.name] pushed via a [NavigatorObserver].
class _RouteNameSpy extends NavigatorObserver {
  final List<String> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) pushed.add(name);
  }
}

// ─── Fixtures ────────────────────────────────────────────────────────────────

const _vehicle = VehicleModel(
  id: 'v-tap-1',
  name: 'Tap Moto',
  currentMileage: 0,
);

final soatValid = SoatModel(
  id: 's-tap',
  vehicleId: 'v-tap-1',
  expiryDate: DateTime.now().add(const Duration(days: 90)),
);

final _rtmValid = TecnomecanicaModel(
  id: 'r-tap',
  vehicleId: 'v-tap-1',
  cdaName: 'CDA',
  startDate: DateTime.now().subtract(const Duration(days: 10)),
  expiryDate: DateTime.now().add(const Duration(days: 90)),
);

// ─── Widget builder ──────────────────────────────────────────────────────────

/// Pumps [card] inside a GoRouter that stubs all document-related routes as
/// empty pages so pushNamed calls don't throw "route not found".
///
/// The [spy] is passed as a NavigatorObserver to the root navigator so we can
/// inspect pushed route names.
Widget _wrapWithRouter(
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
            path: 'soat/manual-capture',
            name: AppRoutes.soatManualCapture,
            builder: (_, s) => const Scaffold(body: Text('soat-capture')),
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

  // ── C6a: SOAT with data taps → soatStatus route ──────────────────────────

  testWidgets(
    'C6a — SOAT card with data: tap navigates to AppRoutes.soatStatus',
    (tester) async {
      when(() => soatCubit.state).thenReturn(ResultState.data(data: soatValid));
      when(() => rtmCubit.state).thenReturn(const ResultState.initial());

      final spy = _RouteNameSpy();

      await tester.pumpWidget(
        _wrapWithRouter(
          const VehicleDocumentCard(
            kind: VehicleDocumentKind.soat,
            vehicle: _vehicle,
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
        reason: 'Tapping SOAT-with-data must push AppRoutes.soatStatus',
      );
      expect(
        spy.pushed,
        isNot(contains(AppRoutes.tecnomecanicaStatus)),
        reason: 'Must not accidentally navigate to RTM route',
      );
    },
  );

  // ── C6b: SOAT empty taps → SoatEntryFlow.start (bottom sheet) ────────────

  testWidgets('C6b — SOAT card empty: tap invokes SoatEntryFlow.start '
      '(bottom sheet opens, NOT a pushNamed to soatStatus)', (tester) async {
    when(() => soatCubit.state).thenReturn(const ResultState.empty());
    when(() => rtmCubit.state).thenReturn(const ResultState.initial());

    final spy = _RouteNameSpy();

    await tester.pumpWidget(
      _wrapWithRouter(
        const VehicleDocumentCard(
          kind: VehicleDocumentKind.soat,
          vehicle: _vehicle,
        ),
        soatCubit: soatCubit,
        rtmCubit: rtmCubit,
        spy: spy,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InkWell).first);
    await tester.pump(); // let the bottom sheet animate one frame

    // SoatEntryFlow.start opens a ModalBottomSheet — verify the sheet is
    // present rather than a named route push to soatStatus.
    // This distinction matters: a wrong branch would push soatStatus even
    // when there is no SOAT yet.
    expect(
      spy.pushed,
      isNot(contains(AppRoutes.soatStatus)),
      reason:
          'SOAT-empty tap must NOT push soatStatus directly; '
          'it must open SoatEntryFlow (bottom sheet first)',
    );
    // The bottom sheet route is an anonymous route (no name) — its presence
    // on the overlay confirms SoatEntryFlow.start was invoked.
    expect(
      find.byType(BottomSheet),
      findsOneWidget,
      reason: 'SoatEntryFlow.start must open a ModalBottomSheet',
    );
  });

  // ── C6c: RTM taps → tecnomecanicaStatus route ─────────────────────────────

  testWidgets(
    'C6c — RTM card with data: tap navigates to AppRoutes.tecnomecanicaStatus',
    (tester) async {
      when(() => soatCubit.state).thenReturn(const ResultState.initial());
      when(() => rtmCubit.state).thenReturn(ResultState.data(data: _rtmValid));

      final spy = _RouteNameSpy();

      await tester.pumpWidget(
        _wrapWithRouter(
          const VehicleDocumentCard(
            kind: VehicleDocumentKind.rtm,
            vehicle: _vehicle,
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
        reason: 'Tapping RTM card must push AppRoutes.tecnomecanicaStatus',
      );
      expect(
        spy.pushed,
        isNot(contains(AppRoutes.soatStatus)),
        reason: 'Must not accidentally navigate to SOAT route',
      );
    },
  );
}
