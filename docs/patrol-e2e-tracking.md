# Seguimiento e2e (v2)

Suite: `integration_test/smoke_v2_patrol_test.dart` (integration_test + flutter_test; `patrol_cli` 4.5.1 es incompatible con `patrol` 4.5.0 fijado en pubspec). Se corre contra Supabase local con el emulador apuntando a `10.0.2.2`:

```bash
flutter test integration_test/smoke_v2_patrol_test.dart -d <emulator> --flavor dev \
  --dart-define-from-file=config/dev.json --dart-define=SUPABASE_URL=http://10.0.2.2:54321
```

## Corrida del 2026-09-09 (Pixel 9a, API 36, Supabase local con seed)

| Escenario | Automatizado | Manual (adb + capturas) |
|---|---|---|
| a. Bienvenida → correo → login qa1 → Mantenimiento con el registro del seed | FAIL (el harness no encuentra la bienvenida en 20 s; la corrida fue matada por falta de memoria del host) | **PASS** |
| b. Registrar mantenimiento y odómetro derivado | SKIP | No ejecutado |
| c. Garaje muestra "La Negra"; documentos en editar | SKIP | **PASS parcial** (galería con la moto y kilometraje) |
| d. Inscripción a "Mi Evento" con sellos del servidor | SKIP | **PASS parcial** (lista de rodadas muestra "Mi Evento") |
| e. qa2 ve a qa1 en inscritos con botón Llamar | SKIP | No ejecutado |
| f. Editar contacto de emergencia | SKIP | **PASS parcial** (perfil carga datos de qa1) |

Bug real encontrado y corregido en esta corrida: el `redirect` del router comparaba `matchedLocation` con igualdad exacta y rebotaba las subrutas de bienvenida (login por correo, registro y recuperar contraseña eran inalcanzables). Corregido en `b41a19b`.

## Suite `live_ride_patrol_test.dart` (Bloque 3, escrita 2026-09-10)

Mismo harness que `smoke_v2_patrol_test.dart` (un solo `testWidgets`, sin `patrolTest`). Corre contra Supabase local con el seed de "Rodada en curso" (`started`, organizada por qa2, qa1 inscrito y aprobado, posición inicial de qa2 en `live_positions`):

```bash
flutter test integration_test/live_ride_patrol_test.dart -d <emulator> --flavor dev \
  --dart-define-from-file=config/dev.json --dart-define=SUPABASE_URL=http://10.0.2.2:54321
```

| Escenario | Descripción | Automatizado |
|---|---|---|
| a | qa1 entra al detalle de "Rodada en curso" y ve el CTA "Ver rodada en vivo" | PENDIENTE (sin emulador) |
| b | LV1: riders visibles, permiso de ubicación solo se consulta al cargar, nunca se pide | PENDIENTE (sin emulador) |
| c | Compartir ubicación → aviso propio (LV2) antes del diálogo del sistema; "Ahora no" no dispara el permiso nativo | PENDIENTE (sin emulador) |
| d | SOS: mantener pulsado 1,5 s → LV4 SOS activo, verificado directamente en BD (`status='active'`) | PENDIENTE (sin emulador) |
| e | Cerrar el SOS con confirmación, verificado en BD (`status='closed'`, `closed_by=qa1`) | PENDIENTE (sin emulador) |
| f | qa2 (organizador) ve la lista completa de riders en LV6 | PENDIENTE (sin emulador) |

No se ejecutó en esta corrida por falta de emulador disponible (ver "Los AVD viven en un SSD externo" en `CLAUDE.md` §Trampas conocidas). La suite incluye limpieza defensiva (`_closeAnyOpenSos`) antes del flujo y en `tearDown`, para no dejar un SOS `active` de qa1 entre corridas.

## Pendiente

- Correr `live_ride_patrol_test.dart` con emulador disponible y volcar los resultados reales sobre esta tabla.
- Estabilizar la suite automatizada de humo: correrla con el host descargado (sin Docker Desktop compitiendo con el emulador) y ajustar la espera inicial de la bienvenida (`pumpAndSettle` no asienta con el shimmer de los skeletons; usar `pump` con reintentos).
- Completar b, d, e y f de `smoke_v2_patrol_test.dart` de forma automatizada con verificación en BD (`psql`), como describe la cabecera del test.
- Verificación de fidelidad visual con goldens (`/design-fidelity-check`) pendiente para todas las features.
