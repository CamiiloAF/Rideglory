# Tech Lead handoff — waiver-inscripcion-registro (re-revisión)

**Date:** 2026-07-02T04:36:29Z
**Status:** ready (0 blockers)

---

## Veredicto

**ready.** Esta es una re-revisión tras correcciones. Los 2 blockers reportados en la ronda
anterior (copy del CTA del waiver y componente visual del botón "Cancelar") están ambos
corregidos y verificados directamente contra el código real y sus tests:

1. `lib/l10n/app_es.arb` — `registration_waiverCtaButton` cambió de "Confirmar inscripción" a
   **"Entiendo, inscribirme"**, cumpliendo literalmente el AC#4/#6 del PRD
   (`PRD_NORMALIZED.md`).
2. `lib/features/event_registration/presentation/wizard/steps/registration_waiver_step.dart` —
   el botón "Cancelar" ya no usa `AppTextButton`; usa `AppButton(style: AppButtonStyle.outlined,
   shape: AppButtonShape.pill)`, el mismo componente visual que "Atrás" usa en los otros 4 pasos
   del wizard (`registration_wizard_navigation_bar.dart:51-55`). El test
   `registration_waiver_step_test.dart` fue actualizado para verificarlo explícitamente:
   `expect(find.byType(AppButton), findsNWidgets(2)); expect(find.byType(AppTextButton),
   findsNothing);`.

`dart analyze` (repo completo) y `flutter test test/features/event_registration/` fueron
re-ejecutados por Tech Lead en esta ronda: ambos limpios/en verde.

No se identificaron blockers nuevos ni regresiones introducidas por el fix pass.

## Hallazgos

Ninguno bloqueante. Un hallazgo menor de higiene documental (no de código):

### 1. [No bloqueante — documentación] `design.md` tiene una línea desactualizada

`docs/exec-runs/waiver-inscripcion-registro/handoffs/design.md` (tabla "Copy", línea ~154) sigue
listando "Cancelar" como `AppTextButton` (Botón secundario), lo cual contradice su propia sección
"Fix pass — UX Review bloqueantes" (líneas ~14-23 del mismo archivo), que documenta correctamente
el cambio a `AppButton` outlined pill. El código y los tests reflejan correctamente el Fix pass
(no la tabla desactualizada). No requiere acción sobre el código; se recomienda que quien retome
el plan `legal-privacidad-edad` corrija esa línea para eliminar la contradicción interna del
handoff.

## Seguridad

Sin hallazgos. No hay secretos, SQL, XSS ni PII en logs — el cambio es exclusivamente Flutter
UI/estado local. `riskAcceptedAt`/`riskAcceptanceVersion` no son datos sensibles. El mecanismo de
detección `error.message.contains('UNDERAGE_RIDER')` sigue siendo frágil (riesgo ya documentado y
aceptado por el Architect, sin usuarios reales) pero no es un riesgo de seguridad — es un riesgo
de UX si el backend cambia el formato del mensaje de error (ver `SUMMARY.md` §Riesgos).

## Arquitectura

Conforme a Clean Architecture y a `rideglory-coding-standards.mdc` (sin cambios respecto a la
ronda anterior, re-verificado en esta ronda sobre el diff final):

- Presentation (`RegistrationWaiverStep`) no hace llamadas HTTP directas; delega a
  `onSubmit`/`onBack` (callbacks del padre) — nunca `cubit.saveRegistration()` ni `context.pop()`
  directamente.
- Un widget por archivo respetado: `RegistrationWaiverStep` (público) +
  `_RegistrationWaiverError` (privado) en el mismo archivo, ambos `StatelessWidget`, sin métodos
  `_buildXxx()` que retornan `Widget`.
- Sin `Expanded` dentro del paso (usa `ConstrainedBox(maxHeight: 280) + SingleChildScrollView`),
  evitando el crash documentado como riesgo R3 por el Architect.
- `Cubit<ResultState<T>>` sin flags booleanos de loading/error.
- `AppSwitchTile` usado en los 2 switches nuevos (nunca `Switch`/`SwitchListTile`/
  `FormBuilderSwitch`/`CupertinoSwitch`), con `subtitle` obligatorio en ambos.
- `app_router.dart` no se tocó; navegación a `AppRoutes.editProfile` vía `context.pushNamed` a
  una ruta ya existente y nominada.
- Sin cambios de backend/DB, confirmado por `git diff --stat` (solo `lib/`, `test/`, ARB, y
  `docs/exec-runs/`).

## Tests

- `dart analyze` (repo completo, re-ejecutado por Tech Lead en esta ronda): **No issues found!**
- `flutter test test/features/event_registration/` (re-ejecutado por Tech Lead en esta ronda):
  **All tests passed!** (79 tests en el feature, incluyendo los 3 archivos nuevos y los 3
  modificados de esta fase).
- Confirmado por lectura del test actualizado que el fix del botón "Cancelar" está cubierto:
  `registration_waiver_step_test.dart` verifica `findsNWidgets(2)` para `AppButton` y
  `findsNothing` para `AppTextButton`, y un test dedicado `'Cancel tap invokes onBack'` que
  hace tap sobre `find.byType(AppButton).last`.
- No se re-corrió `flutter test` (suite completa del repo) por Tech Lead en esta ronda; se
  confía en la cifra de QA de la ronda anterior (944/944) dado que los únicos archivos tocados
  desde entonces (ARB + `registration_waiver_step.dart`/su test) ya fueron re-verificados
  directamente arriba.

## Pruebas manuales

Sin cambios respecto a la ronda anterior — siguen pendientes, ninguna bloquea el veredicto
técnico (ver `REVIEW_CHECKLIST.md` §3):
1. Flujo feliz completo (5 pasos → waiver → envío con switches reales).
2. Rider <18 años → título "No cumples la edad mínima" sin botón "Ir a mi perfil".
3. Edición de inscripción existente → switches precargados correctamente.
4. Nav bar inferior no duplicada/superpuesta en el paso waiver.
5. `UNDERAGE_RIDER` real del backend (422) → mensaje de edad mínima (no el texto crudo).
