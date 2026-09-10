import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/design_system/theme/app_theme.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/widgets/states/empty_state_view.dart';
import 'package:rideglory/shared/widgets/states/error_state_view.dart';
import 'package:rideglory/shared/widgets/states/result_state_builder.dart';
import 'package:rideglory/shared/widgets/states/skeleton_list.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('ResultStateBuilder', () {
    testWidgets('shows a skeleton list while loading', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ResultStateBuilder<String>(
            state: const ResultState.loading(),
            onData: (context, data) => Text(data),
            onRetry: () {},
          ),
        ),
      );

      expect(find.byType(SkeletonList), findsOneWidget);
    });

    testWidgets('shows the empty state view when empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ResultStateBuilder<String>(
            state: const ResultState.empty(),
            onData: (context, data) => Text(data),
            onRetry: () {},
          ),
        ),
      );

      expect(find.byType(EmptyStateView), findsOneWidget);
    });

    testWidgets('shows the data content when data arrives', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ResultStateBuilder<String>(
            state: const ResultState.data(data: 'hola'),
            onData: (context, data) => Text(data),
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('hola'), findsOneWidget);
    });

    testWidgets('shows an accionable error state with a retry button', (
      tester,
    ) async {
      var retried = false;
      await tester.pumpWidget(
        _wrap(
          ResultStateBuilder<String>(
            state: const ResultState.error(
              error: DomainException(message: 'No hay señal'),
            ),
            onData: (context, data) => Text(data),
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('No hay señal'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(retried, isTrue);
    });
  });
}
