import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/design_system/theme/app_theme.dart';
import 'package:rideglory/features/live_ride/domain/live_rider.dart';
import 'package:rideglory/features/live_ride/domain/location_permission_state.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sharing_status.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/live_ride_cubit.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/live_ride_state.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sos_cubit.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sos_state.dart';
import 'package:rideglory/features/live_ride/presentation/live_ride_route_args.dart';
import 'package:rideglory/features/live_ride/presentation/pages/live_ride_view.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/cubits/connectivity/connectivity_cubit.dart';
import 'package:rideglory/shared/cubits/connectivity/connectivity_state.dart';

class _MockLiveRideCubit extends MockCubit<LiveRideState>
    implements LiveRideCubit {}

class _MockSosCubit extends MockCubit<SosState> implements SosCubit {}

class _MockConnectivityCubit extends MockCubit<ConnectivityState>
    implements ConnectivityCubit {}

const _args = LiveRideRouteArgs(
  eventName: 'Rodada al Nevado del Ruiz',
  isOwner: false,
  ownerId: 'owner-1',
);

LiveRider _rider() {
  return LiveRider(
    eventId: 'event-1',
    userId: 'owner-1',
    fullName: 'Juan Camilo',
    isOrganizer: true,
    lat: 4.6,
    lng: -75.6,
    recordedAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
}

Widget _wrap({
  required LiveRideCubit liveRideCubit,
  required SosCubit sosCubit,
  required ConnectivityCubit connectivityCubit,
  LiveRideRouteArgs? args = _args,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<LiveRideCubit>.value(value: liveRideCubit),
      BlocProvider<SosCubit>.value(value: sosCubit),
      BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LiveRideView(eventId: 'event-1', args: args, showMapTiles: false),
    ),
  );
}

void main() {
  late _MockLiveRideCubit liveRideCubit;
  late _MockSosCubit sosCubit;
  late _MockConnectivityCubit connectivityCubit;

  setUp(() {
    liveRideCubit = _MockLiveRideCubit();
    sosCubit = _MockSosCubit();
    connectivityCubit = _MockConnectivityCubit();
    when(
      () => connectivityCubit.state,
    ).thenReturn(const ConnectivityState.online());
    when(() => sosCubit.state).thenReturn(const SosState());
    when(
      () => liveRideCubit.resolveArgs(any(), any()),
    ).thenAnswer((_) async {});
  });

  testWidgets('shows a skeleton while loading', (tester) async {
    when(() => liveRideCubit.state).thenReturn(
      const LiveRideState(permission: LocationPermissionState.whileInUse),
    );

    await tester.pumpWidget(
      _wrap(
        liveRideCubit: liveRideCubit,
        sosCubit: sosCubit,
        connectivityCubit: connectivityCubit,
      ),
    );

    expect(find.byType(ListView), findsWidgets);
  });

  testWidgets('shows the no-permission state with retry action', (
    tester,
  ) async {
    when(() => liveRideCubit.state).thenReturn(
      const LiveRideState(
        permission: LocationPermissionState.denied,
        sharing: SharingStatus.requestingPermission,
      ),
    );

    await tester.pumpWidget(
      _wrap(
        liveRideCubit: liveRideCubit,
        sosCubit: sosCubit,
        connectivityCubit: connectivityCubit,
      ),
    );

    expect(find.text('Necesitamos tu ubicación'), findsOneWidget);
    expect(find.text('Abrir ajustes'), findsOneWidget);
  });

  testWidgets(
    'shows the map and riders (LV1b) without my location permission when '
    'not sharing — never blocks just viewing the ride',
    (tester) async {
      when(() => liveRideCubit.state).thenReturn(
        LiveRideState(
          permission: LocationPermissionState.denied,
          sharing: SharingStatus.notSharing,
          riders: ResultState.data(data: [_rider()]),
          args: _args,
        ),
      );

      await tester.pumpWidget(
        _wrap(
          liveRideCubit: liveRideCubit,
          sosCubit: sosCubit,
          connectivityCubit: connectivityCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Necesitamos tu ubicación'), findsNothing);
      expect(find.textContaining('Juan Camilo'), findsOneWidget);
    },
  );

  testWidgets('shows the no-GPS state', (tester) async {
    when(() => liveRideCubit.state).thenReturn(
      const LiveRideState(
        permission: LocationPermissionState.serviceDisabled,
        sharing: SharingStatus.sharing,
      ),
    );

    await tester.pumpWidget(
      _wrap(
        liveRideCubit: liveRideCubit,
        sosCubit: sosCubit,
        connectivityCubit: connectivityCubit,
      ),
    );

    expect(find.text('No encontramos señal de GPS'), findsOneWidget);
  });

  testWidgets('shows the offline state when there is no connectivity', (
    tester,
  ) async {
    when(
      () => connectivityCubit.state,
    ).thenReturn(const ConnectivityState.offline());
    when(() => liveRideCubit.state).thenReturn(
      const LiveRideState(
        permission: LocationPermissionState.whileInUse,
        riders: ResultState.error(error: DomainException(message: 'offline')),
      ),
    );

    await tester.pumpWidget(
      _wrap(
        liveRideCubit: liveRideCubit,
        sosCubit: sosCubit,
        connectivityCubit: connectivityCubit,
      ),
    );

    expect(find.text('Sin conexión'), findsOneWidget);
  });

  testWidgets('shows the map content once riders load', (tester) async {
    when(() => liveRideCubit.state).thenReturn(
      LiveRideState(
        permission: LocationPermissionState.whileInUse,
        riders: ResultState.data(data: [_rider()]),
        args: _args,
      ),
    );

    await tester.pumpWidget(
      _wrap(
        liveRideCubit: liveRideCubit,
        sosCubit: sosCubit,
        connectivityCubit: connectivityCubit,
      ),
    );
    await tester.pump();

    expect(find.text('Rodada al Nevado del Ruiz'), findsOneWidget);
    expect(find.text('Compartir mi ubicación'), findsOneWidget);
  });

  testWidgets('shows the finished state and offers to go back to the event', (
    tester,
  ) async {
    when(() => liveRideCubit.state).thenReturn(
      const LiveRideState(
        permission: LocationPermissionState.whileInUse,
        riders: ResultState.data(data: []),
        isEventFinished: true,
      ),
    );

    await tester.pumpWidget(
      _wrap(
        liveRideCubit: liveRideCubit,
        sosCubit: sosCubit,
        connectivityCubit: connectivityCubit,
      ),
    );

    expect(find.text('La rodada terminó'), findsOneWidget);
    expect(find.text('Volver al evento'), findsOneWidget);
  });

  testWidgets(
    'asks the cubit to resolve args with what came from the route extra',
    (tester) async {
      when(() => liveRideCubit.state).thenReturn(
        const LiveRideState(permission: LocationPermissionState.whileInUse),
      );

      await tester.pumpWidget(
        _wrap(
          liveRideCubit: liveRideCubit,
          sosCubit: sosCubit,
          connectivityCubit: connectivityCubit,
        ),
      );

      verify(() => liveRideCubit.resolveArgs('event-1', _args)).called(1);
    },
  );

  testWidgets(
    'asks the cubit to resolve args on its own when opened from a SOS push '
    '(no extra)',
    (tester) async {
      when(() => liveRideCubit.state).thenReturn(
        const LiveRideState(permission: LocationPermissionState.whileInUse),
      );

      await tester.pumpWidget(
        _wrap(
          liveRideCubit: liveRideCubit,
          sosCubit: sosCubit,
          connectivityCubit: connectivityCubit,
          args: null,
        ),
      );

      verify(() => liveRideCubit.resolveArgs('event-1', null)).called(1);
    },
  );
}
