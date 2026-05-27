# iter-6 ARB Cleanup Report — REFACTOR-15

## Summary

| Metric | Value |
|--------|-------|
| Baseline key count | 1311 |
| Final key count | 742 |
| Keys deleted (unused) | 563 |
| Keys deleted (migrated to generic) | 6 |
| Total deleted | 569 |
| Reduction % | 43.4% |
| Dynamic-risk keys preserved | 11 |

## Methodology

### Phase 1 — Unused key detection

Used `grep -rn ".${key}\b"` across `lib/` (excluding `lib/l10n/`) for all 1311 ARB keys.
Result: 574 keys with 0 usages.

### Phase 2 — Dynamic-reference risk analysis

The following key families were identified as potential dynamic-reference traps and KEPT:
- `notification_approved_*` — push notification payload (backend-driven)
- `notification_rejected_*` — push notification payload  
- `notification_newRegistration_*` — push notification payload
- `notification_soat*` — push notification payload (soat30d, soat7d, soatDayOf)

Total preserved for dynamic risk: 11 keys.
Safe to delete: 563 keys.

### Phase 3 — Unifications

Migrated 6 feature-specific keys that duplicated existing generic keys:

| Old key | Generic key used | Files updated |
|---------|------------------|---------------|
| `vehicle_form_nav_cancel` | `cancel` | `vehicle_form_view.dart` |
| `event_form_cancel_action` | `cancel` | `event_form_view.dart` |
| `vehicle_form_nav_save` | `save` | `vehicle_form_view.dart` |
| `rider_errorRetry` | `retry` | `rider_profile_error.dart` |
| `notification_retry` | `retry` | `notifications_error_state.dart` |
| `soat_retry` | `retry` | `soat_status_view.dart` |

Note: Generic keys (`cancel`, `save`, `retry`, `delete`, `back`, `apply`, etc.) already existed
at the top of the ARB. No new `common_*` keys were needed — the codebase already had them.

## Key Families Deleted

Most deleted keys were orphaned after previous feature refactors:
- `auth_*` old camelCase duplicates (48 keys)
- `event_*` orphaned filter/form/badge keys (151 keys)
- `vehicle_*` old setup wizard and tooltip keys (95 keys)
- `maintenance_*` unused configuration/alert keys (94 keys)
- `registration_*` unused form/status keys (42 keys)
- `home_*` old dashboard keys (36 keys)
- `soat_*` old upload/form keys (22 keys)
- `tracking_*` unused push/ride keys (12 keys)
- `map_*` unused live-tracking keys (15 keys)
- `sos_*` unused SOS feature keys (7 keys)
- `splash_*` old splash keys (8 keys)
- Other small families

## Risk Assessment

- `dart analyze`: 0 errors, 0 warnings post-deletion
- `flutter test`: pre-existing failure in `event_filters_bottom_sheet_test.dart:TC-2-20`
  (confirmed pre-existing before this batch)
- No dynamic-reference traps encountered in Flutter Dart code
- Push notification title/subtitle strings come from backend payload, not l10n
