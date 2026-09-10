import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/design_system/theme/app_theme.dart';
import 'package:rideglory/features/events/domain/event.dart';
import 'package:rideglory/features/events/domain/event_difficulty.dart';
import 'package:rideglory/features/events/domain/event_state.dart';
import 'package:rideglory/features/events/presentation/cubit/events_list_cubit.dart';
import 'package:rideglory/features/events/presentation/cubit/events_list_state.dart';
import 'package:rideglory/features/events/presentation/pages/events_list_view.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/cubits/connectivity/connectivity_cubit.dart';
import 'package:rideglory/shared/cubits/connectivity/connectivity_state.dart';

class _MockEventsListCubit extends MockCubit<EventsListState>
    implements EventsListCubit {}

class _MockConnectivityCubit extends MockCubit<ConnectivityState>
    implements ConnectivityCubit {}

final _event = Event(
  id: 'e1',
  ownerId: 'owner-1',
  ownerName: 'Camilo',
  name: 'Rodada al Nevado del Ruiz',
  startAt: DateTime(2026, 9, 20, 6),
  difficulty: EventDifficulty.medium,
  state: EventState.published,
  price: 0,
  approvedCount: 3,
  destinationName: 'Manizales, Caldas',
);

Widget _wrap(EventsListCubit cubit, ConnectivityCubit connectivityCubit) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<EventsListCubit>.value(value: cubit),
      BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const EventsListView(),
    ),
  );
}

void main() {
  late _MockEventsListCubit cubit;
  late _MockConnectivityCubit connectivityCubit;

  setUpAll(() {
    registerFallbackValue(EventsSegment.upcoming);
  });

  setUp(() {
    cubit = _MockEventsListCubit();
    connectivityCubit = _MockConnectivityCubit();
    when(
      () => connectivityCubit.state,
    ).thenReturn(const ConnectivityState.online());
  });

  testWidgets('shows a skeleton while loading', (tester) async {
    when(() => cubit.state).thenReturn(const EventsListState());

    await tester.pumpWidget(_wrap(cubit, connectivityCubit));

    expect(find.text('Rodadas'), findsOneWidget);
    expect(find.byType(ListView), findsWidgets);
  });

  testWidgets('shows the empty state with a CTA for Próximas', (tester) async {
    when(() => cubit.state).thenReturn(
      const EventsListState(
        upcoming: ResultState.data(data: []),
        mine: ResultState.data(data: []),
      ),
    );

    await tester.pumpWidget(_wrap(cubit, connectivityCubit));

    expect(find.text('Todavía no hay rodadas'), findsOneWidget);
    expect(find.text('Crear rodada'), findsWidgets);
  });

  testWidgets('shows an actionable error state', (tester) async {
    when(() => cubit.state).thenReturn(
      const EventsListState(
        upcoming: ResultState.error(error: DomainException(message: 'boom')),
        mine: ResultState.data(data: []),
      ),
    );

    await tester.pumpWidget(_wrap(cubit, connectivityCubit));

    expect(find.text('No pudimos cargar las rodadas'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('shows the event cards when there is data', (tester) async {
    when(
      () => cubit.state,
    ).thenReturn(EventsListState(upcoming: ResultState.data(data: [_event])));

    await tester.pumpWidget(_wrap(cubit, connectivityCubit));

    expect(find.text('Rodada al Nevado del Ruiz'), findsOneWidget);
    expect(find.text('Manizales, Caldas'), findsOneWidget);
    expect(find.text('Gratis'), findsOneWidget);
  });

  testWidgets('switching to Mías reflects the segment in the cubit', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(
      const EventsListState(
        upcoming: ResultState.data(data: []),
        mine: ResultState.data(data: []),
      ),
    );
    when(() => cubit.selectSegment(any())).thenAnswer((_) {});

    await tester.pumpWidget(_wrap(cubit, connectivityCubit));
    await tester.tap(find.text('Mías'));
    await tester.pump();

    verify(() => cubit.selectSegment(EventsSegment.mine)).called(1);
  });
}
