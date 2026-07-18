# CineConnect Deployment Inputs

Copy this file to `docs/DEPLOYMENT_INPUTS.md`, fill it in, and give it to the implementation AI together with `docs/CINECONNECT_MASTER_BACKEND_REPORT.md`.

Do not place passwords, private keys, access tokens, or full credentials in this Markdown file. State where each secret will be supplied, such as a server secret manager or an uncommitted `.env`.

## Product decisions

- Production business/legal name:
- Launch country/jurisdiction:
- Supported roles at first launch:
- Launch platforms: Android / iOS / web / admin web
- Supported languages:
- Default timezone:
- Supported currencies:
- Expected launch users:
- Expected monthly active users after 12 months:
- Expected concurrent chat users:
- Expected monthly photo/video uploads:

## Domain and HTTPS

- Production frontend domain:
- Production API domain:
- Admin domain:
- Media/CDN domain:
- Staging frontend domain:
- Staging API domain:
- DNS provider:
- TLS/certificate provider:
- Deep-link domain:

## Server

- Hosting/provider:
- Region:
- Operating system:
- CPU / RAM / disk:
- Deployment method: Docker Compose / Kubernetes / platform service / other
- SSH deployment user:
- Reverse proxy/load balancer:
- Is horizontal scaling supported?:
- Secret-manager location:

## PostgreSQL

- Provider/version:
- Hostname:
- Port:
- Database name:
- Username:
- SSL mode:
- Managed backups enabled?:
- Point-in-time recovery enabled?:
- Retention:
- Connection limit:
- Secret location for password:

## Redis and workers

- Redis provider/version:
- Hostname/port:
- TLS required?:
- Celery worker capacity:
- Celery scheduler location:
- Secret location:

## Object storage and media

- Provider:
- Region:
- Private bucket:
- Public bucket:
- CDN:
- Maximum photo size:
- Maximum video/self-tape size:
- Malware scanning service:
- Video transcoding service:
- Secret location:

## Email, SMS, and push

- Transactional email provider:
- From email/domain:
- SMS/OTP provider:
- Supported OTP countries:
- Firebase project:
- Apple push configuration:
- Secret locations:

## Payments

- Workflow: manual proof / gateway / escrow / hybrid
- Payment provider(s):
- Supported bank transfer/wallet methods:
- Who verifies manual proofs?:
- Refund process:
- Payout process:
- Platform fee policy:
- Taxes:
- Payment webhook URL:
- Provider secret location:

## Privacy and safety rules

- When is phone number revealed?:
- When is an exact shoot address revealed?:
- KYC document retention:
- Contract retention:
- Payment record retention:
- Chat retention:
- Safety/report retention:
- Account-deletion waiting period:
- Required moderation SLAs:
- Emergency escalation policy:

## Admin structure

- Super admins:
- KYC reviewers:
- Payment reviewers:
- Content/listing moderators:
- Dispute agents:
- Support agents:
- Legal reviewers:
- Insurance/safety reviewers:
- City/region restrictions per team:

## Monitoring and operations

- Error monitoring:
- Logging:
- Metrics/alerts:
- Uptime monitoring:
- On-call contact:
- Backup owner:
- Desired RPO:
- Desired RTO:
- Maintenance window:

## Mobile release

- Android application ID:
- iOS bundle ID:
- Play Store URL:
- App Store URL:
- Minimum supported Android:
- Minimum supported iOS:
- Current minimum app version:
- Force-update policy:

## Approvals

- Product owner:
- Technical owner:
- Security approver:
- Legal/privacy approver:
- Payment/finance approver:
- Date approved:

