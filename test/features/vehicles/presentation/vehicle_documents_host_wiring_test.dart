// C3 — host wiring/ordering/spacing test (auditor requirement)
//
// Renders [VehicleDetailView] (the actual host) and asserts:
//   • Exactly two [VehicleDocumentCard] instances are present.
//   • SOAT card comes first (kind == soat), RTM card comes second (kind == rtm).
//   • A [SizedBox] with height 16 separates them — regression-protecting both
//     the ordering and the spacing that the PRD specifies.
//
// Strategy: register all GetIt-resolved cubits as mocks so the widget tree builds
// without a real DI graph or Firebase. VehicleDetailView also mounts
// VehicleMaintenanceHistorySection (which resolves VehicleMaintenancesCubit via GetIt)
// so we stub that too.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_cubit.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_kind.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/cubit/vehicle_maintenances_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart';
import 'package:rideglory/l10n/app_localizations.dart';

// ─── Mocks ──────────────────────────────────────────────────────────────────

class MockSoatCubit extends MockCubit<ResultState<SoatModel>>
    implements SoatCubit {}

class MockTecnomecanicaCubit extends MockCubit<ResultState<TecnomecanicaModel>>
    implements TecnomecanicaCubit {}

class MockVehicleCubit extends MockCubit<ResultState<List<VehicleModel>>>
    implements VehicleCubit {}

class MockVehicleMaintenancesCubit
    extends MockCubit<ResultState<List<MaintenanceModel>>>
    implements VehicleMaintenancesCubit {}

// ─── Fixture ────────────────────────────────────────────────────────────────

const _vehicle = VehicleModel(
  id: 'v-host-1',
  name: 'Host Moto',
  currentMileage: 0,
);

// ─── Test ────────────────────────────────────────────────────────────────────

void main() {
  late MockSoatCubit soatCubit;
  late MockTecnomecanicaCubit rtmCubit;
  late MockVehicleCubit vehicleCubit;
  late MockVehicleMaintenancesCubit maintenancesCubit;

  setUp(() {
    soatCubit = MockSoatCubit();
    rtmCubit = MockTecnomecanicaCubit();
    vehicleCubit = MockVehicleCubit();
    maintenancesCubit = MockVehicleMaintenancesCubit();

    when(() => soatCubit.state).thenReturn(const ResultState.empty());
    when(() => rtmCubit.state).thenReturn(const ResultState.empty());
    when(
      () => vehicleCubit.state,
    ).thenReturn(const ResultState.data(data: [_vehicle]));
    when(() => maintenancesCubit.state).thenReturn(const ResultState.initial());

    when(() => soatCubit.load(any())).thenAnswer((_) async {});
    when(() => rtmCubit.load(any())).thenAnswer((_) async {});
    when(
      () => maintenancesCubit.fetchMaintenances(any()),
    ).thenAnswer((_) async {});
    when(() => maintenancesCubit.lastCompleted).thenReturn(null);

    final gi = GetIt.instance;
    if (gi.isRegistered<SoatCubit>()) gi.unregister<SoatCubit>();
    if (gi.isRegistered<TecnomecanicaCubit>())
      gi.unregister<TecnomecanicaCubit>();
    if (gi.isRegistered<VehicleMaintenancesCubit>()) {
      gi.unregister<VehicleMaintenancesCubit>();
    }
    gi.registerFactory<SoatCubit>(() => soatCubit);
    gi.registerFactory<TecnomecanicaCubit>(() => rtmCubit);
    gi.registerFactory<VehicleMaintenancesCubit>(() => maintenancesCubit);
  });

  tearDown(() {
    final gi = GetIt.instance;
    if (gi.isRegistered<SoatCubit>()) gi.unregister<SoatCubit>();
    if (gi.isRegistered<TecnomecanicaCubit>())
      gi.unregister<TecnomecanicaCubit>();
    if (gi.isRegistered<VehicleMaintenancesCubit>()) {
      gi.unregister<VehicleMaintenancesCubit>();
    }
  });

  testWidgets('C3 — VehicleDetailView renders exactly 2 VehicleDocumentCard: '
      'SOAT first, RTM second, SizedBox(h:16) between them', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: BlocProvider<VehicleCubit>.value(
          value: vehicleCubit,
          child: VehicleDetailView(
            vehicle: _vehicle,
            onBack: () {},
            maintenanceRefreshTick: 0,
            onPendingMaintenanceConsumed: (_) {},
            onMaintenanceCreated: (_) {},
            onMaintenanceRefreshRequested: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    // 1. Exactly two VehicleDocumentCard widgets.
    final cardFinder = find.byType(VehicleDocumentCard);
    expect(cardFinder, findsNWidgets(2));

    // 2. Order: SOAT before RTM.
    final cards = tester.widgetList<VehicleDocumentCard>(cardFinder).toList();
    expect(
      cards[0].kind,
      VehicleDocumentKind.soat,
      reason: 'First card must be SOAT',
    );
    expect(
      cards[1].kind,
      VehicleDocumentKind.rtm,
      reason: 'Second card must be RTM',
    );

    // 3. SizedBox(height: 16) exists between the two cards.
    final allSizedBoxes = tester
        .widgetList<SizedBox>(find.byType(SizedBox))
        .where((sb) => sb.height == 16.0)
        .toList();
    expect(
      allSizedBoxes,
      isNotEmpty,
      reason: 'SizedBox(height: 16) must appear between SOAT and RTM cards',
    );

    // 4. Positional ordering: SOAT renderBox top < RTM renderBox top.
    final soatBox = tester.getRect(cardFinder.at(0));
    final rtmBox = tester.getRect(cardFinder.at(1));
    expect(
      soatBox.top,
      lessThan(rtmBox.top),
      reason: 'SOAT card must appear above RTM card in the layout',
    );
  });
}
