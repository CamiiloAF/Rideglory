# Checklist de QA — Perfil propio (Profile)

**Feature:** Perfil propio de solo lectura + atajos + logout (`lib/features/profile/`)
**Referencia:** `docs/features/profile.md` (actualizada 2026-07-04)
**Estado:** Pendiente de ejecución

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Una cuenta de piloto (`qa1@gmail.com` o equivalente) con sesión activa y con `fullName`, `email` y `residenceCity` completos en su `UserModel`.
- [ ] La misma cuenta con al menos una inscripción a un evento (para verificar el atajo "Mis inscripciones") y al menos un mantenimiento registrado (para verificar el atajo "Mantenimientos").
- [ ] Idealmente, una segunda cuenta o un mock/seed con `fullName`, `email` o `residenceCity` vacíos/nulos, para los casos de borde (puede lograrse editando el usuario directamente en la BD si no hay UI de edición real — ver `docs/features/profile.md` §11 "`EditProfilePage._save()` no persiste cambios").
- [ ] Dispositivo o emulador con la app instalada y tab "Perfil" visible en el bottom navigation.

---

## 1. Ver el perfil propio

> Con sesión iniciada, toca el tab "Perfil" en el bottom navigation.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Abre el tab "Perfil" | Se muestra el AppBar con título "Mi perfil" | 🤖✅ Auto-PASS (`integration_test/profile_patrol_test.dart`) | |
| 1.2 | Espera a que cargue el contenido | Se ve el avatar con las iniciales del usuario, el nombre completo, el email y la ciudad de residencia | | |
| 1.3 | Revisa la fila de estadísticas (Rodadas / km / seguidores) | Las tres celdas muestran "0" (valores hardcoded, sin integración real todavía — ver `docs/features/profile.md` §11 "Stats hardcoded a 0") | | |
| 1.4 | Revisa la sección "CONFIGURACIÓN" | Aparece una tarjeta con las opciones "Mis inscripciones", "Mantenimientos" y "Cerrar sesión" separadas por divisores | | |
| 1.5 | Verifica el estado de carga (reabre la app o fuerza un refresh si es posible) | Mientras carga se ve un loading state; si falla, se ve un estado de error con botón de reintentar | 🤖✅ Auto-PASS (`test/features/profile/presentation/cubit/profile_cubit_test.dart` — cubre loading/data/error del `ProfileCubit`; falta test de widget que verifique el render en pantalla de cada estado) | |

---

## 2. Regresión: el botón "Editar info" NO debe aparecer

> Ver `docs/features/profile.md` §6 "Flujo de edición": el botón fue eliminado (commit `6607bee`); `EditProfilePage` sigue en el código pero es inalcanzable desde la UI.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Revisa el header del perfil (avatar + nombre + email + ciudad) | NO hay ningún botón, ícono o texto "Editar info" / "Editar perfil" visible en el header | 🤖✅ Auto-PASS (`test/features/profile/presentation/profile_page_test.dart`, grupo "Regresión — el botón \"Editar info\" NUNCA debe aparecer": verifica `find.textContaining('Editar')` y `find.byIcon(Icons.edit*)` `findsNothing` tanto en `ProfilePage` completo como en `ProfileHeader` aislado) | |
| 2.2 | Busca en toda la pantalla de perfil algún otro punto de entrada hacia la edición (menú, long-press, swipe) | No existe ningún camino desde la UI hacia `/profile/edit` | | |
| 2.3 | (Técnico) Confirma que `ProfileHeader` no invoca navegación a `AppRoutes.editProfile` | El widget actual no contiene ningún `onTap`/`pushNamed` hacia el editor | 🤖✅ Auto-PASS (`test/features/profile/presentation/profile_page_test.dart`, test "ProfileHeader en aislamiento tampoco expone ningún botón de edición" — confirma ausencia de `GestureDetector`/`IconButton` en `ProfileHeader`) | |

---

## 3. Atajos de navegación

> Desde la sección "CONFIGURACIÓN" del perfil.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Toca "Mis inscripciones" | Navega a la pantalla de inscripciones del usuario (`myRegistrations`) | 🤖✅ Auto-PASS (`test/features/profile/presentation/profile_page_test.dart`, test "tocar \"Mis inscripciones\" navega a la ruta myRegistrations") | |
| 3.2 | Vuelve atrás y toca "Mantenimientos" | Navega a la pantalla de mantenimientos, mostrando los de todos los vehículos (sin filtrar por `initialVehicleId`) | 🤖✅ Auto-PASS (`test/features/profile/presentation/profile_page_test.dart`, test "tocar \"Mantenimientos\" navega a la ruta maintenances" — cubre la navegación; el detalle de "sin filtrar por initialVehicleId" es responsabilidad de la pantalla de mantenimientos, fuera de alcance de este test) | |
| 3.3 | Presiona el botón de retroceso del sistema (o gesto) estando en la pantalla de perfil | La app navega a `/home` (reset del `StatefulShellRoute`) en lugar de hacer un pop nativo normal — ver `docs/features/profile.md` §11 "`PopScope` redirige a `/home`" | | |

---

## 4. Logout con confirmación

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Toca "Cerrar sesión" en la lista de acciones | Aparece un diálogo de confirmación tipo advertencia antes de cerrar sesión | 🤖✅ Auto-PASS (`test/features/profile/presentation/profile_page_test.dart`, test "tocar \"Cerrar sesión\" abre el diálogo de confirmación") | |
| 4.2 | Cancela el diálogo | La sesión sigue activa, sigues en la pantalla de perfil | 🤖✅ Auto-PASS (`test/features/profile/presentation/profile_page_test.dart`, test "cancelar el diálogo no cierra sesión y permanece en el perfil" — verifica `verifyNever` sobre `signOut`/`clearVehicles`/`reset`) | |
| 4.3 | Toca "Cerrar sesión" de nuevo y confirma | Se cierra sesión (Firebase + Google), se limpia el caché de vehículos, se resetea el `ProfileCubit`, y navegas a la pantalla de login reemplazando toda la pila (`goAndClearStack`) | 🤖✅ Auto-PASS (`test/features/profile/presentation/profile_page_test.dart`, test "confirmar el diálogo invoca signOut, clearVehicles y reset, y navega a login" — verifica las 3 llamadas con mocktail `verify(...).called(1)` y la navegación al `login-screen` de prueba; nota: usa `MockAuthCubit.signOut()` mockeado, no ejercita el Firebase/Google real, eso queda cubierto por `integration_test/`) | |
| 4.4 | Vuelve a iniciar sesión con la misma cuenta y entra al tab "Perfil" | Se ve un loading limpio (no datos residuales de la sesión anterior) antes de que cargue el perfil actualizado | 🤖✅ Auto-PASS (`test/features/profile/presentation/cubit/profile_cubit_test.dart`, test "reset emits initial state" — cubre el reset del cubit; falta test e2e del flujo completo de logout) | |

---

## 5. Casos de borde

### 5A. Usuario sin foto

> El perfil no soporta foto (solo iniciales), pero conviene confirmar el fallback.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5A.1 | Abre el perfil de un usuario sin foto configurada | El avatar muestra las iniciales calculadas a partir de `fullName` (`initialsFromName`), nunca un ícono roto ni un espacio en blanco | | |

### 5B. Usuario sin nombre

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5B.1 | Abre el perfil de un usuario con `fullName` nulo o vacío | La fila de nombre no se renderiza (o se omite sin dejar un hueco/errores); la pantalla no truena | | |

### 5C. Usuario sin ciudad

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5C.1 | Abre el perfil de un usuario con `residenceCity` nulo o vacío | La fila de ciudad (con el ícono de ubicación) no se muestra | | |

### 5D. Usuario sin email

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5D.1 | Abre el perfil de un usuario con `email` nulo o vacío | La fila de email no se renderiza; no aparece texto "null" | | |

---

## 6. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso al código, logs o consola de desarrollo.

| # | Verificacion | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 6.1 | Correr `flutter test test/features/profile/` | Todos los tests del feature pasan en verde | |
| 6.2 | Correr `dart analyze` sobre `lib/features/profile/` | Sin issues nuevos | |
| 6.3 | Grep de `EditProfilePage` / `AppRoutes.editProfile` en `lib/features/profile/presentation/widgets/` | Ninguna referencia de navegación activa desde `ProfileHeader`/`ProfileContent`/`ProfileActionsList` (confirma que el botón sigue eliminado tras cualquier refactor) | |
| 6.4 | Revisar `ProfileStatsRow` en `ProfileContent` | Los parámetros `eventsCount`/`kmCount`/`followersCount` siguen sin conectarse a un endpoint real (deuda conocida, no regresión) | |
| 6.5 | Correr `integration_test/profile_patrol_test.dart` con datos de seed reales (`qa1@gmail.com`) | El flujo login → tab Perfil → "Mi perfil" visible pasa sin timeouts | |

---

## Fixes requeridos

> Gaps de automatización detectados durante la planeación (sin ejecutar tests todavía). Priorizados para que el humano decida correr `rg-exec` (modo lite) por cada uno.

1. ~~**Alta prioridad — No existe test de regresión para la ausencia del botón "Editar info".**~~ **RESUELTO** (2026-07-04): `test/features/profile/presentation/profile_page_test.dart`, grupo "Regresión — el botón \"Editar info\" NUNCA debe aparecer" verifica `find.textContaining('Editar')`/`find.byIcon(Icons.edit*)` `findsNothing` sobre `ProfilePage` completo y sobre `ProfileHeader` aislado.
2. ~~**Media prioridad — Sin widget tests para `ProfilePage`/`ProfileContent`/`ProfileHeader`/`ProfileActionsList`.**~~ **RESUELTO parcialmente** (2026-07-04): se agregó `test/features/profile/presentation/profile_page_test.dart` con cobertura de render de nombre/email/ciudad, navegación a "Mis inscripciones"/"Mantenimientos" y el flujo completo de logout (abrir diálogo, cancelar, confirmar → `signOut`/`clearVehicles`/`reset` + navegación a login), todo con mocks (`MockAuthCubit`/`MockVehicleCubit`/`MockProfileCubit`/`MockAnalyticsConsentCubit` vía mocktail + GetIt). El test e2e Patrol laxo (`profile_patrol_test.dart`) sigue sin endurecerse (ver punto 4).
3. **Media prioridad — Sin tests de casos de borde para campos nulos/vacíos** (`fullName`, `email`, `residenceCity` nulos) en `ProfileHeader`. Pendiente — no incluido en esta corrida (ver sección 5 de este checklist, filas 5B/5C/5D aún sin automatizar).
4. **Baja prioridad — `profile_patrol_test.dart` usa un OR laxo** (`hasEditButton || hasEmail || hasLoadingError || ...`) que puede dar falso verde si la pantalla realmente falla en un estado inesperado. Considerar endurecerlo ahora que "Editar perfil" ya no debería aparecer nunca (el comentario en el test todavía lo asume como posible). Pendiente.

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–4 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad (secciones 5 o 6), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2 o 4 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
