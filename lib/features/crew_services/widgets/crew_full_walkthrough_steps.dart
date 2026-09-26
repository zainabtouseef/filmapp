import '../../../core/tour/tour_models.dart';
import '../../../shared/marketplace/marketplace_routes.dart';
import '../routes/crew_services_routes.dart';

/// Persisted-preferences id for the complete Crew Services workflow.
const crewFullWalkthroughTourId = 'crew_services.full_workflow';

class _CrewTourTopic {
  final String title;
  final String description;
  final String targetId;

  const _CrewTourTopic(
    this.title,
    this.description, {
    required this.targetId,
  });
}

class _CrewTourChapter {
  final String routeName;
  final List<_CrewTourTopic> topics;

  const _CrewTourChapter({required this.routeName, required this.topics});
}

/// A Crew/Production-Services-only walkthrough that follows the real
/// provider lifecycle: publish a service profile, build proof of past work,
/// keep availability current, discover and apply to opportunities, handle
/// booking requests and negotiation, sign contracts and track payments, and
/// finally build a verified reputation that feeds back into discovery.
///
/// Every `targetId` below is a real, already-wired `TourTarget` on the real
/// crew_services screen for that chapter — see `cr01`..`cr08` under
/// `lib/features/crew_services/screens/`. The marketplace chapter reuses the
/// `dp.marketplace.*` targets already wired on the shared marketplace
/// discovery screen every portal (including Crew Services) browses through.
const _crewFullWalkthroughChapters = <_CrewTourChapter>[
  _CrewTourChapter(
    routeName: CrewServicesRoutes.home,
    topics: [
      _CrewTourTopic(
        'Welcome to your Crew Workspace',
        "This walkthrough follows the real crew lifecycle on CineConnect: publish your service profile, build proof of past work, keep availability current, win and negotiate bookings, sign contracts, get paid, and earn verified reviews.",
        targetId: 'crew.dashboard.hero',
      ),
      _CrewTourTopic(
        'Read your production snapshot',
        'The hero card shows active projects, verified earnings and open requests at a glance, so you know what needs attention before opening any other screen.',
        targetId: 'crew.dashboard.hero',
      ),
      _CrewTourTopic(
        'Check your quick stats',
        'Available days, contracts awaiting signature and your rating are one tap away — tap any tile to jump straight into that workflow.',
        targetId: 'crew.dashboard.quickStats',
      ),
      _CrewTourTopic(
        'Glance at your published availability',
        "The mini calendar marks the days you've published as available. Directors filter bookings by real availability, so keep this current before requests roll in.",
        targetId: 'crew.dashboard.calendarWidget',
      ),
      _CrewTourTopic(
        'Follow the production pipeline',
        "Open and confirmed bookings surface here in one list, so you don't have to jump between the request inbox and the calendar to see what's moving.",
        targetId: 'crew.dashboard.pipeline',
      ),
      _CrewTourTopic(
        'Clear action-required items first',
        'Open requests, unsigned contracts and open opportunities are ranked here. Working this list before anything else keeps bookings from stalling on your side.',
        targetId: 'crew.dashboard.actionRequired',
      ),
    ],
  ),
  _CrewTourChapter(
    routeName: CrewServicesRoutes.profile,
    topics: [
      _CrewTourTopic(
        'Set how you price your service',
        'This is where your day rate lives. Choose a fixed public price, a negotiable starting price with bargaining, or hide the price and only take offers — the choice controls what buyers see on every card, profile and booking request.',
        targetId: 'crew.profile.pricing',
      ),
      _CrewTourTopic(
        'Add a profile photo and cover image',
        'A recognizable photo and cover image are the first things a director sees on a crew card. Profiles without them get skipped in search results.',
        targetId: 'crew.profile.photos',
      ),
      _CrewTourTopic(
        'Set your service city',
        "Your city drives location-based discovery and travel expectations. Directors filtering by city won't see your profile at all if this is blank or wrong.",
        targetId: 'crew.profile.identity',
      ),
      _CrewTourTopic(
        'Describe your role, department and kit in your bio',
        "There's no separate department or equipment field — your bio is where you state your crew role (gaffer, sound recordist, focus puller, and so on), the department you cover, and any owned kit or gear you bring, since that's exactly what a director is scanning for.",
        targetId: 'crew.profile.identity',
      ),
      _CrewTourTopic(
        'Link Instagram and TikTok',
        'Social links back up your portfolio with a public trail of real work — reel drops, behind-the-scenes clips, past credits — that directors check before reaching out.',
        targetId: 'crew.profile.social',
      ),
      _CrewTourTopic(
        'Save and publish your profile',
        'Nothing here is visible to directors until you save. Save again after every meaningful edit, especially to pricing and bio.',
        targetId: 'crew.profile.saveButton',
      ),
      _CrewTourTopic(
        'Preview how directors see you',
        'This panel mirrors your public, director-facing profile exactly — use it to catch anything that reads wrong before a director does.',
        targetId: 'crew.profile.preview',
      ),
    ],
  ),
  _CrewTourChapter(
    routeName: CrewServicesRoutes.portfolio,
    topics: [
      _CrewTourTopic(
        'Upload portfolio photos',
        'Add up to three photos of past work. These sit directly on your public profile alongside your bio and are often the deciding factor in a shortlist.',
        targetId: 'crew.portfolio.photos',
      ),
      _CrewTourTopic(
        'Upload portfolio videos',
        'Up to three video clips — reels, behind-the-scenes footage, or sample work — give directors the clearest sense of your actual output.',
        targetId: 'crew.portfolio.videos',
      ),
      _CrewTourTopic(
        'Log your past projects and credits',
        'Add each production you worked on with your role label, year and a cover image. This resume-style history is what turns a bare profile into a trusted one.',
        targetId: 'crew.portfolio.pastProjects',
      ),
    ],
  ),
  _CrewTourChapter(
    routeName: CrewServicesRoutes.availability,
    topics: [
      _CrewTourTopic(
        'Publish your availability',
        "Use Add dates to publish available, tentative or unavailable blocks. Confirmed bookings create their own locked entries automatically, so only publish the dates you actually control.",
        targetId: 'crew.availability.publish',
      ),
      _CrewTourTopic(
        'Watch your availability at a glance',
        'Available, tentative and booked counts update live from your published calendar — a quick sanity check before you accept a new date range.',
        targetId: 'crew.availability.kpis',
      ),
      _CrewTourTopic(
        'Manage each schedule block',
        "Switch a block between available, tentative and unavailable with a tap. Locked blocks (marked with a padlock) came from a confirmed booking and can't be edited here.",
        targetId: 'crew.availability.entries',
      ),
    ],
  ),
  _CrewTourChapter(
    routeName: MarketplaceRoutes.browse,
    topics: [
      _CrewTourTopic(
        'See how directors search for crew',
        'The marketplace is the same search directors use to find you. Try a real search here to understand what makes a profile surface quickly.',
        targetId: 'dp.marketplace.search',
      ),
      _CrewTourTopic(
        'Filter by category',
        'Category chips (Crew, Locations, Media & Equipment and more) are the first filter a director applies — being tagged correctly under Crew is what puts you in front of the right search.',
        targetId: 'dp.marketplace.categories',
      ),
      _CrewTourTopic(
        'Narrow with smart filters',
        'Verified-only and new-this-week filters can hide or surface your profile depending on your verification status and how recently you published — keep both current.',
        targetId: 'dp.marketplace.filterButton',
      ),
      _CrewTourTopic(
        'Review a listing card the way a director would',
        'Rate range, verification badge and city are the first things visible on a card before a director opens the full profile — this is the same card format your own listing uses.',
        targetId: 'dp.marketplace.firstCard',
      ),
    ],
  ),
  _CrewTourChapter(
    routeName: CrewServicesRoutes.opportunities,
    topics: [
      _CrewTourTopic(
        'Browse open crew requirements',
        'Open Crew Requests lists live requirements directors have posted for your category — search here regularly instead of waiting for a direct request.',
        targetId: 'crew.opportunities.screen',
      ),
      _CrewTourTopic(
        'Apply with a strong cover note',
        "Apply opens a short form asking why you're a fit, plus any required documents. A specific, project-relevant note performs far better than a generic one.",
        targetId: 'crew.opportunities.screen',
      ),
      _CrewTourTopic(
        'Track your applications',
        "My Applications shows every submission and its live status. Withdraw an application here if you're no longer available for those dates.",
        targetId: 'crew.opportunities.screen',
      ),
      _CrewTourTopic(
        'Open an application to negotiate and follow status',
        'Tap any application to schedule an interview through the meeting negotiation panel and watch its full status timeline update as the production responds.',
        targetId: 'crew.opportunities.screen',
      ),
    ],
  ),
  _CrewTourChapter(
    routeName: CrewServicesRoutes.requests,
    topics: [
      _CrewTourTopic(
        'Search and filter your request inbox',
        'Search by producer, project or status, or use the filter chips (New, Negotiation, Secured, Closed) to jump straight to what needs a decision.',
        targetId: 'crew.requests.searchFilter',
      ),
      _CrewTourTopic(
        'Review each booking request',
        'Every card shows the project, producer, dates and current offer. This is your primary queue for incoming work — check it as often as the dashboard.',
        targetId: 'crew.requests.list',
      ),
      _CrewTourTopic(
        'Open full request details',
        'Details expands the project, producer, dates, current offer and status in one sheet, with a direct link into the booking conversation.',
        targetId: 'crew.requests.list',
      ),
      _CrewTourTopic(
        'Negotiate a counteroffer',
        'Counter sends a revised amount and updated service conditions back to the producer when bargaining is allowed on that request — negotiate rate and conditions together, not just price.',
        targetId: 'crew.requests.list',
      ),
      _CrewTourTopic(
        'Accept or reject a request',
        'Accept locks in the active offer and moves the booking toward a contract. Reject requires a short reason so the producer knows to look elsewhere.',
        targetId: 'crew.requests.list',
      ),
      _CrewTourTopic(
        'Chat with the producer',
        "Chat opens the real booking conversation tied to this request — use it to confirm details that don't belong in the formal offer terms.",
        targetId: 'crew.requests.list',
      ),
    ],
  ),
  _CrewTourChapter(
    routeName: CrewServicesRoutes.contracts,
    topics: [
      _CrewTourTopic(
        'Watch contracts and earnings KPIs',
        'Contracts signed, verified earnings and scheduled milestone amounts update from the live backend ledger — treat this as your financial health check.',
        targetId: 'crew.contracts.kpis',
      ),
      _CrewTourTopic(
        'Generate a contract once accepted',
        'Any accepted or secured booking without a contract yet shows up here. Generate turns the agreed terms into a formal, signable agreement.',
        targetId: 'crew.contracts.readyForContract',
      ),
      _CrewTourTopic(
        'Review and sign contracts',
        "Open each contract to check its value and signature progress before signing — a booking isn't fully secured on your side until you've signed.",
        targetId: 'crew.contracts.list',
      ),
      _CrewTourTopic(
        'Track the payment ledger',
        "Every credit and debit tied to your crew bookings lands here with its status, so you can reconcile what's been released against what's still pending.",
        targetId: 'crew.contracts.ledger',
      ),
    ],
  ),
  _CrewTourChapter(
    routeName: CrewServicesRoutes.ratings,
    topics: [
      _CrewTourTopic(
        'Check your verified rating',
        "Your rating and review count are computed only from completed, verified bookings — there's no way to inflate it, which is exactly why directors trust it.",
        targetId: 'crew.ratings.score',
      ),
      _CrewTourTopic(
        'Read director reviews',
        'Reviews only appear after a booking completes and passes moderation. Read them for the same detail directors will — specifics about reliability and quality, not just the star count.',
        targetId: 'crew.ratings.reviews',
      ),
      _CrewTourTopic(
        'Review your work history',
        'Every accepted and completed booking builds an auditable work history automatically — no manual credit entry needed once a booking closes.',
        targetId: 'crew.ratings.history',
      ),
      _CrewTourTopic(
        'Keep the lifecycle going',
        "A strong rating feeds directly back into discovery: it's one of the top-ranking signals in the marketplace and in opportunity applications. Revisit your profile, portfolio and availability regularly to keep everything current.",
        targetId: 'crew.ratings.score',
      ),
    ],
  ),
];

/// The complete Crew Services walkthrough.
final List<TourStep> crewFullWalkthroughSteps =
    _buildCrewFullWalkthroughSteps();

List<TourStep> _buildCrewFullWalkthroughSteps() {
  final steps = <TourStep>[];
  final total = _crewFullWalkthroughChapters.fold<int>(
    0,
    (sum, chapter) => sum + chapter.topics.length,
  );
  for (final chapter in _crewFullWalkthroughChapters) {
    for (final topic in chapter.topics) {
      final number = steps.length + 1;
      steps.add(
        TourStep(
          id: 'crew.full.$number',
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
