# M10 UI Action Audit

Generated during M10 cleanup from `docs/UI_ACTION_INVENTORY.csv`.

The inventory script is deliberately conservative: it flags callbacks by line-level keywords and cannot always see that a callback delegates to an already-wired controller/repository method. This audit keeps the raw CSV intact while classifying what remains after M0–M9 wiring.

- Raw `server_candidate` rows after pass 4 regeneration: 200

## Source-review update — 2026-07-18 pass 2

The first source-level pass focused on the 93 `needs_manual_review` rows from the
initial audit, starting with rows that looked like real mutations rather than
navigation or harmless preview controls.

One true Flutter wiring gap was found and patched:

- `lib/features/actor_talent/screens/at12_safety_controls_screen.dart` no longer unblocks
  users only from `ActorTalentDemoStore`. `TrustSafetyRepository`/`TrustSafetyController`
  now expose the existing deployed `GET /blocked-users` and
  `DELETE /blocked-users/{user_id}` endpoints, and AT-12 renders/unblocks the live block
  list when an authenticated `TrustSafetyScope` is present. It keeps the previous demo
  list only as an offline/preview fallback.

Rows reviewed in this pass mostly fell into these safe categories:

- Already-wired delegates where the flagged line calls a private method or parent
  callback that already reaches a live controller/repository (`payment_proof_screen`
  picker + submit flow, AT offer reject, payout account creation, brand profile save,
  legal/admin KYC/payment decisions, model rate/restriction saves).
- Navigation/component wrappers (`navigateCoreBack`, generic card callbacks, route
  buttons).
- Deliberate local preview/configuration surfaces where there is no 1:1 backend endpoint
  yet: portfolio ordering controls, actor/crew/location/media rate-card micro-editing,
  local package/listing media previews, brand/agency demo payment verification shortcuts,
  PDF/domain-specific export buttons, and OTP-style publish confirmations used as UI
  guards around local preview state.

M10 is still not complete because the plan requires a real manual UI walkthrough and
because the raw inventory remains intentionally conservative. The next cleanup pass should
continue retiring or documenting the remaining preview-only controls, especially where a
new backend endpoint is intentionally out of scope rather than accidentally missing.

## Source-review update — 2026-07-18 pass 3

The next high-risk screen reviewed was `DS03ReleaseCoordinationScreen`. It already loaded
live distribution projects and saved draft notes through `PATCH /distribution-projects`,
but its final Submit action only changed `DistributionPartnerDemoStore`.

Patch applied:

- `lib/features/distribution_partner/screens/ds03_release_coordination_screen.dart` now
  updates the first live distribution project to `status: submitted` with the coordination
  note through `SpecialistController.updateDistributionProject(...)`.
- The submit button disables while syncing and falls back to the local demo state if the
  live API is unavailable.
- `docs/UI_ACTION_INVENTORY.csv`/`.md` were regenerated after the patch.

The raw conservative inventory now shows 990 callbacks and 200 `server_candidate` rows.
The increase is expected because the live submit callback itself is still classified by
the line-level scanner as a `server_candidate`; source review marks it as addressed.

## Source-review update — 2026-07-18 pass 4

The next high-risk screen reviewed was `ME04PackageBuilderScreen`. The deployed backend
already had `POST /equipment/packages` and
`POST /equipment/packages/{package_id}/items`, while the Flutter screen only published a
package into `MediaEquipmentDemoStore`.

Patch applied:

- `lib/features/media_equipment/screens/me04_package_builder_screen.dart` now loads live
  equipment items from `OperationsController.equipmentItems(force: true)`.
- The package builder shows a live-inventory selection section when live items are
  available.
- Final Publish now creates a backend package through
  `OperationsController.createEquipmentPackage(...)` and attaches selected live equipment
  items through `OperationsController.addEquipmentPackageItem(...)`.
- The old demo package state remains as offline/preview fallback.
- `docs/UI_ACTION_INVENTORY.csv`/`.md` were regenerated after the patch.

The raw conservative inventory now shows 991 callbacks and 200 `server_candidate` rows.
The count is stable because the newly-live `_advance` callback is still classified as a
server candidate by the line-level scanner, but source review marks ME-04 package publish
as addressed.

## Source-review update — 2026-07-18 pass 5

The next pass focused on the remaining media/equipment and model-extension rows with
matching deployed backend endpoints.

Patches applied:

- `lib/features/media_equipment/screens/me06_rate_terms_screen.dart` now publishes each
  visible term row through `OperationsController.createEquipmentTerm(...)` after the
  OTP-style confirmation, while keeping the local `MediaEquipmentDemoStore` publish state
  as fallback/preview behavior.
- `lib/features/model_extension/screens/md04_rate_by_usage_screen.dart` now loads live
  model usage rates, shows a live connection notice, and publishes every visible rate row
  through `SpecialistController.createModelUsageRate(...)` instead of creating only one
  hardcoded sample rate.

Rows reviewed but not patched in this pass:

- `lib/features/model_extension/screens/md05_brand_safety_screen.dart` already saves the
  restricted category set through `SpecialistController.updateModelRestrictedCategories`.
  The auto-flag toggles and preview labels are local policy-preview controls, not a
  separate backend mutation in the current Phase 10 API.

`docs/UI_ACTION_INVENTORY.csv`/`.md` were regenerated after the patch. The raw
conservative inventory still shows 991 callbacks and 200 `server_candidate` rows because
the scanner flags async private callbacks by keyword even when they now call live
controllers. Source review marks ME-06, MD-04, and MD-05 as addressed for this pass.

## Source-review update — 2026-07-18 pass 6

The next pass reviewed brand sponsor, casting/agency, insurance incident, and generic
admin-dashboard rows.

Patch applied:

- `lib/features/brand_sponsors/screens/br03_opportunity_composer_screen.dart` already
  called the live `POST /brand-opportunities` endpoint, but did it as a fire-and-forget
  async task while immediately updating demo state and navigating. It now awaits the live
  publish, disables the Publish button while syncing, and only falls back to the demo
  draft path if the API is unavailable.

Rows reviewed but not patched in this pass:

- `BR04ApplicationsInboxScreen` and `BR06CampaignTrackerScreen` still render demo
  application/deliverable cards. The backend has application/deliverable status endpoints,
  but these cards do not carry live backend IDs yet, so mutating them against production
  would risk writing to the wrong object. They should be refactored to render live DTOs
  before their Reject/Shortlist/Approve/Revision buttons are wired.
- `CA04CandidateShortlistScreen` similarly builds a demo shortlist from demo roster and
  audition IDs. The deployed audition-candidate endpoints require real audition and
  talent-profile IDs, so this remains a preview flow until the screen renders live
  audition/roster DTOs.
- `IN05IncidentReportsScreen` can show and locally resolve/escalate demo incident rows,
  but the current backend only exposes incident create (`POST /incidents`) and has no
  incident list/update endpoint for the insurance partner incident table. Its export
  buttons are also preview-only because Phase 12 exports currently support only `ledger`,
  `bookings`, and `admin_disputes`.
- `AdminDashboardScreen` flagged rows are route wrappers into already-live queues/details
  or preview queue snapshots; the live aggregate is already rendered by
  `_LiveAdminDashboardPanel`.

`docs/UI_ACTION_INVENTORY.csv`/`.md` were regenerated after the patch. The raw
conservative inventory still shows 991 callbacks and 200 `server_candidate` rows.

## Source-review update — 2026-07-18 pass 7

The next pass reviewed location-owner pricing/rules/availability/inspection rows and
media-equipment availability/handover/return rows.

Patches applied:

- `lib/features/location_owner/screens/lo04_pricing_deposit_screen.dart` now publishes
  every visible rate-card row to the first live owner property through
  `OperationsController.createLocationPricing(...)` after OTP confirmation. If no live
  property exists yet, it keeps the local pricing publish as preview fallback and tells
  the user to create a location first.
- `lib/features/location_owner/screens/lo05_rules_restrictions_screen.dart` now syncs
  every visible rule row to the first live owner property through
  `OperationsController.createLocationRule(...)` after OTP confirmation, with the same
  no-live-property fallback.

Rows reviewed but not patched in this pass:

- `LO03AvailabilityCalendarScreen` and `ME05AvailabilityCalendarScreen` are asset-specific
  demo calendars. The current deployed availability API is the generic user calendar from
  Phase 6, not a location-property/equipment-item availability endpoint, so these remain
  local preview controls.
- `LO07CheckInInspectionScreen`, `LO08CheckOutDamageClaimScreen`,
  `ME08HandoverChecklistScreen`, and `ME09ReturnChecklistScreen` have matching create /
  item / confirm endpoints in operations, but the visible rows are demo inspection rows
  without live booking, property/provider-profile, inspection, or equipment-item IDs.
  Wiring them without first rendering live DTO-backed inspection sessions would risk
  mutating the wrong production records.
- `CA07CommissionRecordsScreen` and `BR07PaymentsRecordsScreen` remain preview payment
  ledgers. Live payment proof/admin review and user ledger screens are already wired in
  the shared payment flows; these portal-specific demo rows do not carry live transaction
  or proof IDs for safe mutation.

`docs/UI_ACTION_INVENTORY.csv`/`.md` were regenerated after the patch. The raw
conservative inventory still shows 991 callbacks and 200 `server_candidate` rows.

## Source-review update — 2026-07-18 pass 8

The next pass reviewed shared payment/review/report flows, signup/KYC rows, and actor
talent rate/earnings/counteroffer rows.

Patch applied:

- `lib/features/actor_talent/screens/at05_rate_card_screen.dart` now publishes the
  visible `Per day` row to the canonical live actor/talent `day_rate_minor` field through
  `AuthController.updateTalentProfile(...)` after OTP confirmation. The detailed
  per-project, episode, overtime, travel, and usage rows remain local negotiation-preview
  controls because the backend does not currently expose a multi-row actor/talent rate
  table.

Rows reviewed but not patched in this pass:

- `PaymentProofUploadScreen` is already live-wired: picker uploads via
  `UploadRepository.uploadFile(...)`, and submit posts to the payment-proof endpoint when
  a live milestone is selected. The fallback path only runs when no live payment schedule
  exists.
- `RatingsReviewScreen` and `ReportBlockScreen` are already live-wired when opened with
  live booking/entity/user IDs; they explicitly warn or fallback when launched without
  those IDs.
- Signup and KYC verification rows are already connected to auth, upload, and KYC
  endpoints. The signup OTP and resend controls remain simulated UI because real OTP/SMS
  delivery was deferred in Phase 2; KYC upload actions use the real upload primitive.
- `AT08CounterofferComposerScreen` is already live-wired for booking IDs (`BKG-*`) and
  keeps demo offer IDs local. `AT10EarningsSecurityScreen` is already live-wired for
  dashboard, payout account creation, receipts, and report navigation; its receipt
  confirmation button only appears in demo fallback mode.
- Core utility-screen actions such as retry/static connection checks and app-store
  redirect are deliberate local UX placeholders.

`docs/UI_ACTION_INVENTORY.csv`/`.md` were regenerated after the patch. The raw
conservative inventory still shows 991 callbacks and 200 `server_candidate` rows; the
navigation/review split shifted by one because the scanner is line-level heuristic only.

## Source-review update — 2026-07-18 pass 9

The next pass reviewed crew-services rows plus the remaining director/producer,
distribution, legal, and super-admin wrapper rows that were still conservatively flagged.

Patch applied:

- `lib/features/crew_services/screens/cr04_availability_calendar_screen.dart` now loads
  the current user's live availability entries through `BookingsScope.availability()`,
  shows a small live-entries panel, and saves calendar status changes through
  `BookingsController.createAvailability(...)`. `available` maps to a live available
  slot, `tentative`/`booked` map to a hold, and `unavailable` maps to a blocked entry.
  The existing crew demo calendar remains as the offline/preview fallback.

Rows reviewed but not patched in this pass:

- `CR02ServiceProfileScreen` is still a crew-service profile preview. The current
  backend has KYC, marketplace, and talent profile foundations, but no dedicated crew
  service profile table/API.
- `CR03PortfolioCreditsScreen` remains local proof/ordering preview. The real portfolio
  backend is actor/model portfolio-oriented and does not yet model crew credit rows.
- `CR05RequestsNegotiationScreen` renders demo request cards without live booking IDs;
  shared booking negotiation flows are already live where a `BKG-*` ID exists.
- `CR06ContractsPaymentsScreen` delegates to shared contract/payment surfaces. Those
  shared screens are live when opened with live contract, payment schedule, and milestone
  IDs; the crew demo-store callback only preserves preview state.
- Director/Producer booking, marketplace, negotiation, project, requirement, and shortlist
  rows reviewed in this pass are already wired through their M1–M5 controllers. The
  remaining smart-filter saved-state controls are preview-only because there is no
  dedicated filter-view endpoint.
- `DS02DistributorContactsScreen` and `DS04PerformanceReportingScreen` load live data,
  but the visible demo cards do not carry live contact/report/project IDs. The backend
  exposes contact update and report create/list endpoints, but wiring these rows safely
  requires the screen to render live DTO-backed rows first.
- `LG02ContractReviewDetailScreen` is already live for legal review detail/decision.
  `LG03TemplateReviewScreen` has live template visibility but no deployed template-change
  submission endpoint, and `LG04AddendumReviewScreen` relies on shared live addendum/legal
  review flows where live IDs are present.
- Super Admin helper/detail rows reviewed here are wrappers around already-live review,
  finance, moderation, support, dashboard, analytics, or export controllers, or remain
  deliberate preview snapshots where no exact backend mutation exists.

`docs/UI_ACTION_INVENTORY.csv`/`.md` were regenerated after the patch. The raw
conservative inventory still shows 991 callbacks and 200 `server_candidate` rows because
the scanner is intentionally line-level; source review marks the CR-04 live availability
gap as addressed and the remaining rows above as documented preview/wrapper/backend-gap
controls.

## Source-review update — 2026-07-18 pass 10

The final raw-inventory sweep revisited the highest-count remaining files after pass 9.
No additional safe backend mutation was found in this sweep; the remaining flags are
scanner overreach, already-wired delegates, or controls that would require new backend
IDs/endpoints before they can be made production-safe.

Rows confirmed already wired:

- `LO02LocationListingWizardScreen` already creates a live location property, space,
  default pricing row, and default rule through `OperationsController` on Submit. Its
  draft button, media upload preview buttons, type selector, address-encryption toggle,
  power-backup toggle, and accessibility toggle are local wizard state that is included
  in the final live Submit payload where the current API supports it.
- `ME03InventoryManagerScreen` already loads live equipment inventory and creates a live
  sample equipment item through `OperationsController.createEquipmentItem(...)`. The
  filter row is local UI state, the availability toggle is preview-only because there is
  no deployed equipment item status update endpoint, and the detail-card availability
  callback lacks a live DTO-backed row ID.
- `ME02ProviderProfileScreen`, `AT02ProfileBuilderScreen`,
  `AT03PortfolioShowreelScreen`, `DPShortlistBoardScreen`, booking/chat/contract/payment,
  KYC, review, report, payout, and admin KYC/payment/moderation/detail rows are already
  live through the controller methods documented in the M0–M9 wiring entries.

Rows confirmed preview/backend-gap:

- Remaining generic `RolePortalScreen` form submit/draft actions are demo portal
  placeholders and are superseded by the dedicated role screens that were wired in M1–M9.
- Super Admin contract-template and revenue-setting buttons are preview controls: the
  backend exposes published contract-template reads and seeded fee-rule snapshots, but no
  admin template authoring or revenue-settings mutation endpoint yet.
- Remaining portal-specific export buttons are preview-only unless they use one of the
  deployed Phase 12 export types: `bookings`, `ledger`, or `admin_disputes`.
- Remaining local toggles in safety, location/equipment asset calendars, insurance
  safety/incident preview, brand/agency/demo payment rows, and model policy previews
  should not be mapped to unrelated endpoints. They need either live DTO-backed rows or a
  new backend endpoint before mutation wiring is safe.

At this point the source sweep has documented the material remaining raw candidates, but
M10 is not checked complete until a real Flutter app/device/browser walkthrough verifies
the connected UI against `https://cine.nalexustechnologies.com/api/v1`.

## Audit buckets

| Bucket | Count | Meaning |
|---|---:|---|
| `needs_manual_review` | 93 | Still needs human/source review before final zero-candidate claim. |
| `wired_or_controller_callback` | 42 | Delegates to a private callback or component callback that is already wired or requires source-level inspection rather than line-level classification. |
| `demo_store_or_local_preview` | 40 | Deliberate demo/offline fallback or local preview behavior retained until manual validation/M10 retirement decision. |
| `navigation_wrapper` | 24 | Callback wrapper around selection/navigation, not a backend mutation by itself. |

## Highest-count files still flagged by raw inventory

| Count | File |
|---:|---|
| 8 | `lib/features/director_producer/screens/dp_shortlist_board_screen.dart` |
| 8 | `lib/features/location_owner/screens/lo02_location_listing_wizard_screen.dart` |
| 6 | `lib/features/model_extension/screens/md04_rate_by_usage_screen.dart` |
| 5 | `lib/core/core_ui/screens/verification_screens.dart` |
| 5 | `lib/features/actor_talent/screens/at12_safety_controls_screen.dart` |
| 5 | `lib/features/media_equipment/screens/me06_rate_terms_screen.dart` |
| 5 | `lib/features/model_extension/screens/md05_brand_safety_screen.dart` |
| 4 | `lib/core/core_ui/screens/auth_screens.dart` |
| 4 | `lib/features/actor_talent/screens/at05_rate_card_screen.dart` |
| 4 | `lib/features/casting_agency/screens/ca04_candidate_shortlist_screen.dart` |
| 4 | `lib/features/legal_partner/screens/lg02_contract_review_detail_screen.dart` |
| 4 | `lib/features/media_equipment/screens/me04_package_builder_screen.dart` |
| 4 | `lib/features/super_admin/screens/admin_portal/admin_screen_helpers.dart` |
| 4 | `lib/features/super_admin/screens/admin_portal/payment_review_detail_screen.dart` |
| 3 | `lib/features/actor_talent/screens/at02_profile_builder_screen.dart` |
| 3 | `lib/features/actor_talent/screens/at03_portfolio_showreel_screen.dart` |
| 3 | `lib/features/brand_sponsors/screens/br02_brand_profile_screen.dart` |
| 3 | `lib/features/brand_sponsors/screens/br07_payments_records_screen.dart` |
| 3 | `lib/features/casting_agency/screens/ca07_commission_records_screen.dart` |
| 3 | `lib/features/crew_services/screens/cr04_availability_calendar_screen.dart` |
| 3 | `lib/features/director_producer/screens/dp_booking_request_form_screen.dart` |
| 3 | `lib/features/director_producer/screens/dp_negotiation_thread_screen.dart` |
| 3 | `lib/features/distribution_partner/screens/ds04_performance_reporting_screen.dart` |
| 3 | `lib/features/insurance_partner/screens/in05_incident_reports_screen.dart` |
| 3 | `lib/features/location_owner/screens/lo03_availability_calendar_screen.dart` |
| 3 | `lib/features/location_owner/screens/lo04_pricing_deposit_screen.dart` |
| 3 | `lib/features/location_owner/screens/lo05_rules_restrictions_screen.dart` |
| 3 | `lib/features/media_equipment/screens/me03_inventory_manager_screen.dart` |
| 3 | `lib/features/media_equipment/screens/me05_availability_calendar_screen.dart` |
| 3 | `lib/features/super_admin/screens/admin_portal/admin_dashboard_screen.dart` |
| 2 | `lib/core/core_payment/screens/payment_proof_screen.dart` |
| 2 | `lib/core/core_ui/widgets/core_widgets.dart` |
| 2 | `lib/features/actor_talent/screens/at08_counteroffer_composer_screen.dart` |
| 2 | `lib/features/actor_talent/screens/at10_earnings_security_screen.dart` |
| 2 | `lib/features/brand_sponsors/screens/br03_opportunity_composer_screen.dart` |
| 2 | `lib/features/brand_sponsors/screens/br04_applications_inbox_screen.dart` |
| 2 | `lib/features/crew_services/screens/cr02_service_profile_screen.dart` |
| 2 | `lib/features/crew_services/screens/cr03_portfolio_credits_screen.dart` |
| 2 | `lib/features/crew_services/screens/cr05_requests_negotiation_screen.dart` |
| 2 | `lib/features/director_producer/screens/dp_create_project_wizard_screen.dart` |

## Bucket examples

### wired_or_controller_callback

| File | Line | Source |
|---|---:|---|
| `lib/core/core_booking/screens/booking_chat_screen.dart` | 354 | `onTap: _send,` |
| `lib/core/core_payment/screens/payment_proof_screen.dart` | 285 | `onTap: _submit,` |
| `lib/core/core_safety/screens/ratings_review_screen.dart` | 192 | `onTap: _submitting ? null : _submit,` |
| `lib/core/core_safety/screens/report_block_screen.dart` | 263 | `onTap: _submitting ? null : _submit,` |
| `lib/core/core_ui/screens/auth_screens.dart` | 602 | `onTap: _loading ? null : _createAccount,` |
| `lib/core/core_ui/screens/auth_screens.dart` | 639 | `onPressed: _resendSeconds == 0 ? _startTimer : null,` |
| `lib/core/core_ui/screens/verification_screens.dart` | 274 | `onTap: _submitting ? null : _next,` |
| `lib/core/core_ui/screens/verification_screens.dart` | 307 | `onTap: _loadingUpload == null` |
| `lib/core/core_ui/screens/verification_screens.dart` | 318 | `onTap: _loadingUpload == null` |
| `lib/core/core_ui/screens/verification_screens.dart` | 393 | `onTap: _loadingUpload == null ? _captureSelfie : null,` |
| `lib/core/core_ui/screens/verification_screens.dart` | 418 | `onTap: _loadingUpload == null` |
| `lib/features/actor_talent/screens/at02_profile_builder_screen.dart` | 173 | `onTap: savingRemote ? null : _saveDraft,` |
| `lib/features/actor_talent/screens/at02_profile_builder_screen.dart` | 183 | `onTap: savingRemote ? null : _submit,` |
| `lib/features/actor_talent/screens/at03_portfolio_showreel_screen.dart` | 135 | `onDelete: () => _deleteItem(item),` |
| `lib/features/actor_talent/screens/at03_portfolio_showreel_screen.dart` | 599 | `onTap: busy ? null : onDelete,` |
| `lib/features/actor_talent/screens/at08_counteroffer_composer_screen.dart` | 120 | `onTap: _saveDraft,` |
| `lib/features/actor_talent/screens/at08_counteroffer_composer_screen.dart` | 129 | `onTap: _submit,` |
| `lib/features/brand_sponsors/screens/br03_opportunity_composer_screen.dart` | 111 | `onTap: () => _submit(context, store),` |
| `lib/features/casting_agency/screens/ca04_candidate_shortlist_screen.dart` | 125 | `onTap: () => _submit(context, store),` |
| `lib/features/crew_services/screens/cr06_contracts_payments_screen.dart` | 174 | `onSubmitted: store.uploadPaymentProof,` |

### navigation_wrapper

| File | Line | Source |
|---|---:|---|
| `lib/core/core_contract/screens/contract_viewer_screen.dart` | 526 | `onTap: onSigned,` |
| `lib/core/core_ui/widgets/core_widgets.dart` | 636 | `onTap: onTap,` |
| `lib/features/brand_sponsors/screens/br04_applications_inbox_screen.dart` | 340 | `onTap: onReject,` |
| `lib/features/brand_sponsors/screens/br06_campaign_tracker_screen.dart` | 226 | `onTap: onApprove,` |
| `lib/features/casting_agency/screens/ca02_talent_roster_screen.dart` | 341 | `onTap: onToggle,` |
| `lib/features/casting_agency/screens/ca06_selection_notes_screen.dart` | 322 | `onTap: onReject,` |
| `lib/features/crew_services/screens/cr03_portfolio_credits_screen.dart` | 259 | `onTap: onToggle,` |
| `lib/features/crew_services/screens/cr05_requests_negotiation_screen.dart` | 394 | `onTap: onReject,` |
| `lib/features/director_producer/screens/dp_booking_request_form_screen.dart` | 234 | `onTap: onSend,` |
| `lib/features/director_producer/screens/dp_negotiation_thread_screen.dart` | 420 | `onTap: onCounter,` |
| `lib/features/director_producer/screens/dp_shortlist_board_screen.dart` | 527 | `onTap: onSelect,` |
| `lib/features/distribution_partner/screens/ds02_distributor_contacts_screen.dart` | 353 | `onTap: onApprove,` |
| `lib/features/insurance_partner/screens/in02_shoot_insurance_records_screen.dart` | 358 | `onTap: onVerify,` |
| `lib/features/legal_partner/screens/lg04_addendum_review_screen.dart` | 387 | `onTap: onApprove,` |
| `lib/features/location_owner/screens/lo02_location_listing_wizard_screen.dart` | 452 | `onTap: onPhotosTap,` |
| `lib/features/location_owner/screens/lo02_location_listing_wizard_screen.dart` | 459 | `onTap: onVideoTap,` |
| `lib/features/location_owner/screens/lo06_booking_requests_screen.dart` | 419 | `onTap: onReject,` |
| `lib/features/media_equipment/screens/me03_inventory_manager_screen.dart` | 363 | `onTap: onAvailability,` |
| `lib/features/media_equipment/screens/me07_booking_requests_screen.dart` | 373 | `onTap: onReject,` |
| `lib/features/super_admin/screens/admin_portal/admin_dashboard_screen.dart` | 195 | `onTap: () => onTap(SuperAdminRoutes.paymentReview),` |

### needs_manual_review

| File | Line | Source |
|---|---:|---|
| `lib/core/core_payment/screens/payment_proof_screen.dart` | 271 | `onTap: _pickProof,` |
| `lib/core/core_ui/screens/auth_screens.dart` | 652 | `onTap: _verifyOtp,` |
| `lib/core/core_ui/widgets/core_widgets.dart` | 184 | `onTap: () => navigateCoreBack(context),` |
| `lib/features/actor_talent/screens/at02_profile_builder_screen.dart` | 195 | `onTap: savingRemote \|\| publishingListing` |
| `lib/features/actor_talent/screens/at03_portfolio_showreel_screen.dart` | 592 | `onTap: busy ? null : onMoveDown,` |
| `lib/features/actor_talent/screens/at04_availability_calendar_screen.dart` | 166 | `onTap: () {` |
| `lib/features/actor_talent/screens/at05_rate_card_screen.dart` | 53 | `onTap: () => _reauth(context),` |
| `lib/features/actor_talent/screens/at05_rate_card_screen.dart` | 207 | `onChanged: (value) =>` |
| `lib/features/actor_talent/screens/at07_offer_detail_screen.dart` | 255 | `onTap: busy ? null : () => onReject(booking),` |
| `lib/features/actor_talent/screens/at10_earnings_security_screen.dart` | 181 | `onTap: () => onCreateAccount(),` |
| `lib/features/actor_talent/screens/at12_safety_controls_screen.dart` | 221 | `onPressed: () {` |
| `lib/features/brand_sponsors/screens/br02_brand_profile_screen.dart` | 156 | `onTap: () {` |
| `lib/features/brand_sponsors/screens/br02_brand_profile_screen.dart` | 195 | `onTap: () {` |
| `lib/features/brand_sponsors/screens/br02_brand_profile_screen.dart` | 265 | `onTap: () async {` |
| `lib/features/brand_sponsors/screens/br03_opportunity_composer_screen.dart` | 99 | `onTap: () {` |
| `lib/features/brand_sponsors/screens/br05_negotiation_terms_screen.dart` | 103 | `onTap: () {` |
| `lib/features/brand_sponsors/screens/br07_payments_records_screen.dart` | 81 | `onTap: () {` |
| `lib/features/brand_sponsors/screens/br07_payments_records_screen.dart` | 316 | `onPressed: onVerify,` |
| `lib/features/casting_agency/screens/ca04_candidate_shortlist_screen.dart` | 115 | `onTap: () =>` |
| `lib/features/casting_agency/screens/ca07_commission_records_screen.dart` | 145 | `onChanged: (value) =>` |

### demo_store_or_local_preview

| File | Line | Source |
|---|---:|---|
| `lib/core/core_ui/screens/auth_screens.dart` | 292 | `onTap: _showDemoRolePicker,` |
| `lib/core/core_ui/screens/utility_screens.dart` | 134 | `onTap: () => showCoreSnack(context, 'App store redirect simulated'),` |
| `lib/features/actor_talent/screens/at05_rate_card_screen.dart` | 182 | `onPressed: () => store.updateRate(` |
| `lib/features/actor_talent/screens/at05_rate_card_screen.dart` | 192 | `onPressed: () => store.updateRate(` |
| `lib/features/actor_talent/screens/at10_earnings_security_screen.dart` | 288 | `onTap: store.receiptConfirmed` |
| `lib/features/actor_talent/screens/at12_safety_controls_screen.dart` | 34 | `onChanged: store.togglePhoneHidden,` |
| `lib/features/actor_talent/screens/at12_safety_controls_screen.dart` | 40 | `onChanged: store.toggleAdultContentBoundary,` |
| `lib/features/actor_talent/screens/at12_safety_controls_screen.dart` | 46 | `onChanged: store.toggleTravelConsent,` |
| `lib/features/actor_talent/screens/at12_safety_controls_screen.dart` | 52 | `onChanged: store.toggleEmergencySupport,` |
| `lib/features/brand_sponsors/screens/br04_applications_inbox_screen.dart` | 62 | `onTap: () => store.setApplicationsFilter(filter),` |
| `lib/features/brand_sponsors/screens/br07_payments_records_screen.dart` | 97 | `onAction: () => store.setPaymentsFilter('All'),` |
| `lib/features/casting_agency/screens/ca03_audition_request_inbox_screen.dart` | 98 | `onTap: () => store.setAuditionFilter(filter),` |
| `lib/features/casting_agency/screens/ca04_candidate_shortlist_screen.dart` | 66 | `onTap: () => store.toggleTalent(talent.id),` |
| `lib/features/casting_agency/screens/ca04_candidate_shortlist_screen.dart` | 211 | `onTap: () => store.selectAudition(audition.id),` |
| `lib/features/crew_services/screens/cr04_availability_calendar_screen.dart` | 133 | `onTap: () => store.setCalendarStatus(` |
| `lib/features/crew_services/screens/cr04_availability_calendar_screen.dart` | 145 | `onTap: () => store.setCalendarStatus(` |
| `lib/features/crew_services/screens/cr05_requests_negotiation_screen.dart` | 75 | `onTap: () => store.setRequestFilter(filter),` |
| `lib/features/distribution_partner/screens/ds02_distributor_contacts_screen.dart` | 98 | `onTap: () => store.setContactFilter(filter),` |
| `lib/features/distribution_partner/screens/ds03_release_coordination_screen.dart` | 130 | `onTap: () => store.toggleHandover(item.id),` |
| `lib/features/distribution_partner/screens/ds04_performance_reporting_screen.dart` | 109 | `onTap: () => store.setReportFilter('Submitted'),` |

## Cleanup decision for this pass

- Keep `docs/UI_ACTION_INVENTORY.csv` as the raw conservative signal.
- Use this audit to drive the final M10 manual/source review rather than deleting demo fallback files prematurely.
- Do not delete `*_demo_data.dart` yet: many screens still intentionally use them as offline/error fallback, and several backend domains do not expose PDF/domain-specific export endpoints.
- Before declaring M10 fully complete, finish source-inspecting/documenting every remaining preview-only row, patch true misses, regenerate the inventory, and complete the manual UI walkthrough.
