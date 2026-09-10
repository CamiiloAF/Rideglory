import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/theme/app_theme.dart';
import 'package:rideglory/features/events/presentation/cubit/registrants_cubit.dart';
import 'package:rideglory/features/events/presentation/cubit/registrants_state.dart';
import 'package:rideglory/features/live_ride/domain/live_ride_contacts.dart';
import 'package:rideglory/features/live_ride/domain/live_rider.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/live_ride_cubit.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/live_ride_state.dart';
import 'package:rideglory/features/live_ride/presentation/live_ride_route_args.dart';
import 'package:rideglory/features/live_ride/presentation/pages/live_riders_view.dart';
import 'package:rideglory/l10n/app_localizations.dart';

class _MockLiveRideCubit extends MockCubit<LiveRideState>
    implements LiveRideCubit {}

class _MockRegistrantsCubit extends MockCubit<RegistrantsState>
    implements RegistrantsCubit {}

const _participantArgs = LiveRideRouteArgs(
  eventName: 'Rodada al Nevado del Ruiz',
  isOwner: false,
  ownerId: 'owner-1',
);

const _ownerArgs = LiveRideRouteArgs(
  eventName: 'Rodada al Nevado del Ruiz',
  isOwner: true,
  ownerId: 'owner-1',
);

Widget _wrap({
  required LiveRideCubit liveRideCubit,
  required RegistrantsCubit registrantsCubit,
  required LiveRideRouteArgs args,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<LiveRideCubit>.value(value: liveRideCubit),
      BlocProvider<RegistrantsCubit>.value(value: registrantsCubit),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LiveRidersView(eventId: 'event-1', args: args),
    ),
  );
}

void main() {
  late _MockLiveRideCubit liveRideCubit;
  late _MockRegistrantsCubit registrantsCubit;

  setUp(() {
    liveRideCubit = _MockLiveRideCubit();
    registrantsCubit = _MockRegistrantsCubit();
  });

  testWidgets(
    'a viewer participant sees the organizer as leader with the phone '
    'cached in contacts, even without an event_registrations row',
    (tester) async {
      when(
        () => registrantsCubit.state,
      ).thenReturn(const RegistrantsState(registrants: ResultState.empty()));
      when(() => liveRideCubit.state).thenReturn(
        const LiveRideState(
          riders: ResultState.data(data: <LiveRider>[]),
          contacts: LiveRideContacts(
            organizerName: 'Juan Camilo',
            organizerPhone: '+573001110000',
          ),
        ),
      );

      await tester.pumpWidget(
        _wrap(
          liveRideCubit: liveRideCubit,
          registrantsCubit: registrantsCubit,
          args: _participantArgs,
        ),
      );
      await tester.pump();

      expect(find.textContaining('Juan Camilo'), findsOneWidget);
      expect(find.byIcon(LucideIcons.phone), findsWidgets);
    },
  );

  testWidgets('the owner viewing the list is never asked for their own phone', (
    tester,
  ) async {
    when(
      () => registrantsCubit.state,
    ).thenReturn(const RegistrantsState(registrants: ResultState.empty()));
    when(() => liveRideCubit.state).thenReturn(
      const LiveRideState(
        riders: ResultState.data(data: <LiveRider>[]),
        contacts: LiveRideContacts(organizerName: 'Juan Camilo'),
      ),
    );

    await tester.pumpWidget(
      _wrap(
        liveRideCubit: liveRideCubit,
        registrantsCubit: registrantsCubit,
        args: _ownerArgs,
      ),
    );
    await tester.pump();

    expect(find.text('Todavía no hay inscritos'), findsOneWidget);
  });
}
