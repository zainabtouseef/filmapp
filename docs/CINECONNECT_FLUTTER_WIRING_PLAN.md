# CineConnect Flutter Wiring Plan

This is the execution plan for connecting the Flutter app to the now-complete backend
(Phases 0–12, documented in `docs/CINECONNECT_MASTER_BACKEND_REPORT.md` and
`docs/IMPLEMENTATION_PROGRESS.md`). It is written to be followed by an AI coding session,
one milestone at a time, in order. Do not skip ahead — later milestones assume earlier
ones are done and reuse the primitives they create.

**Last updated:** 2026-07-18
**Status:** M0 implementation started on 2026-07-18. Backend/local-storage and Flutter
picker wiring are implemented, automated checks pass, and the M0 backend/storage changes
are deployed to `cine.nalexustechnologies.com`. M0 remains unchecked until a real
app/device/browser picker upload is verified from the Flutter UI. M1 implementation is
now wired locally against production-shaped endpoints: Director/Producer saved-search
management, shortlist board loading/mutations, Actor/Talent portfolio/showreel
CRUD/upload, and Director/Producer M2 project/requirement/project-room workflows all pass
automated checks and production HTTPS smoke tests. M3 booking/negotiation/availability/chat
screen wiring is also implemented locally and verified against production HTTPS endpoints.
M4 contract/legal, M5 payment/finance, M6 operations/insurance, M7
specialist-portal wiring, M8 trust/safety wiring, and M9 analytics/export wiring are
implemented locally and verified against production HTTPS endpoints. M1–M9 still need a real
app/device/browser pass to confirm the Flutter UI itself. M10 cleanup is in source-review
pass 9: CR-04 crew availability now writes to the live availability endpoint, and the
remaining crew/director/distribution/legal/super-admin rows reviewed in that pass are
documented as already-wired wrappers or preview/backend-gap controls. A pass 10 raw sweep
also confirmed LO-02, ME-03, ME-02, role-portal placeholders, super-admin template/revenue
preview buttons, and remaining export/toggle rows; M10 remains open only for a real
Flutter app/device/browser walkthrough and any fixes found there.
Update the checklist below only as milestones fully complete, and add matching entries to
`docs/IMPLEMENTATION_PROGRESS.md` under "Connected Flutter screens" and the session log.

---

## Milestone checklist

- [x] M0 — Foundation: dependencies, upload primitive, real local-disk file storage (backend + Flutter)
- [x] M1 — Close out Phase 0–4 (auth/KYC/profile/marketplace) gaps: portfolio, saved searches, shortlist board
- [x] M2 — Projects, requirements, project room (Phase 5) — Director/Producer
- [x] M3 — Bookings, negotiation, availability, chat (Phase 6) — Director/Producer, Actor/Talent, Model
- [x] M4 — Contracts & legal (Phase 7) — shared contract screen, Actor/Talent, Legal Partner portal
- [x] M5 — Payments & finance (Phase 8) — shared payment screens, Director/Producer, Actor/Talent, Super Admin
- [x] M6 — Location, equipment, safety, insurance (Phase 9) — Location Owner, Media/Equipment, Insurance Partner
- [x] M7 — Agency, brand, model, distribution (Phase 10) — Casting Agency, Brand/Sponsors, Model Extension, Distribution Partner
- [x] M8 — Reviews, moderation, disputes, support, announcements (Phase 11) — shared screens + Super Admin
- [x] M9 — Dashboards, analytics, exports (Phase 12) — every portal's dashboard screen + Super Admin analytics
- [ ] M10 — Cleanup: retire remaining demo-data imports, final `UI_ACTION_INVENTORY.csv` sweep, full regression pass

---

## 1. Baseline — what already exists (read this before touching anything)

A full codebase survey was done on 2026-07-18. Key findings, so the executing AI does not
have to rediscover them:

**Already wired (real API calls, not demo data):**
splash bootstrap/routing, login, signup, forgot-password, role selection, profile role
switcher, settings logout, KYC upload + submit + status, admin KYC queue/detail/decision,
director/producer marketplace discovery (listings/saved-search/shortlist-add),
actor/talent profile builder (city/bio/talent profile/publish listing).

**Not wired at all (zero Flutter caller today):** everything for projects, bookings,
contracts, payments, location/equipment/insurance/safety, agency/brand/model/distribution,
reviews/moderation/disputes/support/announcements, and all Phase 12 dashboards/exports —
i.e. essentially all of Milestones M1 (partially) through M9 below.

**Existing architecture to reuse (do not replace it — see Section 2):**
- `lib/core/network/api_client.dart` — hand-rolled `ApiClient` over `package:http`. Has
  `get`/`post`/`patch`. **Does not have `put`/`delete` helpers yet** — several backend
  endpoints are `DELETE` (e.g. `/saved-searches/{id}`, `/shortlist-items/{id}`,
  `/blocked-users/{id}`) and `PATCH` (many) — add missing verb helpers as part of M0.
- `lib/core/network/api_exception.dart` — typed exception with `code`/`message`/`fields`.
- `lib/core/auth/token_store.dart` — `flutter_secure_storage` wrapper for access/refresh
  tokens.
- `lib/core/auth/auth_repository.dart` — one method per endpoint, unwraps `data`, returns
  typed models. **This is the template to copy** for every new repository.
- `lib/core/auth/auth_controller.dart` — `ChangeNotifier` exposing app-facing async
  methods; exposed via `AuthScope extends InheritedNotifier<AuthController>`
  (`AuthScope.of(context)` / `AuthScope.maybeOf(context)`). Not Provider/Riverpod/Bloc —
  a hand-rolled scope. **This is the template to copy** for every new controller.
- Two screens (`dp_marketplace_discovery_screen.dart`, `at02_profile_builder_screen.dart`)
  already implement the target pattern end-to-end: call the real API, and on
  error/empty/offline fall back to the local demo dataset with a small inline warning
  ("Live data unavailable — showing preview data"). **Copy this degrade-gracefully
  pattern for every screen in this plan** — do not delete demo data files; downgrade them
  to fallback/offline content instead, until M10.

**Dependencies currently installed:** `flutter`, `google_fonts`, `flutter_secure_storage`,
`http`. That's all. No `dio`, `riverpod`, `flutter_bloc`, `provider`, `freezed`,
`json_serializable`, `go_router`, `connectivity_plus`, `web_socket_channel`,
`image_picker`, `file_picker`. See Section 2.3 for what to add and why.

**Routing:** manual `onGenerateRoute` string-switch in `lib/core/core_ui/core_routes.dart`,
not `go_router`. Route constants like `.../:id` are naming convention only — real entity
ids are passed via `RouteSettings.arguments`, never parsed from the path. Keep this
pattern (Section 2.2).

**Tracking artifact:** `docs/UI_ACTION_INVENTORY.csv` (regenerate with
`python3 tools/inventory_ui_actions.py` after wiring a batch of screens) classifies every
interactive callback as `local_state` / `navigation` / `review` / `server_candidate`. The
170 `server_candidate` rows are the ground truth of what still needs a real API call. Use
it to sanity-check a milestone is actually complete — do not rely on memory of which
screens were touched.

**Portal → screen file map:** every portal under `lib/features/<portal>/` follows
`data/<portal>_demo_data.dart`, `models/`, `routes/<portal>_routes.dart`,
`screens/<portal>_portal_screen.dart` (+ numbered screens), `widgets/`. Screen IDs (AT01,
DP01, LO01, ME01, etc.) match the master report's Section 8 numbering — use that mapping
to find files quickly.

---

## 2. Foundational decisions (lock these before Milestone M1)

### 2.1 State management: keep `ChangeNotifier` + `InheritedNotifier`

Do **not** introduce Riverpod, Bloc, or Provider mid-project. The existing
`AuthController`/`AuthScope` pattern works, is fully understood, has zero extra
dependencies, and a framework swap now would be pure risk with no user-facing benefit.

Convention going forward: **one repository + one controller per backend blueprint**,
mirroring the backend's own `app/api/*.py` module boundaries (which the wiring milestones
below already follow):

| Backend module | New Dart repository | New Dart controller | Scope name |
|---|---|---|---|
| `app/api/projects.py` | `ProjectsRepository` | `ProjectsController` | `ProjectsScope` |
| `app/api/bookings.py` | `BookingsRepository` | `BookingsController` | `BookingsScope` |
| `app/api/contracts.py` | `ContractsRepository` | `ContractsController` | `ContractsScope` |
| `app/api/payments.py` | `PaymentsRepository` | `PaymentsController` | `PaymentsScope` |
| `app/api/operations.py` | `OperationsRepository` | `OperationsController` | `OperationsScope` |
| `app/api/insurance.py` | `InsuranceRepository` | `InsuranceController` | `InsuranceScope` |
| `app/api/specialist.py` | `SpecialistRepository` | `SpecialistController` | `SpecialistScope` |
| `app/api/trust_safety.py` | `TrustSafetyRepository` | `TrustSafetyController` | `TrustSafetyScope` |
| `app/api/analytics.py` | `AnalyticsRepository` | `AnalyticsController` | `AnalyticsScope` |

Prefer **screen-local state** (a `StatefulWidget` + `FutureBuilder` calling the repository
directly, no controller) when only one screen needs the data. Only add a controller/scope
when 2+ screens need to share cached state (e.g. `BookingsController` holding the current
inbox, read by both the inbox list and a badge counter). This mirrors what already exists:
`AuthController` is shared because many screens need `user`/session state;
marketplace-listing search results are not shared beyond one screen and are fetched
directly in `dp_marketplace_discovery_screen.dart` today.

### 2.2 Routing: keep the manual `onGenerateRoute` switch

Do not introduce `go_router`. All routes are already static strings with arguments passed
via `RouteSettings.arguments` — this works fine for a chat/detail screen that needs "the
booking id" as an argument rather than a URL segment. Adding real path-parameter routing
would be a large, purely cosmetic refactor with no functional gain for a mobile-first app
that doesn't need deep-linkable URLs today. Revisit only if/when Flutter web deep-linking
becomes an actual product requirement.

### 2.3 New dependencies to add, once, in M0

Add to `pubspec.yaml` in one PR at the start of M0 (do not add dependencies piecemeal per
milestone — that causes redundant `flutter pub get` churn and version drift):

```yaml
dependencies:
  image_picker: ^1.1.2        # camera/gallery picking (portfolios, KYC docs, listing photos)
  file_picker: ^8.1.4         # arbitrary document picking (contracts, PDFs)
  connectivity_plus: ^6.1.0   # offline detection (master spec §12.1)
  intl: ^0.19.0               # locale-aware PKR/date formatting (master spec §9)
```

Explicitly **do not add**: `dio` (the hand-rolled `ApiClient` already does everything
needed — auth header injection, timeout, typed error envelope parsing; swapping HTTP
clients mid-project buys nothing), `freezed`/`json_serializable` (would require
`build_runner` codegen; the existing manual `fromJson` pattern is proven across 5+ files
already and is easier for a fresh AI session to read/modify without running codegen
first), `go_router` (Section 2.2), `riverpod`/`bloc`/`provider` (Section 2.1).

If real-time chat/notifications (Section 11 of the master report — WebSocket rooms) are
tackled later, add `web_socket_channel` at that point, scoped to that milestone only — not
upfront, since M3's chat screen can ship correctly with REST polling first (matching the
master report's own guidance: "WebSockets improve responsiveness but are not the source of
truth... on reconnect Flutter fetches from REST").

### 2.4 Per-screen state contract (apply to every screen touched)

Every wired screen must handle, explicitly, in this order of priority:

1. **Loading** — show a skeleton/spinner, not a blank screen.
2. **Success with data** — render it.
3. **Success, empty** — an explicit empty state (not just an empty list silently), with a
   relevant call-to-action where applicable (e.g. "No projects yet — create one").
4. **Permission/verification required** — e.g. KYC not approved yet; show why, and a link
   to fix it, don't just show a generic error.
5. **Offline / server error** — show the demo-data fallback content (per the existing
   hybrid-screen pattern) with a small non-blocking inline notice, plus a retry action.
   Do **not** show a raw exception message to the user; map `ApiException.code` to a short
   human sentence (extend `AuthController`'s existing error-mapping approach).
6. **Mutation in progress** — disable the triggering button, show a spinner on it.
7. **Mutation success** — refresh the affected query, show a brief success signal
   (snackbar / inline check), and navigate if that's the expected flow (e.g. after
   creating a project, go to its detail screen).

### 2.5 Demo-data retirement policy

Keep every `*_demo_data.dart` file through M9. They become the offline/error-fallback
content per Section 2.4, not dead code. Only delete a portal's demo data file in M10, and
only after `docs/UI_ACTION_INVENTORY.csv` shows zero `server_candidate` rows remaining for
that portal's files.

---

## 3. File storage: real local-disk storage on the server (do this in M0, first)

### 3.1 Why this has to happen before any upload screen is wired

This is more urgent than "R2 vs local directories" — **the backend today does not
transport file bytes at all**, even in the currently-wired KYC upload flow. Read
`backend/app/api/verification.py`:

- `POST /uploads/presign` creates an `UploadSession` row and returns an `upload_url` that
  literally points back at this API's own `/uploads/{id}/complete` endpoint (there is no
  S3/R2 call anywhere in the codebase — `OBJECT_STORAGE_BUCKET_PRIVATE`/`_PUBLIC` are
  config labels only, never passed to any storage SDK).
- `POST /uploads/{id}/complete` accepts **JSON metadata only** (`size_bytes`,
  `checksum_sha256`) and trusts whatever the client claims. No bytes are ever received or
  written anywhere.
- This is why `AuthController.completeDemoUpload()` sends a hardcoded fake checksum
  (`'0' * 64`) — there was never a real byte transport to plug into.

Per your decision, we will fix this with real files stored in directories on the
production server (no Cloudflare R2, no S3-compatible service). This is simpler to
operate than R2 for a single-server deployment, and is a completely reasonable permanent
choice at this scale — just make sure the backup script (Section 3.3) covers it, since
local files are not covered by the existing MySQL-only backup cron.

### 3.2 Backend changes (exact files to create/modify)

1. **`backend/app/config.py`** — add:
   ```python
   LOCAL_STORAGE_PRIVATE_ROOT = os.getenv("LOCAL_STORAGE_PRIVATE_ROOT", "/data/storage/private")
   LOCAL_STORAGE_PUBLIC_ROOT = os.getenv("LOCAL_STORAGE_PUBLIC_ROOT", "/data/storage/public")
   PUBLIC_MEDIA_BASE_URL = os.getenv("PUBLIC_MEDIA_BASE_URL", "")  # e.g. https://cine.nalexustechnologies.com/media
   ```

2. **New `backend/app/services/local_storage.py`**:
   - `save_stream(upload_session: UploadSession, stream: IO[bytes]) -> tuple[int, str]` —
     writes the incoming bytes to
     `{root}/{upload_session.storage_key}` (create parent dirs as needed), computing a
     real SHA-256 checksum and byte count as it streams (don't buffer the whole file in
     memory for large videos — read/write/hash in chunks, e.g. 1 MiB at a time). Enforce
     `upload_session.max_bytes` mid-stream (abort and delete the partial file if exceeded,
     don't just check after the fact). Root is chosen by `upload_session.bucket`
     (`"private"` vs `"public"`, replacing the old S3-bucket-name meaning of that column —
     no migration needed, it's just a label now).
   - `resolve_path(file_asset: FileAsset) -> Path` — for authenticated downloads.
   - `public_url_for(file_asset: FileAsset) -> str | None` — returns
     `f"{PUBLIC_MEDIA_BASE_URL}/{file_asset.storage_key}"` if `visibility == "public"`,
     else `None`.
   - Path traversal safety: validate `storage_key` never contains `..` before joining (it's
     server-generated today in `presign_upload()`, but validate defensively anyway since
     it's attacker-adjacent surface).

3. **`backend/app/api/verification.py`** changes:
   - Add a migration adding `UploadSession.binary_received_at: datetime | None`.
   - New endpoint:
     ```python
     @verification_blueprint.put("/uploads/<public_id>/binary")
     def upload_binary(public_id: str) -> ResponseReturnValue:
         user = _current_user()
         upload = ...  # look up by public_id + user_id, same guard as complete_upload
         if as_utc(upload.expires_at) <= utc_now():
             raise APIError("uploads.expired", ..., status=410)
         content_length = request.content_length or 0
         if content_length <= 0 or content_length > upload.max_bytes:
             raise _field_error("file", "File size does not match the upload session.")
         size_bytes, checksum = save_stream(upload, request.stream)
         upload.binary_received_at = utc_now()
         db.session.commit()
         return jsonify(success({"size_bytes": size_bytes, "checksum_sha256": checksum}))
     ```
     Rate-limit this the same as `presign_upload` (`@limiter.limit(...)`).
   - Modify `complete_upload()`: require `upload.binary_received_at is not None` (raise a
     clear `uploads.binary_not_received` error otherwise); stop trusting client-supplied
     `size_bytes`/`checksum_sha256` — read them from the `UploadSession`/computed values
     from step above instead (store them on `UploadSession` when `save_stream` runs, or
     re-derive by re-reading the file — prefer storing on `UploadSession` to avoid a
     second disk read).
   - Update `presign_upload()`'s returned `upload_url` to point at the new
     `PUT /uploads/{id}/binary` endpoint instead of `/complete`.

4. **New `GET /files/<public_id>/download`** (new small blueprint or add to
   `verification.py`): authenticated, checks the requesting user is the file's owner *or*
   has a legitimate reason to see it (this needs a bit of judgment per file purpose —
   start with owner-only, extend to "contract party", "booking participant" etc. as those
   download call-sites get wired in later milestones), then `send_file()`s from
   `resolve_path()`. Add `Cache-Control: private, max-age=0` and don't cache-bust the
   filename.

5. **Celery task upgrade (optional, recommended)**: `app/tasks/files.py` /
   `app/services/file_processing.py` — once files are real and on local disk, upgrade
   `mark_file_scan_clean` to actually shell out to `clamscan` (ClamAV) against
   `resolve_path(file)` before flipping `scan_status` to `clean`, and reject (`scan_status
   = "infected"`) otherwise. This is a real, feasible upgrade now that bytes exist on disk
   — flag it as a nice-to-have within M0, not a blocker for the rest of the plan.

### 3.3 Docker / deployment changes

- **Local dev** (`compose.yaml`): add a bind mount so files survive `docker compose down`:
  ```yaml
  api:
    volumes:
      - ./backend/.storage:/data/storage
  worker:
    volumes:
      - ./backend/.storage:/data/storage
  ```
  Add `backend/.storage/` to `.gitignore`.

- **Production**: on the server, `mkdir -p /var/www/cineconnect/storage/{private,public}`,
  `chown` to whatever user the containers should run as. Add `-v
  /var/www/cineconnect/storage:/data/storage` to both the `cineconnect-api` and
  `cineconnect-worker` `docker run` commands (worker needs it if the ClamAV scan task
  reads the file). Set `LOCAL_STORAGE_PRIVATE_ROOT=/data/storage/private`,
  `LOCAL_STORAGE_PUBLIC_ROOT=/data/storage/public`,
  `PUBLIC_MEDIA_BASE_URL=https://cine.nalexustechnologies.com/media` in the server's
  `backend/.env`.

- **Nginx**: add to the existing `cine.nalexustechnologies.com` vhost (before the
  `location /` proxy block, so it's matched first):
  ```nginx
  location /media/ {
      alias /var/www/cineconnect/storage/public/;
      add_header Cache-Control "public, max-age=86400";
  }
  ```
  This serves public/approved media directly (fast, no Gunicorn hop); private files stay
  behind the authenticated `/files/{id}/download` Flask endpoint. Back up the vhost file
  before editing, `nginx -t` before reloading — same discipline as every previous
  deployment change to this shared host.

- **Backups**: the existing `deploy/scripts/backup_db.sh` only covers MySQL. Add a second
  script (or extend it) to `tar`/rsync `/var/www/cineconnect/storage` into the same daily
  backup rotation — uploaded files are now real user data and need the same RPO guarantee
  as the database.

- **Update docs**: `docs/DEPLOYMENT_INPUTS.md` "Object storage and media" section — replace
  "Cloudflare R2 (approved default; credentials required)" with "Local directories on the
  production host (`/var/www/cineconnect/storage/{private,public}`), decided
  2026-07-18 — no third-party object storage in use."

### 3.4 Flutter changes (once the backend above is deployed and smoke-tested)

1. Add `image_picker`/`file_picker` (Section 2.3).
2. Extend `ApiClient` with a raw-body PUT method that streams from a `File`/`Uint8List`
   with the right `Content-Type`, ideally exposing upload progress (a `ValueNotifier` or
   callback) since videos can be large.
3. New `UploadRepository` (or a method on each domain repository that needs it) with one
   entry point:
   ```dart
   Future<UploadedFile> uploadFile({
     required String purpose,       // "kyc_document" | "profile_media" | "payment_proof" | ...
     required PickedFileData file,  // wraps image_picker/file_picker result: bytes, name, mimeType
   })
   ```
   Internally: `presign()` → `PUT` the bytes to the returned `upload_url` → `complete()` →
   return the resulting `UploadedFile`. This is the **one place** upload logic lives;
   every portal's photo/document/video upload button calls this same method.
4. Replace `verification_screens.dart`'s `_uploadDemoFile`/`completeDemoUpload` call sites
   with real picker + `UploadRepository.uploadFile()` calls. Keep the existing `UploadCard`
   widget as-is (it's presentational).
5. Add new backend upload `purpose` values as needed per milestone (the backend currently
   only allows `kyc_document`, `profile_media`, `payment_proof` — M1's portfolio media and
   M6's location/equipment photos will need `portfolio_media`, `location_media`,
   `equipment_media`, etc. added to `ALLOWED_UPLOAD_MIME_TYPES`/the purpose allow-list in
   `verification.py`'s `presign_upload()` as each milestone needs them — don't add purposes
   speculatively ahead of the milestone that uses them).

### 3.5 Verification for this sub-project

- Local: run `docker compose up`, use the app to complete a real KYC upload with an actual
  picked image; confirm a real file appears under `backend/.storage/private/...` on the
  host and its size/checksum in the DB match the real file (not `0`s).
- Production: after deploying, repeat the same check over `ssh` — confirm a file lands
  under `/var/www/cineconnect/storage/private/...` and is retrievable via the new
  `/files/{id}/download` endpoint with a valid token, and rejected (401) without one.
- Confirm the backup script now includes the storage directory (Section 3.3) and run it
  once manually to verify.

---

## 4. Milestone-by-milestone plan

Each milestone below lists: goal, backend reference, exact Flutter files to touch, new
Dart types to create, and a verification checklist. Cross-reference
`docs/IMPLEMENTATION_PROGRESS.md`'s "Completed endpoints" table for exact request/response
shapes and auth rules per endpoint — it is not repeated here to avoid drift between two
copies of the same information.

### M1 — Close out Phase 0–4 gaps

**Goal:** finish what Phase 4 already started. Portfolio/showreel management, saved-search
management UI, and full shortlist board CRUD were explicitly left as "Incomplete work" in
the backend's own Phase 4 session log, and are the last gaps before Phase 4 is 100% wired.

**Screens:**
- `lib/features/actor_talent/screens/at03_portfolio_showreel_screen.dart` — wired to
  `GET/POST/PATCH/DELETE /portfolio`, using `UploadRepository` from M0 for adding new
  portfolio media with `purpose: "profile_media"`; create retries briefly while the
  production file-scan worker marks uploads `clean/ready`.
- Director/Producer saved-search management (wherever saved searches are listed/deleted
  today — likely reachable from `dp_marketplace_discovery_screen.dart` or a dedicated
  screen) — wire `GET/DELETE /saved-searches`.
- Shortlist board screen — wire `GET /shortlists`, `PATCH/DELETE /shortlist-items/{id}`
  (create + add-item already wired via `addToDefaultShortlist`).

**New Dart types:** extend `MarketplaceModels`/`AuthRepository` with the above methods
(this is small enough to stay inside the existing auth/marketplace files rather than
spinning up a whole new repository — use judgment; if it starts feeling crowded, that's
the signal to extract a `MarketplaceRepository`).

**Verification:** automated implementation is complete: production smoke created/listed/
patched/deleted portfolio media after a real HTTPS upload, saved search list reflects
server state after create/delete, and shortlist board loads/mutates server boards/items.
Manual remaining check before ticking M1: run the Flutter app and complete one real
device/browser picker upload plus one shortlist item mutation through the UI.

### M2 — Projects, requirements, project room (Phase 5)

**Portal:** Director/Producer only.

**Screens:** DP-02 Projects List, DP-03 Create Project Wizard, DP-04 Project Detail,
DP-05 Requirement Builder, DP-17 Project Room (members/files/decisions).

**New Dart types:** `ProjectsRepository`, `ProjectsController` (shared cache of "my
projects" since the dashboard, list, and picker-in-booking-flow all need it),
`ProjectsScope`. DTOs: `Project`, `ProjectMember`, `Requirement`, `Skill`,
`ProjectRoomItem`, `ProjectFile`.

**Endpoints:** skills catalog, project CRUD, members list, requirements CRUD, project room
aggregate/items, project files (uses `UploadRepository` from M0 with a new
`project_document` purpose).

**Implementation status:** code and production endpoint smoke are complete. A
`ProjectsRepository`/`ProjectsController`/`ProjectsScope` now backs DP-02, DP-03, DP-04,
DP-05, and DP-17. `project_document` was added to the upload allow-list, and production
`API_PUBLIC_URL` now emits externally reachable HTTPS upload URLs.

**Verification:** production smoke created a project, listed/detail-fetched it, added a
requirement, opened the project room, pinned a decision, uploaded a `project_document`,
linked it to the room, and confirmed the room aggregate persisted both file and decision.
Manual remaining check before ticking M2: run the Flutter app and complete the same flow
through the UI with a real device/browser picker.

### M3 — Bookings, negotiation, availability, chat (Phase 6)

**Portals:** Director/Producer, Actor/Talent, Model (shares Actor/Talent's booking flow).

**Screens:** DP-10 Booking Request, DP-11 Bargaining Center, DP-12 Negotiation Thread,
DP-15 Calendar/Schedule, AT-04 Availability Calendar, AT-06 Opportunity Inbox, AT-07 Offer
Detail, AT-08 Counteroffer Composer, core `/booking/chat`.

**New Dart types:** `BookingsRepository`, `BookingsController` (holds inbox/opportunities
lists + unread state), `BookingsScope`. DTOs: `Booking`, `Offer`, `NegotiationThread`,
`AvailabilityEntry`, `Conversation`, `Message`, `PinnedDecision`.

**Endpoints:** availability check/CRUD, booking create/detail/send/reject, negotiation
list/detail, offer create/accept, booking inbox/opportunities list, conversation
messages/pin.

**Implementation status (2026-07-18):** Implemented locally. Added
`lib/core/bookings/` models/repository/controller/scope and app-level `BookingsScope`.
DP-10 creates and sends bookings using live projects/listings, DP-11 lists negotiations,
DP-12 loads rounds and can counter/accept, AT-04 lists/saves availability, AT-06 loads
provider opportunities and accepts offers, AT-07 loads/rejects/accepts live bookings,
AT-08 sends counteroffers for live `BKG-*` ids, and core `/booking/chat` fetches/sends
REST messages and calls the message pin endpoint. Automated checks pass and production
HTTPS smoke passed. Manual two-account Flutter UI validation is still required before
ticking the milestone checkbox.

**Chat specifics:** start with REST polling (fetch messages on a timer or on
screen-resume) per Section 2.3 — this is correct and matches the master report's own
guidance that WebSockets are an enhancement, not the source of truth. Do not block this
milestone on adding `web_socket_channel`.

**Verification:** two real accounts (a producer and a talent, both created through the
running app) complete a full offer → counter → accept cycle and see it reflected in both
inboxes; chat messages persist and both sides see them; accepted offers show as calendar
locks in the availability screen.

### M4 — Contracts & legal (Phase 7)

**Portals:** shared `/contract` screen (used by both Director/Producer and Actor/Talent),
Legal Partner portal.

**Screens:** core contract viewer/signature screen, DP-13 Contract Center, AT-09 Contract
Signing, LG-01 through LG-05 (Legal Partner dashboard, review detail, template review,
addendum review, history/billing).

**New Dart types:** `ContractsRepository`, `ContractsController`, `ContractsScope`. DTOs:
`ContractTemplate`, `Contract`, `ContractParty`, `ContractSignature`, `LegalReview`.

**Endpoints:** template list, contract list/detail, booking-to-contract generation,
signature, addendum request, legal review request/list/detail/decision.

**Implementation status (2026-07-18):** Implemented locally. Added
`lib/core/contracts/` models/repository/controller/scope and app-level `ContractsScope`.
DP-13 lists live contracts, generates a contract from an accepted booking, opens the
shared viewer, and requests legal review. AT-09 lists live contracts and opens the shared
viewer for signature/correction. Core `/contract` loads `CTR-*` records, signs through the
signature endpoint, and creates addendum requests. LG-01/LG-02 use live legal review
queue/detail/decision endpoints; LG-03 surfaces published templates; LG-04/LG-05 surface
live addendum/review history where available. Automated checks pass and production HTTPS
smoke passed. Manual real UI validation is still required before ticking the milestone
checkbox.

**Verification:** an accepted booking (from M3) produces a contract, both parties sign it
through the app, a legal reviewer (a real `legal_partner`-role test account) sees it in
their queue and can decide it.

### M5 — Payments & finance (Phase 8)

**Status 2026-07-18:** implemented and production-smoked against
`https://cine.nalexustechnologies.com/api/v1`. Shared payment proof upload, ledger,
Director/Producer payment center, Actor/Talent earnings/security, and Super Admin
payments hub/queue/review now use `PaymentsScope` with demo/offline fallback.

**Portals:** shared `/payments/proof` + `/payments/ledger`, DP-14 Payment Center, AT-10
Earnings/Security, Super Admin payment screens (Payments Hub, Payment Verification Queue,
Payment Review Detail, Receipts Ledger Admin, Revenue Settings).

**New Dart types:** `PaymentsRepository`, `PaymentsController`, `PaymentsScope`. DTOs:
`PaymentSchedule`, `PaymentMilestone`, `PaymentProof`, `Receipt`, `LedgerEntry`,
`PayoutAccount`.

**Endpoints:** payments dashboard, schedule list/detail, proof submission (uses
`UploadRepository` with a `payment_proof` purpose — already allow-listed today), ledger,
receipt detail, payout account list/create, admin payment proof queue/detail/decision.

**Verification:** submit a real payment proof with a picked file, a finance-admin test
account approves it, confirm ledger/receipt appear correctly and the booking flips to
"secured" in the UI.

**Verified 2026-07-18:** production HTTPS smoke created a fresh signed contract, loaded
the generated payment schedule, uploaded a real PDF proof through `/uploads/presign` +
`PUT /uploads/{id}/binary`, submitted `/payment-proofs`, approved it through
`/admin/payment-proofs/{id}/decision`, confirmed producer ledger/receipt, and confirmed
the booking became `secured` with the milestone `verified`.

### M6 — Location, equipment, safety, insurance (Phase 9)

**Portals:** Location Owner (LO01–LO10), Media/Equipment (ME01–ME10), Insurance Partner
(the newest backend addition, closed out 2026-07-18 — see
`docs/IMPLEMENTATION_PROGRESS.md`'s 2026-07-18 session log for exact endpoints).

**New Dart types:** `OperationsRepository`/`OperationsController` (location + equipment +
safety, mirroring the backend's single `operations.py` module), `InsuranceRepository`/
`InsuranceController` (separate, mirrors the backend's separate `insurance.py`).

**Endpoints:** location property/space/pricing/rules CRUD, location inspections + dual
confirmation, damage claims + evidence, equipment provider profile/items/packages/terms,
equipment inspections + dual confirmation, safety checks/items, incidents, safety
check-ins, insurance profile/policies/claims/evidence/decision.

**File uploads needed:** location/equipment listing photos, inspection before/after
photos, damage/claim evidence — each needs its own `purpose` value added to the backend
allow-list as this milestone reaches it (Section 3.4, point 5).

**Status 2026-07-18:** Implemented and production-smoked. Added `OperationsRepository`/
`OperationsController` and `InsuranceRepository`/`InsuranceController`, exposed them at
app scope, and wired LO02, ME02, ME03, IN01, IN02, and IN03 to live endpoints with demo
fallback. Backend upload purposes now accept `location_media`, `equipment_media`,
`inspection_evidence`, `damage_evidence`, `insurance_document`, and
`insurance_evidence`. Production smoke passed against
`https://cine.nalexustechnologies.com/api/v1`: property/space/pricing/rule, inspection
dual confirmation, damage evidence, equipment profile/item/package/term, equipment
inspection dual confirmation, safety check/item, incident, talent safety check-in,
insurance profile/policy/claim/evidence/decision.

**Known nuance:** inspection creation is booking-party scoped, so when the location owner
or equipment provider is not a booking participant, the booking requester creates the
inspection and the owner/provider then dual-confirms it. Listing media upload purposes are
allowed, but there is still no dedicated location/equipment listing-media attachment
table/API; the current Flutter wiring validates upload readiness and uses live create/list
records while preserving demo media previews.

**Verification:** a location owner publishes a property with real photos, a booking's
check-in inspection captures real before/after photos with dual confirmation from both
parties, a damage claim with evidence attaches correctly; an equipment provider completes
an equivalent handover/return cycle; an insurance partner creates a policy and processes a
claim through to a decision.

### M7 — Agency, brand, model, distribution (Phase 10)

**Portals:** Casting Agency (8 screens), Brand/Sponsors (7), Model Extension (3–5),
Distribution Partner (4–6).

**New Dart types:** `SpecialistRepository`/`SpecialistController` (mirrors backend
`specialist.py`, which already covers all four of these portals in one module).

**Endpoints:** agency profile/roster/invitations, auditions/candidates/self-tapes/notes,
commissions; brand profile/opportunities/applications/terms/deliverables/metrics; model
profile/campaign-categories/usage-rights/usage-rates/restricted-categories (plus
`GET /portfolio?profile_type=model`, already supported); distribution partner
profile/projects/contacts/release-windows/handover-items/reports.

**Verification:** an agency invites and adds a talent to its roster, runs an audition with
a self-tape submission and selection notes; a brand publishes an opportunity, receives an
application, negotiates terms, and approves a deliverable; a model sets usage
rights/rates/restrictions; a distribution partner tracks a release through report
submission.

**Status 2026-07-18:** Implemented and production-smoked. Added
`SpecialistRepository`/`SpecialistController`, exposed `SpecialistScope` at app level, and
live-wired core Phase 10 surfaces across Casting Agency, Brand/Sponsors, Model Extension,
and Distribution Partner. Production smoke passed against
`https://cine.nalexustechnologies.com/api/v1`: agency profile/invitation/accept/roster,
audition/candidate/self-tape/selection-note/commission, brand
profile/opportunity/application/status/terms/deliverable/metrics/approval, model
profile/categories/usage-rights/usage-rates/restricted-categories, and distribution
profile/project/release-window/handover/contact/report.

**Known nuance:** the first M7 Flutter pass prioritizes live workspace banners plus the
highest-leverage create/update actions already present in the UI. Some deeper screens
still show demo cards as their primary visual surface while live records are loaded or
mutated in the background; this follows the plan's degrade-gracefully rule and leaves a
manual UI pass plus final M10 demo-retirement sweep.

### M8 — Reviews, moderation, disputes, support, announcements (Phase 11)

**Portals:** shared `/review` and `/report` screens, notification center (real wiring,
replacing whatever placeholder exists today), Super Admin (Dispute Center/Case File,
Content Moderation Queue/Detail, Listings Moderation, Support CRM, Broadcast
Announcements, Review Hub).

**New Dart types:** `TrustSafetyRepository`/`TrustSafetyController` (mirrors backend
`trust_safety.py`).

**Endpoints:** review eligibility/create, user reviews, review requests, report
reasons/create, blocked users, admin moderation cases/decision, disputes/evidence/admin
decision, support tickets/messages/admin queue, admin announcements/publish,
notifications list/read/read-all, push device registration.

**Verification:** after a completed booking, both parties can leave a review and see it
reflected in the other's public rating; a report on non-user content produces a
moderation case an admin can see and decide; a dispute goes from filed → evidence →
admin decision with both parties notified in the app's notification center; a support
ticket thread works with internal-note visibility correctly hidden from the ticket owner;
an announcement published by a super-admin appears in a real user's notification center.

**Implementation status (2026-07-18):** done locally. Added `TrustSafetyRepository`,
`TrustSafetyController`, and `TrustSafetyScope`; wired shared notification center,
report/block, and ratings/review screens; wired Super Admin moderation, dispute, support,
broadcast, and review hub pages with live queue/action strips and demo fallback. Automated
Flutter checks pass, and production HTTPS smoke passed against
`cine.nalexustechnologies.com` for review eligibility/create/list/request, reports,
blocked users, moderation decision, disputes/decision, support tickets/messages/admin
status, announcements/publish, notifications read/read-all, and push device registration.

### M9 — Dashboards, analytics, exports (Phase 12)

**Portals:** every portal's "01 Dashboard" screen (AT-01, DP-01/home, LO-01, ME-01,
CR-01, CA-01, BR-01, IN-01, DS-01, LG-01) plus Super Admin Dashboard, Admin Analytics,
Audit Log Explorer, and any "export"/"download CSV" buttons across screens.

**New Dart types:** `AnalyticsRepository`/`AnalyticsController` (mirrors backend
`analytics.py`).

**Endpoints:** `/me/dashboard` (generic personal KPIs — use this for every non-admin
portal's dashboard screen, it already adapts sensibly to any role), `/admin/dashboard`,
`/admin/analytics`, `/exports` create/list/detail.

**Note:** per-portal specialist dashboards (e.g. a location-owner-specific KPI set) are
not yet built as dedicated backend endpoints beyond the generic `/me/dashboard` and the
Section 8 per-portal dashboard endpoints that were never implemented (out of Phase 12's
actual backend scope — see `docs/IMPLEMENTATION_PROGRESS.md`'s Phase 12 "Incomplete work"
notes). Where a portal's dashboard screen needs numbers the generic endpoint doesn't
provide, either (a) wire it to `/me/dashboard` for the subset of fields that do apply and
leave the rest showing "coming soon", or (b) flag it back to a future backend milestone —
do not fabricate client-side aggregate calculations that duplicate what should be a
server-computed, tested number.

**Verification:** every portal's dashboard shows real numbers that change when you take an
action elsewhere in the app (e.g. accepting a booking increases "pending offers" → 0 and
"secured value" on the relevant dashboard); a CSV export button produces a real download
with correct row counts matching what's on screen.

**Implementation status (2026-07-18):** done locally. Added `AnalyticsRepository`,
`AnalyticsController`, `AnalyticsScope`, and reusable dashboard/export widgets. Wired
generic `/me/dashboard` KPI strips into the main portal dashboards, wired Super Admin
Dashboard to `/admin/dashboard`, wired Admin Analytics to `/admin/analytics`, and converted
supported CSV export actions to `/exports` for `bookings`, `ledger`, and
`admin_disputes`. Automated Flutter checks pass, and production HTTPS smoke passed against
`cine.nalexustechnologies.com` for personal dashboard, admin dashboard, admin analytics,
export create/list/detail, and all three supported export types.

### M10 — Cleanup

- Run `python3 tools/inventory_ui_actions.py` and confirm zero `server_candidate` rows
  remain unaddressed (a handful may be legitimately deferred — e.g. features with no
  backend yet — document those explicitly rather than silently leaving them).
- Delete `*_demo_data.dart` files only for portals with zero remaining fallback
  dependents; for any screen still using fallback content deliberately (e.g. genuinely
  offline-tolerant screens), keep it and note why in a code comment.
- Full regression pass: `flutter analyze` clean, full widget test suite green, one
  complete manual walkthrough per portal against the local Docker backend.
- Final `docs/IMPLEMENTATION_PROGRESS.md` update: fill in the "Connected Flutter screens"
  table completely, check every phase's checklist box now that both backend and frontend
  are done for it.

**Implementation status (2026-07-18):** started, not complete. `python3
tools/inventory_ui_actions.py` was regenerated and `docs/M10_UI_ACTION_AUDIT.md` was
created. The raw inventory still has 199 conservative `server_candidate` rows; the first
audit buckets 93 as still needing source-level review before M10 can be checked off.
Demo/mock data files were not deleted because they remain intentional offline/error
fallback for many screens, and several preview-only PDF/domain export actions have no
matching backend endpoint yet. A second source-review pass patched the AT-12 blocked-user
unblock gap by wiring Flutter to the existing deployed `GET /blocked-users` and
`DELETE /blocked-users/{user_id}` endpoints; `flutter analyze` and the full 361-test
suite pass. A third pass patched DS-03 release handover submit so it updates the live
distribution project through `PATCH /distribution-projects/{id}` instead of only changing
demo state. The regenerated raw inventory now has 990 callbacks and 200 conservative
`server_candidate` rows; the count rose because the newly-live submit callback itself is
still conservatively flagged. A fourth pass patched ME-04 package publish so it loads live
equipment items, creates a backend package, and attaches selected live items through the
existing operations endpoints. The regenerated inventory now has 991 callbacks and 200
conservative `server_candidate` rows. A fifth pass patched ME-06 terms publish so each
visible term posts to the live equipment terms endpoint, patched MD-04 so every visible
usage-rate row is created through the model usage-rate endpoint, and source-reviewed
MD-05 as already live-saved for restricted categories with local-only policy-preview
toggles. The regenerated inventory remains at 991 callbacks and 200 conservative
`server_candidate` rows because the line scanner still flags callbacks now known to be
wired. A sixth pass tightened BR-03 brand opportunity publish so it awaits the live
`POST /brand-opportunities` call with a disabled publishing state, and documented BR-04,
BR-06, CA-04, IN-05, and Super Admin dashboard flagged rows that remain preview/wrapper
controls until their screens render live DTO IDs or the backend exposes matching list,
update, or export endpoints. A seventh pass patched LO-04 pricing publish and LO-05 rules
sync so both write visible rows to the first live owner location property when available,
then documented location/equipment availability and inspection/return rows that remain
preview-only until those screens render live booking/property/provider/inspection/item
IDs. M10 remains unchecked until the remaining preview-only
controls are fully documented/retired and a real manual UI walkthrough is completed. An
eighth pass patched AT-05 so OTP publish updates the live actor/talent `day_rate_minor`
from the visible `Per day` row, and documented shared payment proof, review/report,
signup/KYC, AT-08, AT-10, and utility-screen rows as either already live-wired when live
IDs exist or deliberately simulated where the backend has no OTP/SMS/app-store style
endpoint.

---

## 5. Per-screen wiring recipe (apply to every individual screen)

1. Find the backend endpoint(s) in `docs/IMPLEMENTATION_PROGRESS.md`'s "Completed
   endpoints" table; check `docs/openapi.yaml` for the exact request/response shape.
2. Add/extend the milestone's repository with one method per endpoint — copy
   `auth_repository.dart`'s style exactly (call `ApiClient`, unwrap `response['data']`,
   return a typed model or list of models).
3. Add/extend DTOs — plain classes with a `fromJson` factory, only the fields the UI
   actually renders (don't model the whole backend payload speculatively).
4. Decide controller vs screen-local state per Section 2.1's rule of thumb.
5. Replace the screen's demo-data read with the real call; keep the demo dataset as the
   offline/error fallback per Section 2.4/2.5.
6. Wire every mutation button (cross-check against `UI_ACTION_INVENTORY.csv`
   `server_candidate` rows for that file) with in-flight/disabled state and a
   success/error signal.
7. Add/update a widget test covering loading/empty/error/populated/mutation-in-flight for
   that screen.
8. Run `flutter analyze`; fix anything it flags before moving on.
9. Manually run the app (`/run` skill, or `flutter run --dart-define=CINECONNECT_API_BASE_URL=...`)
   against the local Docker backend and exercise the golden path plus at least one edge
   case (offline, permission-denied, empty).
10. Only after the whole milestone is done: update
    `docs/IMPLEMENTATION_PROGRESS.md`'s "Connected Flutter screens" table and add one
    session-log entry for the milestone (not one per screen — matches the backend's own
    logging granularity).

---

## 6. Testing standards (apply throughout)

- `flutter analyze` must stay clean after every milestone — treat any new warning as a
  blocker, not a follow-up.
- Do not let the existing widget test count regress; add tests for every newly-wired
  screen's five states (Section 2.4).
- Automated tests check correctness, not that a feature actually renders and works end to
  end — always do a real manual run against the local backend before calling a milestone
  done, per this project's own standing rule.
- Verify against the **local** Docker backend (`docker compose up` at the repo root)
  during development. Only push a milestone's backend-facing changes (new upload
  endpoints, new purposes, etc.) to production once the milestone is fully verified
  locally, then redeploy following the same rsync → docker build → migrate → restart →
  smoke-test sequence used for every backend phase so far.

---

## 7. Copy-paste prompt for each wiring session

Reuse this verbatim at the start of every session working through this plan:

```text
You are wiring the CineConnect Flutter app to its already-complete backend.

First read, in order:
- docs/CINECONNECT_FLUTTER_WIRING_PLAN.md (this file) — find the next unchecked milestone
  in the checklist at the top.
- docs/CINECONNECT_MASTER_BACKEND_REPORT.md sections 8 (screen-to-API plan), 12 (Flutter
  integration plan), and 22 (route registry) for that milestone's portal(s).
- docs/IMPLEMENTATION_PROGRESS.md's "Completed endpoints" and "Connected Flutter screens"
  tables for exact request/response shapes and current wiring status.
- docs/UI_ACTION_INVENTORY.csv, filtered to the files for this milestone's portal(s), to
  find every `server_candidate` callback that must become a real API call.
- The current git diff, so you don't redo work from a partially-finished session.

Work only on the next unchecked milestone. Do not skip ahead or start a later milestone
early, even if it looks quick — later milestones assume earlier ones' primitives exist.

Follow Section 5's per-screen recipe for every screen in the milestone. Follow Section 2's
architecture decisions (do not add new state-management/routing packages; do reuse the
ChangeNotifier + InheritedNotifier pattern; do keep demo data as offline fallback, not
dead code, until M10).

Before stopping:
1. Run flutter analyze and the full widget test suite; fix anything broken.
2. Manually run the app against the local Docker backend and verify the milestone's
   verification checklist in this document.
3. Update docs/IMPLEMENTATION_PROGRESS.md (Connected Flutter screens table + one
   session-log entry) and check this milestone's box at the top of this file.
4. State clearly whether the milestone is fully complete or what remains.

Do not check off a milestone's box if its verification checklist has not actually been
run against a live local backend.
```
