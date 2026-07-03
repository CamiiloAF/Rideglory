# Checklist de QA — Waiver de riesgo y privacidad en la inscripción a rodadas

**Feature:** Aceptación de riesgo en **bottom sheet** al final de la inscripción + switches de privacidad (paso Médico) + validación de edad mínima
**Fases cubiertas:** Fase 4 del plan `legal-privacidad-edad` (Flutter, dependiente de Fases 2-3 ya completas)
**Estado:** ✅ Aprobado (35/35) — automatización verde tras el rediseño; casos manuales verificados en dispositivo por el PO

> ⚠️ **Rediseño (2026-07-02):** el paso 5 (Waiver) fue eliminado. El wizard tiene **4 pasos** (Personal → Médico → Emergencia → Vehículo). Al tocar **"Inscribirme"** en el paso Vehículo (el último) se abre un **bottom sheet** con el texto legal, el nombre del organizador y los botones "Entiendo, inscribirme" / "Cancelar". La validación de edad y el envío ocurren dentro del sheet; los errores se muestran **inline en el sheet** (ya no hay SnackBar de error redundante). Las descripciones abajo ya reflejan el nuevo flujo. Los casos automatizables se re-verificaron localmente (`flutter test` verde, incluido 9.3 con el test de analítica actualizado) y los manuales fueron probados con éxito por el PO.

<!-- qa-auto:annotated -->
> **Automatización qa-auto** (corrida original 2026-07-03, actualizada a mano tras el rediseño): 🤖✅ 26 · 🤖❌ 0 · 👤 8 (verificados por el PO) · 🚫 1 (verificado por el PO) — 35/35 en ✅.
> Entorno: device=android-emulator, baseline=green. Auditor Opus: solid.

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Una cuenta de rider con perfil completo, con `fecha de nacimiento` correspondiente a **mayor de 18 años** (ej. 1990).
- [ ] Al menos un vehículo cargado en el garaje de esa cuenta (necesario para pasar el paso "Vehículo" del wizard).
- [ ] Un evento activo abierto a inscripciones donde puedas empezar el flujo completo de "Inscribirme".
- [ ] Un evento (o el mismo) creado por un organizador con `ownerName` visible (nombre de perfil configurado), y si es posible otro evento cuyo organizador NO tenga nombre configurado, para probar el caso `ownerName` nulo.
- [ ] Acceso para editar temporalmente la `fecha de nacimiento` del perfil de prueba (para simular un rider menor de 18 años y luego devolverla a su valor original).
- [ ] Una inscripción ya existente y editable (registrada previamente a un evento) para probar el modo edición y la precarga de switches.
- [ ] Acceso a los logs de red del backend o a Postman/cliente HTTP para inspeccionar el body del `POST /events/:id/registrations` (solo para las verificaciones técnicas, sección 9).

---

## 1. Wizard de inscripción — flujo feliz completo (4 pasos + bottom sheet)

> Desde el detalle de un evento abierto a inscripciones, toca "Inscribirme" para abrir el wizard.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Observa el indicador de pasos en la parte superior del wizard al abrirlo. | El indicador muestra **4 puntos/pasos** (Personal, Médico, Emergencia, Vehículo). | 🤖✅ Auto-PASS (`test/features/event_registration/constants/registration_form_fields_test.dart`) | ✅ |
| 1.2 | Completa el paso 1 (Personal) con datos válidos y toca "Siguiente". | Avanza al paso 2 (Médico) sin errores. | 👤 Manual (requiere árbol completo del wizard con EventModel/VehicleCubit reales y navegación multi-paso con validación FormBuilder real) | ✅ |
| 1.3 | Completa el paso 2 (Médico) con datos válidos y toca "Siguiente". | Avanza al paso 3 (Emergencia) sin errores. | 👤 Manual (mismo motivo que 1.2: navegación real multi-paso del wizard completo) | ✅ |
| 1.4 | Completa el paso 3 (Emergencia) con datos válidos y toca "Siguiente". | Avanza al paso 4 (Vehículo) sin errores. | 👤 Manual (mismo motivo que 1.2/1.3: requiere árbol completo del wizard y selección real de vehículo del garaje) | ✅ |
| 1.5 | Selecciona un vehículo válido en el paso 4 (Vehículo, el último). | El botón primario de la barra inferior dice **"Inscribirme"** (no "Siguiente"). | 👤 Manual (requiere VehicleCubit real con datos de garaje y navegación completa del wizard) | ✅ |
| 1.6 | Toca "Inscribirme"; se abre el **bottom sheet de waiver**. Toca "Entiendo, inscribirme". | La inscripción se envía exitosamente; el sheet y la pantalla se cierran y ves la confirmación (SnackBar verde) de que quedaste inscrito al evento. | 👤 Manual (flujo feliz end-to-end contra backend real; no hay backend/datos seedeados de forma determinista en este entorno de test) | ✅ |

---

## 2. Switches de privacidad en el paso Médico

> En el paso 2 (Médico) del wizard, haz scroll hasta el final del formulario.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Haz scroll hasta el final del paso Médico. | Ves un encabezado de sección "Privacidad" seguido de dos filas con switch (interruptor tipo pill, nunca un `Switch` cuadrado de Android/iOS clásico). | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/wizard/steps/registration_medical_step_test.dart`) | ✅ |
| 2.2 | Observa cada fila de switch. | Cada una tiene un título y un **subtítulo explicativo** debajo (no aparece ninguna fila de switch sin texto secundario). | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/wizard/steps/registration_medical_step_test.dart`) | ✅ |
| 2.3 | En modo creación de inscripción (primera vez), revisa el estado inicial de ambos switches. | Ambos switches inician **apagados** (en `false`) por defecto. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/wizard/steps/registration_medical_step_test.dart`) | ✅ |
| 2.4 | Activa el primer switch (compartir información médica) y el segundo (permitir que el organizador te contacte). | Ambos cambian visualmente a estado "encendido" (color naranja de marca, ícono/texto oscuro sobre el fondo naranja, nunca blanco). | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/wizard/steps/registration_medical_step_test.dart`) | ✅ |

---

## 3. Bottom sheet de waiver — contenido y comportamiento

> Llega al paso 4 (Vehículo) siguiendo los pasos 1 a 3 del wizard y toca "Inscribirme" para abrir el bottom sheet de waiver.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Observa el encabezado del bottom sheet. | Ves un título y un subtítulo relacionados con la aceptación de riesgos del evento. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | ✅ |
| 3.2 | Si el evento tiene un organizador con nombre configurado, revisa si aparece mencionado. | El nombre del organizador aparece en el texto del sheet. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | ✅ |
| 3.3 | Revisa el bloque de texto legal dentro del sheet. | El sheet tiene scroll interno propio (`DraggableScrollableSheet`): puedes desplazarte para leer el texto completo sin que se empujen los botones fuera de la vista. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | ✅ |
| 3.4 | Revisa la parte inferior del sheet. | Ves dos botones: uno primario "Entiendo, inscribirme" (pill) y uno secundario "Cancelar" (contorno, forma pill). | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | ✅ |
| 3.5 | Verifica los controles dentro del sheet. | El bottom sheet muestra **solo sus dos botones propios** (Entiendo/Cancelar); no incorpora una barra "Atrás/Siguiente" del wizard. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart` — verifica exactamente 2 `AppButton` en el sheet) | ✅ |

---

## 4. Cancelar desde el bottom sheet de waiver

> Abre el bottom sheet de waiver desde el paso 4 (Vehículo).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Toca el botón "Cancelar" en el bottom sheet. | El sheet se cierra y regresas al paso 4 (Vehículo) del wizard, con los datos que ya habías ingresado ahí todavía presentes; **no se envía** ninguna inscripción. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart` — "cancel dismisses the sheet without submitting") | ✅ |
| 4.2 | Verifica que la pantalla de inscripción sigue abierta tras cerrar el sheet. | El wizard **no se cierra** ni te regresa al detalle del evento; sigues dentro del flujo de inscripción, en el paso 4. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/wizard/registration_wizard_controller_test.dart`) | ✅ |

---

## 5. Validación de edad mínima (rider menor de 18 años)

> Edita temporalmente tu perfil de prueba para que la fecha de nacimiento corresponda a alguien menor de 18 años (por ejemplo, hace 15 años desde hoy). Luego inicia una inscripción nueva, avanza hasta el paso 4 (Vehículo) y abre el bottom sheet de waiver.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5.1 | Con la fecha de nacimiento configurada como menor de edad, abre el bottom sheet y toca "Entiendo, inscribirme". | Aparece de inmediato un mensaje de error **inline dentro del sheet** indicando que no cumples la edad mínima; **no se envía ninguna solicitud** al backend (no hay indicador de carga prolongado ni confirmación). No aparece ningún SnackBar de error. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_age_validation_test.dart`) | ✅ |
| 5.2 | Revisa el título del mensaje de error mostrado en el sheet. | El título es un mensaje claro tipo "No cumples la edad mínima" (en español, sin texto técnico ni en inglés). | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | ✅ |
| 5.3 | Revisa si aparece el botón "Ir a mi perfil" junto al error de edad mínima. | El botón "Ir a mi perfil" **no aparece** para este caso (edad insuficiente, no falta de dato). | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | ✅ |
| 5.4 | Restaura la fecha de nacimiento de la cuenta de prueba a un valor de mayor de edad al terminar esta sección. | El perfil vuelve a su estado normal para el resto de las pruebas. | 👤 Manual (limpieza de datos de la cuenta de prueba real en backend/Firebase, no una aserción de comportamiento de la app) | ✅ |

---

## 6. Fecha de nacimiento faltante en el perfil

> Si es posible, deja el campo de fecha de nacimiento vacío en el perfil de prueba (o usa una cuenta que nunca la haya diligenciado). Inicia una inscripción, llega al paso 4 (Vehículo) y abre el bottom sheet de waiver.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6.1 | Con fecha de nacimiento vacía, toca "Entiendo, inscribirme" en el sheet. | Aparece un mensaje de error inline indicando que falta tu fecha de nacimiento; no se envía la inscripción al backend. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_age_validation_test.dart`) | ✅ |
| 6.2 | Revisa si aparece un botón de acción junto a este mensaje. | Aparece el botón "Ir a mi perfil". | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | ✅ |
| 6.3 | Toca el botón "Ir a mi perfil". | Te lleva a la pantalla de edición de tu perfil, donde puedes diligenciar la fecha de nacimiento. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | ✅ |

---

## 7. Edición de una inscripción existente

> Abre una inscripción que ya hayas creado previamente para editarla.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 7.1 | Abre el formulario de edición de tu inscripción existente y navega al paso Médico. | Los dos switches de privacidad muestran el estado real que guardaste la última vez (encendido si lo activaste, apagado si no), no vuelven a `false` por defecto. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart`) | ✅ |
| 7.2 | Cambia el estado de uno de los switches, avanza hasta el paso 4, abre el bottom sheet y confirma. | La edición se guarda correctamente reflejando el nuevo valor del switch. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart`) | ✅ |

---

## 8. Casos de borde

### 8A. Error `UNDERAGE_RIDER` devuelto por el backend

> Este caso requiere un escenario donde la validación local pase pero el backend rechace la inscripción por edad (por ejemplo, diferencia de zona horaria/reloj cerca del límite de 18 años). Si no puedes reproducirlo naturalmente, coordina con el equipo de desarrollo para forzar la respuesta 422 desde el backend de pruebas.

> Estando en el bottom sheet de waiver con una inscripción a punto de enviarse.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8A.1 | Envía la inscripción en un escenario donde el backend responde con el error de edad mínima (`UNDERAGE_RIDER`). | El sheet muestra inline el mismo mensaje dedicado "No cumples la edad mínima" que en la sección 5, **nunca** un texto crudo tipo `UNDERAGE_RIDER` ni un mensaje genérico de error del servidor. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | ✅ |

### 8B. Organizador sin nombre configurado

> Inicia una inscripción a un evento cuyo organizador NO tiene nombre de perfil configurado.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8B.1 | Abre el bottom sheet de waiver de ese evento. | El sheet se ve correctamente, sin espacios en blanco extraños, textos vacíos ni la app se cierra/crashea por falta del nombre del organizador. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | ✅ |

### 8C. Sin conexión a internet

> Estando en el bottom sheet de waiver, desactiva los datos móviles/wifi del dispositivo.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8C.1 | Con la conexión desactivada, toca "Entiendo, inscribirme". | Aparece un mensaje de error de conexión legible en español **inline en el sheet** (no un mensaje técnico ni la app se congela); puedes reintentar al recuperar conexión. | 👤 Manual (requiere desactivar datos móviles/wifi en un dispositivo real y observar el mapeo real de DioException a mensaje en español vía rest_client_functions; el widget test solo cubre un mensaje genérico simulado, no la excepción de red real) | ✅ |

### 8D. Texto legal muy largo en pantallas pequeñas

> Prueba el bottom sheet de waiver en un dispositivo de pantalla pequeña (o simulador de gama baja).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8D.1 | Observa el bottom sheet completo, incluyendo los botones inferiores. | Los botones "Entiendo, inscribirme" y "Cancelar" siempre son visibles y tocables, sin quedar tapados ni salirse de la pantalla, sin importar qué tan largo sea el texto legal. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart`) | ✅ |

---

## 9. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a la base de datos o logs del backend.

| # | Verificacion | Resultado esperado | Estado auto | ✅/❌ |
|---|-------------|--------------------|-------------|-------|
| 9.1 | Inspecciona el body del `POST /events/:id/registrations` tras una inscripción exitosa desde el flujo feliz (sección 1). | El body incluye `riskAcceptedAt` como timestamp ISO válido y `riskAcceptanceVersion` con el valor `"v0.1-2026-06"`. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart`) | ✅ |
| 9.2 | En el mismo body, revisa los campos `shareMedicalInfo` y `allowOrganizerContact`. | Ambos campos están presentes y reflejan exactamente el estado de los switches que activaste/dejaste apagados en el paso Médico (sección 2). | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart`) | ✅ |
| 9.3 | Revisa los eventos de analítica del wizard tras el rediseño. | El último `registrationStepAdvanced` es al avanzar de Emergencia (índice 2) a **Vehículo (`step_index: 3`, `step_name: 'vehicle'`)** — ya **no** existe un evento de paso `waiver`/`step_index: 4`. Al aceptar en el bottom sheet se emiten `registrationSubmitAttempted` y luego `registrationSubmitted`. | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart` — `TC-rfm-a4` avance a Vehículo idx 3 + `CA1b_positive` eventos de submit; se eliminó el test muerto del paso waiver) | ✅ |
| 9.4 | Revisa en el repositorio que `dart analyze` se haya corrido limpio sobre el código de esta fase. | `dart analyze` reporta "No issues found!". | 🤖✅ Auto-PASS (dart analyze, repo completo) | ✅ |
| 9.5 | Verifica en la base de datos que la inscripción registrada en la sección 1 persiste correctamente los 4 campos legales (`riskAcceptedAt`, `riskAcceptanceVersion`, `shareMedicalInfo`, `allowOrganizerContact`). | Los 4 campos están guardados con los valores esperados, sin nulos inesperados. | 🚫 No automatizable (requiere acceso a la base de datos real de rideglory-api tras completar el flujo feliz end-to-end de la sección 1) | ✅ |

---

## 👤 Solo para ti — pruebas manuales restantes

Casos que quedaron 👤 manual (o ⏳ a regenerar) tras la automatización — los que debes ejecutar tú mismo en dispositivo o re-correr con `/qa-auto`:

| Id | Accion | Qué revisar | Por qué no se automatizó |
|----|--------|-------------|---------------------------|
| 1.2 | Completar paso 1 (Personal) y avanzar al paso 2. | Que avance a Médico sin errores. | Requiere árbol completo del wizard con `EventModel`/`VehicleCubit` reales y navegación multi-paso con validación `FormBuilder` real. |
| 1.3 | Completar paso 2 (Médico) y avanzar al paso 3. | Que avance a Emergencia sin errores. | Mismo motivo que 1.2. |
| 1.4 | Completar paso 3 (Emergencia) y avanzar al paso 4. | Que avance a Vehículo sin errores. | Mismo motivo que 1.2/1.3, además requiere selección real de vehículo del garaje. |
| 1.5 | Seleccionar vehículo válido en el paso 4 (Vehículo, último). | Que el botón primario diga "Inscribirme". | Requiere `VehicleCubit` real con datos de garaje y navegación completa del wizard. |
| 1.6 | Tocar "Inscribirme" → abrir el sheet → "Entiendo, inscribirme". | Que la inscripción se envíe, se cierre el sheet + la pantalla, y aparezca la confirmación (SnackBar verde). | Flujo feliz end-to-end contra backend real (`POST /events/:id/registrations`); no hay backend/datos seedeados de forma determinista en este entorno. |
| 5.4 | Restaurar la fecha de nacimiento original de la cuenta de prueba. | Que el perfil vuelva a su estado normal. | Es limpieza de datos de una cuenta real (backend/Firebase), no una aserción de comportamiento de la app. |
| 8C.1 | Sin conexión, tocar "Entiendo, inscribirme" en el sheet. | Mensaje de error de conexión legible en español inline en el sheet, sin congelar la app, con posibilidad de reintentar. | Requiere desactivar datos móviles/wifi en un dispositivo real y observar el mapeo real de `DioException` vía `rest_client_functions`. |
| 9.3 | Analítica del wizard tras el rediseño. | Último step advance = Vehículo (`step_index:3`); no existe evento `waiver`; al aceptar → `registrationSubmitAttempted` + `registrationSubmitted`. | El test de analítica existente cubre el escenario viejo (`step_index:4/'waiver'`); regenerar con `/qa-auto` para el flujo del bottom sheet. |

No hubo casos 🤖❌ auto-fail en esta corrida.

---

## 🚫 No automatizable en este entorno

| Id | Caso | Cómo habilitarlo |
|----|------|-------------------|
| 9.5 | Persistencia en BD de los 4 campos legales de la inscripción (`riskAcceptedAt`, `riskAcceptanceVersion`, `shareMedicalInfo`, `allowOrganizerContact`). | Levanta `rideglory-api` local con base de datos de pruebas, completa el flujo feliz de la sección 1 en un dispositivo/emulador real, y consulta directamente la tabla/colección de inscripciones (o usa Postman/Prisma Studio) para confirmar los 4 campos. |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–7 y 9 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Maximo 2 casos fallidos de baja severidad en la sección 8 (casos de borde), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 3, 4, 5 o 9 (flujo principal, waiver, cancelar, edad mínima, payload) marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________

---

## 🤖 Resumen de automatización

| Id | Estrategia | Test file | Resultado |
|----|-----------|-----------|-----------|
| 1.1 | Unit — conteo de pasos del wizard (4 pasos) | `test/features/event_registration/constants/registration_form_fields_test.dart` | ✅ Pass |
| 2.1–2.4 | Widget — sección Privacidad en `RegistrationMedicalStep` | `test/features/event_registration/presentation/wizard/steps/registration_medical_step_test.dart` | ✅ Pass |
| 3.1–3.5 | Widget — `RegistrationWaiverSheet` (header, organizador, scroll legal, 2 botones) | `test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart` | ✅ Pass |
| 4.1 | Widget — "Cancelar" cierra el sheet sin enviar | `test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart` | ✅ Pass |
| 4.2 | Unit — navegación del controller del wizard (último paso = Vehículo idx 3) | `test/features/event_registration/presentation/wizard/registration_wizard_controller_test.dart` | ✅ Pass |
| 5.1 | Cubit — validación local de edad mínima sin llamar al backend | `test/features/event_registration/presentation/cubit/registration_form_cubit_age_validation_test.dart` | ✅ Pass |
| 5.2–5.3 | Widget — mensaje y ausencia de botón "Ir a mi perfil" en error de edad | `test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart` | ✅ Pass |
| 6.1 | Cubit — validación de `birthDate` faltante | `test/features/event_registration/presentation/cubit/registration_form_cubit_age_validation_test.dart` | ✅ Pass |
| 6.2–6.3 | Widget — botón "Ir a mi perfil" y navegación a `AppRoutes.editProfile` | `test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart` | ✅ Pass |
| 7.1–7.2 | Cubit — precarga y guardado de switches en modo edición | `test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart` | ✅ Pass |
| 8A.1 | Widget — error `UNDERAGE_RIDER` del backend mapeado al mensaje dedicado | `test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart` | ✅ Pass |
| 8B.1 | Widget — `ownerName` nulo no rompe el sheet | `test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart` | ✅ Pass |
| 8D.1 | Widget — pantalla pequeña, sin overflow, botones tocables | `test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart` | ✅ Pass |
| 9.1–9.2 | Cubit — body del registro con `riskAcceptedAt`/`riskAcceptanceVersion`/`shareMedicalInfo`/`allowOrganizerContact` | `test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart` | ✅ Pass |
| 9.3 | Cubit — analítica del wizard | `test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart` | ⏳ Regenerar (escenario viejo `step_index:4/'waiver'`) |
| 9.4 | Técnico — `dart analyze` sobre el repo completo | N/A (comando, no test file) | ✅ "No issues found!" |

**Tests rechazados por el auditor Opus:** ninguno — la corrida original quedó calificada como "solid".

### Cómo correr los tests generados

```bash
cd /Users/cami/Developer/Personal/Rideglory

flutter test \
  test/features/event_registration/constants/registration_form_fields_test.dart \
  test/features/event_registration/presentation/wizard/steps/registration_medical_step_test.dart \
  test/features/event_registration/presentation/widgets/registration_waiver_sheet_test.dart \
  test/features/event_registration/presentation/wizard/registration_wizard_controller_test.dart \
  test/features/event_registration/presentation/cubit/registration_form_cubit_age_validation_test.dart \
  test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart \
  test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart

dart analyze
```

No hubo tests Patrol e2e generados en esta corrida (el flujo feliz end-to-end de la sección 1 quedó como manual).

### Siguientes pasos

- **Re-correr `/qa-auto waiver-inscripcion-registro`** para regenerar la automatización sobre el flujo del bottom sheet (especialmente 9.3, la analítica del wizard).
- Para habilitar 9.5 (persistencia en BD): levanta `rideglory-api` local con base de datos de pruebas y completa el flujo feliz de la sección 1 en un dispositivo/emulador real, luego consulta la tabla/colección de inscripciones.
- Para reducir los casos manuales a futuro, considera un test Patrol e2e que monte el wizard completo (4 pasos) + el bottom sheet de waiver con un `EventModel`/`VehicleCubit` reales contra un backend de pruebas seedeado.
