# Checklist de QA — SOAT

**Feature:** Captura, visualización, edición y eliminación del SOAT de un vehículo (`lib/features/soat/`)
**Documentación de referencia:** `docs/features/soat.md`
**Estado:** Pendiente de corrida (checklist recién planificado, sin ejecutar)

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Una cuenta de prueba (`qa1@gmail.com` o equivalente) con al menos un vehículo **sin SOAT** registrado (para probar el flujo de registro desde cero).
- [ ] Un segundo vehículo (o el mismo, tras el primer registro) con un SOAT **vigente** (> 30 días para vencer).
- [ ] Un vehículo con SOAT **por vencer** (entre 0 y 30 días para vencer) — se puede simular guardando `expiryDate` a pocos días desde hoy.
- [ ] Un vehículo con SOAT **vencido** (`expiryDate` en el pasado).
- [ ] Un vehículo **archivado** (`isArchived = true`) con SOAT registrado, para probar el modo lectura.
- [ ] Al menos una foto de un SOAT real (o un PDF de SOAT) en la galería del dispositivo/emulador, con texto legible, para probar el flujo de OCR.
- [ ] Un documento que NO sea un SOAT (ej. una foto random) para probar el caso "documento no reconocido".
- [ ] Dispositivo/emulador con permisos de galería concedidos (`READ_MEDIA_IMAGES` / fotos).

---

## 1. Registrar SOAT — captura manual (sin documento)

> Desde el detalle de un vehículo sin SOAT, toca la tarjeta "SOAT" → sheet de opciones → "Completar formulario".

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Toca la tarjeta SOAT de un vehículo sin SOAT registrado | Se abre `SoatVehicleOptionsSheet` con opciones Galería / PDF / "Completar formulario" (manual) | | |
| 1.2 | Elige "Completar formulario" | Navega a `SoatManualCapturePage` con título **"Registrar"** (`vehicle_soat_form_title`), sin documento adjunto | | |
| 1.3 | Deja el campo "Aseguradora" vacío y revisa el botón de guardar | El botón "Guardar datos" queda deshabilitado (`_canSubmit` requiere aseguradora + ambas fechas) | | |
| 1.4 | Llena Aseguradora, fecha de inicio (hoy) y fecha de vencimiento (> 30 días en el futuro) | El botón se habilita; `SoatValidityCard` muestra vigencia calculada en vivo mientras se completan las fechas | | |
| 1.5 | Toca "Guardar datos" | Se guarda el SOAT (`POST /vehicles/{id}/soat`), vuelve al detalle del vehículo y la tarjeta SOAT muestra el badge **"Vigente"** | 🤖✅ Auto-PASS (`integration_test/soat_manual_capture_patrol_test.dart`) | |

---

## 2. Registrar SOAT — captura por foto (OCR, galería)

> Desde el sheet de opciones, elige "Galería" con una foto real de un SOAT.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Elige "Galería" y selecciona una foto legible de un SOAT | Se abre `SoatManualCapturePage` con el documento adjunto; se dispara el escaneo OCR automáticamente (`initState`, `autoApply: true`) | 👤 Manual (requiere selector de galería real del dispositivo/emulador; el picker está mockeado en unit tests) | |
| 2.2 | Espera a que termine el escaneo (si detecta ≥2 campos con confianza alta) | Aparece el banner **`SoatAutofillBanner`** ("Autocompletar campos"), opt-in — los campos NO se prellenan solos | 🤖✅ Auto-PASS (`test/features/soat/data/parser/soat_parser_test.dart`, `test/features/soat/domain/usecases/scan_soat_usecase_test.dart`, `test/features/soat/domain/usecases/parse_soat_text_usecase_test.dart`) | |
| 2.3 | Toca "Autocompletar campos" en el banner | Se prellenan Aseguradora, fecha de inicio y fecha de vencimiento con los valores detectados por el OCR | 👤 Manual (la lógica de parseo está unit-testeada; la interacción real del banner sobre el formulario requiere widget/e2e test que no existe hoy) | |
| 2.4 | Revisa que el reconocimiento de texto ocurrió 100% on-device | No hay llamadas de red asociadas al escaneo (verificar en logs/Charles/Proxyman que no sale tráfico hacia un backend de OCR) | 👤 Manual (verificación de red, no automatizable en unit test) | |
| 2.5 | Guarda el SOAT con el documento adjunto | El documento se sube a Firebase Storage (`soat/{vehicleId}/{timestamp}.{ext}`) y el SOAT queda guardado con `documentUrl` | | |

---

## 3. Registrar SOAT — captura por PDF

> Desde el sheet de opciones, elige "PDF" (opción primaria/resaltada) con un PDF de SOAT real.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Elige "PDF" y selecciona un archivo `.pdf` de SOAT | `FilePicker` solo permite `.pdf` (`allowedExtensions: ['pdf']`); se adjunta el archivo | 🤖✅ Auto-PASS (`test/features/soat/presentation/cubit/soat_upload_cubit_test.dart`) | |
| 3.2 | Espera el escaneo OCR | El PDF se rasteriza a PNG (página 1, `SoatPdfRasterizer`) antes de correr ML Kit; el resultado se comporta igual que el flujo de galería (banner opt-in o aviso si no reconoce) | 👤 Manual (rasterización de PDF real no cubierta por unit tests; solo el parser de texto lo está) | |
| 3.3 | Guarda el SOAT con el PDF adjunto | El documento sube a Storage con extensión `.pdf`; el SOAT queda guardado | | |
| 3.4 | Desde "Mi SOAT", toca "Ver documento" | Abre el PDF remoto (`DocumentDownloader.openRemote`) sin errores | 👤 Manual (requiere abrir un archivo remoto real desde el dispositivo) | |

---

## 4. Editar un SOAT existente

> Desde "Mi SOAT" (`SoatStatusPage`) de un vehículo con SOAT ya registrado.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Abre "Mi SOAT" de un vehículo con SOAT | El AppBar muestra el botón "Editar" (`soat_edit_btn`) | | |
| 4.2 | Toca "Editar" | Navega a `SoatManualCapturePage` con título **"Editar"** (`soat_edit_title`), formulario pre-poblado con los datos existentes | | |
| 4.3 | Cambia la aseguradora y/o las fechas y guarda | `SaveSoatUseCase` se invoca con el `id` existente; al volver, "Mi SOAT" refleja los nuevos datos y el estado de vigencia recalculado | 🤖✅ Auto-PASS (`test/features/soat/presentation/cubit/soat_cubit_test.dart`, `test/features/soat/domain/usecases/save_soat_usecase_test.dart`) | |
| 4.4 | Reemplaza el documento adjunto por uno nuevo (galería o PDF) | El documento anterior se reemplaza; se sube el nuevo archivo con un timestamp distinto | 👤 Manual (subida real a Firebase Storage) | |

---

## 5. Eliminar el SOAT

> Solo posible desde "Mi SOAT" (`SoatDataView`), no desde el detalle del vehículo ni el formulario.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5.1 | Revisa el detalle del vehículo (`VehicleDocumentCard`) y el formulario de captura/edición | Ninguno de los dos expone un botón de eliminar (se quitó del detalle y del form; solo queda en "Mi SOAT") | | |
| 5.2 | En "Mi SOAT", toca la fila "Eliminar" (`SoatActionTile`, tinte error) | Se muestra `ConfirmationDialog` (tipo danger) pidiendo confirmar | | |
| 5.3 | Confirma la eliminación | Se llama `DELETE /vehicles/{id}/soat`; aparece SnackBar "SOAT eliminado" y la pantalla se cierra (`context.pop()`) | 🤖✅ Auto-PASS (`test/features/soat/presentation/cubit/soat_cubit_test.dart`, `test/features/soat/domain/usecases/delete_soat_usecase_test.dart`) | |
| 5.4 | Vuelve al detalle del vehículo | La tarjeta SOAT vuelve a estado "Sin registro" (`VehicleCubit.clearSoatLocally`) | | |
| 5.5 | Cancela el diálogo de confirmación en vez de confirmar | No se llama al DELETE; el SOAT sigue intacto | | |

---

## 6. Los 4 estados de vigencia

> Verificar el badge/estado en el detalle del vehículo y en "Mi SOAT" para cada caso.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6.1 | Vehículo sin SOAT registrado | Badge/estado **"Sin registro"** (`SoatStatus.noSoat`); `SoatEmptyState` con CTA de registro | | |
| 6.2 | SOAT con `expiryDate` a más de 30 días | Badge **"Vigente"** (verde) | 🤖✅ Auto-PASS (`test/features/soat/domain/models/soat_model_test.dart` TC-2-20/21; `test/features/vehicle_documents/domain/vehicle_document_expiry_test.dart`) | |
| 6.3 | SOAT con `expiryDate` entre 0 y 30 días | Badge **"Por vencer"** (amarillo/naranja) | 🤖✅ Auto-PASS (`test/features/soat/domain/models/soat_model_test.dart` TC-2-22/23) | |
| 6.4 | SOAT con `expiryDate` en el pasado | Badge **"Vencido"** (rojo); en "Mi SOAT" aparece el CTA principal "Registrar nuevo SOAT" | 🤖✅ Auto-PASS (`test/features/soat/domain/models/soat_model_test.dart` TC-2-24) | |
| 6.5 | El cálculo de días ignora la hora del día (solo fecha) | Un SOAT que vence "hoy" a cualquier hora sigue contando como 0 días (no negativo por la hora actual) | 🤖✅ Auto-PASS (`test/features/soat/domain/models/soat_model_test.dart` TC-2-25) | |

---

## 7. Validación de fechas

> En el formulario de captura/edición (`SoatManualCapturePage`).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 7.1 | Ingresa una fecha de vencimiento IGUAL a la fecha de inicio | Aparece el error inline `soat_expiry_after_start_error`; el botón de guardar queda deshabilitado | | |
| 7.2 | Ingresa una fecha de vencimiento ANTERIOR a la fecha de inicio | Mismo error inline; no se puede guardar | | |
| 7.3 | Corrige la fecha de vencimiento para que sea posterior a la de inicio | El error desaparece y el botón se habilita (si el resto de campos son válidos) | 🤖✅ Auto-PASS (`test/features/soat/presentation/pages/soat_manual_capture_page_test.dart` — TC-7.3: ingresa fecha de vencimiento anterior a la de inicio, verifica `ValidityCardInvalidDates` ("Fechas inválidas") + botón deshabilitado, corrige la fecha y verifica que el aviso desaparece y el botón se habilita) | |
| 7.4 | Durante el flujo OCR, si las fechas detectadas no cumplen la ventana de 360–370 días de vigencia del SOAT | El parser marca ambas fechas como confianza `low` (`datesFailedValidation`) y NO se prellenan automáticamente | 🤖✅ Auto-PASS (`test/features/soat/data/parser/soat_parser_test.dart`) | |

---

## 8. Modo lectura en vehículo archivado

> Con un vehículo `isArchived: true` que tiene SOAT registrado.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8.1 | Abre "Mi SOAT" desde un vehículo archivado | El botón "Editar" del AppBar no aparece | | |
| 8.2 | Revisa la vista de datos | El warning inline de vigencia (próximo a vencer / vencido) no se muestra | | |
| 8.3 | Revisa las acciones disponibles | El CTA "Registrar nuevo SOAT" no aparece aunque el SOAT esté vencido; la acción "Eliminar" tampoco aparece | | |
| 8.4 | Si el SOAT no tiene documento adjunto | La card de acciones desaparece por completo (no queda "Ver documento" ni "Eliminar") | | |
| 8.5 | Si el SOAT sí tiene documento adjunto | Solo queda visible la acción "Ver documento" | | |

> Nota: ninguno de los casos de esta sección tiene automatización hoy — no existen widget tests para `SoatDataView`/`SoatStatusView` con `isArchived: true` (verificado: solo hay tests de `SoatCubit` y de los use cases; no hay `soat_data_view_test.dart` ni `soat_status_view_test.dart`).

---

## 9. Casos de borde

### 9A. Documento no reconocido por el OCR

> Sube una foto que NO es un SOAT (ej. una foto random).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 9A.1 | Adjunta un documento que no es un SOAT | Se muestra el aviso inline **no bloqueante** `SoatNotRecognizedWarning` bajo el documento (nunca un SnackBar); el documento queda adjunto y el usuario puede completar los datos a mano o guardar igual | 🤖✅ Auto-PASS (`test/features/soat/domain/usecases/scan_soat_usecase_test.dart` para el path de `SoatScanException` en el use case; `test/features/soat/presentation/pages/soat_manual_capture_page_test.dart` TC-9A.1 mockea `ScanSoatUseCase` para que lance `SoatScanException` y verifica que `SoatNotRecognizedWarning` se renderiza en pantalla) | |

### 9B. Falla la subida del documento al guardar (modo edición)

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 9B.1 | Simula una falla de red/Storage al guardar un SOAT en edición con documento nuevo | Se muestra el error en pantalla (`_error`) y NO se guarda el SOAT | 👤 Manual (requiere simular falla de Firebase Storage; no hay test que fuerce este camino) | |

### 9C. Vehículo sin SOAT y sin conexión (error de red al cargar)

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 9C.1 | Abre "Mi SOAT" con el dispositivo sin conexión | El cubit emite estado `error`; se muestra mensaje de error con botón de reintentar, no un crash | 🤖✅ Auto-PASS (`test/features/vehicle_documents/presentation/vehicle_document_cubit_test.dart` — contrato base `loading→error`) | |

### 9D. Backend no retorna `expiryDate`

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 9D.1 | Si el backend devuelve un SOAT con `expiryDate: null` (no debería pasar) | `SoatDto` cae al fallback `DateTime.now()`, mostrando "vence hoy" — comportamiento conocido y documentado como riesgo (ver `docs/features/soat.md §11`), no un crash | |

---

## 10. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso al código, logs, consola de desarrollo o backend.

| # | Verificación | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 10.1 | Correr `flutter test test/features/soat/` | Todos los tests del feature pasan en verde | |
| 10.2 | Correr `flutter test test/features/vehicle_documents/` | Todos los tests de la base compartida (`VehicleDocumentExpiry`, `VehicleDocumentCubit`, widgets genéricos) pasan en verde | |
| 10.3 | Correr `dart analyze` | Sin issues nuevos en `lib/features/soat/` | |
| 10.4 | Correr `patrol test -t integration_test/soat_manual_capture_patrol_test.dart --device-id <emulador>` con `qa1@gmail.com` | El flujo manual completo (sheet → formulario → guardar → badge "Vigente") pasa en el emulador | |
| 10.5 | Revisar en el backend (`rideglory-api`) que los recordatorios push `SOAT_30D`/`SOAT_7D`/`SOAT_DAY_OF` se programan al guardar un SOAT y se cancelan al reemplazarlo antes del vencimiento | Los jobs de notificación se crean/cancelan correctamente en el scheduler | |
| 10.6 | Confirmar en Firebase Storage que el documento subido queda en la ruta `soat/{vehicleId}/{timestampMs}.{ext}` | La ruta y la extensión coinciden con el archivo real subido | |
| 10.7 | Revisar `AnalyticsEvents`/`AnalyticsParams` de OCR (`soat_scan_attempted`, `soat_scan_success`, `soat_scan_failed`) en la consola de Firebase Analytics tras una corrida manual | Los eventos llegan con los parámetros esperados (`insurer_detected` como 0/1, nunca el nombre real de la aseguradora) | |
| 10.8 | Confirmar que no existen widget tests para `soat_status_page.dart`, `soat_manual_capture_page.dart`, `soat_data_view.dart`, `soat_status_view.dart` (gap de cobertura conocido) | Registrar como deuda técnica si se requiere elevar cobertura de presentation | |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1, 4, 5, 6 y 7 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad (secciones 2, 3, 8 o 9), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 5, 6 o 7 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
