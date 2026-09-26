# CineConnect Unified Portal UX implementation log

Date: 2026-09-26  
Specification: `CineConnect_Unified_Portal_UX_UI_Improvement_Specification.docx`  
Release: `20260926-floating-bubbles-v18`
Production domain: `https://cine.nalexustechnologies.com`

This file treats the attached document as the product specification. The user's
messages authorise implementation, backend connection, testing, deployment, and
Git publication. Repeated interaction patterns were changed in shared components
or across every portal where the pattern exists.

## Requirement and implementation record

| Specification requirement | Implemented result | Scope and data source | Status |
|---|---|---|---|
| Remove persistent Demo controls | Removed header Demo launchers and the login Demo account/role picker. Removed the fake OTP portal bypass. Kept Play only for a real project/media story. | Shared header plus Director, Brand, Talent, specialist, partner, public, and Admin shells | Complete |
| About and Logout in portal headers | Added one shared About action with product, account, help, privacy, release, and optional guided tour content. Added or retained Logout beside it. | All portal header implementations | Complete |
| Theme synchronisation | Header, marketplace, dialogs, rails, cards, and skeletons resolve colours from the active app theme. | Shared theme extensions and portal shells | Complete |
| Animated filter system | Added a reusable moving gold selection rail with automatic scroll into view, focus/selected semantics, 44 px targets, press feedback, and reduced motion support. Replaced status/category/range rails across Director, Brand, Actor, Admin, Insurance, Distribution, Location, Equipment, Crew, Casting, and public cinema. | `CineAnimatedFilterRail`; remaining form option chips inherit shared animated chip behaviour | Complete |
| List/Grid mode | Added shared List/Grid controls, responsive 1–4 column results, and device persistence per Director, public/shared, and Brand portal scope. Both modes use the same live result set. | Secure local preference plus live discovery APIs | Complete |
| Category grouping | All-category marketplace results are grouped into Actors, Models, Influencers, Crew, Locations, Equipment, Agencies, and Distribution with counts and View all actions. | Director/shared/public and Brand marketplace | Complete |
| Loading, empty, and error states | Added card-shaped skeletons to content-heavy Director and Brand discovery, projects, profiles, booking, shortlist, bargaining, payments, project room, CinePlanner, and Equipment availability. Kept recoverable inline Retry/Clear actions. Removed production copy that described preview or fake records. | Shared skeleton/card system and live screen states | Complete |
| Project cover required | Director wizard requires an uploaded cover beside the field. Brand creation can upload a cover and requires it before publication. App project writes request server validation; backend rejects non-draft project publication when the required-cover contract is used. Draft planning workspaces remain private and editable. | Upload API, project repository, projects API | Complete |
| Director Console feed | Removed decorative fire content. Added live production news from project-room events, bookings, contracts, and payments with deep links. Renamed Today's pipeline to Planner snapshot and replaced generic module labels with production goals. | Director dashboard API and live dashboard widgets | Complete |
| Backend calendar/planner | Director and Brand schedules include database CinePlanner events. Add Plan creates/reuses a production and shoot day, writes the schedule event and audit record, then reloads date markers/agenda. | MySQL models through `/director/schedule` and `/brands/schedule` | Complete |
| CinePlanner production surface | Preserved the connected project planning workspace, project context, scenes, tasks, scheduling, call sheets, casting, budget, files, and responsive desktop/mobile layouts. Project quick-create now makes a private draft until its cover and publication details are ready. | Existing CinePlanner APIs and Flutter console | Complete |
| Projects list and creation | Uses animated stage filters, image-led project cards, progress/stage metadata, Open project action, step-based creation, local draft restore/save, inline validation, requirements, and review. | Live projects, requirements, files, and upload APIs | Complete |
| Compact Smart Filter | Replaced the large treatment with a compact control and active-count badge. The panel blooms from the top-right control with fade/scale and a readable glass surface; reduced motion removes the transition. Copy says Smart filters/rule-based match. | Director/shared marketplace | Complete |
| Profile gallery and privacy | Preserved horizontally navigable live galleries and contrast-safe hero overlays. Public stakeholder sheets no longer show prominent rate amounts; commercial terms direct users into authorised booking/negotiation. Sticky request and shortlist actions remain. | Live discovery/listing media and booking routes | Complete |
| Booking request | Preserved live project/listing/requirement context, stage spine, step-based terms and review, server booking creation, one state-specific primary action, and skeleton/error states. | Booking and project APIs | Complete |
| Shortlist comparison | Added profile photos, role/city/match facts, rank controls, notes, selected status, saved-search strip, bulk selection, bulk remove, and an invite queue that opens prefilled live booking requests. | Saved searches and shortlist APIs | Complete |
| Back/routing context | Profile and booking routes carry project/category/listing IDs; dashboard news routes to the exact room, negotiation, contract, or payment area. Existing browser/in-app route state is preserved. | Named routes and live entity IDs | Complete |
| Project Hub | Preserved the connected project hero, stage navigator, planning, requirements, shortlist/casting/provider lanes, deals, contracts, payments, files/activity, health indicators, and progressive disclosure. | Projects, CinePlanner, casting, booking, contract, payment, and room APIs | Complete |
| Bargaining | Uses the moving filter rail. Cards now show counterparty, role, project, current offer, whose response is required, precise remaining expiry, and last activity. Opened threads retain live offer history and counter/accept/decline actions. | Booking/negotiation APIs | Complete |
| Payments | Uses Ledger/Timeline/History moving filters; keeps Due, Proof uploaded, Verified, Rejected and settled history visually distinct; retains milestone summaries, proof audit data, actors, timestamps, and real currency values. | Payment schedule, proof, ledger, receipt, and audit APIs | Complete |
| Accessibility and motion quality | Added selected semantics independent of animation, keyboard/focus compatible controls, minimum targets, reduced motion branches, limited result staggering, theme contrast, and responsive header fixes. | Shared design system | Complete |
| Backend-only actions | Removed the fake login/OTP path and fake report entity fallback. Trust & Safety now requires authentication and a real routed entity before submission. | Auth and Trust & Safety controllers/APIs | Complete |

## Work log

| Area | What changed | Evidence |
|---|---|---|
| Shared UI | About action, Logout placement, moving filter rail, persisted marketplace preference, skeletons, responsive header corrections | Flutter static analysis and widget suite |
| Director UX | Console feed, workflow labels, planner add flow, marketplace controls/grouping, profile privacy, shortlist comparison/bulk actions, negotiation context | Flutter tests and live API integration paths |
| Cross-portal UX | Equivalent status/category/range rails migrated across business and partner portals; shared chip fallback retained for form option selectors | Portal widget tests at desktop and compact widths |
| Dashboard animation | Connected the new floating bubble treatment to the shared portal hero, making it available across every dashboard that uses the unified hero; reduced-motion mode renders it statically | Flutter analysis, full widget suite, and exact live-bundle verification |
| Backend | Schedule event read/write/audit integration and project cover validation contract | Ruff, mypy, unit tests, integration test additions |
| Production safety | Fake OTP/demo role login and fake Trust & Safety report target removed | Static analysis and tests |

## Verification record

| Check | Result |
|---|---|
| Flutter static analysis | Passed: no issues |
| Flutter widget/unit suite | Passed: 746 tests |
| Backend Ruff check/format | Passed |
| Backend mypy | Passed: 66 source files |
| Backend unit tests | Passed: 30 tests |
| Backend integration tests | Planner and cover assertions added; 3 tests skip locally because MySQL/Redis integration services are not configured |
| Flutter web production build | Passed with the production API base URL and release marker `20260926-floating-bubbles-v18` |
| Production health/database/Redis | Passed: live readiness returned API, MySQL, and Redis `ok`; API, worker, and scheduler show no deployment errors |
| Live frontend release marker and bootstrap | Passed: HTTPS served the v18 marker and 3.59 MB bundle; its SHA-256 matched the tested local build, and isolated headless Chrome rendered the login page without the slow-loading overlay |
| Authenticated production smoke | Passed: Director demo login plus dashboard, schedule, projects, and Actors marketplace requests returned HTTP 200; the smoke session was revoked |
| Git commit/push | Passed: release commits through `aa9ab07` pushed to `origin/feature/marketplace-pricing-visibility` |

## Items that require external inputs

These items cannot be completed with repository code or the existing server key.
They are external service or business inputs and remain visible here rather than
being represented by demo behaviour.

| External item | Current safe behaviour | Input needed |
|---|---|---|
| Card payment processing | Manual proof, verification, ledger, receipt, and audit workflow remains live | Payment provider account, live API keys, webhook secret, refund/chargeback policy |
| Email delivery | Backend configuration points exist; no fake delivery success is introduced | Verified sender/domain and provider credentials/templates |
| SMS/OTP | Fake OTP login was removed | SMS provider, sender approval, credentials, and production OTP policy |
| Push notifications | Device/API foundation remains | Firebase project/app credentials and production routing |
| Monitoring | Application hooks remain | Sentry or chosen monitoring DSN and alert owners |
| Off-server backups/object storage | Current production uses documented server storage/backups | Destination credentials, retention, and restore policy |
| Weather in call sheets | UI/API does not invent weather | Weather provider and key |
| Legal/business policy | Existing workflows remain | Approved contracts, privacy/terms, banking, KYC retention, refunds, disputes, and support contacts |
| Release acceptance | Automated coverage is recorded above | Named users for role UAT, device/browser matrix, accessibility audit, load test targets |

## Deployment record

| Field | Value |
|---|---|
| Git branch | `feature/marketplace-pricing-visibility` |
| Git commit | `aa9ab07` (deployed frontend); `e1c1068` (deployed backend) |
| Frontend release | `20260926-floating-bubbles-v18` |
| Backend restart | API, worker, and scheduler running image `cineconnect-prod-api:e1c1068` |
| Domain verification | Passed at `https://cine.nalexustechnologies.com`; marker, bundle, browser render, health, login, dashboard, planner schedule, projects, and marketplace verified |
