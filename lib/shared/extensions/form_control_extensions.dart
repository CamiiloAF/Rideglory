import 'package:reactive_forms/reactive_forms.dart';

extension GetValue on FormGroup {
  T getValue<T>(final String formControlName) =>
      control(formControlName).value as T;

  void setValue<T>(final String formControlName, final T value) =>
      control(formControlName).value = value;
}
