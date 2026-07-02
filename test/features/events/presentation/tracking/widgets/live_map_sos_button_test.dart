import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/live_map_sos_button.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/sos_button.dart';
import 'package:rideglory/l10n/app_localizations.dart';

class MockLiveTrackingCubit extends MockCubit<LiveTrackingState>
    implements LiveTrackingCubit {}

const _activeState = LiveTrackingState(
  ridersResult: ResultState<List<RiderTrackingModel>>.data(data: []),
);
const _finishedState = LiveTrackingState(
  ridersResult: ResultState<List<RiderTrackingModel>>.data(data: []),
  isFinished: true,
);

Widget _host(MockLiveTrackingCubit cubit) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      AppLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: Scaffold(
      body: BlocProvider<LiveTrackingCubit>.value(
        value: cubit,
        child: Stack(
          children: [LiveMapSosButton(onPressed: () {})],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'shows the SOS button while the ride is active',
    (tester) async {
      final cubit = MockLiveTrackingCubit();
      whenListen(
        cubit,
        const Stream<LiveTrackingState>.empty(),
        initialState: _activeState,
      );

      await tester.pumpWidget(_host(cubit));

      expect(find.byType(SosButton), findsOneWidget);
    },
  );

  testWidgets(
    'hides the SOS button when the ride finishes (isFinished flips true)',
    (tester) async {
      final cubit = MockLiveTrackingCubit();
      // Regression: buildWhen must react to isFinished even though hasSentSos
      // does not change, otherwise the button lingers after the ride ends.
      whenListen(
        cubit,
        Stream<LiveTrackingState>.fromIterable([_finishedState]),
        initialState: _activeState,
      );

      await tester.pumpWidget(_host(cubit));
      expect(find.byType(SosButton), findsOneWidget);

      await tester.pump(); // process the isFinished emission

      expect(find.byType(SosButton), findsNothing);
    },
  );
}
