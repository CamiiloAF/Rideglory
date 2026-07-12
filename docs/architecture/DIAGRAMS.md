# Architecture Diagrams — Rideglory

> Living document. Updated by Architect each iteration when component hierarchies, boundaries, or data models change.

---

## Iteration 1 — UI/UX Redesign (presentation layer only)

No data model changes this iteration. The diagrams below capture the **design system component hierarchy** as it stands after iter-1, including the two new primitives (`AppEventBadge` atom, `DocumentSlotPill` molecule) extracted from Pencil frames `zKkmE` and `aGqnv` respectively.

### Design system layering

```mermaid
graph TD
  subgraph Foundation
    Tokens["Tokens<br/>app_spacing · app_radius · app_size"]
    Theme["Theme<br/>app_colors · app_text_styles · app_theme"]
  end

  subgraph Atoms
    A_Btn[AppButton]
    A_TBtn[AppTextButton]
    A_TF[AppTextField]
    A_PWTF[AppPasswordTextField]
    A_DD[AppDropdown]
    A_DP[AppDatePicker]
    A_CB[AppCheckbox]
    A_MF[AppMileageField]
    A_CI[AppChipsInput]
    A_TFL[TextFieldLabel]
    A_IC[InfoChip]
    A_DPill[DetailPill]
    A_FC[AppFilterChip]
    A_AB[AppAppBar]
    A_LI[AppLoadingIndicator]
    A_C[AppCard]
    A_ST[AppSectionTitle]
    A_EB["AppEventBadge<br/>NEW · iter-1"]
  end

  subgraph Molecules
    M_AC[AppAutocompleteField]
    M_ACC[AppAutocompleteChipsField]
    M_CA[AppCityAutocomplete]
    M_SB[AppSearchBar]
    M_IP[AppImagePicker]
    M_RTE[AppRichTextEditor]
    M_AD[AppDialog]
    M_CD[ConfirmationDialog]
    M_ID[InfoDialog]
    M_ABS[AppBottomSheet]
    M_ESW[EmptyStateWidget]
    M_NSR[NoSearchResultsEmptyWidget]
    M_ARB[ApproveRejectBar]
    M_CPM[ContactPopupMenuButton]
    M_FSH[FormSectionHeader]
    M_CPR[ContainerPullToRefresh]
    M_DSP["DocumentSlotPill<br/>NEW · iter-1"]
  end

  Theme --> Atoms
  Tokens --> Atoms
  Atoms --> Molecules
  Theme --> Molecules
  Tokens --> Molecules

  A_Btn --> M_ARB
  A_TF --> M_AC
  A_TF --> M_ACC
  A_TF --> M_CA
  A_TF --> M_SB
  A_C --> M_DSP
  A_IC --> M_DSP
```

### Iter-1 consumer map for new primitives

```mermaid
graph LR
  subgraph DesignSystem
    AEB["AppEventBadge (atom)<br/>frame zKkmE"]
    DSP["DocumentSlotPill (molecule)<br/>frame aGqnv"]
  end

  subgraph EventsFeature
    EL[event_list_page]
    ED[event_detail_page]
    UPC[upcoming_events_card<br/>(Home)]
  end

  subgraph VehiclesFeature
    VD[vehicle_detail_page]
    VF[vehicle_form_page<br/>(non-functional placeholder)]
  end

  AEB --> EL
  AEB --> ED
  AEB --> UPC
  DSP --> VD
  DSP --> VF

  DSP -. "iter-2 reuse" .-> SOAT[soat_status_badge<br/>iter-2]
```

### Module-scoped PR sequence

```mermaid
flowchart LR
  PR1[PR 1<br/>splash + auth] --> PR2[PR 2<br/>home]
  PR2 --> PR3a{{Extract<br/>AppEventBadge}}
  PR3a --> PR3[PR 3<br/>events]
  PR3 --> PR4a{{Extract<br/>DocumentSlotPill}}
  PR4a --> PR4[PR 4<br/>garage]
  PR4 --> PR5[PR 5<br/>maintenance + registration]
  PR5 --> Gate[QA Gate<br/>5 smoke tests]
  Gate --> Merge[Merge iter-1 → main]
```

### Color tokenization decision flow (per-file)

```mermaid
flowchart TD
  Start[Encountered Color literal<br/>in lib/features/] --> Q1{Has semantic<br/>role?}
  Q1 -- yes --> CS[Theme.of(context)<br/>.colorScheme.&lt;role&gt;]
  Q1 -- no --> Q2{Mapped in<br/>AppColors?}
  Q2 -- yes --> AC[AppColors.&lt;constant&gt;]
  Q2 -- no --> Q3{Status indicator?}
  Q3 -- yes --> ST[AppColors.success/<br/>warning/error/info]
  Q3 -- no --> Add[Add new constant<br/>to AppColors<br/>+ note in PR]
  CS --> Done
  AC --> Done
  ST --> Done
  Add --> Done[dart analyze]
```

---

## Iteration 3 — Tracking + SOS + Mapbox Migration

### ERD — Event model with iter-3 additions

```mermaid
erDiagram
    Event {
        string id PK
        string ownerId FK
        string name
        string state "SCHEDULED | IN_PROGRESS | FINISHED | CANCELLED"
        Json routeGeoJson "nullable — GeoJSON LineString"
        DateTime sosTriggeredAt "nullable — dedup guard"
        DateTime reminderSentAt "nullable — 24h push dedup"
        DateTime startDate
    }
    Registration {
        string id PK
        string eventId FK
        string userId FK
        string status "PENDING | APPROVED | REJECTED"
    }
    MaintenanceRecord {
        string id PK
        string vehicleId FK
        string serviceType
        DateTime nextMaintenanceDate "nullable"
        boolean receiveDateAlert
        DateTime reminderSentAt "nullable — 30d push dedup"
    }
    Vehicle {
        string id PK
        string userId FK
        string name
        SoatStatus soatStatus "NONE | VALID | EXPIRING_SOON | EXPIRED"
        DateTime soatExpiryDate "nullable"
    }
    Notification {
        string id PK
        string userId FK
        string type "SOS_ALERT | EVENT_REMINDER | MAINTENANCE_REMINDER | ..."
        Json payload
        boolean isRead
        DateTime createdAt
    }

    Event ||--o{ Registration : "has"
    Vehicle ||--o{ MaintenanceRecord : "has"
```

### SOS alert sequence diagram

```mermaid
sequenceDiagram
    participant R as Rider (Flutter)
    participant GW as TrackingGateway (api-gateway)
    participant EMS as events-ms
    participant NS as NotificationService
    participant FCM as Firebase FCM
    participant Others as Other riders (Flutter)

    R->>R: Tap SOS button
    R->>R: SosConfirmDialog shown
    R->>R: Confirm → LiveTrackingCubit.triggerSos()
    R->>GW: WS message { type: "tracking.sos", data: { eventId, userId } }
    GW->>EMS: RPC markSosTriggered(eventId)
    alt sosTriggeredAt already set
        EMS-->>GW: { triggered: false }
        GW->>R: (no-op — silent deduplicate)
    else first SOS
        EMS->>EMS: SET sosTriggeredAt = now()
        EMS-->>GW: { triggered: true, fullName, phone?, latitude, longitude }
        GW->>GW: broadcast to WS room
        GW-->>Others: { type: "tracking.sos.alert", data: { userId, fullName, latitude, longitude, phone? } }
        GW->>NS: dispatch FCM multicast (approved registrant tokens)
        NS->>FCM: sendMulticast(tokens, payload)
        FCM-->>Others: Push notification "¡Alerta SOS! {fullName}"
        GW->>NS: insert notifications row (type: SOS_ALERT)
    end
    R-->>R: "SOS enviado" confirmation shown
    Others->>Others: SosBanner rendered; red pulsing marker on map
```

### Mapbox migration — SDK swap (Story 3.0)

```mermaid
flowchart TD
    subgraph Before["Before (google_maps_flutter + geocoding)"]
        GM[GoogleMap widget]
        GMC[GoogleMapController]
        BD[BitmapDescriptor]
        GEO[geocoding.locationFromAddress]
    end
    subgraph After["After (mapbox_maps_flutter)"]
        MW[MapWidget]
        MBM[MapboxMap]
        PAM[PointAnnotationManager]
        PS[PlaceService.geocode → Retrofit]
    end
    subgraph Files["4 Dart files migrated"]
        LMW[live_map_widget.dart]
        LMP[live_map_page.dart]
        IMI[initials_marker_icon.dart]
        RMP[route_map_preview.dart]
    end
    GM --> MW
    GMC --> MBM
    BD --> PAM
    GEO --> PS
    MW --> LMW
    MW --> LMP
    MW --> RMP
    PAM --> LMW
    PAM --> RMP
    PS --> RMP
    MBM --> LMP
```

---

## `DELETE /users/me` idempotency (eliminacion-cuenta-phase-04)

8-step orchestration in `AccountDeletionService.deleteAccount` (api-gateway). Diagram shows the
retry-after-full-completion case (step 1 gap found by phase-04) and the concurrent-race case
(steps 7-8).

```mermaid
sequenceDiagram
    participant C1 as Client (call 1)
    participant C2 as Client (call 2, retry/race)
    participant GW as api-gateway<br/>AccountDeletionService
    participant U as users-ms
    participant FB as Firebase Admin

    Note over C1,C2: Case A — retry AFTER a full previous run completed
    C1->>GW: DELETE /users/me
    GW->>U: findUserByEmail(email)
    U-->>GW: 404 not found (already hard-deleted)
    Note right of GW: ADR-1 (phase-04): catch "not found"<br/>on step 1 → return early = 204.<br/>Without this fix: 404 leaks to client<br/>(undocumented contract code).
    GW-->>C1: 204 (idempotent no-op)

    Note over C1,C2: Case B — two overlapping calls, same uid
    C1->>GW: DELETE /users/me
    C2->>GW: DELETE /users/me
    par both resolve user before either finishes
        GW->>U: findUserByEmail (call 1) → user.id
        GW->>U: findUserByEmail (call 2) → user.id
    end
    Note over GW: steps 2-6 (organizer precondition,<br/>hardDeleteAllByOwner, storage cleanup,<br/>softDeleteMaintenances, anonymizeRegistrations)<br/>already idempotent (findMany/updateMany) — no fix needed
    GW->>U: hardDeleteUser (call 1) — wins race
    U-->>GW: deleted
    GW->>U: hardDeleteUser (call 2) — loses race
    U-->>GW: P2025 (not found) → no-op (phase-04 fix)
    GW->>FB: deleteUser(uid) (call 1) — wins race
    FB-->>GW: deleted
    GW->>FB: deleteUser(uid) (call 2) — loses race
    FB-->>GW: auth/user-not-found → no-op (phase-04 fix)
    GW-->>C1: 204
    GW-->>C2: 204
```

Client-side session recovery (Flutter), when the account was fully deleted while the app was
closed:

```mermaid
sequenceDiagram
    participant App as App reopens
    participant AC as AuthCubit
    participant API as Any authenticated call
    participant FAI as FirebaseAuthInterceptor
    participant Router as GoRouter

    App->>AC: checkAuthState()
    AC-->>App: authenticated (stale cached session)
    App->>API: e.g. GET /users/me
    API-->>FAI: 401
    FAI->>FAI: getIdToken(true) forced refresh
    FAI-->>FAI: throws FirebaseAuthException<br/>(user-not-found / user-disabled / user-token-expired)
    Note right of FAI: phase-04: only these 3 codes trigger<br/>logout — never network-request-failed
    FAI->>AC: GetIt.instance<AuthCubit>().signOut() (defensive try/catch)
    AC-->>Router: AuthState.unauthenticated (stream)
    Router->>Router: GoRouterRefreshStream fires redirect
    Router-->>App: navigate to /login + snackbar<br/>"Tu sesión terminó, inicia sesión de nuevo."
```

## Change log

- 2026-07-11 (eliminacion-cuenta-phase-04): Added `DELETE /users/me` idempotency sequence diagrams
  (retry-after-completion + concurrent race) and the client-side forced-logout sequence. No ERD
  change — no schema/data model changes in this phase, only error-handling hardening.
- 2026-05-14 (iter-1): Initial diagrams document created. Captures design-system layering, new iter-1 primitives (`AppEventBadge`, `DocumentSlotPill`) and their consumers, module PR sequence, and color tokenization decision flow. No ERD or sequence diagrams — iter-1 introduces no new data models or async flows.
- 2026-05-15 (iter-3): Added ERD (Event + Registration + MaintenanceRecord + Vehicle + Notification with iter-3 fields: `routeGeoJson`, `sosTriggeredAt`, `reminderSentAt`, `soatStatus`, `soatExpiryDate`). Added SOS alert sequence diagram (WS → gateway → events-ms dedup → broadcast + FCM). Added Mapbox migration SDK-swap flowchart (4 Dart files, 4 type replacements).
