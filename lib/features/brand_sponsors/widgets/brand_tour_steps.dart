import '../../../core/tour/tour_models.dart';
import '../routes/brand_sponsor_routes.dart';

const brandTourId = 'brand_sponsor.nova_cola_complete_project';

/// Follows one persisted project instead of explaining menus in isolation.
final List<TourStep> brandTourSteps = [
  _step(
    1,
    BrandSponsorRoutes.home,
    'Meet the project',
    'Nova Cola Winter Stories is one connected Lahore campaign. This journey follows its real backend records from registration to a secured production team.',
    targetId: 'brand:demo:journey',
  ),
  _step(
    2,
    BrandSponsorRoutes.projects,
    '1. Register the production',
    'The brand saves the campaign name, format, city, shoot dates, PKR 3.8M working budget, visibility and project status. The demo opens this same project automatically.',
    targetId: 'brand:demo:project-brief',
  ),
  _step(
    3,
    BrandSponsorRoutes.projects,
    '2. Register every requirement',
    'One brief now contains the lead actor, two lifestyle models, production crew, heritage location, and cinema camera/lighting package—with quantities, dates and budgets.',
    targetId: 'brand:demo:requirements',
  ),
  _step(
    4,
    BrandSponsorRoutes.marketplace,
    '3. Keep discovery project-scoped',
    'Nova Cola Winter Stories stays selected while the brand searches. Every shortlist or booking action is attached to this project—not a disconnected contact list.',
    targetId: 'brand:demo:working-project',
  ),
  _step(
    5,
    BrandSponsorRoutes.marketplace,
    '4. Evaluate the complete profile',
    'Open the large actor or model profile to judge screen presence, positioning, experience, languages, campaign fit, rates, verification, trust and portfolio media before deciding.',
    targetId: 'brand:demo:discovery-results',
  ),
  _step(
    6,
    BrandSponsorRoutes.shortlists,
    '5. Compare one production team',
    'The same project board contains actor, model, crew, location and equipment. Add private notes, mark selections and send a request without losing production context.',
    targetId: 'brand:demo:shortlist-board',
  ),
  _step(
    7,
    BrandSponsorRoutes.bookings,
    '6. Follow every response',
    'Five project requests demonstrate the real lifecycle: sent, viewed, under negotiation, accepted and secured. Filters and search operate on persisted records.',
    targetId: 'brand:demo:booking-pipeline',
  ),
  _step(
    8,
    BrandSponsorRoutes.bookings,
    '7. Negotiate and communicate',
    'Each request keeps the provider, linked requirement, dates, current offer, status history and a project conversation together. The provider sees the same request in their portal.',
    targetId: 'brand:demo:request-results',
  ),
  _step(
    9,
    BrandSponsorRoutes.projects,
    '8. Return to the production truth',
    'The project rolls requirements, shortlisted candidates, selected resources, confirmations and budget into one progress picture for the brand team.',
    targetId: 'brand:demo:project-brief',
  ),
  _step(
    10,
    BrandSponsorRoutes.home,
    'The connected flow is complete',
    'Continue from any stage card: edit the brief, discover another resource, compare the shortlist, message a provider or secure the next booking. Nothing here is a static mock row.',
    targetId: 'brand:demo:journey',
  ),
];

TourStep _step(
  int number,
  String route,
  String title,
  String description, {
  required String targetId,
}) {
  return TourStep(
    id: 'brand.project.$number',
    targetId: targetId,
    badge: '$number / 10 · NOVA COLA',
    title: title,
    description: description,
    routeName: route,
  );
}
