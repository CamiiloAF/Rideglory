# Architect → QA (slim) — Fix Issues #17 & #21

> Slim handoff for /custom-iter fix-issues-17-21. Full detail in architect.md (read only if ambiguous).

## What changed

- **Issue #17 (vehicle_form_page.dart):** Tras crear un vehículo nuevo con SOAT adjuntado, la pantalla del form **ya no hace pop directo**; redirige al usuario a `SoatConfirmationPage` con el `vehicleId` recién creado y la imagen capturada. El usuario completa fechas/aseguradora y al confirmar el SOAT queda persistido y se hace pop completo a garage. Si el usuario cancela esa página, el vehículo queda creado sin SOAT (sin pérdida de datos).
- **Issue #21 (registration_form_content.dart + 3 widgets nuevos):** El selector de vehículo del formulario de inscripción ahora reacciona a los estados `initial`/`loading`/`empty`/`data` del `VehicleCubit`. Mientras carga muestra spinner; cuando hay vehículos muestra el selector; cuando no hay vehículos muestra empty + CTA.

Sin cambios de backend, sin cambios de schema, sin nuevos strings ARB.

## Regression test surface

| Área | Test | Cómo verificar |
|------|------|----------------|
| Creación de vehículo con SOAT | E2E manual | Crear vehículo nuevo → adjuntar imagen SOAT → guardar → la app abre confirmación SOAT → completar fechas + aseguradora → confirmar → badge SOAT visible en detalle del vehículo. |
| Creación de vehículo sin SOAT | E2E manual | Crear vehículo nuevo sin adjuntar nada → guardar → la app va directo a garage con SnackBar de éxito (sin regresión). |
| Cancelar confirmación SOAT post-creación | E2E manual | Crear vehículo con SOAT adjuntado → en pantalla de confirmación tocar back → el vehículo existe en garage sin SOAT. Validar AC-4. |
| Edición de vehículo con SOAT existente | E2E manual | Editar nombre/datos de un vehículo que ya tiene SOAT → guardar → el SOAT existente no debe cambiar ni resetearse (la rama "editing" no activa el redirect). |
| Inscripción — evento "todas las marcas" | E2E manual | Abrir inscripción de un evento con `allowedBrands = ['*']` teniendo vehículos → el selector muestra los vehículos (no empty state). AC-5. |
| Inscripción — VehicleCubit cargando | Widget test + E2E | Forzar `VehicleCubit` en `Loading` (mock en widget test) y montar `RegistrationFormContent` → debe aparecer spinner, no empty state. AC-6. |
| Inscripción — usuario sin vehículos | E2E manual | Usuario sin vehículos abre inscripción → empty state con CTA "Crear vehículo" visible. AC-7. |
| Inscripción — marca restringida | E2E manual | Evento con marcas específicas, vehículo con marca no permitida → SnackBar de validación de marca al intentar inscribirse. Sin regresión. |
| Lint | CI | `dart analyze` debe pasar 0 errors/0 warnings vs baseline. AC-8. |
| Widget tests existentes | CI | `flutter test` debe seguir verde. Si existen tests del form de vehículo o del registration form, validar que pasan tras el cambio. |

## Per-AC verification matrix

| AC | Issue | Comportamiento esperado | Modo de verificación |
|----|-------|--------------------------|----------------------|
| AC-1 | #17 | Vehículo creado con SOAT → badge distinto de "Sin SOAT" | E2E manual + smoke |
| AC-2 | #17 | Badge muestra estado correcto (Vigente / Por vencer / Vencido) | E2E manual con fechas distintas (hoy+30d vencido, hoy+45d por vencer, hoy+365d vigente) |
| AC-3 | #17 | Crear sin SOAT funciona igual que antes | E2E manual |
| AC-4 | #17 | Falla de upload SOAT → vehículo persiste + SnackBar de error | E2E manual con red apagada en la confirmación |
| AC-5 | #21 | Selector muestra vehículos cuando hay y evento es `'*'` | E2E manual |
| AC-6 | #21 | Spinner visible mientras carga | Widget test (state Loading) + E2E |
| AC-7 | #21 | Empty + CTA cuando realmente no hay vehículos | E2E manual con cuenta limpia |
| AC-8 | both | `dart analyze` 0/0 | CI / local |

## Smoke checklist (pre-PR)

- [ ] Crear vehículo + SOAT en iOS sim → badge OK en garage.
- [ ] Crear vehículo + SOAT en Android emu → badge OK en garage.
- [ ] Crear vehículo sin SOAT → flujo idéntico al anterior.
- [ ] Editar vehículo existente con SOAT → SOAT intacto.
- [ ] Cancelar la confirmación SOAT post-creación → vehículo presente, sin SOAT.
- [ ] Abrir inscripción con VehicleCubit en loading → spinner.
- [ ] Abrir inscripción con vehículos cargados → selector funcional.
- [ ] Cuenta sin vehículos → empty + CTA.
- [ ] Evento con marca restringida + vehículo invalid → mensaje de validación intacto.
- [ ] `dart analyze` → 0 issues.
- [ ] `flutter test` → verde.

## Edge cases a verificar

- Usuario adjunta SOAT, lo limpia con la X, guarda → flujo igual a "sin SOAT" (soatLocalPath es null).
- Usuario adjunta SOAT, vuelve atrás del form sin guardar → sin cambios persistidos en backend.
- Vehículo creado con SOAT, usuario cancela confirmación, vuelve a entrar al vehículo → puede agregar SOAT desde el detalle (flujo iter-2 intacto).
- Inscripción con `VehicleCubit` que pasa de `loading` a `data` mientras la pantalla está montada → re-render fluido (no flicker raro del form de inscripción).
- `VehicleCubit` en estado `Error` → comportamiento elegido: mostrar empty + CTA (degradación graceful). Si QA observa mensaje de error confuso para el usuario, abrir bug aparte.

## What QA does NOT need to verify

- Lógica interna de `SoatConfirmationPage` / `SoatFormCubit` (validada en iter-2, sin cambios).
- Backend (`POST /api/vehicles/:vehicleId/soat`) — sin cambios.
- DTOs/serialización — sin cambios.
- Diseño visual del spinner (estándar `CircularProgressIndicator`).
