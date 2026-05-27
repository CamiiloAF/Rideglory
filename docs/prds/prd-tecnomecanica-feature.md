# PRD — Tecnomecánica (RTM): visualizar, registrar y recordar vencimientos

**Tipo:** Feature nuevo + refactor de abstracción compartida con SOAT
**Prioridad:** Media-alta (paridad funcional con SOAT; valor directo al rider)
**Estimado:** 1 iteración (~4–5 días de desarrollo)
**Fecha de creación:** 2026-05-27
**Depende de:** SOAT feature (iter-2) terminado y estable.
**Relacionado con:** OCR auto-fill (iter-7 propuesta) — esta iteración NO incluye OCR para RTM; queda para una futura.

---

## 1. Problema

El rider hoy registra su SOAT en la app y recibe recordatorios (30 días, 7 días, día del vencimiento), pero la **revisión técnico-mecánica y de emisiones contaminantes (RTM, "tecnomecánica")** —que también es obligatoria en Colombia— no tiene representación. El usuario debe acordarse manualmente de cuándo vence, y la app está ciega al respecto.

La tecnomecánica comparte casi todas las características operativas con el SOAT:
- Documento físico/digital con fecha de inicio y vencimiento.
- Vigencia anual (en el caso general).
- Un identificador único (número de certificado).
- Un emisor (CDA — Centro de Diagnóstico Automotor — en lugar de aseguradora).
- Misma necesidad de recordatorios escalonados y badge de estado en el vehículo.

Construirla como copia literal del feature SOAT generaría duplicación grave en frontend (cubits, páginas, widgets) y backend (servicio, controlador, scheduler). El objetivo de esta iteración es **doble**: shippear tecnomecánica funcional y, al hacerlo, **extraer una abstracción compartida `VehicleDocument`** que cubra ambos casos y cualquier documento futuro con la misma forma (p.ej. tarjeta de propiedad si se quisiera, licencia de conducir, etc.).

---

## 2. Objetivo

1. Permitir al rider **registrar, ver y actualizar** la tecnomecánica de cada vehículo, igual que hoy hace con el SOAT.
2. Mostrar **badge de estado** (sin RTM / vigente / por vencer / vencida) en el detalle del vehículo.
3. Enviar **recordatorios push** 30 días, 7 días y el día del vencimiento.
4. Listar las notificaciones de RTM en el centro de notificaciones existente.
5. **Refactor:** unificar SOAT y RTM bajo un modelo compartido `VehicleDocument`, reutilizando widgets, lógica de estado, scheduler y rutas. Tras la iteración, agregar un tercer tipo de documento debe ser una tarea de horas, no de días.

**No-objetivos:**
- OCR auto-fill de la tecnomecánica (queda para iteración futura, post iter-7 con la lección aprendida del parser SOAT).
- Reglas especiales de exención (motos nuevas <2 años sin RTM obligatoria): se documenta como dato informativo en UI, no se enforza en backend.
- Inspección "histórica" — solo se guarda el certificado vigente (igual que SOAT hoy).

---

## 3. Decisiones técnicas clave

### 3.1 Modelo de datos compartido vs. tablas separadas (backend)

**Decisión:** **tablas separadas** (`Soat` y `Tecnomecanica`) en `vehicles-ms`, **no** una tabla genérica `VehicleDocument` con campo `type`.

**Razón:** los campos específicos divergen lo suficiente (`insurer` vs `cdaName`, `policyNumber` vs `certificateNumber`) como para que una tabla única con campos opcionales degrade la integridad. Además, una tabla compartida obligaría a migrar los datos de SOAT existentes, riesgo innecesario por una ganancia mínima. La abstracción compartida se hace en **Flutter (frontend)** y en la **interfaz de servicios HTTP del backend**, no en el esquema de base de datos.

### 3.2 Abstracción compartida en Flutter

Se introduce un módulo nuevo `lib/features/vehicle_documents/` con la lógica genérica, y cada documento concreto (SOAT, RTM) se reduce a una capa muy fina que parametriza al genérico.

```
lib/features/vehicle_documents/
├── domain/
│   ├── models/
│   │   ├── vehicle_document_model.dart       # interfaz/abstract
│   │   ├── vehicle_document_status.dart      # enum compartido (none/valid/expiringSoon/expired)
│   │   └── vehicle_document_kind.dart        # enum: soat, tecnomecanica
│   ├── repository/
│   │   └── vehicle_document_repository.dart  # interfaz genérica
│   └── usecases/
│       ├── get_vehicle_document_usecase.dart
│       └── save_vehicle_document_usecase.dart
├── presentation/
│   ├── cubit/
│   │   └── vehicle_document_cubit.dart       # genérico, parametrizado por kind
│   └── widgets/                              # widgets reutilizables (validity card, badge,
│       ├── document_validity_card.dart       # status row, document section, etc.)
│       ├── document_status_badge.dart
│       ├── document_detail_row.dart
│       ├── document_section_header.dart
│       └── document_empty_state.dart

lib/features/soat/                # se refactoriza para usar vehicle_documents/
└── (capa fina: SoatModel implements VehicleDocumentModel; SoatRepository
   extends VehicleDocumentRepository; widgets de SOAT pasan a ser thin wrappers
   o desaparecen si son idénticos al genérico)

lib/features/tecnomecanica/       # NUEVO
└── (espejo exacto de soat/, pero usando los widgets y cubit genéricos)
```

**Regla:** ningún widget se duplica entre `soat/` y `tecnomecanica/`. Si un widget tiene texto específico ("SOAT" vs "Tecnomecánica"), se parametriza con `VehicleDocumentKind` y se busca el copy en `app_es.arb` por clave compuesta (`document_<kind>_title`, etc.) o vía mapper.

### 3.3 Modelo de dominio

```dart
abstract class VehicleDocumentModel {
  String get id;
  String get vehicleId;
  DateTime? get startDate;
  DateTime get expiryDate;
  String? get documentUrl;
  DateTime? get createdAt;
  DateTime? get updatedAt;
  VehicleDocumentKind get kind;

  // Lógica compartida (calculada, igual para SOAT y RTM)
  VehicleDocumentStatus get status;
  int get daysUntilExpiry;
}

class SoatModel implements VehicleDocumentModel {
  // ... campos existentes + policyNumber + insurer
  @override VehicleDocumentKind get kind => VehicleDocumentKind.soat;
}

class TecnomecanicaModel implements VehicleDocumentModel {
  // ... campos comunes + certificateNumber + cdaName + cdaCode (opcional)
  @override VehicleDocumentKind get kind => VehicleDocumentKind.tecnomecanica;
}
```

La lógica de `status` y `daysUntilExpiry` vive en un mixin o helper `VehicleDocumentExpiryLogic` para evitar duplicarla.

### 3.4 HTTP/Retrofit

Dos servicios distintos (`SoatService`, `TecnomecanicaService`) — Retrofit no se beneficia de generalizar a un cliente único porque las rutas son distintas. Pero **ambos siguen el mismo contrato semántico** (GET por vehicleId, POST con payload):

```
POST   /api/vehicles/:vehicleId/soat
GET    /api/vehicles/:vehicleId/soat
POST   /api/vehicles/:vehicleId/tecnomecanica          # NUEVO
GET    /api/vehicles/:vehicleId/tecnomecanica          # NUEVO
```

### 3.5 Backend (rideglory-api)

**`vehicles-ms`:**
- Nueva tabla Prisma `Tecnomecanica` (espejo de `Soat`):
  ```prisma
  model Tecnomecanica {
    id                String   @id @default(uuid())
    vehicleId         String   @unique
    certificateNumber String
    startDate         DateTime
    expiryDate        DateTime
    cdaName           String
    cdaCode           String?
    documentUrl       String?
    createdAt         DateTime @default(now())
    updatedAt         DateTime @updatedAt
  }
  ```
- Nuevo `TecnomecanicaService` (espejo de `SoatService`).
- Endpoints MS pattern + RPC para que api-gateway consulte vencimientos.

**`api-gateway`:**
- `vehicles.controller.ts` agrega rutas REST para tecnomecánica.
- `create-tecnomecanica.dto.ts` (espejo de `create-soat.dto.ts`).
- `notification-scheduler.service.ts` agrega tres crons (30d/7d/0d) para tecnomecánica reutilizando el helper actual `sendSoatReminders` extraído como genérico `sendDocumentExpiryReminders(kind, days, notificationType)`.
- Nuevos `NotificationType`: `TECNOMECANICA_30D`, `TECNOMECANICA_7D`, `TECNOMECANICA_DAY_OF`.

**`notifications-ms`:**
- Nada nuevo a nivel modelo — el patrón actual ya soporta tipos adicionales.

### 3.6 Datos colombianos relevantes (para parser de copy y validaciones)

- **CDAs** (Centros de Diagnóstico Automotor) — no es un universo cerrado pequeño como las aseguradoras del SOAT; hay cientos en Colombia. Por tanto se captura el campo como **texto libre** con sugerencia (no lookup obligatorio).
- **Número de certificado RTM:** patrón típico de 11–14 caracteres alfanuméricos. Se valida formato básico (no vacío, ≤20 chars) sin regex estricta.
- **Vigencia:** por defecto 1 año (igual que SOAT). Algunos vehículos de transporte público tienen vigencia 6 meses, pero el caso de uso del MVP es motos particulares — vigencia anual.
- **Exención por antigüedad:** mostrar nota informativa cuando la moto tenga <2 años desde `purchaseDate` ("Los vehículos nuevos no requieren RTM durante los primeros 2 años, pero puedes registrarla si ya la tienes"). No bloquea ni enforza.

---

## 4. Criterios de aceptación

### Frontend (Flutter)

- [ ] Módulo `lib/features/vehicle_documents/` creado con interfaz `VehicleDocumentModel`, cubit genérico, widgets reutilizables y enum `VehicleDocumentKind`.
- [ ] Feature `soat/` refactorizado: `SoatModel implements VehicleDocumentModel`; widgets compartidos consumidos desde `vehicle_documents/widgets/`; el comportamiento existente del SOAT se preserva idéntico (regresión cero).
- [ ] Feature `tecnomecanica/` creado: páginas `TecnomecanicaUploadPage`, `TecnomecanicaManualCapturePage`, `TecnomecanicaConfirmationPage`, `TecnomecanicaStatusPage` — todas reutilizando los widgets genéricos.
- [ ] Detalle del vehículo muestra **dos badges**: uno SOAT, otro RTM, cada uno con sus 4 estados (sin / vigente / por vencer / vencido).
- [ ] Cada badge es tap-able y navega al flujo correspondiente.
- [ ] Recordatorios push de RTM aparecen en el centro de notificaciones con icono y copy correctos.
- [ ] Tap de notificación RTM navega al detalle del vehículo (igual que SOAT — depende de iter-1 deep links si está en flight).
- [ ] `app_es.arb` actualizado con strings RTM (`tecnomecanica_*`) y strings genéricos (`document_status_valid`, `document_status_expired`, etc.) si se decide unificar.
- [ ] Sin nuevos warnings de `dart analyze`; `flutter test` al 100%.

### Backend (rideglory-api)

- [ ] Migración Prisma de `vehicles-ms` con tabla `Tecnomecanica` aplicada (corrida primero local, luego en remoto tras validación humana — regla del proyecto).
- [ ] `TecnomecanicaService`, controller MS y DTOs implementados con tests unitarios.
- [ ] Rutas REST en api-gateway: `POST/GET /api/vehicles/:vehicleId/tecnomecanica` con Firebase Auth guard.
- [ ] `notification-scheduler.service.ts` refactorizado: método genérico `sendDocumentExpiryReminders` que cubre SOAT y RTM; tres crons nuevos para RTM (30d/7d/0d) en timezone `America/Bogota`.
- [ ] Tres nuevos `NotificationType` añadidos.
- [ ] Tests `notifications.service.spec.ts` actualizados; nuevos tests `tecnomecanica.service.spec.ts` y crons RTM.

### Tests

- [ ] Unit: lógica de status (4 estados) cubierta a nivel de interfaz `VehicleDocumentModel` con cases para SOAT y RTM.
- [ ] Unit: cubit genérico cubierto con un test parametrizado por kind.
- [ ] Widget: status badge, validity card y empty state probados una sola vez (no por feature).
- [ ] Backend: cron RTM con fixtures de fechas en 30d/7d/0d/otros.

### Docs

- [ ] `docs/features/tecnomecanica.md` (nuevo) — describe el feature, sus pantallas y el patrón compartido.
- [ ] `docs/features/soat.md` actualizado para reflejar el refactor.
- [ ] `CLAUDE.md` agrega `tecnomecanica` a la tabla de features y menciona la abstracción `vehicle_documents/`.
- [ ] `rideglory-api/docs/features/` (si existe) — endpoint nuevo documentado.

---

## 5. Plan de migración del SOAT actual (riesgo crítico)

El refactor de SOAT a `vehicle_documents/` es la parte más riesgosa porque puede romper un feature ya en producción. Reglas:

1. **El refactor de SOAT va primero**, antes de tocar RTM. Sin él, RTM no se puede construir limpio.
2. **Todos los tests existentes del SOAT deben seguir pasando** sin modificación de comportamiento esperado. Si un test requiere cambiar su acceptance, es señal de regresión.
3. **Smoke test manual** del flujo SOAT completo en dispositivo real antes de mergear (subida, manual, status, badge en detalle vehículo, recordatorios disparados a mano vía seed).
4. La PR del refactor SOAT puede ir separada de la PR de RTM si el tamaño lo justifica (≥40 archivos según política del proyecto).

---

## 6. Riesgos

| Riesgo | Mitigación |
|---|---|
| Refactor de SOAT introduce regresión silenciosa | Tests existentes del SOAT corren sin cambios + smoke test manual obligatorio en DoD |
| Sobre-abstracción prematura (KISS) | Solo se generaliza lo que tiene ≥2 usos reales hoy (SOAT + RTM); no se diseña para hipotéticos futuros documentos |
| Diferencias semánticas SOAT/RTM olvidadas | El enum `VehicleDocumentKind` se usa para parametrizar copy y rutas; cada page concreta valida sus campos específicos en su propio form cubit |
| Scheduler de notificaciones rompe envíos de SOAT existentes | El método genérico mantiene la firma exacta del helper actual de SOAT; tests del cron SOAT corren sin cambios |
| Migración Prisma falla en deploy | Aplicar migración local primero, validación humana, luego remoto (regla del proyecto) |

---

## 7. Fuera de alcance (futuras iteraciones)

- OCR auto-fill de tecnomecánica (iteración aparte tras evaluar iter-7 SOAT en producción).
- Inspección histórica (guardar certificados anteriores).
- Integración con APIs de CDAs (si existieran) para autocompletar el certificado.
- Reglas de exención automatizadas (vehículos nuevos, vehículos eléctricos con régimen distinto).
- Generalización a un tercer documento (tarjeta de propiedad, etc.) — solo si surge una necesidad real.
