# CinePlanner Complete and script studio

CinePlanner keeps its full navigation visible before a screenplay is uploaded. The workspace uses the portal's existing theme, replaces the redundant outer hero, and paginates large breakdown tables.

## Preview and membership

The authenticated API returns the first three scenes, characters and locations, plus two props and wardrobe items, for a preview account. The remaining planning modules, exports, editing and assistant endpoints require Complete access. Dashboard totals remain visible.

Complete costs USD 20 for one calendar month from finance approval and includes ten applied AI alterations. Payments use an uploaded bank-transfer receipt and a bank reference. Finance administrators and super administrators review them in the existing payment-verification screen through **Review CinePlanner subscriptions**. Approval is idempotent and reviewers cannot approve their own payment. There is no automatic renewal. Expiry returns an account to preview without deleting scripts or edits.

One applied proposal consumes one alteration, including a proposal changing multiple fields. Questions, unapplied proposals and undo do not consume an alteration. Production collaborators may use the owner's active plan; ordinary project permissions still apply. Existing manual breakdown edits are included.

`CINEPLANNER_PAYMENT_INSTRUCTIONS` provides the bank-transfer instructions. When account details have not been configured, the page directs the user to support before paying; it does not invent bank details.

Private access is entered through **Complete plan → Have an access key?**. Only an Argon2 hash is configured in `CINEPLANNER_UNLOCK_HASH` on the server. No plaintext key or default bypass is shipped in the client. The endpoint requires a signed-in account and has a rate limit. Private access covers that account's accessible productions and does not grant access to somebody else's projects.

## Long screenplays

The reader extracts every PDF page and OCRs scanned pages when needed. It identifies numbered or unnumbered scene headings and divides the source into bounded sections. Oversized scenes continue across sections with their original identity. Four structured analysis passes run per section. Completed passes are committed as checkpoints so an interrupted job resumes unfinished work.

Incomplete provider output, omitted scene identifiers and references outside the source section fail validation. Difficult sections are retried with smaller source windows. Final coverage is checked against all source scene identifiers before saving; scenes are stored in source order. Character and element references are merged across sections without a 500-scene cutoff. A superseded script analysis cannot replace the current revision's schedule.

Analysis runs in a worker; the screen polls progress and can be closed while it runs. Failed jobs have a **Resume analysis** action. The original uploaded PDF and previous script revisions are retained.

Coverage means every extracted source section was processed, not that every AI inference is correct. AI summaries, scene boundaries, continuity and production estimates remain reviewable. PDFs without recognizable scene headings are grouped by page and explicitly marked for scene-boundary review. The existing upload limit is 250 MB; password-protected PDFs must be unlocked before uploading.

## Reviewed chat edits

The script studio stores conversations on the server. A user can select a scene or describe the desired change. The assistant retrieves relevant scene context and proposes additions or updates to scenes, characters, locations or production elements. It cannot delete existing content or change financial or access settings.

Each proposal shows current and proposed field values. Nothing changes until **Apply**. The server rechecks the latest script version, permissions, membership, quota and the original values of every changed field. A stale proposal is rejected. Apply is idempotent. Undo restores only the changed fields and refuses to remove a newly added item that was subsequently modified or put in use. Unrelated later edits remain intact.

The **Working draft** download exports editable scene text. It is separate from the uploaded PDF. Older analyses without stored source text can still have breakdown fields edited, but dialogue/action rewriting and working-draft export require a new analysis of the original PDF.

## Deployment and validation

Migration `72e19d4ca031` adds scene source text, memberships, subscription payments and assistant messages. It is additive and follows `9f84c2e7a6b1`. Workers and the API must use the same release. `CINEPLANNER_TASK_QUEUE` defaults to the existing Celery queue and permits isolated candidate verification.

Validation includes backend unit/integration tests, Flutter tests, static analysis and a release build. A live original 120-page, 60-scene screenplay was uploaded, scanned and analyzed using the configured AI provider. Checks cover the final scene's source and unique prop, preview redaction, manual approval, a real reviewed AI edit, repeated apply, undo, one-time quota accounting, working-draft PDF export and the unchanged original PDF. Browser automation was unavailable; responsive layout checks use Flutter's widget renderer.
