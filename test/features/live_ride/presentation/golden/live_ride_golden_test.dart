import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/event_registrant.dart';
import 'package:rideglory/features/events/domain/registration_status.dart';
import 'package:rideglory/features/events/presentation/cubit/registrants_cubit.dart';
import 'package:rideglory/features/events/presentation/cubit/registrants_state.dart';
import 'package:rideglory/features/live_ride/domain/live_ride_contacts.dart';
import 'package:rideglory/features/live_ride/domain/live_rider.dart';
import 'package:rideglory/features/live_ride/domain/location_permission_state.dart';
import 'package:rideglory/features/live_ride/domain/rider_position.dart';
import 'package:rideglory/features/live_ride/domain/sos_alert.dart';
import 'package:rideglory/features/live_ride/domain/sos_outbox_item.dart';
import 'package:rideglory/features/live_ride/domain/sos_status.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/live_ride_cubit.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/live_ride_state.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sharing_status.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sos_cubit.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sos_send_state.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sos_state.dart';
import 'package:rideglory/features/live_ride/presentation/live_ride_route_args.dart';
import 'package:rideglory/features/live_ride/presentation/pages/live_ride_view.dart';
import 'package:rideglory/features/live_ride/presentation/pages/live_riders_view.dart';
import 'package:rideglory/features/live_ride/presentation/pages/sos_active_view.dart';
import 'package:rideglory/features/live_ride/presentation/widgets/sos_other_sheet.dart';
import 'package:rideglory/shared/cubits/connectivity/connectivity_cubit.dart';
import 'package:rideglory/shared/cubits/connectivity/connectivity_state.dart';

import '../../../../support/golden_helpers.dart';

class _MockLiveRideCubit extends MockCubit<LiveRideState>
    implements LiveRideCubit {}

class _MockSosCubit extends MockCubit<SosState> implements SosCubit {}

class _MockConnectivityCubit extends MockCubit<ConnectivityState>
    implements ConnectivityCubit {}

class _MockRegistrantsCubit extends MockCubit<RegistrantsState>
    implements RegistrantsCubit {}

const _args = LiveRideRouteArgs(
  eventName: 'Rodada al Nevado del Ruiz',
  isOwner: true,
  ownerId: 'owner-1',
);

LiveRider _leader() {
  return LiveRider(
    eventId: 'event-1',
    userId: 'owner-1',
    fullName: 'Juan Camilo',
    isOrganizer: true,
    lat: 4.678,
    lng: -75.658,
    recordedAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
}

LiveRider _rider(String userId, String name, double lat, double lng) {
  return LiveRider(
    eventId: 'event-1',
    userId: userId,
    fullName: name,
    isOrganizer: false,
    lat: lat,
    lng: lng,
    recordedAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
}

SosAlert _alert() {
  return SosAlert(
    id: 'sos-1',
    eventId: 'event-1',
    userId: 'user-2',
    riderName: 'Carlos Ramírez',
    riderPhone: '+573001112233',
    lat: 4.681,
    lng: -75.651,
    accuracyM: 8,
    status: SosStatus.active,
    createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 3)),
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
    when(
      () => liveRideCubit.resolveArgs(any(), any()),
    ).thenAnswer((_) async {});
  });

  Widget wrapLiveRide(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LiveRideCubit>.value(value: liveRideCubit),
        BlocProvider<SosCubit>.value(value: sosCubit),
        BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
      ],
      child: child,
    );
  }

  testWidgets('LV1 - rodada en vivo, compartiendo', (tester) async {
    when(() => sosCubit.state).thenReturn(const SosState());
    when(() => liveRideCubit.state).thenReturn(
      LiveRideState(
        permission: LocationPermissionState.whileInUse,
        sharing: SharingStatus.sharing,
        riders: ResultState.data(
          data: [
            _leader(),
            _rider('user-2', 'Camilo Agudelo', 4.68, -75.66),
            _rider('user-3', 'Sofía Pardo', 4.69, -75.64),
          ],
        ),
        myPosition: RiderPosition(
          lat: 4.678,
          lng: -75.658,
          recordedAt: DateTime.now().toUtc(),
        ),
        args: _args,
      ),
    );

    await pumpGolden(
      tester,
      wrapLiveRide(
        const LiveRideView(
          eventId: 'event-1',
          args: _args,
          showMapTiles: false,
        ),
      ),
    );

    await expectLater(
      find.byType(LiveRideView),
      matchesGoldenFile('goldens/lv1_live_ride_sharing.png'),
    );
  });

  testWidgets('LV1b - rodada en vivo, sin compartir', (tester) async {
    when(() => sosCubit.state).thenReturn(const SosState());
    when(() => liveRideCubit.state).thenReturn(
      LiveRideState(
        permission: LocationPermissionState.whileInUse,
        riders: ResultState.data(data: [_leader()]),
        args: _args,
      ),
    );

    await pumpGolden(
      tester,
      wrapLiveRide(
        const LiveRideView(
          eventId: 'event-1',
          args: _args,
          showMapTiles: false,
        ),
      ),
    );

    await expectLater(
      find.byType(LiveRideView),
      matchesGoldenFile('goldens/lv1b_live_ride_not_sharing.png'),
    );
  });

  testWidgets('LV7 - rodada terminada', (tester) async {
    when(() => sosCubit.state).thenReturn(const SosState());
    when(() => liveRideCubit.state).thenReturn(
      const LiveRideState(
        permission: LocationPermissionState.whileInUse,
        riders: ResultState.data(data: []),
        isEventFinished: true,
      ),
    );

    await pumpGolden(
      tester,
      wrapLiveRide(
        const LiveRideView(
          eventId: 'event-1',
          args: _args,
          showMapTiles: false,
        ),
      ),
    );

    await expectLater(
      find.byType(LiveRideView),
      matchesGoldenFile('goldens/lv7_live_ride_finished.png'),
    );
  });

  testWidgets('LV4a - SOS activo, pendiente', (tester) async {
    when(() => liveRideCubit.state).thenReturn(
      const LiveRideState(
        contacts: LiveRideContacts(
          organizerName: 'Juan Camilo',
          organizerPhone: '+573001110000',
          emergencyContactName: 'Laura Agudelo',
          emergencyContactPhone: '+573002223344',
        ),
      ),
    );
    when(() => sosCubit.state).thenReturn(
      SosState(
        mine: SosSendState.pending(
          item: SosOutboxItem(
            clientId: 'client-1',
            eventId: 'event-1',
            position: RiderPosition(
              lat: 4.678,
              lng: -75.658,
              recordedAt: DateTime.now().toUtc(),
              accuracyM: 8,
            ),
            createdAt: DateTime.now().toUtc(),
          ),
        ),
      ),
    );

    await pumpGolden(
      tester,
      wrapLiveRide(const SosActiveView(eventId: 'event-1', args: _args)),
    );

    await expectLater(
      find.byType(SosActiveView),
      matchesGoldenFile('goldens/lv4a_sos_pending.png'),
    );
  });

  testWidgets('LV4b - SOS activo, confirmado', (tester) async {
    when(() => liveRideCubit.state).thenReturn(
      const LiveRideState(
        contacts: LiveRideContacts(
          organizerName: 'Juan Camilo',
          organizerPhone: '+573001110000',
          emergencyContactName: 'Laura Agudelo',
          emergencyContactPhone: '+573002223344',
        ),
      ),
    );
    when(() => sosCubit.state).thenReturn(
      SosState(
        mine: SosSendState.confirmed(
          alert: SosAlert(
            id: 'sos-mine',
            eventId: 'event-1',
            userId: 'user-1',
            riderName: 'Camilo Agudelo',
            lat: 4.678,
            lng: -75.658,
            accuracyM: 8,
            status: SosStatus.active,
            createdAt: DateTime.now().toUtc(),
          ),
        ),
      ),
    );

    await pumpGolden(
      tester,
      wrapLiveRide(const SosActiveView(eventId: 'event-1', args: _args)),
    );

    await expectLater(
      find.byType(SosActiveView),
      matchesGoldenFile('goldens/lv4b_sos_confirmed.png'),
    );
  });

  testWidgets('LV5b - tarjeta de SOS de otro rider', (tester) async {
    await pumpGolden(
      tester,
      wrapLiveRide(
        MultiBlocProvider(
          providers: [BlocProvider<SosCubit>.value(value: sosCubit)],
          child: Scaffold(body: SosOtherSheet(alert: _alert(), isOwner: true)),
        ),
      ),
    );

    await expectLater(
      find.byType(SosOtherSheet),
      matchesGoldenFile('goldens/lv5b_sos_other_sheet.png'),
    );
  });

  testWidgets('LV6 - riders del organizador', (tester) async {
    final registrantsCubit = _MockRegistrantsCubit();
    when(() => registrantsCubit.state).thenReturn(
      const RegistrantsState(
        registrants: ResultState.data(
          data: [
            EventRegistrant(
              id: 'owner-1',
              userId: 'owner-1',
              fullName: 'Juan Camilo',
              status: RegistrationStatus.approved,
              shareMedicalInfo: false,
              allowOrganizerContact: true,
              phone: '+573001110000',
            ),
            EventRegistrant(
              id: 'reg-2',
              userId: 'user-2',
              fullName: 'Camilo Agudelo',
              status: RegistrationStatus.approved,
              shareMedicalInfo: false,
              allowOrganizerContact: true,
              phone: '+573002223344',
            ),
            EventRegistrant(
              id: 'reg-3',
              userId: 'user-3',
              fullName: 'Sofía Pardo',
              status: RegistrationStatus.approved,
              shareMedicalInfo: false,
              allowOrganizerContact: true,
              phone: '+573003334455',
            ),
          ],
        ),
      ),
    );
    when(() => liveRideCubit.state).thenReturn(
      LiveRideState(
        riders: ResultState.data(
          data: [_leader(), _rider('user-2', 'Camilo Agudelo', 4.68, -75.66)],
        ),
      ),
    );

    await pumpGolden(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<RegistrantsCubit>.value(value: registrantsCubit),
          BlocProvider<LiveRideCubit>.value(value: liveRideCubit),
        ],
        child: const LiveRidersView(eventId: 'event-1', args: _args),
      ),
    );

    await expectLater(
      find.byType(LiveRidersView),
      matchesGoldenFile('goldens/lv6_live_riders.png'),
    );
  });
}
