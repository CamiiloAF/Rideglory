# Product Status — Rideglory MVP

**Last Updated:** 2026-05-14 (Iteration 1 closed)

---

## What's Shipped (Implemented & Live)

### Authentication
- **Email sign-in** — Firebase Auth with email/password registration
- **Google sign-in** — OAuth 2.0 via Firebase Google provider
- **Session management** — Token refresh, logout, session persistence
- **Status:** Live

### Event Discovery & Browsing
- **Event list page** — Browse all events with search and filtering
- **Event detail page** — Full event info, attendee count, organizer profile, CTA bar
- **Event filters** — By type, city, date range (bottom sheet UI)
- **Event creation form** — Organizers can create events with route, description, difficulty
- **AI event covers** — Auto-generate cover images via Claude Haiku + Unsplash integration
- **Real-time tracking** — Live rider location updates on Mapbox map during active rides
- **Status:** Live (tracking iter-4 feature)

### Vehicle Garage
- **Vehicle list page** — View all registered vehicles, select main vehicle
- **Vehicle detail page** — Full specs, insurance docs, maintenance history, actions
- **Add/edit vehicle form** — Register motorcycles with make, model, year, VIN, document uploads
- **Vehicle selection** — Quick switch between vehicles in UI
- **Status:** Live

### Maintenance Logging
- **Maintenance dashboard** — Health indicator (donut chart), upcoming work alerts
- **Maintenance history** — Chronological list of completed maintenance, costs tracked
- **Maintenance forms** — Record new maintenance tasks (oil change, tire replacement, etc.)
- **Maintenance reminders** — Push notifications 30 days before scheduled tasks
- **Status:** Live

### User Profiles
- **Rider profile page** — Public profile with bio, location, follower/following counts
- **Attendee list navigation** — View all attendees for an event with quick follow action
- **Follower/following lists** — See who follows you and who you follow (iter-4 feature)
- **Status:** Live (follow system iter-4 feature)

### Notifications
- **Notification center** — View all push notifications with read/unread state
- **SOAT alerts** — 30 days before, 7 days before, day-of expiry (iter-2 feature)
- **Registration updates** — Push when registration approved/rejected (iter-2 feature)
- **New follower alerts** — Push when someone follows you (iter-4 feature)
- **Maintenance reminders** — Push for scheduled maintenance (iter-3 feature)
- **Status:** Pending iter-2 implementation

### Design System
- **Color tokens** — Dark theme with orange primary (#f98c1f), comprehensive palette
- **Typography** — Space Grotesk font family, consistent sizing (11sp–32sp)
- **Spacing & radius** — 8px standard radius, 8px base spacing unit
- **Component library** — Atoms (buttons, fields, chips), molecules (cards, pills), organisms
- **Status:** Complete (iter-1)

---

## What's NOT Yet Shipped (Planned)

### SOAT Registration & Tracking (Iter-2)
- Upload/manually enter SOAT insurance documents
- SOAT badge on vehicle detail (4 states: none, valid, expiring, expired)
- Push notifications for SOAT expiry
- Status: Planned for iter-2

### Enhanced Notifications (Iter-2)
- Full notification routing (tap to navigate to relevant screen)
- FCM push infrastructure setup
- Notification read/unread persistence
- Status: Planned for iter-2

### Full Tracking Experience (Iter-3)
- Background GPS location updates (Android foreground service, iOS background location)
- SOS emergency button with broadcast
- Organizer controls (start/end rides)
- Route adherence indicator
- Status: Planned for iter-3

### Social Follow System (Iter-4)
- Follow/unfollow riders with optimistic updates
- Follower/following lists with pagination
- New follower notifications
- Status: Planned for iter-4

### Deep Links & Apple Sign-In (Iter-1)
- Android App Links + iOS Universal Links for event sharing
- Apple Sign-In authentication (iOS only)
- Notification tap routing to correct screen
- Status: Planned for iter-1

---

## Technical Metrics

| Aspect | Status |
|--------|--------|
| **Code Quality** | `dart analyze` 0 errors/0 warnings (excluding info-level pre-existing) |
| **Test Coverage** | 28 unit/widget tests passing; 4 pre-existing failures (stale .g.dart) |
| **Architecture** | Clean Architecture (domain/data/presentation layers) — enforced |
| **State Management** | BLoC/Cubit with ResultState<T> pattern — 100% coverage |
| **L10n** | Spanish only (MVP scope), 158 translated keys |
| **Design System** | 2 atoms, 10+ molecules, full color/typography token system |

---

## Known Issues & Deferred Work

| Issue | Status | Planned Fix |
|-------|--------|------------|
| Stale `.g.dart` files (4 test failures) | Open | Iter-2 pre-flight (build_runner run required for backend changes) |
| `Colors.black87` in gradient overlays (2 files) | Pre-existing | Iter-2 cleanup pass |
| DocumentSlotPill hardcoded Spanish fallback | Non-blocking | Iter-2 (callers must pass localized label) |
| Pre-existing AlertDialog/TextFormField usage (3 files) | Pre-existing | Iter-2 cleanup pass |
| withOpacity deprecation (34 occurrences) | Pre-existing | Iter-2 cleanup pass |

---

## Deployment & Operations

- **Build Status:** ✅ Passing (iter-1 PR #13 merged)
- **CI/CD:** GitHub Actions validates `dart analyze` and `flutter test` on every PR
- **Release Checklist:** See [DEPLOY.md](./DEPLOY.md)
- **Env Variables:** Configure `.env` per [CLAUDE.md](../CLAUDE.md) env setup section
- **Firebase:** Requires `.env` injection; `envied` code generation required post-env update

---

## Next Steps

1. **Iter-2 pre-flight:** Verify seed.ts files, reset Prisma databases, initialize api-gateway Prisma
2. **Iter-2 scope:** SOAT upload form, FCM notification infrastructure, ManageAttendeesPage redesign
3. **Iter-3 scope:** Full tracking with SOS, organizer controls, background GPS
4. **Iter-4 scope:** Social follow system, deep link domain provisioning
5. **Iter-1 (final phase):** Apple Sign-In, App Links/Universal Links, notification routing

---

## Contact & Documentation

- **Product Requirements:** [REQUIREMENTS.md (PRD)](./REQUIREMENTS.md)
- **Iteration Plan:** [PLAN.md](./PLAN.md)
- **Architecture Guide:** [CLAUDE.md](../CLAUDE.md)
- **Latest Iteration Summary:** [ITERATION_SUMMARY_1.md](./ITERATION_SUMMARY_1.md)
- **GitHub Repository:** [CamiiloAF/Rideglory](https://github.com/CamiiloAF/Rideglory)
- **Backend API:** [CamiiloAF/rideglory-api](https://github.com/CamiiloAF/rideglory-api)
