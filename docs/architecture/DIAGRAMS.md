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

## Change log
- 2026-05-12 (iter-1): Initial diagrams. Profile fetch sequence + layer recap. No ERD yet.
