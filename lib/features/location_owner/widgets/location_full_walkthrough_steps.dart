import '../../../core/tour/tour_models.dart';
import '../routes/location_owner_routes.dart';

/// Persisted-preferences id for the complete Location Owner workflow.
const locationFullWalkthroughTourId = 'location_owner.full_workflow';

class _LocationTourTopic {
  final String title;
  final String description;
  final String targetId;
  final Object? localStep;

  const _LocationTourTopic(
    this.title,
    this.description, {
    required this.targetId,
    this.localStep,
  });
}

class _LocationTourChapter {
  final String routeName;
  final List<_LocationTourTopic> topics;

  const _LocationTourChapter({
    required this.routeName,
    required this.topics,
  });
}

/// A Location Owner-only tutorial that follows the real property lifecycle:
/// building the listing, setting availability and rates, handling requests,
/// running check-in and check-out, tracking earnings, and managing the
/// public owner identity that sits behind every published property.
const _locationFullWalkthroughChapters = <_LocationTourChapter>[
  _LocationTourChapter(
    routeName: LocationOwnerRoutes.home,
    topics: [
      _LocationTourTopic(
        'Read your location workspace at a glance',
        'The quick-stats row pulls live counts for properties, open requests, upcoming shoots and current earnings straight from the backend — check it first every session before deciding what to work on.',
        targetId: 'location.dashboard.quickStats',
      ),
      _LocationTourTopic(
        'Track your active property',
        'The active property card mirrors exactly what a director sees on your public listing: cover photo, status, crew capacity, parking, power backup and rating. Switch properties from the sidebar switcher if you manage more than one.',
        targetId: 'location.dashboard.activeProperty',
      ),
      _LocationTourTopic(
        'Clear the action-required queue',
        'Publish a draft listing, respond to open booking requests and prepare the next handover from this single attention list — the same requests also appear below in Latest requests.',
        targetId: 'location.dashboard.actionRequired',
      ),
      _LocationTourTopic(
        'Know where to get help',
        'Jump to check-in evidence or file a support report the moment a booking or a property condition needs backend attention — both live in Safety & support.',
        targetId: 'location.dashboard.safety',
      ),
    ],
  ),
  _LocationTourChapter(
    routeName: LocationOwnerRoutes.listing,
    topics: [
      _LocationTourTopic(
        'Create or edit your property profile',
        'The wizard has three steps — basics, location & description, then capacity & amenities. Progress and publication status stay visible in the chips above the form the whole way through.',
        targetId: 'location.wizard.progress',
        localStep: 1,
      ),
      _LocationTourTopic(
        'Name the property clearly',
        'Use a name a director will recognize at a glance in search results and in their shortlist — the property name and type appear together in the public listing badge.',
        targetId: 'location.wizard.name',
        localStep: 1,
      ),
      _LocationTourTopic(
        'Choose the property type',
        'Home, studio, office, farm, restaurant, rooftop or other — this drives how the property is categorized in marketplace discovery filters.',
        targetId: 'location.wizard.type',
        localStep: 1,
      ),
      _LocationTourTopic(
        'Upload property photos',
        'Add clear daylight and night images before publishing — the first photo becomes the cover image on both the dashboard card and the public listing.',
        targetId: 'location.wizard.photos',
        localStep: 1,
      ),
      _LocationTourTopic(
        'Set the public area',
        'City and public area are what directors see before booking — keep them accurate. The exact address stays private and is only shared once the booking workflow allows access.',
        targetId: 'location.wizard.area',
        localStep: 2,
      ),
      _LocationTourTopic(
        'Record the private exact address',
        'This street-level address is never shown publicly. It is stored for logistics and only surfaces once a booking is secured.',
        targetId: 'location.wizard.address',
        localStep: 2,
      ),
      _LocationTourTopic(
        'Write the production description',
        'Describe the space the way a location scout would — natural light, ceiling height, background options, access routes — at least 10 characters, but the more useful detail the better the fit for incoming requests.',
        targetId: 'location.wizard.description',
        localStep: 2,
      ),
      _LocationTourTopic(
        'List the shoot spaces',
        'Name every interior and exterior area available for filming, separated by commas. These become the exact areas check-in and check-out inspections walk through later.',
        targetId: 'location.wizard.spaces',
        localStep: 3,
      ),
      _LocationTourTopic(
        'Set crew capacity and parking',
        'Crew capacity caps how many people a booking can bring on set; parking spaces tells producers what vehicle access to plan for. Both feed directly into booking-request review.',
        targetId: 'location.wizard.capacity',
        localStep: 3,
      ),
      _LocationTourTopic(
        'Flag power backup and accessibility',
        'Power backup and equipment accessibility are common production dealbreakers — mark them honestly so offers already account for them.',
        targetId: 'location.wizard.amenities',
        localStep: 3,
      ),
      _LocationTourTopic(
        'Save the draft or publish',
        'Save draft keeps the property private while you finish rates and rules; Publish property sends it to discovery immediately with whatever spaces, rates and rules are saved so far.',
        targetId: 'location.wizard.publish',
        localStep: 3,
      ),
    ],
  ),
  _LocationTourChapter(
    routeName: LocationOwnerRoutes.calendar,
    topics: [
      _LocationTourTopic(
        'Scan the next two weeks',
        'The legend and the fourteen-day strip show at a glance which days are available, blocked, on hold or already booked — tap any day to inspect it.',
        targetId: 'location.calendar.dayStrip',
      ),
      _LocationTourTopic(
        'Mark a day available, blocked or on hold',
        "Set the selected day's status directly — booked days from an accepted offer are locked here and can only change through the booking itself.",
        targetId: 'location.calendar.statusButtons',
      ),
      _LocationTourTopic(
        'Trust the server-confirmed calendar',
        'Every manual hold and every booking-generated entry is stored on the backend — refresh this list any time to confirm what is actually saved, not just what is showing locally.',
        targetId: 'location.calendar.serverEntries',
      ),
      _LocationTourTopic(
        'Watch for scheduling conflicts',
        'The conflict monitor totals manual holds, secured bookings and blocked entries; the selected-day agenda explains exactly why a given day shows its current status.',
        targetId: 'location.calendar.conflictMonitor',
      ),
    ],
  ),
  _LocationTourChapter(
    routeName: LocationOwnerRoutes.pricing,
    topics: [
      _LocationTourTopic(
        'Set your marketplace pricing visibility',
        'Choose how your rates appear to directors browsing the marketplace before they open your full profile.',
        targetId: 'location.pricing.preferencePanel',
      ),
      _LocationTourTopic(
        'Read the live rate snapshot',
        'Full-day rate, night shoot rate, security deposit and saved-rate-line count are pulled from your actual property pricing records, not placeholders.',
        targetId: 'location.pricing.snapshot',
      ),
      _LocationTourTopic(
        'Build the rate card',
        'Enable and price each unit that applies — hourly, half-day, full-day, night shoot, overtime and cleaning fee — using the plus/minus controls and the switch to publish it.',
        targetId: 'location.pricing.rate.day',
      ),
      _LocationTourTopic(
        'Price the night shoot premium',
        'Night work usually carries noise, lighting and access costs a daytime rate does not — price it separately so offers reflect the real premium.',
        targetId: 'location.pricing.rate.night',
      ),
      _LocationTourTopic(
        'Set the security deposit',
        'A deposit protects against damage and becomes a quote input for every offer sent against this property — leave it disabled only if you genuinely do not require one.',
        targetId: 'location.pricing.rate.deposit',
      ),
      _LocationTourTopic(
        'Save the rate card',
        'Every enabled rate needs an amount before saving — once saved, these become the numbers producers see and negotiate against.',
        targetId: 'location.pricing.save',
      ),
    ],
  ),
  _LocationTourChapter(
    routeName: LocationOwnerRoutes.rules,
    topics: [
      _LocationTourTopic(
        'Review your rules snapshot',
        'Allowed vs. restricted counts and saved-rule progress summarize the eight standard restriction categories covering this property.',
        targetId: 'location.rules.snapshot',
      ),
      _LocationTourTopic(
        'Set the smoking policy',
        'State whether smoking is allowed at all, and under what conditions — this is one of the most common production questions before a booking is confirmed.',
        targetId: 'location.rules.rule.smoking',
      ),
      _LocationTourTopic(
        'Set the animals-on-set policy',
        'Trained animals on a shoot usually need advance notice and supervision — document exactly what you require here.',
        targetId: 'location.rules.rule.animals',
      ),
      _LocationTourTopic(
        'Set noise and equipment restrictions',
        'Amplified sound cutoffs and heavy-equipment conditions, like floor protection and load plans, prevent avoidable disputes once a crew is on site.',
        targetId: 'location.rules.rule.noise',
      ),
      _LocationTourTopic(
        'Save property rules',
        'Rules saved here describe the property itself — any one-off exception still has to be written into the specific booking offer before it is accepted.',
        targetId: 'location.rules.save',
      ),
    ],
  ),
  _LocationTourChapter(
    routeName: LocationOwnerRoutes.requests,
    topics: [
      _LocationTourTopic(
        'Search and scan the request inbox',
        'Search by booking, project or producer name; the New, Negotiation, Accepted and Closed filters next to it narrow the list to the status you are working through.',
        targetId: 'location.requests.search',
      ),
      _LocationTourTopic(
        'Filter and sort by what matters now',
        'Filter by status and sort by newest or by fee to prioritize which requests need a response first.',
        targetId: 'location.requests.filters',
      ),
      _LocationTourTopic(
        'Review and respond to an offer',
        'Open Review for the full offer detail, then Accept the active offer or send a Counter with a revised fee, conditions and a message to the producer.',
        targetId: 'location.requests.list',
      ),
      _LocationTourTopic(
        'Decline a request cleanly',
        'Give a short, clear reason when declining — it goes straight to the producer and keeps the record honest for both sides.',
        targetId: 'location.requests.list',
      ),
    ],
  ),
  _LocationTourChapter(
    routeName: LocationOwnerRoutes.checkIn,
    topics: [
      _LocationTourTopic(
        'Choose the accepted booking',
        'Check-in only becomes available for bookings that are accepted, secured or in progress — pick the one starting next.',
        targetId: 'location.checkin.bookingPicker',
      ),
      _LocationTourTopic(
        'Start the check-in record',
        'Log an optional meter reading and handover notes to open the evidence record before the crew arrives.',
        targetId: 'location.checkin.start',
      ),
      _LocationTourTopic(
        'Capture every area, flag issues as you go',
        'Photograph each shoot space defined on the property profile; use Issue instead of Capture when a space already has a condition problem worth documenting.',
        targetId: 'location.checkin.areas',
      ),
      _LocationTourTopic(
        'Confirm the handover',
        'Owner confirmation locks the evidence record — it only unlocks once every area is captured, and the renter confirms the same record separately on their side.',
        targetId: 'location.checkin.confirm',
      ),
    ],
  ),
  _LocationTourChapter(
    routeName: LocationOwnerRoutes.checkOut,
    topics: [
      _LocationTourTopic(
        'Choose the booking to close out',
        'Check-out and damage claims apply to the same accepted, secured or in-progress bookings as check-in — the decision panel shows whether a check-in record already exists to compare against.',
        targetId: 'location.checkout.bookingPicker',
      ),
      _LocationTourTopic(
        'Compare before-and-after condition',
        'Each area shows its check-in photo next to the check-out photo side by side — capture the after photo for every space before you can confirm.',
        targetId: 'location.checkout.comparison',
      ),
      _LocationTourTopic(
        'File a damage claim with evidence',
        'State the claimed amount and description and attach a clear supporting photo — a claim can reference the check-in or check-out inspection it is based on.',
        targetId: 'location.checkout.fileClaim',
      ),
      _LocationTourTopic(
        'Confirm the check-out',
        'Confirming locks the after-condition record for this booking once every area is captured — the renter still confirms the same record on their side.',
        targetId: 'location.checkout.confirm',
      ),
    ],
  ),
  _LocationTourChapter(
    routeName: LocationOwnerRoutes.earnings,
    topics: [
      _LocationTourTopic(
        'Read the earnings snapshot',
        'Incoming ledger total, pending release, verified entries and disputed-entry count summarize your real payment position — pending release is admin-controlled, not something you can force.',
        targetId: 'location.earnings.snapshot',
      ),
      _LocationTourTopic(
        'Filter the rental ledger',
        'Switch between All, Pending, Verified and Disputed to focus on exactly the entries that need attention right now.',
        targetId: 'location.earnings.filters',
      ),
      _LocationTourTopic(
        'Review ledger entries and receipts',
        "Every entry links back to its booking and status — open Receipts or Report issue directly from an entry's menu instead of hunting for it elsewhere.",
        targetId: 'location.earnings.ledger',
      ),
      _LocationTourTopic(
        'Follow the payment trust timeline',
        'See exactly where a payment sits between submission, verification and release so you know what stage to expect next.',
        targetId: 'location.earnings.timeline',
      ),
      _LocationTourTopic(
        'Connect a payout account',
        'Add a payout account before earnings can be released to you — use the sandbox account here while testing the flow end to end.',
        targetId: 'location.earnings.payout',
      ),
    ],
  ),
  _LocationTourChapter(
    routeName: LocationOwnerRoutes.performance,
    topics: [
      _LocationTourTopic(
        'Choose the reporting window',
        'Switch between 7, 30 and 90 days to see whether recent activity is a blip or a trend.',
        targetId: 'location.performance.range',
      ),
      _LocationTourTopic(
        'Read the performance snapshot',
        'Property count, open requests, accepted bookings and average rating are calculated live from your own booking and property records for the selected window.',
        targetId: 'location.performance.snapshot',
      ),
      _LocationTourTopic(
        'Study the booking funnel',
        'The open vs. accepted vs. closed breakdown shows whether requests are converting or stalling in negotiation.',
        targetId: 'location.performance.chart',
      ),
      _LocationTourTopic(
        'Act on portfolio suggestions',
        'Publish a draft, add shoot spaces, set a full-day rate or define rules — each suggestion here points at exactly the profile gap holding your readiness score back.',
        targetId: 'location.performance.suggestions',
      ),
    ],
  ),
  _LocationTourChapter(
    routeName: LocationOwnerRoutes.profile,
    topics: [
      _LocationTourTopic(
        'Add your profile photo and cover',
        'These appear alongside every property you publish — directors see your identity next to your listings, not just the listing itself.',
        targetId: 'location.profile.avatar',
      ),
      _LocationTourTopic(
        'Write your identity',
        'City, website and bio establish who a director is dealing with — city must match a supported city exactly for the profile to save.',
        targetId: 'location.profile.bio',
      ),
      _LocationTourTopic(
        'Link your social accounts',
        'Instagram and TikTok handles give a director an easy way to see more of your work before they commit to a booking.',
        targetId: 'location.profile.social',
      ),
      _LocationTourTopic(
        'Save and preview your profile',
        'Save profile pushes these fields to the backend immediately — the preview panel on the right shows exactly what a director sees.',
        targetId: 'location.profile.save',
      ),
    ],
  ),
  _LocationTourChapter(
    routeName: LocationOwnerRoutes.portfolio,
    topics: [
      _LocationTourTopic(
        'Add portfolio photos',
        "Up to three photos, separate from any single property's listing images — this is your general body-of-work gallery.",
        targetId: 'location.portfolio.photos',
      ),
      _LocationTourTopic(
        'Add portfolio videos',
        'Up to three video clips showcase the property or past shoots in motion — replace or remove any slot at any time.',
        targetId: 'location.portfolio.videos',
      ),
      _LocationTourTopic(
        'Feature past productions filmed here',
        'List title, year and a cover photo for real productions shot at your property — social proof directors weigh heavily before booking.',
        targetId: 'location.portfolio.pastRoles',
      ),
    ],
  ),
  _LocationTourChapter(
    routeName: LocationOwnerRoutes.opportunities,
    topics: [
      _LocationTourTopic(
        'Browse open location requests',
        'Directors post specific location needs here — filter to the ones matching your property type, area and capacity.',
        targetId: 'nav:${LocationOwnerRoutes.opportunities}',
      ),
      _LocationTourTopic(
        'Apply and track your responses',
        "Submit your property against a posted need, then track every application's status from the same inbox instead of losing it in a chat thread.",
        targetId: 'nav:${LocationOwnerRoutes.opportunities}',
      ),
    ],
  ),
];

/// The complete Location Owner walkthrough: exactly 60 guided steps.
final List<TourStep> locationFullWalkthroughSteps =
    _buildLocationFullWalkthroughSteps();

List<TourStep> _buildLocationFullWalkthroughSteps() {
  final steps = <TourStep>[];
  final total = _locationFullWalkthroughChapters.fold<int>(
    0,
    (sum, chapter) => sum + chapter.topics.length,
  );
  assert(total == 60, 'The full Location Owner walkthrough must be 60 steps.');

  for (final chapter in _locationFullWalkthroughChapters) {
    for (final topic in chapter.topics) {
      final number = steps.length + 1;
      steps.add(
        TourStep(
          id: 'location.full.$number',
          targetId: topic.targetId,
          badge: '$number / $total',
          title: topic.title,
          description: topic.description,
          routeName: chapter.routeName,
          localStep: topic.localStep,
        ),
      );
    }
  }
  return List.unmodifiable(steps);
}
