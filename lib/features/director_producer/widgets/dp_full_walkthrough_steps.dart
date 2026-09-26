import '../../../core/tour/tour_models.dart';
import '../routes/director_producer_routes.dart';

/// Persisted-preferences id for the complete Director/Producer workflow.
const dpFullWalkthroughTourId = 'director_producer.full_workflow';

class _DpTourTopic {
  final String title;
  final String description;

  /// The real `TourTarget.id` this topic's spotlight lands on. Each topic
  /// targets the actual widget it describes rather than sharing one
  /// chapter-wide nav icon — reusing a target across topics is expected
  /// when several topics describe the same real widget (e.g. a wizard's
  /// Next/Create button, or a list's first real card standing in for a
  /// drill-down that isn't its own route).
  final String targetId;

  /// Sub-state a multi-step/tabbed screen should be showing while this
  /// topic is active (see [TourStep.localStep] / `TourLocalStepSync`).
  final Object? localStep;

  const _DpTourTopic(
    this.title,
    this.description, {
    required this.targetId,
    this.localStep,
  });
}

class _DpTourChapter {
  final String routeName;
  final List<_DpTourTopic> topics;

  const _DpTourChapter({
    required this.routeName,
    required this.topics,
  });
}

/// A Director/Producer-only tutorial that follows the production lifecycle
/// from the first project brief through discovery, booking, delivery, finance,
/// collaboration, and final reporting.
const _dpFullWalkthroughChapters = <_DpTourChapter>[
  _DpTourChapter(
    routeName: DirectorProducerRoutes.console,
    topics: [
      _DpTourTopic(
        'Welcome to your Producer Console',
        'This complete walkthrough stays inside the Director/Producer portal and follows one production from setup to final reporting.',
        targetId: 'dp.newProject',
      ),
      _DpTourTopic(
        'Read the production snapshot',
        'Use the console to see active projects, casting activity, approvals, contracts, and payment blockers before choosing the next task.',
        targetId: 'dp.console.modules',
      ),
      _DpTourTopic(
        'Start with a real project',
        'Every requirement, shortlist, booking, agreement, payment, and conversation needs a project to keep its context.',
        targetId: 'dp.newProject',
      ),
      _DpTourTopic(
        'Use attention cards as your queue',
        'Clear urgent approvals and blocked work first, then return here between workflow stages to confirm the updated production state.',
        targetId: 'dp.needsAttention',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.createProject,
    topics: [
      _DpTourTopic(
        'Create the production',
        'Open the project wizard and give the production a clear working title that collaborators will recognize.',
        targetId: 'dp.wizard.title',
        localStep: 0,
      ),
      _DpTourTopic(
        'Choose the production type',
        'Select the closest format so the project brief, provider searches, and downstream workflow use the right context.',
        targetId: 'dp.wizard.type',
        localStep: 0,
      ),
      _DpTourTopic(
        'Write the project overview',
        'Explain the concept, audience, style, scale, and expected outcome without relying on private messages later.',
        targetId: 'dp.wizard.overview',
        localStep: 0,
      ),
      _DpTourTopic(
        'Set the production location',
        'Add the working city or region so provider availability, travel, equipment delivery, and location discovery stay relevant.',
        targetId: 'dp.wizard.location',
        localStep: 1,
      ),
      _DpTourTopic(
        'Plan application dates',
        'Give providers enough time to review the brief and respond before auditions, negotiations, or scheduling begin.',
        targetId: 'dp.wizard.dates',
        localStep: 1,
      ),
      _DpTourTopic(
        'Plan shoot dates',
        'Use realistic production dates because availability checks, booking terms, contracts, and the calendar depend on them.',
        targetId: 'dp.wizard.dates',
        localStep: 1,
      ),
      _DpTourTopic(
        'Set the working budget',
        'Enter a useful budget range so discovery and commercial decisions remain aligned with what the production can support.',
        targetId: 'dp.wizard.budget',
        localStep: 2,
      ),
      _DpTourTopic(
        'Add references and documents',
        'Attach the current brief, visual references, scripts, or production notes so collaborators work from the same source.',
        targetId: 'dp.wizard.files',
        localStep: 4,
      ),
      _DpTourTopic(
        'Review before creating',
        'Confirm the title, dates, location, budget, and brief before saving; these details become the foundation for every later action.',
        targetId: 'dp.wizard.review',
        localStep: 6,
      ),
      _DpTourTopic(
        'Save the project',
        'Create the production, then continue to Projects to add requirements and manage the project hub.',
        targetId: 'dp.wizard.save',
        localStep: 6,
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.projects,
    topics: [
      _DpTourTopic(
        'Manage all productions',
        'Projects separates draft, active, and completed work while keeping each production record independent.',
        targetId: 'dp.projects.filters',
      ),
      _DpTourTopic(
        'Open the project hub',
        'Select a project to review its brief, requirements, files, bookings, activity, and overall production status.',
        targetId: 'dp.projects.firstCard',
      ),
      _DpTourTopic(
        'Define production requirements',
        'Add the talent roles, crew services, equipment, and locations needed before searching for providers.',
        targetId: 'dp.projects.firstCard',
      ),
      _DpTourTopic(
        'Set requirement details',
        'Describe the scope, skills, dates, quantity, and non-negotiable conditions so matching and applications stay useful.',
        targetId: 'dp.projects.firstCard',
      ),
      _DpTourTopic(
        'Keep project files current',
        'Store the latest references and working documents with the production instead of scattering versions across private conversations.',
        targetId: 'dp.projects.firstCard',
      ),
      _DpTourTopic(
        'Track the production stage',
        'Update status as the project moves from planning to staffing, contracting, production, delivery, and closure.',
        targetId: 'dp.projects.filters',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.marketplace,
    topics: [
      _DpTourTopic(
        'Discover production providers',
        'Search talent, crew, equipment, and locations while keeping the active project and requirement in context.',
        targetId: 'dp.marketplace.search',
      ),
      _DpTourTopic(
        'Choose the right category',
        'Begin with the provider type required by the project so category-specific filters and results stay relevant.',
        targetId: 'dp.marketplace.categories',
      ),
      _DpTourTopic(
        'Apply smart filters',
        'Narrow results by location, availability, experience, rate, verification, and other production needs.',
        targetId: 'dp.marketplace.filterButton',
      ),
      _DpTourTopic(
        'Use AI matching carefully',
        'Treat recommended matches as a faster starting point, then confirm the profile, proof of work, and production fit yourself.',
        targetId: 'dp.marketplace.firstCard',
      ),
      _DpTourTopic(
        'Review the full profile',
        'Check biography, credits, portfolio, services, media, availability, rates, and booking information before deciding.',
        targetId: 'dp.marketplace.firstCard',
      ),
      _DpTourTopic(
        'Check trust and safety signals',
        'Verification, completed work, ratings, and safety information help you assess risk before making contact.',
        targetId: 'dp.marketplace.firstCard',
      ),
      _DpTourTopic(
        'Compare creative fit',
        'Look beyond price and confirm the provider can deliver the quality, style, scale, and working conditions in the brief.',
        targetId: 'dp.marketplace.firstCard',
      ),
      _DpTourTopic(
        'Save strong options',
        'Add promising providers to the shortlist so the production team can compare finalists before sending requests.',
        targetId: 'dp.marketplace.firstCard',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.shortlist,
    topics: [
      _DpTourTopic(
        'Build the project shortlist',
        'Keep the best candidates and providers together instead of repeating marketplace searches.',
        targetId: 'dp.shortlist.board',
      ),
      _DpTourTopic(
        'Group by requirement',
        'Tie each option to the role, service, item, or location it could fulfill for the production.',
        targetId: 'dp.shortlist.firstGroup',
      ),
      _DpTourTopic(
        'Compare the finalists',
        'Review creative fit, availability, trust signals, expected cost, and any project-specific constraints side by side.',
        targetId: 'dp.shortlist.firstCard',
      ),
      _DpTourTopic(
        'Remove outdated choices',
        'Archive providers who are no longer available or suitable so collaborators discuss only the current decision set.',
        targetId: 'dp.shortlist.remove',
      ),
      _DpTourTopic(
        'Choose who to contact',
        'Move the selected provider into a booking request with the project scope and proposed commercial terms ready.',
        targetId: 'dp.shortlist.select',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.bookingRequest,
    topics: [
      _DpTourTopic(
        'Create the booking request',
        'Attach the request to the correct project, requirement, and provider so every later record stays connected.',
        targetId: 'dp.booking.project',
        localStep: 0,
      ),
      _DpTourTopic(
        'Describe the scope',
        'State exactly what the provider will supply or perform, including important deliverables and responsibilities.',
        targetId: 'dp.booking.deliverables',
        localStep: 2,
      ),
      _DpTourTopic(
        'Confirm dates and location',
        'Use the production schedule and real working location so the provider can validate availability and travel needs.',
        targetId: 'dp.booking.dates',
        localStep: 2,
      ),
      _DpTourTopic(
        'Propose the commercial terms',
        'Add the rate, total amount, deposit, milestones, overtime, expenses, and payment timing that apply.',
        targetId: 'dp.booking.scheduleBuilder',
        localStep: 2,
      ),
      _DpTourTopic(
        'Add booking conditions',
        'Include usage, cancellation, delivery, safety, insurance, or access conditions that must be agreed before work starts.',
        targetId: 'dp.booking.conditions',
        localStep: 2,
      ),
      _DpTourTopic(
        'Send a complete request',
        'Review the whole offer before sending so the provider can accept or counter without chasing missing information.',
        targetId: 'dp.booking.send',
        localStep: 3,
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.bargaining,
    topics: [
      _DpTourTopic(
        'Manage every negotiation',
        'Bargaining keeps offers and counteroffers attached to the provider, requirement, and project that created them.',
        targetId: 'dp.bargaining.list',
      ),
      _DpTourTopic(
        'Read the complete counteroffer',
        'Compare changed dates, scope, usage, payment timing, deliverables, and cancellation terms—not only the price.',
        targetId: 'dp.bargaining.firstCard',
      ),
      _DpTourTopic(
        'Keep negotiation in the thread',
        'Record commercial decisions in the shared offer history so both sides can refer to the same version.',
        targetId: 'dp.bargaining.open',
      ),
      _DpTourTopic(
        'Revise only changed terms',
        'Make a counteroffer easy to understand by updating the affected fields and explaining the production reason.',
        targetId: 'dp.bargaining.firstCard',
      ),
      _DpTourTopic(
        'Watch the production budget',
        'Check the accepted amount and related costs against Accounts before creating a new commitment.',
        targetId: 'dp.bargaining.firstCard',
      ),
      _DpTourTopic(
        'Confirm final agreement',
        'Verify the dates, scope, milestones, usage, and total amount one last time before accepting.',
        targetId: 'dp.bargaining.open',
      ),
      _DpTourTopic(
        'Move agreed terms to contract',
        'Once both sides agree, continue to Contracts so the negotiated terms become the formal booking agreement.',
        targetId: 'dp.bargaining.open',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.contracts,
    topics: [
      _DpTourTopic(
        'Review production agreements',
        'Contracts shows draft, sent, signed, and completed agreements across your productions.',
        targetId: 'dp.contracts.list',
      ),
      _DpTourTopic(
        'Verify parties and project',
        'Confirm the legal names, provider, production, requirement, and booking before sending the agreement.',
        targetId: 'dp.contracts.firstCard',
      ),
      _DpTourTopic(
        'Check scope and compensation',
        'Make sure deliverables, dates, rates, milestones, expenses, and payment conditions match the accepted offer.',
        targetId: 'dp.contracts.firstCard',
      ),
      _DpTourTopic(
        'Review protective clauses',
        'Check usage rights, confidentiality, cancellation, liability, dispute, safety, and delivery clauses for the booking.',
        targetId: 'dp.contracts.wizardButton',
      ),
      _DpTourTopic(
        'Request legal review when needed',
        'Use legal review for unusual, high-value, or higher-risk terms before signatures lock the agreement.',
        targetId: 'dp.contracts.legalReview',
      ),
      _DpTourTopic(
        'Track all signatures',
        'Treat the booking as secured only when every required party has signed the final agreement.',
        targetId: 'dp.contracts.signatures',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.schedule,
    topics: [
      _DpTourTopic(
        'Build the production calendar',
        'Schedule brings shoot dates, milestones, bookings, and production events into one working view.',
        targetId: 'dp.schedule.calendar',
      ),
      _DpTourTopic(
        'Check confirmed availability',
        'Compare provider commitments with the project plan before locking dates or publishing call information.',
        targetId: 'dp.schedule.projectScope',
      ),
      _DpTourTopic(
        'Add complete event details',
        'Include time, location, project, participants, instructions, and dependencies so every calendar item is actionable.',
        targetId: 'dp.schedule.callSheet',
      ),
      _DpTourTopic(
        'Resolve scheduling conflicts',
        'Fix overlapping bookings, travel constraints, location limits, and delivery dependencies before production begins.',
        targetId: 'dp.schedule.riskWatch',
      ),
      _DpTourTopic(
        'Keep every workflow aligned',
        'When dates change, update bookings, contracts, milestones, room messages, and payment expectations as needed.',
        targetId: 'dp.schedule.sync',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.payments,
    topics: [
      _DpTourTopic(
        'Follow the payment timeline',
        'Payments groups upcoming, submitted, verified, released, and disputed amounts by project and booking.',
        targetId: 'dp.payments.timeline',
        localStep: 'Timeline',
      ),
      _DpTourTopic(
        'Pay against contract milestones',
        'Use the agreed deposit, delivery, or completion stages so the financial record matches the signed contract.',
        targetId: 'dp.payments.ledger',
        localStep: 'Ledger',
      ),
      _DpTourTopic(
        'Attach clear payment proof',
        'Use the correct amount, reference, method, recipient, and evidence so verification is not delayed.',
        targetId: 'dp.payments.proofButton',
        localStep: 'Ledger',
      ),
      _DpTourTopic(
        'Approve only completed milestones',
        'Confirm the related work or deliverable is accepted before releasing the next payment.',
        targetId: 'dp.payments.ledger',
        localStep: 'Ledger',
      ),
      _DpTourTopic(
        'Keep receipts and ledger records',
        'Use transaction history for production reconciliation, reporting, support, and any later audit.',
        targetId: 'dp.payments.history',
        localStep: 'History',
      ),
      _DpTourTopic(
        'Raise issues from the transaction',
        'Start payment support or a dispute from the relevant record so the amount, booking, and evidence remain linked.',
        targetId: 'dp.payments.history',
        localStep: 'History',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.accounts,
    topics: [
      _DpTourTopic(
        'Control the production budget',
        'Accounts separates planned cost, committed spend, paid amounts, and remaining exposure for the project.',
        targetId: 'dp.accounts.budgetOverview',
      ),
      _DpTourTopic(
        'Act on budget risk early',
        'Review category overruns and pending commitments before approving more bookings or commercial changes.',
        targetId: 'dp.accounts.projectSplit',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.room,
    topics: [
      _DpTourTopic(
        'Collaborate in the project room',
        'Keep production messages, files, updates, and important decisions in the shared project history.',
        targetId: 'dp.room.feed',
      ),
      _DpTourTopic(
        'Move formal actions to their workflow',
        'Use Room for collaboration, then complete booking, contract, schedule, payment, or dispute actions in their dedicated sections.',
        targetId: 'dp.room.pinDecision',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.reports,
    topics: [
      _DpTourTopic(
        'Review and export production records',
        'Use Reports for project, booking, contract, payment, and performance summaries with the correct project and date scope.',
        targetId: 'dp.reports.list',
      ),
      _DpTourTopic(
        'Close the production cleanly',
        'Confirm deliverables, signatures, payments, receipts, files, and open issues, then keep the final report as the production record.',
        targetId: 'dp.reports.exportBuilder',
      ),
    ],
  ),
];

/// The complete Director/Producer walkthrough: exactly 69 guided steps.
final List<TourStep> dpFullWalkthroughSteps = _buildDpFullWalkthroughSteps();

List<TourStep> _buildDpFullWalkthroughSteps() {
  final steps = <TourStep>[];
  final total = _dpFullWalkthroughChapters.fold<int>(
    0,
    (sum, chapter) => sum + chapter.topics.length,
  );
  assert(
      total == 69, 'The full Director/Producer walkthrough must be 69 steps.');

  for (final chapter in _dpFullWalkthroughChapters) {
    for (final topic in chapter.topics) {
      final number = steps.length + 1;
      steps.add(
        TourStep(
          id: 'dp.full.$number',
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
