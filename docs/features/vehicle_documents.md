# Documentación del Feature: Vehicle Documents (base compartida)

> Última actualización: 2026-07-04
> Alcance: `lib/features/vehicle_documents/`

---

## Tabla de contenido

1. [Visión general](#1-visión-general)
2. [Modelo de dominio](#2-modelo-de-dominio)
3. [Arquitectura por capas](#3-arquitectura-por-capas)
   - 3.1 [Domain](#31-domain)
   - 3.2 [Presentation](#32-presentation)
4. [Cubit base y estados](#4-cubit-base-y-estados)
5. [Los 4 estados del documento](#5-los-4-estados-del-documento)
6. [Widgets genéricos compartidos](#6-widgets-genéricos-compartidos)
7. [Cómo SOAT y RTM extienden esta base](#7-cómo-soat-y-rtm-extienden-esta-base)
8. [Patrones y trampas conocidas](#8-patrones-y-trampas-conocidas)
9. [Archivos clave de referencia rápida](#9-archivos-clave-de-referencia-rápida)

---

## 1. Visión general

`vehicle_documents/` es una **abstracción compartida sin pantallas propias**: no tiene rutas, no se navega directamente a él, y no expone un `Repository`/`Service`/`DTO`. Existe únicamente para eliminar duplicación entre features que gestionan un documento legal de vehículo con fecha de vencimiento — hoy **SOAT** (`lib/features/soat/`) y **Tecnomecánica/RTM** (`lib/features/tecnomecanica/`).

Nació en la **Fase 1 de la iteración de tecnomecánica**: al construir RTM se extrajo de SOAT la lógica que ambos documentos necesitan igual:
1. **Cálculo de vigencia** (`daysUntilExpiry`, `documentStatus`) a partir de una `expiryDate` — mixin `VehicleDocumentExpiry`.
2. **Ciclo de vida del cubit** (`loading → data/empty/error`, 404 → "no existe registro") — clase base abstracta `VehicleDocumentCubit<T>`.
3. **Presentación genérica** (vista de estado, vista de datos, empty state, card de vigencia, fila de detalle, header de sección) — widgets parametrizados por tipo.

Cada documento concreto (SOAT, RTM, y cualquier futuro documento) sigue teniendo su **propio** `Model`, `Repository`, `Service`, `DTO`, `Cubit` concreto y páginas — este feature solo aporta el contrato base y el andamiaje de UI reutilizable. No tiene tests de integración propios más allá de los unitarios de mixin/cubit/widgets (ver `test/features/vehicle_documents/`).

---

## 2. Modelo de dominio

### `VehicleDocumentModel` (abstract class)
> `lib/features/vehicle_documents/domain/vehicle_document_model.dart`

```dart
abstract class VehicleDocumentModel with VehicleDocumentExpiry {
  String get id;
  String get vehicleId;

  @override
  DateTime get expiryDate;

  @override
  int get daysUntilExpiry;

  @override
  VehicleDocumentStatus get documentStatus;
}
```

Contrato mínimo que todo documento legal debe cumplir: identidad (`id`, `vehicleId`) + fecha de vencimiento. Los getters de vigencia se re-declaran aquí (con `@override`) para que el tipo estático del contrato los exponga, pero su implementación real vive en el mixin.

### `VehicleDocumentExpiry` (mixin)
> `lib/features/vehicle_documents/domain/vehicle_document_expiry.dart`

```dart
mixin VehicleDocumentExpiry {
  DateTime get expiryDate;   // el implementor debe exponerlo

  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);      // medianoche, sin hora
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  VehicleDocumentStatus get documentStatus {
    final days = daysUntilExpiry;
    if (days < 0) return VehicleDocumentStatus.expired;
    if (days <= 30) return VehicleDocumentStatus.expiringSoon;
    return VehicleDocumentStatus.valid;
  }
}
```

Puro Dart, sin dependencia de Flutter ni del resto de la app — testeable de forma aislada (`test/features/vehicle_documents/domain/vehicle_document_expiry_test.dart`, árbol de 4 estados parametrizado sobre SOAT y RTM). Umbral fijo: **30 días** para `expiringSoon`; negativo para `expired`.

> El mixin **nunca** retorna `VehicleDocumentStatus.none` — ese valor se asigna externamente (en la capa que sabe que "no hay documento registrado", normalmente al mapear 404 → `empty`), nunca se deriva de una fecha.

### `VehicleDocumentStatus` (enum)
> `lib/features/vehicle_documents/domain/vehicle_document_status.dart`

```dart
enum VehicleDocumentStatus { valid, expiringSoon, expired, none }
```

### `VehicleDocumentKind` (enum)
> `lib/features/vehicle_documents/domain/vehicle_document_kind.dart`

```dart
enum VehicleDocumentKind { soat, rtm }
```

Identifica de qui tipo es un documento cuando se necesita lógica polimórfica (p. ej. un badge genérico que recibe cualquier `VehicleDocumentModel` y decide ícono/copy según `kind`). Al agregar un documento nuevo, se agrega su valor aquí.

---

## 3. Arquitectura por capas

### 3.1 Domain

```
lib/features/vehicle_documents/domain/
├── vehicle_document_expiry.dart   (mixin: daysUntilExpiry, documentStatus)
├── vehicle_document_kind.dart     (enum: soat, rtm)
├── vehicle_document_model.dart    (abstract class — contrato base; re-exporta kind y status)
└── vehicle_document_status.dart   (enum: valid, expiringSoon, expired, none)
```

No hay `Repository` ni `UseCase` en esta capa: cada documento concreto define los suyos contra su propio backend endpoint (`/vehicles/{id}/soat`, `/vehicles/{id}/tecnomecanica`, etc.). Este feature no hace I/O.

### 3.2 Presentation

```
lib/features/vehicle_documents/presentation/
├── cubit/
│   └── vehicle_document_cubit.dart       (VehicleDocumentCubit<T> — abstracto)
└── widgets/
    ├── status_view.dart                  (DocumentStatusView<C, T> — scaffold + AppBar + BlocBuilder)
    ├── status_view_error_body.dart       (StatusViewErrorBody — cuerpo de error + reintentar)
    ├── data_view.dart                    (DocumentDataView<T> — hero + detalles + acciones)
    ├── data_view_hero_card.dart          (DataViewHeroCard — ícono/título/chip de días)
    ├── data_view_details_card.dart       (DataViewDetailsCard — contenedor de DocumentDetailRow)
    ├── data_view_warning_banner.dart     (DataViewWarningBanner — aviso bajo el hero)
    ├── detail_row.dart                   (DocumentDetailRow — fila label/value)
    ├── empty_state.dart                  (DocumentEmptyState — ícono + título + subtítulo + CTA)
    ├── section_header.dart               (DocumentSectionHeader — ícono + título uppercase + trailing)
    ├── validity_card.dart                (DocumentValidityCard — despacha según fechas)
    ├── validity_card_pending.dart        (ValidityCardPending — fechas aún no definidas)
    ├── validity_card_invalid_dates.dart  (ValidityCardInvalidDates — start >= expiry)
    ├── validity_card_expired.dart        (ValidityCardExpired — días < 0)
    └── validity_card_valid.dart          (ValidityCardValid — vigente, incluye "vence hoy")
```

No hay capa `data/` en este feature: cada documento concreto trae su propio DTO/Service/RepositoryImpl.

---

## 4. Cubit base y estados

### `VehicleDocumentCubit<T extends VehicleDocumentModel>`
> `lib/features/vehicle_documents/presentation/cubit/vehicle_document_cubit.dart`

```dart
abstract class VehicleDocumentCubit<T extends VehicleDocumentModel>
    extends Cubit<ResultState<T>> {
  VehicleDocumentCubit() : super(const ResultState.initial());

  Future<void> load(String vehicleId);
}
```

Es deliberadamente mínimo: solo fija el tipo de estado (`ResultState<T>`) y el contrato `load(vehicleId)`. **No** implementa el manejo de 404 ni analytics — eso lo hace cada subclase concreta (`SoatCubit`, `TecnomecanicaCubit`), porque cada una invoca su propio use case y necesita loguear sus propios eventos.

**Patrón que replican las subclases concretas** (ver `TecnomecanicaCubit.load` como referencia):

```dart
Future<void> load(String vehicleId) async {
  emit(const ResultState.loading());
  final result = await _getUseCase(vehicleId);   // Either<DomainException, T?>
  result.fold(
    (error) => emit(ResultState.error(error: error)),
    (doc) {
      if (doc == null) {
        emit(const ResultState.empty());          // 404 desde el backend → Right(null) en el repo
      } else {
        emit(ResultState.data(data: doc));
      }
    },
  );
}
```

El mapeo **404 → `Right(null)` → `ResultState.empty()`** ocurre en dos saltos:
1. El `RepositoryImpl` concreto (`SoatRepositoryImpl`, `TecnomecanicaRepositoryImpl`) atrapa `DioException` con `statusCode == 404` y retorna `Right(null)` en vez de `Left`.
2. El cubit concreto interpreta `null` como "no hay documento registrado" y emite `empty` (no `error`).

Las subclases también agregan `save()` y `delete()` — no forman parte del contrato base porque no todos los futuros documentos necesariamente los tendrán con la misma firma, pero en la práctica SOAT y RTM los implementan de forma casi idéntica (emitir `loading` → invocar use case → `data`/`empty` en éxito, `error` en fallo, logueo de analytics propio del feature).

Test de contrato: `test/features/vehicle_documents/presentation/vehicle_document_cubit_test.dart` — verifica el ciclo `loading → data/empty/error` y el mapeo `404 → empty` de forma genérica (fake cubit).

---

## 5. Los 4 estados del documento

| Estado (`VehicleDocumentStatus`) | Condición | Quién lo asigna |
|---|---|---|
| `none` | No hay documento registrado para el vehículo | Externamente, cuando `load()` recibe `null` (404) — **no** lo calcula el mixin |
| `valid` | `daysUntilExpiry > 30` | `VehicleDocumentExpiry.documentStatus` |
| `expiringSoon` | `0 <= daysUntilExpiry <= 30` | `VehicleDocumentExpiry.documentStatus` |
| `expired` | `daysUntilExpiry < 0` | `VehicleDocumentExpiry.documentStatus` |

En términos de `ResultState<T>` del cubit, esto se traduce así:

| `ResultState<T>` | `VehicleDocumentStatus` correspondiente |
|---|---|
| `Empty` | `none` (sin documento) |
| `Data(doc)` donde `doc.documentStatus == valid` | `valid` |
| `Data(doc)` donde `doc.documentStatus == expiringSoon` | `expiringSoon` |
| `Data(doc)` donde `doc.documentStatus == expired` | `expired` |
| `Error` | (sin estado de documento — error de carga, se muestra `StatusViewErrorBody`) |

---

## 6. Widgets genéricos compartidos

Todos son `StatelessWidget`, sin acceso a HTTP ni a Cubits concretos (excepto `DocumentStatusView`, que sí conoce el tipo del cubit vía genérico `C`). Reciben todo el copy/color/ícono por parámetro — **cero strings ni colores hardcodeados por documento**; el feature concreto (SOAT/RTM) es responsable de pasar `context.l10n.<key>` y el color según su propia paleta.

### `DocumentStatusView<C extends VehicleDocumentCubit<T>, T extends VehicleDocumentModel>`
Scaffold completo de la pantalla de estado: `AppBar` (con `actions` opcionales solo visibles en estado `Data`, vía `BlocBuilder`) + cuerpo que despacha según `ResultState<T>`:
- `Initial`/`Loading` → `AppLoadingIndicator(variant: page)`
- `Empty` → `buildEmpty(context)` (widget builder pasado por el consumidor, típicamente `DocumentEmptyState`)
- `Data<T>` → `buildData(context, data)` (típicamente `DocumentDataView<T>`)
- `Error<T>` → `StatusViewErrorBody(message: state.error.message, onRetry: onRetry)`

### `DocumentDataView<T extends VehicleDocumentModel>`
Vista de "documento existente": `DataViewHeroCard` (ícono + título + chip de días, coloreado por `heroColor`) + `DataViewWarningBanner` opcional + `DataViewDetailsCard` (lista de `DocumentDetailRow`) + `heroFooter` opcional (p. ej. CTA de renovación) + `actions` opcional (p. ej. lista de acciones ver/eliminar).

### `DocumentEmptyState`
Ícono en contenedor cuadrado + título + subtítulo + un único `AppButton` de CTA. Usado cuando el estado es `empty` (sin documento registrado).

### `DocumentValidityCard`
El único widget de este feature que **no** depende del cubit — recibe `startDate`/`expiryDate` directamente (útil dentro de un formulario, antes de guardar). Despacha a una de cuatro variantes internas según las fechas:
- `ValidityCardPending` — alguna fecha es `null`.
- `ValidityCardInvalidDates` — `startDate` no es anterior a `expiryDate`.
- `ValidityCardExpired` — `daysRemaining < 0`.
- `ValidityCardValid` — vigente (incluye copy especial cuando `daysRemaining == 0`, "vence hoy").

> Usa claves `l10n` con prefijo `vehicle_soat_status_*` aunque el widget sea genérico — son las claves originales heredadas de cuando esta card vivía solo en SOAT. RTM las reutiliza tal cual (no hay claves `vehicle_rtm_status_*` separadas); si el copy debe diferir por documento, hay que parametrizarlo explícitamente en vez de agregar claves duplicadas.

### `DocumentDetailRow` / `DocumentSectionHeader`
Piezas atómicas: fila label/value de dos columnas, y header de sección (ícono + título uppercase + trailing opcional). Sin lógica, solo estilo compartido.

---

## 7. Cómo SOAT y RTM extienden esta base

| Elemento base | SOAT | RTM (Tecnomecánica) |
|---|---|---|
| `VehicleDocumentModel` + `VehicleDocumentExpiry` | `SoatModel` **no** implementa este contrato — sigue con su propio `SoatStatus`/`status` legacy paralelo (ver `soat.md §2` y la nota sobre "dos `SoatModel`") | `TecnomecanicaModel with VehicleDocumentExpiry implements VehicleDocumentModel` — implementación directa y completa del contrato |
| `VehicleDocumentCubit<T>` | `SoatCubit` no extiende la base — predata la abstracción (feature más antiguo); mantiene su propio ciclo `ResultState<SoatModel>` equivalente a mano | `TecnomecanicaCubit extends VehicleDocumentCubit<TecnomecanicaModel>` |
| Widgets genéricos (`DocumentStatusView`, `DocumentDataView`, `DocumentEmptyState`, `DocumentValidityCard`, etc.) | `SoatStatusPage`/`SoatDataView`/`SoatEmptyState`/`SoatValidityCard` son **wrappers propios** que replican visualmente los genéricos, pero definidos en `soat/presentation/widgets/` (ver `soat.md §3.3` y §13) | Usa los widgets genéricos directamente (`TecnomecanicaStatusPage` compone `DocumentStatusView`/`DocumentDataView`) |

En resumen: **RTM fue el primer feature diseñado desde el inicio contra esta base** (extiende el cubit, implementa el modelo, usa los widgets genéricos sin envoltorios). **SOAT es anterior a la extracción** y todavía no fue migrado a extender directamente `VehicleDocumentCubit`/`VehicleDocumentModel` — su `soat.md §13` documenta la abstracción y aclara que sus widgets equivalentes (`SoatDataView`, `SoatValidityCard`, etc.) son réplicas visuales, no consumidores directos de los widgets genéricos. Al tocar SOAT, **no dar por hecho que usa esta base** — verificar el archivo concreto antes de asumir el contrato.

**Regla para features nuevos:** cualquier documento legal de vehículo que se agregue de aquí en adelante (ver `soat.md §13` "Agregar un tercer documento") debe:
1. Implementar `VehicleDocumentModel` + `VehicleDocumentExpiry` directamente (como RTM, no como SOAT).
2. Extender `VehicleDocumentCubit<DocModel>` en vez de reescribir el ciclo `loading→data/empty/error` a mano.
3. Componer los widgets genéricos de `vehicle_documents/presentation/widgets/` en vez de crear equivalentes propios (`XxxStatusView`, `XxxDataView`, `XxxEmptyState`...).
4. Agregar su `kind` a `VehicleDocumentKind`.

**Cómo deberían referenciar esto `soat.md` y `tecnomecanica.md`:** en vez de reexplicar el cálculo de vigencia o el ciclo del cubit, ambos documentos deberían enlazar a este archivo (`vehicle_documents.md §2` para el mixin, `§4` para el cubit base, `§6` para los widgets) y documentar solo **su propia desviación** del contrato (p. ej. SOAT: "no extiende la base todavía, mantiene ciclo equivalente a mano"; RTM: "extiende directamente, sin desviación"). `tecnomecanica.md §3` y `§7` ya siguen este patrón (referencian el mixin/cubit base en vez de reexplicarlos); `soat.md §13` documenta la relación pero mantiene además el detalle histórico completo de su propio cálculo en `§5` — al actualizar SOAT en el futuro, considerar recortar esa duplicación una vez SOAT migre a extender la base directamente.

---

## 8. Patrones y trampas conocidas

### El cubit base no maneja 404 por sí mismo
`VehicleDocumentCubit<T>` solo declara `load()` como abstracto; **no** implementa el mapeo 404→`empty`. Esa lógica vive en cada `RepositoryImpl` concreto (que mapea `DioException 404` a `Right(null)`) y en cada `Cubit` concreto (que interpreta `null` como `empty`). Si se agrega un documento nuevo y se olvida ese mapeo en el repository, el 404 se propagará como `Left`/`error` en vez de `empty`, y la UI mostrará un error genérico en vez del `DocumentEmptyState`.

### `VehicleDocumentStatus.none` nunca sale del mixin
`documentStatus` solo retorna `valid`/`expiringSoon`/`expired`. Si se necesita representar "sin documento" como un `VehicleDocumentStatus`, hay que asignarlo explícitamente en la capa que sabe que no hay registro (normalmente al mapear el estado `Empty` del cubit a UI), nunca esperar que el mixin lo calcule.

### SOAT no consume esta base todavía
A pesar de que `vehicle_documents/` nació para servir a ambos, **SOAT no extiende `VehicleDocumentCubit` ni implementa `VehicleDocumentModel`** — son réplicas visuales/funcionales paralelas (ver `soat.md §13`). No asumir que un cambio en los widgets/cubit genéricos afecta a SOAT automáticamente; hay que revisar `soat/presentation/` por separado.

### `DocumentValidityCard` reutiliza claves l10n con prefijo `vehicle_soat_*`
Aunque el widget es genérico y lo usa RTM, sus claves de localización siguen con el prefijo histórico `vehicle_soat_status_*` (no existen equivalentes `vehicle_rtm_status_*`). No es un bug, pero puede confundir al buscar dónde se define el copy de una card de vigencia de RTM.

### Sin capa `data/` en este feature
No busques un `VehicleDocumentRepository`, `VehicleDocumentService` o DTO aquí — no existen. Cada documento (SOAT, RTM) trae el suyo propio contra su propio endpoint. Este feature es puro contrato (`domain/`) + andamiaje visual (`presentation/`).

### `save()`/`delete()` no son parte del contrato base
Solo `load()` está en `VehicleDocumentCubit<T>`. Los métodos de guardado/borrado los define cada subclase concreta con su propia firma (aunque en la práctica siguen el mismo patrón `loading→data/empty` + `error`). No se puede llamar `cubit.save(...)` genéricamente tipando solo contra `VehicleDocumentCubit<T>`.

---

## 9. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Mixin de expiración (vigencia + status) | `lib/features/vehicle_documents/domain/vehicle_document_expiry.dart` |
| Contrato base del modelo | `lib/features/vehicle_documents/domain/vehicle_document_model.dart` |
| Enum de estado de documento | `lib/features/vehicle_documents/domain/vehicle_document_status.dart` |
| Enum de tipo de documento | `lib/features/vehicle_documents/domain/vehicle_document_kind.dart` |
| Cubit base abstracto | `lib/features/vehicle_documents/presentation/cubit/vehicle_document_cubit.dart` |
| Scaffold genérico de estado | `lib/features/vehicle_documents/presentation/widgets/status_view.dart` |
| Cuerpo de error genérico | `lib/features/vehicle_documents/presentation/widgets/status_view_error_body.dart` |
| Vista genérica de datos | `lib/features/vehicle_documents/presentation/widgets/data_view.dart` |
| Hero card / warning banner / details card | `lib/features/vehicle_documents/presentation/widgets/data_view_hero_card.dart`, `data_view_warning_banner.dart`, `data_view_details_card.dart` |
| Fila de detalle genérica | `lib/features/vehicle_documents/presentation/widgets/detail_row.dart` |
| Empty state genérico | `lib/features/vehicle_documents/presentation/widgets/empty_state.dart` |
| Header de sección genérico | `lib/features/vehicle_documents/presentation/widgets/section_header.dart` |
| Card de vigencia (formularios) + variantes | `lib/features/vehicle_documents/presentation/widgets/validity_card.dart` (+ `validity_card_pending.dart`, `validity_card_invalid_dates.dart`, `validity_card_expired.dart`, `validity_card_valid.dart`) |
| Ejemplo de implementador directo (RTM) | `lib/features/tecnomecanica/domain/models/tecnomecanica_model.dart`, `lib/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart` |
| Ejemplo de feature paralelo (SOAT, no migrado) | `lib/features/soat/domain/models/soat_model.dart` — ver `soat.md §13` |
| Tests del mixin (4 estados, SOAT + RTM) | `test/features/vehicle_documents/domain/vehicle_document_expiry_test.dart` |
| Tests del cubit base (`loading→data/empty/error`, `404→empty`) | `test/features/vehicle_documents/presentation/vehicle_document_cubit_test.dart` |
| Tests de widgets genéricos | `test/features/vehicle_documents/presentation/widgets/vehicle_document_widgets_test.dart` |
