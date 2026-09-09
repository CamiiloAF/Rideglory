import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/design_system/theme/app_theme.dart';
import 'package:rideglory/features/maintenance/domain/maintenance.dart';
import 'package:rideglory/features/maintenance/domain/vehicle_option.dart';
import 'package:rideglory/features/maintenance/presentation/cubit/maintenance_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/cubit/maintenance_state.dart';
import 'package:rideglory/features/maintenance/presentation/pages/maintenance_view.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/cubits/connectivity/connectivity_cubit.dart';
import 'package:rideglory/shared/cubits/connectivity/connectivity_state.dart';

class _MockMaintenanceCubit extends MockCubit<MaintenanceState>
    implements MaintenanceCubit {}

class _MockConnectivityCubit extends MockCubit<ConnectivityState>
    implements ConnectivityCubit {}

const _vehicle = VehicleOption(
  id: 'v1',
  displayName: 'Yamaha MT-03',
  chipLabel: 'MT-03',
  currentMileage: 18450,
  isMain: true,
);

Widget _wrap(MaintenanceCubit cubit, ConnectivityCubit connectivityCubit) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<MaintenanceCubit>.value(value: cubit),
      BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MaintenanceView(),
    ),
  );
}

void main() {
  late _MockMaintenanceCubit cubit;
  late _MockConnectivityCubit connectivityCubit;

  setUp(() {
    cubit = _MockMaintenanceCubit();
    connectivityCubit = _MockConnectivityCubit();
    when(
      () => connectivityCubit.state,
    ).thenReturn(const ConnectivityState.online());
    when(() => cubit.load()).thenAnswer((_) async {});
  });

  testWidgets('shows a skeleton while loading', (tester) async {
    when(() => cubit.state).thenReturn(const MaintenanceState());

    await tester.pumpWidget(_wrap(cubit, connectivityCubit));

    expect(find.text('Mantenimiento'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets(
    'shows the empty state with a CTA when there are no maintenances',
    (tester) async {
      when(() => cubit.state).thenReturn(
        const MaintenanceState(
          vehicles: ResultState.data(data: [_vehicle]),
          maintenances: ResultState.data(data: []),
        ),
      );

      await tester.pumpWidget(_wrap(cubit, connectivityCubit));

      expect(find.text('Registra tu primer mantenimiento'), findsOneWidget);
      expect(find.text('Registrar mantenimiento'), findsWidgets);
    },
  );

  testWidgets('shows an accionable error state', (tester) async {
    when(() => cubit.state).thenReturn(
      const MaintenanceState(
        vehicles: ResultState.error(error: DomainException(message: 'boom')),
        maintenances: ResultState.data(data: []),
      ),
    );

    await tester.pumpWidget(_wrap(cubit, connectivityCubit));

    expect(find.text('No pudimos cargar tu mantenimiento'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('shows the agenda and history sections when there is data', (
    tester,
  ) async {
    final maintenance = Maintenance(
      id: 'm1',
      vehicleId: _vehicle.id,
      vehicleDisplayName: _vehicle.displayName,
      type: 'Cambio de aceite',
      serviceDate: DateTime(2026, 8, 12),
      odometer: 18450,
    );
    when(() => cubit.state).thenReturn(
      MaintenanceState(
        vehicles: const ResultState.data(data: [_vehicle]),
        maintenances: ResultState.data(data: [maintenance]),
      ),
    );

    await tester.pumpWidget(_wrap(cubit, connectivityCubit));

    expect(find.text('HISTORIAL'), findsOneWidget);
    expect(find.text('Cambio de aceite'), findsOneWidget);
  });
}
