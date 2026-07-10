# Feature: Tecnomecánica (RTM)

> Feature introducido en la iteración `tecnomecanica-rtm` (Fases 1–5).
> Documentación de cierre: Fase 6 — Calidad, regresión y documentación.
> Última actualización: 2026-07-04

---

## 1. Qué es

La **revisión técnico-mecánica (RTM o tecnomecánica)** es el documento legal colombiano que certifica que un vehículo cumple las condiciones técnicas de seguridad vial. Tiene periodicidad bianual (cada 2 años), excepto vehículos con menos de 2 años desde su matrícula original, los cuales están **exentos**.

---

## 2. Flujos principales

### 2.1 Registrar RTM por primera vez

1. Usuario navega a detalle del vehículo → badge RTM en estado `none` (sin documento).
2. Toca el badge → abre `TecnomecanicaStatusPage`.
3. Estado `empty` → muestra `DocumentEmptyState` con CTA "Registrar RTM".
4. Toca CTA → navega a `TecnomecanicaFormPage`.
5. Usuario llena: CDA, fechas inicio/vencimiento, URL del documento (opcional). **El campo `certificateNumber` fue eliminado** (commit `c07aca4`, junto con `cdaCode`).
6. Confirma → `TecnomecanicaCubit.save()` → estado `data` → regresa al detalle.

### 2.2 Ver RTM registrado

1. Badge RTM en el detalle del vehículo muestra el estado actual (verde/amarillo/rojo).
2. Toca badge → `TecnomecanicaStatusPage`.
3. Estado `data` → renderiza `SoatDataView`-equivalente via `DocumentDataView`.
4. Muestra: CDA, certificado, fechas, días restantes, banner de advertencia si expira pronto o ya expiró.

### 2.3 Editar RTM

1. En `TecnomecanicaStatusPage` → botón editar en AppBar.
2. Abre `TecnomecanicaFormPage` pre-poblado.
3. Guarda → `TecnomecanicaCubit.save()` con RTM existente (id no vacío → evento `tecnomecanica_updated`).

### 2.4 Eliminar RTM

1. En `TecnomecanicaStatusPage` → botón eliminar en AppBar.
2. Confirmación → `TecnomecanicaCubit.delete()`.
3. Estado `empty` → badge RTM vuelve a `none`.

### 2.5 Vehículo exento (< 2 años desde matrícula)

El backend retorna el RTM con una marca de exención. La UI muestra un chip de "Exento" en el badge y en la página de estado, sin mostrar alerta de vencimiento.

---

## 3. Los 4 estados del documento

| Estado (`VehicleDocumentStatus`) | Condición | Badge color | Descripción |
|---|---|---|---|
| `none` | No hay RTM registrado | Gris neutro | El vehículo no tiene RTM en la app |
| `valid` | `daysUntilExpiry > 30` | Verde | RTM vigente, más de 30 días |
| `expiringSoon` | `0 <= daysUntilExpiry <= 30` | Amarillo/naranja | RTM próximo a vencer |
| `expired` | `daysUntilExpiry < 0` | Rojo | RTM vencido |

> El estado `none` es asignado externamente (no emerge del mixin `VehicleDocumentExpiry`).
> Los estados `valid`, `expiringSoon`, `expired` son derivados por el mixin según `expiryDate`.

---

## 4. Exención para vehículos < 2 años

Los vehículos con matrícula de menos de 2 años no están obligados a presentar RTM. En la app:

- El backend no retorna RTM para esos vehículos (respuesta 404 → `Right(null)` → estado `empty`).
- El badge muestra un ícono de escudo sin estado de alerta.
- La página de estado muestra texto de exención en lugar del CTA de registro.

---

## 5. Recordatorios push

Los recordatorios siguen el mismo patrón que SOAT. El scheduler de `api-gateway` envía notificaciones push a **30 días**, **7 días** y **0 días** (día de vencimiento) antes de que expire el RTM.

| Días antes del vencimiento | Tipo de recordatorio |
|---|---|
| 30 días | `rtm_expiry_reminder_30d` |
| 7 días | `rtm_expiry_reminder_7d` |
| 0 días (día de vencimiento) | `rtm_expiry_reminder_0d` |

Los recordatorios son cancelados si el usuario registra un RTM nuevo antes del vencimiento.

---

## 6. Deep link / route

La app responde al deep link `rideglory://garage` para navegar al garaje del usuario (lista de vehículos con badges RTM y SOAT). No hay un deep link específico por vehículo o documento en esta versión.

---

## 7. Arquitectura (Clean Architecture)

```
lib/features/tecnomecanica/
├── domain/
│   ├── models/
│   │   └── tecnomecanica_model.dart       # VehicleDocumentModel + VehicleDocumentExpiry
│   ├── repository/
│   │   └── tecnomecanica_repository.dart  # Interface
│   └── usecases/
│       ├── get_tecnomecanica_usecase.dart
│       ├── save_tecnomecanica_usecase.dart
│       └── delete_tecnomecanica_usecase.dart
├── data/
│   ├── dto/
│   │   └── tecnomecanica_dto.dart         # Pattern B: extends TecnomecanicaModel
│   ├── service/
│   │   └── tecnomecanica_service.dart     # Retrofit client
│   └── repository/
│       └── tecnomecanica_repository_impl.dart
└── presentation/
    ├── cubit/
    │   └── tecnomecanica_cubit.dart       # extends VehicleDocumentCubit<TecnomecanicaModel>
    ├── pages/
    │   ├── tecnomecanica_status_page.dart
    │   └── tecnomecanica_form_page.dart
    └── widgets/
        ├── tecnomecanica_data_view.dart
        └── tecnomecanica_form_slot.dart   # usado en vehicle form
```

El cubit `TecnomecanicaCubit` extiende `VehicleDocumentCubit<TecnomecanicaModel>` (en `lib/features/vehicle_documents/`), heredando el contrato `load() → loading → data/empty/error`.

---

## 8. Contrato API

| Endpoint | Método | Descripción |
|---|---|---|
| `GET /vehicles/:id/tecnomecanica` | GET | Obtiene RTM del vehículo. 404 si no existe. |
| `POST /vehicles/:id/tecnomecanica` | POST | Crea RTM. |
| `PUT /vehicles/:id/tecnomecanica` | PUT | Actualiza RTM. |
| `DELETE /vehicles/:id/tecnomecanica` | DELETE | Elimina RTM. |

Request body (create/update): `TecnomecanicaDto.toJson()` (Pattern B — DTO extends Model).

---

## 9. Modelo de datos

```dart
class TecnomecanicaModel with VehicleDocumentExpiry implements VehicleDocumentModel {
  final String id;
  final String vehicleId;
  final String cdaName;           // Centro de diagnóstico automotor
  final DateTime startDate;
  final DateTime expiryDate;      // Base para VehicleDocumentExpiry
  final String? documentUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleDocumentKind get kind => VehicleDocumentKind.rtm;
}
```

> `cdaCode` y `certificateNumber` fueron eliminados del modelo (commit `c07aca4`, "eliminar cdaCode y certificateNumber, validar fechas en SOAT y RTM"). El commit también agregó validación de fechas en tiempo real en el formulario (`TecnomecanicaFormPage`) y modo lectura para RTM de vehículos archivados.

### Borrado de cuenta (cascada)
Al eliminar la cuenta (`DELETE /users/me`), `hardDeleteAllByOwner` en `vehicles-ms` borra (hard-delete) toda fila `Tecnomecanica` de cada vehículo del owner, dentro de la misma transacción Prisma que borra `Soat` y `Vehicle`. El `documentUrl` de la RTM se incluye en el batch best-effort de limpieza de Firebase Storage; una RTM capturada sin foto (`documentUrl: null`) no bloquea el borrado.

---

## 10. Analytics

| Evento | Cuándo |
|---|---|
| `tecnomecanica_status_viewed` | Load exitoso (estado `data`) |
| `tecnomecanica_manual_saved` | Guardado con id vacío (creación) |
| `tecnomecanica_updated` | Guardado con id no vacío (edición) |
| `tecnomecanica_deleted` | Eliminación exitosa |

---

## 11. Tests

| Archivo | Qué cubre |
|---|---|
| `test/features/tecnomecanica/data/dto/tecnomecanica_dto_test.dart` | Serialización/deserialización DTO |
| `test/features/tecnomecanica/domain/models/tecnomecanica_model_test.dart` | Modelo, mixin expiry |
| `test/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit_test.dart` | CRUD + analytics del cubit concreto |
| `test/features/vehicle_documents/domain/vehicle_document_expiry_test.dart` | Árbol de 4 estados parametrizado (soat + rtm) |
| `test/features/vehicle_documents/presentation/vehicle_document_cubit_test.dart` | Contrato base `loading→data/empty/error` y `404→empty` |
| `test/features/vehicle_documents/presentation/widgets/vehicle_document_widgets_test.dart` | Widgets genéricos compartidos |

---

## 12. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Modelo RTM + kind getter | `lib/features/tecnomecanica/domain/models/tecnomecanica_model.dart` |
| Repository interface | `lib/features/tecnomecanica/domain/repository/tecnomecanica_repository.dart` |
| Use cases | `lib/features/tecnomecanica/domain/usecases/` |
| DTO (Pattern B) | `lib/features/tecnomecanica/data/dto/tecnomecanica_dto.dart` |
| Service Retrofit | `lib/features/tecnomecanica/data/service/tecnomecanica_service.dart` |
| Repository impl (404 → Right(null)) | `lib/features/tecnomecanica/data/repository/tecnomecanica_repository_impl.dart` |
| Cubit (CRUD + analytics) | `lib/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart` |
| Page de status | `lib/features/tecnomecanica/presentation/pages/tecnomecanica_status_page.dart` |
| Page de formulario | `lib/features/tecnomecanica/presentation/pages/tecnomecanica_form_page.dart` |
| Slot RTM en vehicle form | `lib/features/tecnomecanica/presentation/widgets/tecnomecanica_form_slot.dart` |
| Cubit base abstracto | `lib/features/vehicle_documents/presentation/cubit/vehicle_document_cubit.dart` |
| Endpoint | `lib/core/http/api_routes.dart` (`vehicleTecnomecanica(id)`) |
| Spec backend | `vehicles-ms/src/vehicles/tecnomecanica.service.spec.ts` |
| Spec scheduler | `api-gateway/src/scheduler/notification-scheduler.service.spec.ts` |
