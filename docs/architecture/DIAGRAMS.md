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

## Iteration 2 — SOAT + Notification Foundation

Iter-2 introduces new persisted entities and async flows. ERD covers the new backend tables; sequence diagrams cover the SOAT save flow and the FCM notification lifecycle (foreground + background isolate).

### ERD — new entities

```mermaid
erDiagram
  Vehicle ||--o| Soat : "has one (vehicles-ms)"
  User ||--o{ Notification : "receives (api-gateway)"
  User {
    string id PK
    string fcmToken "NEW iter-2 · nullable · users-ms"
  }
  Vehicle {
    string id PK
    string ownerId
  }
  Soat {
    string id PK
    string vehicleId FK "unique"
    string policyNumber
    datetime startDate
    datetime expiryDate
    string insurer
    string documentUrl "nullable"
    datetime createdAt
    datetime updatedAt
  }
  Notification {
    string id PK
    string userId
    string type "SOAT_30D|SOAT_7D|SOAT_DAY_OF|NEW_REGISTRATION|REGISTRATION_APPROVED|REGISTRATION_REJECTED"
    json payload "scalar IDs only"
    boolean isRead "default false"
    datetime createdAt
  }
```

`Soat` lives in vehicles-ms. `Notification` lives in api-gateway's first-ever Prisma schema. `fcmToken` is added to `User` in users-ms.

### Sequence — SOAT save + client-side status

```mermaid
sequenceDiagram
  participant UI as SoatUploadPage / SoatManualFormPage
  participant Cubit as SoatCubit
  participant Repo as SoatRepositoryImpl
  participant FS as Firebase Storage
  participant API as rideglory-api (vehicles-ms)

  UI->>Cubit: save(soat, localDocumentPath?)
  Cubit->>Cubit: emit Loading
  opt document attached
    Repo->>FS: putFile(soat/{vehicleId}/document.ext)
    FS-->>Repo: documentUrl
  end
  Cubit->>Repo: saveSoat(SoatModel)
  Repo->>API: POST /api/vehicles/:vehicleId/soat
  API-->>Repo: SoatResponse (no status field)
  Repo-->>Cubit: Either<DomainException, SoatModel>
  Cubit->>Cubit: emit Data(soat)
  Note over UI: SoatModel.status computed client-side<br/>(expiryDate vs now) → DocumentSlotPill state
```

### Sequence — FCM notification lifecycle

```mermaid
sequenceDiagram
  participant App as Flutter App
  participant Auth as AuthCubit
  participant FCM as FcmService
  participant GW as api-gateway
  participant FB as Firebase Cloud Messaging
  participant BG as Background Isolate

  Note over Auth: post-login
  Auth->>FCM: initialize() + requestPermission()
  FCM->>GW: POST /api/notifications/fcm-token { fcmToken }
  GW-->>FCM: 204

  Note over GW: trigger (registration approved / SOAT cron @America/Bogota)
  GW->>GW: INSERT Notification row
  GW->>FB: send multicast (payload: scalar IDs)
  alt app foreground
    FB-->>FCM: onMessage
    FCM->>FCM: flutter_local_notifications banner
  else app background / terminated
    FB-->>BG: onBackgroundMessage (@pragma vm:entry-point)
    BG->>BG: Firebase.initializeApp() + configureDependencies()
    BG->>BG: show local notification
  end

  Note over App: user opens Notification Center
  App->>GW: GET /api/notifications?cursor=&limit=20
  GW-->>App: { data, nextCursor }
  App->>GW: PATCH /api/notifications/:id/read | /read-all
```

---

## Change log

- 2026-05-14 (iter-1): Initial diagrams document created. Captures design-system layering, new iter-1 primitives (`AppEventBadge`, `DocumentSlotPill`) and their consumers, module PR sequence, and color tokenization decision flow. No ERD or sequence diagrams — iter-1 introduces no new data models or async flows.
- 2026-05-14 (iter-2): Added ERD for new entities (`Soat` in vehicles-ms, `Notification` in api-gateway, `fcmToken` on `User` in users-ms). Added sequence diagrams: SOAT save flow (with client-side status computation) and FCM notification lifecycle (token registration, trigger+insert+multicast, foreground vs background-isolate handling, cursor-paginated read).
