# REVIEW CHECKLIST — observability-sentry Fase 4

**Fecha (UTC):** 2026-06-12T17:15:56Z
**Estado:** READY para commit

Sigue estos pasos antes de `git add / commit`.

---

## 1. Verificación rápida de código

- [ ] `dart analyze lib/` — confirmar "No issues found".
- [ ] `flutter test test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart test/shared/widgets/form/app_button_test.dart` — 33 tests verde.
- [ ] Los 2 fallos pre-existentes (`TC-stp-8`, `TC-stp-11` en `event_form_stepper_cubit_test.dart`) siguen siendo los únicos fallos en la suite completa.

---

## 2. Revisión del diff

- [ ] `git diff --stat HEAD` muestra 14 archivos (los mismos que en el SUMMARY), más los 2 untracked nuevos (`sentry_config.dart`, `app_button_test.dart`).
- [ ] Sin archivos fuera del scope comprometidos accidentalmente (p.ej. `api_base_url_resolver.dart` con `shouldUseLocalApi=true` — **NO revertir**).
- [ ] Confirmar que `sentry.properties` está en `.gitignore` y NO aparece en `git status` como untracked.

---

## 3. Pruebas manuales

- [ ] **Wizard de creación**: avanzar y retroceder pasos → Firebase DebugView o consola muestra `events_step_advanced` / `events_step_back` con `step_index` y `step_name` correctos.
- [ ] **Publicar evento**: tap en "Publicar" → `events_publish_attempted` antes del spinner.
- [ ] **Abandono wizard**: abrir wizard, cerrar sin publicar → `events_create_abandoned` con `abandoned_at_step` correcto.
  - Si el evento NO se emite: verificar que el `BlocProvider` del wizard dispone el cubit al hacer pop.
- [ ] **Home CTA vacío**: tap en "Ver eventos" (home sin eventos) → `home_empty_events_cta` en consola.
- [ ] **Opt-out intacto**: Perfil → toggle de analytics → `AppSwitch` pill naranja, knob oscuro, sin cambios visuales.
- [ ] *(Opcional)* **SentryNavigatorObserver**: correr con `--dart-define=SENTRY_DEV_VERIFY=true` y DSN real → breadcrumbs de navegación visibles en Sentry.

---

## 4. Commit

Una vez todo lo anterior está verde, stagear y commitear con el mensaje sugerido en SUMMARY.md.

```bash
git add \
  lib/core/services/analytics/analytics_events.dart \
  lib/core/services/analytics/analytics_params.dart \
  lib/features/events/presentation/form/cubit/event_form_cubit.dart \
  lib/features/event_registration/presentation/cubit/registration_form_cubit.dart \
  lib/shared/widgets/form/app_button.dart \
  lib/shared/widgets/form/app_text_button.dart \
  lib/features/home/presentation/widgets/home_empty_events_card.dart \
  lib/shared/router/app_router.dart \
  lib/core/config/sentry_config.dart \
  lib/main.dart \
  docs/features/analytics.md \
  .gitignore \
  pubspec.yaml \
  test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart \
  test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart \
  test/shared/widgets/form/app_button_test.dart \
  docs/exec-runs/observability-sentry-fase4/
```

No incluir archivos de otras fases en el mismo commit.
