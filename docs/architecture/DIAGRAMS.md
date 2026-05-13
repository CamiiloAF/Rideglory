# Architecture diagrams — Rideglory

> Living document. Append new diagrams per iteration when data model or boundaries change.

---

## Iteration 1 — Profile fetch flow

No data model changes (no new entities, no schema migration). The only architectural addition is a presentation-layer cubit + a domain use case wrapping the existing `UserRepository`. Diagram below shows the request flow for the profile page on first render.

```mermaid
sequenceDiagram
    autonumber
    participant UI as ProfilePage (widget)
    participant Cubit as ProfileCubit
    participant UC as GetMyProfileUseCase
    participant Repo as UserRepository (impl)
    participant Svc as UserService (Retrofit)
    participant Dio as Dio + FirebaseAuthInterceptor
    participant API as rideglory-api /users/me
    participant FB as Firebase Auth

    UI->>Cubit: fetchProfile()
    Cubit-->>UI: ResultState.loading()
    Cubit->>UC: call()
    UC->>Repo: getCurrentUser()
    Repo->>Svc: getCurrentUser()
    Svc->>Dio: GET /api/users/me
    Dio->>FB: getIdToken()
    FB-->>Dio: <jwt>
    Dio->>API: GET /users/me (Authorization: Bearer <jwt>)
    API-->>Dio: 200 UserDto
    Dio-->>Svc: UserDto
    Svc-->>Repo: UserDto
    Repo-->>UC: Right(UserModel)
    UC-->>Cubit: Right(UserModel)
    Cubit-->>UI: ResultState.data(user)
```

### Error variant
On any failure (network, 401, 5xx) the chain returns `Left(DomainException)` and `ProfileCubit` emits `ResultState.error`. The page renders an error banner + retry button; tapping retry restarts the sequence above.

---

## Logical layering (unchanged, recap)

```mermaid
flowchart LR
    subgraph Presentation
      Page[ProfilePage]
      Cubit[ProfileCubit]
    end
    subgraph Domain
      UC[GetMyProfileUseCase]
      Model[UserModel]
      RepoI[UserRepository interface]
    end
    subgraph Data
      RepoImpl[UserRepositoryImpl]
      Service[UserService - Retrofit]
      DTO[UserDto]
    end
    Page --> Cubit --> UC --> RepoI
    RepoImpl -. implements .-> RepoI
    RepoImpl --> Service --> DTO
    RepoImpl --> Model
```

Dependencies flow inward toward `Domain`. `Data` and `Presentation` both depend on `Domain`; never the reverse.

---

## ERD

No entity changes this iteration. Existing `User` (Prisma) and `Vehicle` (Prisma) tables are untouched. ERD will be introduced when SOAT module lands in Iteration 3a.

---

## Iteration 4 — AI Cover Generation flow

New data flow: Flutter form → backend endpoint → Claude Haiku → Unsplash → image URL back to Flutter.

```mermaid
sequenceDiagram
    autonumber
    participant UI as EventFormContent (widget)
    participant FC as EventFormCubit
    participant UC as GetGenerateCoverUseCase
    participant Repo as EventCoverRepositoryImpl
    participant Svc as EventCoverService (Retrofit)
    participant API as api-gateway POST /events/generate-cover
    participant Claude as Claude Haiku (Anthropic SDK)
    participant Unsplash as Unsplash API

    UI->>FC: generateCover(title, eventType, city)
    FC-->>UI: EventFormState(coverGenerationResult: loading())
    FC->>UC: call(title, eventType, city)
    UC->>Repo: generateCover(...)
    Repo->>Svc: POST /events/generate-cover {title, eventType, city}
    Svc->>API: HTTP POST (Firebase ID token)
    API->>Claude: messages.create (search query prompt)
    Claude-->>API: "mountain motorcycle offroad"
    API->>Unsplash: GET /search/photos?query=...&per_page=1&orientation=landscape
    Unsplash-->>API: { results: [{ urls: { regular: "https://..." } }] }
    API-->>Svc: 200 { imageUrl, source: "unsplash", query }
    Svc-->>Repo: CoverGenerationDto
    Repo-->>UC: Right("https://...")
    UC-->>FC: Right(imageUrl)
    FC-->>UI: EventFormState(coverGenerationResult: data(imageUrl))
    UI->>UI: FormImageCubit.setRemoteImageUrl(imageUrl)
    UI-->>UI: CoverPreviewWidget shows image + Regenerar button
```

### Error variant (503 from Claude or Unsplash)
`API` returns 503 → `Repo` maps to `Left(DomainException)` → `FC` emits `coverGenerationResult: error(DomainException)` → UI shows Spanish SnackBar → state resets to idle.

---

## EventFormState data model (Iteration 4)

```mermaid
classDiagram
    class EventFormState {
        +ResultState~EventModel~ saveResult
        +ResultState~String~ coverGenerationResult
    }
    class ResultState~T~ {
        <<union>>
        initial()
        loading()
        data(T data)
        empty()
        error(DomainException error)
    }
    EventFormState --> ResultState
```

---

## Change log
- 2026-05-12 (iter-1): Initial diagrams. Profile fetch sequence + layer recap. No ERD yet.
- 2026-05-13 (iter-4): AI Cover Generation sequence + EventFormState class diagram added.
