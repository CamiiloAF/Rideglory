# Checklist e2e Patrol — Rideglory

> Última actualización: 2026-07-04
> Alcance: `integration_test/`

Manifiesto único de todos los tests e2e Patrol del repo: qué flujo cubre cada archivo, qué precondiciones de datos necesita, y en qué **orden correrlos** para que las precondiciones de unos no rompan a otros. Ningún test de esta lista se ha ejecutado todavía — quedan preparados a la espera de la orden explícita de correrlos.

Cuentas de prueba (ver memoria `project_qa_test_users`):
- `qa1@gmail.com` / `Test123.` — rider.
- `qa2@gmail.com` / `Test123.` — owner de "Mi Evento".

## Cómo correr cualquiera de estos tests

```bash
patrol test -t integration_test/<archivo>.dart \
  --device-id emulator-5554 \
  --dart-define=TEST_EMAIL=<cuenta> \
  --dart-define=TEST_PASSWORD=<password>
```

Cada archivo tiene en su comentario de cabecera el comando exacto (incluye `--uninstall` cuando el test lo necesita, p. ej. login fallido).

---

## Orden recomendado de ejecución

Varios tests comparten estado sobre el evento **"Mi Evento"** (owner `qa2`) y su inscripción de `qa1`. Correrlos fuera de orden no los hace fallar de forma opaca (todos documentan sus precondiciones y se detienen con un mensaje claro si no se cumplen), pero correrlos en este orden maximiza cuántos pasos de cada uno se ejercen de verdad:

| # | Archivo | Por qué va en esta posición |
|---|---|---|
| 1 | `authentication_signup_patrol_test.dart` | Independiente — no toca datos compartidos. |
| 2 | `authentication_login_failure_patrol_test.dart` | Independiente. Requiere `--uninstall`. |
| 3 | `authentication_forgot_password_patrol_test.dart` | Independiente. |
| 4 | `events_create_publish_patrol_test.dart` | Independiente (crea un evento nuevo, no toca "Mi Evento"). Requiere ≥1 foto en la galería del emulador. |
| 5 | `registration_patrol_test.dart` *(preexistente)* | Deja la inscripción de `qa1` a "Mi Evento" en estado **PENDING** — precondición de los 3 siguientes. |
| 6 | `registration_organizer_patrol_test.dart` *(preexistente)* | Solo lee la inscripción dejada en el paso 5 (no cambia su estado). |
| 7 | `events_attendees_approve_reject_patrol_test.dart` | Aprueba la inscripción PENDING del paso 5 → queda en **APPROVED**. |
| 8 | `users_rider_profile_patrol_test.dart` | Solo necesita que exista algún inscrito (de 5) — no depende del estado. |
| 9 | `registration_cancel_patrol_test.dart` | Cancela la inscripción (PENDING o APPROVED, ambos válidos) dejada por 5/7. |
| 10 | `soat_manual_capture_patrol_test.dart` | Independiente — requiere un vehículo sin SOAT vigente. |
| 11 | `maintenance_crud_patrol_test.dart` | Independiente — requiere ≥1 vehículo activo. |
| 12 | `vehicles_add_edit_patrol_test.dart` | Independiente. Crea un vehículo nuevo con prefijo `QA E2E ` (no se limpia solo). |
| 13 | `vehicles_archive_setmain_patrol_test.dart` | Requiere ≥2 vehículos activos — correr DESPUÉS de 12 si la cuenta no los tiene ya. |
| 14 | `events_live_tracking_sos_patrol_test.dart` | ⚠️ **DESTRUCTIVO Y AL FINAL SIEMPRE.** Mueve "Mi Evento" a `finished` de forma permanente. Romperá las precondiciones de 5–9 si se corre antes. Considerar usar un evento `scheduled` dedicado en vez de "Mi Evento" si se necesita repetir. |

Smoke tests de navegación pura (no destructivos, no dependen de nada, se pueden correr en cualquier momento): `events_patrol_test.dart`, `home_patrol_test.dart`, `profile_patrol_test.dart`, `vehicles_patrol_test.dart`, `app_test.dart` (stub vacío, sin cobertura real).

---

## Manifiesto por flujo

### Authentication
| Archivo | Flujo | Precondición clave |
|---|---|---|
| `authentication_signup_patrol_test.dart` | Registro con email/password nuevo → Home | Genera email sintético único por corrida; crea cuenta real (purgar periódicamente `qa.signup.*@rideglory-test.com`) |
| `authentication_login_failure_patrol_test.dart` | Login con credenciales inválidas → error genérico, permanece en Login | Requiere `--uninstall` (sin sesión persistida) |
| `authentication_forgot_password_patrol_test.dart` | "Olvidé mi contraseña" → confirmación de envío | Usa `qa1@gmail.com`; no verifica bandeja real |

### Events
| Archivo | Flujo | Precondición clave |
|---|---|---|
| `events_create_publish_patrol_test.dart` | Wizard completo de 4 pasos → publicar evento nuevo | Emulador con ≥1 foto en galería (portada); `qa2` como owner |
| `events_attendees_approve_reject_patrol_test.dart` | Organizador aprueba una solicitud pendiente | "Mi Evento" con ≥1 inscripción PENDING (dejada por `registration_patrol_test.dart`) |
| `events_live_tracking_sos_patrol_test.dart` | Iniciar rodada → SOS → cancelar SOS → terminar rodada | ⚠️ Destructivo — ver tabla de orden. Solo cubre un dispositivo (sin verificación cross-user del SOS) |

### Event Registration
| Archivo | Flujo | Precondición clave |
|---|---|---|
| `registration_patrol_test.dart` *(preexistente)* | Wizard de inscripción completo (4 pasos + consentimiento + waiver) | Perfil de rider completo, ≥1 vehículo de marca permitida |
| `registration_organizer_patrol_test.dart` *(preexistente)* | Organizador ve detalle de inscripción + contacto | ≥1 inscripción visible en "Mi Evento" |
| `registration_cancel_patrol_test.dart` | Rider cancela su propia inscripción | Inscripción activa (PENDING o APPROVED) de `qa1` sobre "Mi Evento" |

### Vehicles
| Archivo | Flujo | Precondición clave |
|---|---|---|
| `vehicles_add_edit_patrol_test.dart` | Agregar vehículo nuevo → editar apodo | Marca "Honda" debe seguir en el catálogo; no limpia el vehículo creado |
| `vehicles_archive_setmain_patrol_test.dart` | Marcar como principal → archivar → desarchivar | Cuenta con ≥2 vehículos activos |

### Maintenance
| Archivo | Flujo | Precondición clave |
|---|---|---|
| `maintenance_crud_patrol_test.dart` | Crear → ver detalle → editar → eliminar mantenimiento | Cuenta con ≥1 vehículo no archivado |

### SOAT
| Archivo | Flujo | Precondición clave |
|---|---|---|
| `soat_manual_capture_patrol_test.dart` | Captura manual (sin OCR/cámara) → SOAT vigente | Vehículo sin SOAT vigente registrado |

### Users
| Archivo | Flujo | Precondición clave |
|---|---|---|
| `users_rider_profile_patrol_test.dart` | Ver perfil de otro rider (email oculto, botón "Seguir" → "Muy pronto") | "Mi Evento" con ≥1 inscrito distinto de `qa2` |

### Smoke tests de navegación (preexistentes, no destructivos)
| Archivo | Flujo |
|---|---|
| `events_patrol_test.dart` | Login → tab Eventos visible |
| `home_patrol_test.dart` | Login → dashboard visible |
| `profile_patrol_test.dart` | Login → perfil visible |
| `vehicles_patrol_test.dart` | Login → garage visible |
| `app_test.dart` | Stub vacío — sin cobertura real, candidato a reemplazar o eliminar |

---

## Gaps conocidos (fuera de alcance de esta suite)

- **SOS multi-dispositivo**: ningún test verifica que un SEGUNDO rider reciba `tracking.sos.alert`/banner/marcador rojo en tiempo real. Requeriría un test Patrol con 2 dispositivos orquestados en paralelo.
- **Portada de evento vía galería**: `events_create_publish_patrol_test.dart` depende de `platformAutomator.mobile.tapAt(Offset)` sobre el Photo Picker nativo — el offset calibrado puede necesitar ajuste en otro Android/API o iOS.
- **SOAT vía OCR/cámara**: no cubierto (solo la vía manual) por fragilidad de automatizar cámara real.
- **Editar perfil propio**: `EditProfilePage._save()` no persiste a backend (ver `docs/features/profile.md`) — no tiene sentido un e2e hasta que se implemente la persistencia real.
- **Borradores de evento**: la funcionalidad fue eliminada del producto (incluido el código muerto `saveDraft()`/`buildDraftToSave()`/`MyDraftsPage`) — no aplica ningún e2e.

## Gotchas operativos al correr Patrol

- **Comando correcto**: `patrol test -t integration_test/<archivo>.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json [--dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...]`. La CLI actual usa `-d/--device`, NO `--device-id` (los comentarios de cabecera de algunos archivos aún dicen `--device-id`, están desactualizados). Sin `--flavor dev --dart-define-from-file=config/dev.json` el build de Gradle falla por flavors ambiguos.
- **Nunca uses `/` literal en la descripción de un `patrolTest(...)`**: `AndroidTestOrchestrator` usa la descripción del test como nombre de archivo de resultado, y una `/` la interpreta como separador de ruta → `IllegalArgumentException: ... contains a path separator` → el proceso del orchestrator crashea con `FATAL EXCEPTION` y el test run entero reporta `Total: 0` sin ninguna pista aparente en el resumen de patrol (solo aparece en `adb logcat` o en el XML de `build/app/outputs/androidTest-results/`). Usa "y"/"," en vez de "/".

## Mantenimiento

Al agregar un test e2e Patrol nuevo: agregarlo a la tabla de su feature correspondiente arriba, y si comparte datos con otro test (mismo evento/vehículo/cuenta), actualizar la tabla de "Orden recomendado de ejecución".
