import '../../../core/tour/tour_models.dart';
import '../routes/director_producer_routes.dart';

/// Persisted-preferences id for the Director/Producer flagship tour.
const dpTourId = 'director_producer.flagship';

/// The full self-navigation tour for the Producer Console — every step's
/// target lives on the dashboard itself (the shell's sidebar/nav is always
/// mounted alongside it), so this never has to navigate mid-tour.
final List<TourStep> dpTourSteps = [
  const TourStep(
    id: 'dp.intro',
    targetId: 'nav:${DirectorProducerRoutes.console}',
    badge: 'GUIDE',
    title: 'Your production console',
    description:
        'This tour highlights each part of your workflow. Tap Next, or tap '
        'the highlighted element itself, to move on.',
  ),
  const TourStep(
    id: 'dp.newProject',
    targetId: 'dp.newProject',
    badge: '1 / 8',
    title: 'Start a production',
    description: 'Create a project to unlock the workflow below.',
  ),
  const TourStep(
    id: 'dp.reviewApplications',
    targetId: 'dp.reviewApplications',
    badge: '2 / 8',
    title: 'Review who applied',
    description: 'All casting applications, in one queue.',
  ),
  const TourStep(
    id: 'dp.createAudition',
    targetId: 'dp.createAudition',
    badge: '3 / 8',
    title: 'Set audition requirements',
    description: 'Define what providers need to see before they apply.',
  ),
  const TourStep(
    id: 'dp.findProviders',
    targetId: 'dp.findProviders',
    badge: '4 / 8',
    title: 'Find providers',
    description: 'Search vetted crew, gear and locations.',
  ),
  const TourStep(
    id: 'dp.needsAttention',
    targetId: 'dp.needsAttention',
    badge: '5 / 8',
    title: 'Clear blockers first',
    description: 'Payment and approval actions surface here when due.',
  ),
  const TourStep(
    id: 'dp.schedule',
    targetId: 'nav:${DirectorProducerRoutes.schedule}',
    badge: '6 / 8',
    title: 'Plan the schedule',
    description: 'Lock shoot dates once talent is booked.',
  ),
  const TourStep(
    id: 'dp.contracts',
    targetId: 'nav:${DirectorProducerRoutes.contracts}',
    badge: '7 / 8',
    title: 'Send contracts',
    description: 'Generate agreements and track signatures.',
  ),
  const TourStep(
    id: 'dp.payments',
    targetId: 'nav:${DirectorProducerRoutes.payments}',
    badge: '8 / 8',
    title: 'Release payments',
    description: 'Pay out once milestones are approved.',
  ),
];
