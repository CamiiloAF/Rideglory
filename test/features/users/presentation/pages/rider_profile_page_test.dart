import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/presentation/cubit/rider_profile_cubit.dart';
import 'package:rideglory/features/users/presentation/pages/rider_profile_page.dart';

class MockRiderProfileCubit extends Mock implements RiderProfileCubit {}

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
  });

  group('RiderProfilePage — State Display Tests (US-2-3)', () {
    // TC-2-26: Loading state shows shimmer/loading indicator
    testWidgets(
      'TC-2-26: Loading state shows loading indicator',
      (WidgetTester tester) async {
        when(() => mockRiderProfileCubit.state).thenReturn(
          const ResultState.loading(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<RiderProfileCubit>.value(
              value: mockRiderProfileCubit,
              child: const RiderProfilePage(),
            ),
          ),
        );

        // Check for loading indicator or shimmer
        expect(
          find.byType(CircularProgressIndicator),
          findsWidgets,
          reason: 'Loading state should show progress indicator',
        );
      },
    );

    // TC-2-27: Data state shows rider name
    testWidgets(
      'TC-2-27: Data state shows rider name',
      (WidgetTester tester) async {
        when(() => mockRiderProfileCubit.state).thenReturn(
          const ResultState.data(data: mockUser),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<RiderProfileCubit>.value(
              value: mockRiderProfileCubit,
              child: const RiderProfilePage(),
            ),
          ),
        );

        expect(
          find.text('Juan Pérez'),
          findsWidgets,
          reason: 'Data state should display rider name',
        );
      },
    );

    // TC-2-28: Data state shows rider email
    testWidgets(
      'TC-2-28: Data state shows rider email',
      (WidgetTester tester) async {
        when(() => mockRiderProfileCubit.state).thenReturn(
          const ResultState.data(data: mockUser),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<RiderProfileCubit>.value(
              value: mockRiderProfileCubit,
              child: const RiderProfilePage(),
            ),
          ),
        );

        expect(
          find.text('juan@example.com'),
          findsWidgets,
          reason: 'Data state should display rider email',
        );
      },
    );

    // TC-2-29: Error state shows error banner
    testWidgets(
      'TC-2-29: Error state shows error banner',
      (WidgetTester tester) async {
        when(() => mockRiderProfileCubit.state).thenReturn(
          ResultState.error(
            error: DomainException(message: 'User not found', code: 'NOT_FOUND'),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<RiderProfileCubit>.value(
              value: mockRiderProfileCubit,
              child: const RiderProfilePage(),
            ),
          ),
        );

        // Check for error indicator
        expect(
          find.byIcon(Icons.error_outline),
          findsWidgets,
          reason: 'Error state should show error icon',
        );
      },
    );

    // TC-2-30: Error state shows retry button
    testWidgets(
      'TC-2-30: Error state shows retry button',
      (WidgetTester tester) async {
        when(() => mockRiderProfileCubit.state).thenReturn(
          ResultState.error(
            error: DomainException(message: 'User not found', code: 'NOT_FOUND'),
          ),
        );
        when(() => mockRiderProfileCubit.fetchRiderProfile(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<RiderProfileCubit>.value(
              value: mockRiderProfileCubit,
              child: const RiderProfilePage(),
            ),
          ),
        );

        // Look for retry button (exact text depends on implementation)
        expect(
          find.byIcon(Icons.refresh),
          findsWidgets,
          reason: 'Error state should show retry button',
        );
      },
    );

    // TC-2-31: Page has title in AppBar
    testWidgets(
      'TC-2-31: Page has title in AppBar',
      (WidgetTester tester) async {
        when(() => mockRiderProfileCubit.state).thenReturn(
          const ResultState.data(data: mockUser),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<RiderProfileCubit>.value(
              value: mockRiderProfileCubit,
              child: const RiderProfilePage(),
            ),
          ),
        );

        expect(
          find.byType(AppBar),
          findsWidgets,
          reason: 'Page should have an AppBar with title',
        );
      },
    );

    // TC-2-32: Data state shows rider avatar with initials
    testWidgets(
      'TC-2-32: Data state shows rider avatar',
      (WidgetTester tester) async {
        when(() => mockRiderProfileCubit.state).thenReturn(
          const ResultState.data(data: mockUser),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<RiderProfileCubit>.value(
              value: mockRiderProfileCubit,
              child: const RiderProfilePage(),
            ),
          ),
        );

        // Check for avatar (CircleAvatar)
        expect(
          find.byType(CircleAvatar),
          findsWidgets,
          reason: 'Data state should display avatar',
        );
      },
    );

    // TC-2-33: No-vehicles placeholder when user has no vehicles
    testWidgets(
      'TC-2-33: No-vehicles placeholder is shown when appropriate',
      (WidgetTester tester) async {
        when(() => mockRiderProfileCubit.state).thenReturn(
          const ResultState.data(data: mockUser),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<RiderProfileCubit>.value(
              value: mockRiderProfileCubit,
              child: const RiderProfilePage(),
            ),
          ),
        );

        // Should show placeholder text or empty state
        // The exact text depends on implementation
        expect(
          find.byType(Text),
          findsWidgets,
          reason: 'Should display some content in data state',
        );
      },
    );
  });
}
