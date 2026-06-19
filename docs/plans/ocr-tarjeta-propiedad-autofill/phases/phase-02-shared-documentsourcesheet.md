# Fase 2 — Shared DocumentSourceSheet

**Timestamp:** 2026-06-19T20:09:31Z
**Slug:** `ocr-tarjeta-propiedad-autofill`
**Nivel rg-exec recomendado:** `lite`
**Depende de:** Fase 1 (Limpieza de código muerto)

---

## Objetivo

Crear `lib/shared/widgets/modals/document_source_sheet.dart`: un `StatelessWidget` que presenta al usuario las opciones "Cámara" y "Galería" para capturar la tarjeta de propiedad, con retorno tipado `enum DocumentSourceOption { camera, gallery }` y un subtítulo de instrucción de "cara frontal" debajo del título del sheet, antes de las opciones.

El scope de esta fase está **restringido exclusivamente** al property card scanner. No se migra `SoatAddDocumentSheet` ni `SoatVehicleOptionsSheet`. Cualquier extensión (PDF, opción Manual, migración SOAT) es v2.

---

## Alcance (entra / no entra)

### Entra
- Archivo nuevo `lib/shared/widgets/modals/document_source_sheet.dart` con:
  - `enum DocumentSourceOption { camera, gallery }` (en el mismo archivo o en un archivo hermano si aplica, ver sección de archivos)
  - `DocumentSourceSheet extends StatelessWidget` que presenta el bottom sheet
  - Drag handle, título, subtítulo de instrucción "cara frontal" (hardcodeado provisional), dos opciones de lista (cámara, galería)
  - `context.pop(DocumentSourceOption.camera)` / `context.pop(DocumentSourceOption.gallery)` al tocar cada opción
  - Estilos del design system oscuro: `AppColors.darkCard`, `AppColors.darkTertiary`, `AppColors.darkBorderPrimary`, bordes redondeados, íconos con fondo `AppColors.primarySubtle` y color `AppColors.primary`
- `dart analyze` pasa sin warnings ni errores en el archivo nuevo

### No entra
- Migración de `SoatAddDocumentSheet` — se deja intacta
- Migración de `SoatVehicleOptionsSheet` — se deja intacta
- Opción PDF o Manual en el nuevo sheet
- Lógica de cubit, imagen picker, o dominio de ningún tipo
- Claves ARB definitivas — el subtítulo "cara frontal" va hardcodeado en esta fase; la l10n se completa en Fase 6
- Registro en DI (el widget es stateless, no necesita injectable)
- Code-gen (no hay freezed ni json_serializable en esta fase)
- Tests de widget (la fase de QA es la 6; el widget es trivial y observable)

---

## Qué se debe hacer (pasos concretos y ordenados)

1. **Verificar prerequisito:** confirmar que `dart analyze` no reporta referencias a los huérfanos borrados en Fase 1 antes de empezar.

2. **Inspeccionar `SoatAddDocumentSheet`** (`lib/features/soat/presentation/widgets/soat_add_document_sheet.dart`) como referencia visual y estructural. Replicar la estructura de padding, drag handle, estilos de tarjeta de opción y chevron — es el patrón que el usuario ya conoce.

3. **Definir el enum** `DocumentSourceOption { camera, gallery }` en el mismo archivo `document_source_sheet.dart` (declarar antes del widget, en el top-level del archivo). No crear un archivo separado solo para el enum — mantener cohesión de artefactos relacionados.

4. **Implementar `DocumentSourceSheet extends StatelessWidget`** con la siguiente estructura visual (de arriba a abajo):
   - Drag handle (pill de 36×4 px, color `AppColors.darkBorderPrimary`, bottom margin 20 px)
   - Título del sheet (texto hardcodeado provisional `'Escanear tarjeta de propiedad'`, estilo `fontSize: 17, fontWeight: w700, color: AppColors.textOnDarkPrimary`)
   - Subtítulo de instrucción cara frontal (texto hardcodeado provisional `'Asegúrate de fotografiar la cara frontal del documento'`, estilo `fontSize: 13, color: AppColors.textOnDarkTertiary`, `SizedBox(height: 4)` entre título y subtítulo, `SizedBox(height: 16)` entre subtítulo y primera opción)
   - Opción "Cámara" con ícono `Icons.camera_alt_outlined`, `onTap: () => context.pop(DocumentSourceOption.camera)`
   - `SizedBox(height: 10)` entre opciones
   - Opción "Galería" con ícono `Icons.photo_library_outlined`, `onTap: () => context.pop(DocumentSourceOption.gallery)`

5. **Implementar el widget de opción** como una clase privada `_DocumentSourceOption extends StatelessWidget` en el mismo archivo. Estructura: `Material` > `InkWell` > `Container` con borde, icono con fondo `AppColors.primarySubtle`, label + subtitle, `Icons.chevron_right`. Replicar el patrón de `_SoatAddDocumentOption`.

6. **Usar `go_router`'s `context.pop(value)`** — importar `package:go_router/go_router.dart` — para el pop tipado con el enum, igual que usa `SoatAddDocumentSheet` pero con el enum en lugar de `int`.

7. **Envolver el contenido en `SafeArea`** con `top: false` y `Padding(EdgeInsets.fromLTRB(20, 12, 20, 24))`, `Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch)`.

8. **Correr `dart analyze`** y corregir cualquier warning antes de dar la fase por completada.

---

## Archivos a crear/modificar (rutas reales)

| Operación | Ruta | Qué cambia |
|-----------|------|------------|
| **CREAR** | `lib/shared/widgets/modals/document_source_sheet.dart` | Nuevo archivo: `enum DocumentSourceOption` + `DocumentSourceSheet` stateless + `_DocumentSourceOption` privado |

**No se modifica ningún archivo existente en esta fase.**

El directorio `lib/shared/widgets/modals/` ya existe y contiene `app_dialog.dart`, `confirmation_dialog.dart` y otros — el archivo nuevo encaja naturalmente ahí.

---

## Contratos / API rideglory-api

**Ninguno.** Esta fase es 100% Flutter UI, sin HTTP, sin WebSocket, sin Firebase.

---

## Cambios de datos / migraciones

**Ninguno.** Widget stateless puro sin persistencia.

---

## Criterios de aceptación (numerados, observables, testeables)

1. Existe `lib/shared/widgets/modals/document_source_sheet.dart` con el enum `DocumentSourceOption { camera, gallery }` y la clase `DocumentSourceSheet extends StatelessWidget`.
2. El sheet muestra exactamente dos opciones: "Cámara" y "Galería". No hay opción PDF ni Manual.
3. Tocar "Cámara" hace `context.pop(DocumentSourceOption.camera)`; tocar "Galería" hace `context.pop(DocumentSourceOption.gallery)`. El tipo del resultado es `DocumentSourceOption`, no `int`.
4. Existe un subtítulo visible **debajo del título** y **antes de las opciones** que instruye al usuario sobre la cara frontal del documento.
5. Los íconos de las opciones tienen fondo `AppColors.primarySubtle` y color `AppColors.primary`. El texto de las opciones usa `AppColors.textOnDarkPrimary`. El fondo de las tarjetas de opción es `AppColors.darkTertiary` con borde `AppColors.darkBorderPrimary`. **No hay texto blanco (`Colors.white`) hardcodeado.**
6. `dart analyze` pasa sin warnings ni errores en el archivo nuevo.
7. `SoatAddDocumentSheet` permanece intacta e inalterada (verificar con `git diff`).
8. `flutter test` pasa sin regresiones (suite completa).

---

## Pruebas

**Tests de widget** para esta fase: no requeridos en esta fase (el widget es trivial, sin estado, sin lógica; la observabilidad visual en la Fase 6 con `dart analyze` + `flutter test` es suficiente).

**Verificación de no-regresión** obligatoria al finalizar:
- `dart analyze` — cero warnings en el archivo nuevo y cero regresiones en el resto del proyecto.
- `flutter test` — suite completa pasa. En particular, `flutter test test/features/soat/` no debe verse afectada.

Si el equipo desea agregar un test de widget para `DocumentSourceSheet` en la Fase 6 (QA), puede hacerse en `test/shared/widgets/modals/document_source_sheet_test.dart` verificando que el pop devuelve el enum correcto al simular el tap en cada opción.

---

## Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|------------|
| R1 | Scope creep: el implementador añade la opción PDF o intenta migrar SOAT como "mejora" | Baja | Medio | La spec restringe explícitamente a `{ camera, gallery }`. El criterio de aceptación 2 es observable. Cualquier extensión es v2. |
| R2 | Uso de `int` en lugar de `enum` como tipo de retorno (repitiendo la deuda de `SoatAddDocumentSheet`) | Baja | Bajo | Criterio de aceptación 3 verifica el tipo. La revisión del auditor lite lo detecta. |
| R3 | Texto blanco (`Colors.white`) sobre ícono naranja (primario) en el fondo de ícono — violación del estándar de accesibilidad de color | Baja-Media | Bajo | Criterio de aceptación 5 lo especifica. El implementador debe copiar el patrón de `form/widgets/vehicle_scan_banner.dart` que ya usa `AppColors.textOnDarkPrimary`, no el del huérfano (ya borrado en Fase 1) que tenía el bug. |
| R4 | Import incorrecto de `go_router` para `context.pop()` (usando `Navigator.pop` en su lugar, que no devuelve valor al `showModalBottomSheet` caller de forma tipada) | Baja | Bajo | Especificado explícitamente en el paso 6 del "Qué se debe hacer". |

---

## Dependencias

**Fase 1 — Limpieza de código muerto** (prerequisito).

Razón: la Fase 1 borra `lib/features/vehicles/presentation/widgets/vehicle_form_scan_banner.dart` (el banner huérfano con el bug de `Colors.white` sobre primario). Aunque `DocumentSourceSheet` es independiente de ese archivo, arrancar con el árbol limpio evita que el implementador tome como referencia el archivo incorrecto. Adicionalmente, `dart analyze` en Fase 1 confirma que el grafo de imports está sano antes de agregar código nuevo.

---

## Ejecución recomendada (nivel rg-exec: lite)

**Nivel: `lite`**

Justificación: widget stateless puro en una sola área (`lib/shared/widgets/modals/`). Sin code-gen (no hay freezed, json_serializable, ni injectable). Sin migraciones ni contratos API. Alcance explícitamente restringido a cámara y galería. Sin lógica de estado. Un único archivo nuevo. Completamente reversible con `git revert`. El auditor lite verifica layout, tipos, colores y `dart analyze` — cobertura suficiente para el riesgo de esta fase.
