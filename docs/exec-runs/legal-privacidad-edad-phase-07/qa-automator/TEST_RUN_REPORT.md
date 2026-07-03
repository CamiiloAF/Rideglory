# QA Automator — Test Run Report

**Corrida:** legal-privacidad-edad-fase7-organizador
**Fecha (UTC):** 2026-07-03T18:40:38Z
**Agente:** qa-automator

## Resumen

Los 21 casos automatizables del QA_CHECKLIST.md ya contaban con tests
escritos por los agentes Frontend/QA de esta misma corrida
(`registration_detail_page_test.dart`, `attendees_list_navigation_test.dart`,
`event_detail_participants_section_test.dart`,
`registration_contact_actions_test.dart`,
`registration_detail_bottom_bar_test.dart`,
`event_registration_dto_test.dart`). No fue necesario escribir tests nuevos:
se verificó que cada caso tiene una aserción real (no `expect(true, isTrue)`)
y se re-ejecutaron las suites completas para confirmar verde.

## Comandos ejecutados

```
flutter test test/features/event_registration/ --concurrency=1   -> 101/101 pass
flutter test test/features/events/ --concurrency=1                -> 165/165 pass
dart analyze                                                       -> 15 issues (todos pre-existentes, 0 en los 5 archivos del diff de esta fase)
```

## Mapeo caso -> test (todos state=auto-pass)

| Caso | Test file | Test name |
|---|---|---|
| 1.1 | test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart + test/features/event_registration/presentation/registration_detail_page_test.dart | TC-2-44 (tap pending row -> isOrganizerView true) + "isOrganizerView=true ... shows organizer title" |
| 1.2 | test/features/event_registration/presentation/registration_detail_page_test.dart | grupo "bloodType row" (1.1-1.4 internos del archivo) |
| 1.3 | test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart + registration_detail_page_test.dart | TC-2-45 (tap processed row) + "isOrganizerView=true ..." |
| 1.4 | test/features/event_registration/presentation/registration_detail_page_test.dart | "phone='••••' renders '••••' literally with no exception" + resto de filas del grupo bloodType |
| 2.1 | test/features/events/presentation/detail/widgets/event_detail_participants_section_test.dart | setup: `attendeesResult` con 1 registro + `find.text('Juan Pérez')` antes del tap (lista renderizada) |
| 2.2 | test/features/events/presentation/detail/widgets/event_detail_participants_section_test.dart | "tapping a participant row pushes RegistrationDetailExtra.isOrganizerView == true" |
| 3.1 | test/features/event_registration/presentation/registration_detail_page_test.dart | "isOrganizerView=false shows rider title, status banner, and no rider summary" |
| 3.2 | test/features/event_registration/presentation/registration_detail_page_test.dart | mismo test (RegistrationDetailStatusBanner findsOneWidget) |
| 3.3 | test/features/event_registration/presentation/widgets/registration_detail_bottom_bar_test.dart | "vista piloto → editar + cancelar, sin contacto" |
| 3.4 | test/features/event_registration/presentation/widgets/registration_contact_actions_test.dart | "vista piloto (isOrganizerView false) no muestra botones" |
| 4.1 | test/features/event_registration/presentation/registration_detail_page_test.dart | "isOrganizerView=true (including registration.userId == authenticated user id) shows organizer title..." |
| 5.1 | registration_contact_actions_test.dart + registration_detail_bottom_bar_test.dart | "organizador con allowOrganizerContact muestra ambos botones" + "aprobada + allowOrganizerContact + organizador → muestra contacto" |
| 6.1 | test/features/event_registration/presentation/widgets/registration_contact_actions_test.dart | "organizador sin allowOrganizerContact no muestra botones" |
| 6.2 | test/features/event_registration/presentation/widgets/registration_detail_bottom_bar_test.dart | "aprobada sin allowOrganizerContact ni acciones → barra vacía (shrink)" |
| 7A.1 | test/features/event_registration/data/dto/event_registration_dto_test.dart | TC-dto-06..09 |
| 7B.1 | test/features/event_registration/presentation/widgets/registration_detail_bottom_bar_test.dart | "pending + organizador con callbacks → aprobar/rechazar, sin contacto" |
| 7C.1 | test/features/event_registration/presentation/registration_detail_page_test.dart | "phone='••••' renders '••••' literally with no exception" |
| 8.1 | (run-existing) | `flutter test test/features/event_registration/` -> 101/101 pass |
| 8.2 | (run-existing) | `flutter test test/features/events/` -> 165/165 pass |
| 8.3 | (run-existing) | `dart analyze` -> limpio en los 5 archivos del diff |
| 8.4 | test/features/event_registration/presentation/registration_detail_page_test.dart | "1.4: registration with bloodType=null and bloodTypeRaw=null renders 'N/A'" (incluye `tester.takeException()` isNull) |

## Fixes requeridos

Ninguno. Sin fallos ni gaps críticos de cobertura. El working tree queda sin
commitear para revisión humana.
