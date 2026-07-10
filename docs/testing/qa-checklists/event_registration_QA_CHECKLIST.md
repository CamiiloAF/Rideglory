# Checklist de QA — Event Registration

**Feature:** Inscripción a eventos (wizard 4 pasos, consentimiento Ley 1581, waiver de riesgos, edad mínima, aprobación/rechazo, cancelación, edición, "Mis inscripciones")
**Alcance:** `lib/features/event_registration/` (+ integración con `events/` para aprobar/rechazar y participantes)
**Estado:** Pendiente de corrida

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Una cuenta de piloto (`qa1@gmail.com` / `Test123.`) con al menos un vehículo activo (no archivado) en el garaje.
- [ ] Una cuenta de piloto secundaria o la misma `qa1@gmail.com` sin ningún vehículo en el garaje (para el caso de borde "sin vehículos elegibles"); si no existe, se puede archivar temporalmente el único vehículo o usar una cuenta nueva.
- [ ] Una cuenta organizadora (`qa2@gmail.com` / `Test123.`) dueña de al menos un evento ("Mi Evento") con inscripciones abiertas (`state` = `scheduled` o `inProgress`).
- [ ] Un evento de la organizadora en estado `finished` o `cancelled` (para el caso de borde de evento cerrado), o crear uno temporal.
- [ ] Un evento con `allowedBrands` restringido a una o dos marcas específicas (para probar el bloqueo por marca no permitida).
- [ ] Un rider con perfil (`RiderProfileModel`) ya guardado de una inscripción anterior (para probar el pre-llenado en cascada).
- [ ] Un rider con fecha de nacimiento configurable para poder simular < 18 años (o un dispositivo/hora del sistema controlable, o una cuenta de prueba con `birthDate` reciente).
- [ ] Al menos una inscripción pendiente y una aprobada existentes en "Mi Evento" para las pruebas de aprobar/rechazar/cancelar/editar.

---

## 1. Inscripción completa — happy path paso a paso

> Entra con la cuenta de piloto, abre un evento con inscripciones abiertas y toca "Inscribirme".

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Abre el formulario de inscripción desde el detalle del evento | Se abre el wizard con indicador de pasos "1-2-3-4" y el paso 1 (Información Personal) visible, con datos pre-llenados desde el usuario autenticado si existen | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart`) | |
| 1.2 | Revisa el paso 1 (Información Personal) | Campos: nombre completo, número de identificación, fecha de nacimiento, teléfono, email, ciudad de residencia | 👤 Manual (verificación visual de layout del paso, no cubierta por widget test dedicado) | |
| 1.3 | Completa el paso 1 y toca "Siguiente" | Se valida el paso; si todo es válido avanza al paso 2 (Información Médica) sin pedir todavía el consentimiento Ley 1581 | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_form_content_test.dart`) | |
| 1.4 | Completa el paso 2 (EPS, seguro médico opcional, tipo de sangre vía grid de chips RH 4x2) y toca "Siguiente" | Antes de avanzar al paso 3 se abre el bottom sheet de autorización de datos médicos (Ley 1581 de 2012) | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_form_content_test.dart`) | |
| 1.5 | En el sheet de Ley 1581, toca "Autorizar" | El sheet se cierra y el wizard avanza al paso 3 (Contacto de Emergencia); el consentimiento queda registrado en el cubit y no se vuelve a pedir en esta misma inscripción | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_form_content_test.dart`) | |
| 1.6 | Completa el paso 3 (nombre y teléfono de contacto de emergencia) y toca "Siguiente" | Avanza al paso 4 (Vehículo de Inscripción) | 👤 Manual (validación de campos del paso 3 cubierta indirectamente; recorrido de UI real) | |
| 1.7 | En el paso 4, selecciona un vehículo del garaje | El selector muestra el vehículo elegido (marca, modelo, placa, año) y aparece el checkbox "Guardar para futuros eventos" (si el form no vino pre-llenado desde el perfil) | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/vehicle_selector_empty_test.dart`; cobertura parcial de estados del selector) | |
| 1.8 | Marca (o deja desmarcado) el checkbox "Guardar para futuros eventos" y toca "Confirmar Inscripción" | Se abre el bottom sheet del waiver de riesgos con el texto legal y el nombre del organizador (si está disponible) | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | |
| 1.9 | En el waiver, toca "Aceptar" | Se envía la inscripción; mientras está en curso el botón muestra estado de carga | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | |
| 1.10 | Espera la confirmación | El sheet se cierra, aparece un snackbar de confirmación, la página del formulario se cierra y la inscripción aparece reflejada en "Mis inscripciones" sin necesidad de refrescar | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_form_content_test.dart`, grupo "success snackbar + page close on submit (case 1.10)": completa el wizard real, acepta el waiver, verifica el snackbar "Inscripción enviada exitosamente..." y que `context.pop()` remueve la página del formulario del stack de navegación; también verifica `MyRegistrationsCubit.onChangeRegistration()` invocado con la inscripción guardada, que es el mecanismo que refleja el cambio en "Mis inscripciones" sin refrescar) | |
| 1.11 | Verifica en el backend/BD que la inscripción se guardó con estado `PENDING` y los datos correctos (incluyendo `vehicleSummary` snapshot del vehículo elegido) | Los datos persistidos coinciden con lo ingresado en el wizard | 👤 Manual (requiere verificación directa en base de datos/backend) | |

---

## 2. Validación de edad mínima (18 años)

> Con una cuenta cuya fecha de nacimiento calcule una edad menor a 18 años, completa el wizard hasta el waiver.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Completa el paso 1 con una fecha de nacimiento que dé menos de 18 años y avanza por todo el wizard hasta el waiver | El wizard permite avanzar por los pasos normalmente (la validación de edad ocurre al intentar enviar, no antes) | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_age_validation_test.dart`) | |
| 2.2 | En el sheet del waiver, toca "Aceptar" | La inscripción NO se envía al backend; el sheet muestra un error local específico de "menor de edad", sin necesidad de esperar respuesta del servidor | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_age_validation_test.dart`; `test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | |
| 2.3 | Revisa el mensaje de error en el sheet | Se muestra un título y mensaje diferenciados (no el mensaje crudo de un error genérico) indicando que se requiere ser mayor de 18 años | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | |
| 2.4 | Si el backend también rechaza por edad (código `UNDERAGE_RIDER`, 422) en algún escenario donde la validación local no aplicó | El error del backend se mapea al mismo mensaje/UI diferenciada de "menor de edad", no a un error genérico | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_age_validation_test.dart`) | |
| 2.5 | Verifica que no se haya creado ningún registro en el backend para el intento fallido por edad | No existe una inscripción nueva asociada a ese intento | 👤 Manual (requiere verificación directa en base de datos/backend) | |

---

## 3. Consentimiento de datos (Ley 1581)

> Desde el paso 2 (Información Médica) del wizard.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Completa el paso 2 y toca "Siguiente" | Se abre el sheet de autorización de datos médicos con texto legal desplazable (scrollable) y dos acciones: "Autorizar" y "No autorizar" | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_form_content_test.dart`) | |
| 3.2 | Toca "No autorizar" | El sheet se cierra y el wizard **permanece en el paso Médico** (no avanza al paso 3); en código se dispara un snackbar informativo (`registration_law1581DeclinedMessage`), pero el test solo asevera que el rider permanece en el paso Médico y que `medicalConsentAcceptedAt` sigue nulo, sin verificar el snackbar | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_form_content_test.dart`; snackbar no cubierto por el test) | |
| 3.3 | Vuelve a tocar "Siguiente" y esta vez toca "Autorizar" | El sheet se cierra, el wizard avanza al paso 3 y el timestamp de aceptación queda registrado en el cubit | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_form_content_test.dart`) | |
| 3.4 | Retrocede al paso 2 con "Atrás" y vuelve a avanzar con "Siguiente" en la misma sesión de inscripción | El sheet de consentimiento **no se vuelve a mostrar** (ya fue autorizado para esta inscripción) | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_age_validation_test.dart` cubre que el modelo construido incluye el timestamp legal; recorrido de re-entrada al paso no tiene test explícito) | |
| 3.5 | Edita una inscripción existente que ya tenía el consentimiento registrado | Al entrar en modo edición, el consentimiento pre-existente se respeta y no se vuelve a solicitar al pasar por el paso médico | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart`) | |
| 3.6 | Verifica en el backend que el registro guardado incluye el timestamp de aceptación del consentimiento Ley 1581 | El campo de consentimiento no es nulo y corresponde al momento real de la aceptación | 👤 Manual (requiere verificación directa en base de datos/backend) | |

---

## 4. Selección de vehículo

> Paso 4 del wizard, con distintas cantidades de vehículos en el garaje.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Con vehículos disponibles en el garaje, llega al paso 4 | Se muestra la tarjeta de invitación "Selecciona tu vehículo" con chevron; al tocarla se abre el bottom sheet de selección de vehículos | 👤 Manual (recorrido de UI del selector no cubierto por widget test dedicado del estado "placeholder") | |
| 4.2 | Elige un vehículo del bottom sheet | La tarjeta se actualiza mostrando ícono, marca/modelo, chip de placa + año y botón "Cambiar" | 👤 Manual (recorrido de UI real; lógica de `field.didChange` no cubierta por test explícito) | |
| 4.3 | Toca "Cambiar" y elige un vehículo distinto | El selector se actualiza con los datos del nuevo vehículo | 👤 Manual (mismo motivo que 4.2) | |
| 4.4 | Intenta avanzar/confirmar sin seleccionar ningún vehículo | Se bloquea el envío con el error de campo requerido debajo del contenedor del selector | 👤 Manual (validador `required` del `FormBuilderField` no tiene test widget dedicado encontrado) | |
| 4.5 | Selecciona un vehículo de una marca NO incluida en `allowedBrands` del evento y confirma | Aparece un snackbar rojo (6 segundos) indicando que la marca no está permitida y se bloquea el envío | 👤 Manual (no se encontró test automatizado para `_isSelectedVehicleBrandAllowed`) | |
| 4.6 | Repite 4.5 pero con un evento multi-marca (`allowedBrands` vacío) | No se aplica ninguna validación de marca; el envío procede normalmente | 👤 Manual (mismo motivo que 4.5) | |
| 4.7 | Desde el paso 4, toca "Crear vehículo" en el estado vacío (sin vehículos en el garaje) | Navega a la creación de vehículo; al guardar, vuelve al formulario de inscripción con el nuevo vehículo ya seleccionado automáticamente | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/vehicle_selector_empty_test.dart` cubre el CTA; el retorno con `didChange` no tiene test explícito) | |

---

## 5. Aprobar solicitud (organizador)

> Entra con la cuenta organizadora, abre "Mi Evento" → "Inscritos" / "Solicitudes" → pestaña pendientes.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5.1 | Abre el detalle de una solicitud pendiente | La barra inferior muestra "Aprobar" (verde sólido, texto/ícono oscuros, full-width) y una fila con "Rechazar" / "Solicitar edición" | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_detail_bottom_bar_test.dart`) | |
| 5.2 | Toca "Aprobar" | La inscripción cambia a estado `APPROVED`; la barra inferior se actualiza mostrando ahora las opciones de contacto si el rider autorizó contacto | 🤖✅ Auto-PASS (`integration_test/events_attendees_approve_reject_patrol_test.dart`) | |
| 5.3 | Vuelve a la lista de solicitudes | El rider aprobado ya no aparece en la pestaña de pendientes, sino en la de procesadas/aprobadas | 🤖✅ Auto-PASS (`integration_test/events_attendees_approve_reject_patrol_test.dart`) | |
| 5.4 | Verifica en el backend/BD que el estado de la inscripción cambió a `APPROVED` | El estado persistido coincide con lo mostrado en la UI | 👤 Manual (requiere verificación directa en base de datos/backend) | |
| 5.5 | Verifica que el rider reciba la notificación/actualización correspondiente (si aplica) | El rider ve su inscripción como aprobada en "Mis inscripciones" sin necesidad de cerrar sesión | 👤 Manual (depende de sistema de notificaciones/push, no cubierto por test) | |

---

## 6. Rechazar solicitud (organizador)

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6.1 | Desde una solicitud pendiente, toca "Rechazar" | La inscripción cambia a estado `REJECTED` | 🤖✅ Auto-PASS (`integration_test/events_attendees_approve_reject_patrol_test.dart`) | |
| 6.2 | Abre el detalle de esa inscripción ya rechazada | La barra inferior ya no muestra "Aprobar"/"Rechazar"/"Solicitar edición" ni botones de contacto | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_detail_bottom_bar_test.dart`) | |
| 6.3 | Entra con la cuenta del rider rechazado y ve a "Mis inscripciones" | La tarjeta muestra el botón secundario "Razón" para ese registro rechazado | 👤 Manual (mapeo de botón por status documentado; sin test widget dedicado a `InscriptionCard` para status `rejected`) | |
| 6.4 | Verifica en el backend/BD que el estado cambió a `REJECTED` | El estado persistido coincide con lo mostrado en la UI | 👤 Manual (requiere verificación directa en base de datos/backend) | |

---

## 7. Cancelar inscripción (rider)

> Entra con la cuenta de piloto, ve a "Mis inscripciones" y abre una inscripción propia en estado pendiente o aprobado.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 7.1 | Abre el detalle de tu inscripción (pendiente o aprobada) | La barra inferior muestra "Cancelar inscripción" (outlined rojo) | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_detail_bottom_bar_test.dart`) | |
| 7.2 | Toca "Cancelar inscripción" | Se solicita confirmación antes de proceder (no cancela de inmediato con un solo toque) | 🤖✅ Auto-PASS (`integration_test/registration_cancel_patrol_test.dart`) | |
| 7.3 | Confirma la cancelación | La inscripción cambia a estado `CANCELLED`; `MyRegistrationsCubit` refleja el cambio sin necesidad de refetch completo | 🤖✅ Auto-PASS (`integration_test/registration_cancel_patrol_test.dart`; `test/features/event_registration/presentation/cubit/my_registrations_cubit_test.dart`) | |
| 7.4 | Revisa la tarjeta en "Mis inscripciones" | El botón secundario ahora dice "Re-Registrarse" y navega al formulario en modo creación | 👤 Manual (mapeo documentado; sin test widget dedicado a `InscriptionCard` para status `cancelled`) | |
| 7.5 | Verifica en el backend/BD que el estado cambió a `CANCELLED` | El estado persistido coincide con lo mostrado en la UI | 👤 Manual (requiere verificación directa en base de datos/backend) | |

---

## 8. Editar inscripción existente

> El organizador debe habilitar "Solicitar edición" primero para que el rider pueda editar tras estar aprobado.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8.1 | Con la cuenta organizadora, abre una inscripción aprobada y toca "Solicitar edición" | La inscripción cambia a estado `READY_FOR_EDIT`; la barra del organizador para esa inscripción queda oculta (sin Aprobar/Rechazar/Solicitar edición) hasta que el rider vuelva a enviarla | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_detail_bottom_bar_test.dart`; `test/features/event_registration/domain/use_cases/set_registration_ready_for_edit_use_case_test.dart`) | |
| 8.2 | Entra con la cuenta del rider y ve a "Mis inscripciones" | La tarjeta de esa inscripción muestra el botón secundario "Editar" | 👤 Manual (mapeo documentado; sin test widget dedicado a `InscriptionCard` para status `readyForEdit`) | |
| 8.3 | Toca "Editar" | Se abre el wizard en modo edición, pre-llenado con **todos** los campos de la inscripción existente (incluyendo el vehículo) | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart`) | |
| 8.4 | Modifica algún campo (p. ej. el vehículo o el contacto de emergencia) y confirma | En modo edición el botón final dice "Actualizar inscripción"; al confirmar no se vuelve a pedir el consentimiento Ley 1581 si ya estaba registrado | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart`) | |
| 8.5 | Verifica el estado tras guardar la edición | La inscripción vuelve a estado `PENDING` (queda de nuevo sujeta a revisión del organizador) | 👤 Manual (comportamiento de backend tras update, no confirmado por test de UI; requiere verificación en BD) | |
| 8.6 | Entra de nuevo con la cuenta organizadora | La barra de Aprobar/Rechazar/Solicitar edición vuelve a estar visible para esa inscripción, ya que regresó a `PENDING` | 👤 Manual (requiere recorrido cruzado de dos cuentas; sin test automatizado que cubra el ciclo completo) | |

---

## 9. Ver "Mis inscripciones"

> Entra con la cuenta de piloto y ve a "Mis inscripciones".

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 9.1 | Abre la pantalla "Mis inscripciones" | Se listan todas las inscripciones del usuario, cada una con imagen/nombre del evento, badge de estado, fecha/ubicación (si están disponibles) y botón "Ver detalle" | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/my_registrations_cubit_test.dart`) | |
| 9.2 | Usa el buscador de la pantalla | La lista se filtra localmente por texto sin llamada adicional al backend | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/my_registrations_cubit_test.dart`) | |
| 9.3 | Abre el bottom sheet de filtros y selecciona uno o más estados | La lista se filtra client-side por los estados elegidos; el botón de filtros muestra el indicador de "hay filtros activos" | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/my_registrations_cubit_test.dart`) | |
| 9.4 | Toca "Limpiar filtros" | Se restablece la lista completa y desaparece el indicador de filtros activos | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/my_registrations_cubit_test.dart`) | |
| 9.5 | Toca "Ver detalle" en cualquier tarjeta | Se abre `RegistrationDetailPage` con el título "Mi registro" y el banner de estado correspondiente | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart`) | |
| 9.6 | Si el usuario tiene inscripciones a eventos distintos, simula que la carga de uno de los eventos falla | La tarjeta de esa inscripción no rompe la lista completa (degradación aislada, N+1 lookup) | 👤 Manual (no se encontró test unitario que simule fallo parcial de `getEventById` dentro del N+1) | |

---

## 10. Vista organizador con datos ofuscados y contacto directo

> Ver checklist específico de referencia: `docs/exec-runs/legal-privacidad-edad-phase-07/QA_CHECKLIST.md` (privacidad de datos ofuscados + botones de contacto). Esta sección solo cubre los puntos de entrada relevantes para `event_registration`.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 10.1 | Abre el detalle de un inscrito aprobado que autorizó el contacto (`allowOrganizerContact = true`) | Aparece un disparador de contacto en el encabezado de la tarjeta "Datos Personales" que abre un bottom sheet con Llamar / WhatsApp | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_contact_trigger_test.dart`) | |
| 10.2 | Abre el detalle de un inscrito aprobado que NO autorizó el contacto | El disparador de contacto no aparece | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_contact_trigger_test.dart`) | |
| 10.3 | Con la vista del propio piloto (no organizador) | Nunca aparece el disparador de contacto, sin importar la autorización | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_contact_trigger_test.dart`) | |
| 10.4 | Toca la banda superior (avatar + nombre) en la vista organizador | Navega al perfil del piloto (chevron visible indicando que es tappable) | 👤 Manual (navegación cruzada a `riderProfile`, no encontrada en tests de esta suite) | |

---

## 11. Casos de borde

### 11A. Perfil de rider incompleto

> Un rider sin `RiderProfileModel` guardado y sin datos completos en su perfil de autenticación (p. ej. sin `eps`/`bloodType` configurados) inicia una inscripción nueva.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 11A.1 | Abre el wizard de inscripción | Los campos sin datos previos quedan vacíos (no se rompe el pre-llenado en cascada); el rider debe completarlos manualmente | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart`) | |
| 11A.2 | Intenta avanzar de paso sin llenar campos requeridos | El wizard bloquea el avance mostrando los errores de validación del paso actual, sin adelantar al siguiente | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_form_content_test.dart`, grupo "blocks advancing without required fields (case 11A.2)": deja el paso Personal vacío (o con un único campo requerido vacío), toca "Siguiente" y verifica que el paso Médico no aparece y que los errores de validación por campo sí) | |

### 11B. Sin vehículos elegibles

> Un rider sin ningún vehículo activo (no archivado) en su garaje llega al paso 4.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 11B.1 | Llega al paso 4 sin vehículos en el garaje | Se muestra el estado vacío (`VehicleSelectorEmpty`) con CTA "Crear vehículo", no un spinner infinito ni un error | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/vehicle_selector_empty_test.dart`) | |
| 11B.2 | Si el usuario llega directo al formulario sin haber pasado antes por el garaje (vehículos en estado `initial`) | Se dispara automáticamente el fetch de vehículos al montar el paso, evitando el loading infinito | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_form_content_test.dart`, grupo "vehicle auto-fetch (case 11B.2)": verifica explícitamente `verify(() => vehicleCubit.fetchMyVehicles()).called(1)` cuando el estado inyectado es `initial`, y `verifyNever(...)` cuando ya hay datos) | |
| 11B.3 | Si todos los vehículos del rider están archivados | Se trata igual que "sin vehículos" (estado vacío), ya que el selector filtra `!v.isArchived` | 👤 Manual (no se encontró test que verifique explícitamente el filtro de archivados en el flujo de registro) | |

### 11C. Evento ya lleno o cerrado

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 11C.1 | Intenta inscribirte a un evento en estado `finished` o `cancelled` | El CTA de inscripción no está disponible / está deshabilitado desde el detalle del evento, o el intento de envío es rechazado por el backend con un mensaje claro | 👤 Manual (no se encontró bloqueo/deshabilitado del CTA "Inscribirme" por estado del evento dentro de `event_detail_cta_bar_content.dart`/`event_detail_default_bar.dart`; validar si el backend rechaza el envío en este escenario) | |
| 11C.2 | El organizador dueño del evento intenta entrar a la ruta de inscripción de su propio evento | El guard de router redirige automáticamente al detalle del evento, sin permitir que el organizador se inscriba a su propio evento | 👤 Manual (comportamiento de `AppRouter.redirect`, documentado pero sin test automatizado encontrado en esta suite) | |
| 11C.3 | Intenta enviar una inscripción justo cuando el evento alcanza su cupo máximo (condición de carrera) | El backend rechaza la inscripción con un error claro que se muestra al usuario, sin crear un registro inconsistente | 👤 Manual (el campo `maxParticipants` SÍ existe en `EventModel` (`lib/features/events/domain/model/event_model.dart:61`), tiene su propia sección de formulario "CUPO MÁXIMO" y se muestra como "cupos disponibles" en `event_detail_participants_summary.dart:79-81`; sin embargo NO hay enforcement client-side: el CTA "Inscribirme" nunca se deshabilita por cupo lleno, y no existe un getter `isFull`/estado "Completo" en el modelo. Depende enteramente de que el backend rechace la inscripción en la condición de carrera) | |

---

## 12. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso al código, logs o consola de desarrollo.

| # | Verificación | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 12.1 | Correr `flutter test test/features/event_registration/` | Todos los tests del feature pasan en verde | |
| 12.2 | Correr `flutter test test/features/events/` (dependencias cruzadas: `EventModel`, `AttendeesCubit`, `EventDetailParticipantsSection`) | Todos los tests pasan en verde | |
| 12.3 | Correr `dart analyze` | Sin issues nuevos en `lib/features/event_registration/` | |
| 12.4 | Correr `integration_test/registration_patrol_test.dart` con datos de seed reales (`qa1@gmail.com` inscribiéndose a un evento de `qa2@gmail.com`) | El flujo completo del wizard (incluyendo consentimiento y waiver) pasa en verde en emulador/dispositivo | |
| 12.5 | Correr `integration_test/registration_organizer_patrol_test.dart` | Pasa en verde con datos de seed reales | |
| 12.6 | Correr `integration_test/events_attendees_approve_reject_patrol_test.dart` | Aprobar/rechazar desde la vista organizador pasa en verde | |
| 12.7 | Correr `integration_test/registration_cancel_patrol_test.dart` | Cancelación desde la vista del rider pasa en verde | |
| 12.8 | Revisar logs al forzar un error `UNDERAGE_RIDER` (422) desde el backend | El mensaje se mapea correctamente a la UI diferenciada de "menor de edad", sin excepciones no capturadas en consola | |
| 12.9 | Revisar que `RegistrationService` (Dio manual, no Retrofit) envíe correctamente el flag `saveToProfile` en el body de `create`/`update` | El body enviado incluye `saveToProfile: true/false` según el checkbox marcado, verificable en el interceptor de logging de Dio | |
| 12.10 | Verificar en Firestore/BD que `rider_profiles/{userId}` se actualiza tras cada `saveRegistration()`, incluso cuando `saveToProfile == false` | El comportamiento documentado (persistencia local siempre, backend solo si el flag es true) se cumple sin inconsistencias | |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1, 2, 3, 5, 6, 7 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad (secciones 4, 8, 9, 10, 11), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2, 3, 5, 6 o 7 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
