# Plan Review — OCR Tarjeta de Propiedad Autofill

**Timestamp:** 2026-06-19T19:53:18Z
**Slug:** `ocr-tarjeta-propiedad-autofill`
**Rol:** Plan Reviewer (UX móvil + calidad / Clean Architecture)
**Veredicto:** `ok_con_ajustes`

---

## Evaluación general

El plan es sólido. La propuesta de fases sigue una progresión lógica: limpieza → shared UI → domain+tests → usecase → presentación → QA. Los supuestos del PO están bien documentados y la decisión de no migrar `SoatVehicleOptionsSheet` en v1 es correcta. Los ajustes a continuación son concretos y ninguno requiere replantear la secuencia de fases.

---

## UX por fase

### Fase 1 — Limpieza de código muerto
Sin UI. No hay superficies de usuario afectadas.

**Gate UX:** N/A.

### Fase 2 — Shared document source sheet
El `DocumentSourceSheet` es el único punto de entrada visual al scanner en v1. Riesgos UX identificados:

- **Touch targets.** El sheet necesita mínimo 2 opciones (cámara / galería) con targets de al menos 48 × 48 dp. Dado que la app ya tiene el patrón de bottom sheet (e.g. `SoatAddDocumentSheet`), replicar su estructura es seguro.
- **Estado de carga durante el picker.** `image_picker` puede tardar en iOS. El cubit (`VehicleScanCubit`) debe emitir `ResultState.loading()` tan pronto el usuario elige fuente, antes de recibir la imagen. El sheet se cierra y el banner muestra un indicador de progreso inline.
- **Cancelación.** Si el usuario cancela el picker nativo (toca fuera, botón atrás), el cubit vuelve a `ResultState.initial()` sin mensaje de error. El formulario permanece igual.
- **Contrato de retorno del sheet.** El scan de salida debe ser un sealed type (`DocumentSourceOption { camera | gallery }`), no un `int`. Esto hace el contrato explícito para futuras extensiones (PDF en v2) sin forzar reescritura.

**Gate UX:** El sheet debe cerrarse antes de que el OCR comience (no bloquear el sheet abierto mientras procesa).

### Fase 3 — Domain layer + parser con tests
Sin UI nueva. No hay superficies de usuario en esta fase.

**Gate UX:** N/A. Sin embargo, la definición del umbral `shouldPrefill` aquí condiciona todo el UX de la fase 5. Ver ajuste #3 abajo.

### Fase 4 — Use case de escaneo + telemetría
Sin UI nueva. La telemetría es interna.

**Gate UX:** N/A. Verificar que `propertyScanFailed` incluya el `failureReason` en los params (bajo confianza vs. error de OCR vs. imagen nula) para que el equipo pueda diagnosticar el UX degradado en producción.

### Fase 5 — Presentación: banner activo + prefill del formulario
Esta es la fase con mayor carga UX. Tres flujos distintos a diseñar:

**Flujo happy path:**
1. Rider ve el banner en la parte superior del formulario (descomentado en `VehicleFormBody`).
2. Toca el banner → `DocumentSourceSheet` aparece desde abajo.
3. Elige cámara o galería → sheet se cierra → banner muestra `CircularProgressIndicator` (o shimmer) inline.
4. OCR completa → campos marcados con ícono de "auto-rellenado" (opcional v1) → snackbar de éxito.
5. Rider puede editar cualquier campo prefillado normalmente.

**Flujo de baja confianza (< 2 campos `high`):**
1. Banner muestra indicador → OCR completa pero confianza insuficiente.
2. Snackbar de error con mensaje claro: ej. "No pudimos leer la tarjeta. Intenta con mejor iluminación." → formulario sin cambios.
3. Banner vuelve al estado idle para reintentar.

**Flujo de error técnico (imagen nula, falla OCR):**
1. Snackbar con mensaje genérico de error + botón de reintento inline en el banner.

**Reglas críticas de UX:**
- El banner en estado idle, loading, error son 3 estados distintos del mismo widget (`VehicleScanBanner`). Si tiene `StatefulWidget`, la clase `State<VehicleScanBanner>` puede coexistir. Si consume el cubit, debe ser un `BlocBuilder` en el archivo del banner (archivo único = un widget).
- El prefill ocurre desde el listener del cubit en `VehicleFormBody` (o mejor, en `VehicleFormView`), no desde dentro del banner. El banner solo dispara el scan y refleja el estado.
- El campo `year` en el formulario puede ser un `AppDatePicker` (selector de año) o un `AppTextField` con validador numérico. Verificar cómo está en `VehicleFormIdSection` o `VehicleFormSpecsSection` antes de implementar el prefill.
- La posición del banner importa en 375px: encima de `VehicleFormCoverSection` (como está comentado) es correcto; el cover photo contextualiza visualmente el vehículo y el banner de scan invita a autocompletar antes de escribir nada a mano.

**Gate UX:** Los 3 estados del banner (idle / loading / error-reintento) deben estar implementados antes de aprobar la fase. El formulario debe ser 100% editable después del prefill.

### Fase 6 — QA, strings es-CO y documentación
Sin UI nueva. Verificación de lo implementado.

**Gate UX:** Revisar que todos los textos en el flujo de scan (título del banner, subtítulo, instrucción "cara frontal", toast éxito, toast error, etiqueta de campo autocompletado) estén en `app_es.arb`. Ningún string hardcodeado en ningún widget de este feature.

---

## Gates de calidad por fase

### Fase 1
- [ ] `dart analyze` pasa limpio tras borrar los 8+ huérfanos.
- [ ] Ningún archivo activo importa los archivos eliminados (verificar con `grep -r 'vehicle_form.dart\|vehicle_form_scan_banner.dart' lib/ --include="*.dart"`).
- [ ] `flutter test` pasa sin cambios (no hay tests de los huérfanos actualmente).
- [ ] El huérfano `vehicle_form_scan_banner.dart` (con `Colors.white`) se borra; el banner activo correcto es `form/widgets/vehicle_scan_banner.dart` (ya usa `AppColors.textOnDarkPrimary`).

### Fase 2
- [ ] `DocumentSourceSheet` es un `StatelessWidget` o `StatefulWidget` en un único archivo. Si necesita lógica de callback, recibe los callbacks como parámetros.
- [ ] El contrato de retorno es un sealed type o enum documentado, no un `int`.
- [ ] No hay imports de `SoatAddDocumentSheet` ni de lógica SOAT en el sheet genérico.
- [ ] El sheet usa componentes del design system (iconos, colores, bordes) que matchean el patrón oscuro de la app.
- [ ] `dart analyze` pasa sin warnings en el archivo nuevo.

### Fase 3
- [ ] `PropertyCardExtraction` vive en `lib/features/vehicles/domain/models/` — dominio puro, sin imports de Flutter.
- [ ] `PropertyCardParser` vive en `lib/features/vehicles/data/parser/` — stateless, `@injectable`.
- [ ] `ParsePropertyCardTextUseCase` vive en `lib/features/vehicles/domain/usecases/`.
- [ ] ≥6 fixtures de tests: mínimo 2 motos (RUNT formato moto), 2 carros, 1 caso de baja confianza, 1 caso con VIN ausente.
- [ ] Los patrones RUNT asumidos (etiquetas exactas) están documentados en comentarios del parser.
- [ ] `dart analyze` pasa. `flutter test test/features/vehicles/` pasa.

### Fase 4
- [ ] `ScanPropertyCardUseCase` vive en `lib/features/vehicles/domain/usecases/` — no llama HTTP, no importa `data/`.
- [ ] Los 3 eventos GA4 (`propertyScanAttempted`, `propertyScanSuccess`, `propertyScanFailed`) están en `lib/core/services/analytics/analytics_events.dart`.
- [ ] `propertyScanFailed` incluye `failureReason` en los params GA4 existentes.
- [ ] El usecase es testeable de forma unitaria con mocks de `OcrService` y del parser.
- [ ] `dart analyze` pasa.

### Fase 5
- [ ] `VehicleScanCubit` es `@injectable` (NO `@singleton`) — va como `BlocProvider` local en `VehicleFormPage`, junto a `VehicleFormCubit` y `FormImageCubit`.
- [ ] `VehicleFormCubit.prefillFromScan()` usa `formKey.currentState?.fields[key]?.didChange(value)` — no reconstruye el form, no emite un estado nuevo solo por el prefill.
- [ ] El prefill se dispara desde un `BlocListener` en `VehicleFormBody` (o `VehicleFormView`) que escucha `VehicleScanCubit` — no desde dentro de `VehicleScanBanner`.
- [ ] `VehicleScanBanner` maneja los 3 estados (idle / loading / error) vía `BlocBuilder<VehicleScanCubit, ResultState<PropertyCardExtraction>>` — sin métodos `Widget _buildXxx()`.
- [ ] Un único widget por archivo: `vehicle_scan_banner.dart` tiene solo `VehicleScanBanner`. Si hay subestados visuales complejos, extraer a archivos separados.
- [ ] El banner está descomentado en `VehicleFormBody` (líneas 35-36 actuales) con el `SizedBox(height: 16)` correspondiente.
- [ ] Texto oscuro sobre acento: el ícono del banner usa `AppColors.textOnDarkPrimary` (ya correcto en el banner activo; solo verificar que no se toque al reconectar).
- [ ] `dart analyze` pasa.

### Fase 6
- [ ] `flutter test` pasa con todos los fixtures del parser más cualquier widget test que aplique.
- [ ] `dart analyze` pasa sin warnings en el código nuevo ni en el código limpiado.
- [ ] Todos los strings del flow de scan en `app_es.arb`: banner título, banner subtítulo, instrucción de cara frontal, snackbar éxito, snackbar error bajo confianza, snackbar error técnico.
- [ ] Permisos de cámara y galería verificados en `AndroidManifest.xml` e `Info.plist` (confirmar que no se necesita agregar nada para `camera` explícito si solo SOAT lo declaró).
- [ ] No hay regresión en el feature SOAT: el flow de carga de SOAT sigue funcionando end-to-end.
- [ ] `docs/features/vehicles.md` actualizado si existe (política de actualizar docs de feature al cambiar comportamiento).

---

## Riesgos de scope

### Riesgo 1 — `shouldPrefill` insuficiente para tarjetas físicas reales (ALTO)
El umbral heredado de SOAT (≥2 campos `high`) puede ser demasiado conservador para el layout RUNT de tarjetas de propiedad. Las tarjetas de propiedad colombianas tienen tipografía más pequeña y campos más compactos que un SOAT; la confianza de ML Kit puede ser sistemáticamente más baja. Si el umbral no se calibra con datos reales, el rider siempre verá el snackbar de error y la feature es inútil. **Mitigación propuesta:** En la fase 3, documentar el umbral como constante nombrada (`kPropertyCardMinHighFields = 2`) con un comentario explícito que indica que debe ajustarse tras pruebas con tarjetas reales. No hardcodear el `2` en la lógica.

### Riesgo 2 — `formKey.currentState` nulo en el momento del prefill (MEDIO)
Si el `BlocListener` que dispara el prefill se monta después de que el form ya emitió el estado de `data`, el listener puede perderse la emisión. Mitigación: usar `listenWhen` para reaccionar solo al cambio `loading → data`, y asegurar que el `BlocProvider<VehicleScanCubit>` se monte antes del `FormBuilder` en el árbol de `VehicleFormPage`.

### Riesgo 3 — Scope creep en `DocumentSourceSheet` (BAJO)
La fase 2 podría inflarse si el implementador intenta hacer el sheet extensible a PDF o a la opción Manual. El supuesto del PO es explícito: cámara + galería solamente. Cualquier extensión futura es v2. El Architect/implementador debe ceñirse a esto para no bloquear las fases 3-5.

### Riesgo 4 — Campo `year` en el formulario no es un campo de texto plano (BAJO)
El prefill de `VehicleFormCubit.prefillFromScan()` para el año depende de cómo esté implementado el campo en `VehicleFormIdSection` o `VehicleFormSpecsSection`. Si es un `AppDatePicker`, el `didChange()` requiere un `DateTime`, no un `String`. El implementador de la fase 5 debe verificar el tipo antes de escribir el prefill.

### Riesgo 5 — Dos banners con nombres similares causan confusión en fase 5 (BAJO-MEDIO)
Hasta que se ejecute la fase 1, coexisten `form/widgets/vehicle_scan_banner.dart` (`VehicleScanBanner`) y `widgets/vehicle_form_scan_banner.dart` (`VehicleFormScanBanner`). Si la fase 1 no se ejecuta primero, el implementador de la fase 5 puede conectar el banner equivocado. La secuencia de fases ya previene esto, pero el gate de la fase 1 debe verificar explícitamente que `VehicleFormScanBanner` ya no existe antes de avanzar.

---

## Ajustes al plan

### Ajuste obligatorio 1 — Contrato de retorno de `DocumentSourceSheet` (Fase 2)
El plan propone devolver `int` (tomado por analogía de `SoatAddDocumentSheet`). El plan resultante de la fase 2 debe especificar un sealed type o enum explícito:

```dart
enum DocumentSourceOption { camera, gallery }
```

Esto previene bugs por `int` mágico y permite que v2 extienda el enum sin romper el contrato actual. El implementador de la fase 2 debe recibir esta especificación.

### Ajuste obligatorio 2 — `VehicleScanBanner` debe conectarse al cubit via `BlocBuilder`, no como widget puramente visual (Fase 5)
El banner actual (`form/widgets/vehicle_scan_banner.dart`) es un `StatelessWidget` con `onTap: () { // TODO }`. En la fase 5 deberá convertirse en un `BlocBuilder<VehicleScanCubit, ResultState<PropertyCardExtraction>>` para manejar los 3 estados (idle / loading / error). Esto no viola la regla de un widget por archivo, pero el implementador debe saber que el archivo existente se edita, no se reemplaza. Documentarlo en la especificación de la fase 5.

### Ajuste obligatorio 3 — Umbral `shouldPrefill` como constante nombrada (Fase 3)
El valor `2` del umbral de confianza no debe estar inlined en la lógica de `PropertyCardExtraction.shouldPrefill`. Debe ser:

```dart
/// Ajustar tras pruebas con tarjetas de propiedad reales (layout RUNT colombiano).
/// Heredado de [SoatExtraction]; puede requerir reducción a 1 si la confianza ML Kit
/// es sistemáticamente más baja en tarjetas de propiedad.
static const int kMinHighConfidenceFields = 2;
```

Añadir este ajuste a la especificación de la fase 3.

### Ajuste recomendado 4 — Estado del banner al reintentar (Fase 5)
El plan no especifica qué pasa cuando el rider quiere reintentar después de un error. El banner debe volver a estado `idle` (con el GestureDetector activo) al recibir `ResultState.error(...)`, no quedar bloqueado. Especificarlo en los criterios de aceptación de la fase 5.

### Ajuste recomendado 5 — Verificar tipo del campo `year` antes de implementar el prefill (Fase 5)
Antes de escribir `VehicleFormCubit.prefillFromScan()`, el implementador debe leer `vehicle_form_specs_section.dart` y `vehicle_form_id_section.dart` para confirmar el tipo de campo de `year` (¿`String`? ¿`DateTime`? ¿`int`?). Si es un `AppDatePicker`, el prefill pasa un `DateTime(int.parse(year), 1, 1)`. Documentar el hallazgo en el handoff de arquitectura de la fase 5 antes de implementar.

### Ajuste menor 6 — Instrucción de cara frontal (Fase 5 / 6)
El plan menciona que falta el string de "instrucción cara frontal" en l10n. Este string debe mostrarse en el `DocumentSourceSheet` o como overlay antes de abrir la cámara nativa, no solo en el banner. La especificación de la fase 5 debe incluir dónde aparece esta instrucción (recomendación: como subtítulo dentro del `DocumentSourceSheet`, antes de que el usuario elija cámara/galería).

---

## Resumen de veredicto

El plan está bien estructurado, los supuestos son explícitos y la secuencia de fases es correcta. Los 3 ajustes obligatorios (contrato del sheet, BlocBuilder en el banner, umbral como constante) son cambios de especificación menores que no alteran la arquitectura ni la secuencia. El plan puede avanzar a ejecución con estos ajustes incorporados en las especificaciones de las fases 2, 3 y 5.
