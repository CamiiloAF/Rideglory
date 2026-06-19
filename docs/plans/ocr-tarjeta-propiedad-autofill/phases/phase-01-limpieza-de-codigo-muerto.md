# Fase 1 — Limpieza de código muerto

**Slug:** `ocr-tarjeta-propiedad-autofill`
**Timestamp:** 2026-06-19T20:09:32Z
**Nivel rg-exec recomendado:** lite
**Dependencias:** ninguna (fase de partida)

---

## Objetivo

Eliminar 10 archivos huérfanos confirmados por el Architect bajo
`lib/features/vehicles/presentation/widgets/`: el cluster `vehicle_form` (9 archivos)
más `vehicle_selector.dart`. Tras la eliminación, `dart analyze` y `flutter test`
deben pasar sin errores ni warnings nuevos.

---

## Alcance (entra / no entra)

### Entra

| Archivo a borrar | Ruta completa |
|---|---|
| `vehicle_form.dart` | `lib/features/vehicles/presentation/widgets/vehicle_form.dart` |
| `vehicle_form_cover_photo_section.dart` | `lib/features/vehicles/presentation/widgets/vehicle_form_cover_photo_section.dart` |
| `vehicle_form_documents_section.dart` | `lib/features/vehicles/presentation/widgets/vehicle_form_documents_section.dart` |
| `vehicle_form_add_more_doc_slot.dart` | `lib/features/vehicles/presentation/widgets/vehicle_form_add_more_doc_slot.dart` |
| `vehicle_form_empty_cover_state.dart` | `lib/features/vehicles/presentation/widgets/vehicle_form_empty_cover_state.dart` |
| `vehicle_form_image_preview.dart` | `lib/features/vehicles/presentation/widgets/vehicle_form_image_preview.dart` |
| `vehicle_form_outline_button.dart` | `lib/features/vehicles/presentation/widgets/vehicle_form_outline_button.dart` |
| `vehicle_form_section_label.dart` | `lib/features/vehicles/presentation/widgets/vehicle_form_section_label.dart` |
| `vehicle_form_scan_banner.dart` | `lib/features/vehicles/presentation/widgets/vehicle_form_scan_banner.dart` |
| `vehicle_selector.dart` | `lib/features/vehicles/presentation/widgets/vehicle_selector.dart` |

### No entra

- Ningún archivo bajo `lib/features/vehicles/presentation/form/widgets/` (son activos).
- Los 6 archivos que permanecen en `presentation/widgets/` (no huérfanos):
  `vehicle_card.dart`, `vehicle_card_placeholder_icon.dart`,
  `vehicle_document_default_icon_slot.dart`, `vehicle_document_icon_slot.dart`,
  `vehicle_document_upload_button.dart`, `vehicle_document_upload_slot.dart`.
- No se toca código de SOAT, RTM, shared widgets, ni ninguna otra feature.
- No se modifica `pubspec.yaml`, `analysis_options.yaml`, ni configuración de DI.

---

## Que se debe hacer (pasos concretos y ordenados)

### Paso 0 — Verificación pre-borrado (obligatorio, no omitir)

Antes de borrar cualquier archivo, confirmar con `dart analyze` que ningún
archivo activo del árbol de fuentes los importa. El grep de referencia que
confirmó la ausencia de importadores externos es:

```bash
grep -rl \
  "vehicle_form_add_more_doc_slot\|vehicle_form_cover_photo_section\|vehicle_form_documents_section\|vehicle_form_empty_cover_state\|vehicle_form_image_preview\|vehicle_form_outline_button\|vehicle_form_section_label\|vehicle_form_scan_banner\|vehicle_selector\|VehicleForm\b" \
  lib --include="*.dart" \
  | grep -v "presentation/widgets/"
```

El resultado esperado son únicamente referencias que NO apuntan a los huérfanos
(p.ej. `vehicle_form_docs_section.dart` importa el `vehicle_form_add_more_doc_slot.dart`
que está en `form/widgets/`, no en `presentation/widgets/`). Si aparece algún
importador activo de los archivos bajo `presentation/widgets/`, parar y resolver
antes de borrar.

### Paso 1 — Borrar los 10 archivos huérfanos

Borrar todos en una sola pasada con `git rm`:

```bash
git rm \
  lib/features/vehicles/presentation/widgets/vehicle_form.dart \
  lib/features/vehicles/presentation/widgets/vehicle_form_cover_photo_section.dart \
  lib/features/vehicles/presentation/widgets/vehicle_form_documents_section.dart \
  lib/features/vehicles/presentation/widgets/vehicle_form_add_more_doc_slot.dart \
  lib/features/vehicles/presentation/widgets/vehicle_form_empty_cover_state.dart \
  lib/features/vehicles/presentation/widgets/vehicle_form_image_preview.dart \
  lib/features/vehicles/presentation/widgets/vehicle_form_outline_button.dart \
  lib/features/vehicles/presentation/widgets/vehicle_form_section_label.dart \
  lib/features/vehicles/presentation/widgets/vehicle_form_scan_banner.dart \
  lib/features/vehicles/presentation/widgets/vehicle_selector.dart
```

### Paso 2 — Verificar con dart analyze

```bash
dart analyze
```

Resultado esperado: cero errores nuevos. Los únicos warnings/infos
aceptables son los preexistentes en el proyecto (p.ej. el lint conocido de
`api_base_url_resolver.dart` documentado en `project_local_api_hack.md`).

### Paso 3 — Verificar con flutter test

```bash
flutter test
```

Resultado esperado: misma cantidad de tests en verde que antes del borrado.
Si algún test importaba alguno de los archivos borrados, falla aquí —
lo cual indicaría un importador que el análisis estático no detectó.

### Paso 4 — Gate de fase: confirmar que el huérfano vehicle_form_scan_banner no existe

```bash
ls lib/features/vehicles/presentation/widgets/vehicle_form_scan_banner.dart 2>/dev/null \
  && echo "ERROR: huerfano todavia existe" \
  || echo "OK: huerfano borrado"
```

Y que el banner activo correcto sigue intacto:

```bash
ls lib/features/vehicles/presentation/form/widgets/vehicle_scan_banner.dart \
  && echo "OK: banner activo presente"
```

Solo si ambos gates pasan se puede avanzar a la Fase 2.

---

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

Esta fase solo **borra** archivos. No crea ni modifica ningún archivo existente.

| Operación | Ruta | Cambio |
|-----------|------|--------|
| Borrar | `lib/features/vehicles/presentation/widgets/vehicle_form.dart` | Cluster raíz de código muerto — `VehicleForm` antigua no referenciada desde ningún punto activo |
| Borrar | `lib/features/vehicles/presentation/widgets/vehicle_form_cover_photo_section.dart` | Widget huérfano referenciado solo por `vehicle_form.dart` |
| Borrar | `lib/features/vehicles/presentation/widgets/vehicle_form_documents_section.dart` | Widget huérfano referenciado solo por `vehicle_form.dart` |
| Borrar | `lib/features/vehicles/presentation/widgets/vehicle_form_add_more_doc_slot.dart` | Widget huérfano — **HOMÓNIMO** de `form/widgets/vehicle_form_add_more_doc_slot.dart` (activo); borrar solo el de `presentation/widgets/` |
| Borrar | `lib/features/vehicles/presentation/widgets/vehicle_form_empty_cover_state.dart` | Widget huérfano — **HOMÓNIMO** de `form/widgets/vehicle_form_cover_empty_state.dart` (activo, nombre ligeramente diferente) |
| Borrar | `lib/features/vehicles/presentation/widgets/vehicle_form_image_preview.dart` | Widget huérfano — **HOMÓNIMO** de `form/widgets/vehicle_form_cover_image_preview.dart` (activo) |
| Borrar | `lib/features/vehicles/presentation/widgets/vehicle_form_outline_button.dart` | Widget huérfano — **HOMÓNIMO** de `form/widgets/vehicle_form_cover_outline_button.dart` (activo) |
| Borrar | `lib/features/vehicles/presentation/widgets/vehicle_form_section_label.dart` | Widget huérfano — **HOMÓNIMO** de `form/widgets/vehicle_form_section_header.dart` (activo, nombre diferente) |
| Borrar | `lib/features/vehicles/presentation/widgets/vehicle_form_scan_banner.dart` | Banner huérfano con bug de color (`Colors.white` sobre primario); el banner correcto es `form/widgets/vehicle_scan_banner.dart` |
| Borrar | `lib/features/vehicles/presentation/widgets/vehicle_selector.dart` | `VehicleSelector` huérfano; el selector activo de la app vive en `lib/shared/widgets/` |

---

## Contratos / API rideglory-api

Ninguno. Esta fase no tiene impacto en el backend.

---

## Cambios de datos / migraciones

Ninguno.

---

## Criterios de aceptacion (numerados, observables, testeables)

1. Los 10 archivos listados en la tabla de "Archivos a borrar" ya no existen en el
   working tree (`ls <ruta>` devuelve error).

2. Los 6 archivos que permanecen en `presentation/widgets/` (los no-huérfanos:
   `vehicle_card.dart`, `vehicle_card_placeholder_icon.dart`,
   `vehicle_document_default_icon_slot.dart`, `vehicle_document_icon_slot.dart`,
   `vehicle_document_upload_button.dart`, `vehicle_document_upload_slot.dart`)
   siguen presentes e intactos.

3. Ningún archivo bajo `lib/features/vehicles/presentation/form/widgets/` fue
   modificado ni borrado (verificar con `git status`).

4. `dart analyze` no reporta nuevos errores ni warnings respecto a la línea base
   pre-fase (los lints preexistentes documentados en memoria son aceptables).

5. `flutter test` pasa sin regresiones: mismo número de suites en verde, cero
   fallos nuevos.

6. El banner activo `lib/features/vehicles/presentation/form/widgets/vehicle_scan_banner.dart`
   existe y permanece sin modificaciones (gate de homónimo R7).

7. `dart analyze` + grep confirman que cero archivos activos del proyecto importan
   alguno de los 10 archivos borrados (cero "target not found" ni "undefined class"
   relacionados con los nombres eliminados).

---

## Pruebas (unitarias/widget/integracion)

Esta fase no requiere escribir tests nuevos. Los tests existentes actúan como red
de seguridad:

| Suite | Comando | Propósito en esta fase |
|---|---|---|
| Todos los tests | `flutter test` | Detectar cualquier importador de los archivos borrados que el análisis estático no capturó |
| SOAT tests | `flutter test test/features/soat/` | No-regresión: confirmar que SOAT no se ve afectado por el borrado |

Si algún test falla con un error de "target not found" o "undefined class" referenciando
uno de los 10 archivos borrados, significa que ese archivo tenía un importador
activo no detectado por `dart analyze`. En ese caso: restaurar el archivo con
`git restore <ruta>`, localizar el importador, resolver la dependencia (actualizar
el import al archivo activo equivalente), y volver a borrar.

---

## Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|------------|
| R3 | Borrar accidentalmente un archivo activo de `form/widgets/` confundiéndolo con su homónimo huérfano en `presentation/widgets/` | Baja | Medio | NOTA-1 del plan lista los pares de homónimos (ver tabla de archivos arriba). El comando `git rm` se ejecuta con rutas completas que incluyen `presentation/widgets/` — no con wildcards. `dart analyze` + `flutter test` capturan la regresión si ocurre. |
| R5 | Algún importador escapa al análisis estático (p.ej. reflexión, string-based routing) | Muy baja | Bajo | `flutter test` es la segunda red de seguridad. El proyecto no usa reflexión para imports de widgets. |
| R7 | El implementador confunde `vehicle_form_scan_banner.dart` (huérfano, bug de color) con `vehicle_scan_banner.dart` (activo, correcto) | Baja-Media | Bajo | Gate explícito en Paso 4: verificar que el huérfano no existe Y que el activo sigue presente. Nombres distintos pero similares — la ruta completa es la única fuente de verdad. |

---

## Dependencias (fases prerequisito y por que)

Ninguna. Esta es la fase de partida (id: 1). No depende de ninguna otra fase.

Las fases 2–6 dependen implícitamente de esta fase porque:
- La fase 5 activa `VehicleScanBanner` en `vehicle_form_body.dart`. Si el
  huérfano `vehicle_form_scan_banner.dart` siguiera existiendo, el implementador
  podría editar el archivo incorrecto por error de nombre.
- Eliminar el ruido de código muerto hace más legible el directorio
  `presentation/widgets/` para las fases siguientes.

---

## Ejecucion recomendada (nivel rg-exec: lite)

**Por que lite:** esta fase consiste exclusivamente en borrado de archivos
confirmados como huérfanos por análisis estático (`dart analyze`) y revisión del
Architect. No hay lógica nueva, no se crean contratos de API, no se modifica el
grafo de DI, no se ejecuta code-gen con `build_runner`. La operación es
completamente reversible con `git restore` o `git revert`. El blast radius es
mínimo: si algo sale mal, `dart analyze` y `flutter test` lo detectan
inmediatamente y el estado original se recupera en segundos.

El auditor Opus no necesita iterar sobre lógica de negocio — solo verificar que
los gates de `dart analyze` + `flutter test` pasan y que ningún archivo activo
fue eliminado por error.
