// Widget tests — RegistrationStepIndicator
// Covers: renders one numbered dot per step and highlights reached steps.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/registration_step_indicator.dart';

Widget _wrap({required int stepCount, required int currentStep}) {
  return MaterialApp(
    home: Scaffold(
      body: RegistrationStepIndicator(
        stepCount: stepCount,
        currentStep: currentStep,
      ),
    ),
  );
}

Color _dotColor(WidgetTester tester, String label) {
  final container = tester.widget<Container>(
    find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
  );
  return (container.decoration! as BoxDecoration).color!;
}

void main() {
  group('RegistrationStepIndicator', () {
    testWidgets('renders a numbered dot for each step', (tester) async {
      await tester.pumpWidget(_wrap(stepCount: 4, currentStep: 0));

      for (final label in ['1', '2', '3', '4']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('highlights only reached steps in the accent color', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(stepCount: 4, currentStep: 1));

      expect(_dotColor(tester, '1'), AppColors.primary);
      expect(_dotColor(tester, '2'), AppColors.primary);
      expect(_dotColor(tester, '3'), AppColors.darkTertiary);
      expect(_dotColor(tester, '4'), AppColors.darkTertiary);
    });
  });
}
