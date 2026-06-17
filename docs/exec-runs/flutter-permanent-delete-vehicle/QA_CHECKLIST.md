# Checklist de QA — Eliminación permanente de vehículos archivados

**Feature:** Eliminación permanente de vehículos archivados desde el garaje
**Fases cubiertas:** Fase 1 (backend — endpoint `DELETE /api/vehicles/my/:vehicleId`) + Fase 4 (Flutter — UI y lógica de eliminación permanente)
**Estado:** Pendiente de aprobacion PO

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Al menos **2 vehículos activos** registrados en la cuenta (para verificar que la opción NO aparece en activos)
- [ ] Al menos **2 vehículos archivados** (para el flujo principal y el caso de error de red); si no los tienes, archivalos desde el menú de opciones de un vehículo activo
- [ ] La app conectada al backend con Fase 1 desplegada (endpoint `DELETE /api/vehicles/my/:vehicleId` disponible)
- [ ] Un segundo dispositivo o herramienta de red (como proxy Charles o modo avión) para simular error de red en el caso de borde M-8

---

## 1. Visibilidad de la opción según estado del vehículo

> Abre la app y navega al garaje (pantalla principal, sección "Mi garaje").

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 1.1 | Toca el ícono de opciones (tres puntos o swipe) de un **vehículo activo** | El menú de opciones abre mostrando "Editar", "Agregar mantenimiento" y "Archivar" | |
| 1.2 | Revisa todas las opciones visibles del menú de un vehículo activo | La opción **"Eliminar permanentemente" NO aparece** en ninguna parte del menú | |
| 1.3 | Cierra el menú y abre las opciones de un **vehículo archivado** (sección "Archivados") | El menú de opciones abre | |
| 1.4 | Revisa las opciones del menú del vehículo archivado | La opción **"Eliminar permanentemente" SÍ aparece**, con ícono de papelera en color rojo | |
| 1.5 | Verifica las demás opciones presentes en el menú del vehículo archivado | Aparecen "Restaurar" y "Eliminar permanentemente"; **no aparecen** "Editar", "Agregar mantenimiento" ni "Archivar" | |

---

## 2. Diálogo de confirmación destructivo

> Desde el menú de opciones de un vehículo archivado, toca "Eliminar permanentemente".

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 2.1 | Toca "Eliminar permanentemente" en el menú del vehículo archivado | Aparece un diálogo de confirmación | |
| 2.2 | Observa el estilo visual del diálogo | El ícono y el botón de confirmar aparecen en **color rojo** (tono de error/destructivo), no en naranja ni azul | |
| 2.3 | Lee el título del diálogo | El título indica que la acción es de eliminación permanente (p. ej. "Eliminar vehículo permanentemente") | |
| 2.4 | Lee el cuerpo del diálogo | El mensaje incluye el **nombre exacto del vehículo** que estás por eliminar y describe que la acción es irreversible | |
| 2.5 | Lee el texto del botón principal del diálogo | El botón dice algo como "Eliminar" (no "Aceptar", no "Confirmar") con fondo rojo o estilo destructivo | |
| 2.6 | Lee el texto del botón secundario | Hay un botón de cancelar claramente diferenciado (p. ej. "Cancelar") sin estilo destructivo | |

---

## 3. Flujo de confirmación — eliminar

> Estás viendo el diálogo de confirmación con el nombre del vehículo archivado.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 3.1 | Toca el botón de confirmar ("Eliminar") | El diálogo se cierra | |
| 3.2 | Observa la sección "Archivados" del garaje | El vehículo que acabas de eliminar **ya no aparece** en la lista | |
| 3.3 | Verifica que el resto de vehículos archivados sigue visible | Los demás vehículos archivados siguen listados normalmente | |
| 3.4 | Observa el snackbar que aparece tras la eliminación | Aparece un snackbar con fondo **verde** (éxito) con un mensaje de confirmación de eliminación permanente | |
| 3.5 | Espera a que el snackbar desaparezca y verifica el garaje | La lista completa del garaje se ve coherente; ningún vehículo fantasma aparece ni hay errores de carga | |

---

## 4. Flujo de cancelación — no eliminar

> Abre el menú de opciones de otro vehículo archivado y toca "Eliminar permanentemente".

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 4.1 | Toca "Eliminar permanentemente" para abrir el diálogo | El diálogo de confirmación aparece con el nombre del vehículo | |
| 4.2 | Toca el botón "Cancelar" (o el área fuera del diálogo si aplica) | El diálogo se cierra | |
| 4.3 | Verifica la sección "Archivados" del garaje | El vehículo **sigue apareciendo** en la lista; no fue eliminado | |
| 4.4 | Verifica que no aparece ningún snackbar | No aparece ningún mensaje de éxito ni de error | |
| 4.5 | Toca opciones del mismo vehículo nuevamente | El menú sigue abriendo normalmente; el vehículo está intacto | |

---

## 5. Integridad del formulario de edición

> Abre el formulario de edición de un vehículo (activo o archivado).

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5.1 | Desde el menú de un vehículo activo toca "Editar" | El formulario de edición abre correctamente | |
| 5.2 | Revisa todos los botones visibles en el formulario de edición | **No aparece ningún botón de "Eliminar vehículo"** en ninguna parte del formulario | |
| 5.3 | Navega por los pasos del formulario (si es multi-paso) | Ningún paso muestra botón o enlace de eliminación | |
| 5.4 | Guarda o descarta el formulario | El formulario cierra normalmente; el vehículo sigue en la lista | |

---

## 6. Integridad de otros flujos del garaje

> Verifica que los flujos existentes no se rompieron.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 6.1 | Abre opciones de un vehículo activo y toca "Archivar" | Aparece diálogo de confirmación; al confirmar, el vehículo pasa a la sección "Archivados" con snackbar de confirmación | |
| 6.2 | Abre opciones de un vehículo archivado y toca "Restaurar" | El vehículo pasa de la sección "Archivados" a la sección de activos con snackbar de confirmación | |
| 6.3 | Abre opciones de un vehículo activo y toca "Editar" | El formulario de edición carga correctamente con los datos del vehículo | |
| 6.4 | Abre opciones de un vehículo activo y toca "Agregar mantenimiento" | Navega a la pantalla de mantenimiento del vehículo | |

---

## 7. Casos de borde

### 7A. Doble tap rápido en confirmar

> Abre el diálogo de confirmación de eliminación permanente de un vehículo archivado.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 7A.1 | Toca el botón "Eliminar" dos veces muy rápido (doble tap) | El vehículo se elimina **una sola vez**; no aparece error ni comportamiento extraño (el guard anti doble-tap previene la segunda llamada) | |
| 7A.2 | Verifica el snackbar tras el doble tap | Aparece un solo snackbar de éxito; no dos snackbars apilados | |

### 7B. Error de red al confirmar eliminación

> Activa modo avión o bloquea la conexión de red en el dispositivo. Luego abre opciones de un vehículo archivado.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 7B.1 | Con la red desactivada, toca "Eliminar permanentemente" y luego confirma en el diálogo | El diálogo se cierra o el botón muestra estado de carga | |
| 7B.2 | Observa el snackbar que aparece | Aparece un snackbar con fondo **rojo** (error) y un mensaje de error legible (en español) | |
| 7B.3 | Verifica la sección "Archivados" | El vehículo **sigue apareciendo** (no fue eliminado porque la request falló) | |
| 7B.4 | Reactiva la red y repite el flujo de eliminación | La eliminación ahora funciona correctamente con snackbar verde | |

### 7C. Lista de archivados queda vacía tras la última eliminación

> Elimina el último vehículo archivado que te queda en la cuenta.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 7C.1 | Confirma la eliminación del único vehículo archivado restante | El vehículo desaparece y el snackbar de éxito aparece | |
| 7C.2 | Observa la sección "Archivados" | La sección desaparece del garaje o muestra un estado vacío apropiado; no hay pantalla rota ni error visible | |

---

## 8. Verificaciones tecnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a la base de datos, logs del backend o herramientas de red.

| # | Verificacion | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 8.1 | En base de datos, busca el registro del vehículo eliminado tras el flujo M-3 | El registro **no existe** (eliminación física — hard delete); el campo `isArchived` no aplica porque la fila fue borrada | |
| 8.2 | Inspecciona la request HTTP que se dispara al confirmar eliminación (p. ej. con Charles o DevTools en simulador) | La request es `DELETE /api/vehicles/my/{vehicleId}` con el `Authorization: Bearer <token>` correcto; no hay request a `hard-delete/:id` | |
| 8.3 | Verifica en los logs del backend la request de eliminación | El backend retorna `200` o `204`; no hay errores 404 ni 500 | |
| 8.4 | Después de eliminar, realiza un GET de la lista de vehículos del usuario | El endpoint `/api/vehicles/my` devuelve la lista sin el vehículo eliminado | |
| 8.5 | Ejecuta en el proyecto Flutter: `grep -rn 'hard-delete' lib/` | **Cero hits** — no existe ninguna referencia a la ruta obsoleta en código compilable | |
| 8.6 | Ejecuta: `grep -rn 'VehicleDeleteCubit\|deleteVehicleLocally' lib/ --include='*.dart'` | **Cero hits** — el cubit obsoleto y el método eliminado no tienen referencias | |
| 8.7 | Ejecuta: `dart analyze lib/` | **0 errores** (los warnings de nivel `info` pre-existentes no son bloqueantes) | |
| 8.8 | Ejecuta: `flutter test` | Mínimo **548 passed**; los 2 fallos conocidos de `garage_options_bottom_sheet_test.dart` son pre-existentes (icon package mismatch) y no representan regresión | |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1 a 6 marcados como ✅, mas los casos criticos de las secciones 7 y 8 |
| ⚠️ Aprobado con observaciones | Maximo 2 casos fallidos de baja severidad (secciones 7C o 8 no criticos), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2, 3 o 4 marcado como ❌; o un fallo de red (7B) que deje el estado del UI inconsistente; o cualquier referencia a `hard-delete` en codigo compilable (8.5) |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
