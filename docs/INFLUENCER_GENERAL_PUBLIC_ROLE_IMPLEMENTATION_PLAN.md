# CineConnect Influencer + General Public Role Implementation Plan

## Goal

Add two new product capabilities without breaking existing CineConnect portals:

1. **Influencer availability** for people who may already be actors or models.
2. **General Public buyer registration** so non-industry customers can register without KYC and book actors/models/influencers for marketing campaigns.

## Product decisions

### 1. General Public is a buyer role, not a provider role

- Role code: `general_public`
- Display name: `General Public`
- Portal purpose: browse public marketplace, book actors/models/influencers for campaigns, manage booking/payment/contract status.
- KYC: **not required at registration**.
- Reason: customers should be able to browse and submit campaign booking requests quickly. Payment verification and anti-abuse checks still apply at transaction level.

### 2. Influencer is both a role and an availability category

- Role code: `influencer`
- Display name: `Influencer`
- KYC: **required before public paid listing / accepting paid bookings**.
- Reason: influencers receive paid public work, so identity and safety verification should remain required.

### 3. Actor/model/influencer should be multi-availability, not mutually exclusive

A person can be:

- Actor only
- Model only
- Influencer only
- Actor + Model
- Actor + Influencer
- Model + Influencer
- Actor + Model + Influencer

Implementation should store this as availability flags/categories on the shared Talent Profile, not as separate duplicate people.

## Current system facts

### Existing backend roles

Roles are seeded in `backend/migrations/versions/5b0e3a1f7c2d_identity_access.py`.

Current roles include:

- `director_producer`
- `actor_talent`
- `model`
- `location_owner`
- `equipment_provider`
- `crew_service`
- `casting_agency`
- `brand_sponsor`
- `legal_partner`
- `insurance_partner`
- `distribution_partner`

All launch roles currently default to `requires_kyc=True`.

### Current marketplace limitation

`backend/app/api/marketplace.py` currently allows publishing only:

- `talent`
- `location`

Actor profile publishing currently publishes a `talent` listing and requires approved `actor_talent` KYC.

### Current Flutter limitation

Director Marketplace categories currently include:

- All
- Actors
- Models
- Crew
- Locations
- Media & Equipment
- Agencies

No `Influencers` category exists yet.

Signup currently routes every new user through OTP screen and then KYC upload. For General Public this must change.

## Backend implementation plan

### B1. Add roles migration

Create a new Alembic migration to insert:

| Code | Name | Portal route | Requires KYC | Display order |
|---|---|---|---:|---:|
| `influencer` | Influencer | `/influencer` or `/talent` initially | true | after Model |
| `general_public` | General Public | `/public` | false | near Director/Producer or after Brand |

Notes:

- `influencer` can initially reuse the Actor/Talent portal shell if we do not yet build a dedicated portal.
- `general_public` needs a lightweight buyer portal eventually, but can initially reuse a customer booking/discovery shell.

### B2. Add Talent Profile availability categories

Add a new field to the talent profile table, preferably JSON:

```json
{
  "actor": true,
  "model": true,
  "influencer": true
}
```

Recommended DB column:

- `availability_categories_json JSON NOT NULL DEFAULT []`

Recommended values:

- `actor`
- `model`
- `influencer`

Reason:

- One human profile can appear in multiple marketplace categories.
- Avoids duplicated actor/model/influencer records.
- Keeps portfolio, photos, credits, reviews, bookings, and KYC attached to one person.

### B3. Marketplace listing support

Allow talent-backed listings to publish under these listing types:

- `actor`
- `model`
- `influencer`
- existing `talent` can remain as backward-compatible alias

Publishing rules:

- If listing type is `actor`, require approved KYC for `actor_talent` or `influencer`/`model` if user has those roles.
- If listing type is `model`, require approved KYC for `model` or `actor_talent`.
- If listing type is `influencer`, require approved KYC for `influencer` or `actor_talent`/`model` if they selected influencer availability and have approved provider KYC.

Practical first version:

- Require approved KYC for any one of: `actor_talent`, `model`, `influencer`.
- This keeps implementation simple and safe.

### B4. Director discovery API

Update Director discovery/listing category filters:

- Add `Influencers`
- Map `Influencers` to listing type `influencer`
- Keep `Actors` → `actor` and/or `talent`
- Keep `Models` → `model`

### B5. General Public buyer APIs

Minimum first version can reuse existing marketplace and booking endpoints:

- Browse marketplace listings.
- View actor/model/influencer profiles.
- Submit booking request for marketing campaign.

Booking request payload should support campaign context:

- campaign title
- brand/product name
- campaign objective
- deliverables
- usage channels
- campaign dates
- city/remote
- budget range
- notes

KYC should not block General Public from submitting a request, but transaction/payment proof flow can still verify payment.

### B6. Backend validation changes

Where the backend currently requires Director/Producer role for booking requests, allow `general_public` for public campaign booking routes.

Security:

- General Public cannot access Director project management APIs.
- General Public cannot create production projects unless intentionally enabled later.
- General Public cannot publish marketplace listings unless they also hold a provider role.

## Flutter implementation plan

### F1. Role selection / signup

Add cards:

- `Influencer`
- `General Public`

Signup behavior:

- Influencer: continue to verification/KYC.
- General Public: skip KYC after OTP/signup and route to General Public portal/home.

Important:

- The OTP is currently placeholder-style in the frontend unless real SMS provider is configured. Do not present it as production SMS until OTP backend/provider is fully enabled.

### F2. Role mapper

Update `lib/core/auth/role_mapper.dart`:

- `Influencer` → `influencer`
- `General Public` → `general_public`
- `influencer` portal route initially can point to Actor/Talent or a new Influencer route.
- `general_public` portal route should point to a new public buyer portal.

### F3. Actor/Talent profile availability controls

In Actor/Talent profile builder, add visible toggles:

- Available as Actor
- Available as Model
- Available as Influencer

Rules:

- At least one must be selected before publishing.
- Profile text and listing publish button should explain where they will appear.

### F4. Model portal profile controls

In Model profile screen, add same availability toggles:

- Model
- Actor
- Influencer

Reason:

- A model should not need a duplicate profile to receive influencer campaign requests.

### F5. Publish marketplace listings

Add publish controls that can publish one listing per selected category:

- Actor listing
- Model listing
- Influencer listing

Clean first version:

- Keep one shared talent profile.
- Create/update separate marketplace listing rows by listing type.
- Titles can be category-specific:
  - `Ayaan Malik — Actor`
  - `Ayaan Malik — Model`
  - `Ayaan Malik — Influencer`

### F6. Director Marketplace UI

Add `Influencers` filter chip to:

- Director Marketplace
- Smart filters
- Search/saved search listing types
- Candidate card category mapping

### F7. General Public portal

Minimum buyer portal screens:

1. Home / Campaign Booking
2. Browse Actors
3. Browse Models
4. Browse Influencers
5. Profile Detail
6. Campaign Booking Request
7. My Requests
8. Payments / Proofs
9. Contracts / Agreements
10. Account

First implementation can reuse existing Director marketplace/profile/booking components with a simplified shell and without production project management.

### F8. Copy changes

Avoid film-industry-only language in General Public portal:

- Use “campaign,” “marketing,” “brand/product,” “deliverables,” “usage channels.”
- Avoid “project room,” “shoot production,” “director console” unless needed.

## Demo data plan

Add at least:

- 10 influencer-capable profiles
- 5 actor + influencer profiles
- 5 model + influencer profiles
- 1 General Public demo customer account
- 10 campaign booking requests across actors/models/influencers

General Public demo account should not have KYC submissions.

## Deployment plan

1. Backend migration locally.
2. Backend API changes.
3. Flutter auth/role/profile/marketplace changes.
4. Local tests:
   - backend tests
   - `flutter analyze`
   - widget tests
   - web build
5. Deploy backend to server.
6. Run migrations on server.
7. Deploy frontend web bundle.
8. Verify live:
   - `/auth/roles` or `/me/roles`
   - register General Public
   - no KYC redirect
   - browse Influencers
   - actor/model can publish influencer listing after KYC
   - General Public can create campaign booking request

## Recommended implementation phases

### Phase 1 — Safe foundation

- Add backend roles.
- Add Flutter role mapper/cards.
- Make General Public signup skip KYC.
- Add Influencers chip to marketplace UI.

### Phase 2 — Multi-availability profile

- Add talent availability categories field.
- Add Actor/Model profile toggles.
- Persist and load selected availability.

### Phase 3 — Influencer marketplace publishing

- Allow `influencer` listings.
- Publish/update separate listing rows per category.
- Update Director discovery mappings.

### Phase 4 — General Public booking flow

- Create or reuse buyer portal shell.
- Add campaign booking request UI.
- Allow `general_public` booking request permissions.

### Phase 5 — Demo data and walkthrough

- Seed influencer profiles and General Public customer.
- Run live end-to-end walkthrough.

## Open business decisions

These can be assumed for now but should be confirmed before production launch:

1. Should General Public require email verification before booking?
   - Recommended: yes.
2. Should General Public pay a deposit before actor/influencer sees request?
   - Recommended: optional for demo, required later for spam control.
3. Should influencers have follower/platform metrics?
   - Recommended: yes; add Instagram, TikTok, YouTube, Facebook, Snapchat fields later.
4. Should influencer booking require campaign content approval?
   - Recommended: yes; include deliverables and brand-safety approval.
5. Should General Public see all actors/models or only those who opted into public marketing campaigns?
   - Recommended: only profiles with `influencer` or `public_campaigns` availability enabled.

