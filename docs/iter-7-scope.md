# Iter-7 — Scope propuesto (pre-`/solo-plan`)

**Estado:** Borrador para revisión humana. **No aprobado**, **no ejecutado**.
**PRD fuente:** [`docs/prds/prd-ocr-soat-autofill.md`](./prds/prd-ocr-soat-autofill.md)
**Iteración:** 7
**Tipo:** Feature add-on sobre el feature SOAT existente (iter-2)
**Estimado:** ~3 días de desarrollo + 0.5 día QA

---

## Tema único

**Autocompletar SOAT desde foto/PDF con ML Kit on-device** — un solo objetivo cohesivo, sin paquetes paralelos.

---

## Stories propuestas

| ID | Story | Acceptance |
|---|---|---|
| 7.1 | Como rider, puedo tocar "Escanear SOAT" en el flujo de subida y elegir foto de cámara, galería, o PDF. | El picker abre con las tres opciones; permisos solicitados correctamente en Android e iOS; si el usuario cancela vuelve al estado anterior sin error. |
| 7.2 | Como sistema, proceso la imagen (o PDF rasterizado) con ML Kit on-device y extraigo los 4 campos del SOAT con un parser por reglas. | OCR corre 100% local (sin red); soporta foto, imagen de galería y **PDF rasterizado con `pdfx`**; parser identifica aseguradora, número de póliza, fecha inicio, fecha vencimiento, con niveles de confianza por campo. Validación de duración 360–370 días aplicada. |
| 7.3 | Como rider, al completar el escaneo aterrizo en el formulario manual con los campos prellenados y marcados visualmente como "auto-rellenado". | Banner "Datos extraídos del documento — revisa antes de guardar" visible; cada campo OCR tiene indicador visual; el usuario puede editar cualquier campo antes de guardar. |
| 7.4 | Como rider, si el OCR no extrae al menos 2 campos con confianza alta, no veo datos basura — voy al formulario manual vacío con un toast explicativo. | Si <2 campos `high confidence`, ningún campo se prellena; toast: "No pudimos leer el documento, ingresa los datos manualmente"; el usuario nunca ve datos extraídos con baja confianza. |
| 7.5 | Como producto, registro telemetría anónima de cada intento de escaneo para mejorar el parser sin acceder a los documentos. | Eventos `soat_scan_attempted`, `soat_scan_success`, `soat_scan_failed` registrados en Firebase Analytics; sin envío de imagen ni texto reconocido al backend. |

---

## Aseguradoras soportadas en v1

**Las 10 aseguradoras autorizadas** por la Superfinanciera (verificado vía Fasecolda, mayo 2026). Todas se detectan por nombre; un subset tiene regex específica de número de póliza:

| # | Aseguradora | Detección por nombre | Regex específica de póliza |
|---|---|---|---|
| 1 | SURA (Seguros Generales Suramericana) | ✅ | ✅ |
| 2 | Seguros Bolívar | ✅ | ✅ |
| 3 | AXA Colpatria | ✅ | ✅ |
| 4 | Seguros del Estado | ✅ | ✅ |
| 5 | Seguros Mundial | ✅ | ✅ |
| 6 | La Previsora | ✅ | genérica |
| 7 | Liberty Seguros | ✅ | genérica |
| 8 | Mapfre | ✅ | genérica |
| 9 | La Equidad | ✅ | genérica |
| 10 | Aseguradora Solidaria | ✅ | genérica |

Falabella opera como intermediario respaldado por una de las anteriores — no requiere detección propia.

Cualquier aseguradora con "regex genérica" se beneficia automáticamente cuando una futura iteración agregue su patrón específico, sin tocar el resto del parser.

---

## Archivos esperados (referencia para architect)

### Nuevos
- `lib/core/services/ocr/ocr_service.dart` (interfaz)
- `lib/core/services/ocr/ml_kit_ocr_service.dart` (impl)
- `lib/core/services/ocr/ocr_result.dart` (modelo)
- `lib/features/soat/domain/models/soat_extraction.dart`
- `lib/features/soat/domain/usecases/parse_soat_text_usecase.dart`
- `lib/features/soat/domain/usecases/scan_soat_usecase.dart`
- `lib/features/soat/data/parsers/soat_parser.dart`
- `lib/features/soat/data/parsers/insurer_rules/` (un archivo por aseguradora con regex propia)
- `lib/features/soat/data/services/soat_pdf_rasterizer.dart` (opcional, si se aborda PDF en v1)
- `lib/features/soat/presentation/cubit/soat_scan_cubit.dart`
- `lib/features/soat/presentation/pages/soat_scan_page.dart`
- `test/features/soat/parser/soat_parser_test.dart` (con ≥8 fixtures)
- `test/fixtures/soat/` (textos de OCR de muestra, uno por aseguradora)

### Modificados
- `lib/features/soat/presentation/pages/soat_upload_page.dart` (botón "Escanear")
- `lib/features/soat/presentation/pages/soat_manual_capture_page.dart` (aceptar `SoatExtraction?` opcional)
- `lib/features/soat/presentation/pages/soat_manual_capture_params.dart` (extender params)
- `lib/shared/router/app_router.dart` (ruta `soat_scan`)
- `lib/l10n/app_es.arb` (strings nuevos)
- `pubspec.yaml` (`google_mlkit_text_recognition`, `pdfx` o `printing`, opcional `image_cropper`)
- `android/app/src/main/AndroidManifest.xml` (verificar permisos; probablemente sin cambios)
- `ios/Runner/Info.plist` (verificar `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`)
- `docs/features/soat.md` (sección "Auto-fill por OCR")
- `CLAUDE.md` (mención breve del servicio OCR en Core Services)

### Sin cambios
- Backend (`rideglory-api`) — esta iteración es 100% Flutter
- Base de datos — no hay nuevas entidades
- Diseño Pencil — al ser un add-on sobre pantallas existentes, los cambios son menores (banner + ícono de campo auto-rellenado); evaluar en `/solo-design` si requiere frames nuevos

---

## Pre-flight (antes de comenzar)

- [ ] `git merge main --no-edit` (regla del proyecto)
- [ ] Confirmar que iter-6 está merged y `main` está limpio
- [ ] Confirmar versión actual de `google_mlkit_text_recognition` compatible con la versión de Flutter del proyecto
- [ ] Diseño Pencil revisado: ¿necesitamos un frame nuevo para `SoatScanPage` (loader) o reutilizamos el modal genérico? R//: Si es necesario un nuevo frame en pencil.

---

## Definition of Done

- [ ] Todas las stories 7.1–7.5 cumplen acceptance
- [ ] `dart analyze` sin warnings nuevos
- [ ] `flutter test` al 100% (incluye los nuevos tests del parser)
- [ ] Smoke test manual en Android físico: foto + galería + PDF con SOAT real → datos correctos prellenados
- [ ] Smoke test manual en iOS simulador (cámara no aplica) con galería
- [ ] APK release size delta documentado en el PR description
- [ ] `app_es.arb` actualizado y `flutter gen-l10n` ejecutado
- [ ] Telemetría verificada en Firebase Analytics dashboard
- [ ] `docs/features/soat.md` actualizado

---

## Riesgos y mitigaciones (heredados del PRD §7)

Ver PRD para detalle. Resumen:
- Calidad de foto → caída silenciosa a manual.
- Variaciones por aseguradora → reglas por aseguradora + fixtures.
- PDF digital → rasterizar con `pdfx`.
- Tamaño APK +20MB → aceptado.

---

## Próximos pasos

1. **Revisar este scope** con la persona de producto (tú).
2. Si está OK → correr `/solo-plan` con este PRD para obtener el plan formal del PO + Architect.
3. Tras `/solo-plan`, correr `/solo-approve` para activar iter-7 en `workflow/state.json`.
4. Solo entonces, `/iter 7` ejecuta la iteración completa.
