import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/design_system/theme/app_theme.dart';
import 'package:rideglory/features/live_ride/domain/rider_position.dart';
import 'package:rideglory/features/live_ride/domain/sos_alert.dart';
import 'package:rideglory/features/live_ride/domain/sos_outbox_item.dart';
import 'package:rideglory/features/live_ride/domain/sos_status.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/live_ride_cubit.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/live_ride_state.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sos_cubit.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sos_send_state.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sos_state.dart';
import 'package:rideglory/features/live_ride/presentation/live_ride_route_args.dart';
import 'package:rideglory/features/live_ride/presentation/pages/sos_active_view.dart';
import 'package:rideglory/l10n/app_localizations.dart';

class _MockSosCubit extends MockCubit<SosState> implements SosCubit {}

class _MockLiveRideCubit extends MockCubit<LiveRideState>
    implements LiveRideCubit {}

const _args = LiveRideRouteArgs(
  eventName: 'Rodada al Nevado del Ruiz',
  isOwner: false,
  ownerId: 'owner-1',
);

Widget _wrap(SosCubit sosCubit, LiveRideCubit liveRideCubit) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<SosCubit>.value(value: sosCubit),
      BlocProvider<LiveRideCubit>.value(value: liveRideCubit),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SosActiveView(eventId: 'event-1', args: _args),
    ),
  );
}

void main() {
  late _MockSosCubit sosCubit;
  late _MockLiveRideCubit liveRideCubit;

  setUp(() {
    sosCubit = _MockSosCubit();
    liveRideCubit = _MockLiveRideCubit();
    when(() => liveRideCubit.state).thenReturn(const LiveRideState());
  });

  testWidgets('pending SOS never says it was sent', (tester) async {
    when(() => sosCubit.state).thenReturn(
      SosState(
        mine: SosSendState.pending(
          item: SosOutboxItem(
            clientId: 'client-1',
            eventId: 'event-1',
            position: RiderPosition(
              lat: 4.678,
              lng: -75.658,
              recordedAt: DateTime.utc(2026, 9, 10, 12),
              accuracyM: 8,
            ),
            createdAt: DateTime.utc(2026, 9, 10, 12),
          ),
        ),
      ),
    );

    await tester.pumpWidget(_wrap(sosCubit, liveRideCubit));

    expect(find.text('Alerta pendiente'), findsOneWidget);
    expect(find.text('Enviando cuando haya señal'), findsOneWidget);
    expect(find.text('El grupo ya sabe dónde estás'), findsNothing);
  });

  testWidgets('confirmed SOS shows the confirmed chip and close action', (
    tester,
  ) async {
    when(() => sosCubit.state).thenReturn(
      SosState(
        mine: SosSendState.confirmed(
          alert: SosAlert(
            id: 'sos-1',
            eventId: 'event-1',
            userId: 'user-1',
            riderName: 'Camilo Agudelo',
            lat: 4.678,
            lng: -75.658,
            status: SosStatus.active,
            createdAt: DateTime.utc(2026, 9, 10, 12),
            accuracyM: 8,
          ),
        ),
      ),
    );

    await tester.pumpWidget(_wrap(sosCubit, liveRideCubit));

    expect(find.text('El grupo ya sabe dónde estás'), findsOneWidget);
    expect(find.text('Alerta confirmada'), findsOneWidget);
    expect(find.text('Ya estoy bien — cerrar SOS'), findsOneWidget);
  });
}
