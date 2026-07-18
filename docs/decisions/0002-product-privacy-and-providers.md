# ADR 0002: Product, privacy, retention, and provider defaults

- Status: accepted as implementation defaults; legal review required before public launch
- Date: 2026-07-17
- Product owner: user
- Business name: CineConnect
- Launch jurisdiction: Pakistan

The user authorized reasonable implementation choices where exact policies or
providers were not specified. These choices are deliberately conservative and
must remain configurable rather than being hard-coded into business logic.

## Contact and exact-address disclosure

### Decision

- A user's private phone number is visible only to authenticated participants
  of the same booking after all required contract parties have signed and the
  booking is `secured`.
- An exact shoot address is visible only to authenticated booking participants
  after the booking is `secured`, and no earlier than 24 hours before the
  scheduled start.
- Before those gates, the API returns only public contact controls and the
  approximate locality/area.
- Super-admin and assigned safety/support access requires a reason, is
  time-limited where practical, and always writes an audit event.
- Blocking, suspension, cancellation, or a safety restriction immediately
  removes ordinary access.

### Reason

This gives participants the operational information they need while reducing
pre-contract stalking, scraping, harassment, and location-security risks.
Requiring both signature and secured status is clearer and safer than relying
on a UI-only toggle.

## Retention schedule

All periods run from the later of booking completion, dispute closure, or
account-relationship end. A legal hold, court order, active investigation, or
unresolved dispute suspends deletion. Expired data is deleted or irreversibly
anonymized by a scheduled job with an audit record.

| Data class | Default retention | Reason |
|---|---:|---|
| KYC identity documents and verification history | 5 years | Conservative identity/compliance baseline; minimize after the relationship ends |
| Contracts, signatures, addendums, and consent evidence | 7 years | Supports contract enforcement, audits, and dispute history |
| Payment transactions, proofs, receipts, fees, and ledger | 7 years | Supports reconciliation, tax review, fraud investigations, and disputes |
| Booking chat and attachments | 3 years | Enough for ordinary disputes without indefinite storage |
| Safety reports, incidents, claims, and evidence | 7 years | Longer tail for injury/property/safety claims |
| Security and traffic metadata | 1 year | Security investigations and the PECA traffic-data baseline |
| General audit logs | 7 years | Admin accountability and financial/security traceability |
| Rejected upload sessions and unreferenced temporary files | 7 days | Limits unnecessary sensitive-file exposure |
| Account deletion grace period | 30 days | Allows reversal of accidental deletion and completion of active obligations |
| Operational backups | daily 35 days, monthly 12 months | Recovery without turning backups into an indefinite shadow archive |

The Electronic Transactions Ordinance supports retention of electronic records
when integrity, accessibility, provenance, and timestamps are preserved. The
Pakistan personal-data bill's data-minimization direction is used as a design
baseline even where final legal applicability requires counsel. SBP rules are
not asserted to regulate CineConnect directly; their five-year identity and
transaction baseline is used conservatively for KYC design.

Official references:

- Pakistan Electronic Transactions Ordinance, 2002:
  https://pakistancode.gov.pk/pdffiles/administratordbc98dd49f2df3b1d07bb986dcceb9a3.pdf
- Pakistan Prevention of Electronic Crimes Act, 2016:
  https://www.pakistancode.gov.pk/pdffiles/administrator6a061efe0ed5bd153fa8b79b8eb4cba7.pdf
- Pakistan draft Personal Data Protection Bill:
  https://www.moitt.gov.pk/SiteImage/Misc/files/Final%20Draft%20Personal%20Data%20Protection%20Bill%20May%202023.pdf
- SBP record-retention baseline:
  https://www.sbp.org.pk/circulars/bpd-circular-no-20-of-2004

## Payments during implementation

### Decision

- Support `manual_bank_transfer` and `card` as API/UI methods.
- Both run only through a `sandbox` provider until real provider details and
  finance approval are supplied.
- Sandbox transactions have `is_test=true`, use non-financial references, and
  display a visible "Demo payment — no money moved" notice.
- Sandbox events can exercise state machines in development/staging but cannot
  mark a production booking `secured`, create a real payout, or post production
  ledger revenue.
- The server rejects sandbox providers when `APP_ENV=production` unless an
  explicit, time-limited operations override is present. The release gate
  forbids that override for public launch.
- Manual proof verification remains an authorized finance-admin action. Card
  verification will later require a signature-verified, idempotent provider
  webhook.

### Reason

This allows the full workflow and tests to be built now without pretending that
a dummy card form or uploaded image proves that money moved.

## Service-provider defaults

| Capability | Decision | Current launch state | Reason |
|---|---|---|---|
| Object storage | Cloudflare R2 via its S3-compatible API; MinIO for local development | Credentials required | Direct presigned uploads fit the master architecture and keep media out of Flask workers |
| Public media | Separate moderated R2 bucket/custom domain | Credentials/domain required | Separates private evidence from approved public thumbnails |
| Malware scan | ClamAV worker, quarantine before ready state | Implement locally | Gives an enforceable scan gate without trusting filename/MIME claims |
| Video processing | FFmpeg Celery worker | Implement locally | Keeps transcoding outside request workers |
| Transactional email | Amazon SES over TLS SMTP | AWS/domain verification required | Standard SMTP integration with separated regional credentials |
| SMS/OTP | Provider adapter; disabled until a Pakistan-compliant sender/provider is approved | Email verification only | Pakistan sender rules and one-way limitations require commercial/provider onboarding |
| Push | Firebase Cloud Messaging | Firebase project credentials required | One supported service for Android, iOS, web, and Flutter |
| Error monitoring | Sentry | DSN required | Native Flask and Flutter error reporting with release/environment separation |
| Logs | Structured JSON to journald, shipped off-host before launch | Shipping destination required | Searchable request IDs without logging sensitive payloads |
| Metrics | Prometheus-compatible application/node metrics with Grafana dashboards | External destination required | Portable service and host monitoring |
| Uptime | External HTTPS probe from outside the VPS | Account/contact required | A same-host monitor cannot detect complete host/network failure |
| Database backup | Encrypted nightly MySQL logical backup plus binary-log archive to R2 | R2 credentials required | Supports off-host recovery and point-in-time restoration |

Cloudflare documents S3-compatible presigned PUT/GET URLs, which directly fits
the signed-upload requirement:
https://developers.cloudflare.com/r2/api/s3/presigned-urls/

Firebase documents FCM as a cross-platform service including Flutter:
https://firebase.google.com/docs/cloud-messaging

MySQL documents full backup plus binary-log replay for point-in-time recovery:
https://dev.mysql.com/doc/refman/8.4/en/point-in-time-recovery.html

Amazon SES requires distinct regional SMTP credentials and TLS:
https://docs.aws.amazon.com/ses/latest/dg/smtp-connect.html

## Backup and recovery policy

- Desired RPO: 15 minutes.
- Desired RTO: 4 hours.
- Nightly encrypted full database backup.
- Binary logs copied off-host at least every 15 minutes.
- Daily backups retained 35 days; monthly restore points retained 12 months.
- Object-versioning and lifecycle rules protect media metadata and evidence.
- Automated integrity checks run after every backup.
- A restore rehearsal into an isolated database runs quarterly and before a
  major production release.
- Backup access uses a dedicated least-privilege credential and is never shared
  with the application upload credential.

## Open approvals that still require accounts or credentials

Implementation may proceed with provider interfaces and local substitutes, but
public production launch still requires:

- Cloudflare account, R2 buckets, API credentials, and media domain;
- Firebase project and service-account credentials;
- Amazon SES account, verified sending domain, and SMTP credentials;
- an approved Pakistan SMS/OTP provider and registered sender identity;
- Sentry/metrics/logging/uptime accounts and alert recipients;
- named super admins, reviewers, support contacts, and an on-call owner;
- real bank-transfer instructions and a real card-payment provider.

