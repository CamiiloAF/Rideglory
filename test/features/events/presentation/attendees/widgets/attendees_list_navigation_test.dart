import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/features/event_registration/domain/model/registration_model.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendees_list.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('AttendeesList — Navigation Tests (US-2-3)', () {
    // TC-2-41: Attendee tap navigates to rider profile with userId
    testWidgets(
      'TC-2-41: Attendee tap navigates to rider profile',
      (WidgetTester tester) async {
        const mockRegistration = RegistrationModel(
          id: 'reg-123',
          userId: 'user-456',
          eventId: 'event-789',
          status: RegistrationStatus.approved,
          userFullName: 'Juan Pérez',
          userEmail: 'juan@example.com',
        );

        final registrations = [mockRegistration];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AttendeesList(
                registrations: registrations,
                isProcessed: true,
                onNavigateToRiderProfile: (userId) {
                  // Verify navigation is called with correct userId
                  expect(userId, 'user-456');
                },
              ),
            ),
          ),
        );

        // Find and tap the attendee item
        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();
      },
    );

    // TC-2-42: Multiple attendees can be tapped independently
    testWidgets(
      'TC-2-42: Multiple attendees can be tapped independently',
      (WidgetTester tester) async {
        final registrations = [
          const RegistrationModel(
            id: 'reg-1',
            userId: 'user-1',
            eventId: 'event-789',
            status: RegistrationStatus.approved,
            userFullName: 'Juan Pérez',
            userEmail: 'juan@example.com',
          ),
          const RegistrationModel(
            id: 'reg-2',
            userId: 'user-2',
            eventId: 'event-789',
            status: RegistrationStatus.approved,
            userFullName: 'María García',
            userEmail: 'maria@example.com',
          ),
        ];

        var tappedUserId = '';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AttendeesList(
                registrations: registrations,
                isProcessed: true,
                onNavigateToRiderProfile: (userId) {
                  tappedUserId = userId;
                },
              ),
            ),
          ),
        );

        // Tap first attendee
        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();
        expect(tappedUserId, 'user-1');

        // Tap second attendee
        await tester.tap(find.byType(ListTile).last);
        await tester.pumpAndSettle();
        expect(tappedUserId, 'user-2');
      },
    );

    // TC-2-43: Attendee item shows trailing chevron when clickable
    testWidgets(
      'TC-2-43: Attendee item shows chevron icon when clickable',
      (WidgetTester tester) async {
        const mockRegistration = RegistrationModel(
          id: 'reg-123',
          userId: 'user-456',
          eventId: 'event-789',
          status: RegistrationStatus.approved,
          userFullName: 'Juan Pérez',
          userEmail: 'juan@example.com',
        );

        final registrations = [mockRegistration];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AttendeesList(
                registrations: registrations,
                isProcessed: true,
                onNavigateToRiderProfile: (_) {},
              ),
            ),
          ),
        );

        // Check for chevron icon (indicates clickable item)
        expect(
          find.byIcon(Icons.chevron_right_rounded),
          findsWidgets,
          reason: 'Should show chevron for clickable attendee item',
        );
      },
    );

    // TC-2-44: Empty attendees list renders without error
    testWidgets(
      'TC-2-44: Empty attendees list renders without error',
      (WidgetTester tester) async {
        final registrations = <RegistrationModel>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AttendeesList(
                registrations: registrations,
                isProcessed: true,
                onNavigateToRiderProfile: (_) {},
              ),
            ),
          ),
        );

        // Should render without crashing
        expect(find.byType(AttendeesList), findsOneWidget);
      },
    );

    // TC-2-45: Attendee list displays user names
    testWidgets(
      'TC-2-45: Attendee list displays user names',
      (WidgetTester tester) async {
        const mockRegistration = RegistrationModel(
          id: 'reg-123',
          userId: 'user-456',
          eventId: 'event-789',
          status: RegistrationStatus.approved,
          userFullName: 'Juan Pérez',
          userEmail: 'juan@example.com',
        );

        final registrations = [mockRegistration];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AttendeesList(
                registrations: registrations,
                isProcessed: true,
                onNavigateToRiderProfile: (_) {},
              ),
            ),
          ),
        );

        expect(
          find.text('Juan Pérez'),
          findsWidgets,
          reason: 'Should display attendee name',
        );
      },
    );

    // TC-2-46: Attendee list displays user emails
    testWidgets(
      'TC-2-46: Attendee list displays user emails',
      (WidgetTester tester) async {
        const mockRegistration = RegistrationModel(
          id: 'reg-123',
          userId: 'user-456',
          eventId: 'event-789',
          status: RegistrationStatus.approved,
          userFullName: 'Juan Pérez',
          userEmail: 'juan@example.com',
        );

        final registrations = [mockRegistration];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AttendeesList(
                registrations: registrations,
                isProcessed: true,
                onNavigateToRiderProfile: (_) {},
              ),
            ),
          ),
        );

        expect(
          find.text('juan@example.com'),
          findsWidgets,
          reason: 'Should display attendee email',
        );
      },
    );
  });
}
