import '../../../core/tour/tour_models.dart';
import '../routes/brand_sponsor_routes.dart';

const brandFullWalkthroughTourId = 'brand_sponsor.full_workflow';

// No brand_sponsors screen carries its own internal step/tab state (no
// wizard or multi-page stepper among br01-br11 as built), so unlike a
// screen adopting `TourLocalStepSync`, every topic here omits `localStep`.
class _BrandTourTopic {
  final String title;
  final String description;
  final String targetId;
  const _BrandTourTopic(
    this.title,
    this.description, {
    required this.targetId,
  });
}

class _BrandTourChapter {
  final String routeName;
  final List<_BrandTourTopic> topics;
  const _BrandTourChapter({required this.routeName, required this.topics});
}

const _brandFullWalkthroughChapters = <_BrandTourChapter>[
  // BR-01 · Brand workspace overview
  _BrandTourChapter(
    routeName: BrandSponsorRoutes.home,
    topics: [
      _BrandTourTopic(
        'Read the workspace hero',
        'Live opportunities, committed production budget and confirmed bookings sit in one glance — New opportunity jumps straight into the campaign composer.',
        targetId: 'brand.dashboard.hero',
      ),
      _BrandTourTopic(
        'Track your active brief',
        "The most recent opportunity's budget, deadline and application count stay visible here, with one-tap shortcuts to edit the brief or open its applications.",
        targetId: 'brand.dashboard.activeBrief',
      ),
      _BrandTourTopic(
        'Clear the action queue',
        'Pending applications, deliverables waiting on review and unfinished draft briefs are ranked here — tap any row to jump straight into that queue.',
        targetId: 'brand.dashboard.actionQueue',
      ),
      _BrandTourTopic(
        'Confirm organization readiness',
        "Organization name, category and KYB status show what's still blocking full marketplace trust; Review brand profile opens the fix.",
        targetId: 'brand.dashboard.readiness',
      ),
    ],
  ),
  // BR-02 · Brand profile & trust
  _BrandTourChapter(
    routeName: BrandSponsorRoutes.profile,
    topics: [
      _BrandTourTopic(
        'Set the organization identity',
        "Legal name, industry category, authorized representative and a 20+ character sponsorship description are what applicants and CineConnect's trust checks read first.",
        targetId: 'brand.profile.identityForm',
      ),
      _BrandTourTopic(
        'Upload a brand logo',
        'A square PNG, JPG or WebP logo renders on every opportunity brief and the profile card — it queues immediately and confirms once processed.',
        targetId: 'brand.profile.logo',
      ),
      _BrandTourTopic(
        'Complete KYB verification',
        "Open verification starts the organization's identity check; until it clears, KYB status stays the ceiling on how much marketplace trust the brand carries.",
        targetId: 'brand.profile.trust',
      ),
      _BrandTourTopic(
        'Keep billing identity separate',
        'Billing details are tokenized and never redisplayed — this is organization billing only, not the campaign payment schedule, which stays in the ledger.',
        targetId: 'brand.profile.billing',
      ),
      _BrandTourTopic(
        'Watch profile readiness tick up',
        'Six checks — name, category, representative, description, logo, website and city — show exactly what is missing before the profile counts as complete.',
        targetId: 'brand.profile.readiness',
      ),
    ],
  ),
  // BR-08 · Campaign & production projects
  _BrandTourChapter(
    routeName: BrandSponsorRoutes.projects,
    topics: [
      _BrandTourTopic(
        'Scan production KPIs',
        'Active projects, open requirements, pending requests and confirmed bookings roll up across every campaign project in one row.',
        targetId: 'brand.projects.metrics',
      ),
      _BrandTourTopic(
        'Register a campaign project',
        'New project captures the campaign name, type, production city, shoot dates and working budget; search and status filters keep a growing list workable.',
        targetId: 'brand.projects.list',
      ),
      _BrandTourTopic(
        'Open the production brief',
        'Status, progress percentage, confirmed count and shortlisted count roll project type, city, shoot dates and working budget into one brief.',
        targetId: 'brand.projects.brief',
      ),
      _BrandTourTopic(
        'Add production requirements',
        'Add registers a talent, model, crew, location or equipment need with a quantity — each one becomes discoverable and bookable from Discover.',
        targetId: 'brand.projects.requirements',
      ),
      _BrandTourTopic(
        'Review attached resources',
        'Shortlisted and selected talent, crew, locations and equipment for this project collect here automatically as Discover and Shortlists work happens.',
        targetId: 'brand.projects.resources',
      ),
      _BrandTourTopic(
        "Move the project through its lifecycle",
        'Edit, Publish, Duplicate, Archive and Cancel control the project status — Publish is what lets discovery and shortlisting proceed against real dates.',
        targetId: 'brand.projects.actions',
      ),
    ],
  ),
  // BR-03 · Opportunity composer
  _BrandTourChapter(
    routeName: BrandSponsorRoutes.composer,
    topics: [
      _BrandTourTopic(
        'Name the opportunity',
        'A clear opportunity title is what applicants and your own portfolio list search by first.',
        targetId: 'brand.composer.title',
      ),
      _BrandTourTopic(
        'Pick the opportunity category',
        'Product placement, sponsorship, branded content, social campaign, event partnership or other sets applicant expectations and marketplace category filtering.',
        targetId: 'brand.composer.category',
      ),
      _BrandTourTopic(
        'Set the campaign budget',
        'Enter a realistic PKR total so creator discovery and commercial negotiation stay aligned with what the sponsorship can support.',
        targetId: 'brand.composer.budget',
      ),
      _BrandTourTopic(
        'Define usage rights and territory',
        "State how long and where the brand may reuse delivered content — this becomes the baseline the negotiation screen's exclusivity terms build on.",
        targetId: 'brand.composer.usage',
      ),
      _BrandTourTopic(
        'Set eligibility criteria',
        'Describe who may apply — audience size, niche, location — so the applications inbox fills with proposals that actually fit the campaign.',
        targetId: 'brand.composer.eligibility',
      ),
      _BrandTourTopic(
        'List required deliverables',
        'Spell out exactly what the creator must produce and deliver — the campaign tracker later checks submitted proof against this text.',
        targetId: 'brand.composer.deliverables',
      ),
      _BrandTourTopic(
        'Add an opportunity cover',
        'An optional campaign or product image is what makes the public brief read as a real opportunity to prospective applicants.',
        targetId: 'brand.composer.cover',
      ),
      _BrandTourTopic(
        'Set the application deadline',
        "Applications close automatically once this date passes, keeping the applicant pool time-boxed to the campaign's real production timeline.",
        targetId: 'brand.composer.deadline',
      ),
      _BrandTourTopic(
        'Save a draft or publish',
        'Save draft keeps the brief private while it is unfinished; Publish requires a budget, usage terms, deliverables and a deadline before applicants can see it.',
        targetId: 'brand.composer.publish',
      ),
      _BrandTourTopic(
        "Manage every opportunity you've created",
        'Selecting a row loads it back into the editor; the status menu moves it between published, paused and closed without losing its applications.',
        targetId: 'brand.composer.portfolio',
      ),
    ],
  ),
  // BR-04 · Applications inbox
  _BrandTourChapter(
    routeName: BrandSponsorRoutes.applications,
    topics: [
      _BrandTourTopic(
        'Read the proposal funnel',
        'Awaiting review, shortlisted and in-terms counts summarize where every applicant currently sits before a single proposal is opened.',
        targetId: 'brand.applications.queueStats',
      ),
      _BrandTourTopic(
        'Search across proposals',
        'One field matches applicant name, opportunity title, proposal text and audience metrics at once.',
        targetId: 'brand.applications.search',
      ),
      _BrandTourTopic(
        'Filter and sort the queue',
        'Narrow by status or opportunity, then sort by newest, budget ask or applicant name to work the queue in the order that matters today.',
        targetId: 'brand.applications.filters',
      ),
      _BrandTourTopic(
        'Review a proposal',
        'Each card shows the audience summary, budget ask and term-version count; Message opens chat, Shortlist flags a favorite, and Negotiate opens Terms & Deals for that applicant.',
        targetId: 'brand.applications.results',
      ),
    ],
  ),
  // BR-09 · Marketplace / discovery
  _BrandTourChapter(
    routeName: BrandSponsorRoutes.marketplace,
    topics: [
      _BrandTourTopic(
        'Search the marketplace',
        'One field matches name, skill, city or equipment across every published, approved listing on CineConnect.',
        targetId: 'brand.discovery.search',
      ),
      _BrandTourTopic(
        'Scope discovery to a working project',
        'Every shortlist or booking action taken here attaches to whichever project is selected, so discovery results stay tied to a real production instead of a disconnected contact list.',
        targetId: 'brand.discovery.project',
      ),
      _BrandTourTopic(
        'Filter by resource type',
        'Switch between actors, models, influencers, crew, locations, media & equipment, agencies and distribution partners without leaving the search.',
        targetId: 'brand.discovery.categories',
      ),
      _BrandTourTopic(
        'Evaluate a full profile',
        'Open a card to review screen presence, audience and trust metrics, rates, verification status and portfolio media before you shortlist or send a booking request.',
        targetId: 'brand.discovery.results',
      ),
    ],
  ),
  // BR-10 · Project shortlists
  _BrandTourChapter(
    routeName: BrandSponsorRoutes.shortlists,
    topics: [
      _BrandTourTopic(
        'Filter shortlists by project',
        "Switch the project dropdown to see just that project's saved candidates, or leave it on All projects to see every board at once.",
        targetId: 'brand.shortlists.filter',
      ),
      _BrandTourTopic(
        'Compare shortlisted candidates',
        'Each board groups one project\'s candidates with private notes, a status menu — selected, active or rejected — and a direct Request booking action.',
        targetId: 'brand.shortlists.board',
      ),
    ],
  ),
  // BR-11 · Requests & bookings
  _BrandTourChapter(
    routeName: BrandSponsorRoutes.bookings,
    topics: [
      _BrandTourTopic(
        'Track the request pipeline',
        'Pending, confirmed and closed counts summarize every booking request sent from Discover or a shortlist.',
        targetId: 'brand.bookings.metrics',
      ),
      _BrandTourTopic(
        'Search and filter requests',
        'Search plus a full status rail — sent, viewed, under negotiation, accepted, secured, completed, cancelled — tracks a request through its entire real lifecycle.',
        targetId: 'brand.bookings.filters',
      ),
      _BrandTourTopic(
        'Manage a booking request',
        "Each card keeps the provider, dates, current offer and linked requirement together; Messages opens the shared conversation and Cancel releases the provider's reserved availability with a recorded reason.",
        targetId: 'brand.bookings.results',
      ),
    ],
  ),
  // BR-05 · Negotiation & terms
  _BrandTourChapter(
    routeName: BrandSponsorRoutes.negotiation,
    topics: [
      _BrandTourTopic(
        'Choose which application to negotiate',
        "Switch applicants without losing your place — the form reloads that applicant's latest terms automatically.",
        targetId: 'brand.negotiation.applications',
      ),
      _BrandTourTopic(
        'Define scope and rights',
        'Campaign scope, category exclusivity and approval rights and response window are the three fields every term version is built from.',
        targetId: 'brand.negotiation.scope',
      ),
      _BrandTourTopic(
        'Structure the payment schedule',
        'Advance, proof approval and completion percentages must total 100 — each save writes an immutable new term version tied to those milestones.',
        targetId: 'brand.negotiation.milestones',
      ),
      _BrandTourTopic(
        'Message, counter or accept',
        'Message opens the shared conversation, Send counter writes a new term version, and Accept locks the deal and unlocks campaign delivery.',
        targetId: 'brand.negotiation.actions',
      ),
      _BrandTourTopic(
        'Review every term version',
        'Selecting an older version reloads it into the editor as the starting point for a new counteroffer, so nothing from an earlier round is lost.',
        targetId: 'brand.negotiation.history',
      ),
      _BrandTourTopic(
        'Follow the connected workflow',
        "This panel shows the application's status and how many term versions exist, and it unlocks Open campaign delivery the moment the deal is accepted.",
        targetId: 'brand.negotiation.workflow',
      ),
    ],
  ),
  // BR-06 · Campaign delivery tracker
  _BrandTourChapter(
    routeName: BrandSponsorRoutes.tracker,
    topics: [
      _BrandTourTopic(
        'Watch delivery status at a glance',
        'Awaiting proof, ready to review, approved and total impressions summarize every deliverable across every accepted deal.',
        targetId: 'brand.tracker.metrics',
      ),
      _BrandTourTopic(
        'Assign and filter deliverables',
        'Assign is enabled once an application is accepted; it names a deliverable and hands it to that creator with a due date, while the status tabs filter awaiting proof, review, revision and approved.',
        targetId: 'brand.tracker.board',
      ),
      _BrandTourTopic(
        'Review submitted proof',
        'Each card shows the owner, due date and impressions; Approve proof locks it in, Revision sends it back with required changes, and Record verified metrics captures impressions, reach, engagement and clicks once approved.',
        targetId: 'brand.tracker.results',
      ),
    ],
  ),
  // BR-07 · Payments & finance records
  _BrandTourChapter(
    routeName: BrandSponsorRoutes.payments,
    topics: [
      _BrandTourTopic(
        'Read the finance snapshot',
        "Recorded spend, pending release, released milestones and accepted deals summarize the account's entire payment position.",
        targetId: 'brand.payments.metrics',
      ),
      _BrandTourTopic(
        'Search and filter milestones',
        'Search matches milestone, booking or status; the filter rail narrows to due, pending verification, released or issue milestones.',
        targetId: 'brand.payments.search',
      ),
      _BrandTourTopic(
        'Work each payment milestone',
        "Each row's menu can submit payment proof once it is due, open the shared ledger, or report a payment issue on that exact milestone.",
        targetId: 'brand.payments.milestones',
      ),
      _BrandTourTopic(
        'Confirm accepted usage rights',
        'Exclusivity and approval terms from each accepted deal stay attached to its payment record here for audit.',
        targetId: 'brand.payments.rights',
      ),
      _BrandTourTopic(
        'Reconcile the ledger',
        'Credits and debits recorded against this brand account appear here, with View all opening the complete ledger.',
        targetId: 'brand.payments.ledger',
      ),
    ],
  ),
];

final List<TourStep> brandFullWalkthroughSteps =
    _buildBrandFullWalkthroughSteps();

List<TourStep> _buildBrandFullWalkthroughSteps() {
  final steps = <TourStep>[];
  final total = _brandFullWalkthroughChapters.fold<int>(
      0, (sum, c) => sum + c.topics.length);
  for (final chapter in _brandFullWalkthroughChapters) {
    for (final topic in chapter.topics) {
      final number = steps.length + 1;
      steps.add(TourStep(
        id: 'brand.full.$number',
        targetId: topic.targetId,
        badge: '$number / $total',
        title: topic.title,
        description: topic.description,
        routeName: chapter.routeName,
      ));
    }
  }
  return List.unmodifiable(steps);
}
