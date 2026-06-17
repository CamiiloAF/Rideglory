# Checklist de QA — Archivado y restauración de vehículos

**Feature:** Archivar / restaurar vehículos desde el garaje  
**Fases cubiertas:** Fase 1 (backend soft-delete) + Fase 3 (Flutter archivar/restaurar) + Detalle read-only  
**Estado:** Pendiente de aprobación PO

---

## Pre-condiciones

Antes de empezar, asegúrate de tener en la cuenta de prueba:

- [ ] Al menos **3 vehículos activos** registrados en el garaje
- [ ] Uno de ellos debe estar marcado como **vehículo principal**
- [ ] Al menos uno de los vehículos tiene **SOAT registrado**
- [ ] Al menos uno de los vehículos tiene **RTM (Tecnomecánica) registrada**
- [ ] Al menos uno de los vehículos tiene **registros de mantenimiento**
- [ ] La app conectada al backend (modo dev o prod, con internet)

---

## 1. Menú contextual de vehículo activo

> Abre el garaje y toca los tres puntos (⋮) de cualquier vehículo activo.

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 1.1 | Abrir menú ⋮ de un vehículo activo que **NO** es el principal | Aparecen las opciones: "Marcar como principal", "Editar", "Agregar mantenimiento", "Archivar" | |
| 1.2 | Abrir menú ⋮ del vehículo **principal** | Aparecen las opciones: "Editar", "Agregar mantenimiento", "Archivar" (sin "Marcar como principal") | |
| 1.3 | Verificar que **no aparece** la opción "Eliminar" en el menú de vehículos activos | La opción "Eliminar" no existe en el menú | |

---

## 2. Flujo: Archivar un vehículo activo

> Abre el garaje, toca ⋮ sobre un vehículo activo que **NO** es el principal, y toca "Archivar".

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 2.1 | Tocar "Archivar" en el menú | Aparece un diálogo de confirmación con título "Archivar vehículo" y un botón naranja "Archivar" | |
| 2.2 | Tocar **"Cancelar"** en el diálogo | El diálogo se cierra, el vehículo sigue en la lista activa, no ocurre nada más | |
| 2.3 | Tocar "Archivar" nuevamente y confirmar con el botón naranja | El menú y el diálogo se cierran, aparece un snackbar "Vehículo archivado" | |
| 2.4 | Observar la lista activa del garaje inmediatamente después | El vehículo archivado **desaparece** de la lista activa sin recargar la página | |
| 2.5 | Observar la parte inferior del garaje | Aparece la sección "ARCHIVADOS" con el contador indicando "1" | |

---

## 3. Flujo: Sección "Archivados" en el garaje

> Con al menos un vehículo archivado, observa la sección en la parte inferior del garaje.

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 3.1 | Observar el garaje sin vehículos archivados (antes de archivar ninguno) | La sección "ARCHIVADOS" **no se muestra** en absoluto | |
| 3.2 | Con 1 vehículo archivado, ver el header de la sección | Se muestra "ARCHIVADOS" con badge "1"; los vehículos archivados **no son visibles** (sección colapsada por defecto) | |
| 3.3 | Tocar el header "ARCHIVADOS" | La sección se expande y muestra la tarjeta del vehículo archivado (con apariencia visual diferenciada) | |
| 3.4 | Archivar un segundo vehículo y volver al garaje | El contador del header aumenta a "2"; ambos vehículos aparecen al expandir | |
| 3.5 | Tocar el header "ARCHIVADOS" cuando está expandido | La sección se colapsa y los vehículos archivados dejan de verse | |

---

## 4. Flujo: Ver detalle de un vehículo archivado

> Expande la sección "ARCHIVADOS" y toca la tarjeta de un vehículo archivado (no el ⋮).

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 4.1 | Tocar la tarjeta de un vehículo archivado | Navega a la pantalla de detalle del vehículo | |
| 4.2 | Observar el header del detalle | Se muestra un badge visible que indica "Vehículo Archivado" | |
| 4.3 | Buscar el botón "Editar" en el detalle | El botón "Editar" **no aparece** en ninguna parte de la pantalla | |
| 4.4 | Buscar el botón/FAB "Agregar mantenimiento" | El botón para agregar mantenimiento **no aparece** | |
| 4.5 | Ver el historial de mantenimientos existentes | Los registros son visibles, pero **no hay opción de borrar** ni deslizar para editar | |
| 4.6 | Ver la tarjeta de SOAT (vehículo con SOAT registrado) | Se muestran los datos (aseguradora, póliza, fechas) sin badge de estado ("Vigente", "Vencido", etc.) y sin indicador de días restantes | |
| 4.7 | Tocar la tarjeta de SOAT en modo archivado | La tarjeta **no es tappable** / no navega a ninguna pantalla | |
| 4.8 | Ver la tarjeta de RTM (vehículo con RTM registrada) | Se muestran los datos sin badge de vigencia ni días restantes | |
| 4.9 | Tocar la tarjeta de RTM en modo archivado | La tarjeta **no es tappable** | |

---

## 5. Flujo: Restaurar un vehículo archivado

> Desde el garaje, expande la sección "ARCHIVADOS" y toca los tres puntos (⋮) de un vehículo archivado.

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5.1 | Tocar ⋮ sobre un vehículo archivado | Aparece un menú con **únicamente** la opción "Restaurar" (sin Editar, sin Agregar mantenimiento) | |
| 5.2 | Tocar "Restaurar" | El menú se cierra, aparece un snackbar "Vehículo restaurado" | |
| 5.3 | Observar la lista activa del garaje | El vehículo restaurado **aparece de inmediato** en la lista activa sin recargar | |
| 5.4 | Observar el contador de la sección "ARCHIVADOS" | El contador disminuyó en 1; si era el único, la sección desaparece completamente | |

---

## 6. Casos de borde

### 6A. Archivar el vehículo principal

> Abre el menú ⋮ del vehículo marcado como principal y archívalo.

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 6.1 | Archivar el vehículo principal teniendo otros vehículos activos | El vehículo principal pasa a archivados; **otro vehículo activo es promovido automáticamente** como principal (aparece el badge de principal en otro vehículo) | |
| 6.2 | Verificar que el nuevo principal se refleja inmediatamente | Sin recargar la pantalla, la card del nuevo principal muestra el badge correspondiente | |

### 6B. Intentar archivar el único vehículo activo

> Con un solo vehículo activo en el garaje, intenta archivarlo.

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 6.3 | Archivar el único vehículo activo | *(Verificar comportamiento: ¿el sistema lo permite o muestra un error? Documentar lo observado)* | |

### 6C. Vehículo archivado sin SOAT ni RTM registrados

> Archiva un vehículo que no tiene SOAT ni RTM, y abre su detalle.

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 6.4 | Ver el detalle de un vehículo archivado sin documentos | La pantalla no muestra error; las tarjetas de SOAT y RTM muestran el estado vacío habitual | |

### 6D. Persistencia tras cerrar y reabrir la app

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 6.5 | Archivar un vehículo, cerrar la app completamente y volver a abrirla | El vehículo sigue archivado; aparece en la sección "ARCHIVADOS" (los datos provienen del backend) | |
| 6.6 | Restaurar un vehículo, cerrar la app completamente y volver a abrirla | El vehículo restaurado aparece en la lista activa | |

---

## 7. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a la base de datos o logs del backend.

| # | Verificación | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 7.1 | Después de archivar un vehículo, consultar la DB | El campo `isArchived = true`; el vehículo **no fue eliminado** de la tabla | |
| 7.2 | Verificar que los mantenimientos del vehículo archivado siguen en la DB | Los registros de mantenimiento existen y están intactos | |
| 7.3 | Después de restaurar, consultar la DB | El campo `isArchived = false` | |
| 7.4 | Verificar que al restaurar **no se hace un GET /api/vehicles/my** adicional | En los logs de red, el flujo de restaurar solo hace un PATCH, sin GET posterior | |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos 1–6 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad, con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 2, 4 o 5 marcado como ❌ |

**Revisado por:** ___________________  
**Fecha:** ___________________  
**Resultado:** ___________________  
**Observaciones:** ___________________
