# Fase 2 — Diseño Pencil: garaje con sección de archivados

_Generated: 2026-06-16T16:24:00Z_
_Plan: archive-vehicle-soft-delete_
_Nivel rg-exec: lite_

---

## Objetivo

El diseñador y el PO aprueban la UX completa del flujo de archivado de vehículos —incluyendo la sección colapsable de archivados, los menús contextuales bifurcados y los diálogos de confirmación— antes de que se escriba una sola línea de código Flutter. La aprobación explícita por escrito del PO es el artefacto de salida que desbloquea la Fase 3.

---

## Alcance (entra / no entra)

### Entra

- **8 frames obligatorios en `rideglory.pen`** (ver sección "Qué se debe hacer") que cubren todos los estados de la pantalla de garaje y sus flujos modales relacionados con el archivado.
- **Decisión explícita documentada** en el frame o como comentario de diseño: "Editar" y "Agregar mantenimiento" NO aparecen en el menú de vehículos archivados.
- **Touch targets verificados**: mínimo 44 px de alto en el header colapsable "Archivados (N)"; mínimo 48 px por celda de menú en los bottom sheets.
- **Anotaciones de diseño** que indiquen los tokens de color correctos: CTA naranja (primario, texto `darkBgPrimary`) para archivar; CTA `colorScheme.error` (texto `onError`) para eliminación permanente.
- **Aprobación explícita por escrito del PO** antes de cerrar la fase (puede ser un mensaje de Slack, comentario en el frame o email — lo importante es que quede registrado).

### No entra

- Código Flutter de ningún tipo (widgets, cubits, use cases, DTOs, l10n).
- Cambios en `rideglory-api` o contratos backend.
- Migraciones de base de datos.
- Diseño de pantallas que no sean parte del flujo garaje → archivado → restaurar/eliminar (por ejemplo, perfil, eventos, home).
- Creación de un archivo `.pen` nuevo — todos los frames van en el único `rideglory.pen` existente.

---

## Qué se debe hacer (pasos concretos y ordenados)

### Paso 0 — Pre-flight MCP

1. Verificar que el MCP de Pencil responda: llamar `get_editor_state(include_schema: true)` sobre `rideglory.pen`.
2. Si el MCP está caído, **no continuar**. Registrar el bloqueo y reprogramar. No diseñar en ninguna herramienta alternativa.
3. Leer las guidelines del proyecto con `get_guidelines()` para respetar la paleta y tipografía del design system.
4. Identificar los frames existentes del garaje con `batch_get` para no duplicar ni sobrescribir frames activos.

### Paso 1 — Frame 1: Garaje sin archivados

Diseñar el estado del garaje cuando el usuario no tiene ningún vehículo archivado. La sección "Archivados" no es visible o muestra un estado vacío implícito (sin ruido visual). Este frame es la línea base.

- Usar el componente `VehicleCard` existente para los vehículos activos.
- No mostrar ningún header ni separador de "Archivados".

### Paso 2 — Frame 2: Garaje, sección "Archivados (N)" colapsada

Diseñar el garaje cuando hay al menos un vehículo archivado. La sección aparece al pie de la lista activa como un header colapsable:

- Texto: `"Archivados (N)"` donde N es el número real de archivados.
- Ícono de chevron apuntando hacia abajo (colapsado).
- Alto mínimo del header: **44 px**.
- Área táctil ocupa el ancho completo del contenedor.
- Bajo el header no se muestra ninguna card (estado colapsado).

### Paso 3 — Frame 3: Garaje, sección "Archivados (N)" expandida

Diseñar el mismo garaje con la sección expandida:

- Chevron apunta hacia arriba.
- Las cards de vehículos archivados aparecen listadas bajo el header.
- Diferenciación visual del vehículo archivado: usar el `VehicleCard` existente con **opacidad reducida** y/o un chip de estado "Archivado" en color neutro (no naranja). La recomendación es opacidad `0.6` + chip; el diseñador elige la variante.
- No mostrar indicador de "vehículo principal" en vehículos archivados.

### Paso 4 — Frame 4: Menú contextual — vehículo activo

Diseñar el bottom sheet de opciones para un vehículo **activo** (no archivado):

- Opciones (en orden): "Establecer como principal" (visible solo si no es ya el principal), "Editar", "Agregar mantenimiento", "Archivar".
- La opción "Eliminar" **no aparece** en este menú.
- Cada celda: alto mínimo **48 px**. Ícono + label alineados.
- "Archivar": ícono de archivo/carpeta en color de texto estándar (no destructivo).

### Paso 5 — Frame 5: Menú contextual — vehículo archivado

Diseñar el bottom sheet de opciones para un vehículo **archivado**:

- Opciones (en orden): "Restaurar", "Eliminar permanentemente".
- **"Editar" y "Agregar mantenimiento" no aparecen.** Agregar una nota de diseño en el frame: _"Un vehículo archivado no debe recibir nuevos registros. Decisión PO: solo Restaurar y Eliminar permanentemente."_
- "Restaurar": ícono de volver/restaurar, color de texto estándar.
- "Eliminar permanentemente": color `colorScheme.error` (rojo), ícono de papelera.
- Cada celda: alto mínimo **48 px**.

### Paso 6 — Frame 6: Diálogo de confirmación de archivado

Diseñar el diálogo modal que aparece cuando el usuario toca "Archivar" en el menú de vehículo activo:

- **Tono:** informativo (no destructivo).
- Título: `"Archivar vehículo"`.
- Cuerpo: `"El vehículo se ocultará de tu garaje activo. Tu historial de mantenimientos e inscripciones se conserva."` (l10n key: `vehicle_archiveConfirmMessage`).
- CTA primario: `"Archivar"` — botón en color **naranja** (`AppColors.primary`) con texto oscuro (`darkBgPrimary`). Cumple la regla de texto oscuro sobre el acento naranja.
- CTA secundario: `"Cancelar"` — texto o botón neutro.
- Layout: usar `ConfirmationDialog` del design system existente.

### Paso 7 — Frame 7: Diálogo de confirmación de eliminación permanente

Diseñar el diálogo modal que aparece cuando el usuario toca "Eliminar permanentemente" en el menú de vehículo archivado:

- **Tono:** destructivo (irreversible).
- Título: `"Eliminar vehículo permanentemente"`.
- Cuerpo: `"Esta acción es irreversible. El vehículo {vehicleName} y su historial serán eliminados definitivamente."` — nombrar el vehículo en el cuerpo.
- CTA primario: `"Eliminar permanentemente"` — botón en `colorScheme.error` (rojo), texto `colorScheme.onError` (claro). **Excepción justificada a la regla de texto oscuro sobre naranja:** `colorScheme.error` no es el acento naranja, es el color de error del sistema; la accesibilidad se garantiza con `onError`.
- CTA secundario: `"Cancelar"` — texto o botón neutro.
- Agregar nota de diseño en el frame: _"CTA usa DialogActionType.danger con ConfirmationDialog existente. No crear variante nueva."_

### Paso 8 — Frame 8: Estado loading / error inline

Diseñar los estados de transición durante las operaciones de archivar y restaurar:

- **Loading en card archivada/restaurada:** shimmer o overlay de carga sobre la `VehicleCard` afectada mientras la operación está en curso. Alternativa: indicador circular pequeño en el menú.
- **Error inline:** snackbar o banner de error al pie de la pantalla si la operación falla. Usar el estilo de error existente en el design system (no modal).
- El estado de loading cubre la operación de archivado y la de restauración. La eliminación permanente muestra el CTA deshabilitado (grayed out) durante el request — incluir este estado en el frame del diálogo (Frame 7, estado secundario).

### Paso 9 — Revisión interna antes de presentar al PO

Verificar con `snapshot_layout` y `get_screenshot` que:

- Todos los frames tienen nombre descriptivo (p.ej. `Garaje - Archivados colapsado`, `Menu - Vehículo archivado`, `Dialogo - Eliminar permanentemente`).
- Los touch targets son visualmente correctos (44/48 px).
- Los tokens de color son consistentes con el design system.
- La decisión sobre Editar/Agregar mantenimiento está anotada en el Frame 5.

### Paso 10 — Presentación al PO y aprobación

Exportar capturas de los 8 frames con `export_nodes` (un nodo por llamada, escala 1x para frames altos) y presentarlos al PO. El PO debe dar **aprobación explícita por escrito** (comentario, mensaje, o anotación en el frame). Sin esta aprobación, la Fase 3 no puede iniciarse.

---

## Archivos a crear/modificar (rutas reales, una línea de "qué cambia")

| Archivo | Qué cambia |
|---------|------------|
| `rideglory.pen` | Se añaden 8 frames nuevos con los estados de pantalla del garaje con archivados, menús contextuales bifurcados y diálogos de confirmación |

No se modifica ningún archivo de código fuente Flutter ni del backend.

---

## Contratos / API rideglory-api

**Ninguno.** Esta fase es diseño puro. No se tocan endpoints, DTOs, ni contracts del monorepo.

---

## Cambios de datos / migraciones

**Ninguno.** No hay cambios en schema Prisma, datos de base de datos, Firebase, ni `SharedPreferences`.

---

## Criterios de aceptación

1. El archivo `rideglory.pen` contiene exactamente 8 frames nuevos correspondientes a los estados definidos en el alcance: (1) garaje sin archivados, (2) sección colapsada con contador, (3) sección expandida con cards diferenciadas, (4) menú activo sin "Eliminar", (5) menú archivado sin "Editar"/"Agregar mantenimiento", (6) diálogo de archivado informativo, (7) diálogo de eliminación permanente destructivo, (8) loading/error inline.
2. El Frame 5 (menú archivado) contiene una nota de diseño visible que documenta la decisión del PO: "Editar" y "Agregar mantenimiento" no aparecen en vehículos archivados.
3. El header "Archivados (N)" en Frame 2 tiene un alto verificable de mínimo 44 px y el área táctil ocupa el ancho completo.
4. Cada celda de menú en Frames 4 y 5 tiene un alto verificable de mínimo 48 px.
5. El CTA del Frame 6 (archivar) usa el color naranja de acento (`AppColors.primary`) con texto oscuro (`darkBgPrimary`) — nunca blanco sobre naranja.
6. El CTA del Frame 7 (eliminar permanentemente) usa `colorScheme.error` con texto `colorScheme.onError` (claro).
7. El Frame 7 incluye el nombre del vehículo en el cuerpo del diálogo y el estado secundario con el CTA deshabilitado durante loading.
8. El Frame 8 muestra estado de loading inline (shimmer o overlay en card) y estado de error como snackbar (no modal).
9. Todos los frames tienen nombres descriptivos en Pencil (no "Frame 1", "Frame 2").
10. El PO ha dado aprobación explícita por escrito antes de que la Fase 3 se inicie.

---

## Pruebas (unitarias / widget / integración)

**No aplica.** Esta fase no produce código de producción, widgets, ni lógica testeable.

El único "test" es la verificación visual humana (PO + diseñador) de los 8 frames antes de la aprobación. `get_screenshot` y `snapshot_layout` de Pencil sirven como herramienta de verificación durante el diseño.

---

## Riesgos y mitigaciones

| # | Riesgo | Prob. | Impacto | Mitigación |
|---|--------|-------|---------|------------|
| R-1 | **MCP Pencil caído bloquea toda la fase** | Media | Alto | No hay alternativa — es una regla del proyecto. Registrar el bloqueo y reprogramar. No diseñar en herramientas alternativas (Figma, mockup HTML, etc.) porque rideglory.pen es la única fuente de verdad. Planificar la fase al inicio del sprint para tener margen de reintento. |
| R-2 | **Frames altos (≥ 1445 px) no se exportan correctamente a 1x** | Media | Bajo | Usar `export_nodes` con escala 1x. Para frames que excedan el límite, exportar en secciones o usar `get_screenshot` como alternativa de revisión. Documentado en `reference_pencil_export_limits.md`. |
| R-3 | **Ambigüedad en la diferenciación visual del vehículo archivado** | Baja | Medio | El arquitecto recomienda reutilizar `VehicleCard` con opacidad reducida + chip "Archivado". Si el diseñador propone un componente nuevo, el PO debe evaluar el impacto en la Fase 3 (más trabajo de implementación). La decisión queda registrada en la aprobación del PO. |
| R-4 | **Solapamiento de nombres de frames con frames existentes** | Baja | Bajo | Pre-flight obligatorio: listar frames actuales con `batch_get` antes de crear nuevos. Usar prefijos únicos (p.ej. `[Garaje-Archivados]`). |
| R-5 | **PO no está disponible para dar aprobación** | Baja | Alto | La fase no cierra sin aprobación. Fijar fecha de revisión antes de iniciar el diseño. Si la aprobación se demora, las Fases 1 y 5 pueden avanzar en paralelo (no dependen del diseño). |
| R-6 | **Regla de texto oscuro sobre naranja mal interpretada en el Frame 6** | Baja | Bajo | El CTA de archivar usa `AppColors.primary` (naranja). El texto del CTA debe ser `darkBgPrimary` (`#0D0D0F`), nunca blanco. Anotar el token correcto en el frame. Referencia: regla `feedback_dark_text_on_primary.md`. |

---

## Dependencias (fases prerequisito y por qué)

| Fase | Relación | Razón |
|------|----------|-------|
| Fase 1 (Backend) | **Independiente** | El diseño no requiere que el endpoint de soft-delete esté listo. Los flujos se pueden diseñar con datos de muestra. |
| Ninguna fase previa | **Sin prerequisitos** | Fase 2 puede iniciarse en paralelo con Fase 1 desde el día 1. |

**Esta fase es prerequisito bloqueante para:**

| Fase posterior | Por qué bloquea |
|----------------|-----------------|
| Fase 3 (Flutter: archivar y restaurar) | Las reglas del proyecto exigen que toda UI nueva esté aprobada en Pencil antes de implementar. La sección colapsable de archivados y los menús bifurcados son UI nueva. Sin aprobación del PO, ningún widget puede escribirse. |

---

## Ejecución recomendada (nivel rg-exec: lite)

**Nivel: `lite`**

**Por qué ese nivel:** Fase de diseño puro — sin código de producción, sin contratos de API, sin migraciones. Una sola herramienta (Pencil MCP). Completamente reversible (los frames pueden editarse o eliminarse sin impacto en el código). El único riesgo es de proceso (MCP caído), no técnico. No requiere auditor de arquitectura posterior (el gate de calidad es la aprobación visual del PO).

**Instrucción al agente rg-exec:**

```
Abrir rideglory.pen con get_editor_state(include_schema: true).
Leer guidelines con get_guidelines().
Listar frames existentes del garaje con batch_get para no sobrescribir.
Crear los 8 frames en el orden definido en "Qué se debe hacer".
Verificar touch targets con snapshot_layout tras crear Frame 2 y Frames 4-5.
Exportar capturas con export_nodes (un nodo por llamada, 1x) para revisión del PO.
No tocar ningún archivo .dart, .arb, .yaml, ni de backend.
```

**Artefacto de salida esperado:** confirmación de que los 8 frames están en `rideglory.pen` con nombres descriptivos, y el mensaje de aprobación del PO transcrito o referenciado en el resumen de ejecución.
