# Fase 5 — Presentación: banner activo + prefill del formulario

**Timestamp:** 2026-06-19T20:09:36Z
**Slug fase:** `05-presentacion-banner-activo-prefill-del-formulario`
**Depende de:** Fase 4 (ScanPropertyCardUseCase registrado en DI)
**Nivel rg-exec recomendado:** normal

---

## Objetivo

Conectar el flujo completo de escaneo en la UI del formulario de vehículo:

1. Crear `VehicleScanCubit` (`@injectable`, `Cubit<ResultState<PropertyCardExtraction>>`).
2. Añadirlo como tercer `BlocProvider` local en `VehicleFormPage` (nunca en el `MultiBlocProvider` raíz de `main.dart`).
3. Convertir `vehicle_scan_banner.dart` en un `BlocBuilder<VehicleScanCubit, ResultState<PropertyCardExtraction>>` con tres estados visuales (idle / loading / error-reintento), editando el archivo existente, no reemplazándolo.
4. El banner dispara `DocumentSourceSheet` → el usuario elige cámara o galería → la imagen resultante llama a `VehicleScanCubit.scan(file)`.
5. Añadir un `BlocListener<VehicleScanCubit>` en `VehicleFormBody` que, al recibir `Data(extraction)`, llama a `context.read<VehicleFormCubit>().prefillFromScan(extraction)`.
6. Implementar `VehicleFormCubit.prefillFromScan()`: método síncrono que aplica cada campo con confianza `high` o `medium` vía `formKey.currentState?.fields[key]?.didChange(value)` sin emitir estado.
7. Descomentar `VehicleScanBanner()` en `VehicleFormBody` (líneas 35-36).
8. Correr `dart run build_runner build --delete-conflicting-outputs` para regenerar `injection.config.dart`.

---

## Alcance (entra / no entra)

### Entra
- `VehicleScanCubit` nuevo (`lib/features/vehicles/presentation/cubit/vehicle_scan_cubit.dart`).
- Modificación de `VehicleFormPage` para añadir el tercer `BlocProvider<VehicleScanCubit>`.
- Modificación de `vehicle_scan_banner.dart` (editar, no reemplazar) para convertirlo en `BlocBuilder` con 3 estados visuales.
- Modificación de `VehicleFormBody` para descomentar el banner y añadir el `BlocListener<VehicleScanCubit>`.
- Adición del método `prefillFromScan(PropertyCardExtraction)` en `VehicleFormCubit`.
- Regeneración de `injection.config.dart` con `build_runner`.

### No entra
- Strings l10n del banner de loading y toasts de éxito/error (eso es Fase 6).
- Permisos de cámara/galería (verificación en Fase 6).
- Cambios en SOAT, RTM, `SoatAddDocumentSheet`, `SoatVehicleOptionsSheet`.
- Tests unitarios del cubit (no hay lógica nueva de dominio; el timing del prefill se valida manualmente).
- Adición de `VehicleScanCubit` al `MultiBlocProvider` raíz en `main.dart` (prohibido — A2).

---

## Qué se debe hacer (pasos concretos y ordenados)

### Paso 1 — Crear `VehicleScanCubit`

Crear el archivo `lib/features/vehicles/presentation/cubit/vehicle_scan_cubit.dart`:

```dart
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/property_card_extraction.dart';
import 'package:rideglory/features/vehicles/domain/models/property_card_scan_result.dart';
import 'package:rideglory/features/vehicles/domain/usecases/scan_property_card_usecase.dart';

@injectable
class VehicleScanCubit extends Cubit<ResultState<PropertyCardExtraction>> {
  VehicleScanCubit(this._scanPropertyCard)
      : super(const ResultState.initial());

  final ScanPropertyCardUseCase _scanPropertyCard;

  Future<void> scan(File file) async {
    emit(const ResultState.loading());
    try {
      final result = await _scanPropertyCard(file: file);
      emit(ResultState.data(data: result.extraction));
    } on PropertyCardScanException catch (exception) {
      emit(
        ResultState.error(
          error: DomainException(message: exception.reason.analyticsValue),
        ),
      );
    }
  }

  void reset() {
    emit(const ResultState.initial());
  }
}
```

**Invariantes:**
- `@injectable`, no `@singleton` (A2: cubit local al formulario, no global).
- Sin `@freezed`; la clase de estado es `ResultState<PropertyCardExtraction>` directamente.
- El método `reset()` permite al banner volver al estado idle tras error (REC-4).

### Paso 2 — Añadir tercer BlocProvider en `VehicleFormPage`

Editar `lib/features/vehicles/presentation/form/vehicle_form_page.dart`.

Añadir `BlocProvider<VehicleScanCubit>` como tercer elemento en el `MultiBlocProvider`, después de `FormImageCubit` y `VehicleFormCubit`. Importar `VehicleScanCubit` y `getIt`:

```dart
BlocProvider(
  create: (context) => getIt.get<VehicleScanCubit>(),
),
```

El orden de providers no tiene dependencias entre sí; colocar como último de los tres es suficiente.

**Invariante:** NUNCA añadir `VehicleScanCubit` al `MultiBlocProvider` en `main.dart`.

### Paso 3 — Convertir `vehicle_scan_banner.dart` en BlocBuilder con 3 estados

Editar `lib/features/vehicles/presentation/form/widgets/vehicle_scan_banner.dart`.

El widget `VehicleScanBanner` pasa de `StatelessWidget` puro a `BlocBuilder<VehicleScanCubit, ResultState<PropertyCardExtraction>>`. Conservar el diseño visual existente (container con borde naranja, ícono `document_scanner_outlined`, colores `AppColors.textOnDarkPrimary` / `AppColors.textOnDarkSecondary`) para el estado idle.

**Tres estados visuales (OBL-2, REC-4):**

1. **Idle** (`Initial` o `Error` — reintento disponible): el diseño actual con `GestureDetector` activo que abre `DocumentSourceSheet`. Si el estado es `Error`, opcionalmente mostrar un ícono de advertencia o cambiar el subtítulo a un string de reintento (strings de Fase 6). El `GestureDetector` debe seguir funcional tras error; llamar a `cubit.reset()` no es necesario antes de la nueva selección de imagen porque `scan()` emite `loading()` de inmediato.

2. **Loading** (`Loading`): reemplazar el `GestureDetector` por un contenedor no interactivo con el mismo diseño base pero con un `CircularProgressIndicator` pequeño (tamaño ~18, `color: AppColors.primary`) en lugar del chevron derecho. El ícono de escáner permanece visible.

3. **Error con reintento** (`Error`): el diseño idle vuelve a estar completamente activo. El `GestureDetector` permite reintentar sin llamar a `reset()` (el método `scan()` transiciona a `loading` directamente). El implementador puede añadir color de borde diferente (`AppColors.error`) como indicador visual opcional; si lo hace, debe restaurarse a `AppColors.primary` en idle/loading.

**Flujo de tap (idle/error):**
```
GestureDetector.onTap
  → showModalBottomSheet(DocumentSourceSheet)
  → await result (DocumentSourceOption? )
  → if result == null, return
  → pick file from camera or gallery via ImagePicker / image_picker
  → VehicleScanCubit.scan(File(pickedPath))
```

La lógica de `ImagePicker` se hace inline en el `onTap` del banner (vía closure que captura `context`), o extrayéndola a un método privado en la clase (siempre que sea método en la clase, no función `_buildXxx` que retorna widget). Usar `ImagePicker().pickImage(source: ImageSource.camera/gallery, imageQuality: 100)`.

**Prohibición crítica:** el widget `VehicleScanBanner` NO puede contener métodos que retornen `Widget` (e.g. `_buildIdle()`, `_buildLoading()`). Cada estado visual se renderiza directamente dentro del `builder` del `BlocBuilder` con sus propios widgets inline o clases `StatelessWidget` separadas si la complejidad lo justifica. Si los tres estados son demasiado largos para inline, crear `_VehicleScanBannerIdle`, `_VehicleScanBannerLoading`, `_VehicleScanBannerError` como clases separadas en archivos separados bajo `form/widgets/`.

### Paso 4 — Descomentar `VehicleScanBanner` en `VehicleFormBody`

Editar `lib/features/vehicles/presentation/form/vehicle_form_body.dart`.

Las líneas 35-36 tienen:
```dart
// const SizedBox(height: 16),
// const VehicleScanBanner(),
```

Descomentar ambas líneas. Añadir el import de `VehicleScanBanner`.

### Paso 5 — Añadir `BlocListener<VehicleScanCubit>` en `VehicleFormBody`

Editar `lib/features/vehicles/presentation/form/vehicle_form_body.dart`.

El `BlocListener` debe escuchar `VehicleScanCubit` y llamar a `prefillFromScan` cuando el estado sea `Data`. Dado que `VehicleFormBody` ya recibe `formKey` como parámetro (y el cubit lo tiene internamente), el listener solo necesita acceder al `VehicleFormCubit` vía `context.read`.

Envolver el `FormBuilder` en un `BlocListener`:

```dart
@override
Widget build(BuildContext context) {
  return BlocListener<VehicleScanCubit, ResultState<PropertyCardExtraction>>(
    listener: (context, state) {
      state.whenOrNull(
        data: (extraction) =>
            context.read<VehicleFormCubit>().prefillFromScan(extraction),
      );
    },
    child: FormBuilder(
      key: formKey,
      // ... resto sin cambios
    ),
  );
}
```

**Gotcha crítico de timing (R2):** el `BlocListener` está dentro de `VehicleFormBody`, que se construye después de que `FormBuilder` ya está en el árbol. El `VehicleFormBody` se monta en `VehicleFormView._VehicleFormViewState.build()` dentro del `BlocListener<VehicleFormCubit>`. Para cuando el scan completa (operación asíncrona de segundos), el `FormBuilder` ya está completamente montado y `formKey.currentState?.fields` estará disponible. No hay carrera de condición si el listener vive en `VehicleFormBody` (no en el cubit ni en el banner).

**Importar** `PropertyCardExtraction` y `VehicleScanCubit` en `vehicle_form_body.dart`.

### Paso 6 — Implementar `prefillFromScan` en `VehicleFormCubit`

Editar `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart`.

Añadir el método síncrono al final de la clase, antes de `reset()`:

```dart
/// Prefills form fields from a scanned property card extraction.
///
/// Only applies fields with [OcrFieldConfidence.high] or
/// [OcrFieldConfidence.medium] confidence. Does NOT emit a new
/// [VehicleFormState] — updates the [FormBuilder] in-place via [didChange].
void prefillFromScan(PropertyCardExtraction extraction) {
  final fields = formKey.currentState?.fields;
  if (fields == null) return;

  void maybeSet(String key, String? value, OcrFieldConfidence confidence) {
    if (value != null &&
        confidence != OcrFieldConfidence.low &&
        value.trim().isNotEmpty) {
      fields[key]?.didChange(value.trim());
    }
  }

  maybeSet(VehicleFormFields.brand, extraction.brand, extraction.brandConfidence);
  maybeSet(VehicleFormFields.model, extraction.model, extraction.modelConfidence);
  maybeSet(VehicleFormFields.year, extraction.year, extraction.yearConfidence);
  maybeSet(VehicleFormFields.licensePlate, extraction.licensePlate, extraction.licensePlateConfidence);
  maybeSet(VehicleFormFields.vin, extraction.vin, extraction.vinConfidence);
}
```

**Invariantes críticos (A5):**
- El método es síncrono y NO llama a `emit()`. Viola el diseño emitir `VehicleFormState` aquí.
- El campo `year` se pasa como `String` (e.g. `'2019'`), nunca como `int` ni `DateTime`. `PropertyCardExtraction.year` debe ser `String?` (confirmado en Fase 3 — el campo `VehicleFormFields.year` en `VehicleFormBasicSection` es `AppTextField` con `keyboardType: TextInputType.number`; el cubit parsea con `int.tryParse()` al guardar — REC-5).
- `brand` en el formulario es `AppAutocompleteField` con lista de marcas de Colombia (`ColombiaMotosBrandsData`). El `didChange()` acepta cualquier `String`; si la marca extraída no está en la lista, el validador la rechazará al intentar guardar. Esto es comportamiento correcto v1: el usuario corrige manualmente. No se añade lógica de normalización en esta fase.
- No hay `toModel()`, `fromModel()` ni `toDto()` involucrados (no es capa data).

**Importar** `PropertyCardExtraction` y `OcrFieldConfidence` en `vehicle_form_cubit.dart`.

### Paso 7 — Regenerar injection.config.dart

```bash
dart run build_runner build --delete-conflicting-outputs --force-jit
```

Verificar que `VehicleScanCubit` y `ScanPropertyCardUseCase` aparecen registrados en `lib/core/di/injection.config.dart`.

Si el build falla por el gotcha `objective_c`, consultar `project_build_runner_force_jit.md`: copiar `.env` y configs Firebase si aplica.

### Paso 8 — Lint

```bash
dart analyze
```

Zero warnings en archivos nuevos o modificados. Los dos lints de `api_base_url_resolver.dart` (config local de testing) se ignoran según `project_local_api_hack.md`.

---

## Archivos a crear/modificar (rutas reales)

| Acción | Ruta | Qué cambia |
|--------|------|------------|
| **Crear** | `lib/features/vehicles/presentation/cubit/vehicle_scan_cubit.dart` | Nuevo cubit `@injectable Cubit<ResultState<PropertyCardExtraction>>` con métodos `scan(File)` y `reset()`. |
| **Modificar** | `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | Añadir tercer `BlocProvider<VehicleScanCubit>` al `MultiBlocProvider` local. |
| **Modificar** | `lib/features/vehicles/presentation/form/widgets/vehicle_scan_banner.dart` | Convertir de `StatelessWidget` puro a `BlocBuilder<VehicleScanCubit, ResultState<PropertyCardExtraction>>` con 3 estados visuales. Conectar tap a `DocumentSourceSheet` → `VehicleScanCubit.scan()`. |
| **Modificar** | `lib/features/vehicles/presentation/form/vehicle_form_body.dart` | Descomentar `VehicleScanBanner()`, añadir `BlocListener<VehicleScanCubit>` que llama a `prefillFromScan` en estado `Data`. |
| **Modificar** | `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart` | Añadir método síncrono `prefillFromScan(PropertyCardExtraction)` que aplica campos via `didChange()` sin emitir estado. |
| **Auto-regenerado** | `lib/core/di/injection.config.dart` | Registro automático de `VehicleScanCubit` (y `ScanPropertyCardUseCase` de Fase 4 si aún no estaba). |

---

## Contratos / API rideglory-api

**Ninguno.** Esta fase es 100% Flutter on-device. No se tocan endpoints existentes.

---

## Cambios de datos / migraciones

**Ninguno.** No hay cambios de esquema, base de datos ni persistencia local.

---

## Criterios de aceptación (numerados, observables, testeables)

1. **Banner visible:** al abrir `VehicleFormPage` (nuevo o edición), el banner de escaneo aparece entre la sección de foto de portada y los campos de información básica.

2. **Banner estado idle:** el banner muestra el ícono de escáner, el título (`vehicle_form_scan_title`) y el subtítulo (`vehicle_form_scan_subtitle`) con el fondo naranja sutil y borde naranja. El icono usa `AppColors.textOnDarkPrimary` (no blanco) sobre fondo `AppColors.primary` — cumple el estándar de texto oscuro sobre acento.

3. **Tap en banner — apertura del sheet:** al tocar el banner en estado idle, se abre `DocumentSourceSheet` con la instrucción de cara frontal visible.

4. **Selección de fuente dispara escaneo:** al elegir cámara o galería en el sheet, el picker nativo se abre. Tras seleccionar imagen, `VehicleScanCubit.scan()` se invoca y el banner transiciona a estado loading.

5. **Banner estado loading:** durante el escaneo, el banner muestra un `CircularProgressIndicator` y el `GestureDetector` no es interactivo (no permite doble tap).

6. **Prefill en éxito:** cuando el escaneo termina con `ResultState.data`, los campos del formulario (`brand`, `model`, `year`, `licensePlate`, `vin`) con confianza `high` o `medium` se rellenan automáticamente sin recargar la pantalla. Los campos con confianza `low` permanecen sin cambios.

7. **Campo year como String:** el campo de año del formulario muestra el año como texto numérico (e.g. `2019`), no como fecha ni como entero formateado. El validador del campo acepta el valor sin error de tipo.

8. **Banner estado error con reintento (REC-4):** si el escaneo falla o la confianza es insuficiente (`PropertyCardScanException`), el banner vuelve a un estado interactivo (idle o con indicador de error). El `GestureDetector` está activo y permite reintentar el escaneo sin necesidad de navegar fuera del formulario.

9. **Prefill no rompe campos no prefillados:** los campos del formulario que no corresponden a ningún campo extraído (e.g. `name`, `currentMileage`, `purchaseDate`, `color`) conservan sus valores previos (vacíos en modo creación, valores originales en modo edición).

10. **No emite VehicleFormState en prefill (A5):** el loader del AppBar (flag `isLoading` del `VehicleFormState`) no aparece durante el prefill. El botón "Guardar" permanece activo.

11. **Provider local, no singleton:** si se abren dos instancias de `VehicleFormPage` simultáneamente (e.g. push doble), cada una tiene su propio `VehicleScanCubit` independiente. El estado de scan de una no afecta a la otra.

12. **`VehicleScanCubit` ausente en main.dart:** `git grep 'VehicleScanCubit' lib/main.dart` retorna 0 resultados.

13. **`dart analyze` limpio:** cero warnings en los archivos de esta fase. Ningún método `_buildXxx` que retorne `Widget` en `VehicleScanBanner`.

14. **build_runner sin errores:** `injection.config.dart` se regenera sin conflictos. `VehicleScanCubit` aparece en el registro de GetIt.

---

## Pruebas

### Unitarias
No se añaden tests unitarios en esta fase. La lógica del cubit es un wrapper delgado sobre `ScanPropertyCardUseCase` (testeado en Fase 4). El método `prefillFromScan` es síncrono y su corrección depende del estado del `FormBuilder` (no es testeable sin widget tree). Los tests de dominio y parser ya cubren la lógica de negocio (Fases 3 y 4).

### Widget / integración manual
Verificar manualmente los 14 criterios de aceptación usando la app en modo dev (`flutter run --flavor dev --dart-define-from-file=config/dev.json`):

1. Abrir el formulario de nuevo vehículo → confirmar que el banner aparece.
2. Tocar el banner → confirmar apertura de `DocumentSourceSheet`.
3. Elegir galería → seleccionar una foto de tarjeta de propiedad sintética → confirmar loading.
4. Confirmar que los campos se rellenan con los valores extraídos.
5. Repetir con cámara.
6. Simular fallo (imagen sin texto) → confirmar banner en estado error con `GestureDetector` activo → reintentar.
7. Abrir en modo edición → confirmar que los valores existentes no se sobrescriben en campos con confianza `low`.

### No-regresión
```bash
flutter test test/features/soat/
flutter test test/features/vehicles/
dart analyze
```

Los tests de SOAT no deben verse afectados. Los tests del formulario de vehículo (si existen) deben pasar.

---

## Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|------------|
| R2 | `formKey.currentState?.fields` nulo en el momento del prefill (carrera de condición) | Media | Alto (falla silenciosa — el form no se rellena sin error visible) | Prefill disparado desde `BlocListener` en `VehicleFormBody`, el cual solo se monta después de que el `FormBuilder` ya está en el árbol. El scan es asíncrono (segundos) → el form siempre estará montado antes de que el resultado llegue. Mitigación adicional: `prefillFromScan` tiene guard `if (fields == null) return;` para fallar silenciosamente en el caso improbable. |
| R7 | Confusión entre banner activo (`form/widgets/vehicle_scan_banner.dart`) y banner huérfano (`widgets/vehicle_form_scan_banner.dart`) | Baja-Media | Bajo | La Fase 1 eliminó el huérfano. Gate: verificar con `git status` que `presentation/widgets/vehicle_form_scan_banner.dart` no existe antes de editar `form/widgets/vehicle_scan_banner.dart`. |
| RN1 | Método `_buildXxx` que retorne `Widget` dentro de `VehicleScanBanner` | Media | Bajo | El auditor debe verificar explícitamente que el BlocBuilder con 3 estados usa clases widget separadas o inline, nunca métodos privados que retornen `Widget`. |
| RN2 | Campo `brand` del formulario es `AppAutocompleteField` con lista cerrada | Media | Bajo (UX) | El prefill aplica la marca extraída via `didChange()`. Si la marca no está en `ColombiaMotosBrandsData`, el validador lo marcará en rojo al intentar guardar. Comportamiento esperado en v1; el usuario corrige. No añadir lógica de fuzzy matching en esta fase. |
| RN3 | `VehicleScanCubit` accidentalmente añadido a `main.dart` | Baja | Medio (architectural — viola A2) | El auditor verifica con `git grep 'VehicleScanCubit' lib/main.dart` que retorna vacío. |
| R6 | `build_runner` falla en entornos frescos (gotcha `objective_c`) | Media | Medio | Usar `--force-jit`. Copiar `.env` y configs Firebase si aplica. Ver `project_build_runner_force_jit.md`. |

---

## Dependencias (fases prerequisito y por qué)

| Fase | Razón |
|------|-------|
| **Fase 4** (ScanPropertyCardUseCase + telemetría) | `VehicleScanCubit` recibe `ScanPropertyCardUseCase` por inyección de dependencias. Sin la Fase 4, el cubit no puede compilar ni resolver su constructor en GetIt. |
| **Fase 3** (domain layer + parser) | `ScanPropertyCardUseCase` depende de `ParsePropertyCardTextUseCase` y `PropertyCardExtraction`. Sin la Fase 3, la Fase 4 no compila. Transitiva para esta fase. |
| **Fase 2** (DocumentSourceSheet) | El banner en estado idle abre `DocumentSourceSheet`. Sin la Fase 2, el `onTap` no tiene sheet que mostrar (compilaría pero fallaría en runtime). |
| **Fase 1** (limpieza código muerto) | El banner huérfano `presentation/widgets/vehicle_form_scan_banner.dart` debe estar eliminado para que el implementador edite el archivo correcto sin confusión. |

---

## Ejecución recomendada (nivel rg-exec: normal)

**Por qué normal y no lite:**

- **UI con estados múltiples:** el `BlocBuilder` del banner tiene 3 estados visuales distintos (idle, loading, error-reintento). Cada estado debe cumplir los estándares del design system (colores, interactividad, indicadores de carga). Un auditor debe verificar que no hay regresiones visuales ni violaciones del estándar de texto oscuro sobre primario.

- **Gotcha crítico de timing de `formKey`:** la solución del `BlocListener` en `VehicleFormBody` es correcta según el Architect Review, pero su implementación exacta puede desviarse. Si el implementador coloca el listener en el lugar equivocado (e.g. en `VehicleFormView.build()` antes de que `FormBuilder` se monte, o directamente en el cubit), el prefill falla silenciosamente sin lanzar excepciones. El auditor debe rastrear el flujo completo.

- **Restricción estricta de no emitir estado en prefill (A5):** si `prefillFromScan` emite `VehicleFormState`, se produce una reconstrucción del formulario que puede resetear el estado de validación de campos no prefillados. Esta violación no produce un error en compilación ni en tests simples.

- **Múltiples invariantes de arquitectura verificables por el auditor:**
  - `BlocBuilder` sin métodos `_buildXxx` que retornen `Widget` (regla de un widget por archivo).
  - `BlocListener` en el widget correcto (VehicleFormBody), no en el cubit.
  - `VehicleScanCubit` como `BlocProvider` local, nunca en `main.dart`.
  - Tipo exacto del campo `year`: `String`, no `int` ni `DateTime` (REC-5).
  - `brand` via `AppAutocompleteField.didChange()` acepta `String` — no confundir con `AppTextField.didChange()`.

- **Riesgo medio-alto en UX:** si el banner o el listener se conectan incorrectamente, el flujo completo del feature queda inutilizable aunque el código compile.

- **No hay API ni migraciones:** el riesgo está concentrado en la correctitud de la implementación UI y la arquitectura BLoC, no en contratos externos. Dos rondas de auditor Opus con revisión de Architect + QA cubren el riesgo sin necesitar nivel `full`.
