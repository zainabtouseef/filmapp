# CineConnect Portal API + Static Data Audit

Generated: 2026-07-24  
Base branch: `refactor/theme-system`  
Base commit inspected: `b5a970e`  
Primary rule: runtime portal screens must not display static demo business data. Demo-like walkthrough data must be seeded into MySQL/storage and fetched through `https://cine.nalexustechnologies.com/api/v1`.

## 1. Baseline checks

| Check | Result | Notes |
| --- | --- | --- |
| `git status --short` | plan/audit docs only | Worktree had new plan document before this audit. |
| `cd backend && python3 -m compileall app tests` | pass | Backend imports compile after latest GitHub pull. |
| `cd backend && python3 -m ruff check app tests` | pass | No lint failures. |
| `cd backend && python3 -m pytest tests/unit -q` | blocked by local MySQL | 15 passed, 1 failed because local MySQL on `127.0.0.1` refused connection for `/api/v1/roles`. This needs local DB service or test DB config, not portal code changes. |
| `flutter analyze` | pass | No Dart analyzer issues. |
| Portal widget tests | pass | Super Admin, Brand, Location Owner, Media/Equipment, Actor/Talent, Model Extension selected route tests passed. |

Portal widget test command run:

```sh
flutter test test/super_admin_portal_test.dart test/brand_sponsor_portal_test.dart test/location_owner_portal_test.dart test/media_equipment_portal_test.dart test/actor_talent_portal_test.dart test/model_extension_portal_test.dart
```

## 2. Backend API coverage summary

The latest pull already provides these backend API groups locally:

| Backend module | Coverage available locally |
| --- | --- |
| `admin_control.py` | Admin bookings, users, listings, contract templates, fee rules, roles/permissions, audit events |
| `analytics.py` | User dashboard, admin dashboard, admin analytics, exports |
| `marketplace.py` | Profiles, talent profile, portfolio, saved searches, shortlists, listings, facets |
| `bookings.py` | Availability, bookings, talent opportunities, negotiations, offers, messages |
| `contracts.py` | Contract templates, contracts, signatures, addendums, legal reviews |
| `payments.py` | Payment dashboard, schedules, proofs, ledger, receipts, payout accounts, admin proof decisions |
| `operations.py` | Location properties/pricing/rules/inspections/damage claims; equipment profile/items/packages/terms/inspections; safety checks/incidents |
| `insurance.py` | Insurance profile, policies, claims, evidence, decisions, dashboard |
| `specialist.py` | Agency, brand, model, distribution specialist flows |
| `trust_safety.py` | Reviews, reports, blocked users, moderation, disputes, support, announcements, notifications |
| `verification.py` | Uploads, KYC, admin KYC review |

Conclusion: many APIs are already generated locally. The next work is mostly frontend runtime-data replacement, plus targeted backend gaps where a portal still has no dedicated data shape.

## 3. Portal status matrix

Status meanings:

- `LIVE`: no major runtime static business-data dependency found in screen files.
- `PARTIAL`: API scopes/FutureBuilders exist, but static demo data still appears in visible runtime content.
- `DEMO`: screens are primarily driven by static demo data/store.
- `GAP`: backend shape likely missing or too generic for portal perfection.

| Portal | Current status | Main static runtime sources | Existing API scopes seen | Immediate decision |
| --- | --- | --- | --- | --- |
| Director/Producer | LIVE/mostly clean | none found in main screens | Auth, Projects, Bookings, Contracts, Payments, Analytics | Keep stable; only fix bugs while other portals are wired. |
| Super Admin | LIVE/CLEANED | `admin_mock_data.dart` removed and deleted on 2026-07-24; no `DemoData`, `DemoStore`, `admin_mock_data`, or `mock_data` runtime matches remain under `lib/features/super_admin` | Admin, Analytics, Payments, TrustSafety, Verification | Continue manual walkthrough and admin action smoke; shared core mock imports remain outside the Super Admin feature. |
| Media/Equipment | LIVE/CLEANED | `media_equipment_demo_data.dart` deleted on 2026-07-24; no feature-level `DemoData`, `DemoStore`, `mock_data`, or static-demo runtime matches remain | Operations, Bookings, Payments, TrustSafety | Continue live walkthrough and database seeding checks. |
| Brand Sponsor | LIVE/CLEANED | `brand_sponsor_demo_data.dart` removed and deleted on 2026-07-24; no feature-level `BrandSponsorDemoData`, `BrandSponsorDemoStore`, `brand_sponsor_demo_data`, preview-mode, or `_buildPreview` runtime matches remain | Specialist, Payments, Auth | Continue live walkthrough and verify seeded brand applications/deliverables/payments cover each screen. |
| Location Owner | LIVE/CLEANED | `location_owner_demo_data.dart` removed and deleted on 2026-07-24; no feature-level `LocationOwnerDemoData`, `LocationOwnerDemoStore`, `location_owner_demo_data`, preview-mode, or `_buildPreview` runtime matches remain | Operations, Bookings, Payments, Auth | Continue live walkthrough and verify seeded property/bookings/inspection/payment records cover each screen. |
| Actor/Talent | LIVE/CLEANED | `actor_talent_demo_data.dart` removed and deleted on 2026-07-24; no feature-level `ActorTalentDemoData`, `ActorTalentDemoStore`, or `actor_talent_demo_data` runtime matches remain | Auth, Bookings, Contracts, Payments, TrustSafety | Continue authenticated walkthrough and verify seeded profile/portfolio/opportunity/contract/payment/review rows cover each screen. |
| Model Extension | LIVE/CLEANED | `model_extension_demo_data.dart` removed and deleted on 2026-07-24; no feature-level `ModelExtensionDemoData`, `ModelExtensionDemoStore`, `model_extension_demo_data`, preview-mode, or `_Preview*` runtime matches remain | Specialist, Auth | Continue live walkthrough and verify seeded model categories/rights/rates/restrictions/media cover each screen. |
| Casting Agency | LIVE/CLEANED | `casting_agency_demo_data.dart` removed and deleted on 2026-07-24; no feature-level `CastingAgencyDemoData`, `CastingAgencyDemoStore`, or `casting_agency_demo_data` runtime matches remain | Specialist | Continue authenticated walkthrough and verify seeded agency roster/audition/candidate/commission rows cover each screen. |
| Crew Services | GAP/CLEANED | `crew_services_demo_data.dart` removed and deleted on 2026-07-24; no feature-level `CrewServicesDemoData`, `CrewServicesDemoStore`, or `crew_services_demo_data` runtime matches remain | none dedicated | Screens now show explicit backend-gap states. Requires crew-specific profile, portfolio, availability, request, contract/payment, and review APIs before live rows can appear. |
| Legal Partner | LIVE/CLEANED + GAP NOTES | `legal_partner_demo_data.dart` removed and deleted on 2026-07-24; no feature-level `LegalPartnerDemoData`, `LegalPartnerDemoStore`, or `legal_partner_demo_data` runtime matches remain | Contracts | Dashboard, review queue, templates, addendums, and history use Contracts APIs. Template decision/change-log and legal billing invoice rollups remain explicit backend gaps. |
| Insurance Partner | LIVE/CLEANED + GAP NOTES | `insurance_partner_demo_data.dart` removed and deleted on 2026-07-24; no feature-level `InsurancePartnerDemoData`, `InsurancePartnerDemoStore`, or `insurance_partner_demo_data` runtime matches remain | Insurance for dashboard/policies/claims; Operations create-only for safety/incidents | Dashboard, policy records, and claims are live-backed. Safety/incident pages now show explicit backend-gap notices until list/detail/update APIs exist. |
| Distribution Partner | LIVE/CLEANED | `distribution_partner_demo_data.dart` removed and deleted on 2026-07-24; no feature-level `DistributionPartnerDemoData`, `DistributionPartnerDemoStore`, or `distribution_partner_demo_data` runtime matches remain | Specialist | Continue authenticated walkthrough and verify seeded distribution profile/project/contact/report rows cover each screen. Statement export remains an explicit backend-gap notice until a real export endpoint exists. |
| Role Portals generic | GAP/CLEANED | `role_portal_demo_data.dart` removed and deleted on 2026-07-24; no feature-level `RolePortalDemoData`, `RolePortalDemoStore`, or `role_portal_demo_data` runtime matches remain | none | Legacy generic shell now renders a clean disabled/backend-gap placeholder instead of fake records, metrics, media, or workflow actions. |

## 4. Screen-by-screen static data audit

### 4.1 Director/Producer

| Screen | Status | Notes |
| --- | --- | --- |
| Director portal shell/dashboard/projects/marketplace/shortlist/bookings/contracts/payments/room/reports | LIVE | No `DemoData`/`DemoStore` found in main screen files. Keep this portal stable. |

### 4.2 Super Admin

| Area | Status | Static source | Replacement path |
| --- | --- | --- | --- |
| Admin widgets/shared rows | CLEANED | `lib/features/super_admin/mock_data/admin_mock_data.dart` deleted on 2026-07-24; nav constants moved to `admin_widgets.dart` as real UI navigation config | Feature-level static-data search now clean. |
| Dashboard/review hub/queues | PARTIAL | mock-backed widgets likely still supply rows/labels | Use admin control, analytics, KYC, moderation, payment proof, dispute, support endpoints. |

### 4.3 Brand Sponsor

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| BR-01 Dashboard | CLEANED | none | Specialist, Payments |
| BR-02 Profile | CLEANED | none | Auth, Specialist |
| BR-03 Opportunity Composer | CLEANED | none | Auth, Specialist |
| BR-04 Applications Inbox | CLEANED | none | Specialist |
| BR-05 Negotiation Terms | CLEANED | none | Specialist |
| BR-06 Campaign Tracker | CLEANED | none | Specialist |
| BR-07 Payments Records | CLEANED | none | Specialist, Payments |

Cleanup result:

- BR-01 through BR-07 now render backend data or explicit sign-in/profile/empty/error states.
- Offline preview/demo branches were removed from dashboard, profile, opportunity composer, applications inbox, negotiation terms, campaign tracker, and payments records.
- `BrandSponsorDemoStore` selection mutations were removed; live selection comes from fetched DTOs in each screen.
- Shared status labels now live in `brand_sponsor_live.dart` instead of demo data.
- Verified with `flutter analyze` and `flutter test test/brand_sponsor_portal_test.dart`.

### 4.4 Actor/Talent

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| AT-01 Dashboard | CLEANED | none | Auth, Bookings, Analytics |
| AT-02 Profile Builder | CLEANED | none | Auth |
| AT-03 Portfolio Showreel | CLEANED | none | Auth, Uploads |
| AT-04 Availability | CLEANED | none | Bookings |
| AT-05 Rate Card | CLEANED | none | Auth |
| AT-06 Opportunity Inbox | CLEANED | none | Bookings |
| AT-07 Offer Detail | CLEANED | none | Auth, Bookings |
| AT-08 Counteroffer | CLEANED | none | Bookings |
| AT-09 Contract Signing | CLEANED | none | Contracts |
| AT-10 Earnings/Security | CLEANED | none | Payments |
| AT-11 Reviews | CLEANED | none | Auth, TrustSafety |
| AT-12 Safety | CLEANED | none | TrustSafety |

Cleanup result:

- AT-01 through AT-12 now render backend data or explicit sign-in/live-backend empty/error states.
- Offline demo/store branches were removed from dashboard, profile builder, portfolio/showreel, availability, rate card, opportunity inbox, offer detail, counteroffer composer, contract signing, earnings/security, reviews, and safety controls.
- `ActorTalentDemoData` and `ActorTalentDemoStore` were removed from all screens/components, and `lib/features/actor_talent/data/actor_talent_demo_data.dart` was deleted.
- Shared booking status labels now live in `actor_talent_components.dart` instead of demo data.
- Rate Card now edits only the live published day-rate field available on the talent profile API; the old fake private quote-guide table was removed until a dedicated backend rate-card API exists.
- Verified with `flutter analyze` and `flutter test test/actor_talent_portal_test.dart`.

### 4.5 Model Extension

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| MD-01 Campaign Categories | CLEANED | none | Specialist |
| MD-02 Usage Rights | CLEANED | none | Specialist |
| MD-03 Portfolio Categories | CLEANED | none | Auth |
| MD-04 Rate by Usage | CLEANED | none | Specialist |
| MD-05 Brand Safety | CLEANED | none | Specialist |

Cleanup result:

- MD-01 through MD-05 now render backend data or explicit sign-in/empty/error states.
- Offline preview/demo branches were removed from campaign categories, usage rights, portfolio categories, usage rates, and brand safety.
- Category and restriction options remain configuration-only UI choices; selected/live values are loaded from backend model profile records.
- Shared status/platform labels now live in `model_extension_components.dart` instead of demo data.
- Verified with `flutter analyze` and `flutter test test/model_extension_portal_test.dart`.

### 4.6 Location Owner

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| LO-01 Dashboard | CLEANED | none | Operations, Bookings, Payments |
| LO-02 Listing Wizard | CLEANED | none | Auth, Operations |
| LO-03 Availability | CLEANED | none | Bookings |
| LO-04 Pricing | CLEANED | none | Operations |
| LO-05 Rules | CLEANED | none | Operations |
| LO-06 Booking Requests | CLEANED | none | Auth, Bookings |
| LO-07 Check-in | CLEANED | none | Auth, Bookings, Operations |
| LO-08 Check-out/Damage | CLEANED | none | Auth, Bookings, Operations |
| LO-09 Earnings | CLEANED | none | Auth, Payments |
| LO-10 Performance | CLEANED | none | Operations, Bookings |

Cleanup result:

- LO-01 through LO-10 now render backend data or explicit sign-in/property/empty/error states.
- Offline preview/demo branches were removed from dashboard, listing wizard, availability, pricing, rules, booking requests, check-in, check-out/damage, earnings, and performance.
- `LocationOwnerDemoStore` was replaced with `LocationOwnerSelectionStore`, which stores only the selected backend property ID and contains no business/demo data.
- Shared booking status labels now live in `location_owner_live.dart` instead of demo data.
- Verified with `flutter analyze` and `flutter test test/location_owner_portal_test.dart`.

### 4.7 Media/Equipment

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| ME-01 Dashboard | LIVE/PARTIAL | none in screen | Operations, Bookings |
| ME-02 Provider Profile | LIVE/PARTIAL | none in screen | Operations |
| ME-03 Inventory | CLEANED | Former `MediaEquipmentDemoData` fallback removed; API errors now show retry/empty state, not preview items | Operations |
| ME-04 Packages | LIVE/PARTIAL | none in screen | Operations |
| ME-05 Availability | LIVE/PARTIAL | none in screen | Bookings, Operations |
| ME-06 Terms | LIVE/PARTIAL | none in screen | Operations |
| ME-07 Booking Requests | LIVE/PARTIAL | none in screen | Bookings |
| ME-08 Handover | LIVE/PARTIAL | inspection workspace | Operations, Bookings |
| ME-09 Return | LIVE/PARTIAL | inspection workspace | Operations, Bookings |
| ME-10 Earnings/Ratings | LIVE/PARTIAL | none in screen | Auth, Operations, Bookings, Payments, TrustSafety |

Cleanup result:

- Removed `MediaEquipmentDemoData` import from inventory manager and shared components.
- Moved booking status labels into real component helper `mediaBookingStatusLabel`.
- Deleted `lib/features/media_equipment/data/media_equipment_demo_data.dart`.
- Empty/error states now show database-backed retry/empty messaging instead of static preview records.

### 4.8 Crew Services

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| CR-01 Dashboard | GAP/CLEANED | none | none dedicated |
| CR-02 Service Profile | GAP/CLEANED | none | none dedicated |
| CR-03 Credits | GAP/CLEANED | none | none dedicated |
| CR-04 Availability | GAP/CLEANED | none | none dedicated |
| CR-05 Requests | GAP/CLEANED | none | none dedicated |
| CR-06 Contracts/Payments | GAP/CLEANED | none | none dedicated |
| CR-07 Ratings | GAP/CLEANED | none | none dedicated |

Replacement path:

- Crew requires backend APIs before serious UI wiring.
- Recommended: add crew profile, credits, service categories, rate-card, marketplace listing linkage, crew availability, crew requests/offers, crew contract/payment linkage, and crew reviews/work history.

### 4.9 Casting Agency

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| CA-01 Dashboard | CLEANED | none | Specialist, Analytics |
| CA-02 Roster | CLEANED | none | Specialist |
| CA-03 Audition Inbox | CLEANED | none | Specialist |
| CA-04 Shortlist | CLEANED | none | Specialist |
| CA-05 Self-tapes | CLEANED | none | Specialist |
| CA-06 Notes | CLEANED | none | Specialist |
| CA-07 Commissions | CLEANED | none | Specialist |
| CA-08 Bookings | CLEANED | none | Specialist |

Cleanup result:

- CA-01 through CA-08 now render backend data or explicit sign-in/live-backend empty/error states.
- Offline demo/store branches were removed from dashboard, roster, audition inbox, shortlist builder, self-tape collection, selection notes, commission records, and booking records.
- `CastingAgencyDemoData` and `CastingAgencyDemoStore` were removed from all screens/components, and `lib/features/casting_agency/data/casting_agency_demo_data.dart` was deleted.
- Shared status labels now live in `casting_agency_components.dart` instead of demo data.
- Added thin `SpecialistController` wrappers for existing backend candidate update, selection-note create, and commission create repository methods.
- Verified with `flutter analyze` and `flutter test test/casting_agency_portal_test.dart`.

### 4.10 Legal Partner

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| LG-01 Dashboard | CLEANED | none | Contracts |
| LG-02 Contract Review | CLEANED | none | Contracts |
| LG-03 Template Review | GAP/CLEANED | none | Contracts templates |
| LG-04 Addendum Review | CLEANED | none | Contracts |
| LG-05 History/Billing | GAP/CLEANED | none | Contracts |

Replacement path:

- Uses contracts, legal reviews, decisions, contract templates, and contract addendums.
- Add template review decision/change-log APIs and legal billing invoice/ledger rollup APIs before enabling those workflow actions.

### 4.11 Insurance Partner

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| IN-01 Dashboard | CLEANED | none | Insurance |
| IN-02 Records | CLEANED | none | Insurance |
| IN-03 Claims | CLEANED | none | Insurance |
| IN-04 Safety/Permits | GAP/CLEANED | none | Operations create endpoints only |
| IN-05 Incidents | GAP/CLEANED | none | Operations create endpoints only |

Replacement path:

- Uses insurance dashboard/policies/claims.
- Add operations safety-check and incident list/detail/update APIs before showing live safety and incident rows.

### 4.12 Distribution Partner

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| DS-01 Dashboard | CLEANED | none | Specialist |
| DS-02 Contacts | CLEANED | none | Specialist |
| DS-03 Release Coordination | CLEANED | none | Specialist |
| DS-04 Reporting | CLEANED | none | Specialist |

Replacement path:

- Uses distribution profile/projects/contacts/reports through `SpecialistScope`.
- Statement export is intentionally not faked; add a backend export endpoint before enabling that action.

### 4.13 Role Portals generic screens

| Screen | Status | Static source | Decision |
| --- | --- | --- | --- |
| `lib/features/role_portals/screens/role_portal_screen.dart` | GAP/CLEANED | none | Legacy generic visual shell retained for route compatibility; it no longer shows fake records and requires live DTOs before re-enabling data views. |

## 5. Priority implementation recommendation

Based on current code shape and backend coverage:

1. Deploy the latest Flutter web build after this clean pass.
2. Seed MySQL rows for each live-backed portal so manual demo screens are visibly populated from `https://cine.nalexustechnologies.com/api/v1`.
3. Add missing backend APIs for explicit gap screens: Crew Services, Insurance safety/incident read/update feeds, Legal template decision/change-log, Legal billing rollup, and Distribution statement export.
4. Keep generic Role Portals disabled unless they receive live DTOs or are removed from route exposure.

## 6. Static data removal acceptance command

Before calling any portal complete, run:

```sh
rg -n "DemoData|DemoStore|_demo_data|mock_data|MockData" lib/features -g '*.dart'
```

Allowed matches:

- tests only
- seed scripts/docs only
- neutral image/icon fallback names that do not render business records
- explicit backend-gap copy

Not allowed:

- dashboard metrics
- business cards/lists/tables
- profile defaults
- booking/payment/contract rows
- action state machines
- selected active IDs
- fake media galleries

## 7. Next concrete implementation step

Proceed with Phase P2 from the perfection plan:

1. Verify whether production backend already includes latest pulled backend routes.
2. If not, deploy backend and run the new migration.
3. Then implement Phase P3 Super Admin static-data removal and API completion.
