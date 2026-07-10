// Widget tests for LoginSocialButton.
//
// Covers the tap callback, disabled state (no-op tap), and the
// loading-vs-icon rendering. Pure StatelessWidget — the callback is a mock
// VoidCallback, no real Google/Apple sign-in service is invoked.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_social_button.dart';

class MockCallback extends Mock {
  void call();
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  late MockCallback onPressed;

  setUp(() {
    onPressed = MockCallback();
  });

  testWidgets('TC-social-1: tapping the button invokes onPressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        LoginSocialButton(
          label: 'Continuar con Google',
          icon: Icons.g_mobiledata_rounded,
          backgroundColor: Colors.white,
          textColor: Colors.black,
          isLoading: false,
          isDisabled: false,
          onPressed: onPressed.call,
        ),
      ),
    );

    await tester.tap(find.text('Continuar con Google'));
    await tester.pump();

    verify(() => onPressed()).called(1);
  });

  testWidgets('TC-social-2: disabled button does not invoke onPressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        LoginSocialButton(
          label: 'Continuar con Google',
          icon: Icons.g_mobiledata_rounded,
          backgroundColor: Colors.white,
          textColor: Colors.black,
          isLoading: false,
          isDisabled: true,
          onPressed: onPressed.call,
        ),
      ),
    );

    await tester.tap(find.text('Continuar con Google'), warnIfMissed: false);
    await tester.pump();

    verifyNever(() => onPressed());
  });

  testWidgets(
    'TC-social-3: isLoading shows a progress indicator instead of the icon',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          LoginSocialButton(
            label: 'Continuar con Google',
            icon: Icons.g_mobiledata_rounded,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            isLoading: true,
            isDisabled: true,
            onPressed: onPressed.call,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.g_mobiledata_rounded), findsNothing);
    },
  );

  testWidgets('TC-social-4: not loading shows the icon, not the spinner', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        LoginSocialButton(
          label: 'Continuar con Apple',
          icon: Icons.apple,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          isLoading: false,
          isDisabled: false,
          onPressed: onPressed.call,
        ),
      ),
    );

    expect(find.byIcon(Icons.apple), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
