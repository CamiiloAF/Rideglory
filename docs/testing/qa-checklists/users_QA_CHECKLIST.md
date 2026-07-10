# Checklist de QA — Perfil de otro rider (Users)

**Feature:** `RiderProfilePage` (perfil público de otro rider) + privacidad de email + botón "Seguir" (`lib/features/users/`)
**Referencia:** `docs/features/users.md` (actualizada 2026-07-04)
**Estado:** Pendiente de ejecución

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Una cuenta de organizador (`qa2@gmail.com` o equivalente), dueña de al menos un evento ("Mi Evento").
- [ ] "Mi Evento" con al menos un inscrito visible en la sección "Inscritos", de un usuario DISTINTO al organizador (por ejemplo, la inscripción dejada por `qa1@gmail.com`).
- [ ] El rider inscrito debe tener `fullName` y `residenceCity` completos, y un `email` válido en su `UserModel` (para verificar que justamente ese email NO se muestra).
- [ ] Idealmente, un segundo rider inscrito con `residenceCity` o `fullName` nulo/vacío (casos de borde).
- [ ] Dispositivo o emulador con la app instalada.

---

## 1. Ver el perfil de otro rider desde la lista de asistentes

> Entra con la cuenta organizadora (`qa2`), abre "Mi Evento", ve a la sección "Inscritos" y toca un inscrito hasta llegar a su perfil.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Abre "Mi Evento" y ubica la sección "Inscritos" (o el preview de participantes) | Se ve al menos un inscrito distinto al organizador | 🤖✅ Auto-PASS (`integration_test/users_rider_profile_patrol_test.dart`) | |
| 1.2 | Toca la fila del inscrito | Se abre el detalle de inscripción en modo organizador (`RegistrationDetailPage`, `isOrganizerView: true`) | 🤖✅ Auto-PASS (`integration_test/users_rider_profile_patrol_test.dart`) | |
| 1.3 | Dentro del detalle, toca la banda de resumen del piloto (`RegistrationDetailRiderSummary`) | Navega a `RiderProfilePage` del asistente (`userId` distinto al del organizador logueado) | 🤖✅ Auto-PASS (`integration_test/users_rider_profile_patrol_test.dart`) | |
| 1.4 | Revisa el AppBar de la nueva pantalla | El título dice **"Perfil del motorista"** | 🤖✅ Auto-PASS (`integration_test/users_rider_profile_patrol_test.dart`) | |
| 1.5 | Revisa el contenido | Se ve el avatar con iniciales, el nombre completo, la ciudad (si existe) y la fila de estadísticas (eventos/seguidores/siguiendo) en "0" | 🤖✅ Auto-PASS (`test/features/users/presentation/pages/rider_profile_page_test.dart`, TC-2-27 "Data state shows rider name") | |
| 1.6 | Verifica el estado de carga y error | Mientras carga se ve el skeleton (`RiderProfileLoading`); si falla, se ve `RiderProfileError` con botón de reintentar que vuelve a llamar `fetchRiderProfile` | 🤖✅ Auto-PASS (`test/features/users/presentation/pages/rider_profile_page_test.dart`, TC-2-26 "Loading state...", TC-2-29 "Error state renders without crash", TC-2-30 "Initial state renders without crash") | |

---

## 2. Email oculto en perfil ajeno

> Verifica que el email del rider visitado nunca se muestra (commit `6cbd85c`, "ocultar email en perfil ajeno" — ver `docs/features/users.md` §3.3 y §9).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Estando en el perfil del rider (paso 1.4 en adelante), busca cualquier texto con "@" en la pantalla | No aparece ningún email en pantalla | 🤖✅ Auto-PASS (`integration_test/users_rider_profile_patrol_test.dart`, assert `find.textContaining('@')` `findsNothing`; `test/features/users/presentation/pages/rider_profile_page_test.dart`, TC-2-28 "Data state does not show rider email (privacy)") | |
| 2.2 | Compara con tu propio perfil (tab "Perfil", cuenta propia) | En tu propio perfil el email SÍ se muestra (comportamiento distinto intencional entre "mi perfil" y "perfil ajeno") | 👤 Manual (requiere comparar dos pantallas distintas del feature `profile`, fuera del alcance de los tests unitarios de `users`) | |

---

## 3. Botón "Seguir" — bottom sheet informativo

> El botón no ejecuta ninguna acción de follow/unfollow real; solo informa que la función llegará más adelante.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | En el perfil del rider, ubica el botón "Seguir" | El botón es visible debajo de la fila de estadísticas | 🤖✅ Auto-PASS (`test/features/users/presentation/widgets/rider_profile_content_test.dart`, `find.widgetWithText(AppButton, 'Seguir')` `findsOneWidget`) | |
| 3.2 | Toca "Seguir" | Se abre un bottom sheet/diálogo informativo con título **"Muy pronto"** | 🤖✅ Auto-PASS (`integration_test/users_rider_profile_patrol_test.dart`; `test/features/users/presentation/widgets/rider_profile_content_test.dart`, test "toca \"Seguir\" abre el diálogo/bottom sheet con título \"Muy pronto\"" — aislado, sin emulador, verifica también el mensaje completo del diálogo) | |
| 3.3 | Cierra el bottom sheet y vuelve a revisar el perfil | El botón "Seguir" sigue mostrando el mismo texto (no cambia a "Siguiendo" ni similar); no hubo ninguna llamada real de follow/unfollow | 👤 Manual (no existe endpoint ni cubit de follow real que verificar; es una confirmación de "nada cambió", difícil de aserorder automáticamente sin un mock de red que intercepte llamadas inexistentes) | |

---

## 4. Casos de borde

### 4A. Rider sin foto

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4A.1 | Abre el perfil de un rider sin foto configurada | El avatar (`RiderAvatar`) muestra las iniciales calculadas desde `fullName`, con fondo degradado; nunca un ícono roto | | |

### 4B. Rider sin ciudad

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4B.1 | Abre el perfil de un rider con `residenceCity` nulo o vacío | La fila con el ícono de ubicación no se renderiza; el resto de la pantalla se ve normal | 🤖✅ Auto-PASS (`test/features/users/presentation/widgets/rider_profile_content_test.dart`, tests "residenceCity nula" y "residenceCity vacía": no renderiza la fila de ciudad ni el ícono de ubicación") | |

### 4C. Rider sin nombre

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4C.1 | Abre el perfil de un rider con `fullName` nulo o vacío | Las iniciales se calculan a partir de un string vacío sin lanzar excepción; el texto del nombre queda vacío en pantalla, sin "null" | 🤖✅ Auto-PASS (`test/features/users/presentation/widgets/rider_profile_content_test.dart`, tests "fullName nulo" y "fullName vacío": `tester.takeException()` es `null` y `find.textContaining('null')` `findsNothing`) | |

### 4D. Falla al cargar el perfil del rider (error de red)

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4D.1 | Simula un error del backend al pedir `GET /users/{id}` (o abre el perfil con un `userId` inexistente) | Se muestra `RiderProfileError` con el mensaje de error y un botón de reintentar; la app no se cierra | 🤖✅ Auto-PASS (`test/features/users/domain/use_cases/get_user_by_id_use_case_test.dart`, TC-2-36 "returns error on failure"; `test/features/users/presentation/pages/rider_profile_page_test.dart`, TC-2-29) | |

---

## 5. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso al código, logs o consola de desarrollo.

| # | Verificacion | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 5.1 | Correr `flutter test test/features/users/` | Todos los tests del feature pasan en verde | |
| 5.2 | Correr `dart analyze` sobre `lib/features/users/` | Sin issues nuevos | |
| 5.3 | Grep de `user.email` en `lib/features/users/presentation/widgets/rider_profile_content.dart` | Ninguna referencia al campo `email` del `UserModel` en el árbol de widgets (confirma que la ocultación sigue vigente tras cualquier refactor) | |
| 5.4 | Revisar `GetUserByIdUseCase` y `UserRepositoryImpl.getUserById` | El endpoint sigue siendo `GET /users/{id}` (hardcoded, no usa `ApiRoutes` — deuda conocida, no bloqueante) | |
| 5.5 | Correr `integration_test/users_rider_profile_patrol_test.dart` con datos de seed reales (inscripción de `qa1@gmail.com` en el evento de `qa2@gmail.com`) | El test navega hasta el perfil del rider y verifica ausencia de email + bottom sheet "Muy pronto" | |

---

## Fixes requeridos

> Gaps de automatización detectados durante la planeación (sin ejecutar tests todavía). Priorizados para que el humano decida correr `rg-exec` (modo lite) por cada uno.

1. ~~**Media prioridad — Sin widget test para el botón "Seguir" y su bottom sheet.**~~ **RESUELTO** (2026-07-04): `test/features/users/presentation/widgets/rider_profile_content_test.dart` monta `RiderProfileContent` de forma aislada (sin `RiderProfileCubit`, sin backend) y verifica que tocar "Seguir" abre el `InfoDialog` con título "Muy pronto" y el mensaje completo, y que el botón sigue mostrando "Seguir" (no "Siguiendo") tras la interacción.
2. ~~**Baja prioridad — Sin tests de casos de borde para `residenceCity`/`fullName` nulos** en `RiderProfileContent`.~~ **RESUELTO** (2026-07-04): mismo archivo (`rider_profile_content_test.dart`) agrega 4 tests: `residenceCity` nulo/vacío (no se renderiza la fila ni el ícono de ubicación) y `fullName` nulo/vacío (no lanza excepción, sin texto "null" en pantalla).
3. **Baja prioridad — Comparación "mi perfil vs. perfil ajeno" (caso 2.2) no automatizada.** Requeriría un test que monte ambas pantallas (`profile` + `users`) en el mismo flujo para confirmar el contraste de comportamiento; hoy son features y test suites separadas. Pendiente.

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–3 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad (secciones 4 o 5), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2 o 3 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
