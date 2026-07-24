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
| Media/Equipment | PARTIAL but closest to live | `MediaEquipmentDemoData` in inventory/widgets; demo store still exists | Operations, Bookings, Payments, TrustSafety | Good early win; most screens already use live scopes. |
| Brand Sponsor | PARTIAL | `BrandSponsorDemoData`, `BrandSponsorDemoStore` | Specialist, Payments, Auth | Needs live dashboard/application/deliverable/payment replacement. |
| Location Owner | PARTIAL | `LocationOwnerDemoData`, `LocationOwnerDemoStore` | Operations, Bookings, Payments, Auth | APIs exist for most workflows; replace shell/store and performance/ledger fallbacks. |
| Actor/Talent | PARTIAL | `ActorTalentDemoData`, `ActorTalentDemoStore` | Auth, Bookings, Contracts, Payments, TrustSafety | Many existing APIs; rate-card/profile/reputation gaps need careful handling. |
| Model Extension | PARTIAL | `ModelExtensionDemoData`, `ModelExtensionDemoStore` | Specialist, Auth | Model APIs exist; remove local profile/rates/restrictions fallbacks. |
| Casting Agency | DEMO/PARTIAL | `CastingAgencyDemoData`, `CastingAgencyDemoStore` | Specialist only on first screens | Specialist APIs exist but most screens still local. |
| Crew Services | DEMO/GAP | `CrewServicesDemoData`, `CrewServicesDemoStore` | Bookings only on availability | Requires crew-specific backend decision. |
| Legal Partner | PARTIAL | `LegalPartnerDemoData`, `LegalPartnerDemoStore` | Contracts | Contract/legal review APIs exist; billing/template review may need backend additions. |
| Insurance Partner | PARTIAL | `InsurancePartnerDemoData`, `InsurancePartnerDemoStore` | Insurance on first screens | Insurance APIs exist; safety/incident screens need operations linkage. |
| Distribution Partner | PARTIAL | `DistributionPartnerDemoData`, `DistributionPartnerDemoStore` | Specialist | Distribution APIs exist; dashboard/reporting/handover need full live replacement. |
| Role Portals generic | DEMO | `RolePortalDemoData`, `RolePortalDemoStore` | none | Treat as legacy/generic demo portal; remove from runtime if replaced by real role portals. |

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
| BR-01 Dashboard | PARTIAL | `BrandSponsorDemoData`, `BrandSponsorDemoStore` | Specialist, Payments |
| BR-02 Profile | PARTIAL | `BrandSponsorDemoData.profile` | Auth, Specialist |
| BR-03 Opportunity Composer | PARTIAL | `BrandSponsorDemoData`, `BrandSponsorDemoStore` | Auth, Specialist |
| BR-04 Applications Inbox | PARTIAL | `BrandSponsorDemoData`, `BrandSponsorDemoStore` | Specialist |
| BR-05 Negotiation Terms | PARTIAL | `BrandSponsorDemoData`, `BrandSponsorDemoStore` | Specialist |
| BR-06 Campaign Tracker | PARTIAL | `BrandSponsorDemoData`, `BrandSponsorDemoStore` | Specialist |
| BR-07 Payments Records | PARTIAL | `BrandSponsorDemoData`, `BrandSponsorDemoStore` | Specialist, Payments |

Replacement path:

- Use `/brands/profile`, `/brand-opportunities`, `/brand-applications`, `/campaign-deliverables`, `/campaign-metrics`, `/payments/dashboard`, `/ledger`.
- Delete runtime usage of `BrandSponsorDemoStore` once live selected opportunity/application IDs come from backend.

### 4.4 Actor/Talent

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| AT-01 Dashboard | PARTIAL | `ActorTalentDemoData`, `ActorTalentDemoStore` | Auth, Bookings |
| AT-02 Profile Builder | PARTIAL | `ActorTalentDemoData`, `ActorTalentDemoStore` | Auth |
| AT-03 Portfolio Showreel | PARTIAL | `ActorTalentDemoStore` | Auth, FutureBuilder |
| AT-04 Availability | PARTIAL | `ActorTalentDemoStore` | Bookings |
| AT-05 Rate Card | DEMO/PARTIAL | `ActorTalentDemoStore` | Auth |
| AT-06 Opportunity Inbox | PARTIAL | `ActorTalentDemoData`, `ActorTalentDemoStore` | Bookings |
| AT-07 Offer Detail | PARTIAL | `ActorTalentDemoData`, `ActorTalentDemoStore` | Auth |
| AT-08 Counteroffer | DEMO/PARTIAL | `ActorTalentDemoData`, `ActorTalentDemoStore` | Bookings |
| AT-09 Contract Signing | PARTIAL | `ActorTalentDemoStore` | Contracts |
| AT-10 Earnings/Security | PARTIAL | `ActorTalentDemoData`, `ActorTalentDemoStore` | Payments |
| AT-11 Reviews | PARTIAL | `ActorTalentDemoData` | Auth, TrustSafety |
| AT-12 Safety | PARTIAL | `ActorTalentDemoStore` | TrustSafety |

Replacement path:

- Use profile, talent profile, portfolio, availability, talent opportunities, bookings/offers, negotiations, contracts/signatures, payments/ledger/payouts, reviews, reports, blocked users.
- Decide rate-card persistence: marketplace listing rate fields may be enough; if not, add dedicated talent rate-card API.

### 4.5 Model Extension

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| MD-01 Campaign Categories | PARTIAL | `ModelExtensionDemoData`, `ModelExtensionDemoStore` | Specialist |
| MD-02 Usage Rights | PARTIAL | `ModelExtensionDemoData`, `ModelExtensionDemoStore` | Specialist |
| MD-03 Portfolio Categories | PARTIAL | `ModelExtensionDemoData`, `ModelExtensionDemoStore` | Auth |
| MD-04 Rate by Usage | PARTIAL | `ModelExtensionDemoStore` | Specialist |
| MD-05 Brand Safety | PARTIAL | `ModelExtensionDemoStore` | Specialist |

Replacement path:

- Use `/model/profile`, `/model/campaign-categories`, `/model/usage-rights`, `/model/usage-rates`, `/model/restricted-categories`, `/portfolio`.
- Remove static hero/profile images and replace with backend media/file URLs.

### 4.6 Location Owner

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| LO-01 Dashboard | PARTIAL | `LocationOwnerDemoData`, `LocationOwnerDemoStore` | Operations, Bookings, Payments |
| LO-02 Listing Wizard | PARTIAL | `LocationOwnerDemoStore` | Auth, Operations |
| LO-03 Availability | PARTIAL | `LocationOwnerDemoStore` | Bookings |
| LO-04 Pricing | PARTIAL | `LocationOwnerDemoStore` | Operations |
| LO-05 Rules | PARTIAL | `LocationOwnerDemoStore` | Operations |
| LO-06 Booking Requests | PARTIAL | `LocationOwnerDemoData`, `LocationOwnerDemoStore` | Auth, Bookings |
| LO-07 Check-in | PARTIAL | `LocationOwnerDemoStore` | Auth, Bookings, Operations |
| LO-08 Check-out/Damage | PARTIAL | `LocationOwnerDemoStore` | Auth, Bookings, Operations |
| LO-09 Earnings | PARTIAL | `LocationOwnerDemoData` | Auth, Payments |
| LO-10 Performance | PARTIAL | `LocationOwnerDemoData`, `LocationOwnerDemoStore` | Operations, Bookings |

Replacement path:

- Use location properties/spaces/pricing/rules, availability, bookings, inspections, damage claims, payments, payout accounts.
- Add backend property performance rollup if current endpoints cannot calculate dashboard/performance efficiently.

### 4.7 Media/Equipment

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| ME-01 Dashboard | LIVE/PARTIAL | none in screen | Operations, Bookings |
| ME-02 Provider Profile | LIVE/PARTIAL | none in screen | Operations |
| ME-03 Inventory | PARTIAL | `MediaEquipmentDemoData` fallback | Operations |
| ME-04 Packages | LIVE/PARTIAL | none in screen | Operations |
| ME-05 Availability | LIVE/PARTIAL | none in screen | Bookings, Operations |
| ME-06 Terms | LIVE/PARTIAL | none in screen | Operations |
| ME-07 Booking Requests | LIVE/PARTIAL | none in screen | Bookings |
| ME-08 Handover | LIVE/PARTIAL | inspection workspace | Operations, Bookings |
| ME-09 Return | LIVE/PARTIAL | inspection workspace | Operations, Bookings |
| ME-10 Earnings/Ratings | LIVE/PARTIAL | none in screen | Auth, Operations, Bookings, Payments, TrustSafety |

Replacement path:

- This is the best first portal after Admin/Backend deploy.
- Remove remaining `MediaEquipmentDemoData` fallback from inventory and shared widgets.
- Ensure empty inventory shows empty state rather than seeded Dart inventory.

### 4.8 Crew Services

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| CR-01 Dashboard | DEMO | `CrewServicesDemoData`, `CrewServicesDemoStore` | none |
| CR-02 Service Profile | DEMO | `CrewServicesDemoData`, `CrewServicesDemoStore` | none |
| CR-03 Credits | DEMO | `CrewServicesDemoStore` | none |
| CR-04 Availability | PARTIAL | `CrewServicesDemoStore` | Bookings |
| CR-05 Requests | DEMO | `CrewServicesDemoData`, `CrewServicesDemoStore` | none |
| CR-06 Contracts/Payments | DEMO | `CrewServicesDemoData`, `CrewServicesDemoStore` | none |
| CR-07 Ratings | DEMO | `CrewServicesDemoData` | none |

Replacement path:

- Crew requires a backend decision before serious UI wiring.
- Recommended: add crew profile, credits, service categories, rate-card, and marketplace listing linkage; reuse availability/bookings/contracts/payments/reviews.

### 4.9 Casting Agency

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| CA-01 Dashboard | PARTIAL | `CastingAgencyDemoData`, `CastingAgencyDemoStore` | Specialist |
| CA-02 Roster | PARTIAL | `CastingAgencyDemoData`, `CastingAgencyDemoStore` | Specialist |
| CA-03 Audition Inbox | PARTIAL | `CastingAgencyDemoData`, `CastingAgencyDemoStore` | Specialist |
| CA-04 Shortlist | DEMO/PARTIAL | `CastingAgencyDemoData`, `CastingAgencyDemoStore` | none |
| CA-05 Self-tapes | DEMO/PARTIAL | `CastingAgencyDemoData`, `CastingAgencyDemoStore` | none |
| CA-06 Notes | DEMO/PARTIAL | `CastingAgencyDemoData`, `CastingAgencyDemoStore` | none |
| CA-07 Commissions | DEMO/PARTIAL | `CastingAgencyDemoData`, `CastingAgencyDemoStore` | none |
| CA-08 Bookings | DEMO/PARTIAL | `CastingAgencyDemoData`, `CastingAgencyDemoStore` | none |

Replacement path:

- Use agency profile/invitations/talent, auditions, candidates, self-tapes, notes, commissions, bookings.
- Add missing controller/repository exposure where specialist backend endpoints exist but UI has no scope usage.

### 4.10 Legal Partner

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| LG-01 Dashboard | PARTIAL | `LegalPartnerDemoData`, `LegalPartnerDemoStore` | Contracts |
| LG-02 Contract Review | PARTIAL | `LegalPartnerDemoData`, `LegalPartnerDemoStore` | Contracts |
| LG-03 Template Review | PARTIAL | `LegalPartnerDemoData`, `LegalPartnerDemoStore` | Contracts |
| LG-04 Addendum Review | PARTIAL | `LegalPartnerDemoData`, `LegalPartnerDemoStore` | Contracts |
| LG-05 History/Billing | PARTIAL | `LegalPartnerDemoData`, `LegalPartnerDemoStore` | Contracts |

Replacement path:

- Use contracts, legal reviews, decisions, contract templates.
- Billing may need a legal-review payment/ledger join or dedicated backend rollup.

### 4.11 Insurance Partner

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| IN-01 Dashboard | PARTIAL | `InsurancePartnerDemoData`, `InsurancePartnerDemoStore` | Insurance |
| IN-02 Records | PARTIAL | `InsurancePartnerDemoData`, `InsurancePartnerDemoStore` | Insurance |
| IN-03 Claims | PARTIAL | `InsurancePartnerDemoData`, `InsurancePartnerDemoStore` | Insurance |
| IN-04 Safety/Permits | DEMO/PARTIAL | `InsurancePartnerDemoData`, `InsurancePartnerDemoStore` | none |
| IN-05 Incidents | DEMO/PARTIAL | `InsurancePartnerDemoData`, `InsurancePartnerDemoStore` | none |

Replacement path:

- Use insurance profile/dashboard/policies/claims plus operations safety checks and incidents.
- Add controller/repository methods for safety/incident read APIs if not exposed.

### 4.12 Distribution Partner

| Screen | Status | Static source | Existing scopes |
| --- | --- | --- | --- |
| DS-01 Dashboard | PARTIAL | `DistributionPartnerDemoData`, `DistributionPartnerDemoStore` | Specialist |
| DS-02 Contacts | PARTIAL | `DistributionPartnerDemoData`, `DistributionPartnerDemoStore` | Specialist |
| DS-03 Release Coordination | PARTIAL | `DistributionPartnerDemoData`, `DistributionPartnerDemoStore` | Specialist |
| DS-04 Reporting | PARTIAL | `DistributionPartnerDemoData`, `DistributionPartnerDemoStore` | Specialist |

Replacement path:

- Use distribution profile/projects/release windows/handover items/contacts/reports.
- Add dashboard aggregation if needed.

### 4.13 Role Portals generic screens

| Screen | Status | Static source | Decision |
| --- | --- | --- | --- |
| `lib/features/role_portals/screens/role_portal_screen.dart` | DEMO | `RolePortalDemoData`, `RolePortalDemoStore` | Treat as legacy visual/demo shell. Remove from production navigation if real portals replace it, or rewire completely to live APIs. |

## 5. Priority implementation recommendation

Based on current code shape and backend coverage:

1. Deploy latest pulled backend first if server does not already have `admin_control.py`, expanded `operations.py`, expanded `specialist.py`, and migration `c4d5e6f7a8b9`.
2. Super Admin next, because it validates admin/control APIs and reveals cross-portal records.
3. Media/Equipment next, because it has the least remaining screen-level static data and strong operations APIs.
4. Brand Sponsor, Location Owner, Actor/Talent, Model Extension.
5. Casting Agency, Distribution, Insurance, Legal.
6. Crew Services last among the user-facing portals because it likely needs the most new backend shape.

## 6. Static data removal acceptance command

Before calling any portal complete, run:

```sh
rg -n "DemoData|DemoStore|admin_mock_data|mock_data|shared_mock_data|sample|static demo" lib/features lib/core -g '*.dart'
```

Allowed matches:

- tests only
- seed scripts/docs only
- neutral image/icon fallback names that do not render business records

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
