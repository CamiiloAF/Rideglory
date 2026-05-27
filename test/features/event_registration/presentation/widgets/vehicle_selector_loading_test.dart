// Widget tests — VehicleSelectorLoading
// Covers: AC-6 (Issue #21) — spinner visible while VehicleCubit is loading/initial

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/vehicle_selector_loading.dart';

void main() {
  group('VehicleSelectorLoading', () {
    testWidgets(
      'TC-vsel-1: shows CircularProgressIndicator',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: VehicleSelectorLoading()),
          ),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'TC-vsel-2: shows no text (not empty-state text)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: VehicleSelectorLoading()),
          ),
        );
        // Should not show any text — pure spinner
        expect(find.byType(Text), findsNothing);
      },
    );

    testWidgets(
      'TC-vsel-3: widget is centered inside a Padding',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: VehicleSelectorLoading()),
          ),
        );
        expect(find.byType(Padding), findsAtLeastNWidgets(1));
        expect(find.byType(Center), findsOneWidget);
      },
    );
  });
}
