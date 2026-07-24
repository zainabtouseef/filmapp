# CineConnect Current Status and Next Steps Report

Generated: 2026-07-24  
Environment: Production web at `https://cine.nalexustechnologies.com`  
API base used by deployed Flutter web: `https://cine.nalexustechnologies.com/api/v1`  
Latest pushed commit: `8793f9a` on branch `refactor/theme-system`

## 1. Executive summary

CineConnect is now past the main backend creation, frontend-backend wiring, production deployment, and static demo-data cleanup phases.

The most important result from the latest pass is this:

- Feature-level runtime static demo data has been removed from `lib/features`.
- The deployed Flutter web app now points to the production API domain.
- Portals with real APIs now show live server-backed data, authenticated empty states, or API error states.
- Portals or actions without a backend API now show explicit backend-gap messaging instead of fake business records.

The app is therefore cleaner and safer for demo preparation: visible business data should now come from MySQL/API-backed rows, not hardcoded Flutter demo stores.

## 2. What is already done

### 2.1 Backend platform

The backend has already been built through the major planned phases and deployed previously to the production server.

Completed backend areas include:

- Authentication and role mapping.
- Director/Producer project flows.
- Marketplace discovery and listing detail.
- Bookings, offers, negotiations, messages, and availability foundations.
- Contracts, signatures, legal reviews, addendums, and templates.
- Payments, schedules, proofs, receipts, ledgers, and payout-account foundations.
- Operations for locations, equipment, inspections, damage claims, safety checks, incidents, and check-ins.
- Insurance profile, policy, claim, evidence, decisions, and dashboard.
- Specialist flows for casting agency, brand sponsor, model extension, and distribution partner.
- Trust and safety: reviews, reports, blocks, moderation, disputes, support, announcements, and notifications.
- Admin control, dashboards, analytics, CSV exports, monitoring wiring, and production backups.

### 2.2 Production deployment

The latest Flutter web build was deployed to production.

- Production web domain: `https://cine.nalexustechnologies.com`
- Production API base compiled into Flutter web: `https://cine.nalexustechnologies.com/api/v1`
- HTTPS smoke check: production root returned HTTP 200.

No backend deployment was required in the latest cleanup pass because the latest changes were frontend/data-cleanup and documentation work, not backend Python/API changes.

### 2.3 GitHub

Latest commit was pushed to GitHub:

- Commit: `8793f9a Remove remaining feature demo portal data`
- Branch: `refactor/theme-system`

### 2.4 Static demo-data cleanup

The following feature demo stores/data files were removed:

- `casting_agency_demo_data.dart`
- `crew_services_demo_data.dart`
- `director_producer_demo_data.dart`
- `distribution_partner_demo_data.dart`
- `insurance_partner_demo_data.dart`
- `legal_partner_demo_data.dart`
- `role_portal_demo_data.dart`

The global feature-level static-data check now passes:

```sh
rg -n "DemoData|DemoStore|_demo_data|mock_data|MockData" lib/features -g '*.dart'
```

Expected/current result: no matches.

## 3. Portal-by-portal current status

| Portal | Current status | Data behavior now |
| --- | --- | --- |
| Director/Producer | Live/mostly clean | Uses live APIs for dashboard/project/marketplace/booking/contract/payment/report flows. |
| Super Admin | Live/cleaned | Feature-level admin mock data removed; admin/control APIs available. |
| Media/Equipment | Live/cleaned | Uses operations/bookings/payments/trust-safety APIs. |
| Brand Sponsor | Live/cleaned | Uses Specialist, Payments, and Auth APIs. |
| Location Owner | Live/cleaned | Uses Operations, Bookings, Payments, and Auth APIs. |
| Actor/Talent | Live/cleaned | Uses Auth, Bookings, Contracts, Payments, Analytics, and Trust Safety APIs. |
| Model Extension | Live/cleaned | Uses Specialist and Auth APIs. |
| Casting Agency | Live/cleaned | Uses Specialist APIs for agency profile, roster, auditions, candidates, notes, and commissions. |
| Distribution Partner | Live/cleaned | Uses Specialist APIs for profile, projects, contacts, project status update, and reports. |
| Insurance Partner | Live/cleaned with gap notes | Dashboard, records, and claims use Insurance APIs; safety/incidents show explicit backend-gap notices. |
| Legal Partner | Live/cleaned with gap notes | Dashboard, reviews, templates, addendums, and history use Contracts APIs; template decisions and billing rollups show explicit backend-gap notices. |
| Crew Services | Gap/cleaned | No fake rows remain; screens show explicit backend-gap states until crew APIs are built. |
| Generic Role Portals | Gap/cleaned | Legacy shell retained for route compatibility but fake metrics/records/media/workflows removed. |

## 4. What is functional now

### 4.1 Functional live-backed areas

These areas are wired to live APIs and should be demoable once the correct user accounts and database rows exist:

- Director/Producer:
  - dashboard
  - projects
  - requirement builder
  - project room
  - marketplace discovery
  - shortlist board
  - booking requests
  - contracts
  - payments
  - reports

- Actor/Talent:
  - profile
  - portfolio
  - availability
  - opportunities
  - offers/counteroffers
  - contracts
  - earnings
  - reviews/safety

- Location Owner:
  - property/listing flows
  - pricing/rules
  - availability
  - booking requests
  - check-in/check-out and inspection-related flows
  - earnings/performance

- Media/Equipment:
  - provider profile
  - inventory
  - packages
  - availability
  - terms
  - booking requests
  - handover/return
  - earnings/ratings

- Brand Sponsor:
  - sponsor profile
  - opportunity creation
  - applications
  - negotiation
  - campaign tracking
  - payment records

- Model Extension:
  - campaign categories
  - usage rights
  - portfolio categories
  - rates by usage
  - brand safety restrictions

- Casting Agency:
  - agency dashboard
  - talent roster
  - audition inbox
  - candidate shortlist
  - self-tape collection
  - selection notes
  - commission records
  - agency booking records

- Distribution Partner:
  - dashboard
  - distributor contacts
  - release coordination
  - performance reports

- Insurance Partner:
  - dashboard
  - policy records
  - claim support
  - claim approve/escalate actions

- Legal Partner:
  - legal dashboard
  - legal review queue/detail
  - approve/request-changes review actions
  - template list
  - addendum list from live contracts
  - review/contract history

### 4.2 Functional but needs seeded data

Many screens are technically wired and working but may look empty until the database has enough realistic rows.

Recommended seed coverage:

- At least 10 visible Director projects/listings/bookings/payment/contract records.
- At least 10 Actor/Talent records including portfolio media, opportunities, offers, contracts, earnings, and reviews.
- At least 10 Location records with spaces, prices, rules, bookings, inspections, and payments.
- At least 10 Media/Equipment records with items, packages, bookings, inspections, and payouts.
- At least 10 Brand opportunities/applications/deliverables/payment records.
- At least 10 Model category/rights/rate/restriction records.
- At least 10 Casting Agency roster/audition/candidate/commission records.
- At least 10 Distribution profile/project/contact/report records.
- At least 10 Insurance policy/claim/evidence rows.
- At least 10 Legal review/contract/template/addendum rows.
- Only 1 Super Admin account is needed.

## 5. What is not done yet

### 5.1 Backend APIs still required

These are the real remaining backend gaps:

1. Crew Services backend
   - Crew provider profile CRUD.
   - Crew portfolio/credits.
   - Crew availability blocks.
   - Crew request and offer negotiation.
   - Crew booking-to-contract/payment linkage.
   - Crew reviews and work history.

2. Insurance safety and incident read/update APIs
   - The app currently has operations create endpoints, but the Insurance portal needs list/detail/update feeds.
   - Needed endpoints:
     - list safety checks
     - safety check detail
     - update safety check
     - update safety check item
     - list incidents
     - incident detail
     - update/resolve/escalate incident

3. Legal template workflow APIs
   - Template list exists.
   - Still needed:
     - template review decision endpoint
     - template change-log endpoint
     - template reviewer assignment/status endpoint if required

4. Legal billing rollup
   - Contract/review history exists.
   - Still needed:
     - legal invoice records
     - legal review billing rollup
     - legal partner payout/payment linkage

5. Distribution statement export
   - Distribution reports exist.
   - Still needed:
     - real statement export endpoint
     - export job/status/download endpoint if asynchronous

6. Generic Role Portals decision
   - The generic Role Portal shell is now safely disabled.
   - Either remove these legacy routes from production navigation or give them live DTOs.

### 5.2 Manual user input still required

You still need to provide or decide:

- Final manual bank transfer details.
- Real payment provider choice and production keys when moving away from dummy/manual payment behavior.
- Email provider credentials.
- SMS/OTP provider credentials if OTP must be real.
- Firebase push configuration files and production keys.
- Object storage provider and credentials if final media storage is not already settled.
- Final business/legal policy text for:
  - privacy policy
  - terms of service
  - KYC retention
  - contract retention
  - payment retention
  - chat retention
  - safety report retention
  - deleted account retention
- Real demo walkthrough account list if you want fixed passwords and role-specific accounts.
- Final decision on whether Crew Services should be a full first-class backend module or mapped onto existing marketplace/bookings/payment APIs.

## 6. Dummy or placeholder areas

These are intentionally not pretending to be final production functionality:

- Manual bank transfer: dummy until final bank details are provided.
- Card payments: dummy/sandbox until real payment provider is selected and configured.
- Crew Services screens: explicit backend-gap placeholders.
- Insurance safety/incident screens: explicit backend-gap placeholders.
- Legal template decision/change-log: explicit backend-gap note.
- Legal billing invoices/rollup: explicit backend-gap note.
- Distribution statement export: explicit backend-gap note.
- Generic Role Portals: legacy placeholder, not live business UI.

## 7. Verification already run

Latest cleanup pass verification:

```sh
flutter analyze
flutter test test/casting_agency_portal_test.dart
flutter test test/distribution_partner_portal_test.dart
flutter test test/insurance_partner_portal_test.dart
flutter test test/legal_partner_portal_test.dart
flutter test test/crew_services_portal_test.dart
flutter test test/role_portals_test.dart
rg -n "DemoData|DemoStore|_demo_data|mock_data|MockData" lib/features -g '*.dart'
```

Result:

- Analyzer: passed.
- Portal route tests: passed.
- Feature-level static demo scan: no matches.
- Production HTTPS root smoke: HTTP 200.

Known build warnings:

- Flutter web wasm dry-run warnings from `flutter_secure_storage_web`.
- Cupertino icon font warning.

These warnings did not block the production web build.

## 8. Recommended next implementation order

1. Seed and verify demo data in MySQL
   - This is the highest-value next step because many live-wired screens need rows to look full during a demo.

2. Perform manual browser/device walkthrough
   - Login role by role.
   - Confirm each screen shows live data or an honest gap state.
   - Capture screenshots of any validation/API issues.

3. Build Crew Services backend
   - This is the largest remaining functional gap.

4. Add Insurance safety/incident read/update APIs
   - This turns IN-04 and IN-05 from gap states into real screens.

5. Add Legal billing/template workflow APIs
   - This completes LG-03 and LG-05 workflows.

6. Add Distribution statement export
   - This completes DS-04 export capability.

7. Decide fate of generic Role Portals
   - Remove from production navigation, or rebuild with live DTOs.

8. Final production hardening
   - Confirm backups.
   - Confirm monitoring alerts.
   - Confirm CORS origins.
   - Confirm SSL renewal.
   - Confirm real payment/email/SMS/push providers.

## 9. Manual walkthrough checklist

For each role:

1. Login with the role account.
2. Open every portal route.
3. Confirm no fake/demo rows appear.
4. Confirm populated screens are loaded from API/database.
5. Confirm empty screens explain what data/API is missing.
6. Try one safe write action where available.
7. Refresh the page and confirm state persists from backend.
8. Check browser console for errors.
9. Check API response failures if any screen shows an error.
10. Record screenshots for final acceptance.

Priority walkthrough order:

1. Director/Producer
2. Actor/Talent
3. Location Owner
4. Media/Equipment
5. Casting Agency
6. Brand Sponsor
7. Model Extension
8. Distribution Partner
9. Insurance Partner
10. Legal Partner
11. Super Admin
12. Crew Services gap screens
13. Generic Role Portal gap screens

## 10. Final acceptance criteria

The app can be considered demo-ready when:

- Production app loads at `https://cine.nalexustechnologies.com`.
- Every role can login.
- Every live-backed screen has database rows visible.
- No portal shows hardcoded demo business records.
- All intentional gap screens are understood and approved.
- User-provided payment/bank/provider details are configured or clearly marked as dummy.
- Manual walkthrough succeeds on Chrome and at least one mobile/device target.
- Backend health, database, Redis, SSL, CORS, and backups are confirmed.

## 11. Bottom line

The main app architecture and portal wiring are in strong shape now. The biggest remaining work is not more cleanup; it is data completion and targeted backend APIs for the explicit gap screens.

Next best move: seed/verify live demo data first, then implement the missing Crew, Insurance safety/incident, Legal billing/template, and Distribution export APIs.
