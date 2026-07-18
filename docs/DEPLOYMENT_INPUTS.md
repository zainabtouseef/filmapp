# CineConnect Deployment Inputs

Status values in this file are either **confirmed**, **provisional**, or
**required before the affected production feature can launch**. Secrets are
intentionally not recorded here.

## Product decisions

- Production business/legal name: CineConnect (confirmed)
- Launch country/jurisdiction: Pakistan (confirmed)
- Supported roles at first launch: all roles in the master report (provisional)
- Launch platforms: Android, iOS, web, and admin web (provisional)
- Supported languages: English (provisional)
- Default timezone: Asia/Karachi (confirmed from project context)
- Supported currencies: PKR (provisional)
- Expected launch users: required for capacity approval
- Expected monthly active users after 12 months: required for capacity approval
- Expected concurrent chat users: required for realtime capacity approval
- Expected monthly photo/video uploads: required for storage capacity approval

## Domain and HTTPS

- Production frontend domain: `cine.nalexustechnologies.com` (confirmed)
- Production API domain: `cine.nalexustechnologies.com` under `/api/v1` (confirmed)
- Admin domain: same origin under the Flutter admin routes (provisional)
- Media/CDN domain: required before production media launch
- Staging frontend domain: required
- Staging API domain: required
- DNS provider: not supplied
- TLS/certificate provider: Let's Encrypt (confirmed)
- TLS status: issued and externally verified on 2026-07-17; automatic renewal enabled; confirmed serving the deployed API over HTTPS on 2026-07-18
- Deep-link domain: `cine.nalexustechnologies.com` (provisional)

## Server

- Hosting/provider: CloudPanel-managed VPS; upstream provider not supplied; shared host with ~14 unrelated production sites (restaurant/clinic/meet/sportsmeet/etc.) for the same operator
- Region: required
- Operating system: Ubuntu 24.04.3 LTS (confirmed); kernel 6.8 observed at deploy time
- CPU / RAM / disk: 4 vCPU / 15 GiB / 193 GiB, 137 GiB free at audit; 137 GiB still free after first deploy (confirmed)
- Deployment method: Docker (plain `docker build`/`docker run`, no compose plugin installed on the host) with `--network host` so containers reach the host's existing MySQL/Redis on `127.0.0.1`; containers run `--restart unless-stopped` and Docker itself is enabled at boot (confirmed 2026-07-18)
- Application path: `/var/www/cineconnect/release` (source synced via rsync, excludes `.venv`/`__pycache__`/caches); `/var/www/cineconnect/bootstrap` retained as the Nginx document root placeholder
- Container names: `cineconnect-api` (gunicorn, bound to `127.0.0.1:5002`), `cineconnect-worker` (Celery worker), `cineconnect-scheduler` (Celery beat); port 5002 chosen because 5000/5001/5010 were already bound by other sites on this host
- Site registration: deployed via a hand-maintained Nginx vhost (`/etc/nginx/sites-available/cine.nalexustechnologies.com.conf`, backed up before edit), not through `clpctl site:add:python`/CloudPanel's native site model; no CloudPanel site user was created
- Environment label: app currently runs with `APP_ENV=development` in `/var/www/cineconnect/release/backend/.env`, not `production` &mdash; the codebase's own `Config.validate()` refuses to boot with `APP_ENV=production` while `PAYMENT_MODE=sandbox`, and payments are sandbox-only until a real gateway exists. This should be moved to `APP_ENV=staging` once the remaining environment settings are normalized.
- Public API URL for generated upload links: `API_PUBLIC_URL=https://cine.nalexustechnologies.com` (confirmed 2026-07-18); without this, presign responses emitted localhost upload URLs that fail from Flutter clients.
- SSH deployment user: root supplied for bootstrap; a restricted deploy user must replace it
- Reverse proxy/load balancer: Nginx 1.30.1 (confirmed); vhost now proxies `cine.nalexustechnologies.com` to `127.0.0.1:5002`
- Is horizontal scaling supported?: no, not with the current single-host topology
- Secret-manager location: `/var/www/cineconnect/release/backend/.env` on the server only (mode 600, root-owned), generated directly on the server and never committed; pending real secret-manager selection

## SQL database

- Engine/provider/version: local Percona Server for MySQL 8.4.7 (confirmed)
- Hostname: `127.0.0.1` on the production server (confirmed)
- Port: 3306
- Database name: supplied out of band and authenticated; all 15 Alembic migrations applied 2026-07-18 (129 tables, roles/skills/cities seed data confirmed present)
- Username: supplied out of band and authenticated; password contains `/` and must be percent-encoded (`%2F`) in the SQLAlchemy DSN
- SSL mode: local loopback only; remote database access is not approved
- Managed backups enabled?: required
- Point-in-time recovery enabled?: required
- Retention: required
- Connection limit: to be calibrated during load testing
- Secret location for password: production environment only; never committed

## Redis and workers

- Redis provider/version: local Redis 7.0.15 (confirmed); no `requirepass` set, bound to loopback only
- Hostname/port: loopback / 6379
- Logical DB indices: cineconnect uses DB 3 (app cache), DB 4 (Celery broker), DB 5 (Celery result backend) to avoid colliding with other apps sharing this Redis instance; DBs 0-2 left untouched
- TLS required?: no for loopback-only traffic
- Celery worker capacity: provisional concurrency 2; calibrate during load tests
- Celery scheduler location: production server, `cineconnect-scheduler` Docker container (confirmed 2026-07-18)
- Secret location: production environment only

## Object storage and media

- Provider: local server filesystem (confirmed 2026-07-18 from Flutter/backend wiring plan); Cloudflare R2 deferred until a later scaling phase
- Private storage root: `/var/www/cineconnect/storage/private` in production; `backend/.storage/private` for local compose
- Public storage root: `/var/www/cineconnect/storage/public` in production; `backend/.storage/public` for local compose
- Public media URL: `https://cine.nalexustechnologies.com/media`
- Supported private upload purposes currently enabled: `kyc_document`, `profile_media`, `payment_proof`, `project_document`
- CDN: deferred; Nginx serves `/media/` directly for now
- Maximum photo size: 10 MB default from master report
- Maximum video/self-tape size: 500 MB default from master report
- Malware scanning service: ClamAV worker
- Video transcoding service: FFmpeg worker
- Secret location: production environment only; storage paths are non-secret env values

## Email, SMS, and push

- Transactional email provider: Amazon SES (approved default; credentials required)
- From email/domain: `no-reply@cine.nalexustechnologies.com` (provisional; DNS verification required)
- SMS/OTP provider: disabled until a Pakistan-compliant provider/sender is approved
- Supported OTP countries: Pakistan initially
- Firebase project: Firebase Cloud Messaging approved; project credentials required
- Apple push configuration: required before iOS push launch
- Secret locations: production environment only

## Payments

- Production launch blocker: `Config.validate()` refuses to start the app with `APP_ENV=production` while `PAYMENT_MODE=sandbox`; since no real payment gateway exists yet, the 2026-07-18 deploy intentionally runs with `APP_ENV=staging` so the app boots honestly rather than bypassing this safety check
- Workflow: manual bank-transfer proof plus card, sandbox/dummy only for now
- Payment provider(s): internal sandbox adapter; real card provider required before launch
- Supported bank transfer/wallet methods: placeholder bank transfer and sandbox card; real details pending
- Who verifies manual proofs?: finance-admin role; named reviewers pending
- Refund process: required
- Payout process: required
- Platform fee policy: required
- Taxes: requires finance/legal approval
- Payment webhook URL: `https://cine.nalexustechnologies.com/api/v1/webhooks/{provider}` (reserved)
- Provider secret location: production environment only

## Privacy and safety rules

- When is phone number revealed?: after all required signatures and secured booking, to booking participants only
- When is an exact shoot address revealed?: after secured booking and no earlier than 24 hours before start, to booking participants only
- KYC document retention: 5 years after relationship end
- Contract retention: 7 years after completion/closure
- Payment record retention: 7 years after completion/closure
- Chat retention: 3 years after booking/dispute closure
- Safety/report retention: 7 years after case closure
- Account-deletion waiting period: 30 days, followed by deletion/anonymization subject to legal holds
- Required moderation SLAs: required
- Emergency escalation policy: required

## Admin structure

- Super admins: required before production accounts are created
- KYC reviewers: required
- Payment reviewers: required
- Content/listing moderators: required
- Dispute agents: required
- Support agents: required
- Legal reviewers: required
- Insurance/safety reviewers: required
- City/region restrictions per team: required

## Monitoring and operations

- Error monitoring: Sentry (approved default); SDK wired into the app (2026-07-18, safe no-op until a DSN is supplied) — DSN still required
- Logging: structured JSON to stdout (captured by Docker); off-host shipping destination required before launch
- Metrics/alerts: Prometheus-compatible metrics and Grafana dashboards; destination/contact required
- Uptime monitoring: external HTTPS probe; account/contact required
- On-call contact: required
- Backup owner: required
- Database backups: daily `mysqldump | gzip` to local disk (`/var/backups/cineconnect`, 14-day retention) running via root cron at 02:00 UTC since 2026-07-18; verified with a real 128-table dump; off-site/remote copy still required
- File-storage backups: `deploy/scripts/backup_storage.sh` archives `/var/www/cineconnect/storage` to `/var/backups/cineconnect` with 14-day local retention; cron/off-site copy still required on the server
- Desired RPO: 15 minutes (approved)
- Desired RTO: 4 hours (approved)
- Maintenance window: required

## Mobile release

- Android application ID: required
- iOS bundle ID: required
- Play Store URL: required
- App Store URL: required
- Minimum supported Android: required
- Minimum supported iOS: required
- Current minimum app version: 1.0.0 (provisional)
- Force-update policy: required

## Approvals

- Product owner: required
- Technical owner: required
- Security approver: required
- Legal/privacy approver: required
- Payment/finance approver: required
- Date approved: pending
