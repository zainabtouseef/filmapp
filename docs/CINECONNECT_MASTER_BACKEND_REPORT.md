# CineConnect Master Backend Implementation Report

**Document purpose:** single source of truth for converting the existing Flutter UI prototype into a fully dynamic, database-backed production application with a Flask API.

**Repository audited:** `/Users/abdulbasit/Desktop/filmapp`

**Frontend:** Flutter/Dart, mobile and web

**Proposed backend:** Flask/Python REST API

**Primary database:** PostgreSQL

**Document version:** 1.0

**Prepared:** 2026-07-17

---

## 1. Instructions for the implementation AI

This document is intentionally written so another AI can implement the backend over multiple sessions without losing scope.

At the beginning of every implementation session:

1. Read this entire document.
2. Read `README.md`, `pubspec.yaml`, `lib/main.dart`, `lib/core/core_ui/core_routes.dart`, every relevant portal route file, model file, demo-data file, and screen being connected in that session.
3. Inspect the current Git diff. Never overwrite unrelated user changes.
4. Read `docs/IMPLEMENTATION_PROGRESS.md` if it exists.
5. Select only the next incomplete phase from Section 18.
6. Implement a vertical slice: migration, model, schema, service, endpoint, tests, Flutter repository/provider, screen integration, and verification.
7. Run backend and Flutter tests.
8. Update `docs/IMPLEMENTATION_PROGRESS.md` with files changed, migrations added, endpoints completed, tests run, decisions, blockers, and the exact next task.
9. Do not mark a phase complete while the UI still reads from demo stores or contains non-functional controls in that phase.

Hard rules:

- The existing Flutter screens and route names are the UI source of truth.
- Replace demo data incrementally; do not delete demo stores until their consumers use repositories.
- Do not put business logic in Flask route functions or Flutter widgets.
- Use UUID primary keys internally. Human-readable codes such as `BK-2048` remain unique public identifiers.
- Store money as integer minor units plus ISO currency, never float.
- Store timestamps in UTC and return ISO-8601 timestamps with `Z`; display in the user’s timezone.
- Every mutable table must have `created_at`, `updated_at`, and where required `deleted_at`.
- Every mutation must enforce authorization on the server, not only hide buttons in Flutter.
- Every list endpoint must support pagination and deterministic sorting.
- Every upload must use a signed object-storage workflow; never send large media through Flask workers.
- Every external callback must be idempotent and signature-verified.
- Do not log passwords, tokens, KYC files, private addresses, banking data, or contract signatures.
- Use database transactions for booking, contract, payment, deposit, claim, and permission state changes.
- Generate OpenAPI documentation and keep it synchronized with implemented routes.

### 1.1 Definition of “dynamic”

A screen is dynamic only when:

- its initial state comes from an authenticated API request;
- filters, search, sorting, and pagination query the real dataset;
- create/update/delete/actions persist to PostgreSQL;
- uploads persist to object storage and metadata persists to PostgreSQL;
- state changes survive app restarts and a second device;
- loading, empty, validation, permission, offline, timeout, and server-error states are handled;
- affected dashboards and notifications update after mutations;
- the action has automated backend tests and at least one Flutter integration/widget test.

---

## 2. Current application audit

The repository is a Flutter UI prototype using `MaterialApp`, named routes, local models, and feature-specific in-memory demo stores. It currently has no HTTP client, persistent local state, backend SDK, authentication token storage, or production database connection.

### 2.1 Existing product roles

1. Director / Producer
2. Actor / Talent
3. Model extension
4. Location Owner
5. Media / Equipment Provider
6. Crew / Services
7. Casting Agency
8. Brand / Sponsor
9. Legal Partner
10. Insurance / Safety Partner
11. Distribution / Release Partner
12. Super Admin

A user may hold multiple roles. A separate account must not be created for every role. `users` owns identity; `user_roles` grants portal access; role-specific profile tables hold specialized data.

### 2.2 Existing shared modules

- onboarding, role selection, signup, login, forgot password;
- KYC upload and verification status;
- role/profile switcher;
- notification center;
- booking chat and decision messages;
- contract viewer, addendum request, and signature workflow;
- payment-proof upload and receipts ledger;
- ratings/reviews;
- report/block and safety controls;
- account settings;
- offline, error, empty, maintenance, and force-update states.

### 2.3 Current architectural gaps

- All business data is hard-coded in Dart demo-data files.
- Route placeholders such as `:id` are static strings rather than real path parameter parsing.
- No repository/service/state-management layer exists for remote data.
- No secure authentication or authorization exists.
- No upload, messaging, push notification, audit, scheduled-job, payment verification, or realtime infrastructure exists.
- Dashboard metrics are presentation strings rather than query-backed aggregates.
- Money and dates are often stored in display format and must be normalized in the backend.
- Several domain records duplicate shared concepts; the database must normalize projects, bookings, contracts, payments, files, and users.

---

## 3. Target system architecture

```text
Flutter iOS / Android / Web
        |
        | HTTPS REST / WebSocket
        v
Nginx or managed load balancer
        |
        +--> Flask API (Gunicorn)
        |       |
        |       +--> PostgreSQL
        |       +--> Redis (cache, rate limits, Socket.IO, job broker)
        |       +--> Celery workers + scheduler
        |       +--> S3-compatible object storage
        |       +--> Email/SMS/push provider
        |       +--> Payment provider or admin proof-verification workflow
        |
        +--> CDN for public/authorized media delivery
```

Recommended backend components:

- Flask application factory with blueprints.
- SQLAlchemy 2 ORM and Alembic migrations.
- Marshmallow or Pydantic for request/response schemas.
- JWT access tokens plus rotating refresh tokens.
- Argon2id password hashing.
- Flask-Limiter backed by Redis.
- Celery for email, notifications, media processing, report exports, reminders, and analytics rollups.
- Flask-SocketIO or a managed realtime provider for chat and event refresh.
- Sentry-compatible error monitoring and structured JSON logs.
- OpenTelemetry metrics/tracing where hosting supports it.
- Pytest, factory-boy, freezegun, and testcontainers or an isolated PostgreSQL test database.

### 3.1 Flask project layout

```text
backend/
  pyproject.toml
  .env.example
  alembic.ini
  migrations/
  app/
    __init__.py
    config.py
    extensions.py
    api/
      errors.py
      pagination.py
      auth.py
      uploads.py
      users.py
      projects.py
      marketplace.py
      bookings.py
      negotiations.py
      contracts.py
      payments.py
      messaging.py
      notifications.py
      reviews.py
      safety.py
      talent.py
      models.py
      locations.py
      equipment.py
      crew.py
      agencies.py
      brands.py
      legal.py
      insurance.py
      distribution.py
      admin.py
      analytics.py
    models/
    schemas/
    services/
    repositories/
    policies/
    tasks/
    events/
    integrations/
    commands/
  tests/
    unit/
    integration/
    contract/
```

Route functions validate input, call a service, and serialize output. Services own business rules and transactions. Policies answer permission questions. Repositories isolate non-trivial queries. Events trigger notifications and background work after transaction commit.

---

## 4. API conventions

Base URL:

```text
https://api.<YOUR_DOMAIN>/api/v1
```

Standard success envelope:

```json
{
  "data": {},
  "meta": {
    "request_id": "req_01J...",
    "pagination": null
  }
}
```

Standard list metadata:

```json
{
  "page": 1,
  "page_size": 20,
  "total": 87,
  "pages": 5,
  "sort": "-created_at"
}
```

Standard error:

```json
{
  "error": {
    "code": "booking.invalid_transition",
    "message": "A rejected booking cannot be accepted.",
    "fields": {},
    "request_id": "req_01J..."
  }
}
```

Conventions:

- JSON fields use `snake_case`.
- List filters use query parameters.
- Public codes are safe in URLs; private UUIDs may also be accepted.
- `POST` creates, `PATCH` partially updates, `DELETE` soft-deletes unless the law requires hard deletion.
- Destructive and money-moving `POST` requests accept `Idempotency-Key`.
- Optimistic concurrency uses an integer `version` or `If-Match`/ETag for negotiations, contracts, calendars, and admin review.
- Search inputs are debounced in Flutter; server search is indexed.
- Default page size is 20, maximum 100.
- API version is in the path. Breaking response changes require `/api/v2`.

---

## 5. Identity, authentication, and authorization

### 5.1 Authentication flows

- Signup: email/phone, password, display name, selected initial role, terms acceptance.
- Verify email or OTP before sensitive actions.
- Login returns a short-lived access token and rotating refresh token.
- Refresh-token reuse revokes the token family.
- Forgot-password links/OTP expire and are one-time-use.
- Optional MFA is mandatory for super admins and recommended for payment/legal partners.
- Device/session screen allows remote logout.
- Suspended users may authenticate only to see the restriction and contact support.

### 5.2 Role and permission model

Core roles:

`director_producer`, `actor_talent`, `model`, `location_owner`, `equipment_provider`, `crew_service`, `casting_agency`, `brand_sponsor`, `legal_partner`, `insurance_partner`, `distribution_partner`, `support_agent`, `reviewer`, `finance_admin`, `super_admin`.

Permissions use `resource.action`, for example:

- `project.create`, `project.manage`;
- `booking.respond`, `booking.monitor`;
- `contract.review`, `contract.sign`, `contract.template.manage`;
- `payment.proof.submit`, `payment.verify`, `payment.release`;
- `kyc.review`, `user.suspend`, `audit.read`;
- `announcement.publish`, `analytics.export`.

Object-level policies must additionally verify project membership, booking participation, agency representation, assigned review queue, or admin scope.

---

## 6. Database standards

PostgreSQL extensions: `pgcrypto` for UUIDs and optionally `citext` for case-insensitive email.

Unless overridden, each entity table contains:

```text
id uuid primary key default gen_random_uuid()
created_at timestamptz not null default now()
updated_at timestamptz not null default now()
deleted_at timestamptz null
version integer not null default 1
```

Common rules:

- All foreign keys are indexed.
- Unique business identifiers have unique indexes.
- Check constraints enforce non-negative money and valid ranges.
- Status columns use PostgreSQL enums only when values are truly stable; otherwise use checked strings.
- JSONB is allowed for immutable snapshots, flexible form answers, provider payloads, and analytics metadata—not as a replacement for relational design.
- Private address and KYC-sensitive values use field-level encryption or a managed secrets/encryption service.
- IP addresses should be stored with PostgreSQL `inet`.
- File binaries never live in PostgreSQL.

---

## 7. Complete database catalogue with sample data

The following catalogue is the required logical schema. Columns shown are domain-specific columns in addition to the standard columns above. Sample values are illustrative seed records. Foreign-key samples use readable codes for clarity; seed scripts must resolve them to UUIDs.

### 7.1 Identity, access, verification, and settings

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `users` | `public_id`, `email citext unique`, `phone_e164`, `password_hash`, `display_name`, `status`, `email_verified_at`, `phone_verified_at`, `last_login_at` | `USR-0001, sara@cineconnect.demo, +923001110001, <argon2>, Sara Ahmed, active` |
| `roles` | `code unique`, `name`, `portal_route`, `requires_kyc` | `director_producer, Director / Producer, /director, true` |
| `permissions` | `code unique`, `description` | `project.create, Create production projects` |
| `role_permissions` | `role_id`, `permission_id`, unique pair | `director_producer -> project.create` |
| `user_roles` | `user_id`, `role_id`, `status`, `is_primary`, `approved_at` | `USR-0001 -> director_producer, active, true` |
| `admin_role_assignments` | `user_id`, `role_id`, `scope_json`, `assigned_by` | `USR-0090 -> finance_admin, {"cities":["Lahore"]}, USR-0099` |
| `user_sessions` | `user_id`, `refresh_token_hash`, `token_family`, `device_name`, `platform`, `ip_address`, `user_agent`, `expires_at`, `revoked_at` | `USR-0001, <hash>, fam-1, Sara iPhone, ios, 203.0.113.5` |
| `auth_security_events` | `user_id`, `event_type`, `success`, `ip_address`, `user_agent`, `risk_score`, `metadata_json`, `created_at` | `USR-0001, login, true, 203.0.113.5, CineConnect iOS, 0.02, {"mfa":false}, 2026-07-17T08:00:00Z` |
| `password_reset_tokens` | `user_id`, `token_hash`, `expires_at`, `used_at` | `USR-0001, <hash>, 2026-07-18T10:00:00Z, null` |
| `otp_challenges` | `user_id`, `channel`, `destination_masked`, `code_hash`, `purpose`, `attempts`, `expires_at`, `verified_at` | `USR-0001, sms, +92******001, <hash>, phone_verify, 0` |
| `user_settings` | `user_id unique`, `locale`, `timezone`, `theme`, `currency`, `marketing_opt_in`, `safety_check_in_enabled` | `USR-0001, en-PK, Asia/Karachi, dark, PKR, false, true` |
| `notification_preferences` | `user_id`, `category`, `in_app`, `push`, `email`, `sms`, unique user/category | `USR-0001, contracts, true, true, true, false` |
| `legal_consents` | `user_id`, `document_type`, `document_version`, `accepted_at`, `ip_address` | `USR-0001, terms, 1.0, 2026-07-17T08:00:00Z` |
| `kyc_submissions` | `public_id`, `user_id`, `role_id`, `status`, `risk_level`, `submitted_at`, `assigned_admin_id`, `decision_at`, `decision_reason` | `KYC-1001, USR-0001, director_producer, pending, low` |
| `kyc_documents` | `submission_id`, `file_id`, `document_type`, `country`, `document_number_encrypted`, `expires_on`, `status`, `rejection_reason` | `KYC-1001, FILE-KYC-1, national_id_front, PK, <encrypted>, 2031-05-01, pending` |
| `verification_events` | `submission_id`, `actor_user_id`, `from_status`, `to_status`, `reason`, `metadata_json` | `KYC-1001, USR-0091, pending, approved, Identity matched, {}` |
| `blocked_users` | `blocker_user_id`, `blocked_user_id`, `reason`, unique pair | `USR-0002 blocks USR-0008, harassment` |
| `trusted_contacts` | `user_id`, `name`, `phone_e164`, `relationship`, `is_primary` | `USR-0002, Ayesha Khan, +923001112222, sibling, true` |

### 7.2 Organizations, profiles, locations, and files

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `organizations` | `public_id`, `name`, `type`, `tax_id_encrypted`, `billing_email`, `status`, `owner_user_id` | `ORG-001, Sara Ahmed Productions, production_company, <encrypted>, billing@sara.demo, verified, USR-0001` |
| `organization_members` | `organization_id`, `user_id`, `title`, `member_role`, `status` | `ORG-001, USR-0001, Producer, owner, active` |
| `user_profiles` | `user_id unique`, `bio`, `city_id`, `avatar_file_id`, `cover_file_id`, `website_url`, `profile_visibility`, `rating_average`, `review_count` | `USR-0001, Producer focused on TVCs, CITY-KHI, FILE-AV-1, null, null, public, 4.8, 26` |
| `addresses` | `owner_type`, `owner_id`, `label`, `line1_encrypted`, `line2_encrypted`, `city_id`, `postal_code_encrypted`, `latitude_encrypted`, `longitude_encrypted`, `visibility` | `user, USR-0001, billing, <encrypted>, null, CITY-KHI, <encrypted>, <encrypted>, <encrypted>, private` |
| `countries` | `iso2`, `name`, `currency_code`, `phone_prefix` | `PK, Pakistan, PKR, +92` |
| `cities` | `public_id`, `country_id`, `name`, `province`, `timezone`, `active` | `CITY-LHE, PK, Lahore, Punjab, Asia/Karachi, true` |
| `files` | `public_id`, `owner_user_id`, `storage_key`, `bucket`, `mime_type`, `size_bytes`, `checksum_sha256`, `visibility`, `scan_status`, `processing_status`, `original_name` | `FILE-AV-1, USR-0001, avatars/2026/..., private-media, image/jpeg, 240123, <sha>, authorized, clean, ready, sara.jpg` |
| `file_variants` | `file_id`, `variant`, `storage_key`, `width`, `height`, `duration_seconds`, `status` | `FILE-AV-1, thumb_256, avatars/.../thumb.webp, 256, 256, null, ready` |
| `upload_sessions` | `user_id`, `purpose`, `mime_type`, `max_bytes`, `storage_key`, `expires_at`, `completed_at` | `USR-0002, portfolio_video, video/mp4, 524288000, pending/..., 2026-07-17T12:00:00Z, null` |

### 7.3 Projects, requirements, marketplace, and teams

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `projects` | `public_id`, `owner_user_id`, `organization_id`, `title`, `project_type`, `description`, `city_id`, `start_date`, `end_date`, `status`, `estimated_budget_minor`, `currency`, `visibility`, `progress_percent` | `PRJ-1001, USR-0001, ORG-001, Aurora Biscuit TVC, tvc, Family kitchen campaign, CITY-KHI, 2026-07-18, 2026-07-22, active, 150000000, PKR, private, 62` |
| `project_members` | `project_id`, `user_id`, `role_label`, `permissions_json`, `status`, unique project/user | `PRJ-1001, USR-0001, Producer, {"manage":true}, active` |
| `project_budget_lines` | `public_id`, `project_id`, `category`, `label`, `budgeted_minor`, `committed_minor`, `paid_minor`, `currency`, `notes` | `PBL-1001, PRJ-1001, talent, Lead talent, 20000000, 18000000, 7200000, PKR, Includes usage` |
| `project_files` | `project_id`, `file_id`, `folder`, `label`, `uploaded_by`, `visibility`, `sort_order` | `PRJ-1001, FILE-BRIEF-1, briefs, Approved creative brief, USR-0001, project_members, 1` |
| `project_room_items` | `public_id`, `project_id`, `item_type`, `title`, `body`, `linked_entity_type`, `linked_entity_id`, `created_by`, `pinned_at` | `ROOM-1001, PRJ-1001, decision, Final call time, 7:30 AM call, message, MSG-1003, USR-0001, 2026-07-17T10:22:00Z` |
| `project_requirements` | `public_id`, `project_id`, `category`, `title`, `summary`, `budget_min_minor`, `budget_max_minor`, `currency`, `start_date`, `end_date`, `status`, `candidate_count_cache` | `REQ-1001, PRJ-1001, talent, Lead father, Warm screen presence, 15000000, 20000000, PKR, 2026-07-19, 2026-07-19, open, 18` |
| `requirement_skills` | `requirement_id`, `skill_id`, `required`, `minimum_level` | `REQ-1001, SKILL-ACT-DRAMA, true, intermediate` |
| `skills` | `public_id`, `category`, `name`, `active` | `SKILL-ACT-DRAMA, acting, Dramatic acting, true` |
| `marketplace_listings` | `public_id`, `owner_user_id`, `listing_type`, `profile_entity_id`, `title`, `summary`, `city_id`, `price_from_minor`, `currency`, `verification_status`, `moderation_status`, `visibility`, `published_at` | `LST-1001, USR-0002, talent, TAL-001, Ali Khan — Actor, Lead actor, CITY-LHE, 14000000, PKR, approved, approved, public, 2026-07-01T08:00:00Z` |
| `listing_media` | `listing_id`, `file_id`, `sort_order`, `is_cover`, `caption` | `LST-1001, FILE-TAL-1, 1, true, Headshot` |
| `listing_tags` | `listing_id`, `tag_id`, unique pair | `LST-1001, TAG-URDU` |
| `tags` | `public_id`, `category`, `name`, `slug` | `TAG-URDU, language, Urdu, urdu` |
| `listing_views` | `listing_id`, `viewer_user_id`, `anonymous_session_hash`, `source`, `viewed_at` | `LST-1001, USR-0001, null, marketplace_search, 2026-07-17T08:30:00Z` |
| `shortlists` | `public_id`, `project_id`, `requirement_id`, `created_by`, `name` | `SHL-1001, PRJ-1001, REQ-1001, USR-0001, Lead father shortlist` |
| `shortlist_items` | `shortlist_id`, `listing_id`, `candidate_user_id`, `rank`, `notes`, `status` | `SHL-1001, LST-1001, USR-0002, 1, Strong fit, selected` |
| `saved_searches` | `user_id`, `name`, `entity_type`, `filters_json`, `notify_on_match` | `USR-0001, Lahore verified actors, talent, {"city":"Lahore","verified":true}, true` |

### 7.4 Bookings, offers, negotiation, calendars, and chat

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `bookings` | `public_id`, `project_id`, `requirement_id`, `requester_user_id`, `provider_user_id`, `listing_id`, `category`, `status`, `agreed_amount_minor`, `currency`, `start_at`, `end_at`, `expires_at`, `secured_at`, `cancellation_reason` | `BK-2048, PRJ-1001, REQ-1001, USR-0001, USR-0002, LST-1001, talent, under_negotiation, 18000000, PKR, 2026-07-19T02:30:00Z, 2026-07-19T14:30:00Z, 2026-07-18T12:00:00Z, null, null` |
| `booking_participants` | `booking_id`, `user_id`, `participant_role`, `can_chat`, `can_view_finance` | `BK-2048, USR-0002, talent, true, true` |
| `booking_status_events` | `booking_id`, `actor_user_id`, `from_status`, `to_status`, `reason`, `metadata_json` | `BK-2048, USR-0002, sent, under_negotiation, Countered fee, {}` |
| `offers` | `public_id`, `booking_id`, `sender_user_id`, `recipient_user_id`, `revision`, `fee_minor`, `currency`, `schedule_json`, `conditions`, `payment_schedule_json`, `status`, `expires_at` | `OFF-1001, BK-2048, USR-0001, USR-0002, 1, 17000000, PKR, {"date":"2026-07-19"}, Wardrobe included, [{"percent":40}], countered, 2026-07-18T12:00:00Z` |
| `negotiation_threads` | `public_id`, `booking_id unique`, `status`, `current_offer_id`, `locked_at` | `NEG-1001, BK-2048, open, OFF-1002, null` |
| `negotiation_rounds` | `thread_id`, `offer_id`, `round_number`, `sender_user_id`, `message`, `created_at` | `NEG-1001, OFF-1002, 2, USR-0002, PKR 180k with 10-hour day` |
| `availability_calendars` | `owner_type`, `owner_id`, `timezone`, unique owner | `user, USR-0002, Asia/Karachi` |
| `availability_entries` | `calendar_id`, `resource_type`, `resource_id`, `start_at`, `end_at`, `status`, `source_booking_id`, `note` | `CAL-USR-0002, talent, TAL-001, 2026-07-19T00:00:00Z, 2026-07-20T00:00:00Z, booked, BK-2048, Aurora TVC` |
| `conversations` | `public_id`, `booking_id`, `project_id`, `type`, `title`, `last_message_at` | `CONV-1001, BK-2048, PRJ-1001, booking, Aurora TVC negotiation, 2026-07-17T10:35:00Z` |
| `conversation_members` | `conversation_id`, `user_id`, `last_read_message_id`, `muted_until`, unique pair | `CONV-1001, USR-0001, MSG-1005, null` |
| `messages` | `public_id`, `conversation_id`, `sender_user_id`, `message_type`, `body`, `reply_to_id`, `decision_type`, `edited_at`, `deleted_at` | `MSG-1006, CONV-1001, USR-0002, text, Call time confirmed, null, null, null, null` |
| `message_attachments` | `message_id`, `file_id`, `attachment_type`, `caption` | `MSG-1004, FILE-WARDROBE-1, image, Wardrobe reference board` |
| `pinned_decisions` | `conversation_id`, `message_id`, `pinned_by`, `decision_key`, `superseded_by_id` | `CONV-1001, MSG-1003, USR-0001, final_call_time, null` |

Booking states:

```text
draft -> sent -> viewed -> under_negotiation
under_negotiation -> accepted -> contract_pending_signature
contract_pending_signature -> payment_pending
payment_pending -> payment_under_verification -> secured
secured -> in_progress -> completed
any allowed pre-secured state -> expired | rejected | cancelled
completed -> disputed (exception path)
```

Only the booking service may change state, and every change writes `booking_status_events`.

### 7.5 Contracts, legal review, signatures, and templates

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `contract_templates` | `public_id`, `name`, `category`, `jurisdiction`, `version_number`, `body_schema_json`, `status`, `created_by`, `approved_by`, `published_at` | `TPL-001, Talent Booking Agreement, talent, PK, 3, {"sections":[...]}, published, USR-0092, USR-0099, 2026-06-01T00:00:00Z` |
| `template_clauses` | `template_id`, `clause_key`, `title`, `body_text`, `sort_order`, `required`, `editable` | `TPL-001, payment_schedule, Payment schedule, 40/40/20..., 5, true, true` |
| `contracts` | `public_id`, `booking_id`, `project_id`, `template_id`, `version_number`, `title`, `status`, `effective_date`, `value_minor`, `currency`, `rendered_file_id`, `content_snapshot_json`, `signature_progress` | `CTR-1001, BK-2048, PRJ-1001, TPL-001, 1, Actor Booking Agreement, pending_signature, 2026-07-19, 18000000, PKR, FILE-CTR-1, {"clauses":[...]}, 0.5` |
| `contract_parties` | `contract_id`, `user_id`, `organization_id`, `party_role`, `signing_order`, `status` | `CTR-1001, USR-0002, null, talent, 2, pending` |
| `contract_clauses` | `contract_id`, `clause_key`, `title`, `body_text`, `sort_order`, `highlighted`, `source_template_clause_id` | `CTR-1001, usage_rights, Usage rights, Pakistan digital TV OOH for 12 months, 7, true, ...` |
| `contract_signatures` | `contract_id`, `party_id`, `signer_user_id`, `signature_file_id`, `signature_hash`, `signed_at`, `ip_address`, `user_agent` | `CTR-1001, PARTY-PRODUCER, USR-0001, FILE-SIG-1, <sha>, 2026-07-17T11:00:00Z, 203.0.113.5, CineConnect iOS` |
| `contract_addendums` | `public_id`, `contract_id`, `requested_by`, `reason`, `content`, `status`, `reviewer_id`, `rendered_file_id` | `ADD-1001, CTR-1001, USR-0002, Overtime clarification, 18k after 10 hours, review_requested, USR-0040, null` |
| `legal_review_requests` | `public_id`, `contract_id`, `template_id`, `addendum_id`, `requested_by`, `assigned_legal_user_id`, `contract_type`, `risk`, `status`, `sla_due_at`, `decision_notes` | `LGR-1001, CTR-1001, null, null, USR-0001, USR-0040, talent_agreement, medium, in_review, 2026-07-18T12:00:00Z, null` |
| `legal_clause_risks` | `review_request_id`, `contract_clause_id`, `risk_level`, `issue`, `recommendation`, `status` | `LGR-1001, CLAUSE-USAGE, medium, Territory too broad, Limit to Pakistan, open` |
| `template_change_requests` | `template_id`, `requested_by`, `clause_key`, `proposed_change`, `reason`, `status`, `reviewed_by` | `TPL-001, USR-0040, cancellation, Add 48-hour fee, Reduces disputes, approved, USR-0099` |
| `legal_billing_records` | `public_id`, `legal_user_id`, `matter_type`, `matter_id`, `client_user_id`, `minutes`, `amount_minor`, `currency`, `invoice_number`, `status`, `notes` | `LGB-1001, USR-0040, contract_review, LGR-1001, USR-0001, 45, 250000, PKR, INV-LG-1001, invoiced, Standard review` |

### 7.6 Payments, proofs, receipts, fees, deposits, and ledger

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `payment_schedules` | `public_id`, `booking_id`, `contract_id`, `total_minor`, `currency`, `status` | `PS-1001, BK-2048, CTR-1001, 18000000, PKR, active` |
| `payment_milestones` | `public_id`, `schedule_id`, `name`, `sequence`, `amount_minor`, `due_at`, `release_condition`, `status` | `PM-1001, PS-1001, Deposit, 1, 7200000, 2026-07-18T12:00:00Z, proof_verified, proof_submitted` |
| `payment_transactions` | `public_id`, `milestone_id`, `payer_user_id`, `payee_user_id`, `provider`, `provider_reference`, `amount_minor`, `currency`, `direction`, `status`, `paid_at`, `idempotency_key` | `TXN-1001, PM-1001, USR-0001, USR-0002, manual_bank, HBL-884120, 7200000, PKR, outgoing, under_verification, 2026-07-17T09:00:00Z, idem-...` |
| `payment_proofs` | `public_id`, `transaction_id`, `file_id`, `claimed_amount_minor`, `method`, `transaction_reference_encrypted`, `submitted_by`, `status`, `risk_score`, `reviewed_by`, `reviewed_at`, `rejection_reason` | `PP-1001, TXN-1001, FILE-PROOF-1, 7200000, bank_transfer, <encrypted>, USR-0001, pending, 0.08, null, null, null` |
| `receipts` | `public_id`, `transaction_id unique`, `receipt_number unique`, `file_id`, `issued_at` | `RCPT-7821, TXN-1001, RCPT-7821, FILE-RCPT-1, 2026-07-17T11:30:00Z` |
| `ledger_entries` | `public_id`, `user_id`, `booking_id`, `transaction_id`, `entry_type`, `direction`, `amount_minor`, `currency`, `status`, `occurred_at`, `description` | `LED-1001, USR-0001, BK-2048, TXN-1001, deposit, debit, 7200000, PKR, pending_verification, 2026-07-17T09:00:00Z, Aurora TVC deposit` |
| `platform_fee_rules` | `public_id`, `name`, `category`, `percentage_bps`, `flat_minor`, `currency`, `min_minor`, `max_minor`, `effective_from`, `effective_to`, `active` | `FEE-001, Talent booking fee, talent, 500, 0, PKR, 0, null, 2026-07-01, null, true` |
| `booking_fee_snapshots` | `booking_id`, `fee_rule_id`, `base_minor`, `fee_minor`, `tax_minor`, `currency`, `calculation_json` | `BK-2048, FEE-001, 18000000, 900000, 0, PKR, {"bps":500}` |
| `security_deposits` | `public_id`, `booking_id`, `holder_user_id`, `beneficiary_user_id`, `amount_minor`, `currency`, `status`, `held_at`, `released_at` | `DEP-1001, BK-3001, USR-0001, USR-0030, 5000000, PKR, held, 2026-07-17T09:00:00Z, null` |
| `payout_accounts` | `user_id`, `provider`, `account_token_encrypted`, `account_masked`, `account_name`, `status`, `is_default` | `USR-0002, bank, <encrypted>, ****8842, Ali Khan, verified, true` |
| `payouts` | `public_id`, `payee_user_id`, `amount_minor`, `currency`, `provider_reference`, `status`, `scheduled_at`, `paid_at` | `PO-1001, USR-0002, 6840000, PKR, null, scheduled, 2026-07-20T09:00:00Z, null` |

Payment states:

```text
scheduled -> proof_submitted -> under_verification -> verified -> released
under_verification -> rejected -> proof_submitted
verified -> disputed | refunded
```

“Verified” must never be set by the client. It requires a payment-provider webhook or an authorized finance-admin decision.

### 7.7 Talent and model portal data

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `talent_profiles` | `public_id`, `user_id unique`, `screen_name`, `age_range`, `gender_identity`, `height_cm`, `union_note`, `experience_years`, `representation_agency_id`, `availability_status`, `day_rate_minor`, `currency` | `TAL-001, USR-0002, Ali Khan, 28-35, male, 180, Independent, 8, null, available, 14000000, PKR` |
| `talent_languages` | `talent_profile_id`, `language`, `proficiency`, unique pair | `TAL-001, Urdu, native` |
| `talent_skills` | `talent_profile_id`, `skill_id`, `level`, `verified` | `TAL-001, SKILL-ACT-DRAMA, advanced, true` |
| `portfolio_items` | `public_id`, `owner_user_id`, `profile_type`, `profile_id`, `title`, `category`, `file_id`, `thumbnail_file_id`, `duration_seconds`, `status`, `is_cover`, `sort_order`, `moderation_status` | `PORT-1001, USR-0002, talent, TAL-001, Drama Showreel, showreel, FILE-REEL-1, FILE-REEL-TH-1, 92, published, true, 1, approved` |
| `talent_rate_cards` | `public_id`, `talent_profile_id`, `name`, `currency`, `active` | `TRC-1001, TAL-001, Standard 2026, PKR, true` |
| `talent_rate_items` | `rate_card_id`, `category`, `label`, `amount_minor`, `unit`, `negotiable`, `conditions` | `TRC-1001, shoot, Shoot day, 14000000, day, true, 10 hours included` |
| `model_profiles` | `public_id`, `user_id unique`, `talent_profile_id`, `brand_safety_notes`, `public_visibility` | `MOD-001, USR-0003, TAL-003, No tobacco campaigns, true` |
| `model_campaign_categories` | `model_profile_id`, `category`, `selected`, `public_visible` | `MOD-001, fashion, true, true` |
| `model_usage_rights` | `public_id`, `model_profile_id`, `platform`, `territory`, `duration_months`, `exclusive`, `status` | `MUR-1001, MOD-001, instagram, Pakistan, 12, false, active` |
| `model_usage_rates` | `public_id`, `model_profile_id`, `label`, `scope`, `amount_minor`, `currency`, `requires_review`, `negotiable` | `MRT-1001, MOD-001, Digital 12 months, Pakistan social, 9500000, PKR, false, true` |
| `model_restricted_categories` | `model_profile_id`, `category`, `blocked`, `reason` | `MOD-001, tobacco, true, Personal brand safety` |

### 7.8 Location Owner portal

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `location_properties` | `public_id`, `owner_user_id`, `name`, `property_type`, `city_id`, `area_name`, `public_address`, `private_address_id`, `description`, `capacity`, `parking_spaces`, `power_backup`, `accessible`, `rating_average`, `status` | `LOC-001, USR-0030, Gulberg Heritage House, house, CITY-LHE, Gulberg, Gulberg Lahore, ADDR-LOC-1, Colonial home, 35, 8, true, true, 4.7, published` |
| `location_spaces` | `public_id`, `property_id`, `name`, `space_type`, `capacity`, `area_sqft`, `description` | `LSP-001, LOC-001, Main drawing room, interior, 20, 650, Natural light` |
| `location_media` | `property_id`, `space_id`, `file_id`, `sort_order`, `is_cover` | `LOC-001, null, FILE-LOC-1, 1, true` |
| `location_pricing` | `public_id`, `property_id`, `label`, `amount_minor`, `currency`, `unit`, `enabled`, `conditions` | `LPR-001, LOC-001, Day shoot, 18000000, PKR, day, true, 10-hour maximum` |
| `location_rules` | `public_id`, `property_id`, `rule_type`, `label`, `note`, `allowed` | `LRU-001, LOC-001, noise, Night shoots, Until 11 PM, true` |
| `location_inspections` | `public_id`, `booking_id`, `property_id`, `inspection_type`, `status`, `confirmed_by_owner_at`, `confirmed_by_renter_at`, `meter_reading`, `notes` | `LIN-1001, BK-3001, LOC-001, check_in, in_progress, null, null, 7842, Pre-shoot inspection` |
| `location_inspection_items` | `inspection_id`, `space_id`, `area_label`, `before_file_id`, `after_file_id`, `note`, `stage`, `issue_severity` | `LIN-1001, LSP-001, Main drawing room, FILE-BEFORE-1, null, Clean, captured, none` |
| `damage_claims` | `public_id`, `booking_id`, `claimant_user_id`, `respondent_user_id`, `inspection_id`, `description`, `claimed_minor`, `currency`, `status`, `submitted_at` | `DCL-1001, BK-3001, USR-0030, USR-0001, LIN-1002, Scratched floor, 350000, PKR, submitted, 2026-07-22T12:00:00Z` |
| `damage_claim_evidence` | `claim_id`, `file_id`, `evidence_type`, `caption`, `captured_at` | `DCL-1001, FILE-DMG-1, after_photo, Floor near window, 2026-07-22T10:00:00Z` |

### 7.9 Media / Equipment Provider portal

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `equipment_provider_profiles` | `public_id`, `user_id unique`, `organization_id`, `name`, `provider_type`, `city_id`, `coverage`, `service_categories`, `bio`, `rating_average`, `verification_status` | `EPP-001, USR-0031, ORG-031, LensHouse Rentals, rental_house, CITY-KHI, Nationwide, Camera lighting grip, Cinema rental house, 4.9, verified` |
| `equipment_items` | `public_id`, `provider_profile_id`, `category`, `brand`, `model_name`, `serial_encrypted`, `condition`, `day_rate_minor`, `deposit_minor`, `currency`, `city_id`, `cover_file_id`, `status` | `EQ-001, EPP-001, camera, Sony, Venice 2, <encrypted>, excellent, 12000000, 50000000, PKR, CITY-KHI, FILE-EQ-1, available` |
| `equipment_packages` | `public_id`, `provider_profile_id`, `name`, `description`, `operator_included`, `price_minor`, `currency`, `terms`, `cover_file_id`, `status` | `EPK-001, EPP-001, Cinema Camera Package, Venice 2 plus lenses, true, 18500000, PKR, 10-hour day, FILE-EPK-1, published` |
| `equipment_package_items` | `package_id`, `equipment_item_id`, `quantity`, `required` | `EPK-001, EQ-001, 1, true` |
| `equipment_terms` | `public_id`, `provider_profile_id`, `equipment_item_id`, `label`, `note`, `amount_minor`, `currency`, `enabled`, `term_type` | `ETM-001, EPP-001, null, Late return, Per hour, 1500000, PKR, true, late_fee` |
| `equipment_inspections` | `public_id`, `booking_id`, `provider_profile_id`, `inspection_type`, `status`, `handover_at`, `return_at`, `signed_by_provider`, `signed_by_renter` | `EIN-1001, BK-3101, EPP-001, handover, in_progress, 2026-07-18T06:00:00Z, null, false, false` |
| `equipment_inspection_items` | `inspection_id`, `equipment_item_id`, `before_file_id`, `after_file_id`, `accessories_json`, `stage`, `note` | `EIN-1001, EQ-001, FILE-EQ-BEFORE, null, ["battery x4","case"], captured, No marks` |

### 7.10 Crew / Services portal

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `crew_profiles` | `public_id`, `user_id unique`, `service_category`, `service_title`, `city_id`, `coverage`, `owned_kit`, `experience_years`, `day_rate_minor`, `currency`, `rating_average`, `verification_status` | `CRW-001, USR-0032, cinematography, Director of Photography, CITY-LHE, Pakistan, Sony FX6 kit, 11, 8500000, PKR, 4.8, verified` |
| `crew_credits` | `public_id`, `crew_profile_id`, `project_title`, `project_category`, `role_title`, `year`, `file_id`, `featured`, `verification_status` | `CRC-001, CRW-001, Echo Street, music_video, DOP, 2025, FILE-CRC-1, true, verified` |
| `crew_service_packages` | `public_id`, `crew_profile_id`, `name`, `description`, `rate_minor`, `currency`, `unit`, `active` | `CSP-001, CRW-001, DOP plus camera kit, Shoot day package, 12500000, PKR, day, true` |

### 7.11 Casting Agency portal

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `casting_agencies` | `public_id`, `organization_id`, `owner_user_id`, `name`, `city_id`, `commission_bps`, `verification_status` | `AGY-001, ORG-040, USR-0041, FrameOne Casting Bureau, CITY-LHE, 1500, verified` |
| `agency_invitations` | `public_id`, `agency_id`, `invited_by`, `email_or_phone_hash`, `talent_user_id`, `representation_type`, `commission_bps`, `status`, `expires_at` | `AGI-1001, AGY-001, USR-0041, <hash>, USR-0002, non_exclusive, 1500, accepted, 2026-07-31T00:00:00Z` |
| `agency_talent` | `agency_id`, `talent_profile_id`, `representation_type`, `start_date`, `end_date`, `commission_bps`, `status`, `linked_account` | `AGY-001, TAL-001, non_exclusive, 2026-01-01, null, 1500, active, true` |
| `audition_requests` | `public_id`, `agency_id`, `project_id`, `requirement_id`, `requested_by`, `role_title`, `due_at`, `budget_minor`, `currency`, `status` | `AUD-1001, AGY-001, PRJ-1001, REQ-1001, USR-0001, Lead father, 2026-07-18T12:00:00Z, 18000000, PKR, accepted` |
| `audition_candidates` | `audition_request_id`, `talent_profile_id`, `status`, `rank`, `agency_note`, `director_note`, `score` | `AUD-1001, TAL-001, shortlisted, 1, Strong match, Warm read, 92` |
| `self_tapes` | `public_id`, `audition_candidate_id`, `file_id`, `thumbnail_file_id`, `duration_seconds`, `transcript`, `status`, `submitted_at` | `TAPE-1001, AUDC-1001, FILE-TAPE-1, FILE-TAPE-TH-1, 74, My name is Ali..., submitted, 2026-07-17T09:00:00Z` |
| `selection_notes` | `audition_candidate_id`, `author_user_id`, `note`, `score`, `visibility`, `created_at` | `AUDC-1001, USR-0041, Excellent timing, 9, agency_and_director, 2026-07-17T10:00:00Z` |
| `agency_commissions` | `public_id`, `agency_id`, `booking_id`, `talent_profile_id`, `gross_minor`, `commission_bps`, `commission_minor`, `currency`, `due_at`, `status` | `COM-1001, AGY-001, BK-2048, TAL-001, 18000000, 1500, 2700000, PKR, 2026-07-22T12:00:00Z, pending` |

### 7.12 Brand / Sponsor portal

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `brand_profiles` | `public_id`, `organization_id`, `owner_user_id`, `name`, `category`, `representative`, `billing_details_encrypted`, `trust_status`, `description`, `logo_file_id` | `BRD-001, ORG-050, USR-0050, Noor Couture, fashion, Maham Noor, <encrypted>, verified, Pakistani luxury fashion, FILE-BRD-1` |
| `brand_opportunities` | `public_id`, `brand_profile_id`, `project_id`, `title`, `category`, `budget_minor`, `currency`, `usage_summary`, `eligibility`, `deliverables`, `application_due_at`, `status`, `cover_file_id` | `BOP-1001, BRD-001, PRJ-2001, Eid Editorial Campaign, fashion, 62000000, PKR, Digital and print 12 months, Verified models, 6 stills and 2 reels, 2026-08-01T12:00:00Z, published, FILE-BOP-1` |
| `brand_applications` | `public_id`, `opportunity_id`, `applicant_user_id`, `talent_profile_id`, `proposal`, `audience_metrics_json`, `budget_ask_minor`, `currency`, `status` | `BAP-1001, BOP-1001, USR-0003, TAL-003, Editorial concept proposal, {"instagram":85000}, 9500000, PKR, shortlisted` |
| `brand_terms` | `public_id`, `application_id`, `scope`, `exclusivity`, `approval_rights`, `payment_schedule_json`, `status`, `version` | `BTM-1001, BAP-1001, 6 stills 2 reels, 90-day fashion exclusivity, Brand pre-approval, [{"percent":50}], negotiating, 2` |
| `campaign_deliverables` | `public_id`, `opportunity_id`, `booking_id`, `owner_user_id`, `label`, `due_at`, `proof_file_id`, `status`, `approved_at` | `DEL-1001, BOP-1001, BK-5001, USR-0003, First Instagram reel, 2026-08-15T12:00:00Z, FILE-DEL-1, submitted, null` |
| `campaign_metrics` | `deliverable_id`, `captured_at`, `platform`, `impressions`, `reach`, `engagements`, `clicks`, `source`, `raw_json` | `DEL-1001, 2026-08-17T00:00:00Z, instagram, 120000, 91000, 8900, 1400, manual_verified, {}` |

### 7.13 Insurance / Safety portal

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `insurance_partner_profiles` | `public_id`, `user_id`, `organization_id`, `name`, `license_number_encrypted`, `coverage_regions`, `status` | `INS-P-001, USR-0060, ORG-060, CineSecure Safety Desk, <encrypted>, Pakistan, verified` |
| `insurance_policies` | `public_id`, `project_id`, `booking_id`, `provider_profile_id`, `insured_user_id`, `coverage_summary`, `valid_from`, `valid_to`, `document_file_id`, `risk_level`, `status` | `POL-1001, PRJ-1001, BK-2048, INS-P-001, USR-0001, Cast and equipment cover, 2026-07-18, 2026-07-22, FILE-POL-1, low, active` |
| `insurance_claims` | `public_id`, `policy_id`, `booking_id`, `claimant_user_id`, `title`, `item_or_room`, `adjuster_user_id`, `estimate_minor`, `currency`, `status`, `due_at` | `ICL-1001, POL-1001, BK-2048, USR-0001, Damaged lens, Sony 35mm, USR-0060, 6500000, PKR, investigating, 2026-07-25T12:00:00Z` |
| `insurance_claim_evidence` | `claim_id`, `file_id`, `evidence_type`, `mandatory`, `caption` | `ICL-1001, FILE-ICL-1, before_photo, true, Lens before handover` |
| `safety_checks` | `public_id`, `project_id`, `booking_id`, `location_property_id`, `responsible_user_id`, `due_at`, `permit_file_id`, `risk_level`, `status` | `SFC-1001, PRJ-1001, BK-2048, LOC-001, USR-0060, 2026-07-18T12:00:00Z, FILE-PERMIT-1, medium, in_review` |
| `safety_check_items` | `safety_check_id`, `label`, `detail`, `mandatory`, `completed_at`, `completed_by` | `SFC-1001, Fire exit marked, Confirm clear exits, true, null, null` |
| `incidents` | `public_id`, `project_id`, `booking_id`, `reported_by`, `title`, `severity`, `occurred_at`, `parties`, `description`, `corrective_action`, `status` | `INC-1001, PRJ-1001, BK-2048, USR-0002, Minor trip hazard, low, 2026-07-19T08:00:00Z, Crew, Cable crossed walkway, Cable ramp installed, resolved` |
| `safety_check_ins` | `public_id`, `user_id`, `booking_id`, `scheduled_at`, `checked_in_at`, `latitude_encrypted`, `longitude_encrypted`, `status`, `escalated_at` | `SCI-1001, USR-0002, BK-2048, 2026-07-19T02:30:00Z, null, null, null, scheduled, null` |

### 7.14 Distribution / Release portal

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `distribution_partner_profiles` | `public_id`, `user_id`, `organization_id`, `name`, `channels`, `territories`, `status` | `DST-P-001, USR-0070, ORG-070, CineRelease Partner Desk, Cinema OTT TV, Pakistan GCC, verified` |
| `distribution_projects` | `public_id`, `project_id`, `partner_profile_id`, `release_window_start`, `release_window_end`, `territories`, `missing_items`, `status_note`, `status` | `DPR-1001, PRJ-4001, DST-P-001, 2026-09-01, 2026-09-30, Pakistan GCC, DCP subtitles, Awaiting masters, onboarding` |
| `distributor_contacts` | `public_id`, `partner_profile_id`, `name`, `channel`, `territory`, `contact_role`, `email_encrypted`, `phone_encrypted`, `prior_project`, `notes`, `status` | `DCT-1001, DST-P-001, Aamir Shah, cinema, Pakistan, Acquisition Manager, <encrypted>, <encrypted>, Echo Street, Prefers Thursday calls, active` |
| `release_handover_items` | `distribution_project_id`, `label`, `detail`, `mandatory`, `file_id`, `status`, `approved_at` | `DPR-1001, DCP master, 4K encrypted DCP, true, null, missing, null` |
| `release_windows` | `public_id`, `distribution_project_id`, `channel`, `territory`, `starts_on`, `ends_on`, `exclusivity`, `status` | `RW-1001, DPR-1001, cinema, Pakistan, 2026-09-01, 2026-09-21, exclusive, planned` |
| `distribution_reports` | `public_id`, `distribution_project_id`, `partner_profile_id`, `territory`, `channel`, `period_start`, `period_end`, `audience_count`, `revenue_minor`, `currency`, `source_file_id`, `status` | `DRP-1001, DPR-1001, DST-P-001, Pakistan, cinema, 2026-09-01, 2026-09-07, 84000, 125000000, PKR, FILE-DRP-1, verified` |

### 7.15 Reviews, moderation, disputes, support, and communications

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `reviews` | `public_id`, `booking_id`, `reviewer_user_id`, `reviewee_user_id`, `rating`, `text`, `status`, `published_at`, unique reviewer/booking/reviewee | `REV-1001, BK-2048, USR-0001, USR-0002, 5, Professional and punctual, published, 2026-07-23T10:00:00Z` |
| `review_dimensions` | `review_id`, `dimension`, `score` | `REV-1001, punctuality, 5` |
| `review_requests` | `public_id`, `booking_id`, `requested_by`, `requested_from`, `status`, `sent_at`, `completed_review_id` | `RVR-1001, BK-2048, USR-0002, USR-0001, sent, 2026-07-22T10:00:00Z, REV-1001` |
| `reports` | `public_id`, `reporter_user_id`, `reported_user_id`, `entity_type`, `entity_id`, `reason`, `description`, `status`, `assigned_admin_id`, `resolution` | `RPT-1001, USR-0002, USR-0008, message, MSG-2001, harassment, Repeated unsafe messages, open, USR-0093, null` |
| `moderation_cases` | `public_id`, `entity_type`, `entity_id`, `source`, `risk_level`, `status`, `assigned_admin_id`, `decision`, `decision_reason` | `MODC-1001, portfolio_item, PORT-1002, user_report, medium, queued, USR-0093, null, null` |
| `moderation_events` | `case_id`, `actor_user_id`, `action`, `from_status`, `to_status`, `notes` | `MODC-1001, USR-0093, assign, queued, in_review, Reviewing media` |
| `disputes` | `public_id`, `booking_id`, `opened_by`, `respondent_user_id`, `type`, `description`, `value_minor`, `currency`, `severity`, `status`, `assigned_admin_id`, `resolved_at` | `DSP-1001, BK-3001, USR-0030, USR-0001, damage, Floor damage claim, 350000, PKR, medium, open, USR-0094, null` |
| `dispute_evidence` | `dispute_id`, `submitted_by`, `file_id`, `evidence_type`, `description` | `DSP-1001, USR-0030, FILE-DMG-1, image, Checkout floor image` |
| `dispute_events` | `dispute_id`, `actor_user_id`, `event_type`, `note`, `metadata_json` | `DSP-1001, USR-0094, assigned, Case accepted, {}` |
| `support_tickets` | `public_id`, `user_id`, `booking_id`, `category`, `priority`, `subject`, `status`, `assigned_admin_id`, `last_message_at` | `TKT-1001, USR-0001, BK-2048, payment, high, Proof needs review, open, USR-0095, 2026-07-17T10:00:00Z` |
| `support_messages` | `ticket_id`, `sender_user_id`, `body`, `file_id`, `internal_note`, `created_at` | `TKT-1001, USR-0001, Please review clearer receipt, null, false, 2026-07-17T10:00:00Z` |
| `announcements` | `public_id`, `title`, `body`, `audience_json`, `channel_json`, `status`, `scheduled_at`, `published_at`, `created_by` | `ANN-1001, Planned maintenance, Service unavailable Sunday 2 AM, {"roles":["all"]}, ["in_app","push"], scheduled, 2026-07-20T21:00:00Z, null, USR-0099` |
| `notifications` | `public_id`, `user_id`, `category`, `title`, `body`, `route_name`, `route_params_json`, `read_at`, `created_at` | `NTF-1001, USR-0002, contracts, Contract awaiting signature, Aurora TVC agreement is ready, /contract, {"contract_id":"CTR-1001"}, null, 2026-07-17T11:00:00Z` |
| `notification_deliveries` | `notification_id`, `channel`, `provider`, `provider_reference`, `status`, `sent_at`, `failed_reason` | `NTF-1001, push, firebase, fcm-123, delivered, 2026-07-17T11:00:05Z, null` |
| `push_devices` | `user_id`, `platform`, `token_encrypted`, `device_id`, `enabled`, `last_seen_at` | `USR-0002, android, <encrypted>, pixel-ali-1, true, 2026-07-17T11:00:00Z` |

### 7.16 Admin, audit, configuration, analytics, and operations

| Table | Required columns / relationships | Sample seed row |
|---|---|---|
| `admin_queue_assignments` | `queue_type`, `entity_type`, `entity_id`, `assigned_to`, `assigned_by`, `status`, `sla_due_at` | `payment_review, payment_proof, PP-1001, USR-0095, USR-0099, active, 2026-07-17T13:00:00Z` |
| `admin_decisions` | `public_id`, `entity_type`, `entity_id`, `decision`, `reason_code`, `notes`, `actor_user_id`, `created_at` | `DEC-1001, payment_proof, PP-1001, approved, matched_reference, Amount and reference match, USR-0095, 2026-07-17T11:30:00Z` |
| `audit_logs` | `public_id`, `actor_user_id`, `event_type`, `entity_type`, `entity_id`, `action`, `before_json`, `after_json`, `ip_address`, `user_agent`, `risk_level`, `request_id`, `created_at` | `AUDLOG-1001, USR-0095, payment_review, payment_proof, PP-1001, approve, {"status":"pending"}, {"status":"verified"}, 203.0.113.20, Admin Web, low, req_01J..., 2026-07-17T11:30:00Z` |
| `system_settings` | `key unique`, `value_json`, `is_public`, `updated_by` | `maintenance_mode, {"enabled":false}, true, USR-0099` |
| `feature_flags` | `key unique`, `description`, `enabled`, `rules_json`, `updated_by` | `realtime_chat, Enable Socket.IO chat, true, {"percentage":100}, USR-0099` |
| `app_versions` | `platform`, `minimum_version`, `latest_version`, `force_update`, `store_url`, unique platform | `android, 1.0.0, 1.1.0, false, https://play.google.com/...` |
| `webhook_events` | `provider`, `external_id`, `event_type`, `payload_json`, `signature_valid`, `status`, `attempts`, `processed_at`, unique provider/external_id | `payment_provider, evt_1001, payment.completed, {"id":"..."}, true, processed, 1, 2026-07-17T11:30:00Z` |
| `outbox_events` | `aggregate_type`, `aggregate_id`, `event_type`, `payload_json`, `status`, `available_at`, `attempts` | `booking, BK-2048, booking.secured, {"booking_id":"BK-2048"}, pending, 2026-07-17T11:31:00Z, 0` |
| `background_jobs` | `public_id`, `job_type`, `entity_type`, `entity_id`, `status`, `progress`, `result_file_id`, `error_message`, `requested_by` | `JOB-1001, project_report_export, project, PRJ-1001, queued, 0, null, null, USR-0001` |
| `analytics_daily_metrics` | `metric_date`, `scope_type`, `scope_id`, `metric_key`, `metric_value_numeric`, `dimensions_json`, unique date/scope/key/dimensions | `2026-07-17, platform, all, bookings_secured, 14, {"city":"Lahore"}` |
| `data_export_requests` | `public_id`, `user_id`, `export_type`, `filters_json`, `status`, `result_file_id`, `expires_at` | `EXP-1001, USR-0001, project_finance, {"project_id":"PRJ-1001"}, queued, null, 2026-07-24T12:00:00Z` |
| `data_deletion_requests` | `public_id`, `user_id`, `reason`, `status`, `scheduled_for`, `completed_at`, `retention_exceptions_json` | `DELREQ-1001, USR-0080, User request, pending_review, 2026-08-17T00:00:00Z, null, {"contracts":"legal retention"}` |

### 7.17 Required indexes

At minimum:

- `users(lower(email))`, `users(phone_e164)`;
- every public code;
- `projects(owner_user_id, status, updated_at desc)`;
- `project_requirements(project_id, status)`;
- GIN/trigram search indexes for listing title/summary and profile display names;
- `marketplace_listings(listing_type, city_id, status, published_at desc)`;
- `bookings(requester_user_id, status, updated_at desc)` and provider equivalent;
- exclusion constraint or transactional overlap check for availability resources;
- `messages(conversation_id, created_at desc)`;
- `notifications(user_id, read_at, created_at desc)`;
- `payment_proofs(status, created_at)` and all admin queues by status/SLA;
- `audit_logs(entity_type, entity_id, created_at desc)` and `(actor_user_id, created_at desc)`;
- analytics by `metric_date`, `metric_key`, and scope.

---

## 8. Complete portal and screen-to-API plan

All screen endpoints below are relative to `/api/v1`. Dashboard endpoints may return composed read models, but mutations must use domain endpoints.

### 8.1 Shared/core screens

| Screen / route | Dynamic data and operations | API |
|---|---|---|
| Splash `/` | app version, maintenance, token refresh, initial route | `GET /app/bootstrap`, `POST /auth/refresh` |
| Onboarding `/onboarding` | remotely configurable slides/links if desired | `GET /app/public-config` |
| Role selection `/roles` | eligible roles, verification requirement | `GET /roles`, `POST /me/roles` |
| Login `/login` | login, MFA challenge, device registration | `POST /auth/login`, `POST /auth/mfa/verify` |
| Signup `/signup` | account and initial role | `POST /auth/register`, `POST /auth/verify-email` |
| Forgot password | request and complete reset | `POST /auth/password/forgot`, `POST /auth/password/reset` |
| KYC upload | create submission, signed uploads, submit | `POST /kyc/submissions`, `POST /uploads/presign`, `POST /kyc/submissions/{id}/submit` |
| Verification status | status, requirements, resubmission | `GET /me/kyc`, `POST /kyc/submissions/{id}/resubmit` |
| Profile role switcher | active roles and switching eligibility | `GET /me/roles`, `PATCH /me/primary-role` |
| Notifications | category filters, read/unread, deep links | `GET /notifications`, `PATCH /notifications/{id}/read`, `POST /notifications/read-all` |
| Booking chat | paginated messages, uploads, decisions, read state | `GET/POST /conversations/{id}/messages`, `POST /messages/{id}/pin`, WebSocket events |
| Contract viewer | clauses, parties, addendums, signature | `GET /contracts/{id}`, `POST /contracts/{id}/signatures`, `POST /contracts/{id}/addendums` |
| Payment proof | milestone, presigned upload, submission | `GET /payment-milestones/{id}`, `POST /payment-proofs` |
| Receipts ledger | filters, totals, download receipt/export | `GET /ledger`, `GET /receipts/{id}`, `POST /exports` |
| Ratings review | eligibility, dimensions, publish | `GET /bookings/{id}/review-eligibility`, `POST /reviews` |
| Report/block | reasons, submit evidence, block/unblock | `GET /reports/reasons`, `POST /reports`, `POST/DELETE /blocked-users/{id}` |
| Settings | account, notification, theme, password, sessions, deletion | `GET/PATCH /me`, `GET/PATCH /me/settings`, `/me/sessions`, `/me/deletion-request` |
| Utility screens | health, minimum version, maintenance content | `GET /app/bootstrap`, local network detection |
| Generic dashboard | current role summary and portal deep links | `GET /me/dashboard` |

### 8.2 Director / Producer portal

| ID / screen | Required dynamic behavior | API |
|---|---|---|
| DP-01 Home Dashboard | project/booking/payment KPIs, tasks, activity | `GET /director/dashboard` |
| DP-02 Projects List | search/filter/sort/paginate, archive | `GET /projects`, `PATCH /projects/{id}` |
| DP-03 Create Project Wizard | autosave draft, validation, publish | `POST /projects`, `PATCH /projects/{id}`, `POST /projects/{id}/publish` |
| DP-04 Project Detail | summary, budget, requirements, team, lifecycle | `GET /projects/{id}`, `GET /projects/{id}/activity` |
| DP-05 Requirement Builder | CRUD role/service/location/equipment needs | `GET/POST /projects/{id}/requirements`, `PATCH /requirements/{id}` |
| DP-06 Marketplace Discovery | server search, facets, saved search | `GET /marketplace/listings`, `POST /saved-searches` |
| DP-07 Smart Filters Sheet | remote filter values and result counts | `GET /marketplace/facets`, `POST /marketplace/result-count` |
| DP-08 Stakeholder Profile | authorized public profile, reviews, portfolio, availability | `GET /marketplace/listings/{id}` |
| DP-09 Shortlist Board | create boards, add/remove/reorder/note | `GET/POST /shortlists`, `POST /shortlists/{id}/items`, `PATCH /shortlist-items/{id}` |
| DP-10 Booking Request | draft and send offer, clash check | `POST /bookings`, `POST /bookings/{id}/send`, `POST /availability/check` |
| DP-11 Bargaining Center | filter live negotiations and expiries | `GET /negotiations` |
| DP-12 Negotiation Thread | immutable offer rounds, accept/counter/reject | `GET /negotiations/{id}`, `POST /bookings/{id}/offers`, `POST /offers/{id}/accept` |
| DP-13 Contract Center | list/generate/view/request review | `GET /contracts`, `POST /bookings/{id}/contracts`, `POST /legal-reviews` |
| DP-14 Payment Center | schedules, proofs, statuses, receipts | `GET /payments/dashboard`, `GET /payment-schedules`, `POST /payment-proofs` |
| DP-15 Calendar Schedule | cross-project agenda, conflicts, exports | `GET /calendar`, `POST /calendar/conflict-check`, `POST /exports` |
| DP-16 Project Accounts | budget categories, committed/paid/pending totals | `GET /projects/{id}/accounts`, `GET /projects/{id}/ledger` |
| DP-17 Project Room | members, files, pinned decisions, activity | `GET /projects/{id}/room`, `/projects/{id}/members`, `/projects/{id}/files` |
| DP-18 Reports Export | request/poll/download exports | `POST /exports`, `GET /exports/{id}` |

### 8.3 Actor / Talent portal

| ID / screen | Required dynamic behavior | API |
|---|---|---|
| AT-01 Talent Dashboard | offers, earnings, calendar, reviews, tasks | `GET /talent/dashboard` |
| AT-02 Profile Builder | profile fields, skills, languages, preview | `GET/PATCH /talent/profile`, `/talent/skills`, `/talent/languages` |
| AT-03 Portfolio & Showreel | upload, reorder, cover, publish/delete | `GET/POST /portfolio`, `PATCH/DELETE /portfolio/{id}`, `/uploads/presign` |
| AT-04 Availability Calendar | month data, blocks/holds, clash protection | `GET/POST /availability`, `PATCH /availability/{id}` |
| AT-05 Rate Card | CRUD categorized rates and export | `GET/POST /talent/rate-cards`, `PATCH /talent/rate-items/{id}`, `POST /exports` |
| AT-06 Opportunity Inbox | filters, read state, bulk-safe actions | `GET /talent/opportunities`, `PATCH /bookings/{id}/viewed` |
| AT-07 Offer Detail | trust, project, dates, terms, accept/reject | `GET /bookings/{id}`, `POST /offers/{id}/accept`, `POST /bookings/{id}/reject` |
| AT-08 Counteroffer Composer | validate and send versioned counter | `POST /bookings/{id}/offers` |
| AT-09 Contract Signing | shared contract flow | `GET /contracts/{id}`, `POST /contracts/{id}/signatures` |
| AT-10 Earnings Security | schedules, ledger, proof/receipt, payout account | `GET /talent/earnings`, `/ledger`, `/payout-accounts` |
| AT-11 Reputation Reviews | ratings, dimensions, request review/export | `GET /users/{id}/reviews`, `POST /review-requests`, `POST /exports` |
| AT-12 Safety Controls | blocks, reports, check-ins, trusted contacts | `/blocked-users`, `/reports`, `/safety-check-ins`, `/trusted-contacts` |

### 8.4 Model extension

| ID / screen | Dynamic behavior | API |
|---|---|---|
| MD-01 Campaign Categories | select/public visibility/save | `GET/PATCH /model/campaign-categories` |
| MD-02 Usage Rights | CRUD rights, contract locks | `GET/POST /model/usage-rights`, `PATCH /model/usage-rights/{id}` |
| MD-03 Portfolio Categories | filtered portfolio management | `GET /portfolio?profile_type=model`, standard portfolio mutations |
| MD-04 Rate by Usage | CRUD rates, review flags | `GET/POST /model/usage-rates`, `PATCH /model/usage-rates/{id}` |
| MD-05 Brand Safety | restriction toggles and explanations | `GET/PATCH /model/restricted-categories` |

### 8.5 Location Owner portal

| ID / screen | Dynamic behavior | API |
|---|---|---|
| LO-01 Owner Dashboard | property/request/income/deposit KPIs | `GET /locations/dashboard` |
| LO-02 Listing Wizard | autosave property, spaces, media, publish | `/location-properties`, `/location-spaces`, `/location-media`, publish endpoint |
| LO-03 Availability | property calendar and booking locks | `GET/POST /availability?resource_type=location` |
| LO-04 Pricing & Deposit | pricing rules and deposit values | `GET/POST/PATCH /location-properties/{id}/pricing` |
| LO-05 Rules & Restrictions | CRUD/toggle rules | `GET/POST/PATCH /location-properties/{id}/rules` |
| LO-06 Booking Requests | filter, detail, accept/counter/reject | `GET /location-bookings`, standard booking/offer actions |
| LO-07 Check-In Inspection | offline draft, photos, meter, dual confirmation | `/location-inspections`, `/inspection-items`, signed uploads |
| LO-08 Check-Out / Damage Claim | after photos, compare, claim, evidence | `/location-inspections/{id}`, `POST /damage-claims` |
| LO-09 Earnings & Deposits | rental ledger, deposit timeline, export | `GET /locations/earnings`, `/security-deposits`, `/ledger`, `/exports` |
| LO-10 Property Performance | range/metric filters, chart/table/export | `GET /location-properties/{id}/analytics`, `POST /exports` |

### 8.6 Media / Equipment Provider portal

| ID / screen | Dynamic behavior | API |
|---|---|---|
| ME-01 Dashboard | inventory/request/earnings/tasks | `GET /equipment/dashboard` |
| ME-02 Provider Profile | provider identity, coverage, categories | `GET/PATCH /equipment/provider-profile` |
| ME-03 Inventory Manager | CRUD/search/filter items, photos, serial security | `/equipment/items`, `/uploads/presign` |
| ME-04 Package Builder | 3-step autosaved package and item selection | `/equipment/packages`, `/equipment/packages/{id}/items`, publish |
| ME-05 Availability Calendar | item/team status, holds, transit, maintenance | `GET/POST /availability?resource_type=equipment` |
| ME-06 Rate & Terms | CRUD/toggle rates, deposit, booking rules | `/equipment/terms` |
| ME-07 Booking Requests | search/filter/detail/counter/reject/accept | `GET /equipment/bookings`, standard booking/offer actions |
| ME-08 Handover Checklist | item/accessory photos and dual signature | `/equipment-inspections` |
| ME-09 Return Checklist | compare condition, missing/damage, claim | `/equipment-inspections/{id}`, `/damage-claims` |
| ME-10 Earnings & Ratings | earnings ledger, payouts, reviews | `GET /equipment/earnings`, `/ledger`, `/reviews` |

### 8.7 Crew / Services portal

| ID / screen | Dynamic behavior | API |
|---|---|---|
| CR-01 Crew Dashboard | work, earnings, tasks, profile health | `GET /crew/dashboard` |
| CR-02 Service Profile | service, coverage, kit, rate, identity | `GET/PATCH /crew/profile` |
| CR-03 Portfolio & Credits | CRUD media/credits, verification | `/crew/credits`, `/portfolio` |
| CR-04 Availability | block/open/hold/booked dates | `/availability?resource_type=crew` |
| CR-05 Requests & Negotiation | inbox and offer state machine | `GET /crew/bookings`, booking/offer endpoints |
| CR-06 Contracts & Payments | shared contracts, milestones, ledger | `/contracts`, `/payment-schedules`, `/ledger` |
| CR-07 Ratings & Work History | completed bookings and reviews | `GET /crew/work-history`, `/users/{id}/reviews` |

### 8.8 Casting Agency portal

| ID / screen | Dynamic behavior | API |
|---|---|---|
| CA-01 Dashboard | roster/audition/tape/commission KPIs | `GET /agencies/dashboard` |
| CA-02 Talent Roster | link/invite/remove/filter talent | `/agencies/{id}/talent`, `POST /agency-invitations` |
| CA-03 Audition Inbox | accept/decline/assign candidates | `/auditions`, `/auditions/{id}/candidates` |
| CA-04 Shortlist Builder | add/remove/reorder/share shortlist | `/auditions/{id}/candidates`, `/shortlists` |
| CA-05 Self-Tape Collection | upload/preview/transcript/status | `/self-tapes`, signed uploads |
| CA-06 Selection Notes | permissioned notes, scores, director feedback | `/audition-candidates/{id}/notes` |
| CA-07 Commission Records | defaults, booking calculations, status/export | `/agencies/{id}/commissions`, `/exports` |
| CA-08 Booking Records | filtered historical bookings | `GET /agencies/{id}/bookings` |

### 8.9 Brand / Sponsor portal

| ID / screen | Dynamic behavior | API |
|---|---|---|
| BR-01 Brand Dashboard | opportunities/applications/campaign/payment KPIs | `GET /brands/dashboard` |
| BR-02 Brand Profile | identity, representative, billing, logo | `GET/PATCH /brands/profile` |
| BR-03 Opportunity Composer | autosave/publish campaign opportunity | `/brand-opportunities`, publish |
| BR-04 Applications Inbox | search/filter/shortlist/reject/open | `/brand-opportunities/{id}/applications` |
| BR-05 Negotiation & Terms | versioned scope/exclusivity/approval/payment terms | `/brand-applications/{id}/terms` |
| BR-06 Campaign Tracker | deliverables, proofs, approval, performance | `/campaign-deliverables`, `/campaign-metrics` |
| BR-07 Payments & Records | schedules, payments, receipts, export | `/brand/payments`, `/ledger`, `/exports` |

### 8.10 Legal Partner portal

| ID / screen | Dynamic behavior | API |
|---|---|---|
| LG-01 Legal Dashboard | queue/SLA/risk/billing KPIs | `GET /legal/dashboard` |
| LG-02 Contract Review Detail | clauses, risks, approve/change/escalate | `/legal-reviews/{id}`, `/legal-reviews/{id}/risks`, decision endpoint |
| LG-03 Template Review | version diff, clause edits, approval | `/contract-templates/{id}`, `/template-change-requests` |
| LG-04 Addendum Review | source decision, affected contract, decision | `/contract-addendums/{id}`, review endpoint |
| LG-05 Review History & Billing | filters, invoices, notes/export | `/legal/reviews`, `/legal/billing`, `/exports` |

### 8.11 Insurance / Safety portal

| ID / screen | Dynamic behavior | API |
|---|---|---|
| IN-01 Dashboard | policy/claim/check/incident KPIs | `GET /insurance/dashboard` |
| IN-02 Shoot Insurance Records | policy CRUD/status/docs/search | `/insurance/policies` |
| IN-03 Claim Support | case, estimate, evidence, adjuster, decision | `/insurance/claims`, `/insurance/claims/{id}/evidence` |
| IN-04 Safety Checks & Permits | checklist, permit upload, approval | `/safety-checks`, `/safety-checks/{id}/items` |
| IN-05 Incident Reports | filter, severity, corrective action, chart/export | `/incidents`, `/insurance/analytics`, `/exports` |

### 8.12 Distribution / Release portal

| ID / screen | Dynamic behavior | API |
|---|---|---|
| DS-01 Dashboard | projects, handovers, releases, report KPIs | `GET /distribution/dashboard` |
| DS-02 Distributor Contacts | secure contact CRUD/history/search | `/distributor-contacts` |
| DS-03 Release Coordination | windows and mandatory handover items/files | `/distribution-projects`, `/release-windows`, `/release-handover-items` |
| DS-04 Performance Reporting | filters, chart/table, upload/verify/export | `/distribution-reports`, `/distribution/analytics`, `/exports` |

### 8.13 Super Admin portal

| Screen / route | Dynamic behavior | API |
|---|---|---|
| Admin Dashboard | platform KPIs, queues, live feed | `GET /admin/dashboard` |
| Review Hub + People/Listings/Content | queue tabs, assignment, SLA | `GET /admin/review-queues`, assignment endpoint |
| User/People Verification Queue | filters, bulk assign | `GET /admin/kyc-submissions` |
| KYC Review Detail | secure docs, approve/reject/resubmit | `GET /admin/kyc-submissions/{id}`, decision endpoint |
| Content Moderation Queue/Detail | evidence, reports, hide/approve/escalate | `/admin/moderation-cases` and decision |
| Listings Review Queue/Detail | listing/profile/media review | `/admin/listings` and moderation decision |
| Booking Monitor | live booking filters/risk/export | `GET /admin/bookings` |
| Booking Detail | parties, events, contract/payment/chat metadata | `GET /admin/bookings/{id}` |
| Payments Hub | aggregates and queue links | `GET /admin/payments/dashboard` |
| Payment Verification Queue | filter/assign/SLA | `GET /admin/payment-proofs` |
| Payment Review Detail | proof compare, approve/reject/clarify | `GET /admin/payment-proofs/{id}`, decision endpoint |
| Receipts Ledger Admin | platform ledger and CSV | `GET /admin/ledger`, `/exports` |
| Revenue Settings | fee rules with effective dates | `/admin/fee-rules` |
| Contract Template Manager | list/create/version/publish/archive | `/admin/contract-templates` |
| Contract Template Detail | clause editor, preview, approval | `/admin/contract-templates/{id}` |
| Commission & Fee | fee rules and previews | `/admin/fee-rules`, `/admin/fees/preview` |
| Dispute Center | queues/filter/assign | `GET /admin/disputes` |
| Dispute Case File | timeline/evidence/messages/resolution | `/admin/disputes/{id}` and decision |
| User Management | search/status/roles/trust/devices | `/admin/users` |
| Admin Roles & Permissions | RBAC CRUD with self-lockout protection | `/admin/roles`, `/admin/permissions`, assignments |
| Support CRM | tickets, assignment, internal notes, reply | `/admin/support-tickets` |
| Broadcast Announcements | draft/preview/schedule/publish/cancel | `/admin/announcements` |
| Audit Log Explorer | immutable search/export | `/admin/audit-logs`, `/exports` |
| Admin Analytics | ranges, filters, accessible charts/table/export | `/admin/analytics`, `/exports` |

Admin decisions require reason codes, notes where applicable, transaction-safe updates, an audit event, and notification to affected users.

---

## 9. Dashboard and analytics rules

Dashboard numbers must be derived, never manually edited. Use optimized SQL queries initially; add daily aggregate tables and Redis caching after correctness is proven.

Examples:

- active projects: owner/member project where status is active;
- pending offers: provider booking in sent/viewed/under-negotiation;
- secured value: sum of agreed booking amounts in secured/in-progress/completed;
- available balance: released ledger credits minus debits/payouts;
- average rating: published review average only;
- verification SLA: current time minus submitted time for undecided KYC;
- platform revenue: posted platform-fee ledger entries, not gross booking volume;
- conversion: secured bookings divided by sent bookings for the selected range;
- property request rate: booking requests divided by eligible listing views.

Charts must also have a table representation and locale-aware PKR/date formatting.

---

## 10. File and media workflow

1. Flutter calls `POST /uploads/presign` with purpose, MIME type, and size.
2. Flask checks role, quota, allowed MIME, and purpose; creates `upload_sessions`.
3. Flutter uploads directly to private object storage using the signed URL.
4. Flutter calls `POST /uploads/{id}/complete`.
5. A worker verifies checksum, scans malware, reads metadata, creates thumbnails/transcodes, strips unsafe metadata, and marks `files.processing_status=ready`.
6. Domain mutation references the completed `file_id`.
7. Authorized downloads use short-lived signed URLs. Public listing thumbnails may use CDN URLs after moderation.

Limits should be configurable. Initial defaults:

- avatar/photo: 10 MB;
- KYC image/PDF: 15 MB;
- contract/proof: 20 MB;
- portfolio video/self-tape: 500 MB;
- allowed documents: PDF/JPEG/PNG;
- allowed video: MP4/MOV accepted, normalized to streaming-friendly MP4/HLS.

KYC, payment proofs, signatures, exact addresses, claim evidence, and contracts are always private.

---

## 11. Realtime and notification behavior

WebSocket rooms:

- `user:{user_id}` for notifications;
- `conversation:{conversation_id}` for messages, typing, read receipts;
- `booking:{booking_id}` for status refresh;
- `admin_queue:{queue_type}` for authorized admin dashboards.

Events include:

`message.created`, `message.read`, `offer.created`, `offer.accepted`, `booking.status_changed`, `contract.ready`, `contract.signed`, `payment.proof_submitted`, `payment.verified`, `notification.created`, `admin.queue_updated`.

WebSockets improve responsiveness but are not the source of truth. On reconnect Flutter fetches from REST using last-known timestamp/cursor.

Notification triggers:

- KYC approved/rejected/resubmission requested;
- offer received/viewed/countered/accepted/rejected/expiring;
- contract ready/signed/addendum requested;
- milestone due/proof clarification/verified/released;
- booking reminder and availability conflict;
- inspection/check-in overdue;
- damage claim/dispute update;
- review eligible;
- support/admin message;
- scheduled announcement.

---

## 12. Flutter integration plan

Add dependencies appropriate to the selected state-management approach. A conservative stack:

- `dio` for HTTP, interceptors, cancellation, upload progress;
- `flutter_secure_storage` for refresh/access token material on mobile;
- a web-appropriate secure session strategy, preferably same-site secure cookies if Flutter web and API share an approved domain setup;
- `riverpod` or `flutter_bloc` for async state;
- `freezed` + `json_serializable` for DTOs;
- `connectivity_plus` for network hints;
- `web_socket_channel` or compatible Socket.IO client;
- `go_router` eventually for true parameterized deep links.

Proposed frontend layers:

```text
lib/
  core/
    api/api_client.dart
    api/api_error.dart
    auth/auth_repository.dart
    auth/token_store.dart
    config/app_config.dart
    realtime/realtime_client.dart
    uploads/upload_repository.dart
  data/
    dto/
    repositories/
  features/<feature>/
    application/
    data/
    presentation/   # existing screens/widgets
```

### 12.1 API client requirements

- Inject `baseUrl` via `--dart-define=API_BASE_URL=...`.
- Add access token and `X-Request-ID`.
- Refresh once on 401 using a single-flight lock, replay safe requests, then logout if refresh fails.
- Map API codes to typed failures.
- Apply sensible connect/read/write timeouts.
- Cancel obsolete search requests.
- Never print authorization headers or sensitive response bodies.
- Verify production TLS; do not bypass certificate validation.

### 12.2 Screen state contract

Every connected screen exposes:

```text
initial/loading
success with data
success empty
refreshing without removing current data
validation error
permission/verification required
offline with cached data where safe
server/timeout error with retry
mutation in progress
mutation success and affected-query refresh
```

Long forms (project, location listing, package, opportunity) autosave drafts. Offline inspection forms store an encrypted local draft and synchronize idempotently when network returns.

### 12.3 Migration away from demo stores

For each portal:

1. Create DTOs matching the API, not the presentation models.
2. Add repository interface and remote implementation.
3. Add state controller/provider.
4. Adapt DTOs to UI view models.
5. Replace one screen’s demo-store reads and direct mutations.
6. Add tests for loading/empty/error/populated/action states.
7. Repeat until no production screen imports `*_demo_data.dart`.
8. Keep demo data only as test fixtures or delete after migration.

---

## 13. Security and privacy requirements

- TLS 1.2+ and HSTS in production.
- Argon2id password hashing with environment-calibrated parameters.
- Short access tokens; rotating refresh tokens stored hashed in DB.
- Secure, HttpOnly, SameSite cookies for web when used; secure storage for mobile.
- CSRF protection for cookie-authenticated browser mutations.
- CORS allowlist contains exact production/staging frontend origins only.
- Rate limits for login, signup, OTP, password reset, messaging, search, uploads, and admin exports.
- Server-side MIME detection, malware scanning, file-size enforcement, and image/video re-encoding.
- Field-level encryption for exact addresses, KYC numbers, payout tokens, transaction references, and private contacts.
- Do not return exact location address/contact details until booking policy permits.
- Query-level authorization prevents IDOR.
- Admin MFA, short session duration, reason-required decisions, and full audit.
- Immutable financial and audit records; corrections use reversing entries/events.
- SQLAlchemy parameter binding only; no string-built SQL from user input.
- Output escaping and content sanitization for user-generated HTML/markdown.
- Secrets only from environment/secret manager; never committed.
- Automated dependency and container vulnerability scans.
- Daily backups, point-in-time recovery, and tested restore procedures.

Data retention must be confirmed with legal counsel for the launch jurisdiction. Define explicit retention for KYC, contracts, payments, audit logs, chat, safety reports, and deleted accounts.

---

## 14. Server, domain, and HTTPS configuration template

The user will provide final values. Never place real secrets in this document or source control.

Create `backend/.env` only on the server and keep `backend/.env.example` with placeholders:

```dotenv
APP_ENV=production
SECRET_KEY=<64+ random characters>
JWT_SECRET_KEY=<separate 64+ random characters>
DATABASE_URL=postgresql+psycopg://<user>:<password>@<private-host>:5432/<database>
REDIS_URL=redis://:<password>@<private-host>:6379/0
CELERY_BROKER_URL=${REDIS_URL}
CELERY_RESULT_BACKEND=${REDIS_URL}

PUBLIC_WEB_ORIGIN=https://<YOUR_DOMAIN>
API_PUBLIC_URL=https://api.<YOUR_DOMAIN>
CORS_ALLOWED_ORIGINS=https://<YOUR_DOMAIN>,https://admin.<YOUR_DOMAIN>

OBJECT_STORAGE_ENDPOINT=https://<storage-endpoint>
OBJECT_STORAGE_BUCKET_PRIVATE=cineconnect-private
OBJECT_STORAGE_BUCKET_PUBLIC=cineconnect-public
OBJECT_STORAGE_ACCESS_KEY=<secret>
OBJECT_STORAGE_SECRET_KEY=<secret>
CDN_BASE_URL=https://media.<YOUR_DOMAIN>

SMTP_HOST=<host>
SMTP_PORT=587
SMTP_USERNAME=<secret>
SMTP_PASSWORD=<secret>
MAIL_FROM=no-reply@<YOUR_DOMAIN>

FCM_PROJECT_ID=<id>
FCM_CREDENTIALS_PATH=/run/secrets/fcm.json
SENTRY_DSN=<secret>
```

Recommended DNS:

```text
<YOUR_DOMAIN>       -> Flutter web host/CDN
api.<YOUR_DOMAIN>   -> API load balancer/server
admin.<YOUR_DOMAIN> -> optional admin web origin
media.<YOUR_DOMAIN> -> CDN/object storage
```

Production request path:

```text
Flutter: https://api.<YOUR_DOMAIN>/api/v1/...
Nginx: TLS termination -> http://127.0.0.1:8000
Gunicorn: app:create_app()
```

Nginx responsibilities:

- redirect HTTP to HTTPS;
- use an automatically renewed certificate;
- add HSTS, `X-Content-Type-Options`, referrer policy, and a suitable CSP;
- proxy `/socket.io` with upgrade headers;
- enforce a small normal JSON body limit because media uses signed uploads;
- forward request ID and real client IP safely;
- apply timeouts appropriate to API requests, not long-running report generation.

Use at least staging and production environments with separate databases, buckets, Redis instances, keys, OAuth/payment webhooks, and domains.

### 14.1 Flutter environment values

```bash
flutter run \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1

flutter build web \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.<YOUR_DOMAIN>/api/v1
```

Android emulator uses `10.0.2.2`; iOS simulator can generally use `127.0.0.1`; a physical device needs a LAN-accessible HTTPS development host or tunnel.

---

## 15. Testing strategy and acceptance gates

### 15.1 Backend tests

- unit tests for services, money calculations, permissions, transitions, and serializers;
- integration tests against PostgreSQL for every endpoint;
- migration up/down and clean-database boot tests;
- auth tests for missing/expired/revoked/reused tokens;
- object-level authorization tests between every role pair;
- idempotency tests for payment, webhook, offer, upload-complete, and inspection sync;
- race tests for simultaneous offer acceptance, double booking, payment review, and contract signature;
- file validation tests;
- task tests for reminders, exports, notifications, and retry/dead-letter behavior;
- OpenAPI response-contract tests.

### 15.2 Flutter tests

- repository tests with mocked API;
- controller/provider state tests;
- widget tests for loading, empty, error, and populated states;
- interaction tests for each visible action;
- deep-link tests including real IDs;
- token-refresh and logout tests;
- offline inspection draft/sync tests;
- current overflow tests retained for light/dark modes and multiple sizes.

### 15.3 End-to-end journeys

1. Producer signup -> KYC -> project -> requirement -> shortlist -> offer.
2. Talent receives offer -> counteroffers -> producer accepts.
3. Contract generated -> both parties sign -> addendum if requested.
4. Producer uploads payment proof -> admin verifies -> booking secured.
5. Chat, calendar lock, reminder, work completion, receipt, review.
6. Location booking -> check-in photos -> check-out -> deposit release or damage dispute.
7. Equipment booking -> handover accessories -> return -> missing-item claim.
8. Brand opportunity -> model application -> terms -> deliverables -> campaign metrics.
9. Legal review and insurance claim queues.
10. Admin suspend/restore, moderation, dispute, support, announcement, audit export.

Release gate:

- no production screen imports demo stores;
- every interactive control either works or is deliberately disabled with an explanation;
- API contract and migration are committed;
- tests pass;
- no high/critical security findings;
- backup restore tested;
- monitoring alerts and runbook tested.

---

## 16. Non-functional requirements

Initial targets:

- API p95 under 400 ms for ordinary reads and under 700 ms for dashboard aggregates;
- search p95 under 800 ms;
- 99.9% monthly API availability after production stabilization;
- no request worker blocked by media processing or report generation;
- cursor pagination for chat/audit at scale;
- WCAG 2.1 AA behavior in Flutter web where applicable;
- 44x44 pt minimum touch targets and visible async feedback;
- UTC storage, locale-aware dates/numbers/currency;
- database backups at least daily plus point-in-time recovery;
- RPO <= 15 minutes and initial RTO <= 4 hours, refined after business review;
- structured logs include request ID, route, status, latency, user ID where lawful, but no sensitive payload.

---

## 17. Risks and decisions requiring user-provided details

Before production integration, record answers in `docs/DEPLOYMENT_INPUTS.md`:

1. Production domain and API subdomain.
2. Server OS/provider, CPU/RAM/storage, SSH deployment user, and whether Docker is permitted.
3. PostgreSQL host/version/database/user and whether it is managed.
4. Redis availability.
5. Object-storage provider, bucket names, region, and CDN.
6. Email, SMS/OTP, and push-notification providers.
7. Payment workflow: manual proof only, gateway, escrow, or hybrid.
8. Required Pakistani payment methods/banks/wallets.
9. Legal business name, terms/privacy documents, retention rules, and jurisdiction.
10. Whether exact phone/address unlocks after contract, deposit verification, or secured booking.
11. Supported platforms at launch: Android, iOS, web, admin web.
12. App Store/Play Store identifiers and deep-link domains.
13. Expected users, media volume, concurrent chat load, and monthly budget.
14. Admin organization structure and permission scopes.
15. Analytics/monitoring providers and data-residency restrictions.

Do not guess payment settlement, tax, escrow, KYC legality, or data-retention rules. Those require business/legal confirmation.

---

## 18. Step-by-step implementation roadmap

### Phase 0 — Confirm inputs and freeze contracts

- Create `docs/DEPLOYMENT_INPUTS.md`.
- Confirm the decisions in Section 17.
- Create an OpenAPI-first API skeleton.
- Inventory every current button and mutation.
- Create `docs/IMPLEMENTATION_PROGRESS.md`.

**Exit:** approved environment matrix, terminology, state machines, privacy rules, and API naming.

### Phase 1 — Backend foundation

- Scaffold Flask application factory, config, logging, error envelope, health routes.
- Add PostgreSQL, Redis, SQLAlchemy, Alembic, test database, Docker Compose for development.
- Add CI for lint, type checks, tests, migration check.
- Add request IDs and baseline security headers.

**Exit:** clean clone can start API, worker, PostgreSQL, Redis and run tests.

### Phase 2 — Identity and Flutter API foundation

- Implement identity/access tables and seeds.
- Register/login/refresh/logout/reset/email/OTP/session flows.
- Implement RBAC and policy tests.
- Add Flutter API client, secure token store, auth repository, environment config.
- Connect splash, login, signup, forgot password, role selection/switcher, and settings.

**Exit:** a user can register, authenticate, restart the app, refresh tokens, switch authorized roles, and log out.

### Phase 3 — KYC, files, and admin verification

- Implement signed uploads, processing metadata, scan hooks.
- Implement KYC submissions/documents/events.
- Connect KYC user screens and admin queue/detail.
- Add audit events and notifications.

**Exit:** KYC can be submitted, reviewed, approved/rejected/resubmitted with secure files and complete audit history.

### Phase 4 — Profiles and marketplace

- Implement organizations, base profiles, cities, files, listings, media, tags, search/facets.
- Implement talent/model/location/equipment/crew/agency/brand profile tables.
- Connect profile builders, portfolio/inventory/listing screens, and marketplace discovery.

**Exit:** verified users can publish moderated searchable listings; producers can filter and shortlist real records.

### Phase 5 — Projects, requirements, and project room

- Implement projects, team members, requirements, skills, saved searches, shortlists.
- Connect DP-01 through DP-09, project room members/files/activity.
- Add project authorization and dashboard aggregates.

**Exit:** producer can create a project, requirement, search, shortlist, and collaborate with a project team.

### Phase 6 — Booking, negotiation, calendars, and chat

- Implement booking/offer state machines and event history.
- Implement availability conflict protection.
- Implement conversations/messages/attachments/pinned decisions and realtime events.
- Connect all role request/inbox/detail/counter screens.

**Exit:** two real users complete offer/counter/accept flows with persisted chat and calendar locks.

### Phase 7 — Contracts and legal

- Implement templates/clauses/contracts/parties/signatures/addendums/legal review/billing.
- Render immutable PDF contract snapshots.
- Connect shared contract UI, DP/AT contracts, legal portal, and admin template screens.

**Exit:** accepted booking produces a versioned contract, authorized parties sign, and legal review/addendum paths work.

### Phase 8 — Payments and finance

- Implement schedules, milestones, proofs, transactions, receipts, ledger, fee rules, deposits, payouts.
- Connect user finance screens and complete admin payment/revenue/ledger screens.
- Add idempotency, webhook records, immutable accounting rules, and exports.

**Exit:** proof or provider event can be reviewed safely, booking becomes secured, receipt/ledger entries reconcile, and double processing is impossible.

### Phase 9 — Location, equipment, and safety workflows

- Implement pricing/rules/inspections/damage claims.
- Implement equipment packages/terms/handover/returns.
- Implement policies/claims/safety checks/incidents/check-ins.
- Add offline inspection draft sync.

**Exit:** location/equipment booking can pass through inspections and deposit release/claim with evidence; safety partner can manage cases.

### Phase 10 — Agency, brand, model, and distribution extensions

- Implement roster/audition/self-tape/notes/commission.
- Implement brand opportunities/applications/terms/deliverables/metrics.
- Complete model rights/rates/restrictions.
- Implement distribution contacts/releases/handovers/reports.

**Exit:** all specialist portals use real data and complete their principal workflows.

### Phase 11 — Reviews, moderation, disputes, support, communications

- Implement reviews/dimensions, user reports/blocks.
- Implement moderation queues, disputes/evidence/events, tickets/messages.
- Implement announcements and multi-channel notification delivery.
- Connect all related user and admin screens.

**Exit:** trust and safety operations are auditable end to end.

### Phase 12 — Analytics, exports, hardening, and production

- Add daily aggregates, caching, export jobs, monitoring, alerts, backups.
- Load/performance/security/accessibility tests.
- Data migration/seed strategy, staging UAT, production deployment, rollback rehearsal.
- Remove remaining production demo imports and stale controls.

**Exit:** release gates in Section 15 pass on staging and production smoke tests pass through HTTPS.

---

## 19. Seed-data scenario

Seed development and staging with one connected story, not unrelated rows:

- Sara Ahmed (`USR-0001`) is a verified producer and owns Sara Ahmed Productions.
- Ali Khan (`USR-0002`) is a verified actor with portfolio, rate card, calendar, and reviews.
- Maham (`USR-0003`) is a verified model with usage rights and brand restrictions.
- Aurora Biscuit TVC (`PRJ-1001`) has a lead-actor requirement.
- Ali is shortlisted and receives booking `BK-2048`.
- The negotiation reaches PKR 180,000.
- Contract `CTR-1001` is generated with a 40/40/20 schedule.
- Deposit milestone `PM-1001` receives proof `PP-1001`.
- Finance admin verifies the proof, receipt `RCPT-7821` is generated, and the booking becomes secured.
- The chat contains a pinned 7:30 AM call-time decision.
- Notifications exist for the offer, contract, and payment.
- Add related location, equipment, crew, agency, legal, insurance, brand, and distribution records from Section 7 so every portal has at least 3 list rows, one empty-filter result, one actionable item, and one completed historical item.

Seed credentials must be development-only, clearly documented, and impossible to activate in production. Seed files should use local fixtures or safe public placeholder media, never real KYC/payment documents.

---

## 20. Final completion checklist

- [ ] All tables in Section 7 exist through versioned Alembic migrations.
- [ ] Development seed includes at least one valid row in every table and coherent foreign keys.
- [ ] OpenAPI contains all endpoints in Section 8.
- [ ] All mutations have policy tests and audit requirements where applicable.
- [ ] All role dashboards are query-backed.
- [ ] Every existing Flutter screen is connected to an endpoint or intentionally local-only.
- [ ] All search/filter/sort/pagination controls work against real data.
- [ ] Every form persists, validates, and recovers from error.
- [ ] All files use signed upload/download and correct privacy class.
- [ ] Booking, contract, payment, dispute, and moderation state machines reject invalid transitions.
- [ ] Realtime reconnection and REST reconciliation work.
- [ ] Push/email delivery failures retry without duplicating domain actions.
- [ ] Flutter contains no production imports of demo-data stores.
- [ ] Loading, empty, error, permission, offline, and success states exist.
- [ ] Backend, Flutter, integration, and end-to-end tests pass.
- [ ] HTTPS, DNS, CORS, secrets, backups, monitoring, and rollback are verified.
- [ ] Production smoke test completes the core producer-to-talent booking journey.

---

## 21. Copy/paste prompt for the implementation AI

```text
You are implementing the CineConnect backend and Flutter integration.

First read the entire file:
docs/CINECONNECT_MASTER_BACKEND_REPORT.md

Then read:
- docs/DEPLOYMENT_INPUTS.md
- docs/IMPLEMENTATION_PROGRESS.md
- the current git diff
- all existing Flutter route, model, demo-data, and screen files involved in the next incomplete phase

Follow the report as the source of truth. Work only on the next incomplete vertical slice. Implement database migration, SQLAlchemy model, schema, service, policy, endpoint, backend tests, Flutter DTO/repository/state integration, screen connection, and Flutter tests. Preserve unrelated user changes. Do not leave fake-success buttons or in-memory production state.

Before stopping:
1. run relevant formatting, linting, migrations, backend tests, and Flutter tests;
2. compare the result with the report’s acceptance criteria;
3. update docs/IMPLEMENTATION_PROGRESS.md with completed work, files, migrations, endpoints, tests, decisions, blockers, and exact next task;
4. state clearly whether the slice is complete.

Do not proceed to the next phase if this phase’s exit criteria are not met.
```

This prompt should be reused at the start of every new AI session. The progress file records changing implementation state; this report remains the stable product and architecture contract unless the user explicitly approves a revision.

---

## 22. Exact existing Flutter route registry

This registry mirrors the route constants audited in the repository. The implementation AI must preserve these Flutter deep links while mapping entity placeholders such as `:id` to real identifiers. Shared route strings that also appear in the generic role-portal registry are listed once.

### Core

`/`, `/onboarding`, `/roles`, `/login`, `/signup`, `/forgot-password`, `/verification/upload`, `/verification/status`, `/profile/roles`, `/notifications`, `/booking/chat`, `/contract`, `/payments/proof`, `/payments/ledger`, `/review`, `/report`, `/settings`, `/utility/error`, `/utility/empty`, `/utility/no-internet`, `/utility/force-update`, `/utility/maintenance`, `/portal/dashboard`

### Director / Producer

`/director`, `/director/projects`, `/director/projects/create`, `/director/projects/:id`, `/director/projects/:id/requirements`, `/director/marketplace`, `/director/marketplace/filters`, `/director/profile/:id`, `/director/shortlist`, `/director/booking-request`, `/director/bargaining`, `/director/bargaining/:id`, `/director/contracts`, `/director/payments`, `/director/schedule`, `/director/accounts`, `/director/room`, `/director/reports`

### Actor / Talent

`/talent`, `/talent/profile`, `/talent/portfolio`, `/talent/availability`, `/talent/rates`, `/talent/opportunities`, `/talent/offers/:id`, `/talent/counteroffer`, `/talent/contracts`, `/talent/earnings`, `/talent/reputation`, `/talent/safety`

### Model extension

`/model`, `/model/usage-rights`, `/model/portfolio-categories`, `/model/rate-by-usage`, `/model/brand-safety`

### Location Owner

`/location-owner`, `/location-owner/listing-wizard`, `/location-owner/availability`, `/location-owner/pricing`, `/location-owner/rules`, `/location-owner/requests`, `/location-owner/check-in`, `/location-owner/check-out`, `/location-owner/earnings`, `/location-owner/performance`

### Media / Equipment Provider

`/equipment-provider`, `/equipment-provider/profile`, `/equipment-provider/inventory`, `/equipment-provider/packages`, `/equipment-provider/availability`, `/equipment-provider/terms`, `/equipment-provider/requests`, `/equipment-provider/handover`, `/equipment-provider/return`, `/equipment-provider/earnings`

### Crew / Services

`/crew`, `/crew/profile`, `/crew/portfolio`, `/crew/availability`, `/crew/requests`, `/crew/contracts-payments`, `/crew/ratings`

### Casting Agency

`/agency`, `/agency/roster`, `/agency/auditions`, `/agency/shortlist`, `/agency/self-tapes`, `/agency/selection-notes`, `/agency/commission`, `/agency/records`

### Brand / Sponsor

`/brand`, `/brand/profile`, `/brand/opportunity-composer`, `/brand/applications`, `/brand/negotiation`, `/brand/campaign-tracker`, `/brand/payments`

### Legal Partner

`/legal`, `/legal/contract-review`, `/legal/template-review`, `/legal/addendum-review`, `/legal/history-billing`

### Insurance / Safety Partner

`/insurance`, `/insurance/records`, `/insurance/claims`, `/insurance/safety-permits`, `/insurance/incidents`

### Distribution / Release Partner

`/distribution`, `/distribution/contacts`, `/distribution/release`, `/distribution/reports`

### Super Admin

`/admin/login-demo`, `/admin/dashboard`, `/admin/review-hub`, `/admin/review-hub/people`, `/admin/review-hub/listings`, `/admin/review-hub/content`, `/admin/verifications`, `/admin/verifications/:id`, `/admin/content-moderation`, `/admin/listings-moderation`, `/admin/bookings-monitor`, `/admin/bookings-monitor/:id`, `/admin/payments`, `/admin/payment-queue`, `/admin/payment-review/:id`, `/admin/payments/ledger`, `/admin/payments/revenue`, `/admin/contract-templates`, `/admin/contract-templates/:id`, `/admin/fees`, `/admin/disputes`, `/admin/disputes/:id`, `/admin/users`, `/admin/admin-roles`, `/admin/support`, `/admin/broadcasts`, `/admin/audit-logs`, `/admin/analytics`

### Route-specific implementation note

The current `MaterialApp.onGenerateRoute` compares literal strings, so routes containing `:id` do not yet parse real paths such as `/talent/offers/BK-2048`. Before backend connection, introduce a route parser or migrate to `go_router`. Preserve named-route compatibility where tests rely on it, and add tests for direct launch, browser refresh, authenticated redirect, role authorization, and the Android/iOS back stack.
