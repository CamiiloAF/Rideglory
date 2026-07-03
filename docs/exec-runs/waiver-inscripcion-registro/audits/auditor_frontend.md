# Auditoría frontend — waiver-inscripcion-registro

**Fecha:** 2026-07-02T04:13:14Z
**Resultado:** APROBADO con findings (score 88)

## Verificación de AC
- AC1–5, AC9–14: cumplidos (5º paso `<String>[]`, dos AppSwitchTile con subtitle, nav bar oculta con `if (!_wizard.isLastStep)`, callbacks onSubmit/onBack, payload con riskAcceptedAt/version/booleanos, analytics stepNameWaiver, ownerName nullable-safe).
- AC6/AC8: guardia de edad y birthDate faltante en el cubit antes de tocar backend; mensajes por igualdad exacta; botón "Ir a mi perfil" → AppRoutes.editProfile.
- AC7: `isUnderage` es OR con `.contains('UNDERAGE_RIDER')` — corregido tras ronda previa; test dedicado en verde.
- AC15: `dart analyze` limpio (reportado); tests 33/33 en subconjunto tocado, verde.

## Clean Architecture / estándares
- Un widget por archivo (RegistrationWaiverStep + auxiliar privado, ambos StatelessWidget). Sin métodos que retornan widgets. AppButton/AppTextButton/AppSwitchTile usados. Sin Expanded (ConstrainedBox+SingleChildScrollView). Strings en app_es.arb. ResultState sin flags. Sin URLs hardcodeadas.

## Findings
1. `lib/shared/widgets/form/app_switch_tile.dart` (línea 62): cambio `textOnDarkTertiary`→`textOnDarkSecondary` fuera del change map §4. El handoff (punto 4) afirma FALSAMENTE que el working tree ya estaba revertido; el `git diff` contra HEAD muestra que el cambio SIGUE presente. Impacto de regresión = nulo (ningún otro AppSwitchTile usa `subtitle`), y es una mejora de contraste WCAG defendible, pero debe reconciliarse la nota del handoff con la realidad y decidir explícitamente si se conserva.
