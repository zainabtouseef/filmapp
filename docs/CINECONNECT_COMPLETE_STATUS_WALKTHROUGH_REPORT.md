# CineConnect Complete Backend, Wiring, Demo Data, and Walkthrough Handoff Report

Generated: 2026-07-18

Domain/API: `https://cine.nalexustechnologies.com/api/v1`

Security note: this report includes demo app account credentials for walkthrough only. It intentionally does not include server/root/database passwords.

## Executive summary

- Backend creation: complete for planned Phase 0-12 scope and deployed.
- Flutter/backend wiring: implemented through M10 cleanup passes; automated tests and route-level browser smoke pass.
- Demo data insertion: seeded across all major plan areas in production MySQL using three idempotent slices.
- Current strongest validation: 361 Flutter tests, production web build, and 82 route screenshots with 0 runtime/error route events.
- Remaining acceptance blocker: human login-based visual walkthrough per portal.

## Overall completion estimate

| Area | Status | Estimate | Evidence |
|---|---|---:|---|
| Backend/API/database | Complete for planned backend scope | 98-100% | Phase 0-12, migrations/smokes, production health |
| Flutter backend wiring | Mostly complete; M10 awaits human acceptance | 90-95% | analyze/test/build/browser route pass |
| Demo data plan | Seeded across all major domains | 95-100% | slices 1-3 idempotent in production |
| Manual visual acceptance | Still required | 0-20% | screenshots exist, human walkthrough pending |
| Business/provider production readiness | Needs owner inputs | 30-50% | payments/providers/legal still dummy or pending |

## What is already functional

- Auth, KYC, upload/files, profile/portfolio, marketplace, saved search, shortlist.
- Projects, requirements, project room, bookings, negotiations, availability, chat.
- Contracts, signatures, legal reviews, addendums.
- Sandbox/manual payments, payment proofs, finance review, ledger, receipts, payout accounts.
- Location/equipment operations, inspections, damage claims, safety checks/incidents/check-ins.
- Insurance policies/claims/evidence.
- Agency, brand, model, and distribution specialist portals.
- Reviews, reports, blocks, moderation, disputes, support, announcements, notifications.
- Personal/admin dashboards, admin analytics, and supported CSV exports.

## What is not done / not fully accepted

- **Final human authenticated walkthrough:** A person still needs to log into Chrome/macOS/iPhone and visually confirm every seeded portal screen. Headless route screenshots passed, but that is not a human UX acceptance pass.
- **Real payment rails:** Manual bank transfer and card payment remain sandbox/dummy. Real bank details, gateway credentials, webhook secrets, settlement, refund, and chargeback rules are needed.
- **Production providers:** Object storage/CDN, email, SMS/OTP, Firebase push, monitoring, and backup destinations still need final credentials/configuration from the owner.
- **Legal/business policy copy:** Final Terms, Privacy, KYC/contract/payment/chat/safety/deleted-account retention, dispute policy, tax/invoice wording, and jurisdiction-specific legal text need approval.
- **Phone/address reveal policy:** The system has safe tokenized handling, but exact rules for when phone numbers and shoot addresses become visible still need final business sign-off.
- **Full production environment posture:** API is deployed and healthy, but payment mode and some provider integrations remain sandbox/manual; do not treat it as real-money production until those are replaced.

## What requires your input

| Input | Why needed |
|---|---|
| Bank transfer details | Bank name, account title, IBAN/account number, branch, reference rules, proof review SLA. |
| Card provider | Provider choice, test/live keys, webhook secret, fee/refund/chargeback policy. |
| Firebase push | Project ID, mobile app IDs, service account JSON, APNs/FCM setup. |
| Email provider | Sender domain, API/SMTP keys, SPF/DKIM/DMARC, support/reply-to inbox. |
| SMS/OTP provider | Provider account, sender ID, approved templates, routing/cost limits. |
| Object storage/CDN | Provider, buckets, access keys, public/private CDN domains, lifecycle retention. |
| Monitoring/backups | Sentry/monitoring DSN, backup destination, retention, restore-test schedule. |
| Legal docs | Terms/privacy/retention/dispute/tax/invoice wording. |
| Manual walkthrough | Confirm each portal visually using demo accounts. |

## Dummy / preview / fallback areas

| Area | Current behavior |
|---|---|
| Demo/offline fallback | Many `*_demo_data.dart` files intentionally remain as offline/error fallback. |
| Exports | Live exports support `bookings`, `ledger`, and `admin_disputes`; PDF/domain-specific export buttons are preview-only unless mapped to those. |
| Super Admin template/revenue settings | Some buttons remain preview/backend-gap because there are no deployed mutation endpoints. |
| Inspection/media/checklist previews | Some controls need live booking/property/provider/inspection/file IDs before safe mutation. |
| Brand/agency finance shortcuts | Some verification/payment shortcut controls are preview-only while list/read surfaces are live. |
| OTP/biometric | Demo OTP/biometric UI exists; real SMS/OTP/device-auth provider wiring requires credentials. |

## Demo data inserted

- Slice 1: 111 demo users, 220 synthetic ready files, 60 KYC submissions, 10 talent profiles/listings, 10 projects, requirements, project-room data, saved searches, shortlists, provider foundations, and 60 availability entries.
- Slice 2: 10 bookings, 30 offers, 10 negotiations, 100 chat messages, contracts, legal reviews, payment schedules/milestones/proofs/receipts/ledger/fee snapshots/payout accounts.
- Slice 3: operations, safety, insurance, agency, brand, distribution, reviews, reports, moderation, disputes, support, announcements, notifications, and export jobs.

## Automated validation evidence

- Headless browser walkthrough: `82` routes checked; screenshots in `docs/m10_walkthrough_screenshots`; error route count `0`.
- `flutter analyze`: pass.
- `flutter test --dart-define=CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1`: pass, 361/361.
- `flutter build web --dart-define=CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1`: pass.
- Production `/health/ready`: database OK, Redis OK.

## Portal-by-portal status

### Core/shared

- Splash
- Login
- Signup
- Forgot password
- Role selection
- Profile role switcher
- Settings logout
- KYC upload
- Verification status
- Shared notification center
- Shared ratings & review
- Shared report & block
- Shared payment proof upload
- Shared receipts ledger
- Shared contract viewer

### Director / Producer

- Director marketplace discovery
- Director shortlist board
- Director projects list
- Director create project wizard
- Director project detail
- Director requirement builder
- Director project room
- Director booking request
- Director bargaining center
- Director negotiation thread
- Director contract center
- Director payment center
- Booking chat

### Actor / Talent

- Actor/talent profile builder
- Actor/talent portfolio & showreel
- Actor/talent availability calendar
- Actor/talent opportunity inbox
- Actor/talent offer detail
- Actor/talent counteroffer composer
- Actor/talent contract signing
- Actor/talent earnings security
- Booking chat
- Shared contract viewer
- Shared receipts ledger

### Location Owner

- Location listing wizard

### Media / Equipment

- Media/equipment provider profile
- Media/equipment inventory manager

### Crew Services

- Crew home/profile/portfolio/availability/requests/contracts/ratings route rendering is covered by widget and headless browser route walkthrough; some crew-specific profile/portfolio proof controls remain preview fallback.

### Casting Agency

- Casting agency dashboard
- Casting agency roster
- Casting agency audition inbox

### Brand / Sponsor

- Brand dashboard
- Brand profile
- Brand opportunity composer

### Legal Partner

- Legal dashboard
- Legal review detail
- Legal template review
- Legal addendum review
- Legal review history/billing

### Insurance / Safety Partner

- Insurance dashboard
- Insurance shoot records
- Insurance claim support

### Distribution Partner

- Distribution dashboard
- Distribution contacts
- Distribution release coordination
- Distribution reporting

### Super Admin

- Super Admin payments hub
- Super Admin payment queue
- Super Admin payment review
- Super Admin receipts ledger
- Super Admin review hub
- Super Admin content moderation queue
- Super Admin dispute center
- Super Admin dispute case file
- Super Admin support CRM
- Super Admin broadcast announcements
- Super Admin dashboard
- Super Admin analytics
- Admin KYC queue
- Admin KYC detail
- Supported CSV exports

## Screen-level implementation table

| Screen | Route | Live backend consumer | Live/fallback status | Verification |
|---|---|---|---|---|
| Splash | `/` | `AuthController.bootstrap/refresh` | yes | analyze/widget suite |
| Login | `/login` | `AuthController.login` | yes | analyze/widget suite |
| Signup | `/signup` | `AuthController.register` | yes | analyze/widget suite |
| Forgot password | `/forgot-password` | `AuthController.forgotPassword` | partial | analyze/widget suite |
| Role selection | `/roles` | `AuthController.roles` | fallback | analyze/widget suite |
| Profile role switcher | `/profile/roles` | `AuthController.setPrimaryRole` | empty | analyze/widget suite |
| Settings logout | `/settings` | `AuthController.logout` | yes | analyze/widget suite |
| KYC upload | `/verification/upload` | `UploadRepository` via `AuthController.uploadFile`, then `AuthController.createAndSubmitKyc` | yes | analyze/widget suite + backend binary-flow integration |
| Verification status | `/verification/status` | `AuthController.myKycSubmissions` | yes | analyze/widget suite |
| Admin KYC queue | `/admin/verifications` | `AuthController.adminKycSubmissions` | yes | analyze/widget suite + HTTP smoke |
| Admin KYC detail | `/admin/verifications/:id` | `AuthController.adminKycSubmission/adminKycDecision` | yes | analyze/widget suite + HTTP smoke |
| Director marketplace discovery | `/director/marketplace` | `AuthController.marketplaceListings/createSavedSearch/addToDefaultShortlist` | yes, demo fallback | analyze/widget suite + HTTP smoke |
| Director shortlist board | `/director/shortlist` | `AuthController.shortlistBundle/deleteSavedSearch/updateShortlistItem/deleteShortlistItem` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Actor/talent profile builder | `/talent/profile` | `AuthController.cities/myProfile/talentProfile/updateMyProfile/updateTalentProfile/publishMarketplaceListing` | yes, local fallback | analyze/widget suite |
| Actor/talent portfolio & showreel | `/talent/portfolio` | `AuthController.portfolioItems/createPortfolioItem/updatePortfolioItem/deletePortfolioItem` plus `UploadRepository` via `AuthController.uploadFile` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Director projects list | `/director/projects` | `ProjectsScope.projects` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Director create project wizard | `/director/projects/create` | `ProjectsScope.createProject` | partial | analyze/widget suite + production HTTP smoke |
| Director project detail | `/director/projects/:id` | `ProjectsScope.project` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Director requirement builder | `/director/projects/:id/requirements` | `ProjectsScope.requirements/createRequirement` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Director project room | `/director/room` | `ProjectsScope.room/createRoomItem/linkProjectFile` plus `UploadRepository` via `AuthController.uploadFile` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Director booking request | `/director/booking-request` | `ProjectsScope.projects`, `AuthController.marketplaceListings`, `BookingsScope.createAndSendBooking` | partial, demo fallback | analyze/widget suite + production HTTP smoke |
| Director bargaining center | `/director/bargaining` | `BookingsScope.negotiations` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Director negotiation thread | `/director/negotiation` | `BookingsScope.negotiation/createCounterOffer/acceptOffer` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Actor/talent availability calendar | `/talent/availability` | `BookingsScope.availability/createAvailability` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Actor/talent opportunity inbox | `/talent/opportunities` | `BookingsScope.opportunities/acceptOffer` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Actor/talent offer detail | `/talent/offers/:id` | `BookingsScope.booking/acceptOffer/rejectBooking` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Actor/talent counteroffer composer | `/talent/counteroffer` | `BookingsScope.createCounterOffer` for live `BKG-*` ids | partial, demo fallback | analyze/widget suite + production HTTP smoke |
| Booking chat | `/booking/chat` | `BookingsScope.conversation/sendMessage/pinMessage` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Director contract center | `/director/contracts` | `ContractsScope.contracts/generateForBooking/requestLegalReview`, `BookingsScope.bookings` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Actor/talent contract signing | `/talent/contracts` | `ContractsScope.contracts` and shared contract viewer for signature/correction | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Shared contract viewer | `/contract` | `ContractsScope.contract/sign/createAddendum` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Legal dashboard | `/legal` | `ContractsScope.legalReviews` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Legal review detail | `/legal/contract-review` | `ContractsScope.legalReview/decideLegalReview` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Legal template review | `/legal/template-review` | `ContractsScope.templates` | partial, demo fallback | analyze/widget suite |
| Legal addendum review | `/legal/addendum-review` | `ContractsScope.contracts` addendum surface | partial, demo fallback | analyze/widget suite + production HTTP smoke |
| Legal review history/billing | `/legal/history-billing` | `ContractsScope.legalReviews` history surface | partial, demo fallback | analyze/widget suite + production HTTP smoke |
| Shared payment proof upload | `/payments/proof` | `PaymentsScope.schedules/submitProof` plus `UploadRepository` for `payment_proof` files | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Shared receipts ledger | `/payments/ledger` | `PaymentsScope.ledger` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Director payment center | `/director/payments` | `PaymentsScope.dashboard` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Actor/talent earnings security | `/talent/earnings` | `PaymentsScope.dashboard/payoutAccounts/createSandboxPayoutAccount` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Super Admin payments hub | `/admin/payments` | `PaymentsScope.adminProofs/ledger` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Super Admin payment queue | `/admin/payment-queue` | `PaymentsScope.adminProofs` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Super Admin payment review | `/admin/payment-review/:id` | `PaymentsScope.adminProof/decideProof` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Super Admin receipts ledger | `/admin/payments/ledger` | shared ledger rows plus existing admin ledger filters | demo fallback | analyze/widget suite |
| Location listing wizard | `/location-owner/listing-wizard` | `OperationsScope.createLocationProperty/createLocationSpace/createLocationPricing/createLocationRule` | partial, demo fallback | analyze/widget suite + production HTTP smoke |
| Media/equipment provider profile | `/media-equipment/provider-profile` | `OperationsScope.equipmentProfile/upsertEquipmentProfile` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Media/equipment inventory manager | `/media-equipment/inventory` | `OperationsScope.equipmentItems/createEquipmentItem` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Insurance dashboard | `/insurance` | `InsuranceScope.dashboard` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Insurance shoot records | `/insurance/records` | `InsuranceScope.policies` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Insurance claim support | `/insurance/claims` | `InsuranceScope.claims/decideClaim` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Casting agency dashboard | `/agency` | `SpecialistScope.agencyProfile/auditions` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Casting agency roster | `/agency/roster` | `SpecialistScope.agencyRoster` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Casting agency audition inbox | `/agency/auditions` | `SpecialistScope.auditions/updateAuditionStatus` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Brand dashboard | `/brand` | `SpecialistScope.brandProfile/brandOpportunities` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Brand profile | `/brand/profile` | `SpecialistScope.brandProfile/upsertBrandProfile` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Brand opportunity composer | `/brand/opportunity-composer` | `SpecialistScope.createBrandOpportunity` | partial, demo fallback | analyze/widget suite + production HTTP smoke |
| Model campaign categories | `/model` | `SpecialistScope.modelProfile/updateModelCampaignCategories` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Model usage rights | `/model/usage-rights` | `SpecialistScope.modelUsageRights/createModelUsageRight` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Model usage rates | `/model/rate-by-usage` | `SpecialistScope.modelUsageRates/createModelUsageRate` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Model brand safety | `/model/brand-safety` | `SpecialistScope.modelRestrictedCategories/updateModelRestrictedCategories` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Distribution dashboard | `/distribution` | `SpecialistScope.distributionProfile/distributionProjects` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Distribution contacts | `/distribution/contacts` | `SpecialistScope.distributorContacts` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Distribution release coordination | `/distribution/release` | `SpecialistScope.distributionProjects/updateDistributionProject` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Distribution reporting | `/distribution/reports` | `SpecialistScope.distributionReports` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Shared notification center | `/notifications` | `TrustSafetyScope.notifications/markNotificationRead/markAllNotificationsRead` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Shared ratings & review | `/review` | `TrustSafetyScope.createReview/createReport` for live booking ids | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Shared report & block | `/report` | `TrustSafetyScope.reportReasons/createReport/blockUser` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Super Admin review hub | `/admin/review-hub` | `TrustSafetyScope.adminModerationCases/adminDisputes/adminSupportTickets` live summary | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Super Admin content moderation queue | `/admin/content-moderation` | `TrustSafetyScope.adminModerationCases/decideModerationCase` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Super Admin dispute center | `/admin/disputes` | `TrustSafetyScope.adminDisputes/decideDispute` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Super Admin dispute case file | `/admin/disputes/:id` | `TrustSafetyScope.adminDisputes/decideDispute` live decision strip | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Super Admin support CRM | `/admin/support` | `TrustSafetyScope.adminSupportTickets/updateSupportTicket/createSupportMessage` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Super Admin broadcast announcements | `/admin/broadcasts` | `TrustSafetyScope.announcements/createAnnouncement/publishAnnouncement` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Portal dashboard KPI strips | main portal dashboards | `AnalyticsScope.personalDashboard` via `/me/dashboard` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Super Admin dashboard | `/admin/dashboard` | `AnalyticsScope.adminDashboard` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Super Admin analytics | `/admin/analytics` | `AnalyticsScope.adminAnalytics/createExport(admin_disputes)` | yes, demo fallback | analyze/widget suite + production HTTP smoke |
| Supported CSV exports | report/ledger/admin CSV actions | `AnalyticsScope.createExport/export/exports` for `bookings`, `ledger`, `admin_disputes` | yes, live error fallback | analyze/widget suite + production HTTP smoke |

## App demo login accounts

All demo accounts below use password: `CineDemo@2026!`.

### super_admin

| Public ID | Display name | Email | Password |
|---|---|---|---|
| DEMO-ADMIN-001 | CineConnect Demo Admin | `demo.admin@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |

### director_producer

| Public ID | Display name | Email | Password |
|---|---|---|---|
| DEMO-DP-001 | Sara Nadeem | `dp01@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DP-002 | Hamza Rafiq | `dp02@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DP-003 | Noor Khan | `dp03@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DP-004 | Bilal Qureshi | `dp04@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DP-005 | Mahnoor Ali | `dp05@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DP-006 | Umer Siddiqui | `dp06@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DP-007 | Daniyal Hussain | `dp07@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DP-008 | Amina Farooq | `dp08@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DP-009 | Kamil Ahmed | `dp09@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DP-010 | Reema Iqbal | `dp10@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |

### actor_talent

| Public ID | Display name | Email | Password |
|---|---|---|---|
| DEMO-AT-001 | Ayaan Malik | `talent01@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-AT-002 | Meher Shah | `talent02@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-AT-003 | Zain Javed | `talent03@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-AT-004 | Hira Salman | `talent04@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-AT-005 | Faris Sheikh | `talent05@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-AT-006 | Sana Mirza | `talent06@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-AT-007 | Omar Rehman | `talent07@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-AT-008 | Laila Noor | `talent08@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-AT-009 | Mariam Tariq | `talent09@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-AT-010 | Taha Baig | `talent10@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |

### model

| Public ID | Display name | Email | Password |
|---|---|---|---|
| DEMO-MD-001 | Demo Model 01 | `model01@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-MD-002 | Demo Model 02 | `model02@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-MD-003 | Demo Model 03 | `model03@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-MD-004 | Demo Model 04 | `model04@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-MD-005 | Demo Model 05 | `model05@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-MD-006 | Demo Model 06 | `model06@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-MD-007 | Demo Model 07 | `model07@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-MD-008 | Demo Model 08 | `model08@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-MD-009 | Demo Model 09 | `model09@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-MD-010 | Demo Model 10 | `model10@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |

### location_owner

| Public ID | Display name | Email | Password |
|---|---|---|---|
| DEMO-LO-001 | Haveli Gulberg Owner | `location01@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LO-002 | Saddar Rooftop Owner | `location02@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LO-003 | Margalla Farmhouse Owner | `location03@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LO-004 | Old City Street Set Owner | `location04@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LO-005 | Coastal Warehouse Owner | `location05@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LO-006 | University Courtyard Owner | `location06@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LO-007 | Bazaar Backlot Owner | `location07@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LO-008 | Studio Kitchen Owner | `location08@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LO-009 | Hospital Training Wing Owner | `location09@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LO-010 | Desert Fort Owner | `location10@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |

### equipment_provider

| Public ID | Display name | Email | Password |
|---|---|---|---|
| DEMO-ME-001 | Alexa Mini LF Kit Provider | `equipment01@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-ME-002 | Sony FX6 Doc Kit Provider | `equipment02@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-ME-003 | Drone + Gimbal Pack Provider | `equipment03@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-ME-004 | Lighting Sprint Pack Provider | `equipment04@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-ME-005 | Documentary Sound Kit Provider | `equipment05@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-ME-006 | Multi-cam Podcast Kit Provider | `equipment06@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-ME-007 | Low-light Cinema Kit Provider | `equipment07@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-ME-008 | Tabletop Food Kit Provider | `equipment08@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-ME-009 | Compact ENG Kit Provider | `equipment09@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-ME-010 | Remote Production Kit Provider | `equipment10@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |

### crew_service

| Public ID | Display name | Email | Password |
|---|---|---|---|
| DEMO-CR-001 | 1st AD Team | `crew01@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CR-002 | Location Sound | `crew02@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CR-003 | Drone Operator | `crew03@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CR-004 | Choreography Crew | `crew04@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CR-005 | Documentary Fixer | `crew05@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CR-006 | Multi-cam Operators | `crew06@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CR-007 | Night Lighting Crew | `crew07@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CR-008 | Food Stylist Team | `crew08@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CR-009 | Safety Marshal | `crew09@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CR-010 | Remote Production Coordinator | `crew10@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |

### casting_agency

| Public ID | Display name | Email | Password |
|---|---|---|---|
| DEMO-CA-001 | North Star Casting | `agency01@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CA-002 | Karachi Screen Faces | `agency02@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CA-003 | AdCast Studio | `agency03@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CA-004 | Rhythm Casting | `agency04@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CA-005 | Real People Network | `agency05@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CA-006 | Campus Talent Desk | `agency06@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CA-007 | Character Room | `agency07@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CA-008 | Lifestyle Hosts PK | `agency08@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CA-009 | Public Impact Casting | `agency09@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-CA-010 | OTT Launch Casting | `agency10@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |

### brand_sponsor

| Public ID | Display name | Email | Password |
|---|---|---|---|
| DEMO-BR-001 | Nova Cola | `brand01@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-BR-002 | Zest Telecom | `brand02@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-BR-003 | Orion Bank | `brand03@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-BR-004 | Naya Wear | `brand04@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-BR-005 | TravelPK | `brand05@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-BR-006 | ByteCafe | `brand06@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-BR-007 | Indie Fund | `brand07@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-BR-008 | Masala House | `brand08@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-BR-009 | InsurePro | `brand09@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-BR-010 | StreamSphere | `brand10@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |

### legal_partner

| Public ID | Display name | Email | Password |
|---|---|---|---|
| DEMO-LG-001 | Legal Partner 01 | `legal01@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LG-002 | Legal Partner 02 | `legal02@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LG-003 | Legal Partner 03 | `legal03@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LG-004 | Legal Partner 04 | `legal04@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LG-005 | Legal Partner 05 | `legal05@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LG-006 | Legal Partner 06 | `legal06@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LG-007 | Legal Partner 07 | `legal07@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LG-008 | Legal Partner 08 | `legal08@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LG-009 | Legal Partner 09 | `legal09@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-LG-010 | Legal Partner 10 | `legal10@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |

### insurance_partner

| Public ID | Display name | Email | Password |
|---|---|---|---|
| DEMO-IN-001 | Insurance Partner 01 | `insurance01@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-IN-002 | Insurance Partner 02 | `insurance02@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-IN-003 | Insurance Partner 03 | `insurance03@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-IN-004 | Insurance Partner 04 | `insurance04@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-IN-005 | Insurance Partner 05 | `insurance05@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-IN-006 | Insurance Partner 06 | `insurance06@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-IN-007 | Insurance Partner 07 | `insurance07@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-IN-008 | Insurance Partner 08 | `insurance08@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-IN-009 | Insurance Partner 09 | `insurance09@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-IN-010 | Insurance Partner 10 | `insurance10@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |

### distribution_partner

| Public ID | Display name | Email | Password |
|---|---|---|---|
| DEMO-DS-001 | Distribution Partner 01 | `distribution01@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DS-002 | Distribution Partner 02 | `distribution02@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DS-003 | Distribution Partner 03 | `distribution03@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DS-004 | Distribution Partner 04 | `distribution04@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DS-005 | Distribution Partner 05 | `distribution05@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DS-006 | Distribution Partner 06 | `distribution06@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DS-007 | Distribution Partner 07 | `distribution07@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DS-008 | Distribution Partner 08 | `distribution08@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DS-009 | Distribution Partner 09 | `distribution09@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |
| DEMO-DS-010 | Distribution Partner 10 | `distribution10@demo.cine.nalexustechnologies.com` | `CineDemo@2026!` |

## Recommended manual walkthrough order

1. Log in as Super Admin and check dashboard, KYC, payments, moderation, disputes, support, broadcasts, analytics, exports.
2. Log in as Director/Producer and check projects, marketplace, shortlist, booking, bargaining, contracts, payments, room, reports.
3. Log in as Actor/Talent and check profile, portfolio, availability, opportunities, contracts, earnings, reputation, safety.
4. Smoke one account from each provider portal: model, location, equipment, crew, agency, brand, legal, insurance, distribution.
5. Mark any screen that shows fallback-only data where live seeded data should appear, then patch that specific screen/controller.

## Final recommendation

Ready for controlled manual demo walkthrough. Not ready for real-money/public production launch until owner inputs, provider credentials, legal copy, and human visual acceptance are complete.