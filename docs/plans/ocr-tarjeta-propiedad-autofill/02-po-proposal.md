# PO Proposal — OCR Tarjeta de Propiedad Autofill

**Timestamp:** 2026-06-19T19:51:17Z
**Slug:** `ocr-tarjeta-propiedad-autofill`

---

## Fases propuestas

| # | Título | Objetivo de valor |
|---|--------|------------------|
| 1 | Limpieza de código muerto | El repo queda sin archivos huérfanos ni el banner con bug de color; `dart analyze` pasa limpio, desbloqueando las fases siguientes sin ruido. |
| 2 | Shared document source sheet | El formulario de vehículo puede mostrar una bottom sheet genérica (cámara / galería) que sirve como punto de entrada al scanner, sin acoplar la lógica a SOAT. |
| 3 | Domain layer + parser con tests | El parser de tarjeta de propiedad colombiana extrae marca, modelo, año, placa y VIN desde texto OCR; cobertura de ≥6 fixtures garantiza que la extracción es confiable antes de exponer la UI. |
| 4 | Use case de escaneo + telemetría | El sistema puede orquestar OCR on-device → parse → eventos GA4 como una unidad cohesiva y auditada; listo para conectarse a la UI. |
| 5 | Presentación: banner activo + prefill del formulario | El rider puede fotografiar su tarjeta de propiedad desde el formulario de vehículo y ver los campos completados automáticamente sin tocar un teclado. |
| 6 | QA, strings es-CO y documentación | Todos los textos visibles están en l10n, los permisos están verificados en ambas plataformas, `flutter test` y `dart analyze` pasan; el feature queda documentado y listo para PR. |

---

## Supuestos

1. **No existen fixtures reales de tarjetas de propiedad en el repo.** Los tests del parser usarán texto sintético que imita el layout RUNT (etiquetas: "MARCA", "LINEA/MODELO", "MODELO/AÑO", "PLACA", "VIN/SERIE"). Es aceptable como punto de partida; los patrones asumidos quedan documentados en comentarios del parser.
2. **RTM (Tecnomecánica) no migra en v1.** El scan de `TecnomecanicaEntryFlow` navega directo sin sheet de fuente de documento; la migración de RTM a `DocumentSourceSheet` no está en scope de este plan.
3. **`SoatVehicleOptionsSheet` no se toca.** Solo se crea `DocumentSourceSheet` como widget nuevo (cámara + galería, sin PDF ni opción Manual). SOAT mantiene su `SoatAddDocumentSheet` y `SoatVehicleOptionsSheet` actuales para no introducir riesgo regresivo.
4. **`VehicleScanCubit` es cubit local al formulario.** Va como `BlocProvider` en `VehicleFormPage`; no necesita persistir fuera de la sesión del formulario.
5. **El prefill no requiere confirmación en modo edición (v1).** Si el usuario tenía datos manuales, el sistema los sobreescribe con los campos de confianza `high`/`medium` y muestra un snackbar posterior. No se implementa dialog de confirmación en esta versión.
6. **Permisos de cámara y galería ya están declarados.** El feature SOAT los declara en `AndroidManifest.xml` e `Info.plist`; se verifica en la fase 6 pero no se espera trabajo nuevo.
7. **No hay cambios de backend.** Las 6 fases son Flutter-only; el guardado del vehículo usa los endpoints existentes sin modificación.
8. **No se necesitan dependencias nuevas.** `google_mlkit_text_recognition`, `image_picker`, `injectable`, `freezed`, `flutter_form_builder` y `firebase_analytics` ya están en `pubspec.yaml`.

---

## Riesgos

1. **Calidad del OCR sobre tarjetas físicas reales.** Los fixtures sintéticos del parser pueden no capturar variaciones tipográficas, deterioro, iluminación pobre o diferencias entre versiones del formato RUNT. Si el umbral `shouldPrefill` (≥2 campos `high`) es muy estricto, la mayoría de scans reales fallarán silenciosamente. Mitigación: documentar patrones RUNT asumidos en el parser para revisión futura con datos reales.
2. **Regresión en el feature SOAT durante la limpieza (Fase 1).** Al borrar archivos huérfanos bajo `presentation/widgets/`, un import no detectado por el análisis estático podría romper SOAT en runtime. Mitigación: confirmar con `dart analyze` + `flutter test` que ningún archivo activo importa los huérfanos antes de borrar.
3. **`formKey.currentState` nulo en el momento del prefill.** Si `VehicleFormCubit.prefillFromScan()` se llama antes de que `FormBuilder` haya montado sus campos, `fields[key]` será nulo y el prefill falla silenciosamente. Mitigación: guardar el resultado del scan en el cubit y disparar el prefill desde un listener en el widget una vez que el form esté montado.
4. **Confianza del campo `shouldPrefill` insuficiente.** La heurística `≥2 high` (tomada de SOAT) puede ser demasiado conservadora para tarjetas de propiedad cuyo layout RUNT difiere del SOAT. Si el umbral es incorrecto, el UX degrada: el rider toma la foto pero no pasa nada. Riesgo moderado hasta tener datos reales.
5. **Complejidad oculta en `DocumentSourceSheet` parametrizable.** Si en iteraciones futuras se quiere añadir PDF u opción Manual al sheet, el contrato de retorno actual (enum simple) puede no ser suficiente. La fase 2 debe diseñar el sheet con extensibilidad mínima para no tener que reescribirlo en v2.

---

## Criterios de éxito globales

- [ ] El rider puede abrir el formulario de vehículo, tocar el banner de scan, tomar una foto de la tarjeta de propiedad y ver los campos marca, modelo, año, placa y VIN completados automáticamente.
- [ ] El formulario permanece editable después del prefill (el rider puede corregir cualquier campo).
- [ ] Si la confianza del scan es insuficiente (menos de 2 campos `high`), el sistema muestra un mensaje de error claro y el formulario queda vacío/sin cambios.
- [ ] `flutter test` pasa con ≥6 fixtures de `PropertyCardParser` (motos, carros, casos negativos).
- [ ] `dart analyze` pasa sin warnings en el código nuevo.
- [ ] No hay regresión en el feature SOAT: el flow de carga de SOAT sigue funcionando end-to-end.
- [ ] Todos los textos visibles en el flow de scan están en `app_es.arb` (sin strings hardcodeados).
- [ ] Los 3 eventos GA4 (`propertyScanAttempted`, `propertyScanSuccess`, `propertyScanFailed`) se emiten correctamente en los escenarios correspondientes.
