import 'package:flutter/material.dart';

import '../../features/actor_talent/routes/actor_talent_routes.dart';
import '../../features/brand_sponsors/routes/brand_sponsor_routes.dart';
import '../../features/casting_agency/routes/casting_agency_routes.dart';
import '../../features/crew_services/routes/crew_services_routes.dart';
import '../../features/director_producer/routes/director_producer_routes.dart';
import '../../features/distribution_partner/routes/distribution_partner_routes.dart';
import '../../features/general_public/routes/general_public_routes.dart';
import '../../features/insurance_partner/routes/insurance_partner_routes.dart';
import '../../features/legal_partner/routes/legal_partner_routes.dart';
import '../../features/location_owner/routes/location_owner_routes.dart';
import '../../features/media_equipment/routes/media_equipment_routes.dart';
import '../../features/model_extension/routes/model_extension_routes.dart';
import '../../features/super_admin/routes/super_admin_routes.dart';

class RoleMapper {
  RoleMapper._();

  static String codeForLabel(String label) {
    return switch (label) {
      'Director / Producer' => 'director_producer',
      'Actor / Talent' => 'actor_talent',
      'Model' => 'model',
      'Influencer' => 'influencer',
      'General Public' => 'general_public',
      'Location Owner' => 'location_owner',
      'Media / Equipment Provider' => 'equipment_provider',
      'Crew / Services' => 'crew_service',
      'Casting Agency' => 'casting_agency',
      'Brand / Sponsor' => 'brand_sponsor',
      'Legal Partner' => 'legal_partner',
      'Insurance / Safety Partner' => 'insurance_partner',
      'Distribution / Release Partner' => 'distribution_partner',
      _ => label,
    };
  }

  static String? portalRouteForCode(String code) {
    return switch (code) {
      'director_producer' => DirectorProducerRoutes.home,
      'actor_talent' => ActorTalentRoutes.dashboard,
      'model' => ModelExtensionRoutes.categories,
      'influencer' => ActorTalentRoutes.dashboard,
      'general_public' => GeneralPublicRoutes.home,
      'location_owner' => LocationOwnerRoutes.home,
      'equipment_provider' => MediaEquipmentRoutes.home,
      'crew_service' => CrewServicesRoutes.home,
      'casting_agency' => CastingAgencyRoutes.home,
      'brand_sponsor' => BrandSponsorRoutes.home,
      'legal_partner' => LegalPartnerRoutes.home,
      'insurance_partner' => InsurancePartnerRoutes.home,
      'distribution_partner' => DistributionPartnerRoutes.home,
      // Real backend staff role codes (see backend `ADMIN_ROLE_CODES` /
      // `SUPER_ADMIN_ROLE_CODES` in admin_control.py) — a genuinely
      // authenticated staff account lands in the console that matches
      // its actual permissions, not a route the login screen just guessed.
      'super_admin' => SuperAdminRoutes.dashboard,
      'reviewer' => SuperAdminRoutes.verifications,
      'finance_admin' => SuperAdminRoutes.paymentQueue,
      'support_agent' => SuperAdminRoutes.disputes,
      _ => null,
    };
  }

  static IconData iconForCode(String code) {
    return switch (code) {
      'director_producer' => Icons.movie_creation_outlined,
      'actor_talent' => Icons.theater_comedy_outlined,
      'model' => Icons.style_outlined,
      'influencer' => Icons.campaign_outlined,
      'general_public' => Icons.shopping_bag_outlined,
      'location_owner' => Icons.location_city_outlined,
      'equipment_provider' => Icons.videocam_outlined,
      'crew_service' => Icons.groups_2_outlined,
      'casting_agency' => Icons.badge_outlined,
      'brand_sponsor' => Icons.campaign_outlined,
      'legal_partner' => Icons.gavel_outlined,
      'insurance_partner' => Icons.health_and_safety_outlined,
      'distribution_partner' => Icons.public_outlined,
      _ => Icons.diversity_3_outlined,
    };
  }
}
