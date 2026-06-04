> Slim handoff — read this before docs/exec-runs/rtm-crud-flutter/handoffs/architect.md

# Architect → Frontend: rtm-crud-flutter

## Feature path

`lib/features/tecnomecanica/` — nueva feature completa (domain / data / presentation).

## Domain models

### `TecnomecanicaModel`

```dart
class TecnomecanicaModel with VehicleDocumentExpiry implements VehicleDocumentModel {
  const TecnomecanicaModel({
    required this.id,
    required this.vehicleId,
    required this.certificateNumber,
    required this.cdaName,
    this.cdaCode,
    this.startDate,
    required this.expiryDate,
    this.documentUrl,
    this.createdAt,
    this.updatedAt,
  });

  @override final String id;
  @override final String vehicleId;
  final String certificateNumber;  // required
  final String cdaName;            // required
  final String? cdaCode;           // optional
  final DateTime? startDate;       // optional
  @override final DateTime expiryDate; // required
  final String? documentUrl;       // optional
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleDocumentKind get kind => VehicleDocumentKind.rtm;
  // daysUntilExpiry + documentStatus vienen del mixin VehicleDocumentExpiry
  // copyWith + == + hashCode obligatorios (ver SoatModel como referencia)
}
```

## DTOs (Pattern B)

### Lectura: `TecnomecanicaDto extends TecnomecanicaModel`

```dart
@JsonSerializable(converters: apiJsonDateTimeConverters)
class TecnomecanicaDto extends TecnomecanicaModel { ... }
```
- `factory TecnomecanicaDto.fromJson(...)` + `Map<String, dynamic> toJson()`
- Genera `tecnomecanica_dto.g.dart` con `part`

### Escritura: `CreateTecnomecanicaRequestDto`

```dart
@JsonSerializable(converters: apiJsonDateTimeConverters)
class CreateTecnomecanicaRequestDto {
  final String certificateNumber;
  final String cdaName;
  final String? cdaCode;
  final DateTime? startDate;
  final DateTime expiryDate;
  final String? documentUrl;
  // toJson() generado — NUNCA construir Map<String,dynamic> a mano
}
```

## Retrofit service `@singleton`

```dart
@singleton
@RestApi()
abstract class TecnomecanicaService {
  @factoryMethod
  factory TecnomecanicaService(Dio dio) = _TecnomecanicaService;

  @GET('${ApiRoutes.vehicles}/{vehicleId}/tecnomecanica')
  Future<TecnomecanicaDto> getTecnomecanica(@Path('vehicleId') String vehicleId);

  @POST('${ApiRoutes.vehicles}/{vehicleId}/tecnomecanica')
  Future<TecnomecanicaDto> saveTecnomecanica(
    @Path('vehicleId') String vehicleId,
    @Body() Map<String, dynamic> request,
  );

  @DELETE('${ApiRoutes.vehicles}/{vehicleId}/tecnomecanica')
  Future<void> deleteTecnomecanica(@Path('vehicleId') String vehicleId);
}
```

Añadir a `api_routes.dart`:
```dart
static String vehicleTecnomecanica(String vehicleId) => '$vehicles/$vehicleId/tecnomecanica';
```

## Repository

`TecnomecanicaRepository` (abstract) + `TecnomecanicaRepositoryImpl @Injectable(as: TecnomecanicaRepository)`.
- `getTecnomecanica`: 404 → `Right(null)`. Otros errores → `Left(DomainException)`.
- `saveTecnomecanica`: usa `CreateTecnomecanicaRequestDto(...).toJson()` como body.
- `deleteTecnomecanica`: retorna `Either<DomainException, Unit>`.

## Cubit

```dart
@injectable
class TecnomecanicaCubit extends VehicleDocumentCubit<TecnomecanicaModel> {
  // override load(), add save(), delete()
  // Mismo patrón que SoatCubit — ver lib/features/soat/presentation/cubit/soat_cubit.dart
}
```

## Páginas

**`TecnomecanicaStatusPage`**: BlocProvider que crea `TecnomecanicaCubit` + llama `load(vehicle.id)`.
**`TecnomecanicaManualCapturePage`**: StatefulWidget con form, precarga si hay `existingRtm`, guarda via `context.read<TecnomecanicaCubit>().save(...)`.
**`TecnomecanicaManualCaptureParams`**: data class con `vehicle?`, `existingRtm?`.
**`TecnomecanicaEntryFlow.start(context, vehicle)`**: navega directo a ManualCapturePage (sin bottom sheet, sin OCR).

## Rutas

Añadir en `app_routes.dart`:
```dart
static const String tecnomecanicaStatus = '/tecnomecanica/status';
static const String tecnomecanicaManualCapture = '/tecnomecanica/manual-capture';
```

Registrar en `app_router.dart` (espejo de las rutas SOAT ~líneas 372–391):
```dart
GoRoute(
  path: AppRoutes.tecnomecanicaStatus,
  name: AppRoutes.tecnomecanicaStatus,
  builder: (context, state) {
    final vehicle = state.extra as VehicleModel;
    return TecnomecanicaStatusPage(vehicle: vehicle);
  },
),
GoRoute(
  path: AppRoutes.tecnomecanicaManualCapture,
  name: AppRoutes.tecnomecanicaManualCapture,
  builder: (context, state) {
    final params = state.extra as TecnomecanicaManualCaptureParams;
    return TecnomecanicaManualCapturePage(
      vehicle: params.vehicle,
      existingRtm: params.existingRtm,
    );
  },
),
```

## Formulario (campos)

| Campo | Tipo | Requerido | Nombre form |
|-------|------|-----------|-------------|
| `certificateNumber` | String | sí | `'certificateNumber'` |
| `cdaName` | String | sí | `'cdaName'` |
| `cdaCode` | String? | no | `'cdaCode'` |
| `startDate` | DateTime? | no | `'startDate'` |
| `expiryDate` | DateTime | sí | `'expiryDate'` |
| `documentUrl` | String? | no | `'documentUrl'` |

## VehicleDocumentKind

Añadir `rtm` al enum en `lib/features/vehicle_documents/domain/vehicle_document_kind.dart`.

## Exemption notice (TecnomecanicaExemptionNotice)

Widget no bloqueante que calcula:
```dart
bool _isExempt(VehicleModel vehicle) {
  final purchaseDate = vehicle.purchaseDate;
  if (purchaseDate != null) {
    return DateTime.now().difference(purchaseDate).inDays < 730; // < 2 años
  }
  final year = vehicle.year;
  if (year != null) {
    return DateTime.now().year - year < 2;
  }
  return false;
}
```
Si `_isExempt == true`, mostrar info chip informativo. El botón "Guardar" sigue habilitado.

## Analytics events a emitir

| Evento | Cuándo |
|--------|--------|
| `tecnomecanica_status_viewed` | `load()` resuelve a `Data` |
| `tecnomecanica_manual_saved` | `save()` exitoso (nuevo) |
| `tecnomecanica_updated` | `save()` exitoso (edición, `id.isNotEmpty`) |
| `tecnomecanica_deleted` | `delete()` exitoso |

## L10n keys mínimas

Prefijo `tecnomecanica_`. Incluir al menos:
- `tecnomecanica_page_status_title`
- `tecnomecanica_page_form_title`
- `tecnomecanica_edit_title`
- `tecnomecanica_certificate_number_label` / `_hint`
- `tecnomecanica_cda_name_label` / `_hint`
- `tecnomecanica_cda_code_label` / `_hint`
- `tecnomecanica_start_date_label` / `_hint`
- `tecnomecanica_expiry_date_label` / `_hint`
- `tecnomecanica_save_btn`, `tecnomecanica_saving`
- `tecnomecanica_status_valid`, `_expiring_soon`, `_expired`, `_no_rtm`
- `tecnomecanica_valid_title`, `tecnomecanica_expiring_title`, `tecnomecanica_expired_title`
- `tecnomecanica_expired_warning` (copy legal propio, NO igual al de SOAT)
- `tecnomecanica_delete_button`, `tecnomecanica_delete_confirm_title`, `tecnomecanica_delete_confirm_message`
- `tecnomecanica_exemption_notice` (info chip de exención)
- `tecnomecanica_manual_subtitle` (con placeholder `{vehicleName}`)

## Comandos tras implementar

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze
flutter test
```

> Full detail: docs/exec-runs/rtm-crud-flutter/handoffs/architect.md
