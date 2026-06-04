import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_cubit.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_kind.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart';
import 'package:rideglory/l10n/app_localizations.dart';

// ─── Mocks ──────────────────────────────────────────────────────────────────

class MockSoatCubit extends MockCubit<ResultState<SoatModel>>
    implements SoatCubit {}

class MockTecnomecanicaCubit
    extends MockCubit<ResultState<TecnomecanicaModel>>
    implements TecnomecanicaCubit {}

// ─── Fixtures ────────────────────────────────────────────────────────────────

const _vehicle = VehicleModel(id: 'v-1', name: 'Mi Moto', currentMileage: 0);

final _soatValid = SoatModel(
  id: 's-1',
  vehicleId: 'v-1',
  expiryDate: DateTime.now().add(const Duration(days: 90)),
);

final _soatExpiringSoon = SoatModel(
  id: 's-2',
  vehicleId: 'v-1',
  expiryDate: DateTime.now().add(const Duration(days: 10)),
);

final _soatExpired = SoatModel(
  id: 's-3',
  vehicleId: 'v-1',
  expiryDate: DateTime.now().subtract(const Duration(days: 5)),
);

final _rtmValid = TecnomecanicaModel(
  id: 'r-1',
  vehicleId: 'v-1',
  cdaName: 'CDA Test',
  startDate: DateTime.now().subtract(const Duration(days: 30)),
  expiryDate: DateTime.now().add(const Duration(days: 90)),
);

final _rtmExpiringSoon = TecnomecanicaModel(
  id: 'r-2',
  vehicleId: 'v-1',
  cdaName: 'CDA Test',
  startDate: DateTime.now().subtract(const Duration(days: 30)),
  expiryDate: DateTime.now().add(const Duration(days: 10)),
);

final _rtmExpired = TecnomecanicaModel(
  id: 'r-3',
  vehicleId: 'v-1',
  cdaName: 'CDA Test',
  startDate: DateTime.now().subtract(const Duration(days: 60)),
  expiryDate: DateTime.now().subtract(const Duration(days: 5)),
);

// ─── Test helper ────────────────────────────────────────────────────────────

/// Wraps [child] with localizations and registers [soatCubit] /
/// [rtmCubit] in GetIt so that [VehicleDocumentCard]'s internal
/// [BlocProvider.create] factory (`getIt<SoatCubit>()..load(...)`) resolves
/// to the mock instead of a real DI graph.
Widget _wrap({
  required Widget child,
  required MockSoatCubit soatCubit,
  required MockTecnomecanicaCubit rtmCubit,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  late MockSoatCubit soatCubit;
  late MockTecnomecanicaCubit rtmCubit;

  setUp(() {
    soatCubit = MockSoatCubit();
    rtmCubit = MockTecnomecanicaCubit();

    // Register mocks in GetIt so VehicleDocumentCard's BlocProvider.create
    // resolves to the mock instead of a real cubit.
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SoatCubit>()) {
      getIt.unregister<SoatCubit>();
    }
    if (getIt.isRegistered<TecnomecanicaCubit>()) {
      getIt.unregister<TecnomecanicaCubit>();
    }
    getIt.registerFactory<SoatCubit>(() => soatCubit);
    getIt.registerFactory<TecnomecanicaCubit>(() => rtmCubit);

    // Default: stub load() as a no-op (BlocProvider.create calls ..load()).
    when(() => soatCubit.load(any())).thenAnswer((_) async {});
    when(() => rtmCubit.load(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SoatCubit>()) getIt.unregister<SoatCubit>();
    if (getIt.isRegistered<TecnomecanicaCubit>()) {
      getIt.unregister<TecnomecanicaCubit>();
    }
  });

  // ── Criterio 3: ambos badges renderizan juntos ──────────────────────────

  group('Criterio 3 — ambos badges renderizan en pantalla', () {
    testWidgets('SOAT card y RTM card se muestran sin excepción fatal', (
      tester,
    ) async {
      when(() => soatCubit.state).thenReturn(const ResultState.empty());
      when(() => rtmCubit.state).thenReturn(const ResultState.empty());

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const Column(
            children: [
              VehicleDocumentCard(
                kind: VehicleDocumentKind.soat,
                vehicle: _vehicle,
              ),
              VehicleDocumentCard(
                kind: VehicleDocumentKind.rtm,
                vehicle: _vehicle,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VehicleDocumentCard), findsNWidgets(2));
    });
  });

  // ── Criterio 4: carga independiente — un skeleton no bloquea al otro ───

  group('Criterio 4 — carga independiente (sin bloqueo cruzado)', () {
    testWidgets(
      'SOAT en loading muestra skeleton; RTM con datos muestra label',
      (tester) async {
        when(() => soatCubit.state).thenReturn(const ResultState.loading());
        when(
          () => rtmCubit.state,
        ).thenReturn(ResultState.data(data: _rtmValid));

        await tester.pumpWidget(
          _wrap(
            soatCubit: soatCubit,
            rtmCubit: rtmCubit,
            child: const Column(
              children: [
                VehicleDocumentCard(
                  kind: VehicleDocumentKind.soat,
                  vehicle: _vehicle,
                ),
                VehicleDocumentCard(
                  kind: VehicleDocumentKind.rtm,
                  vehicle: _vehicle,
                ),
              ],
            ),
          ),
        );
        await tester.pump();

        // Skeleton SOAT presente.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // Label RTM visible al mismo tiempo.
        expect(find.text('Vigente'), findsOneWidget);
      },
    );

    testWidgets(
      'RTM en loading muestra skeleton; SOAT con datos muestra label',
      (tester) async {
        when(
          () => soatCubit.state,
        ).thenReturn(ResultState.data(data: _soatValid));
        when(() => rtmCubit.state).thenReturn(const ResultState.loading());

        await tester.pumpWidget(
          _wrap(
            soatCubit: soatCubit,
            rtmCubit: rtmCubit,
            child: const Column(
              children: [
                VehicleDocumentCard(
                  kind: VehicleDocumentKind.soat,
                  vehicle: _vehicle,
                ),
                VehicleDocumentCard(
                  kind: VehicleDocumentKind.rtm,
                  vehicle: _vehicle,
                ),
              ],
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Vigente'), findsOneWidget);
      },
    );
  });

  // ── Criterio 5 (regresión): SOAT — 4 estados ───────────────────────────

  group('Criterio 5 — SOAT: 4 estados', () {
    testWidgets('loading → CircularProgressIndicator', (tester) async {
      when(() => soatCubit.state).thenReturn(const ResultState.loading());
      when(() => rtmCubit.state).thenReturn(const ResultState.initial());

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const VehicleDocumentCard(
            kind: VehicleDocumentKind.soat,
            vehicle: _vehicle,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('empty → muestra label sin-registro', (tester) async {
      when(() => soatCubit.state).thenReturn(const ResultState.empty());
      when(() => rtmCubit.state).thenReturn(const ResultState.initial());

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const VehicleDocumentCard(
            kind: VehicleDocumentKind.soat,
            vehicle: _vehicle,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Sin registrar'), findsOneWidget);
    });

    testWidgets('data valid → muestra "Vigente"', (tester) async {
      when(
        () => soatCubit.state,
      ).thenReturn(ResultState.data(data: _soatValid));
      when(() => rtmCubit.state).thenReturn(const ResultState.initial());

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const VehicleDocumentCard(
            kind: VehicleDocumentKind.soat,
            vehicle: _vehicle,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Vigente'), findsOneWidget);
    });

    testWidgets('data expiringSoon → muestra "Por vencer"', (tester) async {
      when(
        () => soatCubit.state,
      ).thenReturn(ResultState.data(data: _soatExpiringSoon));
      when(() => rtmCubit.state).thenReturn(const ResultState.initial());

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const VehicleDocumentCard(
            kind: VehicleDocumentKind.soat,
            vehicle: _vehicle,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Por vencer'), findsOneWidget);
    });

    testWidgets('data expired → muestra etiqueta vencido', (tester) async {
      when(
        () => soatCubit.state,
      ).thenReturn(ResultState.data(data: _soatExpired));
      when(() => rtmCubit.state).thenReturn(const ResultState.initial());

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const VehicleDocumentCard(
            kind: VehicleDocumentKind.soat,
            vehicle: _vehicle,
          ),
        ),
      );
      await tester.pump();

      // l10n key: maintenance_expired_label = "vencido"
      expect(find.text('vencido'), findsOneWidget);
    });
  });

  // ── RTM — 4 estados ────────────────────────────────────────────────────

  group('RTM: 4 estados', () {
    testWidgets('loading → CircularProgressIndicator', (tester) async {
      when(() => soatCubit.state).thenReturn(const ResultState.initial());
      when(() => rtmCubit.state).thenReturn(const ResultState.loading());

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const VehicleDocumentCard(
            kind: VehicleDocumentKind.rtm,
            vehicle: _vehicle,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('empty → muestra "Sin RTM registrada"', (tester) async {
      when(() => soatCubit.state).thenReturn(const ResultState.initial());
      when(() => rtmCubit.state).thenReturn(const ResultState.empty());

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const VehicleDocumentCard(
            kind: VehicleDocumentKind.rtm,
            vehicle: _vehicle,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sin RTM registrada'), findsOneWidget);
    });

    testWidgets('data valid → muestra "Vigente"', (tester) async {
      when(() => soatCubit.state).thenReturn(const ResultState.initial());
      when(
        () => rtmCubit.state,
      ).thenReturn(ResultState.data(data: _rtmValid));

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const VehicleDocumentCard(
            kind: VehicleDocumentKind.rtm,
            vehicle: _vehicle,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Vigente'), findsOneWidget);
    });

    testWidgets('data expiringSoon → muestra "Por vencer"', (tester) async {
      when(() => soatCubit.state).thenReturn(const ResultState.initial());
      when(
        () => rtmCubit.state,
      ).thenReturn(ResultState.data(data: _rtmExpiringSoon));

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const VehicleDocumentCard(
            kind: VehicleDocumentKind.rtm,
            vehicle: _vehicle,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Por vencer'), findsOneWidget);
    });

    testWidgets('data expired → muestra "Vencida"', (tester) async {
      when(() => soatCubit.state).thenReturn(const ResultState.initial());
      when(
        () => rtmCubit.state,
      ).thenReturn(ResultState.data(data: _rtmExpired));

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const VehicleDocumentCard(
            kind: VehicleDocumentKind.rtm,
            vehicle: _vehicle,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Vencida'), findsOneWidget);
    });

    testWidgets('error → muestra "Sin RTM registrada" (fallback)', (
      tester,
    ) async {
      when(() => soatCubit.state).thenReturn(const ResultState.initial());
      when(() => rtmCubit.state).thenReturn(
        const ResultState.error(
          error: DomainException(message: 'Error de red'),
        ),
      );

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const VehicleDocumentCard(
            kind: VehicleDocumentKind.rtm,
            vehicle: _vehicle,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sin RTM registrada'), findsOneWidget);
    });
  });

  // ── Criterio 6: tap por kind — InkWell presente ─────────────────────────

  group('Criterio 6 — tap por kind', () {
    testWidgets('SOAT card con datos muestra InkWell (tappable)', (
      tester,
    ) async {
      when(
        () => soatCubit.state,
      ).thenReturn(ResultState.data(data: _soatValid));
      when(() => rtmCubit.state).thenReturn(const ResultState.initial());

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const VehicleDocumentCard(
            kind: VehicleDocumentKind.soat,
            vehicle: _vehicle,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(InkWell), findsAtLeastNWidgets(1));
    });

    testWidgets('RTM card con datos muestra InkWell (tappable)', (
      tester,
    ) async {
      when(() => soatCubit.state).thenReturn(const ResultState.initial());
      when(
        () => rtmCubit.state,
      ).thenReturn(ResultState.data(data: _rtmValid));

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const VehicleDocumentCard(
            kind: VehicleDocumentKind.rtm,
            vehicle: _vehicle,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(InkWell), findsAtLeastNWidgets(1));
    });

    testWidgets('SOAT empty muestra InkWell (permite navegar a añadir)', (
      tester,
    ) async {
      when(() => soatCubit.state).thenReturn(const ResultState.empty());
      when(() => rtmCubit.state).thenReturn(const ResultState.initial());

      await tester.pumpWidget(
        _wrap(
          soatCubit: soatCubit,
          rtmCubit: rtmCubit,
          child: const VehicleDocumentCard(
            kind: VehicleDocumentKind.soat,
            vehicle: _vehicle,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(InkWell), findsAtLeastNWidgets(1));
    });
  });
}

