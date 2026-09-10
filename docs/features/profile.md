# Profile

> Reescrito para v2 (F4). Reemplaza `profile.md` de la v1.

## Problema que resuelve

Ficha del rider (datos personales, médicos y de contacto de emergencia) y los dos requisitos legales que no pueden vivir en ningún otro feature: **borrado de cuenta dentro de la app** (Apple/Google Play + Ley 1581) y el registro de consentimientos. Bloque 0 de `docs/product/ALCANCE-V2.md`: "Borrado de cuenta in-app... su forma actual ya es correcta — el modelo de datos debería partir de sus reglas, no al revés" (veredicto `keep`). También resuelve P-13 (contacto de emergencia editable **fuera** del flujo de inscripción a una rodada).

## Flujos

- **P1 — Ajustes**: `SettingsListPage`, lista de accesos (perfil, contacto de emergencia, consentimientos, notificaciones/analítica, cerrar sesión, borrar cuenta).
- **P2 — Ficha del rider**: `ProfilePage`, carga en paralelo el perfil y una vista previa de vehículos (dos `ResultState` independientes en `ProfileOverviewState`, porque cambiar de resultado en uno no debe re-renderizar el otro).
- **Editar perfil**: `EditProfilePage` (nombre, teléfono, fecha de nacimiento, ciudad, EPS, seguro médico, tipo de sangre) — sin frame propio en el `.pen`, documentado explícitamente en el código.
- **Contacto de emergencia**: `EmergencyContactPage`, editable en cualquier momento, no solo durante la inscripción a una rodada (resuelve P-13).
- **Mis consentimientos**: `ConsentsPage`, lista de sellos de `consent_log` (kind + versión + fecha), inmutables y sellados por el servidor.
- **Borrar cuenta (4 pasos)**: explicación → confirmación → progreso → hecho, contra la Edge Function `delete-account`. Si el rider organiza una rodada activa, el flujo se bloquea (`DeleteAccountBlockedPage`) con un check server-side nuevo (`error == 'active_event_owner'`).
- **Preferencias de dispositivo**: notificaciones y analítica, guardadas en `shared_preferences` (no en Supabase — son locales al dispositivo).

## Pantallas (Pencil)

| Pantalla | Archivo | Pencil |
|---|---|---|
| Ficha del rider (P2) | `presentation/pages/profile_page.dart` | `iFssW` (contenido), `ZhLW3` (carga), `iWE6o` (error), `HGJYs` (sin conexión) |
| Ajustes (P1) | `presentation/pages/settings_list_page.dart` | `BS3wJ` |
| Contacto de emergencia | `presentation/pages/emergency_contact_page.dart` | `FNOK0` |
| Borrar cuenta — explicación | `presentation/pages/delete_account_explanation_page.dart` | `MCSBy` (paso 1), `H69H3` (paso 2, hoja) |
| Borrar cuenta — progreso | `presentation/pages/delete_account_progress_page.dart` | `ofQFh` |
| Borrar cuenta — bloqueada | `presentation/pages/delete_account_blocked_page.dart` | `XryZO` |
| Mis consentimientos | `presentation/pages/consents_page.dart` | sin frame documentado en el código |
| Editar perfil | `presentation/pages/edit_profile_page.dart` | sin frame propio (documentado en el código) |

## Datos

- Tabla `profiles` (1:1 con `auth.users`): `full_name, phone, birth_date, residence_city, eps, medical_insurance, blood_type, emergency_contact_name/phone/relationship`. `ProfileDto` la mapea; el email se inyecta desde `auth.currentUser`, no vive en la tabla.
- Tabla `consent_log` (inmutable): `kind (riskAcceptance|medicalConsent|terms), version, accepted_at`.
- Conteo de borrado: lee `vehicles`, `maintenances`, `vehicle_documents` del owner para mostrar cuánto se va a borrar antes de confirmar.
- Vista previa de vehículos: `vehicles` (`id, name, image_path`, no archivados) + `Storage` bucket `vehicle-images` (URL firmada, 1h).
- Edge Function `delete-account`: anonimiza `profiles`, borra vehículos/documentos/Storage, conserva `consent_log`, elimina el usuario de `auth`.

## Estados

Todos los resultados que dependen de red usan `ResultState<T>`: `ProfileOverviewCubit` (perfil + vehículos, dos independientes), `ProfileSettingsCubit` (perfil + dos bools locales), `ConsentLogCubit`, `DeleteAccountSummaryCubit`, `SaveProfileCubit`, `SaveEmergencyContactCubit`, `SignOutCubit`. La única excepción es `DeleteAccountCubit`, que usa un estado sellado propio (`initial/inProgress/done/blocked/error`) porque "bloqueado por organizar una rodada activa" no es un simple éxito/error genérico.

Estados obligatorios cubiertos: skeleton (`ProfileSkeleton`, `DeleteAccountSummarySkeleton`, `VehiclesRowSkeleton`, `SkeletonList`), vacío (`EmptyStateView` en consentimientos y en la fila de vehículos), error con reintentar (`ErrorStateView`), sin conexión (`OfflineStateView`, solo en `ProfilePage`, gateado por `ConnectivityCubit`). Sin permiso de ubicación / sin GPS no aplican: profile no depende de ubicación.

## Pendientes

- `EditProfilePage` y `ConsentsPage` no tienen frame de Pencil documentado en comentarios del código — verificar contra el `.pen` antes de tocarlas.
- El resto de pantallas de auth/profile surfacean "sin conexión" como un `ErrorStateView` genérico, no como el `OfflineStateView` dedicado — solo `ProfilePage` lo tiene.
