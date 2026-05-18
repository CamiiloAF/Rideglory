# PRD — Módulo de Mantenimientos

**Versión:** 1.0  
**Fecha:** 2026-05-16  
**Estado:** En revisión  
**Autor:** Generado a partir del diseño en Pencil (rideglory.pen)

---

## 1. Contexto y objetivo

El módulo de mantenimientos permite al usuario registrar servicios realizados a su moto y programar servicios futuros. El objetivo es que el usuario tenga visibilidad clara de qué mantenimientos están vencidos, cuáles se aproximan y cuáles están al día, sin tener que calcular nada manualmente.

---

## 2. Pantallas del módulo

| ID Pantalla | Nombre | Ruta go_router |
|---|---|---|
| `maintenance_list` | Mantenimientos (lista) | `/garaje/mantenimientos` |
| `maintenance_new_step1` | Nuevo Mantenimiento — Paso 1 | `/garaje/mantenimientos/nuevo/paso1` |
| `maintenance_new_step2` | Nuevo Mantenimiento — Paso 2 | `/garaje/mantenimientos/nuevo/paso2` |
| `maintenance_detail` | Detalle de Mantenimiento | `/garaje/mantenimientos/:id` |
| `maintenance_filters` | Filtros (bottom sheet) | — (modal sobre lista) |

---

## 3. Modelo de datos

### 3.1 MaintenanceModel

```dart
class MaintenanceModel {
  final String id;
  final String vehicleId;
  final MaintenanceType type;         // enum
  final MaintenanceStatus status;     // enum — calculado, no persistido
  final MaintenanceMode mode;         // completado | programado

  // Campos de COMPLETADO (solo si mode == completado)
  final DateTime? serviceDate;        // Fecha del servicio
  final int? odometerAtService;       // Odómetro al momento del servicio (km, absoluto)
  final double? cost;                 // Gasto total (COP)
  final String? workshop;             // Taller / Mecánico

  // Campos de PROGRAMADO (aplican en ambos modos si hay próximo servicio)
  final int? nextOdometer;            // Odómetro objetivo absoluto (km)
  final DateTime? nextDate;           // Fecha objetivo del próximo servicio

  // Campos comunes
  final String? notes;                // Notas / Observaciones
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 3.2 Enumeraciones

```dart
enum MaintenanceType {
  oilChange,
  brakeCheck,
  tireChange,
  preventive,
  airFilter,
  chainSprocket,
  electrical,
  other;
}

enum MaintenanceMode {
  completed,   // Servicio ya realizado
  scheduled,   // Servicio futuro pendiente
}

// IMPORTANTE: MaintenanceStatus se CALCULA en runtime. Nunca se persiste en BD.
// Solo aplica a registros con mode == programado.
enum MaintenanceStatus {
  overdue,      // Vencido — pasó la fecha o el km
  next,       // Por vencer — dentro del umbral
  upToDate,         // Sin urgencia
  // Para mode == completado, no aplica ninguno de los anteriores.
  // Se muestra con badge "Realizado" en la UI.
}
```

---

## 4. Lógica de negocio central

### 4.1 Cálculo de MaintenanceStatus

**REGLA CRÍTICA:** El cálculo de estado (`atrasado` / `próximo` / `al día`) aplica **únicamente** a registros con `mode == programado`. Los registros `completado` siempre muestran el badge "Realizado" y **no** participan en ninguna sección de estado.

```
fun calcularStatus(maintenance, currentOdometer, today):

  si maintenance.mode == completado → return "Realizado" (badge estático)

  // A partir de aquí solo para mode == programado

  estaAtrasadoPorKm   = nextOdometer != null && currentOdometer > nextOdometer
  estaAtrasadoPorFecha = nextDate != null && today > nextDate

  si (estaAtrasadoPorKm || estaAtrasadoPorFecha):
    return MaintenanceStatus.atrasado

  estaProximoPorKm   = nextOdometer != null && (nextOdometer - currentOdometer) <= UMBRAL_KM
  estaProximoPorFecha = nextDate != null && (nextDate - today).days <= UMBRAL_DIAS

  si (estaProximoPorKm || estaProximoPorFecha):
    return MaintenanceStatus.proximo

  return MaintenanceStatus.alDia
```

**Umbrales (constantes, configurables más adelante):**
- `UMBRAL_KM = 500` — km restantes para considerar "próximo"
- `UMBRAL_DIAS = 30` — días restantes para considerar "próximo"

**Casos especiales:**
- Si el registro `programado` tiene **solo fecha** (sin odómetro): se evalúa únicamente por fecha.
- Si el registro `programado` tiene **solo odómetro** (sin fecha): se evalúa únicamente por km.
- Si tiene **ambos**: es `atrasado` si cualquiera de los dos se incumple; es `próximo` si cualquiera de los dos está dentro del umbral.
- Si un registro `programado` **no tiene ni fecha ni odómetro**: no se puede calcular estado → se muestra en sección "Al día" sin badge de urgencia, con indicador visual de "sin fecha definida".

### 4.2 Auto-creación de Programado desde Completado

Cuando el usuario guarda un mantenimiento en modo **Completado** y ha llenado alguno de los campos de próximo servicio (`nextOdometer` y/o `nextDate`):

1. El backend (o cliente en caso de offline) crea automáticamente un segundo registro con:
   - `vehicleId` = mismo vehículo
   - `type` = mismo tipo
   - `mode` = `programado`
   - `nextOdometer` = valor ingresado (absoluto)
   - `nextDate` = fecha ingresada
   - `notes` = null
   - `createdAt` = ahora
2. El nuevo registro `programado` se inserta en la lista en **tiempo real** (sin necesidad de pull-to-refresh).
3. El registro `completado` original también se inserta en tiempo real en la lista.
4. Ambos registros son independientes: editar o eliminar el `completado` **no** afecta automáticamente al `programado` creado.

**Flujo de inserción en tiempo real:**
- El cubit de mantenimientos expone un stream o recalcula el estado local inmediatamente tras el guardado exitoso, antes de recibir respuesta del servidor si se usa optimistic update.
- La lista se reordena automáticamente según el status calculado.

### 4.3 Odómetro: relativo vs absoluto

- El usuario ingresa en el formulario: **"Próximos km en: 3,000"** → es un **intervalo relativo**.
- El sistema convierte a **odómetro absoluto** antes de persistir:
  - En modo `completado`: `nextOdometer = odometerAtService + intervaloKm`
  - En modo `programado`: `nextOdometer = vehicleCurrentOdometer + intervaloKm`
- En el **Detalle** se muestra el valor absoluto: "Próximo odómetro: 11,100 km".
- En la **lista** se muestra la diferencia: "3,100 km" (cuánto falta o cuánto se pasó).

---

## 5. Pantalla: Mantenimientos (Lista)

### 5.1 Estructura

```
AppBar: "Mantenimientos" | [ícono filtros] [botón + naranja]
─────────────────────────────────────────
Resumen de Mantenimientos (card)
  ├── N Servicios (total de registros del vehículo activo)
  └── $XXX,XXX Total gastado (suma de cost de todos los completado)
      └── [ícono lápiz → navega a edición rápida / reservado]
─────────────────────────────────────────
Sección ATRASADO  (solo si hay registros programado con status atrasado)
  └── Lista de MaintenanceListItem
Sección PRÓXIMAMENTE (solo si hay registros programado con status proximo)
  └── Lista de MaintenanceListItem
Sección AL DÍA (registros programado con status alDia + todos los completado)
  └── Lista de MaintenanceListItem
─────────────────────────────────────────
Empty state: si no hay ningún registro → ilustración + "Sin mantenimientos registrados" + botón "Agregar primero"
```

### 5.2 MaintenanceListItem

Cada ítem muestra:
- Ícono del tipo (color según tipo)
- Nombre del tipo (ej: "Cambio de aceite")
- Sub-texto con contexto:
  - Si `programado`: "Programado en X km · actual Y km" o "Programado para DD MMM YYYY"
  - Si `completado`: "Realizado el DD MMM YYYY · X km"
- Badge de estado (derecha):
  - `atrasado` → badge rojo "vencido"
  - `proximo` → badge amarillo "falta"
  - `alDia` → badge verde "al día" (o sin badge)
  - `completado` → sin badge de estado
- Distancia/tiempo restante (esquina derecha superior):
  - Si `programado` con km: "X,XXX km" (absoluto del próximo odómetro) → texto rojo si atrasado, amarillo si próximo, blanco si al día
  - Si `programado` con solo fecha: "DD MMM YYYY"

### 5.3 Comportamiento de la lista

- Ordenada por urgencia: primero `atrasado`, luego `proximo`, luego `alDia`, luego `completado` (por fecha desc).
- El recálculo de status se hace cada vez que la pantalla vuelve a ser visible (`onResume` / `didChangeDependencies`).
- El odómetro actual del vehículo se toma del `VehicleModel.currentOdometer` (campo ya existente en el modelo).
- Si el usuario tiene múltiples vehículos, la lista muestra los mantenimientos del **vehículo activo** seleccionado en el Garaje. Un selector de vehículo en el AppBar permite cambiar (solo aplica cuando ingresa desde el perfil a la lista de mantenimientos).

---

## 7. Pantalla: Nuevo Mantenimiento — Paso 2 (Formulario)

### 7.1 Estructura común

```
AppBar: "Nuevo Mantenimiento · Paso 2 de 2" | [botón Guardar]
Chip del tipo seleccionado (naranja, no editable aquí)
─────────────────────────────────────────
Toggle de MODO: [Completado] [Programado]
─────────────────────────────────────────
[Contenido condicional según modo]
─────────────────────────────────────────
Sección: NOTAS (opcional, compartida entre ambos modos)
─────────────────────────────────────────
Sección: PRÓXIMO MANTENIMIENTO (opcional, compartida entre ambos modos)
─────────────────────────────────────────
Botón primario: "Guardar mantenimiento"
Link secundario: Ninguno
```

### 7.2 Modo COMPLETADO — campos exclusivos

| Campo | Tipo | Requerido | Validación |
|---|---|---|---|
| Fecha del servicio | Date picker | ✅ Sí | No puede ser fecha futura. No puede ser anterior a la fecha de fabricación del vehículo. |
| Odómetro al momento del servicio | Integer input | ✅ Sí | Puede ser menor al odometro actual. Por defecto se pone el km actual del vehiculo. Si es mayor al km actual del vehiculo se debe informar que se va a editar el km del vehiculo (ya se está haciendo) y se actualiza el km real del vehiculo. |
| Gasto total | Decimal input | ❌ No | >= 0. Máx: 99,999,999. Formato COP. Si se deja vacío se guarda como null. |
| Taller / Mecánico | Text input | ❌ No | Máx 100 caracteres. |

### 7.3 Modo PROGRAMADO — campos exclusivos

El modo Programado no tiene campos de servicio. Solo muestra las secciones de Notas y Próximo Mantenimiento.

### 7.4 Sección NOTAS (ambos modos)

| Campo | Tipo | Requerido | Validación |
|---|---|---|---|
| Descripción / Observaciones | Textarea | ❌ No | Máx 500 caracteres. Placeholder: "Describe el servicio realizado, repuestos usados, observaciones..." |

### 7.5 Sección PRÓXIMO MANTENIMIENTO (ambos modos)

Esta sección es **opcional en modo Completado** y **obligatoria en modo Programado** (al menos uno de los dos campos).

| Campo | Tipo | Requerido | Validación |
|---|---|---|---|
| Próximos km en | Integer input | Condicional* | > 0. Máx: 100,000. El sistema convierte a odómetro absoluto antes de guardar. |
| Fecha programada | Date picker | Condicional* | Debe ser fecha futura (> hoy). |

**Condicional\*:** En modo `programado`, al menos uno de los dos campos (`nextOdometer` o `nextDate`) debe estar lleno para poder guardar. Si ambos están vacíos, el botón "Guardar mantenimiento" se deshabilita con mensaje: "Agrega al menos un criterio para el próximo servicio (km o fecha)."

En modo `completado`, ambos son opcionales. Si se llenan, se crea automáticamente un registro `programado` (ver §4.2).

**Sub-texto dinámico "Faltan para el servicio: X días":**
- Solo se muestra si `nextDate` está llena.
- Calcula `nextDate - hoy` en días.
- Si el resultado es negativo (fecha ya pasó): se muestra en rojo "Hace X días" — validación bloqueante (ver arriba).

### 7.6 Validaciones al guardar (Paso 2)

| Modo | Condición | Comportamiento |
|---|---|---|
| Completado | `serviceDate` vacía | Botón deshabilitado |
| Completado | `odometerAtService` vacío | Botón deshabilitado |
| Completado | `odometerAtService` > vehicle.currentOdometer + 500 | Error: "El odómetro ingresado supera el odómetro actual de tu moto" |
| Completado | `nextDate` <= hoy | Error inline: "La fecha del próximo servicio debe ser futura" |
| Programado | `nextOdometer` == null && `nextDate` == null | Botón deshabilitado + mensaje explicativo |
| Programado | `nextDate` <= hoy | Error inline: "La fecha del próximo servicio debe ser futura" |
| Programado | `nextOdometer` <= 0 | Error inline: "Ingresa un valor mayor a 0" |
| Ambos | Error de red al guardar | Snackbar: "No se pudo guardar el mantenimiento. Intenta de nuevo." |

---

## 8. Pantalla: Detalle de Mantenimiento

### 8.1 Estructura

```
AppBar: "Detalle de Mantenimiento" | [menú 3 puntos → Editar / Eliminar]
─────────────────────────────────────────
Header:
  Ícono del tipo + Nombre del tipo + Badge de modo ("Realizado" | "Programado")
  Sub-texto: nombre del vehículo + año

─────────────────────────────────────────
[Si mode == completado]
Sección "Información del servicio"
  Fecha del servicio     DD MMM YYYY
  Odómetro               X,XXX km
  Taller                 Nombre del taller (o "—" si vacío)
  Costo                  $XX,XXX COP (o "—" si vacío)

─────────────────────────────────────────
[Si notes != null]
Sección "Notas"
  Texto libre

─────────────────────────────────────────
[Si nextDate != null || nextOdometer != null]
Sección "Próxima revisión"
  Próxima fecha          DD MMM YYYY (o "—")
  Próximo odómetro       XX,XXX km (o "—")
  [Si programado] Estado badge: Atrasado / Próximo / Al día

─────────────────────────────────────────
Botones:
  [Editar] (outlined)    [Eliminar] (outlined, rojo)
```

### 8.2 Acción Eliminar

- Muestra `ConfirmationDialog`: "¿Eliminar este mantenimiento? Esta acción no se puede deshacer."
- Al confirmar: elimina el registro y navega hacia atrás con `context.pop()`.
- Si el registro fue la fuente de un auto-programado (completado con next → creó un programado), **no** se elimina automáticamente el programado asociado. Son registros independientes.

### 8.3 Acción Editar

- Navega a `/garaje/mantenimientos/:id/editar` con el formulario pre-llenado.
- Al guardar en edición, se recalcula el status y se actualiza en tiempo real en la lista.

---

## 9. Bottom Sheet: Filtros

### 9.1 Campos de filtro

| Filtro | Tipo | Opciones |
|---|---|---|
| Tipo de mantenimiento | Multi-chip select | ver enum MaintenanceType |
| Estado | Single-chip select | Todos (default), Ver enum MaintenanceStatus |
| Rango de fecha | Radio list | Este mes, Últimos 3 meses, Último año, Personalizado |

- "Personalizado" abre dos date pickers (desde / hasta).
- "Limpiar todo" resetea todos los filtros a sus valores por defecto.
- Botón "Aplicar" cierra el sheet y aplica los filtros en la lista.
- El ícono de filtros en el AppBar muestra un indicador (punto naranja) cuando hay filtros activos.

### 9.2 Comportamiento del filtro Estado

- El filtro Estado filtra **únicamente** registros `programado`. Los registros `completado` solo aparecen si el filtro de Estado es "Todos".
- Si el filtro Estado = "Atrasado": solo muestra programados con status `atrasado`.
- Si el filtro Estado = "Próximo": solo muestra programados con status `proximo`.
- Si el filtro Estado = "Al día": muestra programados con status `alDia` + todos los `completado`.

---

## 10. Widget de Mantenimiento en Garaje

Este widget vive dentro de la pantalla de detalle del vehículo en el Garaje (no es una pantalla standalone).

### 10.1 Contenido

```
[Card izquierda]                [Card derecha]
Jun 2024   ·  Hecho             Ago 2025  ·  Próximo
10,050 km                       12,450 km

[Botón full-width]
Ver historial de mantenimientos →
```

- Card izquierda: último servicio `completado` (fecha + odómetro).
- Card derecha: próximo servicio `programado` más urgente (fecha objetivo o km objetivo).
- Si no hay ningún `completado`: card izquierda muestra "Sin servicios registrados".
- Si no hay ningún `programado`: card derecha muestra "Sin próximo servicio".
- Badge de la card derecha: `Próximo` (amarillo) si status `proximo`, `Atrasado` (rojo) si `atrasado`, sin badge si `alDia`.
- Tap en cualquier card navega a `maintenance_detail` del registro correspondiente.
- Tap en "Ver historial" navega a `maintenance_list` filtrado al vehículo activo.

---

## 11. Notificaciones push (FCM)

> **Nota:** las notificaciones son parte del MVP pero se implementan en el backend. Se documentan aquí para que el contrato sea claro.

| Trigger | Mensaje | Timing |
|---|---|---|
| `nextDate` - 7 días | "Tu {tipo} está programado para el {fecha}. ¡Prepárate!" | 7 días antes |
| `nextDate` - 1 día | "Mañana es el día de tu {tipo}. ¡No lo olvides!" | 1 día antes |
| `nextDate` pasada | "Tu {tipo} está vencido. Agenda tu servicio." | Día del vencimiento |
| `nextOdometer` - 500 km | "Te faltan 500 km para tu próximo {tipo}." | Al registrar odómetro |

- Las notificaciones se cancelan automáticamente si el usuario completa el mantenimiento antes del trigger.
- El usuario puede desactivar notificaciones de mantenimiento en Perfil → Notificaciones.

---

## 12. API Contracts

### POST `/api/vehicles/:vehicleId/maintenances`

**Request body:**
```json
{
  "type": "cambioAceite",
  "mode": "completado",
  "serviceDate": "2024-06-15",
  "odometerAtService": 10050,
  "cost": 85000,
  "workshop": "Moto Center Bogotá",
  "notes": "Aceite sintético 10W-40 Motul 300V...",
  "nextKmInterval": 3000,
  "nextDate": "2024-12-15"
}
```

- `nextKmInterval`: intervalo relativo en km (el backend calcula `nextOdometer = odometerAtService + nextKmInterval`).
- Si `mode == programado`: el backend usa `vehicle.currentOdometer` para calcular `nextOdometer = currentOdometer + nextKmInterval`.
- Si el request incluye `nextKmInterval` o `nextDate` y `mode == completado`, el backend crea automáticamente el registro programado y lo retorna en el response.

**Response 201:**
```json
{
  "created": [
    { ...maintenanceCompletado },
    { ...maintenanceProgramado }   // solo si se auto-creó
  ]
}
```

### GET `/api/vehicles/:vehicleId/maintenances`

**Query params:** `mode`, `type`, `status`, `dateFrom`, `dateTo`

**Response 200:**
```json
{
  "items": [ ...MaintenanceModel[] ],
  "summary": {
    "total": 5,
    "totalCost": 847500
  }
}
```

**Nota:** El campo `status` en el response es **calculado por el cliente**, no por el backend. El backend devuelve `nextOdometer`, `nextDate` y el cliente recibe el `currentOdometer` del vehículo (ya en el estado local) para calcular el status en runtime.

### PATCH `/api/vehicles/:vehicleId/maintenances/:id`

Mismo body que POST pero todos los campos son opcionales. Solo se actualizan los campos enviados.

### DELETE `/api/vehicles/:vehicleId/maintenances/:id`

Response 204 sin body.

---

## 13. Estados de UI por pantalla

### Lista

| Estado | UI |
|---|---|
| Loading inicial | Skeleton de 3 ítems |
| Lista vacía | Empty state con ilustración + CTA "Agregar primero" |
| Lista con datos | Secciones dinámicas según status |
| Error de carga | Snackbar + botón "Reintentar" |
| Guardado exitoso (desde form) | Snackbar "Mantenimiento guardado" + nuevo ítem aparece en lista |

### Formulario (Paso 2)

| Estado | UI |
|---|---|
| Inicial | Todos los campos vacíos, botón deshabilitado |
| Campos mínimos llenos | Botón "Guardar" habilitado |
| Guardando | Botón con loading indicator, campos deshabilitados |
| Error al guardar | Snackbar de error, campos vuelven a ser editables |
| Guardado exitoso | `context.pop()` hacia la lista |

---

## 14. Fuera del alcance (MVP)

- Recordatorios por intervalo de tiempo configurable (ej: "cada 6 meses").
- Sincronización automática de odómetro desde GPS (requiere integración externa).
- Fotos adjuntas al mantenimiento (factura, repuesto).
- Exportación del historial en PDF.
- Mantenimientos compartidos entre usuarios del mismo vehículo.
- Integración con talleres (booking).
