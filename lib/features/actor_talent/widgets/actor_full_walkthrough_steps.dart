import '../../../core/tour/tour_models.dart';
import '../routes/actor_talent_routes.dart';

/// Persisted-preferences id for the complete Actor/Talent workflow.
const actorFullWalkthroughTourId = 'actor_talent.full_workflow';

class _ActorTourTopic {
  final String title;
  final String description;
  final String targetId;

  const _ActorTourTopic(
    this.title,
    this.description, {
    required this.targetId,
  });
}

class _ActorTourChapter {
  final String routeName;
  final List<_ActorTourTopic> topics;

  const _ActorTourChapter({required this.routeName, required this.topics});
}

/// An Actor/Talent-only tutorial that follows the real casting lifecycle:
/// building a complete profile, assembling a portfolio, setting
/// availability and rates, discovering and applying to roles, handling
/// offers and negotiation, signing contracts, tracking earnings, and
/// managing reputation and safety controls.
const _actorFullWalkthroughChapters = <_ActorTourChapter>[
  _ActorTourChapter(
    routeName: ActorTalentRoutes.dashboard,
    topics: [
      _ActorTourTopic(
        'Welcome to your Talent Workspace',
        'This walkthrough follows the real actor/talent lifecycle on CineConnect — building a complete profile, applying to real casting calls, handling offers and contracts, and getting paid — and the hero card above always points at your single most useful next action, ranked from finishing your profile to opening a confirmed booking.',
        targetId: 'actor.dashboard.hero',
      ),
      _ActorTourTopic(
        'Jump straight into Quick Access',
        'Browse Opportunities, My Applications and Auditions sit here as one-tap shortcuts, so the everyday loop of discovering and tracking work never needs the full menu.',
        targetId: 'actor.dashboard.quickAccess',
      ),
      _ActorTourTopic(
        'Check your Talent Snapshot',
        'Your stage name, city, languages, agency and availability status show exactly what directors see first — use Edit profile here whenever a detail goes stale.',
        targetId: 'actor.dashboard.snapshot',
      ),
      _ActorTourTopic(
        'Watch your live widgets',
        'The clock, profile-completeness ring and booking calendar all update from your real profile and booking data — keep the completeness ring above 80% before you start applying widely.',
        targetId: 'actor.dashboard.widgets',
      ),
      _ActorTourTopic(
        'Read your live KPI strip',
        'Secured value, public rating and unread alerts pull from your real dashboard metrics — tap a tile to jump straight into Reviews or Notifications.',
        targetId: 'actor.dashboard.kpis',
      ),
      _ActorTourTopic(
        'Compare roles against your application activity',
        "Recommended Roles and Application Activity sit side by side so you can see what's newly available against what you already have in motion, without leaving the dashboard.",
        targetId: 'actor.dashboard.castingOverview',
      ),
      _ActorTourTopic(
        'Clear Priority Actions first',
        'Every offer and audition awaiting your response lands here in one queue — respond before each one expires so a producer never books around you by default.',
        targetId: 'actor.dashboard.priorityActions',
      ),
      _ActorTourTopic(
        'Manage your profile from one rail',
        'Portfolio, Calendar, Rates and Safety are one tap away here — the sections that keep your public listing accurate between bookings — with a reputation snapshot alongside it for a quick trust check.',
        targetId: 'actor.dashboard.manageProfile',
      ),
    ],
  ),
  _ActorTourChapter(
    routeName: ActorTalentRoutes.profile,
    topics: [
      _ActorTourTopic(
        'Add your photo, cover and CV',
        'A headshot is the first thing a casting director sees on a candidate card — add a profile photo, a wide cover image and, once your stage name is set, a PDF CV/resume.',
        targetId: 'actor.profile.photos',
      ),
      _ActorTourTopic(
        'Set your identity',
        'Stage name, account name, city and portfolio website anchor your public listing — city in particular must match a supported CineConnect city or saving will be rejected.',
        targetId: 'actor.profile.identity',
      ),
      _ActorTourTopic(
        'Write your bio and experience',
        'Biography, languages, acting skills, credits and training are what a producer reads to judge fit before opening your reel — keep credits and training one entry per line.',
        targetId: 'actor.profile.bio',
      ),
      _ActorTourTopic(
        'Fill in physical and voice details',
        'Playable age, height, eye and hair colour, accents, special abilities, gender identity, experience and union membership all feed casting filters — leaving them blank quietly excludes you from role searches.',
        targetId: 'actor.profile.physical',
      ),
      _ActorTourTopic(
        'Choose your marketplace categories',
        'Toggle Actor, Model and Influencer availability here — only the categories you enable are published as separate marketplace listings when you publish.',
        targetId: 'actor.profile.marketplaceAvailability',
      ),
      _ActorTourTopic(
        'Add social and representation',
        'Instagram, TikTok, follower counts and agency affiliation round out your credibility signals for productions comparing candidates.',
        targetId: 'actor.profile.social',
      ),
      _ActorTourTopic(
        'Save the profile',
        'Save profile writes every section to your backend profile at once — stage name, account name and city are required before it will succeed.',
        targetId: 'actor.profile.save',
      ),
      _ActorTourTopic(
        'Publish your marketplace listing',
        'Publishing creates a public listing per enabled category so directors can discover you in marketplace search — approved Actor/Talent KYC is required first.',
        targetId: 'actor.profile.publishListing',
      ),
      _ActorTourTopic(
        'Preview exactly what directors see',
        'The director-facing preview mirrors your live public profile card, including your profile-strength meter — open the full-screen view before publishing to catch anything incomplete.',
        targetId: 'actor.profile.preview',
      ),
    ],
  ),
  _ActorTourChapter(
    routeName: ActorTalentRoutes.portfolio,
    topics: [
      _ActorTourTopic(
        'Add up to three photos',
        'Each photo slot is a single tap to add, replace or remove — directors see these on your public profile, so lead with your strongest, most recent headshots.',
        targetId: 'actor.portfolio.photos',
      ),
      _ActorTourTopic(
        'Add up to three video clips',
        "Upload MP4 showreel or scene clips the same way — a real reel does more to win an audition than any bio text.",
        targetId: 'actor.portfolio.videos',
      ),
      _ActorTourTopic(
        'List your past roles',
        "Past Roles records the productions and characters you've actually played, each with its own cover photo, building a public credit history separate from your uploaded media.",
        targetId: 'actor.portfolio.pastRoles',
      ),
    ],
  ),
  _ActorTourChapter(
    routeName: ActorTalentRoutes.calendar,
    topics: [
      _ActorTourTopic(
        'Read the 14-day availability strip',
        'Each day is colour-coded available, tentative, booked or unavailable from your real calendar data — tap any day to select it before editing.',
        targetId: 'actor.availability.dateStrip',
      ),
      _ActorTourTopic(
        'Know the status legend',
        'The same four availability states appear everywhere a producer checks your calendar, so keeping this vocabulary consistent avoids scheduling confusion.',
        targetId: 'actor.availability.legend',
      ),
      _ActorTourTopic(
        'Review and refresh live entries',
        'Availability Entries lists what is actually saved on the server — refresh after editing elsewhere to confirm a change took effect.',
        targetId: 'actor.availability.entries',
      ),
      _ActorTourTopic(
        "Edit the selected day's agenda",
        "Use Edit on the selected day to mark it available, tentative or unavailable — booked days are locked automatically by a secured booking and can't be manually overridden.",
        targetId: 'actor.availability.agenda',
      ),
      _ActorTourTopic(
        'Check your secured booking count',
        'Travel Limits also totals how many dates are already locked by confirmed bookings, a quick sanity check before you commit to a new one.',
        targetId: 'actor.availability.travel',
      ),
    ],
  ),
  _ActorTourChapter(
    routeName: ActorTalentRoutes.rates,
    topics: [
      _ActorTourTopic(
        "Understand what's published vs. negotiable",
        'Rate Settings shows your published day rate status at a glance — everything beyond the standard day rate (project scope, travel, usage, overtime) stays negotiable per offer.',
        targetId: 'actor.rates.settings',
      ),
      _ActorTourTopic(
        'Set your marketplace pricing preference',
        'Choose how your Actor/Talent listings show pricing to directors browsing the marketplace — this preference applies across every category you publish.',
        targetId: 'actor.rates.pricingPreference',
      ),
      _ActorTourTopic(
        'Publish your standard day rate',
        'This is the one rate field the server actually stores on your talent profile — complete your Casting Profile first, since publishing is blocked without a stage name.',
        targetId: 'actor.rates.publishedRate',
      ),
    ],
  ),
  _ActorTourChapter(
    routeName: ActorTalentRoutes.opportunities,
    topics: [
      _ActorTourTopic(
        'Search and filter live casting calls',
        'Filter by Self-tape, Online, In person or your Saved list, and search narrows results as you type — every result is a real, currently open casting call.',
        targetId: 'actor.opportunities.searchFilter',
      ),
      _ActorTourTopic(
        'Browse and save roles',
        'Save a role to compare it later without losing your place — every result here is a real, currently open casting call, refreshed on demand.',
        targetId: 'actor.opportunities.castingCalls',
      ),
      _ActorTourTopic(
        "Apply from a role's detail page",
        'Opening a role takes you to its brief, application form, portfolio picker and an optional self-tape upload — submit or save your answers as a draft at any point.',
        targetId: 'actor.opportunities.roleGrid',
      ),
      _ActorTourTopic(
        'Track direct offers separately',
        'Producers can send a direct booking offer without a public casting call — those land here, distinct from roles you applied to yourself.',
        targetId: 'actor.opportunities.directOffers',
      ),
      _ActorTourTopic(
        'Respond to an offer or counter its terms',
        'Opening a direct offer lets you accept, reject with a reason, message the producer, or counter the fee, dates and conditions when the listing allows bargaining.',
        targetId: 'actor.opportunities.directOffers',
      ),
    ],
  ),
  _ActorTourChapter(
    routeName: ActorTalentRoutes.applications,
    topics: [
      _ActorTourTopic(
        'Track every application in one place',
        'Filter by Active, Auditions, Offers or Closed, and search across role, project and city — this is the single source of truth for where each submission stands.',
        targetId: 'actor.applications.searchFilter',
      ),
      _ActorTourTopic(
        'Open an application for next-step guidance',
        'Each application\'s Next Action panel tells you exactly what to do — submit a draft, wait for review, prepare a self-tape, or open a booking — based on its real status.',
        targetId: 'actor.applications.list',
      ),
      _ActorTourTopic(
        'Edit or submit a draft',
        'A draft can be edited — cover note, availability, question answers and attached portfolio media — right up until you submit it for the production to see.',
        targetId: 'actor.applications.list',
      ),
      _ActorTourTopic(
        'Message the production, or withdraw',
        "Once past draft, message the production straight from the application; withdraw instead only when you're certain — it closes the application for good and can't be undone.",
        targetId: 'actor.applications.list',
      ),
    ],
  ),
  _ActorTourChapter(
    routeName: ActorTalentRoutes.auditions,
    topics: [
      _ActorTourTopic(
        'Filter straight to auditions and callbacks',
        'This is the same tracker filtered to only audition and callback stages, so you never have to scroll past applications still waiting on a first response.',
        targetId: 'actor.applications.searchFilter',
      ),
      _ActorTourTopic(
        'Propose, accept or decline a meeting time',
        'The meeting negotiation panel lets you and the production trade proposed times, locations or online links back and forth until one round is accepted.',
        targetId: 'actor.applications.list',
      ),
      _ActorTourTopic(
        'Record and attach a self-tape',
        'When a role calls for a self-tape, upload it directly from the application — progress uploads live and the file attaches to that specific application automatically.',
        targetId: 'actor.applications.list',
      ),
    ],
  ),
  _ActorTourChapter(
    routeName: ActorTalentRoutes.bookings,
    topics: [
      _ActorTourTopic(
        'See every offer and confirmed booking together',
        'Filter by Offers, Confirmed or Closed, and search by producer, project or city — bookings and their still-open offers live in one combined list.',
        targetId: 'actor.bookings.searchFilter',
      ),
      _ActorTourTopic(
        'Open messages tied to the booking',
        'Each booking card carries its own Messages shortcut straight into the conversation with that producer, no separate inbox lookup required.',
        targetId: 'actor.bookings.list',
      ),
      _ActorTourTopic(
        'Jump to contract signing',
        "A confirmed booking's Contract shortcut takes you straight to its agreement — no need to hunt through the full contract queue.",
        targetId: 'actor.bookings.list',
      ),
      _ActorTourTopic(
        'Jump to payment and earnings',
        "The Payment shortcut opens Earnings scoped to that booking's schedule, so you can check what's pending without losing your place in the bookings list.",
        targetId: 'actor.bookings.list',
      ),
    ],
  ),
  _ActorTourChapter(
    routeName: ActorTalentRoutes.contracts,
    topics: [
      _ActorTourTopic(
        'Review the live contract queue',
        'Contracts issued after you accept an offer land here — the top card is the one most needing your attention, with older versions listed underneath it.',
        targetId: 'actor.contracts.queue',
      ),
      _ActorTourTopic(
        'Read the clause-by-clause preview',
        'Project, talent fee, effective date and signature progress are pulled straight from the contract record — check every figure against the offer you actually accepted.',
        targetId: 'actor.contracts.preview',
      ),
      _ActorTourTopic(
        'Sign, or request a correction',
        'Sign contract commits your signature to that exact version; Request correction instead opens an addendum if a term still needs to change first.',
        targetId: 'actor.contracts.signButton',
      ),
      _ActorTourTopic(
        'Track signature progress',
        "The timeline shows terms approved, contract issued and signature captured in sequence — the booking isn't secured until every required party has signed.",
        targetId: 'actor.contracts.actions',
      ),
    ],
  ),
  _ActorTourChapter(
    routeName: ActorTalentRoutes.earnings,
    topics: [
      _ActorTourTopic(
        'See your protected balance',
        'Money Safe Summary totals verified ledger credits and shows how much is still pending release — CineConnect holds payment in escrow until milestones clear.',
        targetId: 'actor.earnings.summary',
      ),
      _ActorTourTopic(
        'Follow the payment timeline',
        "Every scheduled payment for your bookings appears here in order, so you always know what's due next and when it's expected to release.",
        targetId: 'actor.earnings.timeline',
      ),
      _ActorTourTopic(
        'Add a verified payout account',
        'A bank account or mobile wallet must be submitted and verified before funds can be released to you — only the last four characters of the identifier are ever displayed.',
        targetId: 'actor.earnings.securityActions',
      ),
      _ActorTourTopic(
        'Open receipts, or raise a payment issue',
        'Every payment leaves a permanent ledger receipt for reconciliation — and Raise issue starts a support case straight from this same earnings context when something looks wrong.',
        targetId: 'actor.earnings.securityActions',
      ),
    ],
  ),
  _ActorTourChapter(
    routeName: ActorTalentRoutes.reputation,
    topics: [
      _ActorTourTopic(
        'Check your public rating',
        'Your average rating and total review count are exactly what directors see on your listing — only reviews from completed, verified CineConnect bookings ever count.',
        targetId: 'actor.reputation.rating',
      ),
      _ActorTourTopic(
        'Read published reviews',
        'Every review ties back to a specific booking, so you can see which productions are shaping your public reputation.',
        targetId: 'actor.reputation.reviews',
      ),
      _ActorTourTopic(
        'Follow the guidance to improve it',
        'Replying to offers before they expire, keeping availability current, and leading with strong portfolio media are the concrete levers behind a stronger reputation.',
        targetId: 'actor.reputation.guidance',
      ),
    ],
  ),
  _ActorTourChapter(
    routeName: ActorTalentRoutes.safety,
    topics: [
      _ActorTourTopic(
        'Know your booking protections',
        'Contact stays inside CineConnect chat, content and usage terms are reviewable before you accept, travel needs your explicit consent, and secured dates are locked by the booking itself.',
        targetId: 'actor.safety.protections',
      ),
      _ActorTourTopic(
        'Manage account, privacy and identity',
        'Account settings, identity verification and notification preferences all live here — verification in particular unlocks higher-trust roles and marketplace visibility.',
        targetId: 'actor.safety.account',
      ),
      _ActorTourTopic(
        'Open a dispute and attach evidence',
        'Disputes over payment, cancellation, contract terms or safety attach to a specific sent or confirmed booking — add a note, image, PDF or video as evidence directly from the same row.',
        targetId: 'actor.safety.disputes',
      ),
      _ActorTourTopic(
        'Review and manage blocked users',
        'Anyone you\'ve blocked is listed here with your reason, and can be unblocked in one tap if circumstances change.',
        targetId: 'actor.safety.blockedUsers',
      ),
      _ActorTourTopic(
        'Report or contact safety support',
        'Report a suspicious offer or open a direct safety support ticket — for immediate danger, leave the location and contact local emergency services first.',
        targetId: 'actor.safety.reportSupport',
      ),
    ],
  ),
];

/// The complete Actor/Talent walkthrough, built once at load time.
final List<TourStep> actorFullWalkthroughSteps =
    _buildActorFullWalkthroughSteps();

List<TourStep> _buildActorFullWalkthroughSteps() {
  final steps = <TourStep>[];
  final total = _actorFullWalkthroughChapters.fold<int>(
    0,
    (sum, chapter) => sum + chapter.topics.length,
  );
  for (final chapter in _actorFullWalkthroughChapters) {
    for (final topic in chapter.topics) {
      final number = steps.length + 1;
      steps.add(
        TourStep(
          id: 'actor.full.$number',
          targetId: topic.targetId,
          badge: '$number / $total',
          title: topic.title,
          description: topic.description,
          routeName: chapter.routeName,
        ),
      );
    }
  }
  return List.unmodifiable(steps);
}
