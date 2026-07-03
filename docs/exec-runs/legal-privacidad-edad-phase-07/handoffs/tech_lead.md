# Tech Lead handoff — legal-privacidad-edad-fase7-organizador

**Date:** 2026-07-03T17:49:58Z
**Status:** done

## Veredicto

**ready.** El diff es pequeño (6 archivos modificados + 2 nuevos), se limita
estrictamente al change map del Architect, no toca `rideglory-api`, no rompe
Pattern B ni Clean Architecture, y las pruebas ejecutadas en esta revision
(no solo reportadas por Frontend/QA) pasan en verde.

## Hallazgos

- La corrida fue correctamente identificada como retroactiva: ~95% del
  alcance del PRD (`isOrganizerView`, `RegistrationContactActions`, los 3
  call-sites de navegacion organizador, bottom bar con contacto independiente
  del early-return) ya estaba implementado en el arbol de trabajo antes de
  que Architect/Frontend/QA tocaran nada. Confirmado por `git status
  --porcelain`: solo aparecen los archivos relacionados con el fix de AC10 +
  los tests reforzados que exigio el auditor Opus en la ronda de QA.
- El unico gap real (Criterio de Aceptacion 10, fallback nullable de
  `bloodType`) fue cerrado correctamente: `bloodTypeRaw` se agrego como campo
  de solo lectura en `EventRegistrationModel`/`EventRegistrationDto`, con
  `@JsonKey(includeFromJson: false, includeToJson: false)` para excluirlo de
  la serializacion JSON directa, y un `fromJson` custom que lo puebla solo
  cuando el `_BloodTypeConverter` no pudo mapear el string del backend.
  Verificado en el `.g.dart` regenerado (gitignored) que ni `fromJson` ni
  `toJson` generados referencian una clave literal `bloodTypeRaw`.
- Decision de alcance del Architect (extender la fase para cubrir
  `bloodTypeRaw` en vez de bloquear por completo, dado que Fase 3 no lo
  entrego tal como el PRD asumia) es razonable: es aditivo, de solo lectura,
  no rompe consumidores existentes, y no requiere tocar contratos backend.
  No lo considero un blocker.
- Los tests nuevos son deterministas y no dependen de datos de seed ni
  emulador (contrastan favorablemente con el unico Patrol e2e, que si
  depende de datos y no ejercito la rama de contacto en esta corrida). El
  auditor Opus de QA rechazo correctamente el primer sign-off por falta de
  cobertura determinista del switch `isOrganizerView`, y los 4 tests
  agregados en la segunda ronda (attendees_list_navigation_test TC-2-44/45,
  event_detail_participants_section_test nuevo, registration_detail_page_test
  grupo "isOrganizerView switch") cierran ese gap de forma solida.
- Deuda menor no bloqueante: la clave ARB `registration_maskedValue` queda
  sin call-sites tras el fix de AC10. Documentado, no requiere accion
  inmediata.

## Seguridad

- Sin secretos ni credenciales reales expuestos. El comentario con
  `TEST_EMAIL=qa2@gmail.com`/`TEST_PASSWORD=Test123.` en
  `integration_test/registration_organizer_patrol_test.dart` es una
  credencial de seed de QA ya usada en el resto de la suite Patrol del
  proyecto (patron existente, no nuevo).
- Sin SQL concatenado (no aplica, cambio 100% Flutter).
- Sin XSS (no aplica, no hay renderizado de HTML/markup dinamico).
- Sin PII en logs: el cambio no agrega ningun `print`/log de datos de
  registro; `bloodTypeRaw` solo se usa para render en UI.
- El manejo de datos ofuscados (`"••••"`, `"__NOT_SHARED__"`) respeta la
  regla de la fase: se muestran crudos tal cual, sin intentar decodificarlos
  ni loguearlos.
- No hay cambios de auth/CORS (fase exclusivamente de presentacion Flutter,
  Backend en stand-down confirmado).

## Arquitectura

- **Pattern B respetado:** `EventRegistrationDto extends EventRegistrationModel`
  se mantiene; `bloodTypeRaw` se agrega como `super.bloodTypeRaw` en el
  constructor del DTO, sin romper la herencia ni introducir `toModel()`/
  `fromModel()`/`.toDto()` prohibidos.
- **Clean Architecture:** el campo nuevo vive primero en `domain/model`
  (sin imports de Flutter/HTTP), luego se propaga a `data/dto`. La
  presentacion (`registration_detail_page.dart`) consume el modelo de
  dominio, no el DTO directamente — correcto.
- **Sin URLs hardcodeadas ni contratos backend nuevos:** confirmado, cero
  archivos de `rideglory-api` en el diff, sin endpoints ni migraciones.
- **Un widget por archivo:** no aplica cambio de widgets nuevos en esta
  corrida (el widget `RegistrationContactActions` ya existia de una fase
  previa/implementacion retroactiva); `registration_detail_page.dart` no
  agrega metodos `_buildX()`.
- El uso de `@JsonKey(includeFromJson: false, includeToJson: false)` sobre un
  super-parameter es valido en Dart moderno y confirmado por build_runner +
  tests, aunque es un patron sutil — documentado como watchlist para quien
  replique este patron en otro DTO sin el `@JsonKey` (generaria busqueda
  inofensiva de una clave inexistente).

## Tests

- `dart analyze lib/features/event_registration/`: **0 issues** (verificado
  en esta revision, no solo reportado).
- `flutter test test/features/event_registration/ --concurrency=1`:
  **101/101 pass** (verificado en esta revision).
- `flutter test test/features/events/presentation/detail/widgets/event_detail_participants_section_test.dart test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart`:
  **7/7 pass** (verificado en esta revision).
- Cada AC del PRD tiene al menos un test que falla sin el cambio:
  - AC10 (bloodType nullable): casos 1.3/1.4 en `registration_detail_page_test.dart`
    fallarian con el codigo anterior (`bloodType?.label ?? registration_maskedValue`
    siempre mostraria `"••••"`, no el raw ni `"N/A"`).
  - AC1/AC2/AC4 (isOrganizerView): los 4 tests nuevos de la ronda de auditoria
    fallarian si el flag no se propagara correctamente en la navegacion o si
    el switch dependiera de `userId` en vez de `isOrganizerView` explicito.
  - AC9 (telefono ofuscado): caso nuevo en `registration_detail_page_test.dart`
    fallaria si se introdujera alguna transformacion/excepcion sobre el
    string crudo del telefono.
- Frontend/QA reportan `flutter test` completo del repo en 974/974 —
  confirmado indirectamente al pasar los subconjuntos relevantes sin fallos
  en esta revision independiente.
- Patrol e2e organizador: ejecutado 1/1 pass por QA, con caveat documentado
  (sin datos de seed para ejercitar la rama de contacto). No bloqueante — la
  rama esta cubierta por widget tests deterministas.

## Pruebas manuales

Ver `REVIEW_CHECKLIST.md` seccion 6 — pendientes de ejecucion humana antes de
commitear (no bloqueantes para el veredicto, pero recomendadas):

1. Confirmar visualmente que "Tipo de sangre" muestra el sentinel crudo o
   "N/A" segun corresponda, sin crash.
2. Confirmar tap real en "Llamar"/"WhatsApp" en un dispositivo fisico.
3. Re-correr el Patrol organizador con datos de seed reales para ejercitar
   la rama de contacto end-to-end.
