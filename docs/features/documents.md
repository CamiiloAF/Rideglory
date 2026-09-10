# Documents (SOAT y RTM)

> Nuevo en v2 (F5). Fusiona `soat.md`, `tecnomecanica.md` y `vehicle_documents.md` de la v1: en v2 SOAT y RTM son un solo modelo (`VehicleDocument`) diferenciado por `kind`, no dos features paralelas.

## Problema que resuelve

Bloque 1 de `docs/product/ALCANCE-V2.md`: "SOAT y RTM como documentos: captura, vigencia, y llegar a ellos **sin señal**" (P-11, P-12). Dos problemas abiertos que el bloque exige resolver aquí, no después: **el caché de documentos** — en la v1 vivía en el directorio temporal del SO, exactamente lo que borra "limpiar el dispositivo"; y **recordatorios de vencimiento que el usuario controla**, incluida la RTM, que en la v1 no tenía ni un tipo de notificación.

## Flujos

- **Subir documento** (`DocumentUploadPage`): origen (cámara/galería/PDF) → si es SOAT y viene de foto, OCR on-device → confirmar (con o sin prellenado) → guardar.
- **OCR solo para SOAT y solo desde foto**: `OcrService` (ML Kit, `lib/core/services/ocr/ml_kit_ocr_service.dart`, sin red) extrae texto; `SoatParser` (puro Dart) lo interpreta contra un catálogo cerrado de 10 aseguradoras colombianas autorizadas (`soat_insurer_rules.dart`), valida que el rango de vigencia sea de 360–370 días, y asigna confianza (alta/media/baja) por campo. Solo prellena si hay **al menos 2 campos de alta confianza** (`SoatExtraction.shouldPrefill`). Un fallo de OCR no bloquea nada: cae a llenado manual en silencio — es una conveniencia, no una ruta crítica de seguridad. RTM y los PDF de SOAT saltan el OCR directo a llenado manual.
- **Ver documento** (`DocumentViewerPage`): siempre intenta el caché local primero. Si hay conexión y no hay caché, descarga y cachea. Si no hay conexión y sí hay caché, muestra el documento con un aviso de "sin conexión". Si no hay conexión y no hay caché, estado dedicado `offlineNoCache` (no un error genérico).
- **Recordatorios locales**: `DocumentReminderScheduler` programa notificaciones locales (no push) a 30/7/1 días antes del vencimiento, siempre a las 9am hora `America/Bogota` (fija, sin horario de verano — Colombia no lo tiene). Se reprograman en cada subida/reemplazo y se pueden apagar por documento (`reminder_enabled`).
- **Compartir / reemplazar**: vía `share_plus`, sobre el archivo cacheado.

## Pantallas (Pencil)

| Pantalla | Archivo | Pencil |
|---|---|---|
| Subir documento | `presentation/pages/document_upload_page.dart` | `R9ZYe` (origen), `rbRuw` (cámara — usa la cámara nativa de `image_picker`, no un overlay de encuadre custom; **desviación documentada** en el commit de F5), `MG790` (confirmar) |
| Ver documento | `presentation/pages/document_viewer_page.dart` | `tu2U6` (con red), `P5GIm` (sin conexión), `dB4Au` (no subido) |

## Datos

- Tabla `vehicle_documents`: `vehicle_id, kind (soat|rtm), number, issuer, start_date, expiry_date, file_path, reminder_enabled`.
- Storage: bucket privado `documents`, ruta `<ownerId>/<vehicleId>/<kind>.<ext>`, URL firmada TTL 1h.
- Caché local offline (D7): `DocumentLocalCacheService` en `ApplicationSupportDirectory/documents/<vehicleId>/<kind>.<ext>` — nunca en directorio temporal.
- Sin RPCs ni Edge Functions propias.

## Estados

`VehicleDocumentsCubit` es `Cubit<ResultState<VehicleDocumentsSummary>>` (SOAT + RTM juntos en un solo resultado — excepción documentada a la regla de "un `ResultState` por resultado independiente", porque ambos documentos se muestran siempre juntos). `DocumentUploadCubit` tiene un estado freezed propio con paso (`origin|confirm`) y una `submission: ResultState<Unit>` embebida. `DocumentViewerCubit` usa una unión propia (`loading|loaded|notUploaded|offlineNoCache|error`) en vez del `ResultState` genérico, porque "no subido" y "sin conexión sin caché" son estados de producto distintos de un error.

Obligatorios: skeleton (`SkeletonList`, `SkeletonBox`), error con reintentar (`ErrorStateView` en el visor), sin conexión (`OfflineStateView` para `offlineNoCache`), y el estado propio `notUploaded` (`DocumentNotUploadedView`, Pencil `dB4Au`). Sin permiso de ubicación / sin GPS no aplican.

## Pendientes

- Ninguna nota `TODO`/`FIXME`/pendiente encontrada en el código de esta feature.
- Desviación documentada: la captura usa la cámara nativa de `image_picker` en vez del overlay de encuadre custom del frame `rbRuw` (no hay dependencia `camera` en el `pubspec`). Reconciliar con Pencil: actualizar el frame o agregar el overlay.
- Escaneo de tarjeta de propiedad sigue fuera de alcance (`kill`, ver `ALCANCE-V2.md`); el OCR on-device de esta feature no se toca por eso.
