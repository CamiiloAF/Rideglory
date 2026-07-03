# Preflight — qa-auto waiver-inscripcion-registro

- Timestamp inicio: 2026-07-03T01:22:33Z
- Timestamp fin: 2026-07-03T01:23:19Z

## 1. Device para Patrol e2e

- `adb devices`: `emulator-5554	device` (Android emulator disponible, estado "device").
- `xcrun simctl list devices booted`: sin líneas "Booted" (ningún simulador iOS booteado).
- **deviceAvailable = true**
- **deviceKind = "android-emulator"**

## 2. Baseline Flutter

- `flutter test --reporter compact`: **944 tests, "All tests passed!"** → **baselineFlutterTests = "green"**
- `dart analyze lib/`: **"No issues found!"** → **analyzeClean = true**

## 3. Notes

- No se ejecutaron casos e2e/Patrol en este preflight (la fase indicó "No hay casos e2e o el usuario pidió sin e2e"); el device Android disponible queda registrado por si `qa-auto` decide generar/correr Patrol de todos modos.
- Working tree se deja sin cambios de código de producción; este archivo es el único artefacto nuevo, bajo `docs/exec-runs/waiver-inscripcion-registro/`.
- No se ejecutó ningún comando git de escritura (add/commit/push/merge/rebase/restore/reset) ni `gh pr`.
