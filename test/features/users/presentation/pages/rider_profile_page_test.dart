import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/presentation/cubit/rider_profile_cubit.dart';
import 'package:rideglory/features/users/presentation/pages/rider_profile_page.dart';
import 'package:rideglory/l10n/app_localizations.dart';

class MockRiderProfileCubit extends Mock implements RiderProfileCubit {}

Widget _buildTestPage(String userId) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.dark,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      AppLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: RiderProfilePage(userId: userId),
  );
}

void main() {
  late MockRiderProfileCubit mockRiderProfileCubit;

  const mockUser = UserModel(
    id: 'user-123',
    fullName: 'Juan Pérez',
    email: 'juan@example.com',
  );

  setUp(() {
    mockRiderProfileCubit = MockRiderProfileCubit();
    when(() => mockRiderProfileCubit.stream).thenAnswer((_) => Stream.empty());
    when(() => mockRiderProfileCubit.fetchRiderProfile(any()))
        .thenAnswer((_) async {});
    when(() => mockRiderProfileCubit.close()).thenAnswer((_) async {});
    GetIt.I.allowReassignment = true;
    GetIt.I.registerFactory<RiderProfileCubit>(() => mockRiderProfileCubit);
  });

  tearDown(() {
    if (GetIt.I.isRegistered<RiderProfileCubit>()) {
      GetIt.I.unregister<RiderProfileCubit>();
    }
    GetIt.I.allowReassignment = false;
  });

  group('RiderProfilePage — State Display Tests (US-2-3)', () {
    testWidgets(
      'TC-2-26: Loading state shows loading widget',
      (WidgetTester tester) async {
        when(() => mockRiderProfileCubit.state).thenReturn(
          const ResultState.loading(),
        );

        await tester.pumpWidget(_buildTestPage('user-123'));
        await tester.pump();

        expect(find.byType(RiderProfilePage), findsOneWidget);
      },
    );

    testWidgets(
      'TC-2-27: Data state shows rider name',
      (WidgetTester tester) async {
        when(() => mockRiderProfileCubit.state).thenReturn(
          const ResultState.data(data: mockUser),
        );

        await tester.pumpWidget(_buildTestPage('user-123'));
        await tester.pumpAndSettle();

        expect(find.text('Juan Pérez'), findsWidgets);
      },
    );

    testWidgets(
      'TC-2-28: Data state shows rider email',
      (WidgetTester tester) async {
        when(() => mockRiderProfileCubit.state).thenReturn(
          const ResultState.data(data: mockUser),
        );

        await tester.pumpWidget(_buildTestPage('user-123'));
        await tester.pumpAndSettle();

        expect(find.text('juan@example.com'), findsWidgets);
      },
    );

    testWidgets(
      'TC-2-29: Error state renders without crash',
      (WidgetTester tester) async {
        when(() => mockRiderProfileCubit.state).thenReturn(
          const ResultState.error(
            error: DomainException(message: 'User not found'),
          ),
        );

        await tester.pumpWidget(_buildTestPage('user-123'));
        await tester.pump();

        expect(find.byType(RiderProfilePage), findsOneWidget);
      },
    );

    testWidgets(
      'TC-2-30: Initial state renders without crash',
      (WidgetTester tester) async {
        when(() => mockRiderProfileCubit.state).thenReturn(
          const ResultState.initial(),
        );

        await tester.pumpWidget(_buildTestPage('user-123'));
        await tester.pump();

        expect(find.byType(RiderProfilePage), findsOneWidget);
      },
    );
  });
}
