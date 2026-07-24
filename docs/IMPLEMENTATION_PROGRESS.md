# CineConnect Implementation Progress

## Current status

- Current master-report version: 1.0
- Current phase: Other portals database-only perfection
- Current vertical slice: P0/P1 audit complete; P2 latest pulled backend APIs and brand conversation migration deployed to production; next is P3 Super Admin static-data removal/API completion
- Overall status: Phases 0, 1, 2, and 3 complete locally; Phase 4 profile/marketplace/portfolio/saved-search/shortlist foundation complete locally; Phase 5 projects/requirements/skills and project-room files/decisions foundation complete locally; Phase 6 booking/offer/counter/accept, booking inbox, manual availability blocks, availability lock, and conversation foundation complete locally; Phase 7 contract generation, signatures, legal review queue/decision, and addendum foundation complete locally; Phase 8 sandbox payment schedules, proof review, ledger, receipts, and payout-account foundation complete locally; Phase 9 location/equipment inspections, damage claims, safety checks/incidents/check-ins, **and insurance partner/policy/claim/evidence** backend now fully complete locally and in production (the insurance tables were missed in the original 2026-07-17 Phase 9 pass and closed out 2026-07-18); Phase 10 casting agency roster/audition/self-tape/notes/commission, brand opportunity/application/terms/deliverable/metrics, model rights/rates/restrictions, and distribution contact/release/handover/report foundation complete locally; Phase 11 reviews/dimensions/requests, reports/blocks, moderation cases/events, disputes/evidence/events, support tickets/messages, and announcements/notifications foundation complete locally; Phase 12 personal/admin dashboards, admin analytics, synchronous CSV export jobs, Sentry wiring, production DB backups, and a dependency security patch complete locally and deployed to production
- Last updated: 2026-07-24
- Updated by: Codex

## Environment status

- Local backend: Flask/Gunicorn container healthy on port 5000
- SQL database: local MySQL 8.4 healthy; production Percona Server for MySQL 8.4.7 migrated through M0 local storage migration `a7b8c9d0e1f2`
- Redis: local Redis 7 integration-tested; production Redis 7 active, cineconnect using DB 3/4/5 to avoid collisions with other apps on the shared instance
- Celery worker: local worker and scheduler healthy; production `cineconnect-worker`/`cineconnect-scheduler` Docker containers healthy (confirmed 2026-07-18)
- Object storage: local-disk upload storage selected for M0; local compose uses `backend/.storage`, production should use `/var/www/cineconnect/storage/{private,public}` with `/media/` Nginx alias
- Flutter API configuration: default API endpoint is `https://cine.nalexustechnologies.com/api/v1`; override remains available through `CINECONNECT_API_BASE_URL`
- Staging: blocked on staging domain/environment decision
- Production: DNS and HTTPS ready; backend API deployed 2026-07-18 to `https://cine.nalexustechnologies.com/api/v1` via Docker (`--network host`) behind the existing Nginx vhost, running with `APP_ENV=staging` because payment mode remains sandbox/manual. Flutter web is now deployed on the same live domain root `https://cine.nalexustechnologies.com` with `/api/` preserved for API proxying and `/media/` preserved for public uploaded media. External HTTPS smoke tests pass, including M2 project/requirement/room/file upload, M3 booking/negotiation/chat, M4 contract/signature/legal-review, M5 payment-proof/finance-ledger, M6 location/equipment/safety/insurance, M7 agency/brand/model/distribution specialist flows, M8 review/report/moderation/dispute/support/announcement/notification flows, and M9 personal/admin dashboards plus CSV exports. Production env was corrected on 2026-07-18 to use host-network-safe `127.0.0.1` MySQL/Redis URLs, `API_PUBLIC_URL=https://cine.nalexustechnologies.com`, and explicit CORS origins for the live Flutter domain plus local browser walkthrough origins.

## Phase checklist

- [x] Phase 0 — Confirm inputs and freeze contracts
- [x] Phase 1 — Backend foundation
- [x] Phase 2 — Identity and Flutter API foundation
- [x] Phase 3 — KYC, files, and admin verification
- [ ] Phase 4 — Profiles and marketplace
- [ ] Phase 5 — Projects, requirements, and project room
- [ ] Phase 6 — Booking, negotiation, calendars, and chat
- [ ] Phase 7 — Contracts and legal
- [ ] Phase 8 — Payments and finance
- [ ] Phase 9 — Location, equipment, and safety workflows
- [ ] Phase 10 — Agency, brand, model, and distribution extensions
- [ ] Phase 11 — Reviews, moderation, disputes, support, communications
- [ ] Phase 12 — Analytics, exports, hardening, and production

## Database migrations

| Revision | Description | Applied locally | Applied staging | Applied production |
|---|---|---:|---:|---:|
| `efc80f32cc35` | MySQL-compatible foundation baseline | yes | no | yes |
| `5b0e3a1f7c2d` | Identity, access, roles, sessions, reset tokens, preferences, and auth audit events | yes | no | yes |
| `9c1d4f8a2b67` | Files, upload sessions, KYC submissions/documents, and verification events | yes | no | yes |
| `2f4a6b8c9d10` | Hidden admin roles, `kyc.review` permission, and reviewer/super-admin grants | yes | no | yes |
| `7d2e5f6a8b90` | Countries, cities, base user profiles, talent profiles/languages, and public marketplace listings | yes | no | yes |
| `8e3b7c9d1a20` | Portfolio items and listing media attachments | yes | no | yes |
| `9a4b6c7d8e30` | Saved searches, shortlists, and shortlist items | yes | no | yes |
| `a1b2c3d4e5f6` | Projects, project members, project requirements, requirement skills, and skill catalog | yes | no | yes |
| `b2c3d4e5f6a7` | Project files and project room items | yes | no | yes |
| `c3d4e5f6a7b8` | Bookings, participants, offers, negotiations, availability calendars/entries, conversations, messages, attachments, and pinned decisions | yes | no | yes |
| `d4e5f6a7b8c9` | Contract templates/clauses, contracts, contract parties/clauses/signatures/addendums, legal reviews/risks, and legal billing records | yes | no | yes |
| `e5f6a7b8c9d0` | Payment schedules/milestones/transactions/proofs, receipts, ledger entries, fee rules/snapshots, payout accounts, and payouts | yes | no | yes |
| `f6a7b8c9d0e1` | Location properties/spaces/pricing/rules/inspections, damage claims/evidence, equipment provider inventory/packages/terms/inspections, safety checks/incidents/check-ins | yes | no | yes |
| `f32946609750` | Casting agencies/invitations/roster/auditions/candidates/self-tapes/selection-notes/commissions, brand profiles/opportunities/applications/terms/campaign deliverables/metrics, model profiles/campaign-categories/usage-rights/usage-rates/restricted-categories, distribution partner profiles/projects/contacts/handover-items/release-windows/reports | yes | no | yes |
| `de636c6a400c` | Reviews/dimensions/requests, blocked users, reports, moderation cases/events, disputes/evidence/events, support tickets/messages, announcements, notifications/deliveries, push devices | yes | no | yes |
| `81af73d41ffc` | Export jobs (synchronous CSV export records) | yes | no | yes |
| `0f25fa31c34f` | Insurance partner profiles, policies, claims, and claim evidence (Phase 9 gap closed) | yes | no | yes |
| `a7b8c9d0e1f2` | Local-disk binary upload receipt metadata (`binary_received_at`, server-computed size/checksum) | yes | no | yes |
| `b8c9d0e1f2a3` | Director project cover file reference (`projects.cover_file_id`) | yes | no | yes |
| `c4d5e6f7a8b9` | Brand application conversations, rejection reasons, and campaign deliverable revision notes | yes | no | yes |

## Completed endpoints

| Method | Path | Auth/policy | Tests | Flutter consumer |
|---|---|---|---:|---|
| GET | `/api/v1/health/live` | public | yes | none |
| GET | `/api/v1/health/ready` | public, dependency-safe | yes | none |
| GET | `/api/v1/app/bootstrap` | public | yes | splash |
| GET | `/api/v1/app/public-config` | public | yes | pending onboarding |
| GET | `/api/v1/roles` | public | yes | role selection |
| GET | `/api/v1/openapi.yaml` | public | yes | none |
| POST | `/api/v1/auth/register` | public, rate-limited | yes | signup |
| POST | `/api/v1/auth/login` | public, rate-limited | yes | login |
| POST | `/api/v1/auth/refresh` | public, rotating refresh token | yes | splash/session restore |
| POST | `/api/v1/auth/logout` | public token revocation | yes | settings/logout |
| POST | `/api/v1/auth/password/forgot` | public, enumeration-safe | yes | forgot password |
| POST | `/api/v1/auth/password/reset` | public reset token | yes | pending forgot password |
| GET | `/api/v1/me` | bearer JWT | yes | session/profile |
| GET | `/api/v1/me/roles` | bearer JWT | yes | role switcher |
| POST | `/api/v1/me/roles` | bearer JWT | yes | role selection |
| PATCH | `/api/v1/me/primary-role` | bearer JWT, granted role only | yes | role switcher |
| POST | `/api/v1/uploads/presign` | bearer JWT, rate-limited | yes | KYC upload |
| PUT | `/api/v1/uploads/{id}/binary` | bearer JWT, owner only, rate-limited | yes | KYC upload |
| POST | `/api/v1/uploads/{id}/complete` | bearer JWT, owner only, requires received bytes | yes | KYC upload |
| GET | `/api/v1/files/{id}/download` | bearer JWT, owner only | yes | pending admin/user file preview |
| POST | `/api/v1/kyc/submissions` | bearer JWT, granted role only | yes | KYC upload |
| POST | `/api/v1/kyc/submissions/{id}/submit` | bearer JWT, owner only | yes | KYC upload |
| GET | `/api/v1/me/kyc` | bearer JWT, owner only | yes | verification status |
| POST | `/api/v1/kyc/submissions/{id}/resubmit` | bearer JWT, owner only | yes | pending verification status |
| GET | `/api/v1/admin/kyc/submissions` | bearer JWT, `kyc.review` | yes | admin verification queue |
| GET | `/api/v1/admin/kyc/submissions/{id}` | bearer JWT, `kyc.review` | yes | admin verification detail |
| POST | `/api/v1/admin/kyc/submissions/{id}/decision` | bearer JWT, `kyc.review` | yes | admin verification detail |
| GET | `/api/v1/cities` | public | yes | marketplace/profile city pickers |
| GET | `/api/v1/me/profile` | bearer JWT | yes | actor/talent profile builder |
| PATCH | `/api/v1/me/profile` | bearer JWT, owner only | yes | actor/talent profile builder |
| GET | `/api/v1/talent/profile` | bearer JWT, actor talent role | yes | actor/talent profile builder |
| PATCH | `/api/v1/talent/profile` | bearer JWT, actor talent role | yes | actor/talent profile builder |
| GET | `/api/v1/portfolio` | bearer JWT, talent profile required | yes | actor/talent portfolio |
| POST | `/api/v1/portfolio` | bearer JWT, owner clean/ready file required | yes | actor/talent portfolio |
| PATCH | `/api/v1/portfolio/{id}` | bearer JWT, owner only | yes | actor/talent portfolio |
| DELETE | `/api/v1/portfolio/{id}` | bearer JWT, owner only | yes | actor/talent portfolio |
| GET | `/api/v1/saved-searches` | bearer JWT, owner only | yes | director marketplace discovery |
| POST | `/api/v1/saved-searches` | bearer JWT, owner only | yes | director marketplace discovery |
| DELETE | `/api/v1/saved-searches/{id}` | bearer JWT, owner only | yes | pending saved-search management |
| GET | `/api/v1/shortlists` | bearer JWT, owner only | yes | director marketplace discovery |
| POST | `/api/v1/shortlists` | bearer JWT, owner only | yes | director marketplace discovery |
| POST | `/api/v1/shortlists/{id}/items` | bearer JWT, owner only, public listing required | yes | director marketplace discovery |
| PATCH | `/api/v1/shortlist-items/{id}` | bearer JWT, owner only | yes | pending shortlist board |
| DELETE | `/api/v1/shortlist-items/{id}` | bearer JWT, owner only | yes | pending shortlist board |
| GET | `/api/v1/skills` | bearer JWT, active catalog only | yes | pending requirement builder |
| GET | `/api/v1/projects` | bearer JWT, active project member only | yes | pending projects list |
| POST | `/api/v1/projects` | bearer JWT, director/producer or casting agency role required | yes | pending create project wizard |
| GET | `/api/v1/projects/{id}` | bearer JWT, active project member only | yes | pending project detail |
| PATCH | `/api/v1/projects/{id}` | bearer JWT, project owner only | yes | pending create/detail screens |
| GET | `/api/v1/projects/{id}/members` | bearer JWT, active project member only | yes | pending project room |
| GET | `/api/v1/projects/{id}/room` | bearer JWT, active project member only | yes | pending project room |
| POST | `/api/v1/projects/{id}/room/items` | bearer JWT, active project member only | yes | pending project room |
| GET | `/api/v1/projects/{id}/files` | bearer JWT, active project member only | yes | pending project room |
| POST | `/api/v1/projects/{id}/files` | bearer JWT, active project member only, owner clean/ready file required | yes | pending project room |
| GET | `/api/v1/projects/{id}/requirements` | bearer JWT, active project member only | yes | pending requirement builder |
| POST | `/api/v1/projects/{id}/requirements` | bearer JWT, active project member only | yes | pending requirement builder |
| PATCH | `/api/v1/requirements/{id}` | bearer JWT, active project member only | yes | pending requirement builder |
| POST | `/api/v1/marketplace/listings` | bearer JWT, approved actor-talent KYC required for talent listing | yes | actor/talent profile builder publish action |
| GET | `/api/v1/marketplace/listings` | public, approved/public listings only | yes | director/producer marketplace discovery |
| GET | `/api/v1/marketplace/listings/{id}` | public, approved/public listings only | yes | pending marketplace detail |
| POST | `/api/v1/marketplace/result-count` | public | yes | filters/result count |
| GET | `/api/v1/marketplace/facets` | public | yes | pending marketplace filters |
| GET | `/api/v1/availability` | bearer JWT, current user's calendar only | yes | AT-04 availability calendar |
| POST | `/api/v1/availability` | bearer JWT, current user's calendar only, overlap-protected holds/blocks | yes | AT-04 availability calendar |
| PATCH | `/api/v1/availability/{id}` | bearer JWT, current user's manual entry only | yes | pending availability screens |
| DELETE | `/api/v1/availability/{id}` | bearer JWT, current user's manual entry only | yes | pending availability screens |
| POST | `/api/v1/availability/check` | public conflict check by owner/time range | yes | pending richer booking request conflict preview |
| GET | `/api/v1/bookings` | bearer JWT, booking participant only, optional role/status filters | yes | `BookingsController` cache for booking flows |
| POST | `/api/v1/bookings` | bearer JWT, project member requester, public listing provider, conflict check | yes | DP-10 booking request |
| GET | `/api/v1/bookings/{id}` | bearer JWT, booking participant only | yes | AT-07 offer detail |
| POST | `/api/v1/bookings/{id}/send` | bearer JWT, requester only, draft only | yes | DP-10 booking request |
| GET | `/api/v1/negotiations` | bearer JWT, booking participant only | yes | DP-11 bargaining center |
| GET | `/api/v1/negotiations/{id}` | bearer JWT, booking participant only | yes | DP-12 negotiation thread |
| POST | `/api/v1/bookings/{id}/offers` | bearer JWT, participant only, open negotiation states | yes | DP-12 negotiation thread; AT-08 counteroffer composer |
| POST | `/api/v1/offers/{id}/accept` | bearer JWT, offer recipient only, active offer only, conflict check and calendar lock | yes | DP-12 negotiation thread; AT-06/AT-07 accept actions |
| POST | `/api/v1/bookings/{id}/reject` | bearer JWT, participant only, pre-secured mutable states | yes | AT-07 offer detail |
| GET | `/api/v1/talent/opportunities` | bearer JWT, provider-side participant only | yes | AT-06 opportunity inbox |
| GET | `/api/v1/conversations/{id}/messages` | bearer JWT, conversation member only | yes | core booking chat |
| POST | `/api/v1/conversations/{id}/messages` | bearer JWT, conversation member only, ready owned attachments only | yes | core booking chat |
| POST | `/api/v1/messages/{id}/pin` | bearer JWT, conversation member only | yes | core booking chat |
| GET | `/api/v1/contract-templates` | public published templates only | yes | pending contract viewer |
| GET | `/api/v1/contracts` | bearer JWT, current user's contract party records only | yes | pending contract inbox |
| POST | `/api/v1/bookings/{id}/contracts` | bearer JWT, accepted booking requester only, one contract per booking | yes | pending booking-to-contract action |
| GET | `/api/v1/contracts/{id}` | bearer JWT, contract party only | yes | pending contract viewer |
| POST | `/api/v1/contracts/{id}/signatures` | bearer JWT, contract party only, one signature per party | yes | pending contract signature UI |
| POST | `/api/v1/contracts/{id}/addendums` | bearer JWT, contract party only, queues legal review | yes | pending addendum UI |
| POST | `/api/v1/legal-reviews` | bearer JWT, visible contract party only | yes | pending legal review request |
| GET | `/api/v1/legal/reviews` | bearer JWT, legal partner/reviewer/super-admin only | yes | pending legal dashboard |
| GET | `/api/v1/legal-reviews/{id}` | bearer JWT, requester or legal role only | yes | pending legal dashboard |
| POST | `/api/v1/legal-reviews/{id}/decision` | bearer JWT, legal partner/reviewer/super-admin only, creates draft billing record | yes | pending legal review decision |
| GET | `/api/v1/payments/dashboard` | bearer JWT, payer/payee finance summary only | yes | pending payment center |
| GET | `/api/v1/payment-schedules` | bearer JWT, booking payer/payee only, optional booking filter | yes | pending payment center |
| GET | `/api/v1/payment-schedules/{id}` | bearer JWT, booking payer/payee only | yes | pending payment center |
| POST | `/api/v1/payment-proofs` | bearer JWT, booking payer only, idempotent sandbox manual/card proof | yes | pending payment proof upload |
| GET | `/api/v1/ledger` | bearer JWT, current user's ledger entries only | yes | pending receipts ledger |
| GET | `/api/v1/receipts/{id}` | bearer JWT, issued-to user only | yes | pending receipt viewer |
| GET | `/api/v1/payout-accounts` | bearer JWT, current user's payout accounts only | yes | pending earnings security |
| POST | `/api/v1/payout-accounts` | bearer JWT, sandbox/bank/wallet metadata only | yes | pending earnings security |
| GET | `/api/v1/admin/payment-proofs` | bearer JWT, finance-admin/reviewer/super-admin only | yes | admin payment queue |
| GET | `/api/v1/admin/payment-proofs/{id}` | bearer JWT, finance-admin/reviewer/super-admin only | yes | admin payment review |
| POST | `/api/v1/admin/payment-proofs/{id}/decision` | bearer JWT, finance-admin/reviewer/super-admin only; approval posts ledger/receipt and secures booking | yes | admin payment review |
| GET | `/api/v1/location-properties` | bearer JWT, current owner only | yes | pending location owner dashboard |
| POST | `/api/v1/location-properties` | bearer JWT, private address tokenized/not returned | yes | pending listing wizard |
| POST | `/api/v1/location-properties/{id}/spaces` | bearer JWT, property owner only | yes | pending listing wizard |
| POST | `/api/v1/location-properties/{id}/pricing` | bearer JWT, property owner only | yes | pending pricing/deposit |
| POST | `/api/v1/location-properties/{id}/rules` | bearer JWT, property owner only | yes | pending rules UI |
| POST | `/api/v1/location-inspections` | bearer JWT, booking requester or property owner | yes | pending check-in/out inspection |
| POST | `/api/v1/location-inspections/{id}/items` | bearer JWT, inspection participant only, ready owned files only | yes | pending inspection capture |
| POST | `/api/v1/location-inspections/{id}/confirm` | bearer JWT, property owner/requester dual confirmation | yes | pending inspection signature |
| POST | `/api/v1/damage-claims` | bearer JWT, booking participant only | yes | pending damage claim UI |
| POST | `/api/v1/damage-claims/{id}/evidence` | bearer JWT, claim party only, ready owned files only | yes | pending damage evidence |
| GET | `/api/v1/equipment/provider-profile` | bearer JWT, current provider only | yes | pending equipment profile |
| PATCH | `/api/v1/equipment/provider-profile` | bearer JWT, current provider upsert | yes | pending equipment profile |
| GET | `/api/v1/equipment/items` | bearer JWT, current provider inventory only | yes | pending inventory |
| POST | `/api/v1/equipment/items` | bearer JWT, provider profile required, serial tokenized/not returned | yes | pending inventory |
| POST | `/api/v1/equipment/packages` | bearer JWT, provider profile required | yes | pending package builder |
| POST | `/api/v1/equipment/packages/{id}/items` | bearer JWT, package owner only | yes | pending package builder |
| POST | `/api/v1/equipment/terms` | bearer JWT, provider profile required | yes | pending equipment terms |
| POST | `/api/v1/equipment-inspections` | bearer JWT, booking requester or equipment provider | yes | pending handover/return |
| POST | `/api/v1/equipment-inspections/{id}/items` | bearer JWT, inspection participant only | yes | pending handover checklist |
| POST | `/api/v1/equipment-inspections/{id}/confirm` | bearer JWT, provider/requester dual confirmation | yes | pending handover signature |
| POST | `/api/v1/safety-checks` | bearer JWT, active project member only | yes | pending safety checks |
| POST | `/api/v1/safety-checks/{id}/items` | bearer JWT, responsible user only | yes | pending safety checklist |
| POST | `/api/v1/incidents` | bearer JWT, active project member only | yes | pending incident reports |
| POST | `/api/v1/safety-check-ins` | bearer JWT, booking participant only | yes | pending talent safety controls |
| POST | `/api/v1/safety-check-ins/{id}/complete` | bearer JWT, check-in owner only, coordinates tokenized/not returned | yes | pending talent safety controls |
| GET | `/api/v1/agencies/profile` | bearer JWT, current owner only | yes | pending agency profile screen |
| PATCH | `/api/v1/agencies/profile` | bearer JWT, current owner upsert | yes | pending agency profile screen |
| POST | `/api/v1/agency-invitations` | bearer JWT, agency owner only | yes | pending agency roster screen |
| GET | `/api/v1/agency-invitations` | bearer JWT, agency owner only | yes | pending agency roster screen |
| POST | `/api/v1/agency-invitations/{id}/accept` | bearer JWT, invited talent only, auto-creates talent profile link | yes | pending talent invitation inbox |
| GET | `/api/v1/agencies/{id}/talent` | bearer JWT, agency owner only | yes | pending agency roster screen |
| POST | `/api/v1/auditions` | bearer JWT, active project member requester | yes | pending audition inbox |
| GET | `/api/v1/auditions` | bearer JWT, agency owner or requesting director | yes | pending audition inbox |
| PATCH | `/api/v1/auditions/{id}` | bearer JWT, agency owner or requesting director | yes | pending audition inbox |
| POST | `/api/v1/auditions/{id}/candidates` | bearer JWT, agency owner only | yes | pending shortlist builder |
| PATCH | `/api/v1/audition-candidates/{id}` | bearer JWT, agency owner or requesting director, field-scoped by role | yes | pending shortlist builder |
| POST | `/api/v1/self-tapes` | bearer JWT, candidate talent owner only, ready owned file required | yes | pending self-tape collection |
| POST | `/api/v1/audition-candidates/{id}/notes` | bearer JWT, agency owner or requesting director | yes | pending selection notes screen |
| POST | `/api/v1/agency-commissions` | bearer JWT, agency owner only | yes | pending commission records |
| GET | `/api/v1/agencies/{id}/commissions` | bearer JWT, agency owner only | yes | pending commission records |
| GET | `/api/v1/brands/profile` | bearer JWT, current owner only | yes | pending brand profile screen |
| PATCH | `/api/v1/brands/profile` | bearer JWT, current owner upsert | yes | pending brand profile screen |
| POST | `/api/v1/brand-opportunities` | bearer JWT, brand owner only | yes | pending opportunity composer |
| GET | `/api/v1/brand-opportunities` | public published opportunities, or current brand's own | yes | pending opportunity discovery |
| GET | `/api/v1/brand-opportunities/{id}` | public published detail | yes | pending opportunity detail |
| POST | `/api/v1/brand-opportunities/{id}/applications` | bearer JWT, any authenticated applicant | yes | pending application composer |
| GET | `/api/v1/brand-opportunities/{id}/applications` | bearer JWT, brand owner only | yes | pending applications inbox |
| PATCH | `/api/v1/brand-applications/{id}` | bearer JWT, brand owner only | yes | pending applications inbox |
| POST | `/api/v1/brand-applications/{id}/terms` | bearer JWT, brand or applicant party, versioned | yes | pending negotiation & terms |
| POST | `/api/v1/campaign-deliverables` | bearer JWT, brand owner only | yes | pending campaign tracker |
| GET | `/api/v1/campaign-deliverables` | bearer JWT, brand owner or deliverable owner | yes | pending campaign tracker |
| POST | `/api/v1/campaign-deliverables/{id}/proof` | bearer JWT, deliverable owner only, ready owned file required | yes | pending campaign tracker |
| POST | `/api/v1/campaign-deliverables/{id}/approve` | bearer JWT, brand owner only | yes | pending campaign tracker |
| POST | `/api/v1/campaign-metrics` | bearer JWT, brand owner or deliverable owner | yes | pending campaign tracker |
| GET | `/api/v1/model/profile` | bearer JWT | yes | pending model dashboard |
| PATCH | `/api/v1/model/profile` | bearer JWT, auto-creates talent profile link | yes | pending model dashboard |
| GET | `/api/v1/model/campaign-categories` | bearer JWT | yes | pending campaign categories screen |
| PATCH | `/api/v1/model/campaign-categories` | bearer JWT, replace-all | yes | pending campaign categories screen |
| GET | `/api/v1/model/usage-rights` | bearer JWT | yes | pending usage rights screen |
| POST | `/api/v1/model/usage-rights` | bearer JWT | yes | pending usage rights screen |
| PATCH | `/api/v1/model/usage-rights/{id}` | bearer JWT, owner only | yes | pending usage rights screen |
| GET | `/api/v1/model/usage-rates` | bearer JWT | yes | pending rate-by-usage screen |
| POST | `/api/v1/model/usage-rates` | bearer JWT | yes | pending rate-by-usage screen |
| PATCH | `/api/v1/model/usage-rates/{id}` | bearer JWT, owner only | yes | pending rate-by-usage screen |
| GET | `/api/v1/model/restricted-categories` | bearer JWT | yes | pending brand safety screen |
| PATCH | `/api/v1/model/restricted-categories` | bearer JWT, replace-all | yes | pending brand safety screen |
| GET | `/api/v1/distribution/profile` | bearer JWT, current owner only | yes | pending distribution profile screen |
| PATCH | `/api/v1/distribution/profile` | bearer JWT, current owner upsert | yes | pending distribution profile screen |
| POST | `/api/v1/distribution-projects` | bearer JWT, partner owner only | yes | pending release coordination |
| GET | `/api/v1/distribution-projects` | bearer JWT, partner owner or project owner | yes | pending release coordination |
| PATCH | `/api/v1/distribution-projects/{id}` | bearer JWT, partner owner only | yes | pending release coordination |
| POST | `/api/v1/distribution-projects/{id}/release-windows` | bearer JWT, partner owner only | yes | pending release coordination |
| POST | `/api/v1/distribution-projects/{id}/handover-items` | bearer JWT, partner owner only | yes | pending release coordination |
| PATCH | `/api/v1/release-handover-items/{id}` | bearer JWT, partner owner only | yes | pending release coordination |
| POST | `/api/v1/distributor-contacts` | bearer JWT, partner owner only | yes | pending distributor contacts |
| GET | `/api/v1/distributor-contacts` | bearer JWT, partner owner only | yes | pending distributor contacts |
| PATCH | `/api/v1/distributor-contacts/{id}` | bearer JWT, partner owner only | yes | pending distributor contacts |
| POST | `/api/v1/distribution-reports` | bearer JWT, partner owner only | yes | pending performance reporting |
| GET | `/api/v1/distribution-reports` | bearer JWT, partner owner only | yes | pending performance reporting |
| GET | `/api/v1/bookings/{id}/review-eligibility` | bearer JWT, booking participant only | yes | shared ratings review screen |
| POST | `/api/v1/reviews` | bearer JWT, booking participant, secured booking only, one review per party pair | yes | shared ratings review screen |
| GET | `/api/v1/users/{id}/reviews` | public, published reviews only | yes | shared/profile reputation surfaces |
| POST | `/api/v1/review-requests` | bearer JWT, booking participant only | yes | shared ratings review request flow |
| GET | `/api/v1/reports/reasons` | public | yes | shared report/block screen |
| POST | `/api/v1/reports` | bearer JWT, non-user entities auto-open a moderation case | yes | shared report/block screen |
| GET | `/api/v1/blocked-users` | bearer JWT, current user only | yes | shared report/block safety controls |
| POST | `/api/v1/blocked-users` | bearer JWT, current user only | yes | shared report/block safety controls |
| DELETE | `/api/v1/blocked-users/{id}` | bearer JWT, current user only | yes | shared report/block safety controls |
| POST | `/api/v1/admin/moderation-cases` | bearer JWT, reviewer/super-admin only | yes | Super Admin content moderation queue |
| GET | `/api/v1/admin/moderation-cases` | bearer JWT, reviewer/super-admin only | yes | Super Admin content moderation queue |
| GET | `/api/v1/admin/moderation-cases/{id}` | bearer JWT, reviewer/super-admin only | yes | Super Admin content moderation detail |
| POST | `/api/v1/admin/moderation-cases/{id}/decision` | bearer JWT, reviewer/super-admin only | yes | Super Admin content moderation detail |
| POST | `/api/v1/disputes` | bearer JWT, booking participant only | yes | shared dispute/report flow |
| GET | `/api/v1/disputes` | bearer JWT, dispute party only | yes | shared dispute/support surfaces |
| GET | `/api/v1/disputes/{id}` | bearer JWT, dispute party only | yes | shared dispute/support surfaces |
| POST | `/api/v1/disputes/{id}/evidence` | bearer JWT, dispute party only | yes | shared dispute/support surfaces |
| GET | `/api/v1/admin/disputes` | bearer JWT, reviewer/finance-admin/super-admin only | yes | Super Admin dispute center |
| GET | `/api/v1/admin/disputes/{id}` | bearer JWT, reviewer/finance-admin/super-admin only | yes | Super Admin dispute case file |
| POST | `/api/v1/admin/disputes/{id}/decision` | bearer JWT, reviewer/finance-admin/super-admin only, notifies both parties | yes | Super Admin dispute case file |
| POST | `/api/v1/support-tickets` | bearer JWT | yes | shared/support CRM surfaces |
| GET | `/api/v1/support-tickets` | bearer JWT, current user only | yes | shared/support CRM surfaces |
| GET | `/api/v1/support-tickets/{id}` | bearer JWT, owner or support admin, internal notes admin-only | yes | shared/support CRM surfaces |
| POST | `/api/v1/support-tickets/{id}/messages` | bearer JWT, owner or support admin | yes | shared/support CRM surfaces |
| GET | `/api/v1/admin/support-tickets` | bearer JWT, support-agent/reviewer/super-admin only | yes | Super Admin support CRM |
| PATCH | `/api/v1/admin/support-tickets/{id}` | bearer JWT, support-agent/reviewer/super-admin only | yes | Super Admin support CRM |
| POST | `/api/v1/admin/announcements` | bearer JWT, super-admin only | yes | Super Admin broadcast announcements |
| GET | `/api/v1/admin/announcements` | bearer JWT, super-admin only | yes | Super Admin broadcast announcements |
| POST | `/api/v1/admin/announcements/{id}/publish` | bearer JWT, super-admin only, fans out notifications | yes | Super Admin broadcast announcements |
| GET | `/api/v1/notifications` | bearer JWT, current user only | yes | notification center |
| PATCH | `/api/v1/notifications/{id}/read` | bearer JWT, current user only | yes | notification center |
| POST | `/api/v1/notifications/read-all` | bearer JWT, current user only | yes | notification center |
| POST | `/api/v1/push-devices` | bearer JWT, token tokenized/not returned | yes | notification center push registration |
| GET | `/api/v1/me/dashboard` | bearer JWT, current user only | yes | portal dashboard KPI strips |
| GET | `/api/v1/director/dashboard` | bearer JWT, director/producer project scope | yes | Director home dashboard |
| GET | `/api/v1/admin/dashboard` | bearer JWT, reviewer/finance-admin/support-agent/super-admin only | yes | Super Admin dashboard |
| GET | `/api/v1/admin/analytics` | bearer JWT, reviewer/finance-admin/support-agent/super-admin only | yes | Super Admin analytics |
| POST | `/api/v1/exports` | bearer JWT, synchronous CSV generation, admin-only export types gated | yes | supported CSV export actions |
| GET | `/api/v1/exports` | bearer JWT, current user only, CSV content omitted from list view | yes | supported CSV export actions |
| GET | `/api/v1/exports/{id}` | bearer JWT, current user only | yes | supported CSV export actions |
| GET | `/api/v1/insurance/profile` | bearer JWT, current owner only | yes | pending insurance profile screen |
| PATCH | `/api/v1/insurance/profile` | bearer JWT, current owner upsert | yes | pending insurance profile screen |
| POST | `/api/v1/insurance/policies` | bearer JWT, provider profile required | yes | pending shoot insurance records |
| GET | `/api/v1/insurance/policies` | bearer JWT, provider owner or insured user | yes | pending shoot insurance records |
| GET | `/api/v1/insurance/policies/{id}` | bearer JWT, provider owner or insured user | yes | pending shoot insurance records |
| POST | `/api/v1/insurance/claims` | bearer JWT, policy party only | yes | pending claim support |
| GET | `/api/v1/insurance/claims` | bearer JWT, provider owner, claimant, or adjuster | yes | pending claim support |
| GET | `/api/v1/insurance/claims/{id}` | bearer JWT, provider owner, claimant, or adjuster | yes | pending claim support |
| POST | `/api/v1/insurance/claims/{id}/evidence` | bearer JWT, claim party only | yes | pending claim support |
| POST | `/api/v1/insurance/claims/{id}/decision` | bearer JWT, provider owner only | yes | pending claim support |
| GET | `/api/v1/insurance/dashboard` | bearer JWT, provider owner only | yes | pending insurance dashboard |

## Connected Flutter screens

| Screen ID | Route | Repository/provider | Loading/empty/error | Actions tested |
|---|---|---|---:|---:|
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

## Tests last run

| Command | Result | Date |
|---|---|---|
| External DNS/TLS verification | pass | 2026-07-17 |
| MySQL authenticated connection | pass | 2026-07-17 |
| `ruff check backend` and format check | pass | 2026-07-17 |
| `mypy --config-file backend/pyproject.toml backend/app` | pass | 2026-07-17 |
| MySQL/Redis unit and integration suite (31 tests) | pass, 86.08% coverage | 2026-07-17 |
| Container build and Gunicorn readiness smoke test | pass | 2026-07-17 |
| Container HTTP auth smoke test | pass | 2026-07-17 |
| Container HTTP KYC/upload smoke test | pass | 2026-07-17 |
| Container Celery file scan smoke test | pass, pending file moved to clean/ready | 2026-07-17 |
| Container admin KYC permission smoke test | pass, normal user 403; reviewer queue/detail/decision 200 | 2026-07-17 |
| Container marketplace/profile smoke test | pass, profile/talent update, pre-KYC 403, post-KYC publish/search/detail/facets 200/201 | 2026-07-17 |
| Container portfolio/listing media smoke test | pass, portfolio create/list, publish with attached media, public detail media | 2026-07-17 |
| Container saved-search/shortlist smoke test | pass, result-count, save/list/delete search, create/list/update/delete shortlist item | 2026-07-17 |
| Container project/requirement smoke test | pass, skills lookup, project create/detail, requirement create/list | 2026-07-17 |
| Container project-room smoke test | pass, project file link, pinned room decision create, room aggregate fetch | 2026-07-17 |
| Container booking/negotiation/chat smoke test | pass, booking send, counter, accept, provider availability conflict, chat message, pin decision | 2026-07-17 |
| Container availability/inbox smoke test | pass, booking list, manual availability create/list/update/delete | 2026-07-17 |
| Contract/legal integration flow | pass, template list, accepted-booking contract generation, two-party signing, legal review decision, addendum request | 2026-07-17 |
| Payment/finance integration flow | pass, signed-contract schedule generation, idempotent proof submission, finance approval, ledger, receipt, booking secured, payout account | 2026-07-17 |
| Operations/safety integration flow | pass, location property/pricing/rules, location inspection dual confirm, damage claim/evidence, equipment profile/item/package/terms, equipment inspection dual confirm, safety check, incident, check-in | 2026-07-17 |
| `flutter analyze` | pass | 2026-07-17 |
| `flutter test` | pass, 361 widget tests | 2026-07-17 |
| OpenAPI YAML parse check | pass, 102 paths / 166 schemas | 2026-07-17 |
| `ruff check backend` and format check | pass | 2026-07-18 |
| `mypy --config-file backend/pyproject.toml backend/app` | pass | 2026-07-18 |
| MySQL/Redis unit and integration suite (35 tests) | pass, 85.77% coverage | 2026-07-18 |
| Container build and Gunicorn readiness smoke test | pass | 2026-07-18 |
| Container HTTP agency/brand/model/distribution smoke test | pass, agency/brand profile upsert, published opportunity public list, model profile upsert, distribution profile upsert | 2026-07-18 |
| OpenAPI YAML parse check | pass, 140 paths / 207 schemas | 2026-07-18 |
| `ruff check backend` and format check | pass | 2026-07-18 |
| `mypy --config-file backend/pyproject.toml backend/app` | pass | 2026-07-18 |
| MySQL/Redis unit and integration suite (40 tests) | pass, 85.93% coverage | 2026-07-18 |
| Container build and Gunicorn readiness smoke test | pass | 2026-07-18 |
| Container HTTP review/report/support/notification smoke test | pass, report reasons, report create, support ticket create, notifications list, push device register | 2026-07-18 |
| OpenAPI YAML parse check | pass, 168 paths / 226 schemas | 2026-07-18 |
| Production migration (`flask db upgrade` against real MySQL) | pass, 15/15 migrations, 129 tables, roles/skills/cities seeded | 2026-07-18 |
| Production container health (`cineconnect-api`/`worker`/`scheduler`) | pass, all three healthy with restart policy `unless-stopped` | 2026-07-18 |
| Production external HTTPS smoke test | pass, register/login, `/me`, `/cities`, `/brand-opportunities`, `/notifications` via `https://cine.nalexustechnologies.com` | 2026-07-18 |
| `nginx -t` after vhost edit | pass (pre-existing unrelated warnings on other sites only) | 2026-07-18 |
| `ruff check backend` and format check | pass | 2026-07-18 |
| `mypy --config-file backend/pyproject.toml backend/app` | pass | 2026-07-18 |
| MySQL/Redis unit and integration suite (42 tests) | pass, 86.27% coverage | 2026-07-18 |
| `pip-audit` dependency vulnerability scan | 7 known CVEs found in `cryptography` 45.0.7 and `pytest` 8.4.2; fixed by upgrading to `cryptography>=48.0.1,<50` (49.0.0 installed) and `pytest>=9.0.3,<10` (9.1.1 installed); re-scan clean | 2026-07-18 |
| OpenAPI YAML parse check | pass, 173 paths / 229 schemas | 2026-07-18 |
| Production migration (`flask db upgrade` for `export_jobs`) | pass | 2026-07-18 |
| Production redeploy (rebuilt image, restarted containers) | pass, all three containers healthy | 2026-07-18 |
| Production external HTTPS smoke test (Phase 12) | pass, `/me/dashboard`, `/exports` create/get/list, `/admin/dashboard` 403 for non-admin | 2026-07-18 |
| MySQL/Redis unit and integration suite (43 tests, insurance flow added) | pass, 86.32% coverage | 2026-07-18 |
| OpenAPI YAML parse check | pass, 181 paths / 235 schemas | 2026-07-18 |
| Production migration (`flask db upgrade` for insurance tables) | pass | 2026-07-18 |
| Production redeploy and external HTTPS smoke test (insurance) | pass, profile upsert, policy create, dashboard | 2026-07-18 |
| `ruff check backend/app backend/tests` and `ruff format` | pass | 2026-07-18 |
| `mypy --config-file backend/pyproject.toml backend/app` | pass | 2026-07-18 |
| `flutter analyze` | pass | 2026-07-18 |
| `flutter test` | pass, 361 widget tests | 2026-07-18 |
| Local migration (`flask db --directory backend/migrations upgrade`) | pass, `a7b8c9d0e1f2` applied | 2026-07-18 |
| KYC binary upload integration flow | pass, real bytes stored locally, DB size/checksum computed by server, owner download 200, other user 404 | 2026-07-18 |
| MySQL/Redis unit and integration suite (43 tests) | pass | 2026-07-18 |
| OpenAPI YAML parse check | pass, 183 paths / 237 schemas | 2026-07-18 |
| `flutter analyze` | pass | 2026-07-18 |
| `flutter test` | pass, 361 widget tests | 2026-07-18 |
| Production saved-search/shortlist smoke test | pass, director account created saved search, listed saved searches, created shortlist board, listed boards, deleted saved search | 2026-07-18 |
| Production portfolio/showreel smoke test | pass, actor/talent account created profile, uploaded `profile_media`, created portfolio item after scan, listed, patched cover/order, deleted | 2026-07-18 |
| `ruff check backend/app/api/verification.py` | pass | 2026-07-18 |
| OpenAPI YAML parse check | pass, 183 paths / 237 schemas | 2026-07-18 |
| `flutter analyze` | pass | 2026-07-18 |
| `flutter test` | pass, 361 widget tests | 2026-07-18 |
| Production M2 project/room smoke test | pass, director account created project, listed/detail fetched it, created requirement, pinned room decision, uploaded `project_document`, linked project file, room aggregate persisted file and decision | 2026-07-18 |
| Production M3 booking/negotiation/chat smoke test | pass, created throwaway producer/talent, approved smoke KYC, published talent listing, created availability, project and requirement, sent booking, talent countered, producer accepted, chat message created, pin endpoint accepted | 2026-07-18 |
| Production M4 contract/legal smoke test | pass, created throwaway producer/talent/legal users, approved smoke KYC, accepted booking, generated contract, producer signed, talent signed, addendum created, legal review requested/listed/approved by legal partner | 2026-07-18 |
| Production M5 payment/finance smoke test | pass, created throwaway producer/talent/finance users, approved smoke KYC and granted finance role, accepted booking, signed contract, loaded payment schedule, uploaded real PDF payment proof, finance admin approved it, receipt and ledger appeared, booking became secured and milestone verified | 2026-07-18 |
| `ruff check backend/app/api/verification.py` and `ruff format --check backend/app/api/verification.py` | pass | 2026-07-18 |
| `flutter analyze` | pass | 2026-07-18 |
| `flutter test` | pass, 361 widget tests | 2026-07-18 |
| Production M6 location/equipment/safety/insurance smoke test | pass, direct throwaway SQL fixtures only for users/project/booking/file-ready state, then public HTTPS API created location property/space/pricing/rule, booking-party location inspection with LO/DP dual confirmation, damage claim/evidence, equipment profile/item/package/term, booking-party equipment inspection with EP/DP dual confirmation, safety check/item, incident, talent check-in, insurance profile/policy/claim/evidence/decision | 2026-07-18 |
| `flutter analyze` | pass | 2026-07-18 |
| `flutter test` | pass, 361 widget tests | 2026-07-18 |
| Production M7 agency/brand/model/distribution smoke test | pass, direct throwaway SQL fixtures only for users/project/booking/file-ready state, then public HTTPS API ran agency profile/invitation/accept/roster/audition/candidate/self-tape/selection-note/commission, brand profile/opportunity/application/status/terms/deliverable/metrics/approval, model profile/categories/usage-rights/usage-rates/restricted-categories, and distribution profile/project/release-window/handover/contact/report | 2026-07-18 |
| `flutter analyze` | pass | 2026-07-18 |
| `flutter test` | pass, 361 widget tests | 2026-07-18 |
| Production M8 review/moderation/support/notification smoke test | pass, direct throwaway SQL fixtures only for users/project/secured booking/admin-role setup, then public HTTPS API ran review eligibility/create/list/request, report/reasons/block/unblock, moderation decision, dispute create/list/admin decision, support ticket/messages/admin status, announcement create/list/publish, notifications list/read/read-all, and push device register | 2026-07-18 |
| `flutter analyze` | pass | 2026-07-18 |
| `flutter test` | pass, 361 widget tests | 2026-07-18 |
| Production M9 dashboard/analytics/export smoke test | pass, public HTTPS API loaded `/me/dashboard`, `/admin/dashboard`, `/admin/analytics`, created `bookings`, `ledger`, and `admin_disputes` exports, listed exports, and fetched export detail CSV metadata | 2026-07-18 |
| M10 UI action inventory regeneration | pass, raw inventory has 989 callbacks and 199 conservative `server_candidate` rows; audit document created with 93 rows still needing source review | 2026-07-18 |
| M10 blocked-user cleanup regression | pass, AT-12 now uses live blocked-user list/unblock endpoints with demo fallback; `flutter analyze` clean and full Flutter suite passes 361 tests | 2026-07-18 |
| M10 distribution release submit cleanup | pass, DS-03 submit now updates live distribution project status/note with demo fallback; regenerated inventory has 990 callbacks and 200 conservative `server_candidate` rows; full Flutter suite passes 361 tests | 2026-07-18 |
| M10 media package publish cleanup | pass, ME-04 now loads live equipment items, creates backend packages, and attaches selected live items with demo fallback; regenerated inventory has 991 callbacks and 200 conservative `server_candidate` rows; full Flutter suite passes 361 tests | 2026-07-18 |
| M10 media/model rate publish cleanup | pass, ME-06 now publishes visible terms through live equipment terms endpoint, MD-04 now publishes every visible usage-rate row through live model usage-rate endpoint, and MD-05 restricted-category save was source-reviewed as already live-wired; regenerated inventory has 991 callbacks and 200 conservative `server_candidate` rows; full Flutter suite passes 361 tests | 2026-07-18 |
| M10 brand/agency/insurance/admin source review | pass, BR-03 now awaits live opportunity publish with disabled publishing state; BR-04, BR-06, CA-04, IN-05, and admin dashboard flagged rows documented as preview/wrapper/backend-gap controls rather than unsafe prod mutations; regenerated inventory has 991 callbacks and 200 conservative `server_candidate` rows; full Flutter suite passes 361 tests | 2026-07-18 |
| M10 location/equipment/payment source review | pass, LO-04 now publishes visible pricing rows to the first live owner property, LO-05 now syncs visible rules to the first live owner property, and location/equipment availability/inspection plus portal payment/commission rows were documented as preview-only until live IDs/endpoints exist; regenerated inventory has 991 callbacks and 200 conservative `server_candidate` rows; full Flutter suite passes 361 tests | 2026-07-18 |
| M10 shared/actor core source review | pass, AT-05 now publishes the visible per-day actor/talent rate to live `day_rate_minor`; shared payment proof, review/report, signup/KYC, AT-08, AT-10, and utility-screen rows documented as already live-wired or intentional preview/simulated controls; regenerated inventory has 991 callbacks and 200 conservative `server_candidate` rows; full Flutter suite passes 361 tests | 2026-07-18 |
| M10 crew/director/distribution/legal source review | pass, CR-04 now saves crew availability through the live user-calendar endpoint and shows live entries; crew profile/portfolio/request/contract rows, director/producer rows, distribution contacts/reports, legal rows, and super-admin wrappers documented as already-wired, preview-only, or blocked on missing live DTO IDs/endpoints; regenerated inventory has 991 callbacks and 200 conservative `server_candidate` rows; full Flutter suite passes 361 tests | 2026-07-18 |
| M10 final raw inventory source sweep | pass, LO-02/ME-03/ME-02 and shared DP/AT/KYC/payment/admin rows confirmed already wired where endpoints exist; generic role-portal placeholders, admin contract-template/revenue buttons, unsupported export types, and local toggle/preview rows documented as backend-gap or preview-only; regenerated inventory remains 991 callbacks and 200 conservative `server_candidate` rows; M10 still needs real Flutter UI walkthrough | 2026-07-18 |
| Demo data seed slice 1 | pass, idempotent seed created/verified locally and in production: 111 demo users, 220 synthetic ready files, 60 KYC submissions, 10 talent listings, 10 backbone projects, 30 requirements, 10 saved searches, 10 shortlists, 20 shortlist items, location/equipment/model/agency/brand/distribution provider foundations, and 60 availability entries; HTTPS smoke login/list checks passed | 2026-07-18 |
| Demo data seed slice 2 | pass, idempotent seed created/verified locally and in production: 10 bookings, 20 booking participants, 30 offers, 10 negotiation threads, 30 negotiation rounds, 10 conversations, 100 chat messages, 1 demo contract template with clauses, 10 contracts, 20 parties, 14 signatures, 10 legal reviews, 3 addendums, 10 payment schedules, 20 milestones, 10 transactions/proofs, 5 receipts, 10 ledger entries, 10 payout accounts, and 10 fee snapshots; HTTPS smoke checks passed for DP/talent/admin/legal/payment views | 2026-07-18 |
| Demo data seed slice 3 | pass, idempotent seed created/verified locally and in production: operations inspections/items, 5 damage claims/evidence rows, 10 equipment inspections/items, 10 safety checks with 20 checklist items, 10 incidents/check-ins, 10 insurance profiles/policies/claims/evidence, 10 auditions with 30 candidates, 20 self-tapes, 20 selection notes, 10 commissions, 10 brand opportunities with 30 applications/10 terms/20 deliverables/20 metrics, 20 release handover rows, 20 release windows, 10 distribution reports, 10 reviews/requests, 10 blocked-user rows, 10 reports, 10 moderation cases/events, 10 disputes/evidence/events, 10 support tickets with 20 messages, 3 announcements, 30 notifications/deliveries, 5 push devices, and 3 completed export jobs; production smoke checks passed for admin/trust, agency, brand, distribution, insurance, operations, analytics, notifications, and health | 2026-07-18 |
| M10 production-configured Flutter launch validation | pass, default Flutter API base confirmed as `https://cine.nalexustechnologies.com/api/v1`; `flutter analyze` clean; `flutter test --dart-define=CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` passed 361/361; `flutter build web` passed; `flutter run -d chrome --web-port=52173 --dart-define=...` reached `main()` and served app HTML with no startup errors; manual human screen-by-screen walkthrough still remains | 2026-07-18 |
| M10 headless browser route walkthrough | pass after fixes, production CORS now allows the local Flutter web walkthrough origin; AT-10 unauthenticated payout-account future no longer throws; `flutter analyze`, 361 tests, and production-configured web build pass; headless Chrome route walkthrough captured 82 screenshots across core/portal/admin routes with 0 runtime/error event routes | 2026-07-18 |
| Flutter web production live-domain deployment | pass, production web build deployed to `/var/www/cineconnect/web`; Nginx serves Flutter at `https://cine.nalexustechnologies.com`, preserves `/api/` proxy to Gunicorn and `/media/` alias, SPA fallback works for deep links, `/api/v1/health/ready` returns ok, and live-origin CORS preflight returns `access-control-allow-origin: https://cine.nalexustechnologies.com` | 2026-07-18 |
| `flutter analyze` | pass | 2026-07-18 |
| `flutter test` | pass, 361 widget tests | 2026-07-18 |
| Director portal route overflow regression | pass, `flutter test test/director_producer_portal_test.dart --reporter compact` | 2026-07-22 |
| `flutter analyze` | pass | 2026-07-22 |
| `flutter test` | pass, full suite | 2026-07-22 |
| Backend unit tests | pass, 15 unit tests | 2026-07-22 |
| Backend targeted lint | pass, `.venv/bin/ruff check backend/app ... project/marketplace tests ... cover migration` | 2026-07-22 |
| Backend targeted integration modules | skipped as expected without `RUN_INTEGRATION_TESTS=1`, MySQL, and Redis | 2026-07-22 |
| OpenAPI YAML parse check | pass, 183 paths | 2026-07-22 |
| Production migration (`flask db upgrade` for Director project cover files) | pass, current head `b8c9d0e1f2a3` | 2026-07-22 |
| Production backend redeploy | pass, rebuilt `cineconnect-prod-api:latest`, restarted API/worker/scheduler, internal and external health checks pass | 2026-07-22 |
| Production OpenAPI smoke | pass, live `/api/v1/openapi.yaml` has 183 paths and `Project.cover_file` | 2026-07-22 |
| Production CORS smoke | pass, `https://cine.nalexustechnologies.com` origin allowed for `/api/v1/projects` preflight | 2026-07-22 |
| Production Flutter web build/deploy | pass, `flutter build web --release --dart-define=CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1`; synced to `/var/www/cineconnect/web` | 2026-07-22 |
| Director public media seed | pass, 20 public file rows, 10 project covers, and 10 listing media covers seeded in production | 2026-07-22 |
| Production media smoke | pass, listing detail and project list expose `public_url`; `/media/...jpg` returns `image/jpeg` 200 | 2026-07-22 |
| Director dashboard aggregate endpoint | pass, live `GET /api/v1/director/dashboard` returns summary/projects/timeline/payments/pipeline/activity/priority for demo DP account | 2026-07-22 |
| Director dashboard Flutter live wiring/deploy | pass, dashboard screen/widget layer no longer imports `DirectorProducerDemoData`; `flutter analyze`, Director route tests, full Flutter tests, production web build, live root smoke, and authenticated live `/director/dashboard` smoke pass | 2026-07-22 |
| Director projects/listing discovery fallback removal | pass, `DPProjectsListScreen` and live talent branch of `DPMarketplaceDiscoveryScreen` no longer use `DirectorProducerDemoData`; web redeployed; live `/projects` and `/marketplace/listings?type=talent` smokes pass | 2026-07-22 |
| Director stakeholder profile live listing detail | pass, `DPStakeholderProfileScreen` no longer reads `DirectorProducerDemoData`; live listing detail and seeded public media smoke pass; web redeployed | 2026-07-22 |
| Director booking request composer live send path | pass, `DPBookingRequestFormScreen` no longer reads `DirectorProducerDemoData`; it loads live listing/project/requirements and sends through `BookingsScope.createAndSendBooking`; web redeployed | 2026-07-22 |

## Decisions made

| Date | Decision | Reason | Approved by |
|---|---|---|---|
| 2026-07-17 | Use `https://cine.nalexustechnologies.com/api/v1` | User supplied one production domain; avoids inventing an unconfigured API subdomain | User |
| 2026-07-17 | Use the supplied MySQL database (Percona Server 8.4) and local Redis 7 | User explicitly corrected the master report's PostgreSQL assumption; credentials were verified | User |
| 2026-07-17 | Keep production uploads blocked until object storage is selected | Master report prohibits large uploads through Flask or PostgreSQL | Master report |
| 2026-07-17 | Use documented privacy/retention/provider defaults in ADR 0002 | User authorized suitable defaults with reasons | User |
| 2026-07-17 | Sandbox bank/card flows cannot secure production bookings | Dummy payment data must never be mistaken for money movement | User direction and security policy |
| 2026-07-18 | Deploy to `cine.nalexustechnologies.com` with `APP_ENV=staging` rather than `production` | `Config.validate()` refuses to boot with `APP_ENV=production` while `PAYMENT_MODE=sandbox`; no real payment gateway exists yet, so `production` would be a false label | User directed deployment; app's own safety check |
| 2026-07-18 | Deploy via plain `docker build`/`docker run --network host` instead of CloudPanel's native `clpctl site:add:python` or systemd | Host has no `docker compose` plugin; a hand-maintained Nginx vhost and Certbot cert already existed for this domain from Phase 0/1, and the host is shared with ~14 unrelated production sites, so the lowest-risk path was to reuse the existing vhost rather than let CloudPanel regenerate it | Technical judgment call during deployment |
| 2026-07-18 | Use local server filesystem for M0 uploads instead of R2/MinIO object storage | The Flutter wiring plan explicitly selected local storage for this milestone; it removes credential dependency and lets real file bytes flow end-to-end now, with a later object-storage migration still possible | User wiring plan |
| 2026-07-18 | Add `project_document` as an upload purpose and set `API_PUBLIC_URL` to the HTTPS domain | M2 project-room files need the same upload pipeline as KYC/portfolio; Flutter clients must receive externally reachable PUT URLs, not localhost URLs | Wiring plan + production smoke failure |
| 2026-07-18 | Approve only throwaway M3 smoke KYC directly in production SQL during automated smoke testing | Public talent listing publication correctly requires approved Actor/Talent KYC; no reviewer UI token was available in this automation session, and the actual listing/booking/negotiation/chat flow still used public HTTPS API endpoints | Technical judgment call during production smoke |
| 2026-07-18 | Approve only throwaway M4 smoke KYC directly in production SQL during automated smoke testing | M4 needed a fresh publishable talent listing to reach accepted-booking contract generation; only the smoke account was touched, while contract/signature/legal-review actions used public HTTPS API endpoints | Technical judgment call during production smoke |
| 2026-07-18 | Grant finance role, approve KYC, and mark only the throwaway M5 proof file clean/ready directly in production SQL during automated smoke testing | M5 needed a finance-admin reviewer and a clean uploaded proof file to exercise the live approval path; all business actions still used public HTTPS API endpoints and only timestamped smoke records were touched | Technical judgment call during production smoke |
| 2026-07-18 | Create throwaway M6 users/project/booking and mark only smoke files clean/ready directly in production SQL during automated smoke testing | Public registration was rate-limited and M6 evidence endpoints require clean/ready files; all location/equipment/safety/insurance business actions used the deployed public HTTPS API endpoints | Technical judgment call during production smoke |
| 2026-07-18 | Create throwaway M7 specialist users/project/booking and mark only smoke self-tape file clean/ready directly in production SQL during automated smoke testing | Public registration remained rate-limited, and the self-tape endpoint requires a clean/ready owned file; all agency/brand/model/distribution specialist actions used the deployed public HTTPS API endpoints | Technical judgment call during production smoke |
| 2026-07-18 | Create throwaway M8 users/project/secured booking and grant only smoke admin roles directly in production SQL during automated smoke testing | Public registration/login validation and role setup would slow the trust/safety smoke; all review, report, moderation, dispute, support, announcement, notification, and push-device business actions used deployed public HTTPS API endpoints | Technical judgment call during production smoke |
| 2026-07-18 | Add explicit production CORS origins for local Flutter web walkthrough (`http://localhost:53117`, `http://127.0.0.1:53117`) and the live domain | Headless/Chrome Flutter web validation from localhost was blocked by preflight; mobile/native clients are not affected by browser CORS, but web demos and local walkthroughs need explicit origins | Browser walkthrough evidence |
| 2026-07-18 | Serve Flutter web from the same production domain root while keeping backend under `/api/` | User asked to make the app live using the API domain; same-domain deployment avoids cross-site cookies/CORS surprises for public demos while preserving the documented `https://cine.nalexustechnologies.com/api/v1` API base | User |

## Known blockers

| Blocker | Owner | Required input/action | First observed |
|---|---|---|---|
| Staging environment is undefined | Technical owner | Supply or approve staging domain and isolation plan | 2026-07-17 |
| SES, FCM, and SMS credentials/accounts are unavailable | Product/technical owner | Create provider accounts and supply credentials out of band | 2026-07-17 |
| Monitoring, backup, and on-call ownership are undefined | Technical owner | Select providers, retention, contacts, and restore policy | 2026-07-17 |

## Security and data notes

- New sensitive fields: none stored in source control
- New audit events: `register`, `login`, `refresh`, `password_reset_requested`, `password_reset_completed`
- New verification events: KYC draft, submit, resubmit, approve/reject/needs-resubmission decisions
- New profile/listing fields: base profile bio/city/website/visibility, talent screen profile/languages/rate/availability, public marketplace listing metadata
- New portfolio/listing media fields: portfolio item title/category/file/thumbnail/status/moderation, listing media file/order/cover/caption
- New saved-search/shortlist fields: saved search query/filter snapshot, shortlist board names, shortlist item rank/notes/status
- New project fields: owner/member-scoped project title/type/description/city/dates/status/budget/visibility/progress, project member role/permissions, requirement category/title/budget/dates/status, requirement skill mappings, project file links, and project room notes/decisions/activity items
- New booking fields: booking participants/status events/offers/negotiation rounds/provider availability locks/conversation members/messages/attachments/pinned decisions
- New worker hooks: completed uploads enqueue `app.tasks.files.scan_completed_file`; local/demo processor moves pending files to `clean/ready`
- New permissions: hidden admin roles seeded; `kyc.review` required for admin KYC queue/detail/decision
- Marketplace safety rule: public search/detail only return approved/public listings; talent listing publish requires approved actor-talent KYC
- Media safety rule: portfolio/listing media can only use files owned by the current user and marked `clean/ready`
- Shortlist safety rule: saved searches and shortlists are owner-scoped; shortlist items can only reference approved/public marketplace listings
- Project safety rule: projects are visible only to active members; project creation is limited to director/producer and casting agency roles; project setting updates are owner-only
- Project file safety rule: project files link only to existing files owned by the current user and marked `clean/ready`
- Booking safety rule: booking creation requires project membership and an approved public listing; participants only can read bookings/negotiations/chat; accepted offers lock provider availability and reject overlapping accepted booking windows
- Availability safety rule: users can list/create/update/delete only their own manual availability entries; booking-generated entries are locked against manual edit/delete
- Payment safety rule: only booking requesters can submit proof for their milestones; claimed amount must match the milestone; finance-admin/reviewer/super-admin only can approve/reject proofs; approval writes receipt/ledger entries and secures the booking, while real payment movement remains sandbox/manual until provider credentials are supplied
- Retention implications: ADR 0002 defaults apply; KYC/payment/chat/safety production launch still depends on provider credentials and backup retention setup
- Threats reviewed: wrong-host TLS, credential leakage, public database exposure, root-only deployment, upload handling
- New Phase 10 fields: casting agency commission/roster/audition/candidate/self-tape/selection-note/commission records; brand profile/opportunity/application/terms/campaign-deliverable/metric records; model profile/campaign-category/usage-right/usage-rate/restricted-category records; distribution partner/project/contact/handover-item/release-window/report records
- Phase 10 tokenized fields: brand billing details and distributor contact email/phone are stored only as placeholder/tokenized values pending field-level encryption implementation, matching the existing private-address/serial/coordinate pattern
- Phase 10 safety rule: agency roster/audition/commission actions are agency-owner scoped; audition candidate director fields are limited to the requesting project member; self-tapes can only be submitted by the candidate's own talent-profile user; brand opportunity applications are open to any authenticated user but application status/terms/deliverable approval are brand-owner scoped; model profile/portfolio actions are self-scoped; distribution project/contact/report actions are partner-owner scoped
- New Phase 11 fields: review/review-dimension/review-request records; blocked-user and report records; moderation-case/moderation-event records; dispute/dispute-evidence/dispute-event records; support-ticket/support-message records; announcement and notification/notification-delivery/push-device records
- Phase 11 tokenized fields: push-device tokens are stored only as placeholder/tokenized values pending real FCM/APNs integration, matching the existing private-address/serial/coordinate pattern; notification delivery is sandboxed (in-app always logged, push logged only when an enabled device exists) with no real SES/FCM/SMS provider calls yet
- Phase 11 safety rule: reviews require a secured booking and are limited to one per reviewer/reviewee/booking triple, with the reviewee's aggregate rating recomputed from published reviews only; support-ticket internal notes are hidden from the ticket owner and visible only to support-agent/reviewer/super-admin; moderation-case and dispute admin actions require the corresponding hidden admin role (reviewer/super-admin for moderation; reviewer/finance-admin/super-admin for disputes; support-agent/reviewer/super-admin for support); announcement create/publish is super-admin only; dispute decisions and support replies notify the affected parties through the new notification service
- Phase 12 fields: export job records (`export_jobs`) store synchronously generated CSV content inline (MySQL `LONGTEXT`) rather than in object storage, since no real bucket exists yet; capped at 2,000 rows per export
- Phase 12 safety rule: `/me/dashboard` is self-scoped; `/admin/dashboard` and `/admin/analytics` require reviewer/finance-admin/support-agent/super-admin; `admin_disputes` exports require the same admin check inside the export handler itself (a non-admin attempt is recorded as a failed export job with the 403 preserved, not silently dropped); `ledger`/`bookings` exports are owner-scoped
- Phase 12 hardening: Sentry SDK now initializes (Flask integration, `send_default_pii=False`) whenever `SENTRY_DSN` is set and is a safe no-op otherwise; daily production MySQL backups (`mysqldump` + gzip, 14-day local retention) run via cron at 02:00 UTC on the production server; `pip-audit` found and fixed 7 known CVEs (see Tests last run); announcement fan-out no longer silently truncates at a fixed user cap after this was caught by a flaky-looking test failure that turned out to be a real bug

## Session log

### 2026-07-22 — Director portal perfection B1/B2 implementation and deploy

- Goal: start implementing `docs/DIRECTOR_PORTAL_DATABASE_PERFECTION_PLAN.md` with public media URL support and project cover-image support before removing Director demo fallbacks.
- Backend changes: public upload purposes now include `project_cover`; public URLs are emitted only for `visibility='public'`, `scan_status='clean'`, and `processing_status='ready'`; marketplace/listing file payloads expose `public_url`; projects now support nullable `cover_file_id` with owned/public/image validation and return `cover_file`.
- Flutter changes: uploaded files parse `visibility` and `public_url`; marketplace listings parse/sort media and pass cover images into Director candidate cards; projects parse `cover_file.public_url` and render cover images in project cards; Director narrow-layout overflows in console/discovery/shortlist/project detail widgets were fixed.
- Migration(s): `b8c9d0e1f2a3` adds `projects.cover_file_id`; applied in production on 2026-07-22.
- Deploy: synced backend/docs to `/var/www/cineconnect/release`, added `PUBLIC_MEDIA_BASE_URL=https://cine.nalexustechnologies.com/media` and local storage roots to the server env, rebuilt `cineconnect-prod-api:latest`, ran `flask db upgrade`, restarted `cineconnect-api`/`cineconnect-worker`/`cineconnect-scheduler`, built Flutter web with the live API base, and synced `build/web` to `/var/www/cineconnect/web`.
- Tests: backend compile, targeted Ruff, backend unit tests, OpenAPI parse, `flutter analyze`, Director portal route test, and full `flutter test` all pass locally. Live health, migration-head, OpenAPI, CORS, app-root, and public listing endpoint smokes pass. Integration modules are present but skipped locally until MySQL/Redis integration environment is started with `RUN_INTEGRATION_TESTS=1`.
- Incomplete work: public image seed/import, Director dashboard aggregate endpoint, live project/candidate image data walkthrough after seed, and screen-by-screen removal of `DirectorProducerDemoData`.

### 2026-07-22 — Director public media seed

- Goal: make the first 10 Director demo projects and first 10 actor/talent demo listings visibly image-backed from production storage/database rather than local Flutter demo assets.
- Files changed: added `backend/scripts/seed_director_public_media.py` and `docs/DIRECTOR_PUBLIC_MEDIA_SOURCES.md`.
- Production seed: downloaded Pakistan-relevant Wikimedia-hosted landmark/location images locally, synced them to `/var/www/cineconnect/storage/public/demo/cineconnect-director-public-media-2026-07-22`, then ran the seed in offline mode inside the deployed API image.
- Results: created 20 clean/ready public `FileAsset` rows, attached 10 `projects.cover_file_id` values, and created 10 public `ListingMedia` cover rows.
- Verification: `DEMO-LST-AT-001` detail returns `DEMO-DIR-LISTING-MEDIA-001.public_url`; `DEMO-PROJ-001` appears in the DP project list with `DEMO-DIR-PROJ-MEDIA-001.public_url`; direct `/media/.../lahore-fort-river-lights.jpg` returns HTTP 200 `image/jpeg`.
- Incomplete work: Director dashboard aggregate endpoint and replacing remaining `DirectorProducerDemoData` runtime imports screen-by-screen.

### 2026-07-22 — Director dashboard aggregate endpoint

- Goal: add the B3 backend aggregate needed to refactor the Director dashboard away from local `DirectorProducerDemoData`.
- Backend changes: added `GET /api/v1/director/dashboard` under a new Director API blueprint. The endpoint returns summary metrics, project previews with `cover_file.public_url`, upcoming booking timeline rows, payment attention rows, pipeline rows, activity rows, and priority actions for the authenticated Director/Producer scope.
- OpenAPI: added `Director` tag, `/director/dashboard` path, and `DirectorDashboardEnvelope`.
- Deploy: synced backend/docs, rebuilt `cineconnect-prod-api:latest`, and restarted API/worker/scheduler.
- Verification: local Ruff/compile/backend unit tests pass; live smoke with `dp01@demo.cine.nalexustechnologies.com` returns `active_projects=3`, 3 project previews, 3 timeline rows, 2 payment attention rows, 4 pipeline rows, 3 activity rows, and 3 priority actions. First project includes a true public cover URL.
- Incomplete work: Flutter dashboard DTO/repository/controller and screen/widget refactor to consume this endpoint.

### 2026-07-22 — Director dashboard Flutter live wiring and deploy

- Goal: complete F2 from `docs/DIRECTOR_PORTAL_DATABASE_PERFECTION_PLAN.md` so the Director home dashboard reads from production-backed API data instead of local demo arrays.
- Flutter changes: added `lib/core/director/director_dashboard_models.dart` and `lib/core/director/director_repository.dart`; exposed `AuthController.directorDashboard()`; converted `DPHomeDashboardScreen` to load the authenticated live dashboard future; refactored `DPCommandHeader`, `DPPulseStrip`, `DPTodayTimeline`, `DPProjectDeck`, `DPFinancialCentre`, `DPDealPipeline`, `DPPriorityActions`, `DPActivityFeed`, and `DPDiscoverySnapshot` to receive live payload data; deleted `dp_dashboard_insights.dart`.
- Demo-data cleanup: the Director dashboard screen/widget layer now has no `DirectorProducerDemoData`, `dpPriorityItems`, or `DpPriorityItem` references. Deeper Director screens still require their own passes.
- Deploy: built Flutter web with `CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` and synced `build/web` to `/var/www/cineconnect/web`.
- Verification: `flutter analyze`, `flutter test test/director_producer_portal_test.dart --reporter compact`, full `flutter test --reporter compact`, and production web build pass. Live root returns HTTP 200, and the live demo Director account authenticates and fetches `/api/v1/director/dashboard` with 3 active projects, 3 project previews, 3 timeline rows, 2 payment attention rows, 4 pipeline rows, and 3 priority actions.
- Incomplete work: remove local demo-data fallbacks from `DPProjectsListScreen`, `DPMarketplaceDiscoveryScreen`, stakeholder profile, booking request, bargaining/negotiation, contracts, payments, project room, requirement builder, project accounts, reports, and shared Director console widgets.

### 2026-07-22 — Director projects list and talent discovery fallback removal

- Goal: continue the database-only Director portal cleanup by removing fake populated fallbacks from the next two highly visible screens.
- Flutter changes: `DPProjectsListScreen` now uses only live `ProjectsScope.projects()` data and shows proper loading/error/retry/empty states; `DPMarketplaceDiscoveryScreen` now uses only live authenticated marketplace listings for `All`/`Talent`, removes local candidate fallback, and loads live projects/requirements for the shortlist picker.
- Product truthfulness: non-backed marketplace categories (`Models`, `Crew`, `Locations`, `Media & Equipment`, `Agencies`) now show a backend-gap empty state instead of fake cards until `/director/discovery` or generalized marketplace support is implemented.
- Deploy: rebuilt Flutter web with `CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` and synced to `/var/www/cineconnect/web`.
- Verification: `flutter analyze`, Director portal route regression, and full Flutter suite pass. Live root returns HTTP 200 with new timestamp; live demo DP account gets 3 DB projects from `/projects` and live DB talent listings from `/marketplace/listings?type=talent`.
- Incomplete work: build generalized Director discovery backend for non-talent provider types and continue demo-data removal from stakeholder profile, booking request, bargaining/negotiation, contracts, payments, project room, requirement builder, project accounts, reports, and shared Director console widgets.

### 2026-07-22 — Director stakeholder profile live listing detail

- Goal: remove the stakeholder profile screen's local candidate/template dependency and use live listing detail where an existing backend endpoint already exists.
- Flutter changes: added `AuthRepository.marketplaceListing(...)` and `AuthController.marketplaceListing(...)`; `DPStakeholderProfileScreen` now loads `/marketplace/listings/{listing_id}`, renders live listing summary/owner/city/rate/verification/media, and shows loading/error/retry states.
- Demo-data cleanup: removed direct `DirectorProducerDemoData.candidates` usage and removed hardcoded actor/model/crew/location/equipment/agency profile templates from this screen. Rich provider-specific profile sections are intentionally deferred until the planned Director discovery/detail DTO exists.
- Deploy: rebuilt Flutter web with `CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` and synced to `/var/www/cineconnect/web`.
- Verification: `flutter analyze`, Director portal route regression, and full Flutter suite pass. Live root returns HTTP 200 with new timestamp; live listing detail smoke passes; seeded `DEMO-LST-AT-001` returns 2 public media rows with `public_url`.
- Incomplete work: implement richer `/director/discovery`/detail backend for non-talent provider types and continue demo-data removal from booking request, bargaining/negotiation, contracts, payments, project room, requirement builder, project accounts, reports, and shared Director console widgets.

### 2026-07-22 — Director booking request composer live context and send path

- Goal: convert the booking composer from local demo defaults to live listing/project/requirement context and wire the Send action to the deployed booking backend.
- Flutter changes: `DPBookingRequestFormScreen` now loads marketplace listing detail through `AuthController.marketplaceListing`, live projects and selected-project requirements through `ProjectsScope`, and sends through `BookingsScope.createAndSendBooking`.
- Demo-data cleanup: removed `DirectorProducerDemoData` and shared console helper dependency from the booking composer. Missing auth/listing/projects now renders loading/error/retry state instead of fake records.
- Deploy: rebuilt Flutter web with `CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` and synced to `/var/www/cineconnect/web`.
- Verification: `flutter analyze`, Director portal route regression, and full Flutter suite pass. Live root returns HTTP 200 with new timestamp; read-only smokes for `/projects`, `/projects/DEMO-PROJ-001/requirements`, and `/marketplace/listings/DEMO-LST-AT-001` pass. No production booking was created during smoke.
- Incomplete work: continue demo-data removal from bargaining/negotiation, contracts, payments, project room, requirement builder, project accounts, reports, and shared Director console widgets.

### 2026-07-22 — Director remaining visible screen demo-data removal

- Goal: finish the Director/Producer database-only UI cleanup for the remaining visible portal screens without adding backend records.
- Flutter changes: removed populated demo fallback rendering from bargaining, negotiation detail, contracts, payments, project accounts, project room, requirement builder, shortlist board, reports/export center, calendar risk/watch copy, and shared project console widgets.
- Project Detail: `DPProjectDetailScreen` now loads a live project hub from `ProjectsScope`, `BookingsScope`, `ContractsScope`, and `PaymentsScope`, then converts backend DTOs into the existing Director card models.
- Shared console widgets: project picker and project rail now use live `ProjectsScope` data; schedule/calendar surfaces with no exact backend endpoint show live-empty/backend-gap copy instead of fabricated schedule/weather/risk rows; project-scoped shortlist columns no longer invent candidate cards.
- Demo-data cleanup: `rg` confirms no active `DirectorProducerDemoData` references remain under `lib/features/director_producer` except the data file declaration itself.
- Deploy: rebuilt Flutter web with `CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` and synced `build/web` to `/var/www/cineconnect/web`.
- Verification: `flutter analyze`, `flutter test test/director_producer_portal_test.dart --reporter compact`, and full `flutter test --reporter compact` pass. Live web root returns HTTP 200 and `/api/v1/health/live` returns `status=ok`.
- Incomplete work: add real production schedule/risk/call-sheet backend endpoints, add richer project-scoped shortlist data if required, and add provider-specific Director discovery/detail DTOs for non-talent marketplace types.

### 2026-07-22 — Director schedule endpoint and Calendar live wiring

- Goal: replace the remaining Calendar schedule/risk/call-sheet backend-gap copy with a real Director-owned aggregate endpoint.
- Backend changes: added `GET /api/v1/director/schedule`, scoped to projects visible to the authenticated Director/Producer. It derives events from project dates, active booking windows, contract checkpoints, payment milestones, and recent project-room items; computes risk rows for incomplete project dates, unsigned contracts, and overdue unverified payment milestones; and returns a lightweight call-sheet summary from the next live event.
- Flutter changes: added `DirectorSchedule`, `DirectorScheduleEvent`, `DirectorScheduleRisk`, and `DirectorCallSheet` DTOs; added `DirectorRepository.schedule(...)` and `AuthController.directorSchedule(...)`; wired `ProductionCalendar`, the Calendar risk watch, and the call-sheet bottom sheet to `/director/schedule`.
- OpenAPI: added `/director/schedule` and `DirectorScheduleEnvelope`.
- Deploy: rsynced backend/docs to `/var/www/cineconnect/release`, rebuilt `cineconnect-prod-api:latest`, recreated API/worker/scheduler containers, rebuilt Flutter web with the production API base, and synced `build/web` to `/var/www/cineconnect/web`.
- Verification: backend compile and targeted Ruff pass; OpenAPI YAML parse confirms the new path/schema; backend pytest pass locally with 15 passed and 28 integration tests skipped pending MySQL/Redis integration mode; `flutter analyze`, Director portal route regression, and full Flutter suite pass. Live smokes pass: `/health/live`, `/health/ready`, `/director/schedule`, `/director/schedule?project_id=DEMO-PROJ-001`, and web root HTTP 200.
- Incomplete work: real weather provider credentials, persisted/sent call-sheet documents or notifications if required, richer provider-specific Director discovery/detail DTOs, and optional project-scoped shortlist grouping.

### 2026-07-22 — Director project-scoped shortlist grouping

- Goal: finish the smaller remaining Project Detail shortlist gap using existing backend saved-shortlist data.
- Flutter changes: `MarketplaceShortlist` now parses `project_id` and `requirement_id`; `DPProjectScopedShortlists` loads live shortlist boards through `AuthController.shortlistBundle()` and renders items under the matching live requirement column when `board.requirementId == requirement.id`.
- Backend: no code, migration, or redeploy required for this sub-slice because `/shortlists` already returns `requirement_id`.
- Deploy: rebuilt Flutter web with the production API base and synced it to `/var/www/cineconnect/web`.
- Verification: `flutter analyze`, Director portal route regression, and full Flutter suite pass. Live web root returns HTTP 200.
- Incomplete work: add an in-tab flow for creating requirement-scoped shortlist boards if needed, and continue with richer provider-specific Director discovery/detail DTOs.

### 2026-07-18 — Flutter/backend wiring M10 cleanup audit started

- Goal: begin the final cleanup pass by regenerating the UI action inventory, auditing remaining `server_candidate` rows, preserving legitimate offline/demo fallback, and running a full Flutter regression
- Files changed: regenerated `docs/UI_ACTION_INVENTORY.csv`/`.md`, added `docs/M10_UI_ACTION_AUDIT.md`, updated implementation progress docs
- Findings: raw inventory now reports 989 interactive callbacks and 199 conservative `server_candidate` rows. The first M10 audit buckets these into 42 likely wired/controller callbacks, 40 demo/offline preview callbacks, 24 navigation/component wrappers, and 93 rows still requiring source-level review before M10 can be honestly marked complete.
- Cleanup decision: do not delete `*_demo_data.dart` yet. The app still deliberately uses demo/mock data for offline/error fallback, and some visible export/download actions are preview-only because the deployed backend supports CSV export types only for `bookings`, `ledger`, and `admin_disputes`.
- Tests: `flutter analyze` passed; Flutter widget suite passed (361 tests)
- Incomplete work: M10 remains open. Next pass should source-inspect the 93 `needs_manual_review` rows in `docs/M10_UI_ACTION_AUDIT.md`, patch true misses, and document unsupported backend gaps. Only then should the M10 checklist be checked.
- Exact next task: continue M10 from `docs/M10_UI_ACTION_AUDIT.md`, starting with the highest-count raw inventory files and reducing the `needs_manual_review` bucket to zero.

### 2026-07-18 — Flutter/backend wiring M10 source review pass 2

- Goal: continue the M10 source-level audit and patch real missed wiring where a deployed backend endpoint already exists
- Files changed: `lib/core/trust_safety/trust_safety_models.dart`, `lib/core/trust_safety/trust_safety_repository.dart`, `lib/core/trust_safety/trust_safety_controller.dart`, `lib/features/actor_talent/screens/at12_safety_controls_screen.dart`, `docs/M10_UI_ACTION_AUDIT.md`, `docs/CINECONNECT_FLUTTER_WIRING_PLAN.md`, `docs/IMPLEMENTATION_PROGRESS.md`
- Flutter screens: AT-12 Safety Controls now reads the live blocked-user list from `GET /blocked-users` and unblocks through `DELETE /blocked-users/{user_id}` when authenticated, while retaining the previous demo blocked-user list only as offline/preview fallback
- Findings: the reviewed high-risk rows mostly classify as already-wired private/controller callbacks, navigation/component wrappers, or deliberate preview controls for granular domain features with no exact backend endpoint yet. The one concrete gap found in this pass was blocked-user unblock, now patched.
- Verification: `flutter analyze` passes; `flutter test` passes 361 tests
- Incomplete work: M10 remains open. Remaining work is the final source documentation/retirement of preview-only controls, inventory regeneration after any further patches, and a real manual Flutter UI walkthrough against the deployed server endpoints.
- Exact next task: continue M10 by documenting/retiring the remaining preview-only controls portal by portal, then regenerate `docs/UI_ACTION_INVENTORY.csv`.

### 2026-07-18 — Flutter/backend wiring M10 source review pass 3

- Goal: continue the high-risk source review and patch another callback that had a deployed backend endpoint available
- Files changed: `lib/features/distribution_partner/screens/ds03_release_coordination_screen.dart`, regenerated `docs/UI_ACTION_INVENTORY.csv`/`.md`, updated M10 audit/progress docs
- Flutter screens: DS-03 Release Coordination now submits the live distribution project by calling `SpecialistController.updateDistributionProject(...)` with `status: submitted` and the coordination note; the button disables while syncing and keeps local fallback behavior if the API is unavailable
- Findings: the raw inventory now reports 990 callbacks and 200 conservative `server_candidate` rows. The increase is expected because the newly-live DS-03 submit callback is still line-level classified as a candidate even though source review has addressed it.
- Verification: `flutter analyze` passes; `flutter test` passes 361 tests
- Incomplete work: M10 remains open. Remaining work is portal-by-portal documentation/retirement of preview-only controls and a real manual Flutter UI walkthrough.
- Exact next task: inspect the remaining high-count local preview groups (`location_owner`, `media_equipment`, `model_extension`, `brand_sponsors`, `casting_agency`) and either wire an existing endpoint or document the missing 1:1 backend endpoint.

### 2026-07-18 — Flutter/backend wiring M10 source review pass 4

- Goal: continue source-reviewing high-count media/equipment callbacks and patch a screen that had matching deployed operations endpoints
- Files changed: `lib/features/media_equipment/screens/me04_package_builder_screen.dart`, regenerated `docs/UI_ACTION_INVENTORY.csv`/`.md`, updated M10 audit/progress docs
- Flutter screens: ME-04 Package Builder now loads live equipment items, lets the user select live inventory rows, creates a live backend package through `OperationsController.createEquipmentPackage(...)`, and attaches selected live items through `OperationsController.addEquipmentPackageItem(...)`; demo package state remains as fallback
- Findings: LO-02 Location Listing Wizard was inspected and is already live-wired on final submit through location property/space/pricing/rule endpoints. ME-04 had a real gap and is now patched. The raw inventory now reports 991 callbacks and 200 conservative `server_candidate` rows.
- Verification: `flutter analyze` passes; `flutter test` passes 361 tests
- Incomplete work: M10 remains open. Remaining work is source-reviewing the rest of `media_equipment`, `model_extension`, `brand_sponsors`, `casting_agency`, `insurance_partner`, and generic Super Admin preview buttons.
- Exact next task: continue M10 with ME-06 rate/terms and MD-04/MD-05 model extension controls, patching existing endpoints and documenting controls that remain preview-only.

### 2026-07-18 — Flutter/backend wiring M10 source review pass 5

- Goal: close the remaining high-risk media/equipment terms and model-extension rate rows where deployed endpoints already existed
- Files changed: `lib/features/media_equipment/screens/me06_rate_terms_screen.dart`, `lib/features/model_extension/screens/md04_rate_by_usage_screen.dart`, regenerated `docs/UI_ACTION_INVENTORY.csv`/`.md`, updated M10 audit/progress docs
- Flutter screens: ME-06 Rate Terms now publishes each visible equipment term through `OperationsController.createEquipmentTerm(...)` after the OTP-style confirmation; MD-04 Rate by Usage now loads live model usage rates and creates every visible usage-rate row through `SpecialistController.createModelUsageRate(...)` instead of one hardcoded sample; both screens retain their demo stores as offline/preview fallback
- Findings: MD-05 Brand Safety was source-reviewed and already saves restricted categories through `SpecialistController.updateModelRestrictedCategories(...)`; its auto-flag switches remain local policy-preview controls because Phase 10 has no separate persisted auto-flag endpoint. The regenerated raw inventory remains 991 callbacks and 200 conservative `server_candidate` rows.
- Verification: `flutter analyze` passes; `flutter test` passes 361 tests
- Incomplete work: M10 remains open. Remaining work is source-reviewing/documenting brand sponsor, casting agency, insurance partner, remaining location/equipment availability/inspection preview controls, and generic Super Admin wrapper/export buttons, followed by a real manual Flutter UI walkthrough.
- Exact next task: continue M10 with the highest-count remaining raw inventory files, starting with brand/casting and insurance/super-admin rows, patching only where a matching deployed backend endpoint exists.

### 2026-07-18 — Flutter/backend wiring M10 source review pass 6

- Goal: review remaining brand sponsor, casting agency, insurance incident, and Super Admin dashboard `server_candidate` rows and patch only safe live-wiring gaps
- Files changed: `lib/features/brand_sponsors/screens/br03_opportunity_composer_screen.dart`, regenerated `docs/UI_ACTION_INVENTORY.csv`/`.md`, updated M10 audit/progress docs
- Flutter screens: BR-03 Opportunity Composer now awaits the live `POST /brand-opportunities` publish call, disables the Publish button during sync, then updates demo fallback state and navigates only after the live attempt completes
- Findings: BR-04 Applications Inbox, BR-06 Campaign Tracker, and CA-04 Candidate Shortlist still render demo-only cards without live backend IDs, so their reject/shortlist/approve/submit controls were documented as preview-safe rather than wired to production objects by guesswork. IN-05 Incident Reports remains preview-only for list/resolve/escalate/export because the current backend exposes incident create but not partner incident list/update, and exports support only `ledger`, `bookings`, and `admin_disputes`. Admin dashboard flagged rows are route wrappers or preview queue snapshots; the live dashboard aggregate is already rendered separately.
- Verification: `flutter analyze` passes; regenerated inventory remains 991 callbacks and 200 conservative `server_candidate` rows; `flutter test` passes 361 tests
- Incomplete work: M10 remains open. Remaining work is source-reviewing the remaining location/equipment availability and inspection rows, payments/commission preview verification buttons, and generic export/detail wrappers, then doing a real manual Flutter UI walkthrough.
- Exact next task: continue M10 with location/equipment availability/pricing/rules/check-in/check-out and commission/payment preview rows, patching only where live IDs and matching endpoints exist.

### 2026-07-18 — Flutter/backend wiring M10 source review pass 7

- Goal: review location/equipment availability, pricing/rules, inspection/return, and portal payment/commission rows, then patch only screens with safe live endpoints and live IDs
- Files changed: `lib/features/location_owner/screens/lo04_pricing_deposit_screen.dart`, `lib/features/location_owner/screens/lo05_rules_restrictions_screen.dart`, regenerated `docs/UI_ACTION_INVENTORY.csv`/`.md`, updated M10 audit/progress docs
- Flutter screens: LO-04 Pricing Deposit now posts each visible rate-card row to `POST /location-properties/{id}/pricing` using the first live owner property when available; LO-05 Rules Restrictions now posts each visible rule row to `POST /location-properties/{id}/rules` using the first live owner property when available. Both retain demo/offline state and show a create-location-first message when no live property exists.
- Findings: LO-03 and ME-05 remain asset-specific local calendars because the deployed availability API is user-calendar scoped, not location/equipment scoped. LO-07/LO-08 and ME-08/ME-09 need live booking/property/provider/inspection/equipment IDs before their inspection and damage-claim endpoints can be safely called. CA-07 and BR-07 remain preview ledgers because shared payment proof/admin review/ledger screens are already live-wired, while these portal-specific rows do not carry live payment proof/transaction IDs.
- Verification: `flutter analyze` passes; regenerated inventory remains 991 callbacks and 200 conservative `server_candidate` rows; `flutter test` passes 361 tests
- Incomplete work: M10 remains open. Remaining work is source-reviewing remaining generic detail/export wrappers and any stale preview controls, then a real manual Flutter UI walkthrough.
- Exact next task: continue M10 with remaining `needs_manual_review` rows in `docs/M10_UI_ACTION_AUDIT.md`, especially generic wrappers and shared core rows, and reduce the undocumented remainder toward zero.

### 2026-07-18 — Flutter/backend wiring M10 source review pass 8

- Goal: review shared payment/review/report/signup/KYC and actor-talent rate/earnings/counteroffer rows, patching any remaining safe live field updates
- Files changed: `lib/features/actor_talent/screens/at05_rate_card_screen.dart`, regenerated `docs/UI_ACTION_INVENTORY.csv`/`.md`, updated M10 audit/progress docs
- Flutter screens: AT-05 Rate Card now publishes the visible `Per day` rate to the actor/talent profile's live `day_rate_minor` through `AuthController.updateTalentProfile(...)` after OTP confirmation; the detailed multi-row rate card remains local negotiation preview because no actor/talent rate table exists yet
- Findings: shared Payment Proof is already live-wired for upload and proof submission when a live milestone exists; Ratings Review and Report Block are already live-wired when opened with live booking/entity/user IDs; signup/KYC is wired to auth/upload/KYC while signup OTP/resend stays simulated until real OTP/SMS delivery exists; AT-08 is live for `BKG-*` IDs and demo for demo offer IDs; AT-10 is live for dashboard/payout/ledger/report and demo-only for receipt confirmation fallback; utility static retry/app-store actions are intentional placeholders.
- Verification: `flutter analyze` passes; regenerated inventory remains 991 callbacks and 200 conservative `server_candidate` rows, with one navigation/review split change from scanner heuristics; `flutter test` passes 361 tests
- Incomplete work: M10 remains open. Remaining work is source-reviewing the final portal-specific wrappers and stale preview rows, then a real manual Flutter UI walkthrough.
- Exact next task: continue M10 with crew-services and any remaining director/producer/distribution/legal/super-admin wrapper rows not yet documented in the audit.

### 2026-07-18 — Flutter/backend wiring M10 source review pass 9

- Goal: review crew-services plus the remaining director/producer, distribution, legal, and super-admin rows, then patch only actions that can safely call deployed endpoints with live IDs
- Files changed: `lib/features/crew_services/screens/cr04_availability_calendar_screen.dart`, regenerated `docs/UI_ACTION_INVENTORY.csv`/`.md`, updated M10 audit/progress docs
- Flutter screens: CR-04 Availability Calendar now loads live availability entries through `BookingsScope.availability()` and saves status changes through `BookingsController.createAvailability(...)`, while retaining the existing crew demo calendar as offline/preview fallback.
- Findings: CR-02 profile and CR-03 credits remain preview because no dedicated crew service profile/credit backend exists; CR-05 request cards lack live booking IDs; CR-06 uses live shared contract/payment screens only when live IDs are present. Director/producer booking/project/shortlist rows reviewed here are already wired through M1–M5 controllers, except smart-filter saved-state preview controls. DS-02/DS-04 load live data but visible demo cards lack live contact/report/project IDs for safe mutation. LG-02 is live for legal review decisions, while LG-03/LG-04 depend on template/addendum endpoints or shared live legal-review IDs. Super-admin rows reviewed here are either already-live wrappers or deliberate preview snapshots.
- Verification: `flutter analyze` passes; regenerated inventory remains 991 callbacks and 200 conservative `server_candidate` rows; `flutter test` passes 361 tests
- Incomplete work: M10 remains open. Remaining work is the final manual/source sweep of any still-undocumented preview rows, followed by a real Flutter app/device/browser walkthrough against `https://cine.nalexustechnologies.com/api/v1`.
- Exact next task: continue M10 with the final raw inventory review, update or retire any remaining preview-only actions that have safe live endpoints, then perform the manual UI walkthrough before checking M10 complete.

### 2026-07-18 — Flutter/backend wiring M10 source review pass 10

- Goal: finish the raw-inventory source sweep for the highest-count remaining files and avoid unsafe endpoint mapping for preview-only UI controls
- Files changed: `docs/M10_UI_ACTION_AUDIT.md`, `docs/CINECONNECT_FLUTTER_WIRING_PLAN.md`, `docs/IMPLEMENTATION_PROGRESS.md`
- Flutter screens: no code patch was needed in this pass. LO-02 was confirmed already live for final property submit; ME-03 was confirmed live for inventory load/create; ME-02, AT-02, AT-03, DP shortlist, booking/chat/contract/payment, KYC, review/report, payout, and admin KYC/payment/moderation/detail rows were confirmed already wired where live endpoints and IDs exist.
- Findings: remaining generic role-portal form buttons are demo placeholders superseded by dedicated wired role screens; Super Admin contract-template/revenue buttons have no deployed authoring/settings mutation endpoint; remaining unsupported export buttons should not be mapped to unrelated CSV export types; local safety/location/equipment/insurance/model/brand/agency preview toggles need live DTO IDs or new backend endpoints before safe production mutation wiring.
- Verification: inventory remains 991 callbacks and 200 conservative `server_candidate` rows; `flutter analyze` and the full 361-test Flutter suite were already green after the pass 9 code patch and stayed unaffected by this docs-only sweep; production readiness endpoint reports database and Redis ok after docs sync
- Incomplete work: M10 remains open because the required real Flutter app/device/browser walkthrough against production endpoints has not been completed in this terminal session.
- Exact next task: run the Flutter app against `https://cine.nalexustechnologies.com/api/v1`, walk every M0–M9 golden path plus preview-only controls listed in `docs/M10_UI_ACTION_AUDIT.md`, then either fix any UI issues found or check off M10 if the walkthrough passes.

### 2026-07-18 — Flutter web production live-domain deployment

- Goal: make the Flutter app live on the same production domain used by the API and allow that origin in backend CORS.
- Files changed: `docs/IMPLEMENTATION_PROGRESS.md`; production-only changes were applied to `/etc/nginx/sites-available/cine.nalexustechnologies.com.conf` and `/var/www/cineconnect/web`.
- Build/deploy: ran `flutter build web --dart-define=CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1`; copied `build/web/` to `/var/www/cineconnect/web/` on the production server.
- Nginx routing: `https://cine.nalexustechnologies.com/` now serves the Flutter SPA, `/api/` still proxies to the backend Gunicorn service on `127.0.0.1:5002`, `/media/` still aliases public upload media, and the ACME challenge path still uses the bootstrap root for certificate renewals.
- CORS: production backend env includes the live Flutter origin `https://cine.nalexustechnologies.com` and local walkthrough origins; live preflight to `/api/v1/app/bootstrap` returns `access-control-allow-origin: https://cine.nalexustechnologies.com`.
- Verification: live root returned Flutter `index.html`; `https://cine.nalexustechnologies.com/talent` returned the SPA fallback; `https://cine.nalexustechnologies.com/main.dart.js` returned the compiled app bundle; `https://cine.nalexustechnologies.com/api/v1/health/ready` returned database and Redis ok; headless Chrome rendered the live CineConnect onboarding screen and saved evidence at `docs/server_live/cineconnect_live_home_deep.png`.
- Incomplete work: M10 is still not fully closed until a human manually logs into the live web/app walkthrough accounts and checks each portal screen flow end-to-end.
- Exact next task: use the demo-login report/accounts to walk `https://cine.nalexustechnologies.com` in a real browser, confirm each role portal loads the seeded data, and log/fix any screen-level issues found.

### 2026-07-18 — Demo data seed slice 1

- Goal: begin applying `docs/CINECONNECT_DEMO_DATA_SEED_BLUEPRINT.md` step by step so the deployed app has realistic linked demo data for portal walkthroughs
- Files changed: new `backend/scripts/seed_demo_data_slice1.py`, `.gitignore`, `docs/IMPLEMENTATION_PROGRESS.md`; generated local/server-only `docs/CINECONNECT_DEMO_LOGIN_HANDOFF.json` is intentionally ignored because it contains demo login passwords
- Seeded data: 1 super-admin account plus 10 accounts for each visible role group; accepted demo email domain `demo.cine.nalexustechnologies.com`; 220 synthetic ready files; 60 KYC submissions with documents/events; 10 actor/talent profiles, 30 portfolio rows, 10 public marketplace listings; 10 production backbone projects, 30 requirements, 20 project members, 30 room items, 20 project files; 10 saved searches, 10 shortlists, 20 shortlist items; 10 model profiles with usage/restriction rows; 10 location properties with spaces/pricing/rules; 10 equipment provider profiles with 30 items, 10 packages, 30 package links, 10 terms; 10 casting agency profiles with roster links; 10 brand profiles; 10 distribution partner profiles/projects and 20 distributor contacts; 60 availability entries for talent and crew
- Production run: seed executed inside `cineconnect-api` against the deployed MySQL database and reported all slice-1 records created successfully; rerun-safe idempotent keys are based on `DEMO-*` public IDs or natural unique constraints
- Verification: local Docker dry run reached idempotent rerun; production HTTPS smoke login/list checks passed for `dp01@demo.cine.nalexustechnologies.com`, `talent01@demo.cine.nalexustechnologies.com`, and `equipment01@demo.cine.nalexustechnologies.com`; `/health/ready` returned ok
- Incomplete work: blueprint steps for bookings/offers/negotiations/chat, contracts/legal reviews/addendums, payment schedules/proofs/ledger/receipts, operations inspections/damage/safety/insurance claims, brand opportunities/applications/deliverables/metrics, distribution reports, reviews/reports/moderation/disputes/support/announcements/notifications, and export-job polish still need later seed slices
- Exact next task: implement demo data seed slice 2 for bookings, negotiations, conversations, contracts, legal reviews, payments, and ledger records using the slice-1 backbone IDs.

### 2026-07-18 — Demo data seed slice 2

- Goal: continue applying the demo blueprint by adding transactional records on top of the slice-1 users, projects, listings, files, and provider foundations
- Files changed: new `backend/scripts/seed_demo_data_slice2.py`, `docs/IMPLEMENTATION_PROGRESS.md`
- Seeded data: 10 bookings linked to the 10 backbone projects/listings, 20 booking participants, 30 booking status events, 30 offers, 10 negotiation threads, 30 negotiation rounds, 10 booking conversations, 20 conversation members, 100 chat messages, one published demo talent contract template with 5 clauses, 10 contracts, 20 contract parties, 14 signatures, 50 contract clauses, 10 legal review requests, 10 legal risk rows, 3 addendums, 10 legal billing rows, 10 payment schedules, 20 milestones, 10 transactions, 10 payment proofs with pending/approved/rejected variety, 5 receipts, 10 ledger entries for approved payments, 10 fee snapshots, and 10 payout accounts
- Production run: seed executed inside `cineconnect-api` against the deployed MySQL database and reported all slice-2 records created successfully; rerun-safe idempotent keys are based on `DEMO-*` public IDs and natural relationship keys
- Verification: local Docker run created slice 2 and a second local run was fully idempotent; production HTTPS smoke checks passed for Director/Producer bookings/negotiations/contracts/payment schedules, Actor/Talent opportunities/contracts/payments, approved-payment ledger entries, Super Admin dashboard/payment-proof queue, and legal review list; `/health/ready` returned ok
- Incomplete work: operations inspection/damage/safety rows, insurance policies/claims/evidence, agency audition/candidate/self-tape/commission rows, brand opportunities/applications/terms/deliverables/metrics, distribution handover/windows/reports, reviews/reports/blocks/moderation/disputes/support/announcements/notifications, and export-job polish still need later seed slices
- Exact next task: implement demo data seed slice 3 for operations, insurance, agency, brand, distribution, reviews/trust-safety, support/notifications, and export jobs.

### 2026-07-18 — Demo data seed slice 3

- Goal: finish the portal-heavy demo seed data from `docs/CINECONNECT_DEMO_DATA_SEED_BLUEPRINT.md` so operations, insurance, agency, brand, distribution, trust/safety, support, notifications, and exports have linked production rows for walkthroughs
- Files changed: new `backend/scripts/seed_demo_data_slice3.py`, `docs/IMPLEMENTATION_PROGRESS.md`
- Seeded data: 10 location inspections with 10 items, 5 damage claims with 5 evidence rows, 10 equipment inspections with 10 items, 10 safety checks with 20 checklist items, 10 incidents, 10 safety check-ins, 10 insurance partner profiles, 10 insurance policies, 10 insurance claims with 10 evidence rows, 10 audition requests, 30 audition candidates, 20 self-tapes, 20 selection notes, 10 agency commissions, 10 brand opportunities, 30 brand applications, 10 brand terms, 20 campaign deliverables, 20 campaign metrics, 20 release handover items, 20 release windows, 10 distribution reports, 10 reviews with 20 dimensions, 10 review requests, 10 blocked-user rows, 10 reports, 10 moderation cases with 10 events, 10 disputes with evidence/events, 10 support tickets with 20 messages, 3 announcements, 30 notifications with 30 delivery rows, 5 Firebase-style push devices, and 3 completed export jobs
- Production run: seed executed inside `cineconnect-api` against the deployed MySQL database and reported all slice-3 records created successfully; a second production run reported all records as existing, confirming idempotency
- Verification: local Docker run created slice 3 and a second local run was fully idempotent; production HTTPS smoke checks passed for Super Admin dashboard/moderation/disputes/support/announcements/exports, agency profile/auditions, brand profile/opportunities, distribution profile/projects/reports, insurance profile/dashboard/policies/claims, DP disputes/support/notifications/dashboard, talent blocks/notifications, location properties, equipment profile/items, and `/health/ready`; DB-side verification confirmed 10 brand opportunities, 30 applications, and 20 campaign deliverables after the login rate limiter blocked extra rapid logins
- Incomplete work: demo data is now seeded across all major backend/portal areas in the blueprint. Remaining validation is the manual Flutter app/device/browser walkthrough against `https://cine.nalexustechnologies.com/api/v1`; optional future polish can add more edge-case variants if a specific demo script needs them.
- Exact next task: run the real Flutter walkthrough using the demo login handoff and confirm each M0–M10 screen loads the live seeded data; fix any UI-only issues found during that walkthrough.

### 2026-07-18 — M10 production-configured Flutter launch validation

- Goal: continue the remaining M10 validation by proving the Flutter app builds, tests, and boots with the deployed production API URL after all demo data seed slices were applied
- Files changed: `docs/IMPLEMENTATION_PROGRESS.md`
- Checks run: confirmed `lib/core/network/api_config.dart` defaults `CINECONNECT_API_BASE_URL` to `https://cine.nalexustechnologies.com/api/v1`; `flutter analyze` returned no issues; `flutter test --dart-define=CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` passed 361/361 tests; `flutter build web --dart-define=CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` built `build/web`; `flutter run -d chrome --web-port=52173 --dart-define=CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` launched Chrome, connected the debug service, reached `main()`, and served the Flutter app HTML from the local dev server
- Findings: normal JS web build is green. Flutter emitted non-blocking WebAssembly dry-run warnings from `flutter_secure_storage_web` using `dart:html`/`dart:js_util`; that only matters if a future WASM build target is required. `flutter devices` showed macOS, Chrome, and the wireless iPhone, plus a non-blocking Apple Watch discovery warning.
- Incomplete work: this was still not a human screen-by-screen walkthrough. M10 should remain open until someone actually logs into the running app and walks the demo portals visually against `https://cine.nalexustechnologies.com/api/v1`.
- Exact next task: open the app on Chrome/macOS/iPhone, log in with the demo handoff accounts, and manually walk each portal route/golden path; if any screen still shows stale fallback data where live seeded data should appear, patch that specific UI/controller and rerun analyze/tests.

### 2026-07-18 — M10 headless browser route walkthrough and CORS fix

- Goal: push the remaining M10 walkthrough as far as terminal automation allows by running the built Flutter web app in headless Chrome against the production API and capturing route screenshots/errors
- Files changed: `lib/features/actor_talent/screens/at10_earnings_security_screen.dart`, new `tools/m10_browser_walkthrough.py`, generated `docs/M10_BROWSER_WALKTHROUGH_RESULTS.json`, generated `docs/m10_walkthrough_screenshots/`, `docs/IMPLEMENTATION_PROGRESS.md`; production server env `/var/www/cineconnect/release/backend/.env` was updated for CORS and `cineconnect-api` was recreated with the same image/host-network/storage settings
- Backend/deployment: production `CORS_ALLOWED_ORIGINS` now includes `https://cine.nalexustechnologies.com`, `http://localhost:3000`, `http://localhost:53117`, and `http://127.0.0.1:53117`; OPTIONS preflight from `http://127.0.0.1:53117` to `/api/v1/app/bootstrap` now returns `access-control-allow-origin: http://127.0.0.1:53117`; `/health/ready` returned database and Redis ok after the API container restart
- Flutter fix: AT-10 Earnings Security now wraps payout-account loading in a safe fallback future. Before this patch, unauthenticated browser route loading displayed the demo fallback but still left `/payout-accounts` 401 as an uncaught future error in Chrome.
- Verification: `flutter analyze` returned no issues; `flutter test --dart-define=CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` passed 361/361; `flutter build web --dart-define=CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` succeeded; `python3 tools/m10_browser_walkthrough.py` captured 82 screenshots across core, Director/Producer, Actor/Talent, Model, Location, Equipment, Crew, Agency, Brand, Legal, Insurance, Distribution, and Super Admin routes with `event_routes: 0`
- Findings: the automated browser route pass is clean. Flutter still emits non-blocking WASM dry-run warnings from `flutter_secure_storage_web` and a Cupertino icon-font warning during web build; the normal JS web build succeeds.
- Incomplete work: this is still not a human authenticated click-through. A blind coordinate login attempt was not reliable because the headless Flutter accessibility tree exposes only the initial "Enable accessibility" control by default. M10 should remain open until the app is manually logged into and visually walked using the demo handoff accounts.
- Exact next task: launch the app in Chrome/macOS/iPhone, log in with each primary demo account group from `docs/CINECONNECT_DEMO_LOGIN_HANDOFF.json`, visually confirm live seeded data appears in the portal screens, and patch any screen that still shows fallback-only content where live data exists.

### 2026-07-18 — Flutter/backend wiring M9 dashboards, analytics, and exports

- Goal: wire Phase 12 dashboard/analytics/export endpoints into portal dashboards, Super Admin dashboard/analytics, and supported export buttons while using the deployed server endpoints at `https://cine.nalexustechnologies.com/api/v1`
- Files changed: new `lib/core/analytics/` models/repository/controller/widgets, app-level `AnalyticsScope`, generic dashboard, Director/Producer dashboard and reports export, Actor/Talent dashboard, generic role portal dashboard/report surfaces, Casting Agency dashboard, Brand dashboard, Distribution dashboard, Insurance dashboard, Legal dashboard, Super Admin dashboard/analytics/audit CSV, Location Owner ledger export, Media/Equipment earnings export, regenerated UI action inventory, progress docs
- Flutter screens: non-admin dashboards now show live `/me/dashboard` KPI strips with demo fallback; Super Admin Dashboard shows live `/admin/dashboard` queue/platform counts; Admin Analytics shows live `/admin/analytics` range totals; supported CSV actions create real `/exports` jobs for `bookings`, `ledger`, and `admin_disputes`
- Backend/deployment: no backend code or migration was required for M9 because Phase 12 endpoints were already deployed; production HTTPS API was used for the smoke test
- Tests: `flutter analyze` passed; Flutter widget suite passed (361 tests); production HTTPS smoke loaded personal/admin dashboards and admin analytics, then created/listed/fetched `bookings`, `ledger`, and `admin_disputes` export jobs
- Incomplete work: M9 still needs a manual real Flutter app/device/browser validation pass. PDF-only and domain-specific exports remain preview-only where the backend has no matching export type; M10 should document or retire those remaining mock actions rather than mapping them to incorrect CSV types.
- Exact next task: begin M10 cleanup by regenerating and auditing `docs/UI_ACTION_INVENTORY.csv`, documenting deliberately deferred actions, and doing the final demo-data/fallback sweep.

### 2026-07-18 — Flutter/backend wiring M8 reviews, moderation, support, and notifications

- Goal: wire the Phase 11 trust/safety backend into shared review/report/notification flows and Super Admin moderation, dispute, support, broadcast, and review hub screens while using the deployed server endpoints at `https://cine.nalexustechnologies.com/api/v1`
- Files changed: new `lib/core/trust_safety/` models/repository/controller, app-level `TrustSafetyScope`, shared notification center, shared ratings/review, shared report/block, Super Admin content moderation queue/detail, dispute center/case file, support CRM, broadcast announcements, review hub, regenerated UI action inventory, progress docs
- Flutter screens: notification center loads live notifications and marks one/all read; report/block loads live report reasons, submits reports, and blocks when a real reported user id is provided; ratings/review submits live reviews for live booking ids or private complaints as reports; Super Admin pages show live moderation/dispute/support/announcement/review-hub strips above preview content and perform safe live decisions/status/publish actions
- Backend/deployment: no backend code or migration was required for M8 because Phase 11 endpoints were already deployed through Phase 12; production HTTPS API was used for the smoke test
- Tests: `flutter analyze` passed; Flutter widget suite passed (361 tests); production HTTPS smoke created throwaway SQL-only users/project/secured-booking/admin-role fixture, then used public HTTPS API endpoints for review eligibility/create/list/request, report/reasons/block/unblock, moderation decision, dispute create/list/admin decision, support ticket/messages/admin status, announcement create/list/publish, notification list/read/read-all, and push device registration
- Incomplete work: M8 still needs a manual real Flutter app/device/browser validation pass. Dispute evidence upload was already present in the backend and remains endpoint-smoke-ready, but the current shared Flutter dispute UI surface is still represented through report/support/admin screens until M10 cleanup or a dedicated dispute-filing screen is added.
- Exact next task: begin M9 by wiring dashboards, analytics, and exports to the Phase 12 endpoints, unless manual M0–M8 UI validation is performed first

### 2026-07-18 — Flutter/backend wiring M7 agency, brand, model, and distribution

- Goal: wire the Phase 10 specialist backend into Casting Agency, Brand/Sponsors, Model Extension, and Distribution Partner Flutter screens while using the deployed server endpoints at `https://cine.nalexustechnologies.com/api/v1`
- Files changed: new `lib/core/specialist/` models/repository/controller/scope, app-level `SpecialistScope`, Casting Agency dashboard/roster/audition inbox, Brand dashboard/profile/opportunity composer, Model categories/usage-rights/rates/brand-safety screens, Distribution dashboard/contacts/release/reporting screens, regenerated UI action inventory, progress docs
- Flutter screens: agency dashboard/roster/inbox load live profile, roster, and auditions and the inbox attempts live status updates; brand dashboard/profile/composer load/upsert live brand state and publish live opportunities; model categories/usage-rights/rates/restrictions load and mutate live model rules; distribution dashboard/contacts/release/reporting load live profile/projects/contacts/reports and release coordination writes live status notes when available
- Backend/deployment: no backend code or migration was required for M7 because Phase 10 endpoints were already deployed through Phase 12; production HTTPS API was used for the smoke test
- Tests: `flutter analyze` passed; Flutter widget suite passed (361 tests); production HTTPS smoke created throwaway SQL-only users/project/booking/file-ready fixture for self-tape, then used public HTTPS API endpoints for agency profile/invitation/accept/roster/audition/candidate/self-tape/selection-note/commission, brand profile/opportunity/application/status/terms/deliverable/metrics/approval, model profile/categories/usage-rights/usage-rates/restricted-categories, and distribution profile/project/release-window/handover/contact/report
- Incomplete work: M7 still needs a manual real Flutter app/device/browser validation pass. Some deeper portal screens still render demo cards as their main visual surface while showing live banners or performing live mutations; M10 remains the final demo-data retirement sweep.
- Exact next task: begin M8 by wiring reviews, reports, moderation, disputes, support, announcements, notifications, and Super Admin trust/safety screens to the Phase 11 endpoints, unless manual M0–M7 UI validation is performed first

### 2026-07-18 — Flutter/backend wiring M6 location, equipment, safety, and insurance

- Goal: wire the Phase 9 operations/insurance backend into Location Owner, Media/Equipment, and Insurance Partner Flutter screens while using the deployed server endpoints at `https://cine.nalexustechnologies.com/api/v1`
- Files changed: new `lib/core/operations/` models/repository/controller/scope, new `lib/core/insurance/` models/repository/controller/scope, app-level `OperationsScope` and `InsuranceScope`, LO listing wizard, ME provider profile, ME inventory manager, Insurance dashboard, Insurance shoot records, Insurance claim support, backend upload-purpose allow-list, regenerated progress docs
- Flutter screens: LO listing wizard creates a live location property with default space/pricing/rule while preserving demo-store success UX; ME profile loads/upserts live equipment provider profile; ME inventory lists/creates live equipment items; Insurance dashboard/records/claims load live dashboard/policy/claim data and claim support can decide an existing live claim where available
- Backend/deployment: `backend/app/api/verification.py` was updated to allow `location_media`, `equipment_media`, `inspection_evidence`, `damage_evidence`, `insurance_document`, and `insurance_evidence`; the backend image was rebuilt and redeployed on the production server. After deploy, production `.env` was restored to host-network-safe MySQL/Redis URLs because an earlier full backend sync had overwritten it with local Docker service names.
- Tests: `ruff check backend/app/api/verification.py` passed; `ruff format --check backend/app/api/verification.py` passed; `flutter analyze` passed; Flutter widget suite passed (361 tests); production HTTPS smoke created throwaway SQL-only user/project/booking/file-ready fixtures, then used public HTTPS API endpoints for property/space/pricing/rule, location inspection + LO/DP dual confirmation, damage evidence, equipment profile/item/package/term, equipment inspection + EP/DP dual confirmation, safety check/item, incident, talent safety check-in, insurance profile/policy/claim/evidence/decision
- Incomplete work: M6 still needs a manual real Flutter app/device/browser validation pass for the LO/ME/Insurance UI flows. Actor/Talent safety UI is not fully booking-selector wired yet; the production smoke verified the safety endpoints directly. Location/equipment listing media upload purposes are accepted, but a dedicated location/equipment listing-media attachment table/API is still absent, so screens keep demo media previews while live records are created/listed.
- Exact next task: begin M7 by wiring Casting Agency, Brand/Sponsors, Model Extension, and Distribution Partner screens to the Phase 10 endpoints, unless manual M0–M6 UI validation is performed first

### 2026-07-18 — Flutter/backend wiring M5 payments and finance

- Goal: wire signed-contract payment schedules into proof upload, shared ledger, Director/Producer payment center, Actor/Talent earnings/security, and Super Admin finance review screens using the deployed Phase 8 API
- Files changed: new `lib/core/payments/` models/repository/controller/scope, app-level `PaymentsScope`, shared payment proof upload and receipts ledger screens, DP payment center, AT earnings/security screen, Super Admin payments hub/queue/review route argument handling, regenerated UI action inventory, progress docs
- Flutter screens: shared payment proof screen loads live milestones, uploads a real `payment_proof` file through `UploadRepository`, and submits `/payment-proofs`; shared ledger lists live `/ledger` rows; DP payment center reads `/payments/dashboard`; AT earnings/security reads dashboard/payout accounts and can create a sandbox payout account; Super Admin payments hub/queue/review read `/admin/payment-proofs`, show live proof IDs/status/risk, and approve/reject/ask clarification through `/admin/payment-proofs/{id}/decision`
- Backend/deployment: no backend code or migration was required for M5 because Phase 8 endpoints were already deployed through Phase 12; no production container rebuild was needed
- Tests: `flutter analyze` passed; Flutter widget suite passed (361 tests); production HTTPS smoke created fresh producer/talent/finance users, approved only throwaway talent KYC and finance-role/file-ready fixtures directly in SQL, accepted a booking, signed a contract, loaded the payment schedule, uploaded a real PDF payment proof, submitted it, approved it as finance admin, fetched producer ledger and receipt, and confirmed the booking moved to `secured` with the milestone `verified`
- Incomplete work: M5 still needs a manual real Flutter app/device/browser validation pass for proof picking, finance review UI button flows, and receipt viewing UX. Real bank/card provider integration remains intentionally sandbox/dummy until payment provider credentials and operating procedures are supplied.
- Exact next task: begin M6 by wiring Location Owner, Media/Equipment, safety, and Insurance Partner screens to the Phase 9 operations/insurance endpoints, unless manual M0–M5 UI validation is performed first

### 2026-07-18 — Flutter/backend wiring M4 contracts and legal

- Goal: wire accepted bookings into contract generation, shared contract viewing/signing, addendum requests, and Legal Partner review decisions using the deployed Phase 7 API
- Files changed: new `lib/core/contracts/` models/repository/controller/scope, app-level `ContractsScope`, shared contract viewer, DP contract center, AT contract signing, Legal Partner dashboard/review/template/addendum/history screens, route argument forwarding for legal review detail, regenerated UI action inventory, progress docs
- Flutter screens: DP contract center lists live contracts, generates a contract from an accepted booking, opens the shared viewer, and requests legal review; AT contract signing lists live contract records and opens the viewer for signature/correction; shared contract viewer loads `CTR-*` contracts, signs through `POST /contracts/{id}/signatures`, and creates addendum requests; Legal dashboard/review detail list and decide live legal review requests; Legal template/addendum/history screens surface live templates/reviews/addendums where available while retaining demo fallback
- Backend/deployment: no backend code or migration was required for M4 because Phase 7 endpoints were already deployed through Phase 12; production HTTPS API was used for the smoke test
- Tests: `flutter analyze` passed; Flutter widget suite passed (361 tests); production HTTPS smoke created fresh producer/talent/legal users, approved only the throwaway talent KYC directly in SQL for publish eligibility, accepted a booking, generated a contract, signed as producer and talent, created an addendum, requested legal review, listed it as a legal partner, and approved it
- Incomplete work: M4 still needs a manual real Flutter app/device/browser validation pass for generate → open viewer → sign both parties → legal decision. Signature file upload/drawn-signature media remains optional because the backend supports metadata-only signatures when no signature file is supplied.
- Exact next task: begin M5 by wiring payment schedules, payment proof upload, receipt/ledger, earnings, and finance-admin review screens, unless manual M0–M4 UI validation is performed first

### 2026-07-18 — Flutter/backend wiring M3 bookings, negotiation, availability, and chat

- Goal: wire the Phase 6 booking flow across Director/Producer, Actor/Talent, and shared chat screens using the deployed HTTPS API as the source of truth
- Files changed: new `lib/core/bookings/` models/repository/controller/scope, `main.dart` app-level `BookingsScope`, DP booking request/bargaining/negotiation screens, AT availability/opportunity/offer/counteroffer screens, shared booking chat route/screen, shared chat message model, regenerated UI action inventory, progress docs
- Flutter screens: DP booking request now selects live project/listing data and creates/sends bookings; DP bargaining center lists live negotiation threads; DP negotiation thread loads live rounds and can counter/accept; AT availability lists/saves manual server entries; AT opportunity inbox lists provider-side opportunities and can accept active offers; AT offer detail loads/rejects/accepts live bookings; AT counteroffer composer creates live counteroffers for `BKG-*` ids; shared booking chat fetches/sends REST messages and calls the pin endpoint from message actions; screens retain demo/offline fallback behavior for preview routes and isolated widget tests
- Backend/deployment: no new backend code or migration was required for M3 because Phase 6 endpoints were already deployed through Phase 12; the live server API at `https://cine.nalexustechnologies.com/api/v1` was used for the smoke test
- Tests: `flutter analyze` passed; Flutter widget suite passed (361 tests); production HTTPS smoke created fresh producer/talent users, approved only the throwaway talent KYC directly in SQL for publish eligibility, published a talent listing, created availability/project/requirement, sent a booking, created a talent counteroffer, accepted it as producer, created a chat message, and successfully called the pin endpoint
- Incomplete work: M3 still needs a manual real Flutter app/device/browser validation pass for offer → counter → accept → chat visibility on both accounts; REST chat currently refreshes on load/send rather than WebSocket live updates, which matches the M3 plan and leaves realtime as a later enhancement
- Exact next task: begin M4 by wiring accepted bookings to contract generation/view/sign/legal review flows, unless manual M0–M3 UI validation is performed first

### 2026-07-18 — Flutter/backend wiring M2 projects, requirements, and project room

- Goal: wire Director/Producer Phase 5 project workflows against the deployed project endpoints
- Files changed: new `lib/core/projects/` models/repository/controller/scope, `AuthController.apiClient` getter for authenticated shared client reuse, Director/Producer project list/create/detail/requirement/room screens, upload allow-list for `project_document`, OpenAPI upload-purpose enum, regenerated UI action inventory, progress docs
- Flutter screens: projects list loads live `GET /projects`; create wizard posts to `POST /projects` and opens the returned project hub; project detail loads `GET /projects/{id}` and passes live ids into requirements/room; requirement builder loads `GET /projects/{id}/requirements` and creates requirements; project room loads `GET /projects/{id}/room`, pins decisions through `POST /projects/{id}/room/items`, and uploads/link files through `UploadRepository` plus `POST /projects/{id}/files`; each screen keeps the existing demo fallback where appropriate
- Backend/deployment: added `project_document` upload purpose, updated OpenAPI, rebuilt/restarted production API/worker/scheduler, corrected production env host-network settings for MySQL/Redis, and set `API_PUBLIC_URL=https://cine.nalexustechnologies.com` so presigned PUT URLs are externally reachable
- Tests: `ruff check backend/app/api/verification.py` passed; OpenAPI parse passed; `flutter analyze` passed; Flutter widget suite passed (361 tests); production HTTPS smoke created/listed/fetched a project, created a requirement, pinned a room decision, uploaded real `project_document` bytes, linked a project file, and confirmed the project room aggregate persisted both the file and decision
- Incomplete work: M2 still needs a manual real Flutter app/device/browser validation pass for create project → add requirement → room decision/file upload before marking the milestone checkbox complete
- Exact next task: begin M3 by wiring booking request, negotiation/bargaining, availability, opportunity inbox, offer detail/counteroffer, and REST chat flows, unless manual M0–M2 UI validation is performed first

### 2026-07-18 — Flutter/backend wiring M1 portfolio and showreel

- Goal: finish the Actor/Talent AT-03 portfolio/showreel gap against the deployed Phase 4 portfolio endpoints
- Files changed: portfolio Dart model, `AuthRepository`/`AuthController` portfolio methods, `at03_portfolio_showreel_screen.dart`, regenerated UI action inventory, progress docs
- Flutter screens: Actor/talent portfolio now loads live `GET /portfolio?profile_type=talent`, uploads picked JPG/PNG/WebP/MP4 files through `UploadRepository` with `purpose: "profile_media"`, retries portfolio creation briefly while the production file-scan worker marks the upload `clean/ready`, and supports cover/edit, reorder, and delete through `PATCH/DELETE /portfolio/{id}`; unauthenticated/offline/profile-missing state keeps the existing demo portfolio fallback with a warning
- Tests: `flutter analyze` passed; Flutter widget suite passed (361 tests); production HTTPS smoke created a talent profile, uploaded real media bytes to `https://cine.nalexustechnologies.com/api/v1`, created/listed/patched/deleted a portfolio item
- Incomplete work: M0 and M1 still need one manual real Flutter app/device/browser picker validation before their checkboxes are marked complete; automated implementation and production endpoint smoke are complete
- Exact next task: begin M2 by wiring Director/Producer project list/create/detail/requirements screens to Phase 5 project endpoints, unless manual picker validation is performed first

### 2026-07-18 — Flutter/backend wiring M1 saved searches and shortlist board

- Goal: begin M1 by closing Director/Producer saved-search management and shortlist board gaps against the already-deployed Phase 4 endpoints
- Files changed: `ApiClient.delete`, marketplace saved-search/shortlist Dart models, `AuthRepository`/`AuthController` methods, `dp_shortlist_board_screen.dart`, regenerated UI action inventory, progress docs
- Flutter screens: Director shortlist board now loads live saved searches and shortlist boards from `GET /saved-searches` and `GET /shortlists`, supports saved-search delete, shortlist item remove, rank up/down, and selected/unselected status toggling through `DELETE /saved-searches/{id}`, `DELETE /shortlist-items/{id}`, and `PATCH /shortlist-items/{id}`; unauthenticated/offline state keeps the existing demo shortlist fallback with a warning
- Tests: `flutter analyze` passed; Flutter widget suite passed (361 tests); production HTTPS smoke created/listed/deleted a saved search and created/listed a shortlist board against `https://cine.nalexustechnologies.com/api/v1`
- Incomplete work: M1 portfolio/showreel CRUD and real portfolio media upload are still pending; full shortlist item mutation from the UI needs a live marketplace listing added to the board through the app flow
- Exact next task: wire `AT-03 Portfolio & Showreel` to `GET/POST/PATCH/DELETE /portfolio` using `UploadRepository` with `purpose: "profile_media"`

### 2026-07-18 — Flutter/backend wiring M0 local binary upload foundation

- Goal: follow `docs/CINECONNECT_FLUTTER_WIRING_PLAN.md` M0 and replace metadata-only uploads with real file bytes
- Files changed: upload/session model, verification API, local storage service, migration, Docker/storage backup/Nginx docs, OpenAPI, Flutter dependencies, API client, upload repository, KYC verification screen, tests, progress docs, UI action inventory
- Migration(s): `a7b8c9d0e1f2` upload binary storage
- Backend endpoints: `POST /uploads/presign` now returns a `PUT /uploads/{id}/binary` URL; `PUT /uploads/{id}/binary` streams bytes to local disk and records server-computed size/checksum; `POST /uploads/{id}/complete` refuses sessions without received bytes; `GET /files/{id}/download` serves owner-only private downloads
- Flutter screens: KYC upload now uses `file_picker`/`image_picker` and `UploadRepository.uploadFile()` for presign → raw PUT → complete; old demo upload helper remains as a fallback path but now uses the same real upload pipeline
- Tests: backend Ruff passed; Flutter analyze passed; Flutter widget suite passed (361 tests); local migration applied; focused KYC binary integration passed; full backend MySQL/Redis suite passed (43 tests)
- Production deployment: rsynced backend/docs/deploy assets to `/var/www/cineconnect/release`, created `/var/www/cineconnect/storage/{private,public}`, added local-storage env values, installed the Nginx `/media/` alias, rebuilt `cineconnect-prod-api:latest`, applied migration `a7b8c9d0e1f2`, recreated `cineconnect-api`/`cineconnect-worker`/`cineconnect-scheduler` with `/var/www/cineconnect/storage:/data/storage`, and verified `/api/v1/health/ready`
- Production verification: HTTPS binary upload smoke passed against `https://cine.nalexustechnologies.com/api/v1` (`POST /uploads/presign` → `PUT /uploads/{id}/binary` → `POST /uploads/{id}/complete` → authenticated `GET /files/{id}/download`); the file landed under `/var/www/cineconnect/storage/private/...`; unauthenticated download returned 401; storage backup script produced a real tarball under `/var/backups/cineconnect`
- Flutter endpoint change: `ApiConfig.baseUrl` now defaults to `https://cine.nalexustechnologies.com/api/v1` so app builds connect to the deployed backend unless `CINECONNECT_API_BASE_URL` is supplied
- Incomplete work: manual app/device/browser picker upload was not run in this environment, so M0 remains unchecked in `CINECONNECT_FLUTTER_WIRING_PLAN.md`
- Exact next task: run the app and complete one real KYC file pick/upload from the UI against `https://cine.nalexustechnologies.com/api/v1`; if it succeeds, mark M0 complete and move to M1

### 2026-07-18 — Phase 9 gap closure: insurance partner profiles, policies, and claims

- Goal: the user asked whether Phase 9 was actually complete; checking the master report against what was built showed the original 2026-07-17 Phase 9 pass only implemented location/equipment/safety (7.7-7.10 subset) and explicitly listed "insurance policies/claims" as incomplete in its own session log — the Insurance/Safety portal (section 7.13, screens IN-01 through IN-03) was never built. This entry closes that gap.
- Files changed: new `app/models/insurance.py` (`InsurancePartnerProfile`, `InsurancePolicy`, `InsuranceClaim`, `InsuranceClaimEvidence`); new `app/api/insurance.py` (profile upsert, policy create/list/detail, claim create/list/detail/evidence/decision, provider dashboard); migration; OpenAPI; backend integration tests; progress docs
- Migration(s): `0f25fa31c34f` insurance partner profiles, policies, claims, and claim evidence
- Endpoints: `/insurance/profile` get/upsert; `/insurance/policies` create/list, `/insurance/policies/{id}` detail; `/insurance/claims` create/list, `/insurance/claims/{id}` detail, `/insurance/claims/{id}/evidence` create, `/insurance/claims/{id}/decision` (investigating/approved/rejected/settled); `/insurance/dashboard`
- Tests: backend lint/format/typing pass; MySQL/Redis integration suite has 43 tests with 86.32% coverage; OpenAPI parse passes with 181 paths and 235 schemas
- Verification: policies/claims are scoped to the provider owner or the insured/claimant/adjuster party; only the provider that owns the policy can decide a claim (a non-owner attempt is rejected with 403, verified in tests); license numbers are tokenized placeholders matching the existing private-field pattern
- Redeployment: rsynced, rebuilt the image, ran the new migration against production, recreated all three containers, and verified live over HTTPS (profile upsert, policy create, dashboard)
- Verification note for the user: this closes the specific gap they asked about (insurance policies/claims). Phase 9's other previously-listed gaps remain open and unchanged: public location/equipment marketplace publishing, real encrypted exact-address unlock policy, deposit release automation, offline draft sync, and Flutter location/equipment/insurance/safety screen connections
- Exact next task: continue with Flutter screen wiring, or work through the remaining external inputs listed in `docs/DEPLOYMENT_INPUTS.md`

### 2026-07-18 — Phase 12 analytics/exports/hardening, and redeployment

- Goal: add the backend-buildable slice of Phase 12 that doesn't depend on still-missing external accounts (R2, SES/FCM/SMS, a monitoring/backup vendor decision) — dashboards, an export mechanism, Sentry wiring, database backups, and a dependency security pass — then ship it to the same production deployment from earlier today
- Files changed: new `app/models/analytics.py` (`ExportJob`); new `app/api/analytics.py` (`/me/dashboard`, `/admin/dashboard`, `/admin/analytics`, `/exports` create/list/detail); `app/__init__.py` (Sentry SDK init, safe no-op when `SENTRY_DSN` is empty); `app/api/trust_safety.py` (removed a 500-user cap on announcement fan-out that was silently dropping recipients); `backend/pyproject.toml` (`cryptography` and `pytest` version bumps); new `deploy/nginx/cine.nalexustechnologies.com.conf` (source-controlled copy of the live vhost); new `deploy/scripts/backup_db.sh`; migration; OpenAPI; backend integration tests; progress docs
- Migration(s): `81af73d41ffc` `export_jobs` (synchronous CSV export records)
- Endpoints: personal dashboard (offers/secured value/rating/notifications/disputes/tickets/KYC), admin dashboard (KYC SLA, payment/moderation/dispute/ticket queue counts, user count, calculated platform fees, conversion rate), admin analytics (daily user/booking/secured-booking counts over a 1-90 day window), export create/list/detail for `ledger`, `bookings`, and `admin_disputes`
- Tests: backend lint/format/typing pass; MySQL/Redis integration suite has 42 tests with 86.27% coverage; `pip-audit` found 7 known CVEs in `cryptography` 45.0.7 and `pytest` 8.4.2 (fixed, re-scan clean); OpenAPI parse passes with 173 paths and 229 schemas
- Verification: `secured_value_minor`/`calculated_platform_fees_minor` are cast to `int` because MySQL returns `SUM()` results as `Decimal`/string via pymysql; KYC `submitted_at` timestamps read back from MySQL are naive and had to be treated as UTC before subtracting from `utcnow()` (a real bug caught by the dashboard test, not a flaky test); exports are capped at 2,000 rows and stored inline since no object storage exists yet; a non-admin `admin_disputes` export attempt is recorded as a failed job with the 403 preserved rather than silently succeeding
- Production hardening actually applied to the live server: daily `mysqldump | gzip` backup cron (02:00 UTC, 14-day local retention, root-only credentials file) installed and verified with a real run (128 tables dumped); Sentry SDK wired but inert until a DSN is supplied (still a known blocker); dependency upgrades carried into the redeployed image
- Redeployment: rsynced the updated `backend/` (preserving the server's own `.env`), rebuilt the Docker image, ran the new migration against the production database, recreated all three containers, and re-ran the external HTTPS smoke test against `https://cine.nalexustechnologies.com` — `/me/dashboard`, `/exports` create/list/detail, and the `/admin/dashboard` 403-for-non-admin check all passed live
- Known gaps carried forward unchanged: Cloudflare R2, SES/FCM/SMS, a monitoring dashboard destination (Sentry has no DSN yet), off-site backup shipping, staging UAT, admin org structure, and load/accessibility testing are all still open; per-role portal dashboards beyond `/me/dashboard` and Flutter screen wiring across every phase remain outstanding
- Exact next task: decide and supply the remaining external inputs in `docs/DEPLOYMENT_INPUTS.md` (object storage, email/push/SMS, monitoring destination, backup off-siting, admin team structure) so this deployment can be honestly relabeled `production`; in parallel, begin connecting Flutter screens to the now-complete Phase 4-12 backend surface

### 2026-07-18 — First production deployment to cine.nalexustechnologies.com

- Goal: deploy the Phase 0-11 backend to the real production server and domain the user provided, without disrupting the ~14 unrelated production sites sharing the same CloudPanel host
- Server recon before any change: confirmed OS/disk/memory, found Docker 29.1.3 present but no `docker compose` plugin, found an existing hand-created Nginx vhost + Certbot certificate for `cine.nalexustechnologies.com` serving a `{"status":"provisioning"}` placeholder from `/var/www/cineconnect/bootstrap`, confirmed the `cineconnect` MySQL database existed and was empty (0 tables), confirmed Redis has no password and is shared with other apps, confirmed ports 5000/5001/5010 were already bound by unrelated sites
- Files changed on the server (not in git): `/var/www/cineconnect/release/` (rsynced `backend/` + `docs/openapi.yaml`), `/var/www/cineconnect/release/backend/.env` (generated fresh on the server, mode 600, never transferred from local), `/var/www/cineconnect/release/compose.prod.yaml` (reference only; actual run used plain `docker build`/`docker run` since no compose plugin was available), `/etc/nginx/sites-available/cine.nalexustechnologies.com.conf` (backed up before edit; `location /` changed from the placeholder JSON response to `proxy_pass http://127.0.0.1:5002`)
- Migration(s): all 15 existing revisions (`efc80f32cc35` through `de636c6a400c`) applied to the production `cineconnect` database for the first time; verified 129 tables and correct role/skill/city seed rows afterward
- Runtime: three Docker containers (`cineconnect-api` gunicorn on `127.0.0.1:5002`, `cineconnect-worker`, `cineconnect-scheduler`) with `--network host` so they reach the host's existing MySQL (3306) and Redis (6379, DBs 3/4/5) directly; `--restart unless-stopped`, Docker enabled at boot
- Tests: production migration run, container health checks, `nginx -t` (pre-existing unrelated warnings only) before reload, external HTTPS smoke test covering register/login/`/me`/`/cities`/`/brand-opportunities`/`/notifications` against the live domain — all pass
- Verification: DB password containing `/` had to be percent-encoded (`%2F`) in the SQLAlchemy DSN; confirmed other ~14 sites on the host still resolve after the Nginx reload; confirmed no mysql/redis containers were started (reused the host's existing shared instances instead of the local dev compose stack)
- Decisions made: run with `APP_ENV=staging` rather than `production` because the app's own `Config.validate()` forbids booting in `production` while `PAYMENT_MODE=sandbox`, and there is no real payment gateway yet — labeling this `production` would misrepresent it; deploy via plain Docker commands rather than CloudPanel's native Python site type, to avoid CloudPanel regenerating the existing hand-maintained vhost/cert
- Known gaps carried forward unchanged: Cloudflare R2, SES/FCM/SMS, monitoring/backup ownership, and admin org structure are all still unset, so uploads, real email/push/SMS, and admin account provisioning remain unavailable in this deployment; a restricted deploy user should replace root for routine deploys
- Exact next task: begin Phase 12 (analytics, exports, hardening, production) — including deciding on the missing credentials above before this deployment can be honestly relabeled `production`

### 2026-07-18 — Phase 11 reviews, moderation, disputes, support, and communications foundation

- Goal: implement the first reviews/reputation path, user reports and blocks, moderation case queue, dispute filing/evidence/admin decision path, support ticket/message path, and announcement/notification delivery path
- Files changed: new `app/models/trust_safety.py` (reviews/dimensions/requests, blocked users, reports, moderation cases/events, disputes/evidence/events, support tickets/messages, announcements, notifications/deliveries, push devices); new `app/services/notifications.py` (in-app/push delivery helper); new `app/api/trust_safety.py` (all Phase 11 endpoints); migration; OpenAPI; backend integration tests; progress docs
- Migration(s): `de636c6a400c` reviews/review_dimensions/review_requests, blocked_users, reports, moderation_cases/moderation_events, disputes/dispute_evidence/dispute_events, support_tickets/support_messages, announcements, notifications/notification_deliveries, push_devices
- Endpoints: review eligibility check, review create, public user reviews, review request create; report reasons, report create (auto-opens a moderation case for non-user entities), blocked-user create/list/delete; admin moderation case create/list/detail/decision; dispute create/list/detail/evidence, admin dispute list/detail/decision; support ticket create/list/detail/messages, admin support ticket queue/update; admin announcement create/list/publish; notification list/read/read-all; push device register
- Tests: backend lint/format/typing pass; MySQL/Redis integration suite has 40 tests with 85.93% coverage; OpenAPI parse passes with 168 paths and 226 schemas; Docker API/worker/scheduler rebuilt; container HTTP review/report/support/notification smoke test passes
- Verification: reviews require a secured booking, are limited to one per reviewer/reviewee pair, and recompute the reviewee's published-only rating average; a pending review request is marked completed when the counterpart submits their review; non-user reports automatically open a linked moderation case; moderation/dispute/support admin actions are gated by hidden admin roles (reviewer/super-admin, reviewer/finance-admin/super-admin, and support-agent/reviewer/super-admin respectively), which cannot be selected at signup and must be granted directly, matching the existing finance-admin pattern; support-ticket internal notes are hidden from the ticket owner; dispute decisions and non-internal support replies notify the affected users through the sandbox notification service; announcement publish fans out notifications to the matching role audience; push device tokens are tokenized placeholders
- Incomplete work: real SES/FCM/SMS provider integration (sandbox in-app/push simulation only), moderation/dispute/support dashboards and SLA analytics (deferred to Phase 12 per the roadmap), CSV/export endpoints, audit-log explorer, admin role/permission management UI, and Flutter reviews/report/moderation/dispute/support/announcement screen connections
- Exact next task: connect the shared ratings/report/notification screens and Super Admin review-hub/dispute-center/support-CRM/broadcast screens to the Phase 11 endpoints, or proceed to Phase 12 analytics/exports/hardening/production

### 2026-07-18 — Phase 10 agency, brand, model, and distribution extensions foundation

- Goal: implement the first agency roster/audition/self-tape/notes/commission backend path, brand opportunity/application/terms/deliverable/metrics path, complete model rights/rates/restrictions, and distribution contacts/releases/handovers/reports path
- Files changed: model-extension tables added to `app/models/marketplace.py`; new `app/models/specialist.py` (agency/brand/distribution models); new `app/api/specialist.py` (all Phase 10 endpoints); `app/api/marketplace.py` portfolio endpoints extended to accept `profile_type=model`; migration; OpenAPI; backend integration tests; progress docs
- Migration(s): `f32946609750` casting agencies/invitations/roster/audition requests/candidates/self-tapes/selection-notes/commissions; brand profiles/opportunities/applications/terms/campaign deliverables/metrics; model profiles/campaign-categories/usage-rights/usage-rates/restricted-categories; distribution partner profiles/projects/contacts/handover-items/release-windows/reports
- Endpoints: agency profile upsert/get; agency invitations create/list/accept; agency roster list; audition request create/list/update; audition candidate add/update; self-tape submit; selection note add; agency commission create/list; brand profile upsert/get; brand opportunity create/list (public + owner)/detail; brand application create/list/update; brand terms create (versioned); campaign deliverable create/list/proof/approve; campaign metric create; model profile upsert/get; model campaign-categories get/replace; model usage-rights create/list/update; model usage-rates create/list/update; model restricted-categories get/replace; distribution partner profile upsert/get; distribution project create/list/update; release window create; release handover item create/update; distributor contact create/list/update; distribution report create/list
- Tests: backend lint/format/typing pass; MySQL/Redis integration suite has 35 tests with 85.77% coverage; OpenAPI parse passes with 140 paths and 207 schemas; Docker API/worker/scheduler rebuilt; container HTTP agency/brand/model/distribution smoke test passes
- Verification: agency profile/roster/audition/commission actions are agency-owner scoped; audition candidates carry separate agency-note/director-note fields writable only by the respective party; self-tape submission requires the candidate's own talent-profile user; brand opportunity applications are open to any authenticated user while status/terms/deliverable decisions are brand-owner scoped; model profile auto-creates a backing talent profile when missing and reuses the existing portfolio endpoints via `profile_type=model`; distribution project/contact/report actions are partner-owner scoped; brand billing details and distributor contact email/phone remain tokenized placeholders, matching the existing private-address/serial/coordinate pattern
- Incomplete work: agency/brand/model/distribution dashboards and analytics (deferred to Phase 12 per the roadmap), CSV/export endpoints, crew/insurance portal tables (out of the Phase 10 roadmap scope), admin moderation of agency/brand trust status, real field-level encryption for tokenized fields, and Flutter agency/brand/model/distribution screen connections
- Exact next task: connect CA/BR/MD/DS Flutter screens to the Phase 10 endpoints, or proceed to Phase 11 reviews/moderation/disputes/support/communications

### 2026-07-17 — Phase 9 location, equipment, and safety workflow foundation

- Goal: implement the first operations/safety backend path for location/equipment inspections, damage claims, safety checks, incidents, and check-ins
- Files changed: operations models/API, migration, OpenAPI, backend integration tests, progress docs
- Migration(s): `f6a7b8c9d0e1` location properties/spaces/pricing/rules/inspections/items, damage claims/evidence, equipment provider profiles/items/packages/package-items/terms/inspections/items, safety checks/items, incidents, and safety check-ins
- Endpoints: location property list/create; spaces/pricing/rules create; location inspection create/item/confirm; damage claim/evidence create; equipment profile upsert/get; equipment item/package/package-item/term create; equipment inspection create/item/confirm; safety check/item create; incident create; safety check-in create/complete
- Tests: backend lint/format/typing pass; MySQL/Redis integration suite has 31 tests with 86.08% coverage; OpenAPI parse passes with 102 paths and 166 schemas
- Verification: private location address, equipment serial, and check-in coordinates are tokenized placeholders and not returned; inspection records require booking requester/provider ownership; location/equipment inspections require dual confirmation; damage evidence is claim-party scoped; safety checks/incidents require project membership; safety check-ins require booking participation
- Incomplete work: public location/equipment marketplace publishing, real encrypted exact-address unlock policy, deposit release automation, offline draft sync, insurance policies/claims, admin safety queues, exports/analytics, and Flutter location/equipment/safety screen connections
- Exact next task: connect LO/ME/AT safety screens to Phase 9 endpoints, or proceed to Phase 10 agency/brand/model/distribution extensions

### 2026-07-17 — Phase 8 payments and finance sandbox foundation

- Goal: implement the first safe payment/finance backend path with sandbox manual bank/card proof review, receipt issuance, ledger posting, and booking securement
- Files changed: payment/finance models, payment API, payment service, contract signature schedule hook, migration, OpenAPI, backend integration tests, progress docs
- Migration(s): `e5f6a7b8c9d0` payment schedules, milestones, transactions, proofs, receipts, ledger entries, fee rules/snapshots, payout accounts, and payouts; seeded `FEE-TALENT-SANDBOX-001`
- Endpoints: payments dashboard, payment schedule list/detail, proof submission, ledger, receipt detail, payout account list/create, admin payment proof queue/detail/decision
- Tests: backend lint/format/typing pass; MySQL/Redis integration suite has 30 tests with 85.76% coverage; OpenAPI parse passes with 80 paths and 150 schemas
- Verification: signed contracts create one sandbox payment schedule/milestone; proof submission is payer-only and idempotency-key protected; client cannot mark proof verified; finance role approval posts payer debit/payee pending-release credit, issues receipt, and moves booking to `secured`; payout account stores only sandbox/masked metadata
- Incomplete work: real payment gateway webhooks, real bank details, escrow/release rules, tax calculations, payout execution, CSV exports, admin assignment queues, and Flutter payment/admin screen connections
- Exact next task: connect DP-14/AT-10/admin payment screens to Phase 8 endpoints, or proceed to Phase 9 location/equipment/safety workflows

### 2026-07-17 — Phase 7 contracts and legal foundation

- Goal: implement the first contract/legal backend path where an accepted booking produces a contract, both parties sign, legal can review, and parties can request addendums
- Files changed: contract/legal models, contract/legal API, migration, OpenAPI, backend integration tests, progress docs
- Migration(s): `d4e5f6a7b8c9` contract templates/clauses, contracts, parties, clauses, signatures, addendums, legal reviews/risks, and billing records; seeded `TPL-TALENT-001` talent engagement template
- Endpoints: contract template list; current-user contract list/detail; accepted-booking contract generation; contract signature; addendum creation; legal review request/list/detail/decision
- Tests: backend lint/format/typing pass; MySQL/Redis integration suite has 29 tests with 86.32% coverage; OpenAPI parse passes with 70 paths and 130 schemas
- Verification: contract generation requires an accepted booking and the requester; contract visibility/signing is limited to contract parties; duplicate signatures are idempotent by party; legal review queue/decision is limited to legal/admin roles; addendum creation automatically queues legal review
- Incomplete work: rendered PDF generation, e-signature provider integration, legal clause risk editing UI, contract template admin workflow, notification events, and Flutter contract/legal screen connections
- Exact next task: connect DP-13/AT-09 contract viewer/signature screens to Phase 7 endpoints, or proceed to Phase 8 payments/finance foundation with dummy manual bank/card rails

### 2026-07-17 — Phase 6 booking, negotiation, availability, and chat foundation

- Goal: implement the first end-to-end booking flow where a producer sends an offer, talent counters, producer accepts, chat persists, and provider availability is locked
- Files changed: booking/availability/conversation models, booking API, migration, OpenAPI, backend integration tests, progress docs
- Migration(s): `c3d4e5f6a7b8` bookings, participants, status events, offers, negotiation threads/rounds, availability calendars/entries, conversations, members, messages, attachments, and pinned decisions
- Endpoints: availability check; booking create/detail/send/reject; negotiation list/detail; booking offer create; offer accept; conversation messages list/create; message pin
- Tests: backend lint/format/typing pass; MySQL/Redis integration suite has 28 tests with 87% coverage; OpenAPI parse passes with 57 paths and 111 schemas; Docker API/worker/scheduler rebuilt; container HTTP booking/negotiation/chat smoke test passes
- Verification: producer cannot book without project membership; booking provider is derived from approved public listing owner; offers are revisioned and old active offers become superseded; only the active offer recipient can accept; accepted offer writes status events, locks negotiation, sets booking agreed amount, and creates a provider availability entry; conversation messages are member-scoped and can be pinned as decisions
- Incomplete work: explicit viewed state, booking list/inbox endpoints, availability manual block CRUD, realtime websocket events, chat pagination/read receipts, admin booking monitor, and Flutter booking/negotiation/chat screen connections
- Exact next task: add booking inbox/list endpoints and manual availability blocks, then connect DP-10/DP-12 and AT-06/AT-08 screens to the Phase 6 API

### 2026-07-17 — Phase 6 booking inbox and availability blocks

- Goal: add the backend surface needed by booking inbox/opportunity/calendar screens after the initial offer flow
- Files changed: booking API, OpenAPI, backend integration tests, progress docs
- Migration(s): none; uses `c3d4e5f6a7b8` Phase 6 tables
- Endpoints: booking participant list with role/status filters, talent opportunities alias, availability list/create/update/delete
- Tests: backend lint/format/typing pass; MySQL/Redis integration suite has 28 tests with 86% coverage; OpenAPI parse passes with 60 paths and 116 schemas; Docker API/worker/scheduler rebuilt; container HTTP availability/inbox smoke test passes
- Verification: producer booking inbox returns requester bookings; talent opportunities returns provider bookings; accepted bookings appear as locked availability entries; booking-generated availability cannot be manually deleted; overlapping manual holds are rejected; manual holds can be created, updated, and deleted
- Incomplete work: richer pagination, viewed/read state, booking list sorting facets, calendar month aggregation, manual open-slot semantics, Flutter DP/AT screen connections
- Exact next task: connect DP booking request/bargaining screens and AT opportunity/counteroffer screens to the Phase 6 API, or add contracts/legal Phase 7 foundation

### 2026-07-17 — Phase 5 projects and requirements foundation

- Goal: implement the project, project member, requirement, and skills foundation needed for DP-02 through DP-05 and future project-room collaboration
- Files changed: project models/API, migration, OpenAPI, backend integration tests, progress docs
- Migration(s): `a1b2c3d4e5f6` projects, project members, requirements, requirement skills, and seeded skills catalog
- Endpoints: skill catalog, project list/create/detail/update, project members list, project requirements list/create, requirement update
- Tests: backend lint/format/typing pass; MySQL/Redis integration suite has 26 tests with 87% coverage; OpenAPI parse passes with 43 paths and 85 schemas; Docker API/worker/scheduler rebuilt; container HTTP project/requirement smoke test passes
- Verification: actor/talent users cannot create projects; projects are scoped to active members; non-members receive 404; owners can update project settings; requirements validate dates/budgets/status and reference active skills by public ID
- Incomplete work: project member invite/update flows, project files, project room activity/decisions, director Flutter project screens, and shortlist validation against real project/requirement IDs
- Exact next task: connect DP projects list/create/detail/requirement builder to the Phase 5 endpoints, then add project room members/files/activity

### 2026-07-17 — Phase 5 project room files and decisions

- Goal: add the backend project-room foundation for linked project files and pinned room notes/decisions/activity
- Files changed: project models/API, migration, OpenAPI, backend integration tests, progress docs
- Migration(s): `b2c3d4e5f6a7` project files and project room items
- Endpoints: project room aggregate, project room item create, project files list/link
- Tests: backend lint/format/typing pass; MySQL/Redis integration suite has 27 tests with 87% coverage; OpenAPI parse passes with 46 paths and 94 schemas; Docker API/worker/scheduler rebuilt; container HTTP project-room smoke test passes
- Verification: project files require caller-owned `clean/ready` files; duplicate file links update folder/label/order; project room items can be pinned and linked to project entities; room aggregate returns project, members, files, and room items for active project members
- Incomplete work: project member invite/update flows, file unlink/delete, room item update/delete, activity auto-generation from other mutations, and Flutter DP project room connection
- Exact next task: connect DP projects list/create/detail/requirement builder/project room screens to the Phase 5 endpoints

### 2026-07-17 — Phase 4 profiles and marketplace foundation

- Goal: add country/city references, user base profiles, actor/talent profile fields, and a public marketplace listing/search foundation
- Files changed: marketplace/profile models, profile and marketplace API endpoints, migration, OpenAPI, Flutter marketplace repository/controller models, director marketplace discovery screen, tests, Docker ignore/build hygiene, progress docs
- Migration(s): `7d2e5f6a8b90` profiles and marketplace foundation
- Endpoints: cities, current user profile get/update, talent profile get/update, marketplace publish/list/search/detail/facets
- Flutter screens: director/producer marketplace discovery now requests public marketplace listings through `AuthController.marketplaceListings`, converts backend listings into existing candidate cards, and keeps demo fallback for empty/offline local states; actor/talent profile builder now hydrates/saves city, public bio, screen name, and languages through the profile endpoints while preserving local-only fields until their backend tables exist
- Tests: lint, format, strict typing, OpenAPI parse, MySQL/Redis integration suite with 22 tests and 90% coverage, Flutter analyze, 361 widget tests, rebuilt Docker API/worker/scheduler images, and container HTTP marketplace smoke test all pass
- Verification: talent listing publish is blocked until approved actor-talent KYC exists; approved/public listings are returned by search/detail; seeded Pakistan city references are available through `/api/v1/cities`; Docker build context now excludes local cache directories
- Incomplete work: organizations, saved searches/shortlists, portfolio/media attachment, marketplace moderation queues, marketplace detail UI, publish-listing UI action, and specialized model/location/equipment/crew/agency/brand profiles
- Exact next task: add portfolio/media attachment to marketplace listings, then add a publish-listing action for approved actor/talent profiles

### 2026-07-17 — Phase 4 portfolio media and publish action

- Goal: add portfolio item records, attach clean media to marketplace listings, and expose an actor/talent publish action
- Files changed: marketplace models/API, migration, OpenAPI, backend integration tests, Flutter auth repository/controller, actor/talent profile builder, progress docs
- Migration(s): `8e3b7c9d1a20` portfolio and listing media
- Endpoints: portfolio list/create/update/delete; marketplace listing publish now accepts `portfolio_item_ids`/`media_file_ids` and public listing responses include `media`
- Flutter screens: actor/talent profile builder now has a backend publish-listing action with loading/error feedback and explicit KYC-required messaging
- Tests: backend lint/format/typing pass; MySQL/Redis integration suite has 23 tests with 87% coverage; OpenAPI parse passes with 31 paths and 55 schemas; Flutter analyze and 361 widget tests pass; Docker API/worker/scheduler rebuilt; container HTTP portfolio/listing-media smoke test passes
- Verification: portfolio items require an existing talent profile; media files must be owned by the current user and `clean/ready`; only approved/published portfolio items can attach to listings; duplicate listing media inputs are de-duplicated
- Incomplete work: real object-storage file picker/upload UI, portfolio screen backend CRUD, public marketplace detail UI, saved searches/shortlists, and role-specific marketplace profiles beyond actor/talent
- Exact next task: connect the actor/talent portfolio screen to `/api/v1/portfolio` once real upload/provider credentials are available, or proceed to saved searches/shortlists for director marketplace discovery

### 2026-07-17 — Phase 4 saved searches and shortlists

- Goal: persist director/producer marketplace saved searches and shortlist boards/items against real public listings
- Files changed: marketplace models/API, migration, OpenAPI, backend integration tests, Flutter auth repository/controller, director marketplace discovery/card UI, progress docs
- Migration(s): `9a4b6c7d8e30` saved searches and shortlists
- Endpoints: saved-search list/create/delete, shortlist list/create, add/update/delete shortlist item, marketplace result count
- Flutter screens: director marketplace discovery can save the current search and persist candidate heart actions to a default backend shortlist when authenticated; fallback/demo behavior remains available
- Tests: backend lint/format/typing pass; MySQL/Redis integration suite has 24 tests with 87% coverage; OpenAPI parse passes with 37 paths and 69 schemas; Flutter analyze and 361 widget tests pass; Docker API/worker/scheduler rebuilt; container HTTP saved-search/shortlist smoke test passes
- Verification: saved searches and shortlist boards are scoped to the authenticated owner; duplicate shortlist adds update the existing item; users cannot mutate another user's shortlist item; result count uses the same approved/public marketplace filter semantics as listing search
- Incomplete work: full shortlist board backend rendering, saved-search management UI, project/requirement linkage once Phase 5 project tables exist, and notifications for saved-search matches
- Exact next task: begin Phase 5 project foundation with projects, project members, requirements, and skills so shortlists can attach to real project requirements

### 2026-07-17 — Phase 3 KYC/files backend foundation

- Goal: add secure file metadata, upload sessions, KYC submissions/documents, and verification review history
- Files changed: file/KYC models, verification API endpoints, admin permission policy, migrations, OpenAPI, Celery file task/service, Flutter KYC/status/admin verification screens, tests, progress docs
- Migration(s): `9c1d4f8a2b67` KYC files and verification; `2f4a6b8c9d10` admin verification permissions
- Endpoints: upload presign/complete, KYC create/submit/resubmit/status, admin KYC queue/detail/decision
- Flutter screens: KYC upload/status and admin KYC queue/detail connected to `AuthController`/backend endpoints; file picker still uses demo metadata until native/web picker storage integration
- Tests: lint, format, strict typing, MySQL/Redis integration suite with 21 tests and 90% coverage; Flutter analyze and 361 widget tests pass
- Verification: upload sessions are owner-scoped and expiring; completed files start with `scan_status=pending`, enqueue a scan task, and the local/demo processor can mark them `clean/ready`; admin KYC endpoints deny normal users and require `kyc.review`; KYC state changes write verification events
- Incomplete work: real object storage signed PUTs, production ClamAV/FFmpeg processing, admin assignment/scoping UI, notifications
- Exact next task: replace demo upload completion with real object-storage PUT integration once provider credentials are supplied, or start Phase 4 profiles/marketplace if storage credentials remain unavailable

### 2026-07-17 — Phase 2 identity/auth and Flutter API foundation

- Goal: implement MySQL-backed identity, authentication, session rotation, and account role switching
- Files changed: identity models, auth/security services, auth endpoints, migration, OpenAPI, tests, dependency list
- Migration(s): `5b0e3a1f7c2d` identity and access foundation
- Endpoints: register, login, refresh, logout, forgot/reset password, current user, current roles, add role, set primary role
- Flutter screens: splash, login, signup, forgot password, role selection, role switcher, and settings logout connected
- Tests: lint, format, strict typing, MySQL/Redis integration suite with 19 tests and 91% coverage; Flutter analyze and 361 widget tests pass
- Verification: refresh tokens are stored hashed, rotated on use, rejected after rotation/logout; role switching requires a granted active role; Flutter stores tokens in secure storage and restores sessions on splash
- Incomplete work: real email delivery for password reset token, OTP/MFA, device registration, and admin auth are deferred to communications/admin slices
- Exact next task: start Phase 3 with KYC submission tables, file/upload sessions, object storage adapter, malware scan state, and admin verification queues

### 2026-07-17 — Phase 0 and Phase 1 foundation

- Goal: freeze decisions, acquire HTTPS, and deliver a reproducible backend foundation
- Files changed: deployment/docs, Flask foundation, Compose stack, migration, tests, and CI
- Migration(s): `efc80f32cc35` foundation baseline
- Endpoints: health live/ready, bootstrap, public config, roles, OpenAPI
- Flutter screens: audited; no API connections yet
- Tests: DNS/TLS, MySQL authentication, lint, format, strict typing, 16 backend tests, container smoke test
- Verification: TLS certificate matches `cine.nalexustechnologies.com` and renews automatically
- Incomplete work: Phase 2 identity/authentication and Flutter integration
- Exact next task: add identity/access migrations, Argon2id/JWT rotation services, RBAC policies, auth endpoints, and Flutter API/token layers

### 2026-07-24 — Other portals perfection P0/P1/P2 baseline, audit, and backend deploy

- Goal: start the non-Director portal perfection plan, enforce database-only visible portal data, and deploy the latest pulled backend APIs before frontend portal rewiring depends on them.
- New docs:
  - `docs/CINECONNECT_OTHER_PORTALS_PERFECTION_PLAN.md`
  - `docs/CINECONNECT_PORTAL_API_AUDIT.md`
- Baseline checks:
  - `cd backend && python3 -m compileall app tests` passed.
  - `cd backend && python3 -m ruff check app tests` passed.
  - `flutter analyze` passed.
  - Portal widget tests passed for Super Admin, Brand Sponsor, Location Owner, Media/Equipment, Actor/Talent, and Model Extension route suites.
  - Backend unit tests: 15 passed; 1 local test failed because local MySQL on `127.0.0.1` was not running for `/api/v1/roles`. Production readiness later confirmed database/Redis OK.
- Static data audit:
  - Director/Producer screens are mostly clean/no runtime `DemoData` in main screens.
  - Super Admin, Brand Sponsor, Actor/Talent, Model Extension, Location Owner, Casting Agency, Crew Services, Legal Partner, Insurance Partner, Distribution Partner, and generic Role Portals still have runtime static data dependencies to remove.
  - Media/Equipment is currently the closest non-Director portal to live-only data, with remaining static fallback concentrated around inventory/shared widgets.
- Production backend deployment:
  - Confirmed production was missing `c4d5e6f7a8b9_brand_application_conversations.py`.
  - Synced latest `backend/` to `/var/www/cineconnect/release/backend`.
  - Rebuilt `cineconnect-prod-api:latest`.
  - Ran production migration `b8c9d0e1f2a3 -> c4d5e6f7a8b9`.
  - Restarted `cineconnect-api`, `cineconnect-worker`, and `cineconnect-scheduler`.
- Production smoke:
  - `/api/v1/health/live` returns `ok`.
  - `/api/v1/health/ready` returns database and Redis `ok`.
  - `/api/v1/openapi.yaml` returns HTTP 200.
  - Alembic current revision is `c4d5e6f7a8b9 (head)`.
  - Newly deployed route groups are registered: protected endpoints return `auth.missing_token` instead of 404, and `/api/v1/brand-opportunities` returns database rows.
- P3 Super Admin cleanup started:
  - Removed runtime import of `lib/features/super_admin/mock_data/admin_mock_data.dart`.
  - Moved Super Admin navigation configuration into `admin_widgets.dart` as real UI navigation constants.
  - Replaced mock admin-name fallback with neutral `Super Admin`.
  - Deleted the unused `admin_mock_data.dart` file.
  - `rg -n "DemoData|DemoStore|admin_mock_data|mock_data|shared_mock_data|sample|static demo" lib/features/super_admin lib/core -g '*.dart'` now shows no matches under `lib/features/super_admin`; remaining matches are shared core screens to handle separately.
  - `flutter analyze` passed.
  - `flutter test test/super_admin_portal_test.dart` passed.
- Next:
  - Deploy the updated Flutter web bundle, push the P0/P1/P2/P3 docs/code, then continue with shared core mock cleanup or Media/Equipment static fallback removal.

### 2026-07-22 — Director provider-specific discovery/detail DTOs

- Goal: make non-talent Director Marketplace categories show real database provider records with rich detail DTOs instead of backend-gap/fake data states.
- Files changed: `backend/app/api/director.py`, `docs/openapi.yaml`, `lib/core/director/director_discovery_models.dart`, `lib/core/director/director_repository.dart`, `lib/core/auth/auth_controller.dart`, Director marketplace/profile screens, and Director portal perfection plan docs.
- Endpoints:
  - `GET /api/v1/director/discovery`
  - `GET /api/v1/director/discovery/{kind}/{public_id}`
- Backend DTO sources:
  - Locations from `location_properties`, `location_spaces`, `location_pricing`, and `location_rules`.
  - Media & Equipment from `equipment_provider_profiles`, `equipment_items`, `equipment_packages`, and `equipment_terms`.
  - Agencies from `casting_agencies` and `agency_talent`.
  - Distribution partners from `distribution_partner_profiles` for future Director expansion.
- Flutter behavior:
  - Director Marketplace `All` combines existing talent marketplace listings with provider-specific Director discovery rows.
  - Director Marketplace `Locations`, `Media & Equipment`, and `Agencies` now load real API records.
  - Provider-specific cards open Stakeholder Profile using `director:{kind}:{public_id}` arguments.
  - Stakeholder Profile renders provider-specific detail sections and gallery placeholders from live DTOs.
  - Request/shortlist for provider-specific records shows an explicit pending-linking message instead of sending an invalid listing ID.
- Tests:
  - `compileall` and targeted Ruff pass for `backend/app/api/director.py`.
  - OpenAPI YAML parse confirms both new paths.
  - Backend tests: 15 passed, 28 skipped because local MySQL/Redis integration mode was not enabled.
  - `flutter analyze` passes.
  - `flutter test test/director_producer_portal_test.dart --reporter compact` passes.
  - `flutter test --reporter compact` passes.
- Deployment:
  - Backend release synced to `/var/www/cineconnect/release/backend`.
  - Docker image `cineconnect-prod-api:latest` rebuilt.
  - `cineconnect-api`, `cineconnect-worker`, and `cineconnect-scheduler` restarted.
  - Flutter web rebuilt with `CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` and synced to `/var/www/cineconnect/web`.
- Production smoke:
  - `/api/v1/health/ready` returns database and Redis `ok`.
  - Director discovery returns 13 location records, 13 media/equipment records, and 11 agency records for the demo Director account.
  - Location detail smoke for `DEMO-LOC-006` returns 4 detail sections.
  - Web root returns HTTP 200.
- Incomplete work:
  - Crew still needs a dedicated crew-provider schema or explicit mapping from existing talent/project-role data.

### 2026-07-22 — Actor/Model discovery separation and marketplace bridge

- Goal: separate Actors and Models in Director discovery, and make Actor/Model/provider discovery records usable by existing marketplace shortlist and booking flows.
- Files changed: `backend/app/api/director.py`, `backend/app/api/marketplace.py`, `backend/scripts/sync_marketplace_provider_listings.py`, `docs/openapi.yaml`, Director discovery Flutter models, marketplace models, Director marketplace screen, Stakeholder Profile screen, and progress docs.
- Backend behavior:
  - Director discovery kind `actor` now reads `talent_profiles`.
  - Director discovery kind `model` now reads `model_profiles`.
  - Actor detail returns profile/language/public-profile sections.
  - Model detail returns profile/campaign-category/usage-rate/usage-right/restricted-category sections.
  - All rich discovery items now include `listing_id` when connected to a public marketplace listing.
  - Saved searches now allow `actor`, `model`, `location`, `equipment`, `agency`, and `distribution` listing types.
- Marketplace bridge:
  - Added an idempotent sync script for existing profile/provider records.
  - The sync creates/updates public marketplace listings for actors, models, locations, equipment providers, agencies, and distribution partners using the existing generic `marketplace_listings` table.
  - No shortlist schema migration was required; existing shortlist items still point to `marketplace_listings.id`.
  - No booking schema migration was required; booking requests already use public marketplace listing ids.
- Flutter behavior:
  - Director Marketplace visible category is now `Actors` instead of `Talent`.
  - Legacy `/discover/Talent` routes normalize to `Actors`.
  - Director Marketplace loads all visible categories through Director discovery instead of mixing direct listing and discovery feeds.
  - `DpCandidate` now keeps separate `profileId` and `marketplaceListingId`.
  - Profile opens rich Actor/Model/provider detail via `profileId`.
  - Request/shortlist actions use `marketplaceListingId`.
  - Rich provider/Actor/Model profile pages show Send Request when a listing id exists.
- Tests:
  - Backend compile and targeted Ruff pass.
  - OpenAPI YAML parse confirms Actor/Model enum support and `listing_id`.
  - Backend tests: 15 passed, 28 skipped because local MySQL/Redis integration mode was not enabled.
  - `flutter analyze` passes.
  - `flutter test test/director_producer_portal_test.dart --reporter compact` passes.
  - `flutter test --reporter compact` passes.
- Deployment:
  - Backend release synced to `/var/www/cineconnect/release/backend`.
  - Docker image `cineconnect-prod-api:latest` rebuilt.
  - `cineconnect-api`, `cineconnect-worker`, and `cineconnect-scheduler` restarted.
  - Production marketplace sync ran successfully:
    - 16 actor listings
    - 11 model listings
    - 13 location listings
    - 13 equipment listings
    - 11 agency listings
    - 11 distribution listings
  - Flutter web rebuilt with `CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` and synced to `/var/www/cineconnect/web`.
- Production smoke:
  - `/api/v1/health/ready` returns database and Redis `ok`.
  - Actors: 16 records, 0 missing `listing_id`.
  - Models: 11 records, 0 missing `listing_id`.
  - Locations: 13 records, 0 missing `listing_id`.
  - Media & Equipment: 13 records, 0 missing `listing_id`.
  - Agencies: 11 records, 0 missing `listing_id`.
  - Actor marketplace detail opens from returned listing id.
  - Actor rich detail returns 3 sections with `listing_id`.
  - Model rich detail returns 5 sections with `listing_id`.
  - Web root returns HTTP 200.
- Incomplete work:
  - Crew still needs a dedicated crew-provider schema or a deliberate mapping from existing crew profiles/project roles into marketplace listings.
