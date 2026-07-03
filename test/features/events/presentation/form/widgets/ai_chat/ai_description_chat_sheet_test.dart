// Widget tests for AiChatErrorBanner and AiChatInputRow
// AC13: AiQuotaExceededUserException state → input disabled, no "Reintentar" button
// AC14: 3 recoverable errors show correct l10n message AND "Reintentar" button

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/core/exceptions/ai_domain_exceptions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/widgets/ai_chat/ai_chat_error_banner.dart';
import 'package:rideglory/features/events/presentation/form/widgets/ai_chat/ai_chat_input_row.dart';
import 'package:rideglory/l10n/app_localizations.dart';

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: Scaffold(body: child),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('AC13 — AiQuotaExceededUserException state', () {
    testWidgets('AiChatInputRow is disabled when quota exhausted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(AiChatInputRow(disabled: true, onSend: (_) {})),
      );
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(
        textField.enabled,
        isFalse,
        reason: 'TextField must be disabled when quota is exhausted',
      );
    });

    testWidgets(
      'AiChatErrorBanner for quota_exceeded_user: NO "Reintentar" button',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            AiChatErrorBanner(
              error: const AiQuotaExceededUserException(
                message: 'Límite diario alcanzado.',
              ),
              onRetry: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Reintentar'),
          findsNothing,
          reason:
              'Reintentar button must NOT appear for quota_exceeded_user even when onRetry is provided',
        );
        expect(
          find.textContaining('límite diario'),
          findsOneWidget,
          reason: 'ai_errorQuotaUser message must be shown',
        );
      },
    );
  });

  group('AC14 — recoverable errors show message AND Reintentar button', () {
    testWidgets(
      'AiQuotaExceededProjectException → ai_errorQuotaProject + Reintentar',
      (tester) async {
        bool retryCalled = false;

        await tester.pumpWidget(
          _wrap(
            AiChatErrorBanner(
              error: const AiQuotaExceededProjectException(
                message: 'Servicio temporalmente no disponible.',
              ),
              onRetry: () => retryCalled = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('temporalmente'),
          findsOneWidget,
          reason: 'ai_errorQuotaProject message must be shown',
        );
        expect(
          find.text('Reintentar'),
          findsOneWidget,
          reason:
              'Reintentar must be visible for recoverable quota_project error',
        );

        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();
        expect(
          retryCalled,
          isTrue,
          reason: 'Reintentar tap must invoke onRetry',
        );
      },
    );

    testWidgets(
      'AiSafetyBlockedException → ai_errorSafetyBlocked + Reintentar',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            AiChatErrorBanner(
              error: const AiSafetyBlockedException(
                message: 'Tu mensaje fue bloqueado por filtros de seguridad.',
              ),
              onRetry: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('filtros de seguridad'),
          findsOneWidget,
          reason: 'ai_errorSafetyBlocked message must be shown',
        );
        expect(
          find.text('Reintentar'),
          findsOneWidget,
          reason:
              'Reintentar must be visible for recoverable safety_blocked error',
        );
      },
    );

    testWidgets('AiNetworkErrorException → ai_errorNetwork + Reintentar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AiChatErrorBanner(
            error: const AiNetworkErrorException(
              message: 'No se pudo conectar con el servicio de IA.',
            ),
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No se pudo conectar'),
        findsOneWidget,
        reason: 'ai_errorNetwork message must be shown',
      );
      expect(
        find.text('Reintentar'),
        findsOneWidget,
        reason: 'Reintentar must be visible for recoverable network error',
      );
    });
  });
}
