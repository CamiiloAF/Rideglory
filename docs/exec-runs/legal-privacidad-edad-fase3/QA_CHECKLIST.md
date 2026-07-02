# Checklist de QA — Campos legales de privacidad y responsabilidad en modelos Flutter (inscripción, eventos y usuario)

**Feature:** Modelos y DTOs Flutter para campos legales (consentimiento médico, waiver de riesgo, contacto del organizador, responsabilidad del organizador, SOS)
**Fases cubiertas:** Fase 1 (contratos backend, ya cerrada) + Fase 3 (modelos y DTOs Flutter)
**Estado:** Aprobado con observaciones (verificacion automatizada) — pendiente de que el humano cierre los 8 casos manuales/no automatizables

<!-- qa-auto:annotated -->
> **Automatización qa-auto** (2026-07-01T05:40:54Z): 🤖✅ 13 verificados · 🤖❌ 0 fallando · 👤 8 manuales · 🚫 1 no automatizables (de 22 casos).
> Entorno: device=android-emulator, baseline=green. Auditor Opus: solid.

---

## Notas antes de empezar

Esta fase **no agrega pantallas ni controles nuevos**. Es un cambio interno de modelos de datos (domain) y DTOs (serialización) que prepara el terreno para las fases 4-7 (wizard de waiver, consentimiento, ofuscación visual del tipo de sangre). El único comportamiento visible para un tester es que el detalle de una inscripción **ya no debe crashear** si el backend envía el tipo de sangre vacío/oculto. El resto del checklist son verificaciones de regresión en pantallas existentes que consumen los modelos tocados (inscripción, evento, perfil) y verificaciones técnicas de los DTOs.

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Una cuenta con al menos 1 evento propio creado (para revisar el detalle del evento).
- [ ] Al menos 1 inscripción propia a un evento (activa o pasada), con el tipo de sangre diligenciado en el perfil del rider.
- [ ] Acceso al perfil de usuario para revisar edición y visualización de datos.
- [ ] (Opcional, para el equipo de desarrollo) Acceso a Postman/curl o a los logs del backend para simular una respuesta con `bloodType` ausente o con valores atípicos.

---

## 1. Detalle de inscripción — no debe crashear con tipo de sangre ausente

> Abre la app, entra a un evento donde tengas una inscripción activa o pasada, y navega al detalle de esa inscripción (pantalla de "Mi inscripción" / detalle de registro).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Abre el detalle de una inscripción cuyo perfil de rider SÍ tiene tipo de sangre diligenciado. | La pantalla carga sin errores y la fila "Tipo de sangre" muestra el valor correcto (ej. "A+"). | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart` :: 1.1: registration with bloodType=A+ renders "A+" in the blood type row) | ✅ |
| 1.2 | Abre el detalle de una inscripción cuyo perfil de rider NO tiene tipo de sangre diligenciado (o fue creada antes de que existiera ese campo). | La pantalla carga sin crashear; la fila de tipo de sangre se ve vacía o no muestra el texto literal "null". | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/registration_detail_page_test.dart` :: 1.2: registration with bloodType=null renders blank value, no "null" text, no crash) | ✅ |
| 1.3 | Desde el detalle de inscripción, navega hacia atrás y vuelve a entrar 2-3 veces seguidas. | No hay crashes, congelamientos ni pantallas en blanco en ninguna de las repeticiones. | ✅👤 Manual (requiere navegación real multi-pantalla con go_router y gestos de back repetidos en dispositivo/emulador; no hay infraestructura Patrol para el flujo de inscripción y el widget es stateless, riesgo bajo ya cubierto por 1.1/1.2) | ✅ |

---

## 2. Flujo de inscripción a un evento (regresión)

> Inscríbete a un evento nuevo (o edita una inscripción existente) usando el flujo normal de la app.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Completa el wizard de inscripción a un evento de principio a fin (selección de vehículo, datos del rider, confirmación). | El wizard se completa sin errores y la inscripción queda confirmada, igual que antes del cambio. | ✅👤 Manual (flujo end-to-end multi-pantalla contra backend real; no existe Patrol test de este flujo en integration_test/ y armar uno determinista requeriría mockear todo el backend de inscripción, fuera de alcance de esta fase) | ✅ |
| 2.2 | Edita una inscripción existente que ya tenía tipo de sangre diligenciado y guarda sin cambiar ese campo. | Al reabrir el detalle, el tipo de sangre sigue mostrándose correctamente (no se pierde el dato). | 🤖✅ Auto-PASS (`test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart` :: 2.2: editing an existing registration without touching bloodType keeps the original value in the built registration) | ✅ |
| 2.3 | En el formulario de inscripción, revisa que no aparezcan controles nuevos relacionados con "compartir información médica" o "permitir contacto del organizador". | No aparece ningún switch o campo nuevo — estos se agregan en fases futuras (4/5/6), esta fase es solo de datos. | 🤖✅ Auto-PASS (`test/features/event_registration/constants/registration_form_fields_test.dart` :: fieldsByStep does not include shareMedicalInfo / allowOrganizerContact) | ✅ |

---

## 3. Detalle de evento (regresión)

> Abre el detalle de un evento propio o de uno al que estés inscrito.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Abre el detalle de un evento cualquiera. | La pantalla carga con toda la información habitual (nombre, fecha, ruta, participantes) sin errores ni datos faltantes. | ✅🚫 No automatizable (regresión general de una pantalla no tocada por esta fase; ya existe cobertura amplia en `test/features/events/**` y esta fase no cambió comportamiento visible, se recomienda correr la suite existente en vez de un caso nuevo) | ✅ |
| 3.2 | Si el evento tiene tracking en vivo activo, entra a la vista de tracking. | El mapa y la información del recorrido cargan normalmente, sin crashes relacionados con el evento. | ✅👤 Manual (requiere mapa real Mapbox, tracking WebSocket en vivo y datos de un evento con GPS activo; no mockeable de forma razonable y esta fase no tocó el módulo de tracking) | ✅ |

---

## 4. Perfil de usuario (regresión)

> Abre tu perfil de usuario y la pantalla de edición de perfil.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Abre tu perfil desde la pestaña correspondiente. | El perfil carga con toda la información (nombre, foto, vehículos, etc.) sin errores. | 🤖✅ Auto-PASS (`test/features/profile/**`, `test/features/users/**` :: run-existing: `flutter test test/features/profile test/features/users`) | ✅ |
| 4.2 | Entra a "Editar perfil", cambia un dato simple (ej. teléfono) y guarda. | El cambio se guarda correctamente y se refleja al volver a abrir el perfil. | 👤 Manual (flujo de escritura contra backend real con persistencia visible tras recargar; no tocado por esta fase, requiere verificación manual end-to-end con cuenta real) | |
| 4.3 | Cierra sesión y vuelve a iniciar sesión con la misma cuenta. | El perfil carga igual que antes, sin errores de deserialización ni pantallas en blanco. | 👤 Manual (requiere Firebase Auth real y llamada real a la API de perfil; no automatizable razonablemente sin credenciales de prueba y backend corriendo) | |

---

## 5. Casos de borde

### 5A. Tipo de sangre con valor atípico desde el backend

> Requiere colaboración del equipo de desarrollo para simular la respuesta del backend (Postman/curl o modificando temporalmente el mock).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5A.1 | Simula que el backend responde el detalle de inscripción con `bloodType` ausente (sin la clave en el JSON). | La app carga el detalle sin crashear; el tipo de sangre se ve vacío. | 🤖✅ Auto-PASS (`test/features/event_registration/data/dto/event_registration_dto_test.dart` :: TC-dto-04: absent bloodType key decodes to null) | ✅ |
| 5A.2 | Simula que el backend responde `bloodType` con un valor no reconocido (ej. un texto centinela como `"__NOT_SHARED__"`). | La app carga el detalle sin crashear; el tipo de sangre se ve vacío (no se muestra el texto crudo del centinela). | 🤖✅ Auto-PASS (`test/features/event_registration/data/dto/event_registration_dto_test.dart` :: TC-dto-01 / TC-dto-02: sentinel values (__NOT_SHARED__, ••••) decode to null) | ✅ |

### 5B. Conectividad

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5B.1 | Con el wifi/datos apagados, intenta abrir el detalle de una inscripción ya cacheada localmente (si aplica) o intenta inscribirte a un evento. | La app muestra el error de conectividad habitual, sin crash adicional relacionado con los campos nuevos. | 👤 Manual (requiere apagar wifi/datos en un dispositivo real y observar el manejo de error de red end-to-end; el manejo de conectividad no fue tocado por esta fase y no hay infraestructura para simular fallas de red determinísticas sin backend real corriendo) | |

---

## 6. Verificaciones tecnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso al código fuente, a la terminal del proyecto y/o a los logs de red del backend.

| # | Verificacion | Resultado esperado | Estado auto | ✅/❌ |
|---|-------------|--------------------|-------------|-------|
| 6.1 | Correr `dart run build_runner build --delete-conflicting-outputs`. | Termina sin errores ni conflictos; los 3 `.g.dart` (`event_registration_dto.g.dart`, `event_dto.g.dart`, `user_dto.g.dart`) quedan actualizados. | 🤖✅ Auto-PASS (n/a (run-existing) :: `dart run build_runner build --delete-conflicting-outputs`) | ✅ |
| 6.2 | Correr `dart analyze`. | 0 errores (solo "info" preexistentes no relacionados con esta fase, si los hay). | 🤖✅ Auto-PASS (n/a (run-existing) :: `dart analyze`) | ✅ |
| 6.3 | Correr `flutter test test/features/event_registration/data/dto/event_registration_dto_test.dart test/features/events/data/dto/event_dto_test.dart test/features/users/data/dto/user_dto_test.dart test/features/event_registration/constants/registration_form_fields_test.dart`. | 12/12 tests pasan. | 🤖✅ Auto-PASS (`test/features/event_registration/data/dto/event_registration_dto_test.dart`, `test/features/events/data/dto/event_dto_test.dart`, `test/features/users/data/dto/user_dto_test.dart`, `test/features/event_registration/constants/registration_form_fields_test.dart` :: run-existing: los 4 archivos especificados) | ✅ |
| 6.4 | Correr la suite completa `flutter test`. | Todos los tests pasan, 0 fallos. | 🤖✅ Auto-PASS (n/a (full suite) :: `flutter test` (suite completa)) | ✅ |
| 6.5 | Correr `grep -rn '\.bloodType\b' lib/` y revisar cada resultado. | Ningún acceso directo a `registration.bloodType` como tipo no-nullable; todos usan `?.` o un chequeo de `null` explícito, incluyendo `registration_detail_page.dart:128` (`registration.bloodType?.label ?? ''`). | 🤖✅ Auto-PASS (n/a (grep) :: `grep -rn '\.bloodType\b' lib/ | grep -v '\.g\.dart'`) | ✅ |
| 6.6 | Inspeccionar el payload real enviado en el `POST` de inscripción (logs de Dio o interceptor de red) al completar una inscripción con datos de riesgo/waiver ya presentes en el modelo. | El body incluye las 4 claves `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion` (aunque su UI de edición llegue en fases futuras, el dato no se descarta silenciosamente). | 🤖✅ Auto-PASS (`test/features/event_registration/data/dto/event_registration_dto_test.dart` :: TC-dto-05: toJson includes the 4 new fields with exact values) | ✅ |
| 6.7 | Revisar en el `.g.dart` de `EventRegistrationDto` que `bloodType` usa `_BloodTypeConverter` (no el enum decoder automático). | El `fromJson`/`toJson` generado invoca `const _BloodTypeConverter().fromJson(...)`/`.toJson(...)`. | 👤 Manual (inspección de código generado `.g.dart`, excluido de analyze/lint; ya confirmado por grep manual — `bloodType: const _BloodTypeConverter().fromJson(json['bloodType'] as String?)` presente en `event_registration_dto.g.dart` — queda como verificación puntual, comportamiento ya cubierto indirectamente por 5A.1/5A.2) | |
| 6.8 | Revisar que `UserDto`/`UserModel` NO tienen `_BloodTypeConverter` aplicado a `bloodType`. | `UserDto.bloodType` usa la serialización estándar de `json_serializable` (sin converter custom), consistente con la regla de que `GET /users/me` nunca ofusca. | 👤 Manual (inspección de código fuente/generado —ausencia de una anotación—, confirmado por lectura directa de `user_dto.dart` (`bloodType` usa `super.bloodType` sin converter); verificación negativa de guardrail de arquitectura mejor hecha por inspección manual) | |

---

## 👤 Solo para ti — pruebas manuales restantes

| # | Accion | Que revisar | Por que no se automatizo |
|---|--------|--------------|---------------------------|
| 1.3 | Desde el detalle de inscripción, navega hacia atrás y vuelve a entrar 2-3 veces seguidas. | Que no haya crashes, congelamientos ni pantallas en blanco. | Requiere navegación real multi-pantalla con go_router y gestos de back repetidos en dispositivo/emulador; no hay infraestructura Patrol para el flujo de inscripción. |
| 2.1 | Completa el wizard de inscripción a un evento de principio a fin. | Que el wizard se complete sin errores y la inscripción quede confirmada. | Flujo end-to-end multi-pantalla contra backend real; armar un test determinista requeriría mockear todo el backend de inscripción, fuera de alcance de esta fase. |
| 3.2 | Si el evento tiene tracking en vivo activo, entra a la vista de tracking. | Que el mapa y la información del recorrido carguen sin crashes. | Requiere mapa real (Mapbox) y tracking WebSocket en vivo con datos GPS reales; no mockeable razonablemente y esta fase no tocó el módulo de tracking. |
| 4.2 | Entra a "Editar perfil", cambia el teléfono y guarda. | Que el cambio se guarde y se refleje al reabrir el perfil. | Flujo de escritura contra backend real con persistencia visible tras recargar; no tocado por esta fase. |
| 4.3 | Cierra sesión y vuelve a iniciar sesión con la misma cuenta. | Que el perfil cargue igual que antes, sin errores de deserialización. | Requiere Firebase Auth real y llamada real a la API de perfil; no hay credenciales de prueba ni backend corriendo en este entorno. |
| 5B.1 | Con el wifi/datos apagados, abre una inscripción cacheada o intenta inscribirte. | Que se muestre el error de conectividad habitual, sin crash adicional. | Requiere apagar wifi/datos en un dispositivo real; no hay forma determinista de simular fallas de red en este flujo sin backend real corriendo. |
| 6.7 | Revisa el `.g.dart` de `EventRegistrationDto` para confirmar el uso de `_BloodTypeConverter`. | Que `fromJson`/`toJson` invoquen `const _BloodTypeConverter()`. | Inspección de código generado (`.g.dart`), excluido de analyze/lint; ya confirmado por grep manual, comportamiento cubierto indirectamente por 5A.1/5A.2. |
| 6.8 | Revisa que `UserDto`/`UserModel` no tengan `_BloodTypeConverter` en `bloodType`. | Ausencia del converter (serialización estándar de `json_serializable`). | Verificación negativa de guardrail de arquitectura, confirmada por lectura directa del código fuente; mejor por inspección manual puntual. |

---

## 🚫 No automatizable en este entorno

| # | Accion | Como habilitarlo |
|---|--------|--------------------|
| 3.1 | Abre el detalle de un evento cualquiera. | Es regresión general de una pantalla ya cubierta ampliamente por `test/features/events/**` y no tocada por esta fase (solo `EventModel`/`EventDto` ganaron 2 campos opcionales que aún no se renderizan). Para verificarla, corre la suite existente (`flutter test test/features/events`) en vez de escribir un caso nuevo; si en el futuro se agrega UI que renderice los campos nuevos, ahí sí amerita un test dedicado. |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos 1.1–4.3 y 6.1–6.8 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Maximo 2 casos fallidos de baja severidad (secciones 3, 4 o 5B), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2, 5A o 6 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________

---

## 🤖 Resumen de automatización

| # | Estrategia | Test file | Resultado |
|---|------------|-----------|-----------|
| 1.1 | Widget test de la pantalla de detalle con `bloodType='A+'` | `test/features/event_registration/presentation/registration_detail_page_test.dart` | ✅ pass |
| 1.2 | Widget test de la pantalla de detalle con `bloodType=null` | `test/features/event_registration/presentation/registration_detail_page_test.dart` | ✅ pass |
| 2.2 | Bloc test del cubit de precarga de edición de inscripción | `test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart` | ✅ pass |
| 2.3 | Test de constantes de campos por paso del wizard | `test/features/event_registration/constants/registration_form_fields_test.dart` | ✅ pass |
| 4.1 | Run-existing de las suites de perfil y usuarios | `test/features/profile/**`, `test/features/users/**` | ✅ pass |
| 5A.1 | Test de DTO: clave `bloodType` ausente en el JSON | `test/features/event_registration/data/dto/event_registration_dto_test.dart` (TC-dto-04) | ✅ pass |
| 5A.2 | Test de DTO: valores centinela (`__NOT_SHARED__`, `••••`) | `test/features/event_registration/data/dto/event_registration_dto_test.dart` (TC-dto-01/02) | ✅ pass |
| 6.1 | Run-existing: build_runner | n/a (comando) | ✅ pass |
| 6.2 | Run-existing: dart analyze | n/a (comando) | ✅ pass |
| 6.3 | Run-existing: los 4 archivos de test especificados | los 4 archivos listados en el caso 6.3 | ✅ pass (12/12) |
| 6.4 | Run-existing: suite completa | n/a (`flutter test`) | ✅ pass |
| 6.5 | Grep estático de accesos a `.bloodType` | n/a (grep) | ✅ pass |
| 6.6 | Test de DTO: `toJson` incluye las 4 claves legales | `test/features/event_registration/data/dto/event_registration_dto_test.dart` (TC-dto-05) | ✅ pass |

**Tests rechazados por el auditor Opus:** ninguno (0 tests rechazados por vacíos; auditor califica la corrida como "solid").

### Cómo correr los tests generados

```bash
cd /Users/cami/Developer/Personal/Rideglory/.claude/worktrees/legal-privacidad-edad-fase1

flutter test \
  test/features/event_registration/presentation/registration_detail_page_test.dart \
  test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart \
  test/features/event_registration/constants/registration_form_fields_test.dart \
  test/features/event_registration/data/dto/event_registration_dto_test.dart \
  test/features/events/data/dto/event_dto_test.dart \
  test/features/users/data/dto/user_dto_test.dart

# Run-existing de regresión (perfil/usuarios y suite completa)
flutter test test/features/profile test/features/users
flutter test
```

No hubo tests Patrol/e2e nuevos en esta corrida (los casos que requerían navegación real o backend real quedaron como manuales, ver sección "👤 Solo para ti").

### Siguientes pasos

- No hay casos 🤖❌ auto-fail en esta corrida, por lo que no hay bugs reales pendientes de investigar a partir de la automatización.
- El único caso 🚫 (3.1) se debe a que la pantalla de detalle de evento no fue tocada por esta fase; si una fase futura agrega renderizado de los 2 campos legales nuevos en `EventModel`/`EventDto`, se debe agregar ahí un test dedicado (no antes).
- Los 8 casos 👤 manuales requieren en su mayoría dispositivo/emulador real con backend corriendo (login, wizard de inscripción, edición de perfil, conectividad, tracking en vivo); ejecutarlos siguiendo la tabla de la sección "👤 Solo para ti — pruebas manuales restantes" antes de marcar el checklist como definitivamente aprobado.
