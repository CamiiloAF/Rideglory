# Checklist de QA — Filtro automático de fecha en listado de rodadas

**Feature:** Piso automático "desde hoy" en el listado de descubrimiento de eventos
**Fases cubiertas:** Fase 02 (Flutter — presentación)
**Estado:** Pendiente de aprobacion PO

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Cuenta de usuario activa en el ambiente de desarrollo (dev flavor).
- [ ] Al menos un evento con fecha **anterior a hoy** visible en la base de datos de dev (para poder confirmar que ya no aparece).
- [ ] Al menos un evento con fecha **de hoy o posterior** en la base de datos de dev (para confirmar que sí aparece).
- [ ] Tu cuenta de usuario debe ser **organizador (owner)** de al menos un evento pasado (para verificar el flujo "Mis rodadas").
- [ ] App corriendo con el flavor `dev` en simulador o dispositivo físico.
- [ ] (Opcional, para sección 5) Proxyman o Charles Proxy configurado para interceptar tráfico del simulador en `localhost:3000`.

---

## 1. Pantalla de descubrimiento sin filtros activos

> Abre la app y navega a la pantalla principal de eventos (la que lista todas las rodadas disponibles). No apliques ningún filtro.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 1.1 | Abre la pantalla de listado de eventos sin tocar ningún filtro. | La lista carga y **no aparece ningún evento cuya fecha sea anterior a hoy**. Los eventos pasados que existen en la base de datos no son visibles. | |
| 1.2 | Desplázate por la lista completa de rodadas. | Todos los eventos mostrados tienen fecha igual o posterior a la fecha de hoy en tu zona horaria local. | |
| 1.3 | Espera a que la lista cargue completamente (sin spinner activo). | El mensaje de lista vacía aparece únicamente si no hay eventos futuros o de hoy; en ningún caso porque eventos pasados hayan desaparecido erróneamente de la vista. | |

---

## 2. Filtro manual de fecha con fecha pasada

> Desde la pantalla de listado de eventos, usa el selector de filtros para aplicar un filtro de fecha de inicio con una fecha anterior a hoy (por ejemplo, `2025-01-01`).

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 2.1 | Toca el ícono o botón de filtros en la pantalla de eventos. | Se abre el panel o pantalla de filtros. | |
| 2.2 | Selecciona una fecha de inicio **anterior a hoy** (por ejemplo, 1 de enero de 2025). | El campo de fecha de inicio muestra la fecha seleccionada. | |
| 2.3 | Aplica el filtro (toca "Aplicar" o equivalente). | La lista de eventos se actualiza y **sí muestra eventos con fecha anterior a hoy** que coincidan con el filtro. El filtro manual sobrescribe el piso automático. | |
| 2.4 | Verifica que los eventos pasados existentes en la BD de dev aparecen en el listado. | Al menos el evento pasado preparado en pre-condiciones aparece en la lista. | |

---

## 3. Limpiar filtros restaura el piso automático

> Continuando desde el escenario anterior (filtro manual de fecha pasada activo), usa la opción de limpiar o borrar los filtros.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 3.1 | Toca "Limpiar filtros", "Clear" o la X del filtro activo. | Los filtros se restablecen y el chip/indicador de filtro activo desaparece. | |
| 3.2 | Espera a que la lista se recargue. | La lista vuelve a mostrar **únicamente eventos de hoy en adelante**. Los eventos pasados que antes aparecían con el filtro manual ya no son visibles. | |
| 3.3 | Confirma que el comportamiento es idéntico al del paso 1 (sin filtros desde cero). | No hay eventos pasados en pantalla y los futuros siguen apareciendo. | |

---

## 4. Sección "Mis rodadas" — eventos pasados visibles

> Navega a la sección de "Mis rodadas" o "Mis eventos" (las rodadas donde eres organizador o participante registrado).

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 4.1 | Toca la pestaña o acceso a "Mis rodadas" desde el menú o la pantalla principal. | Se abre el listado de rodadas propias. | |
| 4.2 | Revisa si aparecen eventos con fecha anterior a hoy de los cuales eres owner. | **Los eventos pasados sí aparecen** en esta vista. El piso automático de "desde hoy" NO aplica en "Mis rodadas". | |
| 4.3 | Desplázate por la lista completa. | El historial completo de tus rodadas (pasadas y futuras) está visible sin restricción de fecha. | |

---

## 5. Casos de borde

### 5A. Lista vacía cuando no hay eventos futuros

> Usando una cuenta de prueba en un ambiente donde no existan eventos futuros programados (o simulando este estado).

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5A.1 | Abre la pantalla de descubrimiento sin filtros, en un ambiente sin eventos futuros. | La app muestra un estado vacío (mensaje o ilustración de "sin rodadas disponibles") en lugar de un error o spinner infinito. | |
| 5A.2 | Verifica que no hay crash ni excepción visible. | La UI sigue respondiendo normalmente. Puedes navegar a otras secciones sin problema. | |

### 5B. Error de red al cargar eventos

> Desactiva el Wi-Fi o la conexión de red del dispositivo/simulador y abre la pantalla de eventos.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5B.1 | Desactiva la conexión a internet y abre (o recarga) la pantalla de listado de eventos. | La app muestra un mensaje de error o estado de red no disponible. No hay crash ni pantalla en blanco. | |
| 5B.2 | Reactiva la conexión y recarga la pantalla. | La lista carga correctamente mostrando solo eventos desde hoy. | |

### 5C. Filtro de fecha exactamente hoy

> Aplica un filtro manual con fecha de inicio igual al día de hoy.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5C.1 | Abre el panel de filtros y selecciona como fecha de inicio la fecha de hoy. | El campo muestra la fecha de hoy. | |
| 5C.2 | Aplica el filtro y verifica la lista resultante. | El resultado es idéntico al de no tener filtro manual activo: se ven eventos de hoy en adelante. No hay duplicados ni comportamiento inesperado. | |

### 5D. Zona horaria distinta a UTC

> Si tienes acceso a un dispositivo o simulador con zona horaria configurada diferente a UTC (por ejemplo, UTC-5 para Colombia), realiza este caso.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5D.1 | Con el dispositivo en zona UTC-5 (hora de Colombia), abre el listado de eventos sin filtros. | La fecha enviada al backend corresponde al día local del dispositivo en UTC-5, no a la fecha UTC. Si localmente es aún 19 de junio pero en UTC ya es 20 de junio, el listado muestra eventos desde el 19 de junio. | |

---

## 6. Verificaciones tecnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a los logs de red (Proxyman/Charles) o a la consola de Flutter.

| # | Verificacion | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 6.1 | Intercepta la petición HTTP al abrir el listado sin filtros. Revisa el query param `dateFrom` en `GET /api/events`. | El valor de `dateFrom` es la fecha de hoy en formato `yyyy-MM-dd` según la zona horaria local del dispositivo (ej. `2026-06-20`). Nunca es `null` ni ausente. | |
| 6.2 | Intercepta la petición HTTP con filtro manual de fecha `2026-07-15` activo. | `dateFrom=2026-07-15` en el query string. No aparece la fecha de hoy. | |
| 6.3 | Intercepta la petición HTTP después de limpiar filtros. | `dateFrom` vuelve a ser la fecha de hoy local (igual que 6.1). No es `null` ni está ausente. | |
| 6.4 | Intercepta la petición HTTP desde la vista "Mis rodadas". | La petición va a `GET /api/events/my` (o endpoint equivalente de myEvents) **sin** parámetro `dateFrom`, o el endpoint no acepta ese parámetro. No se filtra por fecha en mis rodadas. | |
| 6.5 | Ejecuta `flutter test test/features/events/presentation/list/events_cubit_date_filter_test.dart` en la consola. | Salida: `+4: All tests passed!` Sin errores. | |
| 6.6 | Ejecuta `dart analyze lib/features/events/presentation/list/events_cubit.dart` en la consola. | Salida: `No issues found!` | |
| 6.7 | Ejecuta la suite completa `flutter test` en la consola. | 1006 tests pasados, 0 fallidos. | |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–4 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Maximo 2 casos fallidos de las secciones 5–6 de baja severidad, con ticket creado para seguimiento |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2, 3 o 4 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
