import 'package:flutter/foundation.dart';

/// Drives the multi-step registration wizard: tracks the active step and
/// exposes navigation. Form data itself lives in the [FormBuilder] /
/// [RegistrationFormCubit]; this controller only owns the step index.
class RegistrationWizardController extends ChangeNotifier {
  RegistrationWizardController({this.stepCount = 4});

  final int stepCount;

  int _currentStep = 0;
  int get currentStep => _currentStep;

  bool get isFirstStep => _currentStep == 0;
  bool get isLastStep => _currentStep == stepCount - 1;

  void next() {
    if (isLastStep) return;
    _currentStep++;
    notifyListeners();
  }

  void previous() {
    if (isFirstStep) return;
    _currentStep--;
    notifyListeners();
  }

  void goTo(int step) {
    if (step < 0 || step >= stepCount || step == _currentStep) return;
    _currentStep = step;
    notifyListeners();
  }
}
