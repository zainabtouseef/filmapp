# CineConnect Director Portal Database-Only Perfection Plan

Generated: 2026-07-22  
Scope: Director/Producer portal first, before touching other portals  
Target live app/API: `https://cine.nalexustechnologies.com` / `https://cine.nalexustechnologies.com/api/v1`  
Primary rule from owner: no Director portal screen should show local demo data; all demo-looking data must come from the live MySQL database through backend APIs.

---

## 1. Goal

Make the Director/Producer portal look and behave like a polished production product while ensuring every visible project, candidate, booking, payment, contract, schedule item, room update, report, and image is fetched from the backend/database.

This plan is intentionally written before implementation so later passes can work step by step, re-open this document, complete one milestone, verify it, update progress, then move to the next milestone.

---

## 2. Non-negotiable rules

1. **No local Director demo data in the live Director portal.**
   - Remove or stop using `DirectorProducerDemoData` from every Director/Producer screen and dashboard widget.
   - Error/offline states may show empty-state copy and retry buttons, but not fake populated records.

2. **All visible seeded demo data must be database-backed.**
   - Seed scripts may create synthetic demo users/records, but the Flutter app must load them via API.
   - If a screen has no backend endpoint, add the backend endpoint first or show a real empty/backend-gap state.

3. **Images must be backend file records, not hardcoded Flutter assets or direct random internet URLs.**
   - Download/prepare licensed images during seed/import.
   - Store/copy them under production public media storage.
   - Create `FileAsset` rows with `visibility='public'`, `bucket='public'` or configured public bucket, `scan_status='clean'`, `processing_status='ready'`.
   - API responses must expose a `public_url`.
   - Flutter renders `public_url` with safe placeholders while loading.

4. **Pakistan relevance must be real but not misleading.**
   - Use Pakistan-relevant cities, landmarks, studio/location imagery, equipment/stage imagery, and culturally realistic production names.
   - Do not create fake app accounts impersonating real Pakistani actors, directors, brands, or celebrities unless there is explicit permission.
   - If using licensed public portrait photos, treat them as generic demo portraits with synthetic names and attribution metadata; do not imply the depicted person is the named CineConnect user.

5. **Every backend change must be deployed to the server before the Flutter live app depends on it.**
   - Backend deploy target remains the existing production server/domain.
   - CORS must continue to allow `https://cine.nalexustechnologies.com`.

---

## 3. Current findings from code inspection

### 3.1 Director files still using local demo data

These files currently import or reference `DirectorProducerDemoData` and must be refactored:

| Area | Files |
|---|---|
| Dashboard widgets | `dp_command_header.dart`, `dp_pulse_strip.dart`, `dp_today_timeline.dart`, `dp_project_deck.dart`, `dp_financial_centre.dart`, `dp_deal_pipeline.dart`, `dp_dashboard_insights.dart`, `dp_activity_feed.dart`, `dp_discovery_snapshot.dart` |
| Director screens | `dp_projects_list_screen.dart`, `dp_marketplace_discovery_screen.dart`, `dp_shortlist_board_screen.dart`, `dp_booking_request_form_screen.dart`, `dp_bargaining_center_screen.dart`, `dp_negotiation_thread_screen.dart`, `dp_contract_center_screen.dart`, `dp_payment_center_screen.dart`, `dp_project_room_screen.dart`, `dp_requirement_builder_screen.dart`, `dp_project_accounts_screen.dart`, `dp_reports_export_screen.dart`, `dp_stakeholder_profile_screen.dart` |
| Shared Director console widgets | `dp_project_console_widgets.dart` |
| Local source to retire from Director runtime | `director_producer_demo_data.dart` |

### 3.2 Backend already exists for many flows

Already present and usable:

- Projects list/detail/create/update
- Project requirements list/create
- Project room items/files
- Talent marketplace listings
- Saved searches and shortlists
- Booking/negotiation/chat APIs
- Contracts/legal APIs
- Payments dashboard/proof/ledger APIs
- `/me/dashboard` personal metrics
- Admin/export APIs
- File upload/storage foundation

### 3.3 Backend gaps for a perfect Director portal

Required improvements:

1. A Director dashboard aggregate endpoint is missing.
2. Project cover/media fields are missing.
3. API file payloads do not expose public media URLs consistently.
4. Marketplace creation is still talent-only, while Director discovery UI needs talent, locations, equipment, crew, and possibly agencies.
5. Location/equipment/crew discovery cards need a unified backend feed or expanded marketplace listing support.
6. Project account/budget snapshot endpoint is missing.
7. Calendar/schedule screen needs a Director-owned schedule endpoint derived from bookings and availability.
8. Stakeholder profile screen needs one backend detail payload per listing type, not local detail copy.

---

## 4. Proposed target data contract

### 4.1 New endpoint: `GET /api/v1/director/dashboard`

Purpose: one fast payload for the Director home dashboard.

Response shape:

```json
{
  "data": {
    "summary": {
      "active_projects": 4,
      "secured_bookings": 8,
      "paid_minor": 420000000,
      "pending_minor": 180000000,
      "currency": "PKR",
      "attention_count": 5
    },
    "priority_items": [
      {
        "type": "payment_rejected",
        "title": "Payment proof needs replacement",
        "subtitle": "River Lights · Ayaan Malik",
        "urgency": "Today",
        "route": "/director/payments",
        "entity_id": "PAY-..."
      }
    ],
    "today": [
      {
        "public_id": "SCH-...",
        "time": "10:00",
        "project": "River Lights",
        "location": "Lahore Fort exterior reference",
        "stakeholders": ["Ayaan Malik", "Camera Crew"],
        "status": "Confirmed",
        "conflict": false
      }
    ],
    "projects": [],
    "financial": {
      "total_minor": 600000000,
      "paid_minor": 420000000,
      "under_review_minor": 100000000,
      "due_minor": 80000000,
      "attention": []
    },
    "pipeline": {
      "negotiating": {"count": 3, "total_minor": 90000000},
      "accepted": {"count": 2, "total_minor": 70000000},
      "contract_sent": {"count": 2, "total_minor": 120000000},
      "signed": {"count": 5, "total_minor": 310000000}
    },
    "discovery": {
      "featured": []
    },
    "activity": []
  }
}
```

Notes:

- This endpoint should only return records visible to the current Director/Producer.
- It should be computed from real tables: projects, project members, requirements, bookings, offers, contracts, payment schedules/proofs/ledger, project room items, marketplace listings, and notifications.
- Keep it read-only.

### 4.2 New endpoint: `GET /api/v1/director/schedule`

Purpose: replace schedule local rows.

Source data:

- Accepted/secured bookings for projects where the current user is requester/member.
- Provider availability entries locked by those bookings.
- Project start/end dates for high-level project milestones.
- Optional room milestone items.

### 4.3 New endpoint: `GET /api/v1/director/accounts`

Purpose: replace `dp_project_accounts_screen.dart`.

Source data:

- Project estimated budget.
- Booking agreed amounts.
- Payment schedules/milestones/proofs.
- Ledger entries/receipts.
- Fee snapshots.

### 4.4 New endpoint or expansion: `GET /api/v1/director/discovery`

Purpose: one search feed for the Director marketplace UI.

Options:

| Option | Recommendation | Reason |
|---|---|---|
| Expand `MarketplaceListing` to support `talent`, `crew`, `location`, `equipment`, `agency` | Recommended long-term | Clean product model; shortlist/search works across provider types |
| Create Director-only discovery endpoint joining existing provider tables | Fastest safe implementation | Avoids broad migration if only Director needs unified discovery now |

Recommended first implementation: Director-only discovery endpoint now, broader marketplace generalization later.

The endpoint should return cards shaped for Flutter:

```json
{
  "public_id": "DISC-...",
  "entity_type": "talent",
  "entity_id": "LST-...",
  "title": "Ayaan Malik",
  "subtitle": "Lead actor · Lahore",
  "city": "Lahore",
  "rate_label": "PKR 160k/day",
  "rating": 4.8,
  "verified": true,
  "available": true,
  "skills": ["Urdu", "Drama", "Commercial"],
  "summary": "Screen actor with TV drama and brand campaign experience.",
  "cover_image_url": "https://cine.nalexustechnologies.com/media/demo/director/talent-001.webp",
  "portfolio": []
}
```

### 4.5 File/media payload improvement

Backend `_file_payload()` should include:

```json
{
  "public_id": "FILE-...",
  "mime_type": "image/webp",
  "size_bytes": 123456,
  "visibility": "public",
  "scan_status": "clean",
  "processing_status": "ready",
  "original_name": "lahore-fort-exterior.webp",
  "public_url": "https://cine.nalexustechnologies.com/media/demo/director/lahore-fort-exterior.webp",
  "download_url": "/api/v1/files/FILE-.../download"
}
```

Rules:

- `public_url` only appears when `visibility='public'`.
- Private files keep only authenticated `download_url`.
- Flutter should use `public_url` for images and never build media URLs manually.

### 4.6 Project cover image support

Add one of:

| Approach | Recommendation |
|---|---|
| Add `cover_file_id` to `projects` | Best for project cards/dashboard |
| Use `ProjectFile(folder='cover')` | Lower migration, but less direct |

Recommended: add `cover_file_id` to `projects`, nullable foreign key to `files.id`.

Update:

- Migration
- `Project` model
- `_project_payload()`
- project create/update payload validation
- seed scripts
- Flutter `Project`/`DpProject` model with `coverImageUrl`
- `DPProjectCard` to render cover image

---

## 5. Flutter target architecture

### 5.1 New Director data layer

Create:

- `lib/core/director/director_models.dart`
- `lib/core/director/director_repository.dart`
- `lib/core/director/director_controller.dart`
- `DirectorScope` mounted inside `DirectorProducerPortalScreen`, alongside `ProjectsScope`

Controller methods:

- `dashboard({force=false})`
- `schedule({force=false})`
- `accounts({force=false})`
- `discovery({type, query, cityId, projectId, requirementId})`
- `stakeholderDetail(entityType, entityId)`

### 5.2 Refactor dashboard widgets to accept data

Current dashboard widgets read `DirectorProducerDemoData` directly. Target pattern:

```dart
class DPPulseStrip extends StatelessWidget {
  final DirectorDashboardSummary summary;
  const DPPulseStrip({super.key, required this.summary});
}
```

Do this for:

- `DPCommandHeader`
- `DPPulseStrip`
- `DPTodayTimeline`
- `DPProjectDeck`
- `DPFinancialCentre`
- `DPDealPipeline`
- `DPPriorityActions`
- `DPActivityFeed`
- `DPDiscoverySnapshot`

`DPHomeDashboardScreen` becomes the only dashboard screen that loads the future and distributes the payload.

### 5.3 Replace fallback-demo behavior with real loading states

Allowed states:

- Skeleton/loading cards
- Empty states, e.g. “No projects yet — create your first production”
- Error states with retry
- Auth-required state

Not allowed in Director portal:

- Populated local fake cards when API fails
- Reading `DirectorProducerDemoData.*`
- “Demo fallback” warnings that still show data

### 5.4 Add image fields to Flutter models

Update:

- `DpCandidate`: add `String? imageUrl`, `String? coverImageUrl`
- `DpProject`: add `String? coverImageUrl`
- `MarketplaceListing`: parse `media`, `coverImageUrl`, `owner` profile image if available
- `Project`: parse `cover_file.public_url`
- shared `UploadedFile`: add `publicUrl` and possibly width/height later

UI components:

- `DPCandidateCard`: show image if present, initials fallback only if no image.
- `DPProjectCard`: show project cover image/gradient overlay.
- `DPStakeholderProfileScreen`: show hero image, portfolio grid, attribution label if required.
- `DPDiscoverySnapshot`: render a horizontal rail of real featured discovery records with images.

---

## 6. Director screen-by-screen implementation plan

| Step | Screen/widget | Current issue | Required change | Backend required? |
|---:|---|---|---|---|
| 1 | `DPHomeDashboardScreen` | Child widgets read local data | Load `DirectorDashboard` from API and pass data down | Yes, `/director/dashboard` |
| 2 | `DPCommandHeader` | Active projects/budget local | Use dashboard summary and authenticated user display name | Yes |
| 3 | `DPPulseStrip` | Projects/bookings/payments local | Use dashboard summary | Yes |
| 4 | `DPTodayTimeline` | Schedule local | Use dashboard `today` or `/director/schedule` | Yes |
| 5 | `DPProjectDeck` | Projects local | Use dashboard projects or `ProjectsScope.projects` | Maybe cover image |
| 6 | `DPFinancialCentre` | Payments local | Use dashboard financial payload or `PaymentsScope.dashboard` | Yes |
| 7 | `DPDealPipeline` | Negotiations/contracts local | Use dashboard pipeline | Yes |
| 8 | `DPPriorityActions` / `dpPriorityItems()` | Priority computed from local payments/contracts/negotiations | Priority should come from backend | Yes |
| 9 | `DPActivityFeed` | Project room items local | Use dashboard activity or selected room endpoint | Yes |
| 10 | `DPDiscoverySnapshot` | Candidate cards local | Use `/director/discovery?featured=true` | Yes |
| 11 | `DPProjectsListScreen` | Has demo fallback | Remove fallback; show real list/empty/error | No, but cover image optional |
| 12 | `DPMarketplaceDiscoveryScreen` | Has fallback candidates and local project/requirement filters | Use live discovery feed plus live projects/requirements | Yes for non-talent types |
| 13 | `DPStakeholderProfileScreen` | Entire detail page local | Use discovery detail endpoint | Yes |
| 14 | `DPShortlistBoardScreen` | Has fallback board/cards | Use backend saved searches/shortlists only | Existing mostly |
| 15 | `DPBookingRequestFormScreen` | Candidate/project/requirement defaults local | Require live candidate/project/requirement IDs; load live picker data | Discovery endpoint |
| 16 | `DPBargainingCenterScreen` | Local negotiations fallback | Use `BookingsScope.negotiations`; remove fallback | Existing |
| 17 | `DPNegotiationThreadScreen` | Local negotiation detail fallback | Use live negotiation detail only | Existing |
| 18 | `DPContractCenterScreen` | Local contracts fallback | Use `ContractsScope` only | Existing |
| 19 | `DPPaymentCenterScreen` | Injects local payments | Use `PaymentsScope.dashboard` only | Existing |
| 20 | `DPProjectRoomScreen` | Local room items fallback | Use `ProjectsScope.room` only | Existing |
| 21 | `DPRequirementBuilderScreen` | Local requirements for a project | Use `ProjectsScope.requirements` only | Existing |
| 22 | `DPProjectAccountsScreen` | Local project accounts | Use `/director/accounts` | Yes |
| 23 | `DPReportsExportScreen` | Local reports | Use export jobs/list supported export types only | Maybe improve list endpoint |
| 24 | `dp_project_console_widgets.dart` | Heavy local console helpers | Either refactor to receive live props or remove unused local console sections | Yes/No depending usage |

---

## 7. Demo data and image asset plan

### 7.1 Seed package name

Create a new idempotent seed slice:

- `backend/scripts/seed_director_portal_perfect_data.py`
- Seed batch: `cineconnect-director-perfect-2026-07-22`

This slice should not replace the old global demo seed immediately. It should enhance and correct the Director-visible part first.

### 7.2 Required Director-visible data counts

| Data type | Target count | Notes |
|---|---:|---|
| Director users | 10 | Existing demo users may be reused |
| Projects | 10 | Pakistan city-linked; each has cover image |
| Requirements | 30 | 3 per project across talent, crew, location/equipment |
| Project room items | 40 | Decisions, files, milestones, production notes |
| Project files | 20 | Scripts, briefs, moodboards, call sheets |
| Discovery cards | 40 | 10 talent, 10 crew, 10 location, 10 equipment |
| Talent/crew portfolio media | 30 | Public URLs where safe |
| Location/equipment images | 40 | Public URLs |
| Saved searches | 10 | One per Director user |
| Shortlists | 10 | Linked to projects/requirements |
| Shortlist items | 30 | Ranked and noted |
| Bookings | 15 | Mix sent/negotiating/accepted/secured/completed |
| Negotiation rounds | 45 | Three rounds each |
| Contracts | 12 | Mixed generated/signed/legal-review |
| Payment schedules | 12 | Mix due/proof uploaded/verified/rejected |
| Calendar rows | 20 | Derived from bookings/project milestones |
| Reports/export jobs | 6 | Only supported export types |

### 7.3 Pakistan-relevant image categories

Use licensed/downloaded images for:

| Category | Examples to source | How used |
|---|---|---|
| Lahore project covers | Lahore Fort, Badshahi Mosque area, Walled City street texture, film/stage neutral photos | Project cards, moodboards |
| Karachi project covers | skyline/port/street/studio-style images | Project cards |
| Islamabad project covers | Faisal Mosque/Margalla Hills/corporate commercial style images | Project cards |
| Bahawalpur/Gwadar/Rawalpindi | desert fort/coastal/street imagery | Project cards |
| Talent/crew portraits | Licensed generic portraits; no celebrity impersonation | Candidate cards/profile hero |
| Locations | Rooftop, haveli, studio kitchen, street, farmhouse, coastal warehouse | Discovery cards |
| Equipment | Camera, lighting, audio, drone/gimbal kit images | Discovery cards |

### 7.4 Recommended image sources and constraints

Use sources in this priority:

1. Wikimedia Commons images with compatible licenses and attribution recorded.
2. Unsplash/Pexels-style permissive stock only after verifying terms.
3. AI-generated or locally created neutral placeholder images only if internet assets are insufficient.

Do not use:

- Random Google Images.
- Images behind paywalls or unclear licenses.
- Real celebrity portraits as fake CineConnect profiles.
- Real brand logos for fake campaigns unless the brand is actually authorized.

### 7.5 Image metadata to store

For each imported public image, store attribution in `FileAsset` extension metadata. If the current schema has no metadata column on `files`, add a small table:

`file_attributions`

| Column | Purpose |
|---|---|
| `file_id` | FK to files |
| `source_url` | Original image/page URL |
| `author` | Photographer/creator |
| `license` | License name |
| `license_url` | License URL |
| `attribution_text` | Text for docs/admin |
| `imported_at` | Audit timestamp |

If we want to avoid a migration for now, attribution can be written to a tracked seed manifest:

- `docs/DIRECTOR_PORTAL_IMAGE_ASSET_MANIFEST.md`
- `backend/scripts/assets/director_seed_manifest.json`

Migration is cleaner for long-term production.

---

## 8. Backend implementation milestones

### B1 — Public media URLs

- Update backend `local_storage.public_url_for()` usage in API payloads.
- Update `_file_payload()` in marketplace/projects/verification-compatible modules to include `public_url`.
- Confirm `/media/` Nginx alias serves public files.
- Add tests for public/private URL behavior.

Verification:

- `GET /api/v1/marketplace/listings` returns `media[0].file.public_url` for public listing images.
- Private files do not expose `public_url`.

### B2 — Project cover image support

- Add migration `project.cover_file_id`.
- Update `Project` model and API payload.
- Allow create/update with `cover_file_id` owned/ready/public or clean/ready file.
- Seed project covers.

Verification:

- `GET /api/v1/projects` returns `cover_file.public_url`.
- Flutter project cards can show images without hardcoded paths.

### B3 — Director dashboard endpoint

- Add `backend/app/api/director.py`.
- Register blueprint under `/api/v1`.
- Implement `GET /director/dashboard`.
- Compute summary, priorities, today schedule, project previews, financial status, pipeline totals, featured discovery, and activity.
- Add backend integration tests using seeded/fixture records.

Verification:

- Demo Director login returns non-empty real dashboard payload.
- Counts match existing project/booking/payment records.

### B4 — Director discovery endpoint

- Implement `GET /director/discovery`.
- Include talent marketplace listings first.
- Then add location/equipment/crew rows from existing specialist/operations tables.
- Return a unified card DTO.

Verification:

- `type=talent`, `type=location`, `type=equipment`, `type=crew` all return database records.

### B5 — Director stakeholder detail endpoint

- Implement `GET /director/discovery/<entity_type>/<entity_id>`.
- Return hero image, gallery, ratings, availability, skills, rates, verification state, and safe contact policy state.

Verification:

- Stakeholder profile screen has no need for local `DirectorProducerDemoData.candidates`.

### B6 — Director accounts endpoint

- Implement `GET /director/accounts`.
- Return per-project budget, committed booking cost, paid/verified milestones, pending proofs, rejected proofs, outstanding amount.

Verification:

- Project accounts screen loads only DB values.

### B7 — Director schedule endpoint

- Implement `GET /director/schedule`.
- Return project milestones and accepted/secured booking date ranges.

Verification:

- Schedule screen loads with DB-derived items only.

### B8 — Seed/import images and Director perfect data

- Add `backend/scripts/seed_director_portal_perfect_data.py`.
- Add image downloader/importer with source manifest.
- Store real files under public storage and create `FileAsset` rows.
- Link files to projects/listings/provider records.
- Run locally, then production.

Verification:

- Public media URLs open in browser.
- API payloads include those URLs.
- Director portal renders them live.

---

## 9. Flutter implementation milestones

### F1 — Add Director core API layer

- Add `lib/core/director/`.
- Add models for dashboard, discovery, account, schedule, and stakeholder detail.
- Add repository/controller/scope.
- Mount `DirectorScope` in `DirectorProducerPortalScreen`.

### F2 — Refactor Director dashboard

- `DPHomeDashboardScreen` loads `DirectorController.dashboard()`.
- All dashboard child widgets receive data through constructors.
- Remove `DirectorProducerDemoData` imports from all dashboard widgets.

### F3 — Refactor projects and project cards

- Parse `cover_file.public_url`.
- Render images in `DPProjectCard`.
- Remove local fallback in `DPProjectsListScreen`.

### F4 — Refactor discovery and candidate cards

- Replace local candidates with `DirectorDiscoveryItem`.
- `DPCandidateCard` displays `imageUrl`.
- Discovery filters call API.
- Empty/error states are real, not demo populated.

### F5 — Refactor stakeholder profile

- Load detail from backend by `entity_type/entity_id`.
- Render gallery from public media URLs.
- Remove all local fake profile sections.

### F6 — Refactor booking request flow

- Require live selected project + requirement + discovery entity/listing.
- If missing, show selector that loads from APIs.
- Submit through existing booking endpoint.

### F7 — Refactor bargaining/negotiation/contracts/payments/room/reports

- Remove local fallback imports.
- Use existing scopes/endpoints.
- Where endpoint data is missing, show real empty/backend-gap state and add backend work item.

### F8 — Run verification

- `flutter analyze`
- `flutter test`
- `flutter build web --dart-define=CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1`
- Headless Chrome route walkthrough for Director routes only
- Live browser check at `https://cine.nalexustechnologies.com`

---

## 10. UX quality requirements for the polished Director portal

Use the existing cinematic/gold-dark visual direction, but enforce:

- Image cards reserve aspect ratio before network image loads.
- Skeletons instead of blank spinners for dashboard cards.
- All tap targets at least 44px high/wide.
- Image loading fallback uses initials/gradient, not fake replacement content.
- Error cards explain the problem and offer retry.
- Empty states guide action: create project, discover talent, upload brief, send booking request.
- No emoji as structural icons.
- Consistent card radius, spacing, and status colors across Director screens.
- Candidate/profile images have accessible labels.
- Deep links keep working for `/director/...` routes.

---

## 11. Deployment and verification checklist

For every backend milestone:

1. Run backend lint/format/tests locally.
2. Run migration locally.
3. Build Docker image.
4. Deploy backend to server.
5. Run production smoke test with a demo Director account.
6. Update `docs/IMPLEMENTATION_PROGRESS.md`.

For every Flutter milestone:

1. Run `flutter analyze`.
2. Run `flutter test`.
3. Build web with production API define.
4. Deploy Flutter web if code changed.
5. Verify live domain renders the changed screen.
6. Update screenshot/evidence if relevant.

---

## 12. Exact recommended implementation order

Do not start by deleting `director_producer_demo_data.dart`. First provide live replacements.

1. **B1 Public media URLs**
2. **B2 Project cover image support**
3. **B3 Director dashboard endpoint**
4. **F1 Director core API layer**
5. **F2 Dashboard refactor**
6. **B4 Director discovery endpoint**
7. **B5 Stakeholder detail endpoint**
8. **F4/F5 Discovery and stakeholder refactor**
9. **B6/B7 Accounts and schedule endpoints**
10. **F3/F6/F7 Remaining screen refactors**
11. **B8 Director perfect seed with public images**
12. **Production seed/deploy**
13. **Director-only live walkthrough**
14. **Only then remove or quarantine Director local demo data**

---

## 13. Completion definition

Director portal is considered “perfect first pass” only when:

- `rg "DirectorProducerDemoData|director_producer_demo_data" lib/features/director_producer` returns no runtime screen/widget imports.
- Every Director route loads without local fake populated rows.
- Every visible card/data row is traceable to an API response and MySQL record.
- Project/candidate/location/equipment images render from `https://cine.nalexustechnologies.com/media/...`.
- Demo data is Pakistan-relevant, coherent across projects/bookings/contracts/payments, and legally safe.
- Live CORS and same-domain deployment still pass.
- `flutter analyze`, `flutter test`, backend tests, web build, and live Director route walkthrough pass.

---

## 14. Implementation log

### 2026-07-22 — B1/B2 implementation deployed

Status: implemented, locally verified, and deployed to `https://cine.nalexustechnologies.com`.

Completed:

- Backend `public_url` payload support for clean/ready public file assets.
- `project_cover` upload purpose with public bucket/visibility and image-only validation.
- `projects.cover_file_id` migration and API create/update/detail serialization.
- Flutter parsing for uploaded file `visibility`/`public_url`.
- Flutter marketplace media parsing and image propagation into Director candidate cards.
- Flutter project cover image parsing and rendering in Director project cards.
- Director mobile overflow fixes discovered while validating this slice.

Verification:

- `.venv/bin/ruff check ...` passed for touched backend/API/test/migration files.
- Backend unit tests passed: 15 tests.
- OpenAPI YAML parsed successfully: 183 paths.
- `flutter analyze` passed.
- Director portal route regression passed.
- Full `flutter test` passed.
- Production migration current head is `b8c9d0e1f2a3`.
- Production API health, OpenAPI, CORS preflight, app root, and public listing endpoint smoke checks passed.
- Production Flutter web bundle was rebuilt with `CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` and synced live.

Still pending before this milestone can create visible image-rich Director screens:

- Seed/import Pakistan-relevant public media files into production storage/database.
- Attach those file records to projects/listings.
- Run live Director route walkthrough after the image seed exists.

### 2026-07-22 — B8 partial public image seed deployed

Status: first public-image pass deployed for the 10 seeded Director backbone projects and 10 actor/talent listings.

Completed:

- Added `backend/scripts/seed_director_public_media.py`.
- Added `docs/DIRECTOR_PUBLIC_MEDIA_SOURCES.md`.
- Downloaded Pakistan-relevant Wikimedia-hosted images for Lahore, Karachi, Islamabad, Gwadar, Rawalpindi, Bahawalpur, and Hunza demo contexts.
- Synced image bytes to production public storage under `/var/www/cineconnect/storage/public/demo/cineconnect-director-public-media-2026-07-22`.
- Created 20 clean/ready public `FileAsset` rows.
- Attached 10 project cover files.
- Added 10 public listing cover media rows.

Verification:

- Live listing detail `DEMO-LST-AT-001` exposes a `public_url`.
- Live DP project list for `dp01@demo.cine.nalexustechnologies.com` exposes `DEMO-PROJ-001.cover_file.public_url`.
- Direct `/media/.../lahore-fort-river-lights.jpg` returns HTTP 200 `image/jpeg`.

Still pending:

- Add Director dashboard aggregate endpoint.
- Refactor remaining Director screens away from `DirectorProducerDemoData`.
- Run a live browser walkthrough once the dashboard/list/detail screens are fully DB-backed.

### 2026-07-22 — B3 dashboard aggregate endpoint deployed

Status: backend/API deployed; Flutter consumption still pending.

Completed:

- Added `GET /api/v1/director/dashboard`.
- Dashboard payload includes:
  - summary metrics
  - project previews with public cover images
  - upcoming booking timeline rows
  - payment attention rows
  - contract/booking pipeline rows
  - project-room activity rows
  - priority action rows
- Added OpenAPI `Director` tag, path, and `DirectorDashboardEnvelope`.
- Deployed backend and restarted production containers.

Verification:

- Local backend compile/Ruff/unit tests pass.
- Live smoke with the first demo DP account returns dashboard data and image-backed project previews.

Still pending:

- Add Flutter Director dashboard models/repository/controller.
- Refactor `DPHomeDashboardScreen` and dashboard widgets to consume this endpoint.
- Remove dashboard widget imports of `DirectorProducerDemoData`.

### 2026-07-22 — F2 Director dashboard wired to live backend and deployed

Status: completed for the Director home dashboard slice.

Completed:

- Added `lib/core/director/director_dashboard_models.dart`.
- Added `lib/core/director/director_repository.dart`.
- Exposed `AuthController.directorDashboard()`.
- Converted `DPHomeDashboardScreen` to load `GET /api/v1/director/dashboard` from the authenticated live API session.
- Refactored dashboard widgets to receive live data through constructors:
  - `DPCommandHeader`
  - `DPPulseStrip`
  - `DPTodayTimeline`
  - `DPProjectDeck`
  - `DPFinancialCentre`
  - `DPDealPipeline`
  - `DPPriorityActions`
  - `DPActivityFeed`
  - `DPDiscoverySnapshot`
- Deleted the local dashboard priority helper `dp_dashboard_insights.dart`.
- Removed `DirectorProducerDemoData` usage from the Director dashboard screen/widget layer.
- Built and deployed the Flutter web release to `https://cine.nalexustechnologies.com` using `CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1`.

Verification:

- `flutter analyze` passes.
- `flutter test test/director_producer_portal_test.dart --reporter compact` passes.
- `flutter test --reporter compact` passes.
- Flutter web production build passes and was deployed.
- Live web root returns HTTP 200.
- Production web build passes and was deployed to `https://cine.nalexustechnologies.com`.
- Live smoke after deploy:
  - web root returns HTTP 200
  - `/api/v1/health/live` returns `status=ok`
- `flutter build web --release --dart-define=CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1` passes.
- Live domain root returns HTTP 200 with the new deployed build timestamp.
- Live demo Director account can authenticate and fetch `/api/v1/director/dashboard`.
- Live dashboard payload currently returns:
  - 3 active projects
  - 3 project previews
  - 3 timeline rows
  - 2 payment attention rows
  - 4 pipeline rows
  - 3 priority actions

Still pending:

- Refactor `DPProjectsListScreen` away from local fallback data.
- Refactor Director marketplace discovery to remove fallback candidates and use a DB-backed discovery feed for talent, crew, locations, and equipment.
- Add/refactor stakeholder profile detail, booking request form, bargaining, contracts, payments, project room, accounts, reports, and shared console widgets so they no longer rely on `DirectorProducerDemoData`.

### 2026-07-22 — F3/F4 partial projects list and talent discovery fallback removal deployed

Status: completed for `DPProjectsListScreen` and the live talent-listing portion of `DPMarketplaceDiscoveryScreen`.

Completed:

- Removed local demo fallback from `DPProjectsListScreen`.
- Project list now shows:
  - live loading state
  - live API error + retry state
  - real empty state when no DB projects exist
  - real filtered-empty state when search/filter excludes all live projects
- Removed local demo candidate fallback from `DPMarketplaceDiscoveryScreen`.
- Marketplace discovery now loads authenticated live marketplace listings for:
  - `All`
  - `Talent`
- Non-backed categories (`Models`, `Crew`, `Locations`, `Media & Equipment`, `Agencies`) now show an honest backend-gap empty state instead of fake cards.
- Marketplace shortlisting picker now loads live projects and live project requirements from `ProjectsScope`/project APIs instead of demo projects/requirements.
- Deployed the updated Flutter web build to `https://cine.nalexustechnologies.com`.

Verification:

- `flutter analyze` passes.
- `flutter test test/director_producer_portal_test.dart --reporter compact` passes.
- `flutter test --reporter compact` passes.
- Production web build passes and is deployed.
- Live root returns HTTP 200 with the new deployment timestamp.
- Live API smoke for demo Director account:
  - `/api/v1/projects` returns 3 DB projects.
  - `/api/v1/marketplace/listings?type=talent` returns live DB listings.

Still pending:

- Add `/director/discovery` or broaden marketplace listing support for live `Crew`, `Locations`, `Media & Equipment`, `Models`, and `Agencies`.
- Refactor `DPStakeholderProfileScreen`, `DPBookingRequestFormScreen`, bargaining/negotiation, contracts, payments, project room, requirement builder, project accounts, reports, and shared Director console widgets.

### 2026-07-22 — F5 partial stakeholder profile live listing detail deployed

Status: completed for public marketplace-listing detail profiles; richer provider-specific detail remains pending.

Completed:

- Added `AuthRepository.marketplaceListing(publicId)` and `AuthController.marketplaceListing(publicId)`.
- Refactored `DPStakeholderProfileScreen` to load `/api/v1/marketplace/listings/{listing_id}`.
- Removed direct `DirectorProducerDemoData.candidates` lookup from stakeholder profile.
- Removed old hardcoded actor/model/crew/location/equipment/agency profile templates from this screen.
- Profile now renders:
  - live listing title/category/city/rate/owner/verification
  - live summary text
  - contact visibility policy copy
  - live public media gallery from listing media `file.public_url`
  - loading/error/retry states
- Deployed updated Flutter web build to `https://cine.nalexustechnologies.com`.

Verification:

- `flutter analyze` passes.
- `flutter test test/director_producer_portal_test.dart --reporter compact` passes.
- `flutter test --reporter compact` passes.
- Live root returns HTTP 200 with the new deployment timestamp.
- Live `/marketplace/listings/{id}` detail smoke passes.
- Seeded `DEMO-LST-AT-001` detail returns 2 public media rows with usable `public_url`.

Still pending:

- Add real rich stakeholder detail DTOs for non-talent provider types through `/director/discovery/<entity_type>/<entity_id>` or a generalized marketplace model.
- Refactor `DPBookingRequestFormScreen`, bargaining/negotiation, contracts, payments, project room, requirement builder, project accounts, reports, and shared Director console widgets.

### 2026-07-22 — F6 booking request composer live context and send path deployed

Status: completed for live listing/project/requirement loading and live booking send action.

Completed:

- Removed `DirectorProducerDemoData` from `DPBookingRequestFormScreen`.
- Booking composer now loads:
  - live marketplace listing detail
  - live projects
  - live requirements for the selected project
- Project and requirement dropdowns are backed by `ProjectsScope`.
- Send action now calls `BookingsScope.createAndSendBooking(...)` instead of showing a local preview snackbar.
- The form shows loading/error/retry states when live booking context is unavailable.
- Deployed updated Flutter web build to `https://cine.nalexustechnologies.com`.

Verification:

- `flutter analyze` passes.
- `flutter test test/director_producer_portal_test.dart --reporter compact` passes.
- `flutter test --reporter compact` passes.
- Production web build passes and is deployed.
- Live read-only smoke confirms:
  - `/api/v1/projects` returns DB projects.
  - `/api/v1/projects/DEMO-PROJ-001/requirements` returns DB requirements.
  - `/api/v1/marketplace/listings/DEMO-LST-AT-001` returns DB listing detail.

Note:

- Production smoke did not create a new booking, to avoid adding extra business records without an explicit throwaway smoke plan.

Still pending:

- Refactor bargaining/negotiation, contracts, payments, project room, requirement builder, project accounts, reports, and shared Director console widgets.

### 2026-07-22 — F7 Director portal demo fallback removal and live project hub wiring

Status: completed for the remaining direct `DirectorProducerDemoData` usage paths in the Director/Producer portal UI.

Completed:

- Removed demo/preview fallback rendering from:
  - bargaining center
  - negotiation thread bottom sheet/detail
  - contract center
  - payment center
  - project accounts
  - project room
  - requirement builder
  - shortlist board
  - reports/export center
  - calendar schedule risk/watch copy
  - shared project console widgets
- Refactored `DPProjectDetailScreen` to load a live project hub from backend scopes:
  - `ProjectsScope` project + requirements
  - `BookingsScope` project bookings
  - `ContractsScope` project contracts
  - `PaymentsScope` project payment schedules/milestones
- Refactored shared console project picker and project rail to use live `ProjectsScope` records.
- Converted schedule/calendar areas with no dedicated backend schedule endpoint into explicit live-empty/backend-gap states instead of fabricated events/weather/risks.
- Kept existing actions live where available:
  - send counter/accept/reject negotiation
  - generate contract from accepted booking
  - upload payment proof
  - pin project-room decision
  - upload/link project-room file
  - save project requirement
  - create/export report jobs
- Confirmed no active `DirectorProducerDemoData` references remain in Director/Producer feature code outside the data file itself.

Verification:

- `flutter analyze` passes.
- `flutter test test/director_producer_portal_test.dart --reporter compact` passes.
- `flutter test --reporter compact` passes.

Still pending:

- Add richer provider-specific profile/detail DTOs for non-talent marketplace types.

### 2026-07-22 — B7/F schedule endpoint and live Calendar wiring

Status: completed for database-derived Director schedule, risk watch, and call-sheet summary.

Completed:

- Added `GET /api/v1/director/schedule`.
- Endpoint is read-only and scoped to visible Director/Producer projects.
- Schedule events are derived from existing real tables:
  - project start/wrap dates
  - non-cancelled booking windows
  - contract checkpoints
  - payment milestone due dates
  - recent project-room items
- Risk watch is computed from real state:
  - missing project dates
  - unsigned/pending contracts
  - overdue unverified payment milestones
- Call-sheet payload is generated from the next live schedule event.
- Weather remains explicitly `provider_not_configured` until a real weather provider is supplied.
- Flutter Calendar now loads `AuthController.directorSchedule(...)`.
- Embedded `ProductionCalendar` widgets, including Project Detail schedule tab, now use live `/director/schedule` rows.
- Calendar risk watch and call-sheet bottom sheet now use the live schedule payload instead of backend-gap copy.
- OpenAPI now includes `/director/schedule` and `DirectorScheduleEnvelope`.

Verification:

- Backend compile and targeted Ruff pass.
- OpenAPI YAML parse confirms `/director/schedule` and `DirectorScheduleEnvelope`.
- Backend local pytest pass: 15 passed, 28 skipped because MySQL/Redis integration mode was not enabled.
- `flutter analyze` passes.
- `flutter test test/director_producer_portal_test.dart --reporter compact` passes.
- `flutter test --reporter compact` passes.
- Backend redeployed to production and containers restarted.
- Flutter web rebuilt with production API base and deployed.
- Live smokes:
  - `/api/v1/health/live` returns `status=ok`
  - `/api/v1/health/ready` returns database and Redis `ok`
  - `/api/v1/director/schedule` for demo Director returns 15 events, 1 risk, and `call_sheet.status=ready`
  - `/api/v1/director/schedule?project_id=DEMO-PROJ-001` returns only `DEMO-PROJ-001` events
  - web root returns HTTP 200

Still pending:

- Add a real weather provider once provider credentials are supplied.
- Add send/share call-sheet persistence if call sheets must become stored documents or notifications.
- Add richer provider-specific Director discovery/detail DTOs for non-talent marketplace types.

### 2026-07-22 — F8 project-scoped shortlist grouping

Status: completed for existing saved-shortlist data.

Completed:

- Added `projectId` and `requirementId` parsing to `MarketplaceShortlist`.
- Updated Project Detail's Shortlists tab to load live shortlist boards through `AuthController.shortlistBundle()`.
- Requirement columns now show saved shortlist items whose backend `requirement_id` matches that live requirement.
- Empty requirement columns show an honest "No saved shortlist items" state plus a Marketplace CTA.
- No backend migration or redeploy was needed because `shortlists.requirement_id` already exists and is already returned by `/shortlists`.

Verification:

- `flutter analyze` passes.
- `flutter test test/director_producer_portal_test.dart --reporter compact` passes.
- `flutter test --reporter compact` passes.

Still pending:

- Add UI affordance to create requirement-scoped shortlist boards directly from the Project Detail tab if product wants that workflow.

### 2026-07-22 — Rich provider-specific Director discovery/detail DTOs

Status: completed for the non-talent provider tables that exist today.

Completed:

- Added `GET /api/v1/director/discovery`.
- Added `GET /api/v1/director/discovery/{kind}/{public_id}`.
- New Director discovery DTOs are built from real provider-specific tables:
  - `location_properties`, with spaces, pricing, rules, public address, capacity, parking, backup power, and accessibility detail sections.
  - `equipment_provider_profiles`, with inventory, packages, and enabled terms detail sections.
  - `casting_agencies`, with represented talent roster and commission detail sections.
  - `distribution_partner_profiles`, supported in the API for future Director discovery expansion.
- Director Marketplace now loads live non-talent discovery cards for:
  - Locations
  - Media & Equipment
  - Agencies
- Director Marketplace "All" now combines existing talent marketplace listings with provider-specific Director discovery rows.
- Stakeholder Profile now detects `director:{kind}:{public_id}` records and renders live provider-specific detail sections instead of trying to load them as talent listings.
- Request/shortlist actions for provider-specific records now show a clear pending-linking message instead of sending a fake marketplace listing ID.
- OpenAPI now documents the Director discovery feed/detail endpoints and DTO envelope.

Verification:

- Backend compile and targeted Ruff pass.
- OpenAPI YAML parse confirms both new Director discovery paths.
- Backend local pytest pass: 15 passed, 28 skipped because MySQL/Redis integration mode was not enabled.
- `flutter analyze` passes.
- `flutter test test/director_producer_portal_test.dart --reporter compact` passes.
- `flutter test --reporter compact` passes.
- Backend redeployed to production and containers restarted.
- Flutter web rebuilt with production API base and deployed.
- Live smokes:
  - `/api/v1/health/ready` returns database and Redis `ok`
  - `/api/v1/director/discovery?category=Locations` returns 13 live records
  - `/api/v1/director/discovery?category=Media%20%26%20Equipment` returns 13 live records
  - `/api/v1/director/discovery?category=Agencies` returns 11 live records
  - `/api/v1/director/discovery/location/DEMO-LOC-006` returns 4 provider-specific detail sections
  - web root returns HTTP 200

Follow-up completed below:

- Models now have separate Director discovery/detail DTOs from `model_profiles`.
- Actors now have separate Director discovery/detail DTOs from `talent_profiles`.
- Provider discovery records are now linked to public marketplace listings for shortlist and booking actions.

### 2026-07-22 — Actor/Model separation and marketplace listing bridge

Status: completed for existing Actor, Model, Location, Equipment, Agency, and Distribution records.

Completed:

- Added Actor as a separate Director discovery kind backed by `talent_profiles`.
- Added Model as a separate Director discovery kind backed by `model_profiles`.
- Actor detail DTO includes profile, language, and public profile sections.
- Model detail DTO includes profile, campaign category, usage rate, usage right, and restricted-category sections.
- Added `listing_id` to Director discovery cards/details.
- Added `backend/scripts/sync_marketplace_provider_listings.py`, an idempotent sync that creates/updates public marketplace listings for:
  - actor
  - model
  - location
  - equipment
  - agency
  - distribution
- Director Marketplace now uses one live Director discovery feed for all visible categories.
- Renamed the visible Talent category to Actors; legacy `/discover/Talent` links normalize to Actors.
- Director cards now use:
  - `profileId` for rich Actor/Model/provider profile pages
  - `marketplaceListingId` for shortlist and booking actions
- Stakeholder Profile now enables Send Request for rich discovery profiles when `listing_id` exists.
- Saved searches now accept the new listing types instead of being talent-only.

Verification:

- Backend compile and targeted Ruff pass.
- OpenAPI YAML parse confirms Actor/Model enum support and `listing_id`.
- Backend local pytest pass: 15 passed, 28 skipped because MySQL/Redis integration mode was not enabled.
- `flutter analyze` passes.
- `flutter test test/director_producer_portal_test.dart --reporter compact` passes.
- `flutter test --reporter compact` passes.
- Backend redeployed to production and containers restarted.
- Production sync created/updated marketplace listings:
  - 16 actors
  - 11 models
  - 13 locations
  - 13 equipment providers
  - 11 agencies
  - 11 distribution partners
- Flutter web rebuilt with production API base and deployed.
- Live smokes:
  - Actors: 16 records, 0 missing `listing_id`
  - Models: 11 records, 0 missing `listing_id`
  - Locations: 13 records, 0 missing `listing_id`
  - Media & Equipment: 13 records, 0 missing `listing_id`
  - Agencies: 11 records, 0 missing `listing_id`
  - Actor marketplace detail opens from returned `listing_id`
  - Actor rich detail returns 3 sections with `listing_id`
  - Model rich detail returns 5 sections with `listing_id`
  - web root returns HTTP 200

Still pending:

- Crew still needs a dedicated crew-provider discovery schema or explicit mapping from existing crew profile/role data before it can match Actor/Model/provider richness.
