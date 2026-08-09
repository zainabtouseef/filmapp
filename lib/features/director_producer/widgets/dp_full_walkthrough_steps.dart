import '../../../core/tour/tour_models.dart';
import '../routes/director_producer_routes.dart';

/// Persisted-preferences id for the complete Director/Producer workflow.
const dpFullWalkthroughTourId = 'director_producer.full_workflow';

class _DpTourTopic {
  final String title;
  final String description;

  const _DpTourTopic(this.title, this.description);
}

class _DpTourChapter {
  final String routeName;
  final String targetId;
  final List<_DpTourTopic> topics;

  const _DpTourChapter({
    required this.routeName,
    required this.targetId,
    required this.topics,
  });
}

/// A Director/Producer-only tutorial that follows the production lifecycle
/// from the first project brief through discovery, booking, delivery, finance,
/// collaboration, and final reporting.
const _dpFullWalkthroughChapters = <_DpTourChapter>[
  _DpTourChapter(
    routeName: DirectorProducerRoutes.console,
    targetId: 'nav:${DirectorProducerRoutes.console}',
    topics: [
      _DpTourTopic(
        'Welcome to your Producer Console',
        'This complete walkthrough stays inside the Director/Producer portal and follows one production from setup to final reporting.',
      ),
      _DpTourTopic(
        'Read the production snapshot',
        'Use the console to see active projects, casting activity, approvals, contracts, and payment blockers before choosing the next task.',
      ),
      _DpTourTopic(
        'Start with a real project',
        'Every requirement, shortlist, booking, agreement, payment, and conversation needs a project to keep its context.',
      ),
      _DpTourTopic(
        'Use attention cards as your queue',
        'Clear urgent approvals and blocked work first, then return here between workflow stages to confirm the updated production state.',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.createProject,
    targetId: 'nav:${DirectorProducerRoutes.projects}',
    topics: [
      _DpTourTopic(
        'Create the production',
        'Open the project wizard and give the production a clear working title that collaborators will recognize.',
      ),
      _DpTourTopic(
        'Choose the production type',
        'Select the closest format so the project brief, provider searches, and downstream workflow use the right context.',
      ),
      _DpTourTopic(
        'Write the project overview',
        'Explain the concept, audience, style, scale, and expected outcome without relying on private messages later.',
      ),
      _DpTourTopic(
        'Set the production location',
        'Add the working city or region so provider availability, travel, equipment delivery, and location discovery stay relevant.',
      ),
      _DpTourTopic(
        'Plan application dates',
        'Give providers enough time to review the brief and respond before auditions, negotiations, or scheduling begin.',
      ),
      _DpTourTopic(
        'Plan shoot dates',
        'Use realistic production dates because availability checks, booking terms, contracts, and the calendar depend on them.',
      ),
      _DpTourTopic(
        'Set the working budget',
        'Enter a useful budget range so discovery and commercial decisions remain aligned with what the production can support.',
      ),
      _DpTourTopic(
        'Add references and documents',
        'Attach the current brief, visual references, scripts, or production notes so collaborators work from the same source.',
      ),
      _DpTourTopic(
        'Review before creating',
        'Confirm the title, dates, location, budget, and brief before saving; these details become the foundation for every later action.',
      ),
      _DpTourTopic(
        'Save the project',
        'Create the production, then continue to Projects to add requirements and manage the project hub.',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.projects,
    targetId: 'nav:${DirectorProducerRoutes.projects}',
    topics: [
      _DpTourTopic(
        'Manage all productions',
        'Projects separates draft, active, and completed work while keeping each production record independent.',
      ),
      _DpTourTopic(
        'Open the project hub',
        'Select a project to review its brief, requirements, files, bookings, activity, and overall production status.',
      ),
      _DpTourTopic(
        'Define production requirements',
        'Add the talent roles, crew services, equipment, and locations needed before searching for providers.',
      ),
      _DpTourTopic(
        'Set requirement details',
        'Describe the scope, skills, dates, quantity, and non-negotiable conditions so matching and applications stay useful.',
      ),
      _DpTourTopic(
        'Keep project files current',
        'Store the latest references and working documents with the production instead of scattering versions across private conversations.',
      ),
      _DpTourTopic(
        'Track the production stage',
        'Update status as the project moves from planning to staffing, contracting, production, delivery, and closure.',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.marketplace,
    targetId: 'nav:${DirectorProducerRoutes.marketplace}',
    topics: [
      _DpTourTopic(
        'Discover production providers',
        'Search talent, crew, equipment, and locations while keeping the active project and requirement in context.',
      ),
      _DpTourTopic(
        'Choose the right category',
        'Begin with the provider type required by the project so category-specific filters and results stay relevant.',
      ),
      _DpTourTopic(
        'Apply smart filters',
        'Narrow results by location, availability, experience, rate, verification, and other production needs.',
      ),
      _DpTourTopic(
        'Use AI matching carefully',
        'Treat recommended matches as a faster starting point, then confirm the profile, proof of work, and production fit yourself.',
      ),
      _DpTourTopic(
        'Review the full profile',
        'Check biography, credits, portfolio, services, media, availability, rates, and booking information before deciding.',
      ),
      _DpTourTopic(
        'Check trust and safety signals',
        'Verification, completed work, ratings, and safety information help you assess risk before making contact.',
      ),
      _DpTourTopic(
        'Compare creative fit',
        'Look beyond price and confirm the provider can deliver the quality, style, scale, and working conditions in the brief.',
      ),
      _DpTourTopic(
        'Save strong options',
        'Add promising providers to the shortlist so the production team can compare finalists before sending requests.',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.shortlist,
    targetId: 'nav:${DirectorProducerRoutes.shortlist}',
    topics: [
      _DpTourTopic(
        'Build the project shortlist',
        'Keep the best candidates and providers together instead of repeating marketplace searches.',
      ),
      _DpTourTopic(
        'Group by requirement',
        'Tie each option to the role, service, item, or location it could fulfill for the production.',
      ),
      _DpTourTopic(
        'Compare the finalists',
        'Review creative fit, availability, trust signals, expected cost, and any project-specific constraints side by side.',
      ),
      _DpTourTopic(
        'Remove outdated choices',
        'Archive providers who are no longer available or suitable so collaborators discuss only the current decision set.',
      ),
      _DpTourTopic(
        'Choose who to contact',
        'Move the selected provider into a booking request with the project scope and proposed commercial terms ready.',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.bookingRequest,
    targetId: 'nav:${DirectorProducerRoutes.shortlist}',
    topics: [
      _DpTourTopic(
        'Create the booking request',
        'Attach the request to the correct project, requirement, and provider so every later record stays connected.',
      ),
      _DpTourTopic(
        'Describe the scope',
        'State exactly what the provider will supply or perform, including important deliverables and responsibilities.',
      ),
      _DpTourTopic(
        'Confirm dates and location',
        'Use the production schedule and real working location so the provider can validate availability and travel needs.',
      ),
      _DpTourTopic(
        'Propose the commercial terms',
        'Add the rate, total amount, deposit, milestones, overtime, expenses, and payment timing that apply.',
      ),
      _DpTourTopic(
        'Add booking conditions',
        'Include usage, cancellation, delivery, safety, insurance, or access conditions that must be agreed before work starts.',
      ),
      _DpTourTopic(
        'Send a complete request',
        'Review the whole offer before sending so the provider can accept or counter without chasing missing information.',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.bargaining,
    targetId: 'nav:${DirectorProducerRoutes.bargaining}',
    topics: [
      _DpTourTopic(
        'Manage every negotiation',
        'Bargaining keeps offers and counteroffers attached to the provider, requirement, and project that created them.',
      ),
      _DpTourTopic(
        'Read the complete counteroffer',
        'Compare changed dates, scope, usage, payment timing, deliverables, and cancellation terms—not only the price.',
      ),
      _DpTourTopic(
        'Keep negotiation in the thread',
        'Record commercial decisions in the shared offer history so both sides can refer to the same version.',
      ),
      _DpTourTopic(
        'Revise only changed terms',
        'Make a counteroffer easy to understand by updating the affected fields and explaining the production reason.',
      ),
      _DpTourTopic(
        'Watch the production budget',
        'Check the accepted amount and related costs against Accounts before creating a new commitment.',
      ),
      _DpTourTopic(
        'Confirm final agreement',
        'Verify the dates, scope, milestones, usage, and total amount one last time before accepting.',
      ),
      _DpTourTopic(
        'Move agreed terms to contract',
        'Once both sides agree, continue to Contracts so the negotiated terms become the formal booking agreement.',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.contracts,
    targetId: 'nav:${DirectorProducerRoutes.contracts}',
    topics: [
      _DpTourTopic(
        'Review production agreements',
        'Contracts shows draft, sent, signed, and completed agreements across your productions.',
      ),
      _DpTourTopic(
        'Verify parties and project',
        'Confirm the legal names, provider, production, requirement, and booking before sending the agreement.',
      ),
      _DpTourTopic(
        'Check scope and compensation',
        'Make sure deliverables, dates, rates, milestones, expenses, and payment conditions match the accepted offer.',
      ),
      _DpTourTopic(
        'Review protective clauses',
        'Check usage rights, confidentiality, cancellation, liability, dispute, safety, and delivery clauses for the booking.',
      ),
      _DpTourTopic(
        'Request legal review when needed',
        'Use legal review for unusual, high-value, or higher-risk terms before signatures lock the agreement.',
      ),
      _DpTourTopic(
        'Track all signatures',
        'Treat the booking as secured only when every required party has signed the final agreement.',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.schedule,
    targetId: 'nav:${DirectorProducerRoutes.schedule}',
    topics: [
      _DpTourTopic(
        'Build the production calendar',
        'Schedule brings shoot dates, milestones, bookings, and production events into one working view.',
      ),
      _DpTourTopic(
        'Check confirmed availability',
        'Compare provider commitments with the project plan before locking dates or publishing call information.',
      ),
      _DpTourTopic(
        'Add complete event details',
        'Include time, location, project, participants, instructions, and dependencies so every calendar item is actionable.',
      ),
      _DpTourTopic(
        'Resolve scheduling conflicts',
        'Fix overlapping bookings, travel constraints, location limits, and delivery dependencies before production begins.',
      ),
      _DpTourTopic(
        'Keep every workflow aligned',
        'When dates change, update bookings, contracts, milestones, room messages, and payment expectations as needed.',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.payments,
    targetId: 'nav:${DirectorProducerRoutes.payments}',
    topics: [
      _DpTourTopic(
        'Follow the payment timeline',
        'Payments groups upcoming, submitted, verified, released, and disputed amounts by project and booking.',
      ),
      _DpTourTopic(
        'Pay against contract milestones',
        'Use the agreed deposit, delivery, or completion stages so the financial record matches the signed contract.',
      ),
      _DpTourTopic(
        'Attach clear payment proof',
        'Use the correct amount, reference, method, recipient, and evidence so verification is not delayed.',
      ),
      _DpTourTopic(
        'Approve only completed milestones',
        'Confirm the related work or deliverable is accepted before releasing the next payment.',
      ),
      _DpTourTopic(
        'Keep receipts and ledger records',
        'Use transaction history for production reconciliation, reporting, support, and any later audit.',
      ),
      _DpTourTopic(
        'Raise issues from the transaction',
        'Start payment support or a dispute from the relevant record so the amount, booking, and evidence remain linked.',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.accounts,
    targetId: 'nav:${DirectorProducerRoutes.accounts}',
    topics: [
      _DpTourTopic(
        'Control the production budget',
        'Accounts separates planned cost, committed spend, paid amounts, and remaining exposure for the project.',
      ),
      _DpTourTopic(
        'Act on budget risk early',
        'Review category overruns and pending commitments before approving more bookings or commercial changes.',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.room,
    targetId: 'nav:${DirectorProducerRoutes.room}',
    topics: [
      _DpTourTopic(
        'Collaborate in the project room',
        'Keep production messages, files, updates, and important decisions in the shared project history.',
      ),
      _DpTourTopic(
        'Move formal actions to their workflow',
        'Use Room for collaboration, then complete booking, contract, schedule, payment, or dispute actions in their dedicated sections.',
      ),
    ],
  ),
  _DpTourChapter(
    routeName: DirectorProducerRoutes.reports,
    targetId: 'nav:${DirectorProducerRoutes.reports}',
    topics: [
      _DpTourTopic(
        'Review and export production records',
        'Use Reports for project, booking, contract, payment, and performance summaries with the correct project and date scope.',
      ),
      _DpTourTopic(
        'Close the production cleanly',
        'Confirm deliverables, signatures, payments, receipts, files, and open issues, then keep the final report as the production record.',
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
          targetId: chapter.targetId,
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
