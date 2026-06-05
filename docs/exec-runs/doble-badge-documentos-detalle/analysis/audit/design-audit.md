# Auditoría — Design handoff (doble-badge-documentos-detalle)

**Fecha:** 2026-06-04T20:58:22Z
**Rol auditado:** design
**Resultado:** APROBADO (con observaciones menores no bloqueantes)

## Alcance del rol
El agente design entrega especificación (handoff + mockup HTML), no código de app.
No se esperan tests ni cambios en `lib/`. `git diff` vacío: correcto.

## Verificación contra el código real
- `VehicleDocumentCard` existe y ya monta SOAT vía `kind: soat`. OK.
- `_RtmDocumentCardBody` actual es stub plano (sin Container/header/Divider/BlocBuilder/estados).
  El handoff describe correctamente la brecha y el trabajo de Frontend. OK.
- `TecnomecanicaModel with VehicleDocumentExpiry implements VehicleDocumentModel`,
  expone `documentStatus: VehicleDocumentStatus` + `expiryDate`. Claim del handoff correcto.
- Rutas `soatStatus` y `tecnomecanicaStatus` existen. OK.
- `vehicle_soat_section.dart` existe y debe borrarse; `vehicle_soat_card.dart` NO existe
  (el PRD asumía su borrado; ya no está). El handoff solo lista `vehicle_soat_section.dart`. Correcto.
- Violación A11 actual confirmada: `vehicle_detail_view.dart` importa `TecnomecanicaEntryFlow`
  (features/tecnomecanica/) en el stub `[TEST]`. El plan del handoff lo elimina al cambiar a
  `VehicleDocumentCard(kind: rtm)`. OK.
- Claves ARB reutilizadas (`tecnomecanica_status_no_rtm`, `vehicle_doc_techreview_label`,
  `vehicle_doc_expires_on`, `vehicle_soat_section_title`) existen. OK.
- Claves nuevas RTM (`vehicle_doc_rtm_status_valid/_expiring_soon/_expired`) NO existen aún:
  trabajo pendiente de Frontend (correctamente delegado). OK.

## Observaciones (no bloqueantes — para Frontend)
1. Las 3 claves RTM nuevas duplican valores de claves SOAT existentes
   (`soat_status_valid`="Vigente", `soat_status_expiring_soon`="Por vencer",
   `maintenance_expired_label`="vencido"). El PRD §3 deja la unificación fuera de alcance,
   así que claves RTM propias son aceptables y consistentes con el patrón SOAT. Solo se anota.
2. El handoff §Copy (línea 120) indica doc-type sub-label RTM = `vehicle_doc_techreview_label`
   ("Técnico-mecánica"), pero el stub actual usa `tecnomecanica_page_status_title`
   ("Mi tecnomecánica") en la línea 264 de `vehicle_document_card.dart`. El handoff §Notas
   (líneas 130-132) solo manda corregir el HEADER, no el doc-type label. Frontend debe cambiar
   ambos. Recomendación: el handoff debió señalar explícitamente la línea 264.

## Conclusión
Handoff exhaustivo y preciso: cubre todos los estados UX (idle/loading/empty/error/3 vigencias),
copy en español consistente, reúso de componentes shared, respeta Clean Architecture (manda quitar
import concreto de tecnomecanica/ del host), entrega mockup HTML con los 4 combos de estado.
Aprobado.
