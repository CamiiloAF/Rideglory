# Checklist de QA — Tecnomecánica (RTM)

**Feature:** Registro, visualización, edición y eliminación de la revisión técnico-mecánica de un vehículo (`lib/features/tecnomecanica/`)
**Documentación de referencia:** `docs/features/tecnomecanica.md`
**Estado:** Pendiente de corrida (checklist recién planificado, sin ejecutar)

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Una cuenta de prueba (`qa1@gmail.com` o equivalente) con al menos un vehículo **sin RTM** registrado (para probar el flujo de registro desde cero).
- [ ] Un vehículo con RTM **vigente** (> 30 días para vencer).
- [ ] Un vehículo con RTM **por vencer** (entre 0 y 30 días para vencer).
- [ ] Un vehículo con RTM **vencido** (`expiryDate` en el pasado).
- [ ] Un vehículo **archivado** (`isArchived = true`) con RTM registrado, para probar el modo lectura.
- [ ] Idealmente, un vehículo con matrícula de menos de 2 años (o marcado como exento en el backend), para probar el caso de exención.
- [ ] Nombre de un CDA (centro de diagnóstico automotor) real o ficticio para llenar el formulario.

---

## 1. Registrar RTM por primera vez

> Desde el detalle de un vehículo sin RTM, toca el badge/tarjeta RTM.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Toca la tarjeta/badge RTM de un vehículo sin RTM registrado | Se abre `TecnomecanicaStatusPage`; el estado `empty` muestra `TecnomecanicaEmptyState` con el texto "Sin RTM registrada" (`tecnomecanica_status_no_rtm`) y el CTA de registro (`tecnomecanica_renew_btn`) | | |
| 1.2 | Toca el CTA de registro | Navega a `TecnomecanicaManualCapturePage` con título **"Registrar RTM"** (`tecnomecanica_form_create_title`) | | |
| 1.3 | Deja el campo CDA vacío y revisa el botón de guardar | El botón de guardar queda deshabilitado hasta completar los campos requeridos (CDA + fechas válidas) | | |
| 1.4 | Llena CDA (`tecnomecanica_field_cda_name`), fecha de inicio y fecha de vencimiento (> 30 días en el futuro); deja la URL del documento vacía (opcional) | El botón se habilita | | |
| 1.5 | Toca guardar | `TecnomecanicaCubit.save()` con id vacío (creación) → `POST /vehicles/{id}/tecnomecanica`; vuelve al detalle/estado con el RTM en estado **"Vigente"**; se registra el evento de analytics `tecnomecanica_manual_saved` | 🤖✅ Auto-PASS (`test/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit_test.dart` — grupo `save` + `analytics`) | |
| 1.6 | Verifica que **no** exista el campo `certificateNumber` en el formulario | El formulario solo pide CDA + fechas + URL de documento opcional; el campo fue eliminado del modelo (commit `c07aca4`) | | |

---

## 2. Ver RTM registrado

> Desde el detalle del vehículo, con RTM ya guardado.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Revisa el badge RTM en el detalle del vehículo | Muestra el color correspondiente al estado (verde/amarillo/rojo) | | |
| 2.2 | Toca el badge | Abre `TecnomecanicaStatusPage`; estado `data` → `TecnomecanicaDataView` | 🤖✅ Auto-PASS (`test/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit_test.dart` — grupo `load`; evento `tecnomecanica_status_viewed`) | |
| 2.3 | Revisa los datos mostrados | Se ven CDA, fechas de inicio/vencimiento y días restantes; si aplica, banner de advertencia por vencimiento próximo o vencido | | |

---

## 3. Editar RTM

> Desde `TecnomecanicaStatusPage` con RTM ya registrado.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Abre "Mi RTM" (o equivalente) de un vehículo con RTM | El AppBar muestra el botón "Editar" (`tecnomecanica_edit_btn`) | | |
| 3.2 | Toca "Editar" | Navega a `TecnomecanicaManualCapturePage` con título **"Editar"** (`tecnomecanica_edit_title`), pre-poblado con los datos existentes (CDA, fechas, documento) | | |
| 3.3 | Cambia el CDA y/o las fechas y guarda | `TecnomecanicaCubit.save()` con id no vacío (edición) → `PUT /vehicles/{id}/tecnomecanica`; se dispara el evento `tecnomecanica_updated`; el estado de vigencia se recalcula | 🤖✅ Auto-PASS (`test/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit_test.dart` — grupo `save` + `analytics`; `test/features/tecnomecanica/data/repository/tecnomecanica_repository_impl_test.dart` — `saveTecnomecanica`) | |

---

## 4. Eliminar RTM

> Desde `TecnomecanicaStatusPage`.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | En el AppBar (o en la vista de datos), toca "Eliminar RTM" (`tecnomecanica_delete_button`) | Se muestra `ConfirmationDialog` con título "¿Eliminar RTM?" (`tecnomecanica_delete_confirm_title`) | | |
| 4.2 | Confirma la eliminación | `DELETE /vehicles/{id}/tecnomecanica`; SnackBar "RTM eliminada" (`tecnomecanica_deleted_success`); estado vuelve a `empty` | 🤖✅ Auto-PASS (`test/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit_test.dart` — grupo `delete`; `test/features/tecnomecanica/domain/usecases/delete_tecnomecanica_usecase_test.dart`; `test/features/tecnomecanica/data/repository/tecnomecanica_repository_impl_test.dart` — `deleteTecnomecanica`) | |
| 4.3 | Cancela el diálogo en vez de confirmar | No se llama al DELETE; el RTM sigue intacto | | |
| 4.4 | Vuelve al detalle del vehículo tras eliminar | El badge RTM vuelve a estado "Sin registro" (`none`) | | |

---

## 5. Vehículo exento (< 2 años desde matrícula)

> El backend no retorna RTM para vehículos exentos (mismo camino técnico que "no tiene RTM registrado").

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5.1 | Abre el badge/estado RTM de un vehículo con matrícula de menos de 2 años | El backend responde 404 → se mapea a `Right(null)` → estado `empty`, igual que un vehículo sin RTM cargado nunca | 🤖✅ Auto-PASS (`test/features/tecnomecanica/data/repository/tecnomecanica_repository_impl_test.dart` — `404 — retorna Right(null)`) | |
| 5.2 | Revisa si la app distingue visualmente "exento" de "no tiene RTM todavía" | **Bug RESUELTO** (ver "Bugs encontrados" al final del documento): `TecnomecanicaEmptyState` ahora instancia `TecnomecanicaExemptionNotice` en su `build()`, justo antes del CTA de registro — el aviso de exención sí se muestra en la pantalla de estado vacío | 🤖✅ Auto-PASS (`test/features/tecnomecanica/presentation/widgets/tecnomecanica_empty_state_test.dart` — test de regresión que monta `TecnomecanicaEmptyState` y verifica que `TecnomecanicaExemptionNotice` aparece en el árbol de widgets) | |
| 5.3 | Abre el formulario de registro de RTM para cualquier vehículo | El aviso `TecnomecanicaExemptionNotice` (`tecnomecanica_exemption_notice`) se muestra en el formulario en modo creación (no en edición), sin condicionar a la antigüedad real del vehículo (no hay campo de antigüedad en `VehicleModel`/`TecnomecanicaModel` para calcularlo en el cliente) | | |
| 5.4 | En un vehículo exento, revisa que no se muestre alerta de vencimiento | No aplica alerta de vencimiento porque no hay RTM cargado (mismo estado `empty` que el caso "no registrado") | | |

---

## 6. Los 4 estados del documento

> Verificar el badge/estado en el detalle del vehículo y en la vista de datos para cada caso.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6.1 | Vehículo sin RTM registrado (o exento) | Estado `none`; badge gris neutro; `TecnomecanicaEmptyState` con CTA de registro | | |
| 6.2 | RTM con `expiryDate` a más de 30 días | Estado `valid`; badge verde | 🤖✅ Auto-PASS (`test/features/tecnomecanica/domain/models/tecnomecanica_model_test.dart` TC-rtm-01/02; `test/features/vehicle_documents/domain/vehicle_document_expiry_test.dart`) | |
| 6.3 | RTM con `expiryDate` entre 0 y 30 días | Estado `expiringSoon`; badge amarillo/naranja | 🤖✅ Auto-PASS (`test/features/tecnomecanica/domain/models/tecnomecanica_model_test.dart` TC-rtm-03/04) | |
| 6.4 | RTM con `expiryDate` en el pasado | Estado `expired`; badge rojo | 🤖✅ Auto-PASS (`test/features/tecnomecanica/domain/models/tecnomecanica_model_test.dart` TC-rtm-05) | |
| 6.5 | El árbol de 4 estados es consistente con SOAT (mismo mixin `VehicleDocumentExpiry`) | Los umbrales (30 días, medianoche) son idénticos entre SOAT y RTM | 🤖✅ Auto-PASS (`test/features/vehicle_documents/domain/vehicle_document_expiry_test.dart` — parametrizado `soat` + `rtm`) | |

---

## 7. Validación de fechas

> En el formulario de registro/edición (`TecnomecanicaManualCapturePage`).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 7.1 | Ingresa una fecha de vencimiento IGUAL a la fecha de inicio | Aparece el error inline `tecnomecanica_expiry_after_start_error`; el botón de guardar queda deshabilitado | | |
| 7.2 | Ingresa una fecha de vencimiento ANTERIOR a la fecha de inicio | Mismo error inline; no se puede guardar | | |
| 7.3 | Corrige la fecha de vencimiento para que sea posterior a la de inicio | El error desaparece y el botón se habilita (si CDA también es válido) | | |
| 7.4 | Simula una falla al subir el documento (si se adjunta URL/archivo) | Se muestra `context.l10n.imageUploadFailed` y no se guarda el RTM | 👤 Manual (requiere simular falla de subida; no hay test de widget que fuerce este camino) | |

> Nota: a diferencia de SOAT, no existe un caso equivalente `parse_soat_text_usecase_test.dart` para RTM porque **no hay OCR en tecnomecánica** — la validación de fechas es puramente de formulario (`setState`), no hay tests de widget para `TecnomecanicaManualCapturePage` hoy (gap conocido, igual que en SOAT).

---

## 8. Modo lectura en vehículo archivado

> Con un vehículo `isArchived: true` que tiene RTM registrado.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8.1 | Abre el estado RTM desde un vehículo archivado | El botón "Editar" del AppBar no aparece | | |
| 8.2 | Revisa la vista de datos | El warning inline de vigencia (próximo a vencer / vencido) no se muestra | | |
| 8.3 | Revisa las acciones disponibles | El botón "Eliminar RTM" no aparece | | |
| 8.4 | Si el RTM no tiene documento adjunto | La sección de acciones queda vacía o reducida según corresponda (mismo patrón que SOAT — ver `docs/features/soat.md §6.6`) | | |
| 8.5 | Si el RTM sí tiene documento adjunto | Solo queda visible la acción "Ver documento" | | |

> Nota: ninguno de los casos de esta sección tiene automatización hoy — no existen widget tests para `TecnomecanicaDataView`/`TecnomecanicaStatusView` con `isArchived: true` (verificado: solo hay tests de `TecnomecanicaCubit`, DTO, repository y modelo; no hay `tecnomecanica_data_view_test.dart` ni `tecnomecanica_status_view_test.dart`).

---

## 9. Casos de borde

### 9A. Error de red al cargar el RTM

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 9A.1 | Abre el estado RTM con el dispositivo sin conexión (o el backend caído) | El cubit emite estado `error`; se muestra el mensaje de error con botón "Reintentar", no un crash | 🤖✅ Auto-PASS (`test/features/vehicle_documents/presentation/vehicle_document_cubit_test.dart` — contrato base `loading→error`; `test/features/tecnomecanica/data/repository/tecnomecanica_repository_impl_test.dart` — `otro DioException — retorna Left`) | |

### 9B. Guardado falla por error del backend

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 9B.1 | Simula un error 500 al guardar el RTM | Se retorna `Left(DomainException)`; se muestra `tecnomecanica_save_error` en el formulario; el RTM no se guarda localmente | 🤖✅ Auto-PASS (`test/features/tecnomecanica/data/repository/tecnomecanica_repository_impl_test.dart` — `saveTecnomecanica` camino de error) | |

### 9C. Eliminación falla por error del backend

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 9C.1 | Simula un error al eliminar el RTM | Se retorna `Left`; no se limpia el estado local; se debería mostrar algún feedback de error al usuario (verificar UX real, no solo el contrato del cubit) | |

---

## 10. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso al código, logs, consola de desarrollo o backend.

| # | Verificación | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 10.1 | Correr `flutter test test/features/tecnomecanica/` | Todos los tests del feature pasan en verde | |
| 10.2 | Correr `flutter test test/features/vehicle_documents/` | Todos los tests de la base compartida pasan en verde | |
| 10.3 | Correr `dart analyze` | Sin issues nuevos en `lib/features/tecnomecanica/` | |
| 10.4 | Revisar en el backend (`rideglory-api`, `vehicles-ms/src/vehicles/tecnomecanica.service.spec.ts`) que la exención de vehículos <2 años se calcula correctamente en el servidor | El spec del backend pasa en verde y la exención se aplica según fecha de matrícula real | |
| 10.5 | Revisar `api-gateway/src/scheduler/notification-scheduler.service.spec.ts` para los recordatorios `rtm_expiry_reminder_30d/7d/0d` | Los jobs se programan al guardar un RTM y se cancelan al reemplazarlo antes del vencimiento | |
| 10.6 | Confirmar que **no existe** un test Patrol (`integration_test/`) para el flujo de tecnomecánica (a diferencia de SOAT) | Gap conocido: agregar `integration_test/tecnomecanica_manual_capture_patrol_test.dart` análogo al de SOAT si se quiere e2e completo | |
| 10.7 | Confirmar que no existen widget tests para `tecnomecanica_status_page.dart`, `tecnomecanica_manual_capture_page.dart`, `tecnomecanica_data_view.dart`, `tecnomecanica_status_view.dart`, `tecnomecanica_empty_state.dart`, `tecnomecanica_exemption_notice.dart` (gap de cobertura conocido, igual que en SOAT) | Registrar como deuda técnica si se requiere elevar cobertura de presentation | |
| 10.8 | Confirmar el fix: `TecnomecanicaExemptionNotice` ya está instanciado en el `build()` de `tecnomecanica_empty_state.dart`, antes del CTA (ver "Bugs encontrados" al final del documento) | RESUELTO: el docstring de `TecnomecanicaEmptyState` ahora coincide con el comportamiento real; cubierto por test de regresión (`tecnomecanica_empty_state_test.dart`) | ✅ |

---

## Bugs encontrados

### 1. `TecnomecanicaExemptionNotice` nunca se renderiza en `TecnomecanicaEmptyState` (RESUELTO)

- **Archivo:** `lib/features/tecnomecanica/presentation/widgets/tecnomecanica_empty_state.dart`
- **Evidencia original:** el widget importaba `TecnomecanicaExemptionNotice` (línea 8) y su docstring de clase decía explícitamente "Also shows `[TecnomecanicaExemptionNotice]` above the CTA when applicable", pero el `build()` nunca instanciaba `TecnomecanicaExemptionNotice` — el import quedaba muerto.
- **Impacto (antes del fix):** un usuario con un vehículo exento de RTM (<2 años) que aún no había registrado un RTM no veía ningún aviso de exención en la pantalla de estado vacío; solo lo veía si entraba al formulario de captura manual (y solo en modo creación, ver hallazgo del caso 5.3).
- **Fix aplicado:** se agregó `const TecnomecanicaExemptionNotice()` en el `build()`, justo antes del botón CTA de registro.
- **Test de regresión:** `test/features/tecnomecanica/presentation/widgets/tecnomecanica_empty_state_test.dart` — monta `TecnomecanicaEmptyState` y verifica que `TecnomecanicaExemptionNotice` aparece en el árbol de widgets; si alguien vuelve a quitarlo, el test falla.
- **Casos relacionados:** 5.2, 10.8.
- **Clasificación:** defecto de código, **RESUELTO** y cubierto por test automatizado.

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1, 2, 3, 4 y 6 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad (secciones 5, 7, 8 o 9), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 4 o 6 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
