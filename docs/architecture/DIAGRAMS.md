# Architecture Diagrams — Rideglory

## Iteration 2: Event Filter Flow (Backend Wire-Up)

```mermaid
sequenceDiagram
    participant UI as EventFiltersBottomSheet
    participant Cubit as EventsCubit
    participant UC as GetEventsUseCase
    participant Repo as EventRepositoryImpl
    participant Svc as EventService (Retrofit)
    participant API as rideglory-api

    UI->>Cubit: updateFilters(EventFilters)
    Cubit->>Cubit: _filters = filters
    Cubit->>Cubit: fetchEvents()
    Cubit->>UC: call(type?, dateFrom?, dateTo?, city?)
    UC->>Repo: getEvents(type?, dateFrom?, dateTo?, city?)
    Repo->>Svc: getEvents(@Query type, dateFrom, dateTo, city)
    Svc->>API: GET /events?type=X&dateFrom=Y&city=Z
    API-->>Svc: List<EventDto>
    Svc-->>Repo: List<EventDto>
    Repo-->>UC: Right<List<EventModel>>
    UC-->>Cubit: Right<List<EventModel>>
    Cubit->>Cubit: _allEvents = events; _applyFiltersAndEmit()
    Cubit-->>UI: ResultState.data(filtered)
```

## Iteration 2: Attendee → Rider Profile Navigation

```mermaid
sequenceDiagram
    participant List as AttendeesList
    participant Router as go_router
    participant Page as RiderProfilePage
    participant Cubit as RiderProfileCubit
    participant UC as GetUserByIdUseCase
    participant Repo as UserRepositoryImpl
    participant Svc as UserService (Retrofit)
    participant API as rideglory-api

    List->>Router: context.pushNamed('rider_profile', extra: userId)
    Router->>Page: RiderProfilePage(userId: userId)
    Page->>Cubit: fetchRiderProfile(userId)
    Cubit->>UC: call(userId)
    UC->>Repo: getUserById(userId)
    Repo->>Svc: getUserById(userId)
    Svc->>API: GET /users/:id
    API-->>Svc: UserDto
    Svc-->>Repo: UserDto (extends UserModel)
    Repo-->>UC: Right<UserModel>
    UC-->>Cubit: Right<UserModel>
    Cubit-->>Page: ResultState.data(user)
```

## Iteration 1: Profile Fetch (Reference)

```mermaid
sequenceDiagram
    participant Page as ProfilePage
    participant Cubit as ProfileCubit
    participant UC as GetMyProfileUseCase
    participant Repo as UserRepositoryImpl
    participant Svc as UserService
    participant API as rideglory-api

    Page->>Cubit: fetchProfile()
    Cubit->>UC: call()
    UC->>Repo: getCurrentUser()
    Repo->>Svc: getCurrentUser()
    Svc->>API: GET /users/me
    API-->>Page: ResultState.data(user)
```
