# CineConnect Other Portals Perfection Plan

Generated: 2026-07-24  
Target API: `https://cine.nalexustechnologies.com/api/v1`  
Target web domain: `https://cine.nalexustechnologies.com`

## 1. Purpose

This document is the step-by-step implementation plan for making every non-Director/Producer portal production-demo ready after the latest GitHub pull.

The goal is not only to make screens look good. The goal is:

1. Every portal screen should fetch visible data from the backend/database where possible.
2. Any missing backend API should be added locally, tested, migrated, and deployed.
3. No portal screen should display static/demo Dart data as user-visible content.
4. Demo-only Dart stores should be removed from portal runtime flows or converted to tests/seed references only.
5. Demo data should live in MySQL and storage, not in Flutter constants.
6. Each portal should have a clean loading, empty, error, and success state.
7. The server and GitHub should stay synchronized after each completed phase.

## 2. Current state after latest GitHub pull

The latest pull added major new local work:

- New backend module: `backend/app/api/admin_control.py`
- Expanded backend modules:
  - `backend/app/api/analytics.py`
  - `backend/app/api/marketplace.py`
  - `backend/app/api/operations.py`
  - `backend/app/api/specialist.py`
- New migration:
  - `backend/migrations/versions/c4d5e6f7a8b9_brand_application_conversations.py`
- New Flutter core API clients/controllers:
  - `lib/core/admin/*`
  - expanded `operations`, `specialist`, `bookings`, `trust_safety`, `payments`, `auth`
- New/expanded live portal helper widgets:
  - `lib/features/brand_sponsors/widgets/brand_sponsor_live.dart`
  - `lib/features/location_owner/widgets/location_owner_live.dart`
  - `lib/features/media_equipment/widgets/equipment_inspection_workspace.dart`
- Large UI updates across Actor/Talent, Brand, Location Owner, Media/Equipment, Model, and Super Admin.

Important: these changes are local after pull. They still need verification, migration/deployment, and screen-by-screen live walkthrough before we can call them production-demo ready.

## 3. Backend endpoint coverage map

### Already available locally

These endpoint groups exist locally and should be reused before creating new APIs:

| Area | Main endpoints |
| --- | --- |
| Auth/roles | `/auth/*`, `/me`, `/me/roles`, `/me/primary-role`, `/roles`, `/app/bootstrap` |
| Analytics | `/me/dashboard`, `/admin/dashboard`, `/admin/analytics`, `/exports` |
| Marketplace | `/me/profile`, `/talent/profile`, `/portfolio`, `/marketplace/listings`, `/shortlists`, `/saved-searches` |
| Projects | `/projects`, `/projects/{id}/room`, `/projects/{id}/members`, `/projects/{id}/files`, `/projects/{id}/requirements` |
| Bookings/negotiations | `/availability`, `/bookings`, `/talent/opportunities`, `/negotiations`, `/offers/{id}/accept`, messages |
| Contracts/legal | `/contract-templates`, `/contracts`, `/legal-reviews`, legal decisions |
| Payments | `/payments/dashboard`, `/payment-schedules`, `/payment-proofs`, `/ledger`, `/payout-accounts`, admin payment proof review |
| Verification | uploads, KYC submissions, admin KYC decisions |
| Trust/safety | reviews, review requests, reports, blocked users, disputes, support tickets, announcements, notifications, push devices |
| Operations | location properties/spaces/pricing/rules/inspections/damage claims; equipment profile/items/packages/terms/inspections; safety checks/incidents |
| Insurance | insurance profile, policies, claims, evidence, decisions, dashboard |
| Specialist | agency profile/invitations/auditions/tapes/commissions; brand profile/opportunities/applications/conversations/terms/deliverables/metrics; model profile/rights/rates/restrictions; distribution profile/projects/contacts/reports |
| Super Admin control | bookings, users, listings, contract templates, fee rules, roles/permissions, audit events |

### Likely missing or incomplete APIs

These are the areas most likely to need new backend work:

| Portal | Missing/incomplete area |
| --- | --- |
| Actor/Talent | Profile-builder full save parity, rate-card CRUD beyond current profile/listing records, portfolio showreel media polish, review dashboard rollups, safety control linkage to reports/blocks |
| Crew Services | Dedicated crew service profile, credits, requests dashboard, contracts/payments filtered by crew role, ratings history |
| Casting Agency | Agency roster CRUD, self-tape upload/list workflows, candidate shortlist actions, commission booking records beyond current specialist primitives |
| Legal Partner | Template review queue may be partially admin/contract-template based; billing/history may still be local demo data |
| Insurance Partner | Policies/claims exist; safety permits/incidents may need consistent joins to operations incidents/safety checks |
| Distribution Partner | Distribution projects/contacts/reports exist; release-window and handover UI actions need full read-back and dashboard aggregation |
| Brand Sponsor | Opportunity/application/deliverable APIs exist; payments, campaign metrics aggregation, negotiation timeline, and application conversation UI need full walkthrough |
| Location Owner | Many operations APIs exist; earnings/deposits rely on payments/ledger linkage and property performance aggregation may need backend rollups |
| Media/Equipment | Items/packages/terms/inspections exist; booking requests and earnings/rating rollups may need filtered bookings/payments/reviews |
| Super Admin | Many admin control APIs exist; all admin screens must be audited for actual live controller use instead of mock data |

## 4. Non-negotiable implementation rules

1. Do not replace live API screens with local demo constants.
2. If a screen needs demo data, seed it into the production MySQL database and fetch through the server API.
3. No static portal demo data may be visible in the running app. Files such as `*DemoData` and `*DemoStore` can remain only as migration references, tests, or seed-script inputs until removed.
4. If a backend endpoint is missing, add the endpoint instead of falling back to static Flutter data.
5. If seeded/demo content is required for walkthroughs, create it in the database/storage first, then fetch it through APIs.
6. Empty database results must show proper empty states, not static fallback lists.
7. Image placeholders are allowed only as neutral UI fallback for failed/missing images; real portal media should come from backend file/storage URLs.
8. Any backend schema change must include:
   - migration
   - model update
   - endpoint update
   - tests
   - server migration/deploy
9. Any frontend wiring change must include:
   - models/repository/controller update
   - screen loading/empty/error state
   - friendly validation errors
   - `flutter analyze`
   - relevant widget/portal tests
10. After every deployable phase:
   - deploy backend if backend changed
   - deploy Flutter web if frontend changed
   - run live smoke checks against `https://cine.nalexustechnologies.com/api/v1`
   - push to GitHub

## 5. Master implementation phases

### Phase P0 — Stabilize local baseline before changes

Goal: confirm the latest GitHub pull builds locally before implementing new work.

Steps:

1. Run `git status --short`.
2. Run backend static/unit checks:
   - `cd backend && python -m compileall app tests`
   - backend unit tests that do not require MySQL/Redis
3. Run Flutter checks:
   - `flutter analyze`
   - `flutter test`
4. Identify any failures introduced by latest pull.
5. Fix only blocking compile/analyze/test failures before portal implementation.
6. Update `docs/IMPLEMENTATION_PROGRESS.md` with baseline results.

Acceptance:

- Local repo is clean or only contains documented plan/check updates.
- Flutter analyze passes.
- Backend imports compile.
- Known skipped integration tests are documented, not silently ignored.

### Phase P1 — API inventory and screen classification

Goal: create a precise matrix of every portal screen and whether it is live, partial-live, or demo-only.

Steps:

1. For each feature under `lib/features/*`, inspect:
   - screen files
   - route file
   - shell file
   - demo data file
   - related `lib/core/*` controller/repository
2. Mark each screen:
   - `LIVE`: primary data comes from API.
   - `PARTIAL`: some cards/actions use API but lists/metrics still use demo store. This is temporary and must be eliminated before completion.
   - `DEMO`: primary data comes from `*DemoData` or `*DemoStore`. This is not acceptable for production-demo completion.
   - `BROKEN`: API intended but missing endpoint/model/action.
3. Compare with backend route list.
4. Search all portal code for static demo sources:
   - `*DemoData`
   - `*DemoStore`
   - `admin_mock_data.dart`
   - hardcoded sample cards/lists/metrics
   - local-only status maps that represent database state
5. For each static dependency, decide one of:
   - replace with existing backend API
   - add missing backend API
   - convert into seed-script source only
   - convert into test fixture only
   - delete
6. Add a new table to `docs/IMPLEMENTATION_PROGRESS.md` or a separate audit file:
   - `docs/CINECONNECT_PORTAL_API_AUDIT.md`

Acceptance:

- Every screen has a status.
- Every demo-store dependency is listed.
- Every missing endpoint is named before implementation starts.
- Every static user-visible data source has a removal/replacement decision.

### Phase P1.5 — Static demo data removal framework

Goal: prevent static data from silently reappearing while we wire portals.

Steps:

1. Add a repo-wide audit command to the implementation checklist:
   - `rg -n "DemoData|DemoStore|admin_mock_data|mock|sample|static demo" lib/features lib/core`
2. Classify matches:
   - allowed in tests
   - allowed in seed scripts/docs
   - not allowed in runtime portal screens/widgets
3. For runtime portal matches, replace with:
   - API-backed controller data
   - loading state
   - empty state
   - error/retry state
4. Add widget tests or smoke tests that verify key portal screens can render with:
   - non-empty API-shaped data
   - empty API-shaped data
   - API error
5. Keep neutral image/icon fallbacks only for failed media loading, not for business records.

Acceptance:

- No runtime portal screen uses `*DemoData`, `*DemoStore`, or mock lists as visible business content.
- Static demo files are either deleted or moved to documented seed/test-only usage.
- If the database is empty, the UI shows empty states rather than fake records.

### Phase P2 — Deploy latest pulled backend safely

Goal: if the pulled backend changes are not yet live, deploy them before frontend relies on them.

Steps:

1. Confirm server currently running image/version.
2. Copy backend to server excluding `.env`, caches.
3. Build Docker image on server.
4. Run Alembic migrations, especially:
   - `c4d5e6f7a8b9_brand_application_conversations.py`
5. Restart:
   - API
   - worker
   - scheduler
6. Smoke:
   - `/health/live`
   - `/health/ready`
   - `/app/bootstrap`
   - `/openapi.yaml`
   - one authenticated endpoint from each major controller group.

Acceptance:

- Server runs latest backend code.
- DB migration head is current.
- No new 500 errors in smoke checks.

### Phase P3 — Super Admin portal perfection

Why first: Super Admin is the control room. It reveals whether other portals are producing real bookings, KYC, payments, listings, disputes, support tickets, broadcasts, audit logs, and analytics.

Screens:

- Admin Dashboard
- Review Hub
- Verifications
- Content Moderation
- Bookings Monitor
- Payments Hub
- Payment Queue
- Receipts Ledger
- Dispute Center
- Support CRM
- Broadcast Announcements
- Analytics
- Users
- Listings Moderation
- Contract Template Manager
- Commission/Fee Rules
- Roles/Permissions
- Audit Logs

Backend to verify/reuse:

- `/admin/dashboard`
- `/admin/analytics`
- `/admin/control/bookings`
- `/admin/control/users`
- `/admin/control/listings`
- `/admin/control/contract-templates`
- `/admin/control/fee-rules`
- `/admin/control/roles`
- `/admin/control/audit-events`
- `/admin/kyc/submissions`
- `/admin/payment-proofs`
- `/admin/moderation-cases`
- `/admin/disputes`
- `/admin/support-tickets`
- `/admin/announcements`

Implementation steps:

1. Ensure every admin screen reads from `AdminScope`, `AnalyticsScope`, `VerificationScope`, `PaymentsScope`, or `TrustSafetyScope`.
2. Remove or demote `admin_mock_data.dart` from primary rendering.
3. Add missing repository methods for any backend endpoint already present but not exposed to UI.
4. Make all admin decisions actually PATCH/POST to the backend:
   - approve/reject KYC
   - approve/reject listing
   - payment proof decision
   - moderation decision
   - dispute decision
   - support status update
   - publish announcement
   - edit fee rule
   - edit role permissions
5. Add empty states for each queue.
6. Add audit-event visibility for admin actions.
7. Seed enough pending/approved/rejected records so every queue shows meaningful rows.

Acceptance:

- One super admin login can walk every admin screen without seeing static-only fake cards.
- Each admin queue has at least 3 realistic states: pending, approved/resolved, rejected/escalated.
- At least one admin action changes backend data and survives refresh.

### Phase P4 — Brand Sponsor portal perfection

Screens:

- BR-01 Dashboard
- BR-02 Brand Profile
- BR-03 Opportunity Composer
- BR-04 Applications Inbox
- BR-05 Negotiation Terms
- BR-06 Campaign Tracker
- BR-07 Payments Records

Backend to verify/reuse:

- `/brands/profile`
- `/brand-opportunities`
- `/brand-opportunities/{id}/applications`
- `/brand-applications`
- `/brand-applications/{id}`
- `/brand-applications/{id}/conversation`
- `/brand-applications/{id}/terms`
- `/campaign-deliverables`
- `/campaign-deliverables/{id}/proof`
- `/campaign-deliverables/{id}/approve`
- `/campaign-metrics`
- `/payments/dashboard`
- `/ledger`
- `/payment-schedules`

Implementation steps:

1. Make dashboard metrics derive from live brand opportunities, applications, deliverables, metrics, and payments.
2. Wire profile save to `/brands/profile`.
3. Wire opportunity create/edit to `/brand-opportunities`.
4. Ensure opportunity composer validates:
   - title
   - brand/category
   - budget range
   - deliverables
   - rights/usage dates
5. Wire applications inbox to `/brand-applications`.
6. Wire application decision and negotiation notes to application PATCH/conversation/terms endpoints.
7. Wire campaign tracker to campaign deliverables and campaign metrics.
8. Wire payments records to payment schedules/ledger filtered by brand.
9. Replace primary `BrandSponsorDemoData` lists with database records.
10. Seed Pakistan-relevant brands, campaigns, creators/models, deliverables, and proof files.

Acceptance:

- Brand can create an opportunity.
- Applications appear from database.
- Brand can shortlist/accept/reject/negotiate an application.
- Campaign deliverable status changes survive refresh.
- Payment records are fetched from backend, even if payment rails are still dummy/sandbox.

### Phase P5 — Actor/Talent portal perfection

Screens:

- AT-01 Dashboard
- AT-02 Profile Builder
- AT-03 Portfolio Showreel
- AT-04 Availability Calendar
- AT-05 Rate Card
- AT-06 Opportunity Inbox
- AT-07 Offer Detail
- AT-08 Counteroffer Composer
- AT-09 Contract Signing
- AT-10 Earnings/Security
- AT-11 Reputation/Reviews
- AT-12 Safety Controls

Backend to verify/reuse:

- `/talent/profile`
- `/me/profile`
- `/portfolio`
- `/availability`
- `/talent/opportunities`
- `/bookings`
- `/negotiations`
- `/bookings/{id}/offers`
- `/offers/{id}/accept`
- `/bookings/{id}/reject`
- `/contracts`
- `/contracts/{id}/signatures`
- `/payments/dashboard`
- `/ledger`
- `/payout-accounts`
- `/reviews`
- `/users/{id}/reviews`
- `/reports`
- `/blocked-users`

Implementation steps:

1. Wire profile builder to profile/talent profile endpoints.
2. Wire portfolio showreel to `/portfolio` with upload/download files.
3. Wire availability calendar to `/availability`.
4. Replace local rate cards with either:
   - marketplace listing rates, or
   - new talent rate-card API if current schema is insufficient.
5. Wire opportunity inbox to `/talent/opportunities`.
6. Wire offer detail/counteroffer to bookings/negotiations endpoints.
7. Wire contract signing to `/contracts/{id}/signatures`.
8. Wire earnings to payments dashboard/ledger/payout accounts.
9. Wire reviews to trust-safety review endpoints.
10. Wire safety controls to reports and blocked users.
11. Seed at least 10 actors/talent with portfolio images/showreel metadata from backend files.

Acceptance:

- Actor can update profile/portfolio/availability and refresh without losing data.
- Actor can view live opportunities, counteroffer, accept/reject.
- Contract signing creates a backend signature record.
- Earnings/reviews/safety screens are not static-only.

### Phase P6 — Model Extension portal perfection

Screens:

- MD-01 Campaign Categories
- MD-02 Usage Rights
- MD-03 Portfolio Categories
- MD-04 Rate by Usage
- MD-05 Brand Safety

Backend to verify/reuse:

- `/model/profile`
- `/model/campaign-categories`
- `/model/usage-rights`
- `/model/usage-rates`
- `/model/restricted-categories`
- `/portfolio`
- `/marketplace/listings`
- `/brand-applications`

Implementation steps:

1. Ensure model profile is separate from actor/talent display but can share user identity.
2. Wire campaign categories to `/model/campaign-categories`.
3. Wire usage rights CRUD to `/model/usage-rights`.
4. Wire portfolio categories either to `/portfolio` metadata or add missing model portfolio categorization API.
5. Wire rate-by-usage to `/model/usage-rates`.
6. Wire brand safety restrictions to `/model/restricted-categories`.
7. Ensure Director marketplace model tab uses model-specific discovery DTOs, not actor/talent feed.
8. Seed Pakistani fashion/commercial model profiles and brand-relevant images.

Acceptance:

- Model portal no longer depends primarily on `ModelExtensionDemoStore`.
- Model rates/restrictions update backend and survive refresh.
- Director marketplace can see model-specific cards and open correct detail profile.

### Phase P7 — Location Owner portal perfection

Screens:

- LO-01 Owner Dashboard
- LO-02 Location Listing Wizard
- LO-03 Availability Calendar
- LO-04 Pricing & Deposit
- LO-05 Rules & Restrictions
- LO-06 Booking Requests
- LO-07 Check-in Inspection
- LO-08 Check-out Damage Claim
- LO-09 Earnings & Deposits
- LO-10 Property Performance

Backend to verify/reuse:

- `/location-properties`
- `/location-properties/{id}/spaces`
- `/location-properties/{id}/pricing`
- `/location-properties/{id}/rules`
- `/availability`
- `/bookings`
- `/location-inspections`
- `/location-inspections/{id}/items`
- `/location-inspections/{id}/confirm`
- `/damage-claims`
- `/damage-claims/{id}/evidence`
- `/payments/dashboard`
- `/ledger`
- `/payout-accounts`
- `/director/discovery?kind=locations`

Implementation steps:

1. Make property picker fully live.
2. Wire listing wizard create/update to location property, spaces, files, and marketplace listing.
3. Wire availability calendar to real availability endpoint with location provider context.
4. Wire pricing/deposit to location pricing endpoint.
5. Wire rules/restrictions to location rules endpoint.
6. Wire booking requests to bookings filtered for location owner.
7. Wire check-in/check-out inspection to inspection endpoints.
8. Wire damage claim to damage-claims/evidence endpoints.
9. Wire earnings/deposits to payments and payout accounts.
10. Add property performance backend rollup if analytics does not already provide it.
11. Seed 10 Pakistan-relevant shoot locations with images stored/served by backend.

Acceptance:

- Location owner can create a listing and it appears in Director discovery.
- Pricing/rules/availability survive refresh.
- Inspection and damage claim workflows create backend records.
- Earnings/performance screens show database data.

### Phase P8 — Media/Equipment Provider portal perfection

Screens:

- ME-01 Provider Dashboard
- ME-02 Provider Profile
- ME-03 Inventory Manager
- ME-04 Package Builder
- ME-05 Availability Calendar
- ME-06 Rate Terms
- ME-07 Booking Requests
- ME-08 Handover Checklist
- ME-09 Return Checklist
- ME-10 Earnings & Ratings

Backend to verify/reuse:

- `/equipment/provider-profile`
- `/equipment/items`
- `/equipment/packages`
- `/equipment/packages/{id}/items`
- `/equipment/terms`
- `/availability`
- `/bookings`
- `/equipment-inspections`
- `/equipment-inspections/{id}/items`
- `/equipment-inspections/{id}/confirm`
- `/payments/dashboard`
- `/ledger`
- `/reviews`
- `/director/discovery?kind=equipment`

Implementation steps:

1. Wire provider profile save to equipment provider profile.
2. Wire inventory CRUD to equipment items.
3. Wire package builder to equipment packages/package items.
4. Wire availability to availability endpoint.
5. Wire terms/rates to equipment terms.
6. Wire booking requests to bookings filtered for equipment provider.
7. Wire handover/return checklists to equipment inspections.
8. Wire earnings/ratings to payments and reviews.
9. Seed 10 Pakistan-relevant equipment providers/packages with images.
10. Ensure equipment appears in Director marketplace equipment tab and can be shortlisted/booked.

Acceptance:

- Equipment provider can edit profile/inventory/packages/terms.
- Handover and return checklist state persists.
- Director can discover and shortlist/book equipment listing.

### Phase P9 — Crew Services portal perfection

Screens:

- CR-01 Dashboard
- CR-02 Service Profile
- CR-03 Portfolio/Credits
- CR-04 Availability Calendar
- CR-05 Requests & Negotiation
- CR-06 Contracts & Payments
- CR-07 Ratings & Work History

Backend gap likely:

There is no clearly separate crew-service API module yet. Crew can probably reuse marketplace listings, portfolio, availability, bookings, contracts, payments, and reviews, but a crew-specific profile/rate/credit shape may be missing.

Implementation steps:

1. Decide whether crew service profile is:
   - a dedicated specialist table/API, or
   - marketplace listing + profile metadata.
2. If missing, add backend schema/API for:
   - crew service profile
   - service categories
   - credits
   - crew-specific rate cards
3. Wire service profile to backend.
4. Wire portfolio/credits to backend.
5. Wire availability to `/availability`.
6. Wire requests/negotiation to bookings/negotiations.
7. Wire contracts/payments to contracts/payments.
8. Wire ratings/work history to reviews and completed bookings.
9. Seed 10 Pakistan-relevant crew providers:
   - DOP
   - assistant director
   - gaffer
   - sound recordist
   - art director
   - makeup artist
   - line producer
   - editor
   - colorist
   - drone operator

Acceptance:

- Crew portal is no longer static demo-only.
- Crew listing appears in Director discovery/marketplace.
- Crew can receive booking requests and respond.

### Phase P10 — Casting Agency portal perfection

Screens:

- CA-01 Agency Dashboard
- CA-02 Talent Roster
- CA-03 Audition Request Inbox
- CA-04 Candidate Shortlist
- CA-05 Self-tape Collection
- CA-06 Selection Notes
- CA-07 Commission Records
- CA-08 Agency Booking Records

Backend to verify/reuse:

- `/agencies/profile`
- `/agency-invitations`
- `/agency-invitations/{id}/accept`
- `/agencies/{id}/talent`
- `/auditions`
- `/auditions/{id}`
- `/auditions/{id}/candidates`
- `/audition-candidates/{id}`
- `/self-tapes`
- `/audition-candidates/{id}/notes`
- `/agency-commissions`
- `/agencies/{id}/commissions`
- `/bookings`
- `/payments/dashboard`
- `/ledger`

Implementation steps:

1. Wire agency profile/dashboard to agency APIs.
2. Wire roster to agency talent/invitations.
3. Wire audition inbox to auditions endpoint.
4. Wire candidate shortlist to audition candidates.
5. Wire self-tape collection to self-tape endpoint plus backend file uploads.
6. Wire selection notes to candidate notes endpoint.
7. Wire commission records to agency commissions.
8. Wire booking records to bookings filtered by agency.
9. Seed 10 agencies, rosters, auditions, self-tapes, commission rows.
10. Ensure Director agency discovery/detail can open and shortlist agency profiles.

Acceptance:

- Agency can manage roster and audition candidates from backend.
- Self-tape statuses survive refresh.
- Commission and booking records are database-backed.

### Phase P11 — Legal Partner portal perfection

Screens:

- LG-01 Legal Dashboard
- LG-02 Contract Review Detail
- LG-03 Template Review
- LG-04 Addendum Review
- LG-05 Review History & Billing

Backend to verify/reuse:

- `/contracts`
- `/contracts/{id}`
- `/legal-reviews`
- `/legal-reviews/{id}`
- `/legal-reviews/{id}/decision`
- `/contract-templates`
- `/admin/control/contract-templates`
- `/ledger`
- `/payment-schedules`

Implementation steps:

1. Wire dashboard to legal reviews and contract queues.
2. Wire contract review detail to legal review detail/decision.
3. Decide template-review ownership:
   - legal partner reviews templates, or
   - super admin controls templates.
4. If legal partner must review templates, add legal template review endpoint or extend contract templates with review statuses.
5. Wire addendum review to contracts/addendums/legal review flow.
6. Wire billing/history to completed legal reviews and ledger/payment schedules.
7. Seed 10 legal review cases and 5 template/addendum cases.

Acceptance:

- Legal partner can approve/request changes on a contract review.
- Review history is backend-backed.
- Billing rows are derived from real legal review/payment records.

### Phase P12 — Insurance Partner portal perfection

Screens:

- IN-01 Insurance Dashboard
- IN-02 Shoot Insurance Records
- IN-03 Claim Support
- IN-04 Safety Checks & Permits
- IN-05 Incident Reports

Backend to verify/reuse:

- `/insurance/profile`
- `/insurance/dashboard`
- `/insurance/policies`
- `/insurance/claims`
- `/insurance/claims/{id}/evidence`
- `/insurance/claims/{id}/decision`
- `/safety-checks`
- `/safety-checks/{id}/items`
- `/incidents`
- `/safety-check-ins`

Implementation steps:

1. Wire profile/dashboard to insurance APIs.
2. Wire policy list/detail/create to insurance policies.
3. Wire claim support to claims/evidence/decision.
4. Wire safety checks/permits to operations safety checks.
5. Wire incident reports to operations incidents.
6. Make insurance dashboard aggregate policies, open claims, incidents, and safety check status.
7. Seed 10 policies, 10 claims, 10 safety checks/permits, 10 incidents.

Acceptance:

- Insurance partner can view policies/claims/safety/incidents from backend.
- Claim evidence upload is linked to backend storage.
- Claim decision persists and appears in admin/safety views where applicable.

### Phase P13 — Distribution Partner portal perfection

Screens:

- DS-01 Distribution Dashboard
- DS-02 Distributor Contacts
- DS-03 Release Coordination
- DS-04 Performance Reporting

Backend to verify/reuse:

- `/distribution/profile`
- `/distribution-projects`
- `/distribution-projects/{id}`
- `/distribution-projects/{id}/release-windows`
- `/distribution-projects/{id}/handover-items`
- `/release-handover-items/{id}`
- `/distributor-contacts`
- `/distribution-reports`

Implementation steps:

1. Wire dashboard to distribution profile/projects/reports.
2. Wire distributor contacts CRUD to `/distributor-contacts`.
3. Wire release coordination to distribution projects, release windows, and handover items.
4. Wire performance reporting to distribution reports.
5. Add missing dashboard aggregation endpoint if current data requires too many calls.
6. Seed 10 distribution projects, 20 contacts, release windows, handover items, and reports.

Acceptance:

- Distribution partner can update contacts and release coordination.
- Handover item state survives refresh.
- Reports are backend-backed and visible in dashboard.

### Phase P14 — Cross-portal marketplace linkage

Goal: every provider portal creates/updates listings discoverable and bookable by Director/Producer.

Provider listing types:

- Actor/Talent
- Model
- Location
- Media/Equipment
- Crew
- Casting Agency
- Distribution Partner

Steps:

1. For every provider profile, define its marketplace listing linkage:
   - one profile row maps to one or more `marketplace_listings`
   - listing owns discoverability, rate range, city, media, status
2. Ensure Director discovery returns provider-specific DTOs for:
   - actors
   - models
   - locations
   - equipment
   - agencies
   - distribution
   - crew
3. Ensure each discovery card has:
   - `profile_id`
   - `marketplace_listing_id`
   - provider type
   - primary image
   - city
   - rate/budget summary
   - verified/status badges
4. Ensure shortlist items can save any provider listing type.
5. Ensure booking request can be created from all supported listing types.
6. Add tests for listing linkage after provider updates.

Acceptance:

- Director can discover, open, shortlist, and start booking for every provider type.
- Provider profile changes update visible marketplace data.

### Phase P15 — Demo data perfection and media assets

Goal: remove “empty app” feeling by loading rich, Pakistan-relevant demo records from backend/database.

Steps:

1. Use `docs/CINECONNECT_DEMO_DATA_SEED_BLUEPRINT.md` as the backbone.
2. Keep one coherent set of 10 productions across all portals.
3. Seed every role owner and related rows.
4. Store media through backend file/storage tables, not Flutter constants.
5. For images:
   - prefer licensed/open images or synthetic placeholders
   - store downloaded/generated media in backend storage
   - record source in docs when external media is used
6. Generate/update login handoff document after seeding.
7. Run count checks per portal.

Acceptance:

- Every portal dashboard has non-empty metrics.
- Every list screen has at least 10 records or a meaningful smaller set where business logic requires it.
- Images load from backend URLs.
- Demo data is visible after hard refresh and across browsers.
- Removing local Flutter demo constants does not reduce visible demo richness because all walkthrough data comes from MySQL/storage.

### Phase P16 — Full deployment and manual walkthrough

Steps:

1. Backend deploy if any backend changed:
   - sync backend
   - build Docker image
   - run migrations
   - restart API/worker/scheduler
2. Frontend deploy if Flutter changed:
   - build web with `CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1`
   - sync `build/web` to `/var/www/cineconnect/web`
3. Smoke:
   - health
   - bootstrap
   - login
   - dashboard endpoint for each role
4. Browser walkthrough:
   - login as one account per portal
   - capture screenshots
   - record pass/fail per screen
5. Update:
   - `docs/IMPLEMENTATION_PROGRESS.md`
   - handoff report if needed
6. Push to GitHub.

Acceptance:

- Production domain serves latest frontend.
- Production API serves latest backend.
- Every portal can be manually opened and clicked through without blank/crashing screens.

## 6. Recommended implementation order

This order minimizes risk because each phase builds on shared backend foundations.

1. P0 — Stabilize local baseline.
2. P1 — Screen/API audit.
3. P2 — Deploy latest pulled backend.
4. P3 — Super Admin.
5. P4 — Brand Sponsor.
6. P7 — Location Owner.
7. P8 — Media/Equipment.
8. P5 — Actor/Talent.
9. P6 — Model Extension.
10. P10 — Casting Agency.
11. P9 — Crew Services.
12. P11 — Legal Partner.
13. P12 — Insurance Partner.
14. P13 — Distribution Partner.
15. P14 — Cross-portal marketplace linkage.
16. P15 — Demo data/media perfection.
17. P16 — Full production walkthrough.

Reasoning:

- Super Admin first gives visibility into all backend data and admin queues.
- Brand/Location/Equipment have the strongest newly added local APIs and can become live fastest.
- Actor/Model should be done after marketplace/provider linkage is confirmed.
- Crew likely needs the most new backend design, so it should not block easier portal wins.
- Legal/Insurance/Distribution depend on contracts, operations, payments, and seeded production workflows.

## 7. Screen status expectations before implementation

Initial expectation based on code inspection:

| Portal | Expected status today | Main work |
| --- | --- | --- |
| Director/Producer | Mostly live; needs continued bug fixes only | Keep stable while other portals connect |
| Super Admin | Newly upgraded, likely partial live | Validate all admin screens and remove mock primacy |
| Brand Sponsor | Partial live | Complete opportunity/application/deliverable/payment wiring |
| Actor/Talent | Partial live | Replace dashboard/rates/reviews/safety demo primacy |
| Model Extension | Partial live | Finish model-specific profile/rates/restrictions/portfolio linkage |
| Location Owner | Partial live | Finish property/booking/inspection/earnings/performance wiring |
| Media/Equipment | Partial live | Finish inventory/package/inspection/booking/earnings wiring |
| Crew Services | Mostly demo/partial shared APIs | Add/decide crew-specific backend shape |
| Casting Agency | Mostly demo/partial specialist APIs | Wire agency/audition/self-tape/commission flows |
| Legal Partner | Partial contracts APIs | Finish template/addendum/billing live flows |
| Insurance Partner | Partial insurance APIs | Finish safety/incident joins and dashboard rollups |
| Distribution Partner | Partial specialist APIs | Finish release/contact/report live flows |

## 8. Testing checklist for every portal phase

For each portal, run:

1. `flutter analyze`
2. Relevant portal tests, for example:
   - `flutter test test/brand_sponsor_portal_test.dart`
   - `flutter test test/location_owner_portal_test.dart`
   - `flutter test test/media_equipment_portal_test.dart`
   - `flutter test test/actor_talent_portal_test.dart`
   - `flutter test test/model_extension_portal_test.dart`
   - `flutter test test/super_admin_portal_test.dart`
3. Backend compile/tests for changed APIs:
   - `cd backend && python -m compileall app tests`
   - targeted unit/integration tests where environment allows
4. Live API smoke after deployment.
5. Manual browser walkthrough on `https://cine.nalexustechnologies.com`.

## 9. Definition of “perfect enough for demo”

A portal is complete only when:

- All visible rows/cards come from backend or documented backend-seeded demo data.
- No visible portal content comes directly from `*DemoData`, `*DemoStore`, `admin_mock_data.dart`, hardcoded sample arrays, or local static lists.
- Key create/update actions persist after refresh.
- Empty states are helpful.
- Error states tell the user what to fix.
- Loading states do not look broken.
- Images load from backend/storage URLs.
- Navigation/back behavior works.
- The portal works on desktop Chrome/Safari and mobile-sized web viewport.
- The portal has at least one demo login with enough data for a walkthrough.
- Production server is updated.
- GitHub is updated.

## 10. Immediate next step

Start with Phase P0 and P1:

1. Run local checks against the freshly pulled code.
2. Generate `docs/CINECONNECT_PORTAL_API_AUDIT.md`.
3. Decide from the audit whether the first implementation phase should be:
   - Super Admin live completion, or
   - deploy latest pulled backend first if local APIs are not on server yet.

After that, implement portal phases one by one and update this plan after every completed phase.
