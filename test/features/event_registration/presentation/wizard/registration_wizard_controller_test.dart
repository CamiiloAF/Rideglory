// Unit tests — RegistrationWizardController
// Covers wizard step navigation: advance, retreat, bounds clamping.

import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/registration_wizard_controller.dart';

void main() {
  group('RegistrationWizardController', () {
    test('starts on the first step', () {
      final controller = RegistrationWizardController(stepCount: 4);
      addTearDown(controller.dispose);

      expect(controller.currentStep, 0);
      expect(controller.isFirstStep, isTrue);
      expect(controller.isLastStep, isFalse);
    });

    test('next() advances and notifies listeners', () {
      final controller = RegistrationWizardController(stepCount: 4);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.next();

      expect(controller.currentStep, 1);
      expect(notifications, 1);
    });

    test('previous() retreats but never goes below the first step', () {
      final controller = RegistrationWizardController(stepCount: 4);
      addTearDown(controller.dispose);

      controller
        ..next()
        ..next()
        ..previous();
      expect(controller.currentStep, 1);

      controller
        ..previous()
        ..previous();
      expect(controller.currentStep, 0);
      expect(controller.isFirstStep, isTrue);
    });

    test('next() never advances past the last step', () {
      final controller = RegistrationWizardController(stepCount: 4);
      addTearDown(controller.dispose);

      controller
        ..next()
        ..next()
        ..next()
        ..next()
        ..next();

      expect(controller.currentStep, 3);
      expect(controller.isLastStep, isTrue);
    });

    test('goTo() jumps to a valid step and ignores out-of-range targets', () {
      final controller = RegistrationWizardController(stepCount: 4);
      addTearDown(controller.dispose);

      controller.goTo(2);
      expect(controller.currentStep, 2);

      controller.goTo(99);
      expect(controller.currentStep, 2);

      controller.goTo(-1);
      expect(controller.currentStep, 2);
    });
  });
}
