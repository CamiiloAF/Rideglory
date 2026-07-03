# SUMMARY — waiver-inscripcion-registro

**Fecha (re-revisión):** 2026-07-02T04:36:29Z
**Veredicto Tech Lead:** ready (working tree sucio a propósito; el humano commitea)

## Objetivo

Agregar el quinto paso del wizard de inscripción a eventos (`RegistrationWaiverStep`): aceptación
del waiver de riesgo con CTA "Entiendo, inscribirme" y botón "Cancelar" (retrocede al paso
anterior), más 2 switches de privacidad (`shareMedicalInfo`, `allowOrganizerContact`) en el paso
médico, y la guardia de edad mínima (rider <18 años → bloqueo local sin llamar al backend, más
manejo del error `UNDERAGE_RIDER` real del servidor).

## Qué cambió por área

- **Frontend (presentation):**
  - `registration_waiver_step.dart` (NEW): paso 5 del wizard — header, nombre del organizador
    (si existe), texto legal en `ConstrainedBox(maxHeight: 280) + SingleChildScrollView`, bloque
    de error diferenciado (edad mínima / falta fecha de nacimiento / genérico), CTA `AppButton`
    primario + botón "Cancelar" `AppButton` outlined pill (mismo componente visual que "Atrás" en
    los otros 4 pasos, ver hallazgo #2 de la ronda anterior — ya corregido).
  - `registration_medical_step.dart`: agrega sección "Privacidad" con 2 `AppSwitchTile`
    (`shareMedicalInfo`, `allowOrganizerContact`), default `false` en creación, precargados desde
    la inscripción existente en edición.
  - `registration_form_content.dart`: inyecta el nuevo paso, oculta la `RegistrationWizardNavigationBar`
    en el último paso (el waiver trae sus propios botones internos, evita doble set de CTAs) y
    agrega `stepNameWaiver` al mapeo de analítica.
  - `app_switch_tile.dart`: fix de contraste WCAG 2.1 AA del subtítulo (`textOnDarkTertiary` →
    `textOnDarkSecondary`, ≈4.02:1 → ≈7.65:1).
- **Cubit (presentation/cubit):** `registration_form_cubit.dart` — guardia de edad mínima local
  (rider <18 años nunca llega a llamar al use case), detección del error `UNDERAGE_RIDER` del
  backend, construcción real de `riskAcceptedAt`/`riskAcceptanceVersion` en el payload.
- **Constants:** `registration_form_fields.dart` — paso 5 (waiver) sin campos `FormBuilder`
  (`<String>[]`), `stepCount` pasa a 5.
- **Analytics:** `analytics_params.dart` — nueva constante `stepNameWaiver`.
- **Localización:** 14 claves nuevas en `app_es.arb` (`registration_waiverCtaButton = "Entiendo,
  inscribirme"`, `registration_waiverCancelButton = "Cancelar"`, textos legales, mensajes de edad
  mínima, secciones de privacidad), regeneradas en `app_localizations.dart`/`_es.dart`.

## Archivos

- `lib/core/services/analytics/analytics_params.dart`
- `lib/features/event_registration/constants/registration_form_fields.dart`
- `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart`
- `lib/features/event_registration/presentation/registration_form_content.dart`
- `lib/features/event_registration/presentation/wizard/steps/registration_medical_step.dart`
- `lib/features/event_registration/presentation/wizard/steps/registration_waiver_step.dart` (NEW)
- `lib/l10n/app_es.arb`, `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_es.dart`
- `lib/shared/widgets/form/app_switch_tile.dart`
- `test/features/event_registration/constants/registration_form_fields_test.dart`
- `test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart`
- `test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart`
- `test/features/event_registration/presentation/cubit/registration_form_cubit_age_validation_test.dart` (NEW)
- `test/features/event_registration/presentation/wizard/steps/registration_waiver_step_test.dart` (NEW)
- `test/features/event_registration/presentation/wizard/steps/registration_medical_step_test.dart` (NEW)

## Pruebas

- `dart analyze` (repo completo, re-ejecutado por Tech Lead en esta ronda): **No issues found!**
- `flutter test test/features/event_registration/` (re-ejecutado por Tech Lead en esta ronda):
  **All tests passed!** (incluye los 3 archivos nuevos y los 3 modificados).
- `registration_waiver_step_test.dart` confirma el fix del botón "Cancelar":
  `expect(find.byType(AppButton), findsNWidgets(2)); expect(find.byType(AppTextButton),
  findsNothing);` — ya no hay `AppTextButton` en el paso.
- Cada AC del PRD tiene un test que fallaría sin el cambio (AC#1, #3, #4/#6 copy CTA, #9/#10
  payload, #12 analítica) — ver detalle en `handoffs/tech_lead.md` §Tests.
- No se re-corrió `flutter test` (suite completa del repo) en esta ronda; QA reportó 944/944 en la
  ronda anterior y los únicos archivos tocados desde entonces son el ARB (regenerado) y
  `registration_waiver_step.dart`/su test, ambos re-verificados arriba.

## Riesgos / watchlist

- `error.message.contains('UNDERAGE_RIDER')` sigue siendo una detección frágil basada en texto de
  error del backend (riesgo aceptado por el Architect desde el inicio de la fase, sin usuarios
  reales todavía). Si el backend cambia el formato del mensaje, el guard silenciosamente deja de
  activarse — vale la pena migrar a un código de error tipado en una fase futura.
- `design.md` (línea ~154, tabla "Copy") todavía lista "Cancelar" como `AppTextButton` (Botón
  secundario), una frase que quedó desactualizada por el "Fix pass" documentado más arriba en el
  mismo archivo. No afecta al código (que es correcto y está verificado) ni bloquea esta ronda,
  pero conviene que quien retome el plan `legal-privacidad-edad` corrija esa línea para que
  `design.md` no contradiga su propia sección de fix.
- Pendiente de decisión de producto (no bloqueante, escalado por Design/UX Review en la ronda
  anterior): si el copy final del botón de retroceso del waiver debería decir "Cancelar" (como
  exige el PRD literal) o "Atrás" (por consistencia total con el resto del wizard). Cualquiera de
  las dos opciones es un cambio de una clave ARB sin impacto de layout.
- Verificaciones manuales en dispositivo/simulador siguen pendientes (ver `REVIEW_CHECKLIST.md`
  §3) — ninguna bloquea el veredicto técnico.

## Mensaje de commit sugerido

```
feat(event_registration): agregar paso de waiver de riesgo e inscripción legal (AC#1-#12)

- Nuevo quinto paso del wizard (RegistrationWaiverStep): aceptación de términos legales,
  guardia de edad mínima local + manejo de UNDERAGE_RIDER del backend.
- Switches de privacidad (compartir info médica / permitir contacto del organizador) en el
  paso médico, precargados en edición.
- Fix de contraste WCAG AA en AppSwitchTile (subtítulo).
```
