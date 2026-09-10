# Fidelidad visual — tracking

Comparación de los golden tests contra su frame en `rideglory.pen`. Los goldens se generan con `flutter test --update-goldens` y se comparan a ojo contra `TakeScreenshot` del nodeId. **Límite conocido:** bajo `flutter_test` la fuente Outfit no está empaquetada, así que los goldens pintan los glifos como bloques; sirven para jerarquía, layout, tamaños y color, no para tipografía.

## live_ride (2026-09-10)

| Golden | Frame Pencil | Veredicto | Notas |
|---|---|---|---|
| `lv1_live_ride_sharing.png` | `RJ9Aq` | Fiel | Header sobre `$c-plate`, chip compartiendo, Detener rojo, marcadores (líder en acento), SOS 68dp, hoja con tarjetas de rider |
| `lv1b_live_ride_not_sharing.png` | `gcRLk` | Fiel | CTA "Compartir mi ubicación" en vez de chip+Detener |
| `lv4a_sos_pending.png` | `bAklu` | Fiel | Franja roja, chip pendiente en warning, tarjeta de coordenadas, primario/secundario/terciario/cierre destructivo |
| `lv4b_sos_confirmed.png` | `KVhKk` | Fiel | Chip confirmado en success |
| `lv5b_sos_other_sheet.png` | `p4830` | Fiel | Llamar / Ver en el mapa / Marcar como resuelto (solo organizador) |
| `lv6_live_riders.png` | `UGgbU` | Fiel | Lista con estado por rider y botón llamar 48dp |
| `lv7_live_ride_finished.png` | `OQJZS` | Fiel | Banner de fin + Volver al evento |

Diferencia aceptada: el botón compacto ("Ver" del banner, "Detener" del header) usa radio 16 (`AppRadii.sm`) en vez del píldora completa del `.pen`; se corrige en el `.pen` o en `AppPrimaryButton(compact:)` cuando se toque ese componente.

Gap: el mapa se renderiza sin tiles en goldens (`showMapTiles: false`); la capa de mapa real se verifica en dispositivo.

Revisión hecha por el orquestador: el agente `pencil-fidelity-reviewer` no tiene acceso a `mcp__pencil__execute` en su definición y no pudo capturar frames — pendiente darle esa herramienta en `.claude/agents/pencil-fidelity-reviewer.md`.
