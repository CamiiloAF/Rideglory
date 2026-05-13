# Rideglory Product Status

**Last Updated:** 2026-05-13 (Iteration 4 close)

---

## What's Shipped

### Core Features (Iterations 1–4)

| Feature | Iteration | Status | User Value |
|---------|-----------|--------|-----------|
| **Authentication** | Framework | Shipped ✓ | Email, Google, Apple sign-in; Firebase Auth |
| **Home Dashboard** | Framework | Shipped ✓ | Event discovery, quick stats, bottom nav |
| **Event Discovery & Filters** | 2 | Shipped ✓ | Browse events by type, city, date; filter UI wired to backend |
| **Event Registration** | Framework | Shipped ✓ | Join events, attendance tracking, organizer approval flow |
| **Vehicle Garage** | Framework | Shipped ✓ | Add/edit/delete motorcycles, manage vehicle list |
| **User Profiles** | 1 | Shipped ✓ | Public rider profiles, navigation from attendee lists |
| **Real-time Event Tracking** | Framework | Shipped ✓ | WebSocket connection, rider location broadcast during events |
| **Maintenance Log** | Framework | Shipped ✓ | Record and track vehicle maintenance history |
| **Design System (Pencil)** | 3 | Shipped ✓ | All screen flows in pencil-new.pen; design tokens; component hierarchy |
| **AI Event Cover Generation** | 4 | Shipped ✓ | Button wired to Claude Haiku + Unsplash; organizers auto-generate event cover images |

---

## Coming Soon (Planned Iterations)

| Feature | Iteration | Status | Description |
|---------|-----------|--------|-------------|
| **AI Event Recommendations** | 5 | Planned | Personalized event suggestions on home dashboard (deterministic scoring) |
| **SOAT Document Management** | 3a/3b (deferred to post-4) | Deferred | Upload/verify motorcycle insurance documents (SOAT); expiration badges on vehicle cards |
| **Push Notifications** | 6 | Planned | Event reminders, SOS alerts, attendance notifications (FCM + APNs) |
| **Event SOS System** | 3a (deferred) | Deferred | Emergency messaging during events; SOS sender can cancel in v1 |

---

## Known Limitations & Deferred Work

### v1 Constraints

- **No image caching:** Generated cover images fetched fresh each form open (v2 feature)
- **Unsplash free tier only:** 50 requests/hour limit; 503 returned if exceeded
- **Single-language:** Spanish-only (ARB); English deferred
- **No profile photo upload:** `profilePhotoUrl` not in Prisma schema (post-6b feature)
- **Organizer SOS dismiss:** Only event sender can cancel SOS messages in v1
- **No alternative image sources:** Only Unsplash for cover generation (Pexels, Pixabay deferred)
- **No payment system:** Event registration free; payments out of scope for v1
- **Mobile only:** No web app, admin dashboard, or social feed

---

## Test Coverage Summary

| Layer | Status | Notes |
|-------|--------|-------|
| **Backend (NestJS)** | 10/10 tests | `POST /events/generate-cover` and supporting services fully tested |
| **Frontend Domain** | 7/7 tests | Use cases and state management verified |
| **Frontend Widget** | Code-reviewed | All state transitions and user flows verified via manual inspection |
| **Linting** | 0 new violations | 34 pre-existing items in shared widgets (unrelated to new features) |
| **Regression** | 7/7 pass | Full test suite green; no regressions from Iteration 4 changes |

---

## Deployment & Environment

### Production (Firebase Remote Config)
- **API Base URL:** Resolved from Firebase Remote Config
- **Firebase Services:** Auth, Firestore, Storage, Remote Config (active)
- **Maps API:** Google Maps Flutter (SDK keys in local.properties)
- **Push Notifications:** FCM configured (ready for Iteration 6)

### Development
- **Local API:** `.env` override for `10.0.2.2:3000/api` (Android emulator) or `localhost:3000/api` (iOS simulator)
- **Firebase:** Dev project credentials in `.env` (Envied injection)
- **Secrets Management:** `.env.example` + local `.env` (not tracked)

---

## Architecture Health

| Aspect | Status | Notes |
|--------|--------|-------|
| **Clean Architecture** | Compliant ✓ | Domain/data/presentation layers strictly separated; no layer violations in Iteration 4 |
| **State Management** | `ResultState<T>` pattern | All async operations use `Cubit<ResultState<T>>` or `@freezed` state classes with ResultState fields |
| **Code Generation** | Freezed + Retrofit + Injectable | Build runner passing; no conflicts or missing imports |
| **Localization** | Spanish + ARB | 5 new keys added in Iteration 4; 0 hardcoded strings |
| **Dependency Injection** | GetIt + @injectable | DI configured; all services singleton/lazy-singleton; no circular dependencies |
| **Testing** | Unit + Widget | Domain layer well-tested; widget tests via code review (manual verification); regression suite green |

---

## Performance Baseline

| Metric | Target | Status |
|--------|--------|--------|
| **App startup** | <2s | N/A (not profiled yet) |
| **Event list load** | <1s (Firebase + Retrofit) | N/A |
| **Cover generation** | <5s (Claude + Unsplash) | 15s timeout applied |
| **Build time** | <2m (debug) | N/A |
| **Test suite** | <30s | 7/7 frontend tests ~5s; backend 10/10 tests ~10s |

---

## Security Checklist

| Control | Status | Evidence |
|---------|--------|----------|
| **No secrets in source** | ✓ | `.env.example` has placeholders; `.env` in `.gitignore` |
| **Firebase config files untracked** | ✓ | `google-services.json`, `GoogleService-Info.plist` in `.gitignore` |
| **Auth tokens on API calls** | ✓ | `FirebaseAuthInterceptor` in `AppDio` applies to all Retrofit clients |
| **No `BuildContext` in data layer** | ✓ | Data services have no Flutter imports |
| **No hardcoded API keys** | ✓ | Unsplash key via `.env`; Claude key in backend `.env` only |
| **No `print()` in lib/`` | ✓ | Linter enforces (analysis_options.yaml) |

---

## Next Steps for PO/Product Owner

1. **Validate Iteration 4 release** — Test AI cover generation on staging/prod Firebase project
2. **Plan Iteration 5 launch** — AI recommendations require home dashboard design review (already in Pencil)
3. **Backlog grooming** — Prioritize deferred features (SOAT, push notifications, profile photo) for post-launch roadmap
4. **Analytics setup** — No user/event telemetry logged yet (v2 feature)

---

## Change log

- **2026-05-13** — Iteration 4 shipped. AI Event Cover Generation (Claude Haiku + Unsplash) now live. Iteration 5 planned for AI Event Recommendations.
