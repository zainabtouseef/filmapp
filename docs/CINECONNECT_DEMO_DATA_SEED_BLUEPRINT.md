# CineConnect Demo Data Seed Blueprint

Generated: 2026-07-18  
Purpose: provide a complete, AI-friendly seed-data plan so another AI/database agent can populate CineConnect with realistic linked data and make every portal visibly functional for demos.  
Target API/database: `https://cine.nalexustechnologies.com/api/v1` / production-shaped MySQL schema  
Business: CineConnect

> Security note: do not put real passwords, real KYC documents, real bank accounts, or private phone numbers in demo data. Use synthetic files and clearly marked test identities.

---

## 1. How the seeding AI should use this document

This is not a random mock-data list. It is a linked scenario graph. The seed agent should create records in the order below so each portal has visible data connected to the same productions, users, bookings, contracts, payments, disputes, reports, and dashboards.

Recommended execution mode:

1. Use backend factories/API endpoints where available.
2. Use direct SQL only when an endpoint does not exist or when creating historical/demo-only rows.
3. Preserve the public IDs suggested here where possible. If the schema auto-generates public IDs, write an ID mapping file after insert.
4. Insert 10 demo records for each major portal domain. Super Admin needs only one admin user, but should see queues populated by everyone else’s records.
5. Use the same 10 production backbone records across portals so the app feels coherent.
6. After seeding, run API health and sample list endpoints to confirm counts.

Recommended seed tag on every insert that supports notes/metadata:

- `seed_batch`: `cineconnect-demo-2026-07-18`
- `is_demo`: `true`
- `created_by_seed`: `CINECONNECT_DEMO_DATA_SEED_BLUEPRINT`

---

## 2. Global demo backbone

Use these 10 productions as the spine for all screens.

| ID | Project title | Type | City | Status | Director/producer | Hero talent | Location | Equipment package | Brand/partner |
|---|---|---|---|---|---|---|---|---|---|
| `DEMO-PROJ-001` | River Lights | Feature film | Lahore | active | Sara Nadeem | Ayaan Malik | Haveli Gulberg | Alexa Mini LF Kit | Nova Cola |
| `DEMO-PROJ-002` | City of Dust | TV drama | Karachi | casting | Hamza Rafiq | Meher Shah | Saddar Rooftop | Sony FX6 Doc Kit | Zest Telecom |
| `DEMO-PROJ-003` | Blue Van | Commercial | Islamabad | secured | Noor Khan | Zain Javed | Margalla Farmhouse | Drone + Gimbal Pack | Orion Bank |
| `DEMO-PROJ-004` | Eid Run | Music video | Lahore | negotiating | Bilal Qureshi | Hira Salman | Old City Street Set | Lighting Sprint Pack | Naya Wear |
| `DEMO-PROJ-005` | Salt Road | Documentary | Gwadar | preprod | Mahnoor Ali | Faris Sheikh | Coastal Warehouse | Documentary Sound Kit | TravelPK |
| `DEMO-PROJ-006` | Campus Beat | Web series | Karachi | active | Umer Siddiqui | Sana Mirza | University Courtyard | Multi-cam Podcast Kit | ByteCafe |
| `DEMO-PROJ-007` | Night Bazaar | Short film | Rawalpindi | review | Daniyal Hussain | Omar Rehman | Bazaar Backlot | Low-light Cinema Kit | Indie Fund |
| `DEMO-PROJ-008` | Monsoon Menu | Food campaign | Lahore | delivered | Amina Farooq | Laila Noor | Studio Kitchen | Tabletop Food Kit | Masala House |
| `DEMO-PROJ-009` | Safe Set PSA | Safety PSA | Islamabad | incident_review | Kamil Ahmed | Mariam Tariq | Hospital Training Wing | Compact ENG Kit | InsurePro |
| `DEMO-PROJ-010` | Desert Echo | OTT pilot | Bahawalpur | distribution | Reema Iqbal | Taha Baig | Desert Fort | Remote Production Kit | StreamSphere |

---

## 3. Seed insertion order

| Step | Seed area | Why first |
|---:|---|---|
| 1 | Countries/cities/reference skills | Required by profiles and listings |
| 2 | Users and roles | Required by every owned record |
| 3 | Base profiles and KYC submissions | Powers auth/profile/admin queues |
| 4 | Talent/model/crew/location/equipment/agency/brand/legal/insurance/distribution profiles | Portal foundations |
| 5 | Files/upload sessions with synthetic ready files | Needed for KYC, portfolio, project room, proofs, evidence |
| 6 | Marketplace listings and portfolio/showreel | Needed for discovery and bookings |
| 7 | Projects, members, requirements, room items/files | Director/Producer foundation |
| 8 | Saved searches, shortlists, shortlist items | Marketplace and shortlist board |
| 9 | Bookings, offers, negotiations, availability, conversations | Booking/chat/calendar flows |
| 10 | Contracts, signatures, legal reviews, addendums | Legal and signing flows |
| 11 | Payment schedules, proofs, receipts, ledger, payout accounts | Finance flows |
| 12 | Location/equipment inspections, claims, safety checks/incidents | Operations/insurance flows |
| 13 | Agency, brand, model, distribution extension records | Specialist portals |
| 14 | Reviews, reports, blocks, moderation, disputes, support, announcements, notifications | Trust/safety and admin queues |
| 15 | Dashboard/export records | Final admin/personal dashboard polish |

---

## 4. Users and roles to create

Create one Super Admin and at least 10 users for every major visible role group. Passwords should be generated by the seed agent and stored only in a local secure handoff file, not in this report.

### 4.1 Super Admin

| Public ID | Display name | Email | Role | Purpose |
|---|---|---|---|---|
| `DEMO-ADMIN-001` | CineConnect Demo Admin | `demo.admin@cineconnect.test` | super_admin | One admin account to view all queues, dashboards, disputes, payments, KYC, support, broadcasts |

### 4.2 Director/Producer users

| Public ID | Name | Email | Linked project |
|---|---|---|---|
| `DEMO-DP-001` | Sara Nadeem | `sara.dp@cineconnect.test` | `DEMO-PROJ-001` |
| `DEMO-DP-002` | Hamza Rafiq | `hamza.dp@cineconnect.test` | `DEMO-PROJ-002` |
| `DEMO-DP-003` | Noor Khan | `noor.dp@cineconnect.test` | `DEMO-PROJ-003` |
| `DEMO-DP-004` | Bilal Qureshi | `bilal.dp@cineconnect.test` | `DEMO-PROJ-004` |
| `DEMO-DP-005` | Mahnoor Ali | `mahnoor.dp@cineconnect.test` | `DEMO-PROJ-005` |
| `DEMO-DP-006` | Umer Siddiqui | `umer.dp@cineconnect.test` | `DEMO-PROJ-006` |
| `DEMO-DP-007` | Daniyal Hussain | `daniyal.dp@cineconnect.test` | `DEMO-PROJ-007` |
| `DEMO-DP-008` | Amina Farooq | `amina.dp@cineconnect.test` | `DEMO-PROJ-008` |
| `DEMO-DP-009` | Kamil Ahmed | `kamil.dp@cineconnect.test` | `DEMO-PROJ-009` |
| `DEMO-DP-010` | Reema Iqbal | `reema.dp@cineconnect.test` | `DEMO-PROJ-010` |

### 4.3 Actor/Talent users

| Public ID | Name | Category | City | Linked project |
|---|---|---|---|---|
| `DEMO-AT-001` | Ayaan Malik | Lead actor | Lahore | `DEMO-PROJ-001` |
| `DEMO-AT-002` | Meher Shah | Supporting actor | Karachi | `DEMO-PROJ-002` |
| `DEMO-AT-003` | Zain Javed | Commercial face | Islamabad | `DEMO-PROJ-003` |
| `DEMO-AT-004` | Hira Salman | Dancer/performer | Lahore | `DEMO-PROJ-004` |
| `DEMO-AT-005` | Faris Sheikh | Documentary presenter | Gwadar | `DEMO-PROJ-005` |
| `DEMO-AT-006` | Sana Mirza | Web-series actor | Karachi | `DEMO-PROJ-006` |
| `DEMO-AT-007` | Omar Rehman | Character actor | Rawalpindi | `DEMO-PROJ-007` |
| `DEMO-AT-008` | Laila Noor | Food/lifestyle host | Lahore | `DEMO-PROJ-008` |
| `DEMO-AT-009` | Mariam Tariq | PSA presenter | Islamabad | `DEMO-PROJ-009` |
| `DEMO-AT-010` | Taha Baig | OTT actor | Bahawalpur | `DEMO-PROJ-010` |

### 4.4 Other portal owner users

Create 10 users each for:

- Model Extension: `DEMO-MD-001` … `DEMO-MD-010`
- Location Owner: `DEMO-LO-001` … `DEMO-LO-010`
- Media/Equipment Provider: `DEMO-ME-001` … `DEMO-ME-010`
- Crew Services: `DEMO-CR-001` … `DEMO-CR-010`
- Casting Agency: `DEMO-CA-001` … `DEMO-CA-010`
- Brand Sponsor: `DEMO-BR-001` … `DEMO-BR-010`
- Legal Partner: `DEMO-LG-001` … `DEMO-LG-010`
- Insurance Partner: `DEMO-IN-001` … `DEMO-IN-010`
- Distribution Partner: `DEMO-DS-001` … `DEMO-DS-010`

Use matching synthetic emails, for example `model01@cineconnect.test`, `location01@cineconnect.test`, and so on.

---

## 5. Shared files required for demo visibility

Create synthetic ready files. These can all point to small placeholder PDFs/JPGs/MP4 metadata in local storage; the demo only needs realistic file rows and download URLs.

| File group | Count | Purpose |
|---|---:|---|
| KYC ID front/back/selfie | 30 | At least 10 KYC submissions, plus admin queue variety |
| Portfolio photos | 30 | Actor/model/crew marketplace profiles |
| Showreel videos | 10 | AT-03, CA-05, marketplace detail |
| Project documents | 20 | DP room/files, contracts, legal review |
| Location photos/videos | 30 | LO listing wizard/performance |
| Equipment photos | 30 | ME inventory/packages/handover/return |
| Payment proofs | 20 | Payment proof screens and admin review |
| Insurance evidence | 20 | Claims/incidents/safety checks |
| Brand campaign proofs | 20 | BR campaign tracker/payments |
| Distribution report CSV/PDF placeholders | 10 | DS reports |

Suggested naming:

- `DEMO-FILE-KYC-001-FRONT`
- `DEMO-FILE-PORTFOLIO-001-A`
- `DEMO-FILE-PROJECT-001-SCRIPT`
- `DEMO-FILE-PAYMENT-001-PROOF`

---

## 6. Core/shared screens data requirements

| Screen | Route | Required demo data |
|---|---|---|
| Splash/bootstrap | `/` | Public config, roles, healthy API |
| Onboarding | `/onboarding` | Role list, app copy |
| Role selection | `/roles` | Granted roles per demo user |
| Login/signup/forgot | `/login`, `/signup`, `/forgot-password` | Demo users; password reset token rows optional |
| KYC upload/status | `/verification/upload`, `/verification/status` | KYC submissions, documents, selfie files, statuses: draft/submitted/approved/rejected |
| Notifications | `/notifications` | 10 notifications across booking/payment/support/announcement |
| Chat | `/booking/chat` | Conversations, 10 messages per active booking |
| Contract viewer | `/contract` | Generated contracts, parties, clauses, signatures |
| Payment proof | `/payments/proof` | Payment milestones and proof file sessions |
| Ledger | `/payments/ledger` | Receipt and ledger rows |
| Review | `/review` | Eligible completed bookings and review requests |
| Report/block | `/report` | Report reasons, blocked users |
| Settings | `/settings` | User preferences/session info |
| Dashboard | `/portal/dashboard` | `/me/dashboard` metrics populated from projects/bookings/payments |

---

## 7. Director/Producer portal seed pack

Minimum records: 10 projects, 20 requirements, 20 project-room items, 10 saved searches, 10 shortlists, 20 shortlist items, 10 booking requests.

| Screen | Route | Data to seed |
|---|---|---|
| DP home | `/director` | Dashboard metrics from 10 projects, bookings, payments |
| Projects list | `/director/projects` | 10 projects from global backbone |
| Create project | `/director/projects/create` | Reference cities/types/skills; no preseed needed except dropdown data |
| Project detail | `/director/projects/:id` | Project members, status notes, budget/date fields |
| Requirements | `/director/projects/:id/requirements` | 2 requirements per project: actor/model/crew/location/equipment |
| Marketplace | `/director/marketplace` | Published listings from talent, location, equipment, crew |
| Smart filters | `/director/marketplace/filters` | Saved filter presets and city/category facets |
| Stakeholder profile | `/director/profile/:id` | Public profiles with portfolio, ratings, availability |
| Shortlist board | `/director/shortlist` | 10 saved searches, 10 shortlists, 20 shortlist items |
| Booking request | `/director/booking-request` | Project + listing seed objects ready for request |
| Bargaining center | `/director/bargaining` | 10 negotiation threads |
| Negotiation thread | `/director/bargaining/:id` | 3 rounds per selected thread |
| Contracts | `/director/contracts` | 10 contracts, mixed draft/signed/legal-review |
| Payments | `/director/payments` | 10 payment schedules, 20 milestones |
| Schedule | `/director/schedule` | Availability entries and accepted bookings |
| Accounts | `/director/accounts` | Project account/budget snapshots |
| Project room | `/director/room` | Files, decisions, pinned notes |
| Reports | `/director/reports` | Supported CSV export jobs: bookings/ledger |

### 10 Director/Producer records

| ID | Seed record |
|---|---|
| `DEMO-DP-SEED-001` | `DEMO-PROJ-001` with 3 requirements, 2 shortlisted actors, active booking with `DEMO-AT-001` |
| `DEMO-DP-SEED-002` | `DEMO-PROJ-002` with open casting requirement and negotiation with `DEMO-AT-002` |
| `DEMO-DP-SEED-003` | `DEMO-PROJ-003` with secured commercial booking, payment pending |
| `DEMO-DP-SEED-004` | `DEMO-PROJ-004` with counteroffer thread and contract draft |
| `DEMO-DP-SEED-005` | `DEMO-PROJ-005` with project room documentary files |
| `DEMO-DP-SEED-006` | `DEMO-PROJ-006` with multi-cast shortlist and chat thread |
| `DEMO-DP-SEED-007` | `DEMO-PROJ-007` with legal review required |
| `DEMO-DP-SEED-008` | `DEMO-PROJ-008` with completed booking and review eligibility |
| `DEMO-DP-SEED-009` | `DEMO-PROJ-009` with incident/dispute linked |
| `DEMO-DP-SEED-010` | `DEMO-PROJ-010` with distribution handover linked |

---

## 8. Actor/Talent portal seed pack

Minimum records: 10 talent profiles, 30 portfolio items, 10 showreels, 20 availability entries, 10 offers/bookings, 10 contracts, 10 reviews, 10 safety/report rows.

| Screen | Route | Data to seed |
|---|---|---|
| AT-01 Dashboard | `/talent` | Active offers, earnings, rating, upcoming bookings |
| AT-02 Profile Builder | `/talent/profile` | Base profile, talent profile, published listing |
| AT-03 Portfolio & Showreel | `/talent/portfolio` | 3 portfolio items + 1 showreel per talent |
| AT-04 Availability Calendar | `/talent/availability` | Manual availability plus locked booking dates |
| AT-05 Rate Card | `/talent/rates` | Day/session/usage rates; currently partly preview if no endpoint |
| AT-06 Opportunity Inbox | `/talent/opportunities` | Provider-side booking offers |
| AT-07 Offer Detail | `/talent/offers/:id` | 10 bookings with offered/accepted/rejected/counter statuses |
| AT-08 Counteroffer | `/talent/counteroffer` | Negotiation thread and booking ID |
| AT-09 Contract Signing | `/talent/contracts` | Contracts requiring talent signature |
| AT-10 Earnings Security | `/talent/earnings` | Payment dashboard, payout account, receipts |
| AT-11 Reputation | `/talent/reputation` | Reviews and rating average |
| AT-12 Safety Controls | `/talent/safety` | Blocked users, report reasons, safety settings |

### 10 Actor/Talent records

| Talent | Seed scenario |
|---|---|
| `DEMO-AT-001` | Approved KYC, published lead actor listing, accepted booking, signed contract |
| `DEMO-AT-002` | Submitted KYC, active offer pending response |
| `DEMO-AT-003` | Approved commercial profile, payment proof pending |
| `DEMO-AT-004` | Counteroffer thread active |
| `DEMO-AT-005` | Documentary presenter with travel consent required |
| `DEMO-AT-006` | Web-series actor with recurring availability blocks |
| `DEMO-AT-007` | Legal review hold on contract |
| `DEMO-AT-008` | Completed job, review request open |
| `DEMO-AT-009` | Safety incident/report linked |
| `DEMO-AT-010` | Distribution/OTT project contract signed |

---

## 9. Model Extension portal seed pack

Minimum records: 10 model profiles, 10 campaign-category sets, 20 usage rights, 20 usage rates, 20 restricted categories, 20 portfolio category rows.

| Screen | Route | Data to seed |
|---|---|---|
| MD-01 Campaign Categories | `/model` | Model profile + selected commercial/editorial/ecommerce categories |
| MD-02 Usage Rights | `/model/usage-rights` | Territory, duration, exclusivity rights |
| MD-03 Portfolio Categories | `/model/portfolio-categories` | Portfolio buckets and active samples |
| MD-04 Rate by Usage | `/model/rate-by-usage` | Usage-specific rates: social, billboard, OTT, print |
| MD-05 Brand Safety | `/model/brand-safety` | Restricted industries/categories and brand-safety notes |

### 10 Model Extension records

| ID | Scenario |
|---|---|
| `DEMO-MD-SEED-001` | Beauty campaign model, Pakistan social 6-month usage |
| `DEMO-MD-SEED-002` | Fashion editorial, print + digital bundle |
| `DEMO-MD-SEED-003` | Fitness model, excludes tobacco/alcohol |
| `DEMO-MD-SEED-004` | Lifestyle parent model, family-safe only |
| `DEMO-MD-SEED-005` | Luxury product model, exclusivity premium |
| `DEMO-MD-SEED-006` | Ecommerce catalog model, per-SKU pricing |
| `DEMO-MD-SEED-007` | Automotive model, billboard usage |
| `DEMO-MD-SEED-008` | Food campaign model, short social clips |
| `DEMO-MD-SEED-009` | PSA model, nonprofit discount |
| `DEMO-MD-SEED-010` | OTT promo model, regional digital rights |

---

## 10. Location Owner portal seed pack

Minimum records: 10 properties, 20 spaces, 20 pricing/rule rows, 30 availability entries, 10 booking requests, 10 inspections, 5 damage claims.

| Screen | Route | Data to seed |
|---|---|---|
| LO-01 Dashboard | `/location-owner` | Property metrics, upcoming shoots, earnings |
| LO-02 Listing Wizard | `/location-owner/listing-wizard` | Property, spaces, photos/video, encrypted exact address |
| LO-03 Availability Calendar | `/location-owner/availability` | Available/blocked/booked/maintenance entries |
| LO-04 Pricing & Deposit | `/location-owner/pricing` | Day rate, overtime, cleaning, security deposit |
| LO-05 Rules & Restrictions | `/location-owner/rules` | Noise, fire, parking, drone, night-shoot rules |
| LO-06 Booking Requests | `/location-owner/requests` | Location booking requests linked to projects |
| LO-07 Check-In Inspection | `/location-owner/check-in` | Before-shoot inspection photos/checklist |
| LO-08 Check-Out Claim | `/location-owner/check-out` | After-shoot inspection and damage claim |
| LO-09 Earnings & Deposits | `/location-owner/earnings` | Receipts, held deposits, released deposits |
| LO-10 Property Performance | `/location-owner/performance` | Occupancy, revenue, repeat bookings |

### 10 Location records

| Location | Demo scenario |
|---|---|
| `DEMO-LOC-001` Haveli Gulberg | Booked for `DEMO-PROJ-001`, deposit pending |
| `DEMO-LOC-002` Saddar Rooftop | Open booking requests |
| `DEMO-LOC-003` Margalla Farmhouse | Secured commercial shoot |
| `DEMO-LOC-004` Old City Street Set | Night-shoot restriction |
| `DEMO-LOC-005` Coastal Warehouse | Travel logistics note |
| `DEMO-LOC-006` University Courtyard | Maintenance block |
| `DEMO-LOC-007` Bazaar Backlot | Legal rule addendum |
| `DEMO-LOC-008` Studio Kitchen | Completed food campaign |
| `DEMO-LOC-009` Hospital Training Wing | Safety incident linked |
| `DEMO-LOC-010` Desert Fort | Distribution/OTT pilot shoot |

---

## 11. Media/Equipment portal seed pack

Minimum records: 10 provider profiles, 30 inventory items, 10 packages, 20 terms, 30 availability entries, 10 booking requests, 10 handovers, 10 returns, 5 damage claims.

| Screen | Route | Data to seed |
|---|---|---|
| ME-01 Dashboard | `/equipment-provider` | Inventory count, requests, earnings |
| ME-02 Provider Profile | `/equipment-provider/profile` | Provider profile, coverage, verification |
| ME-03 Inventory Manager | `/equipment-provider/inventory` | Cameras/lights/sound/drones with photos |
| ME-04 Package Builder | `/equipment-provider/packages` | Bundled kits linked to inventory |
| ME-05 Availability Calendar | `/equipment-provider/availability` | Available/booked/maintenance entries |
| ME-06 Rate & Terms | `/equipment-provider/terms` | Rates, operator, damage, cancellation terms |
| ME-07 Requests & Negotiation | `/equipment-provider/requests` | Equipment bookings and negotiation states |
| ME-08 Handover Checklist | `/equipment-provider/handover` | Outgoing inspection checklist |
| ME-09 Return Checklist | `/equipment-provider/return` | Return match/missing/damage states |
| ME-10 Earnings & Ratings | `/equipment-provider/earnings` | Receipts, ratings, repeat client metrics |

### 10 Equipment package records

| Package | Demo scenario |
|---|---|
| `DEMO-ME-PKG-001` Alexa Mini LF Kit | Booked for River Lights |
| `DEMO-ME-PKG-002` Sony FX6 Doc Kit | Pending booking request |
| `DEMO-ME-PKG-003` Drone + Gimbal Pack | Secured commercial |
| `DEMO-ME-PKG-004` Lighting Sprint Pack | Negotiation active |
| `DEMO-ME-PKG-005` Documentary Sound Kit | Travel surcharge |
| `DEMO-ME-PKG-006` Multi-cam Podcast Kit | Weekly recurring rental |
| `DEMO-ME-PKG-007` Low-light Cinema Kit | Legal/insurance hold |
| `DEMO-ME-PKG-008` Tabletop Food Kit | Completed, review pending |
| `DEMO-ME-PKG-009` Compact ENG Kit | Incident evidence linked |
| `DEMO-ME-PKG-010` Remote Production Kit | Distribution project handover |

---

## 12. Crew Services portal seed pack

Minimum records: 10 crew profiles, 30 credits, 20 portfolio proofs, 30 availability entries, 10 booking requests, 10 contracts/payments, 10 reviews.

| Screen | Route | Data to seed |
|---|---|---|
| CR-01 Dashboard | `/crew` | Requests, upcoming shoots, earnings |
| CR-02 Service Profile | `/crew/profile` | Service type, city coverage, rate snapshot |
| CR-03 Portfolio & Credits | `/crew/portfolio` | Credits and proof files |
| CR-04 Availability Calendar | `/crew/availability` | Available/blocked/booked entries |
| CR-05 Requests & Negotiation | `/crew/requests` | Crew booking requests |
| CR-06 Contracts & Payments | `/crew/contracts-payments` | Contracts, payment proofs, receipts |
| CR-07 Ratings & Work History | `/crew/ratings` | Reviews and work history |

### 10 Crew records

| ID | Service | Linked project |
|---|---|---|
| `DEMO-CR-001` | 1st AD team | `DEMO-PROJ-001` |
| `DEMO-CR-002` | Location sound | `DEMO-PROJ-002` |
| `DEMO-CR-003` | Drone operator | `DEMO-PROJ-003` |
| `DEMO-CR-004` | Choreography crew | `DEMO-PROJ-004` |
| `DEMO-CR-005` | Documentary fixer | `DEMO-PROJ-005` |
| `DEMO-CR-006` | Multi-cam operators | `DEMO-PROJ-006` |
| `DEMO-CR-007` | Night lighting crew | `DEMO-PROJ-007` |
| `DEMO-CR-008` | Food stylist team | `DEMO-PROJ-008` |
| `DEMO-CR-009` | Safety marshal | `DEMO-PROJ-009` |
| `DEMO-CR-010` | Remote production coordinator | `DEMO-PROJ-010` |

---

## 13. Casting Agency portal seed pack

Minimum records: 10 agency profiles, 30 roster talent links, 10 audition requests, 30 candidates, 20 self-tapes, 20 selection notes, 10 commission records.

| Screen | Route | Data to seed |
|---|---|---|
| CA-01 Dashboard | `/agency` | Auditions, roster size, commission metrics |
| CA-02 Talent Roster Manager | `/agency/roster` | 30 roster entries across 10 agencies |
| CA-03 Audition Request Inbox | `/agency/auditions` | 10 audition requests from projects |
| CA-04 Candidate Shortlist Builder | `/agency/shortlist` | Candidate picks linked to auditions |
| CA-05 Self-Tape Collection | `/agency/self-tapes` | Self-tape files and transcripts |
| CA-06 Interview & Selection Notes | `/agency/selection-notes` | Director/agency notes |
| CA-07 Commission Settings & Records | `/agency/commission` | Commission percent and payment rows |
| CA-08 Agency Booking Records | `/agency/records` | Booked/paid/disputed records |

### 10 Casting Agency records

| ID | Agency | Specialty |
|---|---|---|
| `DEMO-CA-001` | North Star Casting | Film leads |
| `DEMO-CA-002` | Karachi Screen Faces | Drama actors |
| `DEMO-CA-003` | AdCast Studio | Commercial talent |
| `DEMO-CA-004` | Rhythm Casting | Dancers/performers |
| `DEMO-CA-005` | Real People Network | Documentary subjects |
| `DEMO-CA-006` | Campus Talent Desk | Youth actors |
| `DEMO-CA-007` | Character Room | Character actors |
| `DEMO-CA-008` | Lifestyle Hosts PK | Hosts/presenters |
| `DEMO-CA-009` | Public Impact Casting | PSA talent |
| `DEMO-CA-010` | OTT Launch Casting | Series ensemble |

---

## 14. Brand Sponsor portal seed pack

Minimum records: 10 brand profiles, 10 opportunities, 30 applications, 10 terms records, 20 deliverables, 20 metrics rows, 10 payment records.

| Screen | Route | Data to seed |
|---|---|---|
| BR-01 Dashboard | `/brand` | Opportunities, applications, campaign metrics |
| BR-02 Brand Profile | `/brand/profile` | Brand identity, billing placeholder, logo file |
| BR-03 Opportunity Composer | `/brand/opportunity-composer` | Reference categories/budget examples |
| BR-04 Applications Inbox | `/brand/applications` | 30 applications across opportunities |
| BR-05 Negotiation & Terms | `/brand/negotiation` | Brand/talent term records |
| BR-06 Campaign Tracker | `/brand/campaign-tracker` | Deliverables and approval states |
| BR-07 Payments & Records | `/brand/payments` | Brand campaign payment/receipt rows |

### 10 Brand records

| ID | Brand | Campaign |
|---|---|---|
| `DEMO-BR-001` | Nova Cola | Summer Launch |
| `DEMO-BR-002` | Zest Telecom | City Connectivity |
| `DEMO-BR-003` | Orion Bank | Secure Future |
| `DEMO-BR-004` | Naya Wear | Eid Street Style |
| `DEMO-BR-005` | TravelPK | Coastal Stories |
| `DEMO-BR-006` | ByteCafe | Campus Creators |
| `DEMO-BR-007` | Indie Fund | Night Bazaar BTS |
| `DEMO-BR-008` | Masala House | Monsoon Menu |
| `DEMO-BR-009` | InsurePro | Safe Set PSA |
| `DEMO-BR-010` | StreamSphere | Desert Echo Launch |

---

## 15. Legal Partner portal seed pack

Minimum records: 10 legal partner profiles, 10 contract templates, 20 legal review requests, 20 risk rows, 10 addendums, 10 billing records.

| Screen | Route | Data to seed |
|---|---|---|
| LG-01 Dashboard | `/legal` | Open reviews, risk counts, billing |
| LG-02 Contract Review Request Detail | `/legal/contract-review` | Legal review details with approve/reject states |
| LG-03 Template Review | `/legal/template-review` | Contract templates and clauses |
| LG-04 Addendum Review | `/legal/addendum-review` | Addendum requests |
| LG-05 Review History & Billing | `/legal/history-billing` | Completed reviews and billing rows |

### 10 Legal records

| ID | Scenario |
|---|---|
| `DEMO-LG-001` | Actor contract review for River Lights |
| `DEMO-LG-002` | Location agreement review for City of Dust |
| `DEMO-LG-003` | Brand usage rights review for Blue Van |
| `DEMO-LG-004` | Music video performer addendum |
| `DEMO-LG-005` | Documentary travel indemnity |
| `DEMO-LG-006` | Web series ensemble contract |
| `DEMO-LG-007` | Night shoot safety clause |
| `DEMO-LG-008` | Food campaign brand approvals |
| `DEMO-LG-009` | Incident dispute legal note |
| `DEMO-LG-010` | Distribution holdback clause |

---

## 16. Insurance Partner portal seed pack

Minimum records: 10 insurance profiles/policies, 10 claims, 20 claim evidence rows, 10 safety checks, 10 incident reports.

| Screen | Route | Data to seed |
|---|---|---|
| IN-01 Dashboard | `/insurance` | Policies, claims, safety metrics |
| IN-02 Shoot Insurance Records | `/insurance/records` | 10 policies linked to projects |
| IN-03 Claim Support | `/insurance/claims` | 10 claims and evidence |
| IN-04 Safety Checks & Permits | `/insurance/safety-permits` | Safety check items and permit status |
| IN-05 Incident Reports | `/insurance/incidents` | 10 incident reports, mixed severity/resolved |

### 10 Insurance records

| ID | Scenario |
|---|---|
| `DEMO-IN-001` | General liability for River Lights |
| `DEMO-IN-002` | Rooftop shoot permit risk |
| `DEMO-IN-003` | Drone coverage for Blue Van |
| `DEMO-IN-004` | Night street safety check |
| `DEMO-IN-005` | Coastal travel equipment cover |
| `DEMO-IN-006` | Student crowd safety plan |
| `DEMO-IN-007` | Low-light electrical safety |
| `DEMO-IN-008` | Kitchen fire safety permit |
| `DEMO-IN-009` | Incident report and corrective action |
| `DEMO-IN-010` | Desert remote medical cover |

---

## 17. Distribution Partner portal seed pack

Minimum records: 10 distribution partner profiles/projects, 20 contacts, 20 handover items, 20 release windows, 10 distribution reports.

| Screen | Route | Data to seed |
|---|---|---|
| DS-01 Dashboard | `/distribution` | Active release projects and reports |
| DS-02 Distributor Contacts & Records | `/distribution/contacts` | Contacts by territory/channel |
| DS-03 Release Coordination | `/distribution/release` | Distribution projects, handover items, release windows |
| DS-04 Performance Reporting | `/distribution/reports` | Reports with territory/channel/revenue/view metrics |

### 10 Distribution records

| ID | Scenario |
|---|---|
| `DEMO-DS-001` | Pakistan theatrical handover for River Lights |
| `DEMO-DS-002` | Karachi TV distributor for City of Dust |
| `DEMO-DS-003` | Digital ad placement report for Blue Van |
| `DEMO-DS-004` | Music channel release for Eid Run |
| `DEMO-DS-005` | Festival screener handover for Salt Road |
| `DEMO-DS-006` | Web platform release for Campus Beat |
| `DEMO-DS-007` | Short-film festival packet for Night Bazaar |
| `DEMO-DS-008` | Brand content distribution for Monsoon Menu |
| `DEMO-DS-009` | PSA broadcast handover for Safe Set PSA |
| `DEMO-DS-010` | OTT release plan for Desert Echo |

---

## 18. Super Admin seed pack

Super Admin needs only one admin account, but the queues must be populated by everyone else’s records.

| Admin screen | Route | Data required |
|---|---|---|
| Dashboard | `/admin/dashboard` | Counts from users, KYC, payments, disputes, moderation |
| Review Hub | `/admin/review-hub` | People/listing/content review rows |
| People Review | `/admin/review-hub/people` | KYC submissions and profile review candidates |
| Listings Review | `/admin/review-hub/listings` | Marketplace listings awaiting review |
| Content Review | `/admin/review-hub/content` | Reports/moderation cases |
| Verifications | `/admin/verifications` | 10 KYC submissions, mixed statuses |
| Verification Detail | `/admin/verifications/:id` | KYC documents and decision history |
| Content Moderation | `/admin/content-moderation` | 10 moderation cases |
| Listings Moderation | `/admin/listings-moderation` | 10 listings with status flags |
| Bookings Monitor | `/admin/bookings-monitor` | 10 bookings, mixed states |
| Payments | `/admin/payments` | Payment dashboard/queues |
| Payment Queue | `/admin/payment-queue` | 10 payment proofs |
| Payment Review | `/admin/payment-review/:id` | Payment proof detail |
| Payment Ledger | `/admin/payments/ledger` | Ledger entries |
| Payment Revenue | `/admin/payments/revenue` | Fee/revenue snapshots |
| Contract Templates | `/admin/contract-templates` | 10 templates/clauses |
| Fees | `/admin/fees` | Fee rules |
| Disputes | `/admin/disputes` | 10 disputes |
| Users | `/admin/users` | All demo users |
| Admin Roles | `/admin/admin-roles` | One super admin plus optional reviewer roles |
| Support | `/admin/support` | 10 support tickets |
| Broadcasts | `/admin/broadcasts` | 3 announcements |
| Audit Logs | `/admin/audit-logs` | Auth/admin/payment audit events |
| Analytics | `/admin/analytics` | Aggregated dashboard rows |

Recommended Super Admin demo state:

- 1 super admin user.
- 10 KYC submissions: 4 approved, 3 submitted, 2 rejected, 1 draft.
- 10 payment proofs: 4 pending, 4 approved, 2 rejected.
- 10 moderation cases: 5 open, 3 resolved, 2 escalated.
- 10 disputes: 4 open, 4 decided, 2 awaiting evidence.
- 10 support tickets: 5 open, 3 waiting user, 2 closed.
- 3 announcements: draft, published, scheduled/demo.

---

## 19. Trust, safety, payments, and communications seed pack

Create these cross-cutting records so shared screens look real:

| Record type | Count | Linked screens |
|---|---:|---|
| Reviews | 20 | AT reputation, public profiles, review screen |
| Review requests | 10 | Review prompts |
| Reports | 10 | Report screen, admin moderation |
| Blocked users | 10 | AT safety controls |
| Moderation cases | 10 | Admin content moderation/review hub |
| Disputes | 10 | Admin disputes, support, payment/location/equipment issue flows |
| Support tickets | 10 | Admin support CRM |
| Notifications | 30 | Notification center and dashboards |
| Announcements | 3 | Broadcasts and notifications |
| Push devices | 5 | Push-device backend visibility |

---

## 20. Payment/finance seed pack

At least 10 payment scenarios:

| ID | Scenario | Screens powered |
|---|---|---|
| `DEMO-PAY-001` | Talent advance pending proof | DP payments, AT earnings, admin queue |
| `DEMO-PAY-002` | Location deposit approved | LO earnings, ledger |
| `DEMO-PAY-003` | Equipment rental proof rejected | ME earnings, admin review |
| `DEMO-PAY-004` | Crew milestone paid | CR contracts/payments |
| `DEMO-PAY-005` | Brand deliverable payment pending | BR payments |
| `DEMO-PAY-006` | Agency commission paid | CA commission |
| `DEMO-PAY-007` | Legal review billing record | LG billing |
| `DEMO-PAY-008` | Insurance claim reserve | IN claims |
| `DEMO-PAY-009` | Dispute holdback | Admin disputes/payments |
| `DEMO-PAY-010` | Final release settlement | DS/DP reports |

Each scenario should include:

- payment schedule
- payment milestone
- optional proof file
- transaction/proof status
- receipt if approved
- ledger entry
- notification

---

## 21. Minimal endpoint/table mapping for the seed agent

Prefer these endpoints when seeding through API:

| Domain | Endpoint family |
|---|---|
| Auth/users | `/auth/register`, `/me/roles`, direct admin SQL for super admin if needed |
| KYC/files | `/uploads/presign`, `/uploads/{id}/binary`, `/uploads/{id}/complete`, `/kyc/submissions` |
| Profiles/marketplace | `/me/profile`, `/talent/profile`, `/marketplace/listings`, `/portfolio` |
| Projects | `/projects`, `/projects/{id}/requirements`, `/projects/{id}/room/items`, `/projects/{id}/files` |
| Shortlists | `/saved-searches`, `/shortlists`, `/shortlists/{id}/items` |
| Bookings/chat | `/bookings`, `/bookings/{id}/offers`, `/negotiations`, `/conversations` families |
| Contracts/legal | `/contracts`, `/contracts/{id}/signatures`, `/legal-reviews` families |
| Payments | `/payment-schedules`, `/payment-proofs`, `/admin/payment-proofs`, `/ledger` families |
| Operations | location/equipment/safety endpoints in `operations.py` |
| Insurance | insurance partner/policy/claim/evidence endpoints |
| Specialist | agency/brand/model/distribution endpoints in `specialist.py` |
| Trust/safety | `/reviews`, `/reports`, `/blocked-users`, `/disputes`, `/support-tickets`, `/notifications` |
| Analytics/exports | `/me/dashboard`, `/admin/dashboard`, `/admin/analytics`, `/exports` |

If direct SQL is used, respect foreign keys and create rows in the insertion order from Section 3.

---

## 22. Demo validation checklist after seeding

Run these checks after data insertion:

1. `GET /api/v1/health/ready` returns database and Redis `ok`.
2. Login as `DEMO-ADMIN-001`.
3. Login as one user from every portal role.
4. Each portal dashboard shows non-empty metrics.
5. Each portal list screen shows at least 10 or meaningful multiple records.
6. Every detail screen opens with a valid route argument.
7. Every file-download button either downloads a synthetic file or is clearly disabled.
8. Booking negotiation flow has at least one active thread.
9. Contract viewer has at least one signable contract.
10. Payment proof queue has pending/approved/rejected examples.
11. Notification center has unread and read examples.
12. Super Admin dashboard shows populated queues.
13. `/exports` can create supported `bookings`, `ledger`, and `admin_disputes` CSV jobs.
14. AT-12 blocked users list loads and unblock works.
15. DS-03 submit changes live distribution project status/note.

---

## 23. Final recommendation

For a compelling demo, do not seed isolated fake rows. Seed the 10 production backbone first, then attach every portal’s records to those productions. The app will feel much more real because the same project appears in discovery, booking, contracts, payments, legal, safety, insurance, distribution, admin queues, notifications, and dashboards.

Immediate next step for the seeding AI: create a `tools/seed_cineconnect_demo_data.py` script that reads this blueprint, creates deterministic public IDs, inserts in the order listed, and prints a login/account handoff table for the demo operator.
