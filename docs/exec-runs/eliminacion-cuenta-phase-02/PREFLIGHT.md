# Preflight — eliminacion-cuenta-phase-02

Timestamp (UTC): 2026-07-11T14:51:30Z

## 1. Device para Patrol e2e

- `adb devices`: `emulator-5554	device` → Android emulator disponible.
- `xcrun simctl list devices booted`: ningún simulador con estado "Booted".
- **deviceAvailable = true**
- **deviceKind = android-emulator**

## 2. Baseline Flutter

- `flutter test --reporter compact` (raíz `.`): exit code 0, "All tests passed!".
  - **baselineFlutterTests = green**
- `dart analyze lib/` (raíz `.`): 5 issues, todos `info` (`curly_braces_in_flow_control_structures`), preexistentes, no relacionados con `api_base_url_resolver.dart`:
  - `features/events/presentation/list/events_page.dart:25:11`
  - `features/home/presentation/widgets/home_vehicle_info_row.dart:24:7`
  - `features/maintenance/presentation/widgets/item_card/modern_maintenance_card.dart:50:7`
  - `features/profile/presentation/profile_page.dart:34:11`
  - `features/vehicles/presentation/garage/garage_page.dart:21:11`
  - **analyzeClean = false** (no dice "No issues found!"; son 5 infos preexistentes fuera del scope de esta fase, no bloqueantes)

## 3. Notas

- No hay simulador iOS booteado; para e2e Patrol se usaría el emulador Android `emulator-5554`.
- El usuario indicó que esta fase no tiene casos e2e o pidió correr sin e2e, por lo que la ausencia de simulador iOS no es bloqueante.
- Baseline de tests Flutter parte en verde: cualquier fallo detectado durante la ejecución de la fase debe atribuirse al trabajo de la fase, no a estado preexistente.
- `dart analyze` no está 100% limpio, pero los 5 issues son preexistentes (info-level, estilo de llaves) y no relacionados con el feature de esta fase ni con `api_base_url_resolver.dart`.
