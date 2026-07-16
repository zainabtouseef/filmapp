import 'package:flutter/material.dart';

import '../models/role_portal_models.dart';
import '../routes/role_portal_routes.dart';

class RolePortalDemoData {
  RolePortalDemoData._();

  static const images = [
    PortalMediaAsset(
      id: 'actor-1',
      url:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=900&q=80',
      label: 'Lead talent portrait',
      category: 'talent',
      fallbackIcon: Icons.theater_comedy_outlined,
    ),
    PortalMediaAsset(
      id: 'model-1',
      url:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=900&q=80',
      label: 'Editorial model portrait',
      category: 'model',
      fallbackIcon: Icons.style_outlined,
    ),
    PortalMediaAsset(
      id: 'set-1',
      url:
          'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&w=1200&q=80',
      label: 'Film set production frame',
      category: 'project',
      fallbackIcon: Icons.movie_filter_outlined,
    ),
    PortalMediaAsset(
      id: 'location-1',
      url:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
      label: 'Premium shoot property',
      category: 'location',
      fallbackIcon: Icons.location_city_outlined,
    ),
    PortalMediaAsset(
      id: 'equipment-1',
      url:
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=1200&q=80',
      label: 'Cinema camera package',
      category: 'equipment',
      fallbackIcon: Icons.videocam_outlined,
    ),
    PortalMediaAsset(
      id: 'crew-1',
      url:
          'https://images.unsplash.com/photo-1536240478700-b869070f9279?auto=format&fit=crop&w=1200&q=80',
      label: 'Crew on set',
      category: 'crew',
      fallbackIcon: Icons.groups_2_outlined,
    ),
    PortalMediaAsset(
      id: 'agency-1',
      url:
          'https://images.unsplash.com/photo-1521737711867-e3b97375f902?auto=format&fit=crop&w=1200&q=80',
      label: 'Casting agency review',
      category: 'agency',
      fallbackIcon: Icons.badge_outlined,
    ),
    PortalMediaAsset(
      id: 'brand-1',
      url:
          'https://images.unsplash.com/photo-1552664730-d307ca884978?auto=format&fit=crop&w=1200&q=80',
      label: 'Brand campaign planning',
      category: 'brand',
      fallbackIcon: Icons.campaign_outlined,
    ),
    PortalMediaAsset(
      id: 'legal-1',
      url:
          'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=1200&q=80',
      label: 'Legal contract review',
      category: 'legal',
      fallbackIcon: Icons.gavel_outlined,
    ),
    PortalMediaAsset(
      id: 'insurance-1',
      url:
          'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?auto=format&fit=crop&w=1200&q=80',
      label: 'Safety and insurance records',
      category: 'insurance',
      fallbackIcon: Icons.health_and_safety_outlined,
    ),
    PortalMediaAsset(
      id: 'distribution-1',
      url:
          'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=1200&q=80',
      label: 'Cinema release performance',
      category: 'distribution',
      fallbackIcon: Icons.public_outlined,
    ),
  ];

  static const records = [
    PortalRecord(
      id: 'BK-2048',
      title: 'Aurora Biscuit TVC',
      subtitle: 'Lead actor, family kitchen location, lighting package',
      meta: 'Karachi · Jul 18-22 · Producer: Sara Ahmed',
      status: 'UNDER NEGOTIATION',
      amount: 'PKR 1.5M',
      imageUrl:
          'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&w=900&q=80',
      icon: Icons.movie_creation_outlined,
    ),
    PortalRecord(
      id: 'BK-2190',
      title: 'Noor Couture Campaign',
      subtitle: 'Editorial model pair, styling, makeup and usage rights',
      meta: 'Islamabad · Aug 9-10 · Brand: Noor Couture',
      status: 'CONTRACT PENDING SIGNATURE',
      amount: 'PKR 620k',
      imageUrl:
          'https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=900&q=80',
      icon: Icons.style_outlined,
    ),
    PortalRecord(
      id: 'BK-2214',
      title: 'Hunza Winter Film',
      subtitle: 'Mountain location, drone unit, local production support',
      meta: 'Hunza · Aug 4-Sep 2 · Feature film',
      status: 'PAYMENT PENDING',
      amount: 'PKR 4.8M',
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
      icon: Icons.terrain_outlined,
    ),
    PortalRecord(
      id: 'BK-2311',
      title: 'Echo Street Music Video',
      subtitle: 'Grip truck, lighting, BTS media and makeup team',
      meta: 'Lahore · Today · Music video',
      status: 'SECURED BOOKING',
      amount: 'PKR 740k',
      imageUrl:
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=900&q=80',
      icon: Icons.videocam_outlined,
    ),
  ];

  static const workflow = [
    PortalWorkflowItem(
      status: BookingLifecycleStatus.draft,
      title: 'Offer drafted with hidden contact details',
      owner: 'Director',
      timestamp: 'Jul 8 · 9:20 AM',
    ),
    PortalWorkflowItem(
      status: BookingLifecycleStatus.sent,
      title: 'Request sent and viewed by stakeholder',
      owner: 'CineConnect',
      timestamp: 'Jul 8 · 10:05 AM',
    ),
    PortalWorkflowItem(
      status: BookingLifecycleStatus.underNegotiation,
      title: 'Counteroffer opened with fee and schedule terms',
      owner: 'Stakeholder',
      timestamp: 'Jul 8 · 2:10 PM',
    ),
    PortalWorkflowItem(
      status: BookingLifecycleStatus.contractPendingSignature,
      title: 'Contract generated from approved terms',
      owner: 'Legal engine',
      timestamp: 'Today · 11:42 AM',
    ),
    PortalWorkflowItem(
      status: BookingLifecycleStatus.paymentUnderVerification,
      title: 'Deposit proof uploaded for admin review',
      owner: 'Producer',
      timestamp: 'Today · 12:30 PM',
    ),
  ];

  static final portals = [
    RolePortalSpec(
      id: 'talent',
      label: 'Actor / Talent Portal',
      shortLabel: 'Talent',
      description: 'Manage profile, offers, contracts, earnings and safety.',
      icon: Icons.theater_comedy_outlined,
      homeRoute: RolePortalRoutes.talentHome,
      screens: [
        _s(
            'AT-01',
            'Home',
            'Talent Dashboard',
            'Today’s offers, earnings, availability and reputation signals.',
            RolePortalRoutes.talentHome,
            Icons.dashboard_outlined,
            PortalScreenKind.dashboard,
            'Update availability',
            'Open inbox',
            'talent'),
        _s(
            'AT-02',
            'Profile',
            'Profile Builder',
            'Build verified acting skills, languages, age range and roles.',
            RolePortalRoutes.talentProfile,
            Icons.person_outline_rounded,
            PortalScreenKind.profile,
            'Save profile',
            'Preview public card',
            'talent',
            formFields: [
              'Screen name',
              'Languages',
              'Role range',
              'Union note'
            ]),
        _s(
            'AT-03',
            'Portfolio',
            'Portfolio & Showreel Manager',
            'Upload clips, reels, photos and featured performance frames.',
            RolePortalRoutes.talentPortfolio,
            Icons.video_library_outlined,
            PortalScreenKind.portfolio,
            'Add showreel',
            'Share portfolio',
            'talent'),
        _s(
            'AT-04',
            'Calendar',
            'Availability Calendar',
            'Block dates, hold tentative projects and prevent clashes.',
            RolePortalRoutes.talentAvailability,
            Icons.calendar_month_outlined,
            PortalScreenKind.calendar,
            'Save availability',
            'Add hold',
            'talent'),
        _s(
            'AT-05',
            'Rates',
            'Rate Card',
            'Set day rates, usage fees, overtime and travel rules.',
            RolePortalRoutes.talentRates,
            Icons.price_change_outlined,
            PortalScreenKind.finance,
            'Update rate card',
            'Export PDF',
            'talent',
            formFields: ['Shoot day rate', 'Overtime', 'Usage uplift']),
        _s(
            'AT-06',
            'Inbox',
            'Opportunity Inbox',
            'Review safe, verified opportunities and booking requests.',
            RolePortalRoutes.talentOpportunities,
            Icons.inbox_outlined,
            PortalScreenKind.inbox,
            'Accept selected',
            'Ask question',
            'talent'),
        _s(
            'AT-07',
            'Offer',
            'Offer Detail & Response',
            'Inspect a booking, terms, producer trust and response window.',
            RolePortalRoutes.talentOfferDetail,
            Icons.assignment_outlined,
            PortalScreenKind.detail,
            'Accept offer',
            'Reject offer',
            'project'),
        _s(
            'AT-08',
            'Counter',
            'Counteroffer Composer',
            'Counter rate, schedule, conditions and expiry professionally.',
            RolePortalRoutes.talentCounteroffer,
            Icons.edit_note_outlined,
            PortalScreenKind.composer,
            'Send counteroffer',
            'Save draft',
            'talent',
            formFields: ['Counter fee', 'Payment schedule', 'Conditions']),
        _s(
            'AT-09',
            'Contracts',
            'Contract Signing',
            'Use the shared e-signing flow for approved terms.',
            RolePortalRoutes.talentContracts,
            Icons.draw_outlined,
            PortalScreenKind.detail,
            'Open signing',
            'Request addendum',
            'legal'),
        _s(
            'AT-10',
            'Earnings',
            'Earnings & Payment Security',
            'Track deposits, verified receipts and secured booking payments.',
            RolePortalRoutes.talentEarnings,
            Icons.account_balance_wallet_outlined,
            PortalScreenKind.finance,
            'Upload proof',
            'Open ledger',
            'talent'),
        _s(
            'AT-11',
            'Reviews',
            'Reputation & Reviews',
            'Monitor ratings, punctuality, professionalism and repeat clients.',
            RolePortalRoutes.talentReputation,
            Icons.star_outline_rounded,
            PortalScreenKind.reports,
            'Request review',
            'Export report',
            'talent'),
        _s(
            'AT-12',
            'Safety',
            'Safety Controls',
            'Manage blocked users, safe check-ins and report controls.',
            RolePortalRoutes.talentSafety,
            Icons.shield_outlined,
            PortalScreenKind.safety,
            'Start check-in',
            'Report concern',
            'insurance'),
      ],
    ),
    RolePortalSpec(
      id: 'model',
      label: 'Model Extension',
      shortLabel: 'Model',
      description:
          'Campaign usage rights, rate tiers and brand-safety controls.',
      icon: Icons.style_outlined,
      homeRoute: RolePortalRoutes.modelHome,
      screens: [
        _s(
            'MD-01',
            'Campaigns',
            'Campaign Categories Setup',
            'Separate fashion, beauty, lifestyle and product categories.',
            RolePortalRoutes.modelHome,
            Icons.category_outlined,
            PortalScreenKind.manager,
            'Save categories',
            'Add campaign type',
            'model'),
        _s(
            'MD-02',
            'Rights',
            'Usage Rights Manager',
            'Control OOH, print, TVC, digital, regional and renewal terms.',
            RolePortalRoutes.modelUsageRights,
            Icons.verified_user_outlined,
            PortalScreenKind.detail,
            'Approve rights',
            'Request edit',
            'model'),
        _s(
            'MD-03',
            'Portfolio',
            'Portfolio Categories',
            'Organize editorial, runway, beauty, commercial and hands work.',
            RolePortalRoutes.modelPortfolio,
            Icons.collections_outlined,
            PortalScreenKind.portfolio,
            'Add category',
            'Reorder frames',
            'model'),
        _s(
            'MD-04',
            'Rates',
            'Rate by Usage',
            'Price bookings by usage type, period, exclusivity and territory.',
            RolePortalRoutes.modelRateUsage,
            Icons.price_change_outlined,
            PortalScreenKind.finance,
            'Update rates',
            'Simulate quote',
            'model'),
        _s(
            'MD-05',
            'Safety',
            'Brand Safety Preferences',
            'Exclude sensitive categories and approve brand fit before offers.',
            RolePortalRoutes.modelBrandSafety,
            Icons.health_and_safety_outlined,
            PortalScreenKind.safety,
            'Save preferences',
            'Block category',
            'brand'),
      ],
    ),
    _portal(
      id: 'location',
      label: 'Location Owner Portal',
      short: 'Locations',
      description: 'List properties, manage deposits, check-ins and claims.',
      icon: Icons.location_city_outlined,
      home: RolePortalRoutes.locationHome,
      media: 'location',
      entries: [
        _e('LO-01', 'Home', 'Owner Dashboard', RolePortalRoutes.locationHome,
            Icons.dashboard_outlined, PortalScreenKind.dashboard),
        _e(
            'LO-02',
            'Listing',
            'Location Listing Wizard',
            RolePortalRoutes.locationListing,
            Icons.add_home_work_outlined,
            PortalScreenKind.composer),
        _e(
            'LO-03',
            'Calendar',
            'Availability Calendar',
            RolePortalRoutes.locationAvailability,
            Icons.calendar_month_outlined,
            PortalScreenKind.calendar),
        _e(
            'LO-04',
            'Pricing',
            'Pricing & Deposit Setup',
            RolePortalRoutes.locationPricing,
            Icons.savings_outlined,
            PortalScreenKind.finance),
        _e(
            'LO-05',
            'Rules',
            'Rules & Restrictions',
            RolePortalRoutes.locationRules,
            Icons.rule_outlined,
            PortalScreenKind.safety),
        _e(
            'LO-06',
            'Requests',
            'Booking Requests Inbox',
            RolePortalRoutes.locationRequests,
            Icons.inbox_outlined,
            PortalScreenKind.inbox),
        _e(
            'LO-07',
            'Check-In',
            'Check-In Inspection Screen',
            RolePortalRoutes.locationCheckIn,
            Icons.fact_check_outlined,
            PortalScreenKind.manager),
        _e(
            'LO-08',
            'Claims',
            'Check-Out & Damage Claim Screen',
            RolePortalRoutes.locationCheckOut,
            Icons.report_problem_outlined,
            PortalScreenKind.safety),
        _e(
            'LO-09',
            'Earnings',
            'Earnings & Deposits',
            RolePortalRoutes.locationEarnings,
            Icons.account_balance_wallet_outlined,
            PortalScreenKind.finance),
        _e(
            'LO-10',
            'Performance',
            'Property Performance',
            RolePortalRoutes.locationPerformance,
            Icons.insights_outlined,
            PortalScreenKind.reports),
      ],
    ),
    _portal(
      id: 'equipment',
      label: 'Media / Equipment Provider Portal',
      short: 'Equipment',
      description: 'Manage inventory, packages, terms, handover and returns.',
      icon: Icons.videocam_outlined,
      home: RolePortalRoutes.equipmentHome,
      media: 'equipment',
      entries: [
        _e(
            'ME-01',
            'Home',
            'Provider Dashboard',
            RolePortalRoutes.equipmentHome,
            Icons.dashboard_outlined,
            PortalScreenKind.dashboard),
        _e(
            'ME-02',
            'Profile',
            'Provider Profile',
            RolePortalRoutes.equipmentProfile,
            Icons.storefront_outlined,
            PortalScreenKind.profile),
        _e(
            'ME-03',
            'Inventory',
            'Inventory Manager',
            RolePortalRoutes.equipmentInventory,
            Icons.inventory_2_outlined,
            PortalScreenKind.manager),
        _e(
            'ME-04',
            'Packages',
            'Package Builder',
            RolePortalRoutes.equipmentPackages,
            Icons.view_module_outlined,
            PortalScreenKind.composer),
        _e(
            'ME-05',
            'Calendar',
            'Availability Calendar',
            RolePortalRoutes.equipmentAvailability,
            Icons.calendar_month_outlined,
            PortalScreenKind.calendar),
        _e(
            'ME-06',
            'Terms',
            'Rate & Terms Management',
            RolePortalRoutes.equipmentTerms,
            Icons.request_quote_outlined,
            PortalScreenKind.finance),
        _e(
            'ME-07',
            'Requests',
            'Booking Requests & Negotiation',
            RolePortalRoutes.equipmentRequests,
            Icons.handshake_outlined,
            PortalScreenKind.inbox),
        _e(
            'ME-08',
            'Handover',
            'Handover Checklist',
            RolePortalRoutes.equipmentHandover,
            Icons.fact_check_outlined,
            PortalScreenKind.manager),
        _e(
            'ME-09',
            'Return',
            'Return Checklist',
            RolePortalRoutes.equipmentReturn,
            Icons.assignment_return_outlined,
            PortalScreenKind.manager),
        _e(
            'ME-10',
            'Earnings',
            'Earnings & Ratings',
            RolePortalRoutes.equipmentEarnings,
            Icons.star_outline_rounded,
            PortalScreenKind.finance),
      ],
    ),
    _portal(
      id: 'crew',
      label: 'Crew & Production Services Portal',
      short: 'Crew',
      description:
          'Crew profile, credits, requests, contracts and work history.',
      icon: Icons.groups_2_outlined,
      home: RolePortalRoutes.crewHome,
      media: 'crew',
      entries: [
        _e('CR-01', 'Home', 'Crew Dashboard', RolePortalRoutes.crewHome,
            Icons.dashboard_outlined, PortalScreenKind.dashboard),
        _e('CR-02', 'Profile', 'Service Profile', RolePortalRoutes.crewProfile,
            Icons.badge_outlined, PortalScreenKind.profile),
        _e(
            'CR-03',
            'Credits',
            'Portfolio & Credits',
            RolePortalRoutes.crewPortfolio,
            Icons.workspace_premium_outlined,
            PortalScreenKind.portfolio),
        _e(
            'CR-04',
            'Calendar',
            'Availability Calendar',
            RolePortalRoutes.crewAvailability,
            Icons.calendar_month_outlined,
            PortalScreenKind.calendar),
        _e(
            'CR-05',
            'Requests',
            'Requests & Negotiation Inbox',
            RolePortalRoutes.crewRequests,
            Icons.inbox_outlined,
            PortalScreenKind.inbox),
        _e(
            'CR-06',
            'Payments',
            'Contracts & Payments',
            RolePortalRoutes.crewContracts,
            Icons.article_outlined,
            PortalScreenKind.finance),
        _e(
            'CR-07',
            'Ratings',
            'Ratings & Work History',
            RolePortalRoutes.crewRatings,
            Icons.history_edu_outlined,
            PortalScreenKind.reports),
      ],
    ),
    _portal(
      id: 'agency',
      label: 'Casting Director / Agency Portal',
      short: 'Agency',
      description: 'Roster, auditions, self-tapes, notes and commissions.',
      icon: Icons.badge_outlined,
      home: RolePortalRoutes.agencyHome,
      media: 'agency',
      entries: [
        _e('CA-01', 'Home', 'Agency Dashboard', RolePortalRoutes.agencyHome,
            Icons.dashboard_outlined, PortalScreenKind.dashboard),
        _e(
            'CA-02',
            'Roster',
            'Talent Roster Manager',
            RolePortalRoutes.agencyRoster,
            Icons.people_alt_outlined,
            PortalScreenKind.manager),
        _e(
            'CA-03',
            'Auditions',
            'Audition Request Inbox',
            RolePortalRoutes.agencyAuditions,
            Icons.inbox_outlined,
            PortalScreenKind.inbox),
        _e(
            'CA-04',
            'Shortlist',
            'Candidate Shortlist Builder',
            RolePortalRoutes.agencyShortlist,
            Icons.view_kanban_outlined,
            PortalScreenKind.manager),
        _e(
            'CA-05',
            'Self-Tapes',
            'Self-Tape Collection',
            RolePortalRoutes.agencySelfTapes,
            Icons.video_collection_outlined,
            PortalScreenKind.portfolio),
        _e(
            'CA-06',
            'Notes',
            'Interview & Selection Notes',
            RolePortalRoutes.agencyNotes,
            Icons.edit_note_outlined,
            PortalScreenKind.detail),
        _e(
            'CA-07',
            'Commission',
            'Commission Settings & Records',
            RolePortalRoutes.agencyCommission,
            Icons.percent_outlined,
            PortalScreenKind.finance),
        _e(
            'CA-08',
            'Records',
            'Agency Booking Records',
            RolePortalRoutes.agencyRecords,
            Icons.receipt_long_outlined,
            PortalScreenKind.reports),
      ],
    ),
    _portal(
      id: 'brand',
      label: 'Brands / Sponsors Portal',
      short: 'Brands',
      description: 'Campaign opportunities, applications, terms and tracking.',
      icon: Icons.campaign_outlined,
      home: RolePortalRoutes.brandHome,
      media: 'brand',
      entries: [
        _e('BR-01', 'Home', 'Brand Dashboard', RolePortalRoutes.brandHome,
            Icons.dashboard_outlined, PortalScreenKind.dashboard),
        _e('BR-02', 'Profile', 'Brand Profile', RolePortalRoutes.brandProfile,
            Icons.business_center_outlined, PortalScreenKind.profile),
        _e(
            'BR-03',
            'Composer',
            'Opportunity Composer',
            RolePortalRoutes.brandComposer,
            Icons.campaign_outlined,
            PortalScreenKind.composer),
        _e(
            'BR-04',
            'Applications',
            'Applications Inbox',
            RolePortalRoutes.brandApplications,
            Icons.inbox_outlined,
            PortalScreenKind.inbox),
        _e(
            'BR-05',
            'Terms',
            'Negotiation & Terms',
            RolePortalRoutes.brandNegotiation,
            Icons.handshake_outlined,
            PortalScreenKind.detail),
        _e(
            'BR-06',
            'Tracker',
            'Campaign Tracker',
            RolePortalRoutes.brandTracker,
            Icons.track_changes_outlined,
            PortalScreenKind.reports),
        _e(
            'BR-07',
            'Payments',
            'Payments & Records',
            RolePortalRoutes.brandPayments,
            Icons.payments_outlined,
            PortalScreenKind.finance),
      ],
    ),
    _portal(
      id: 'legal',
      label: 'Legal Partner Portal',
      short: 'Legal',
      description: 'Review contracts, templates, addendums and billing.',
      icon: Icons.gavel_outlined,
      home: RolePortalRoutes.legalHome,
      media: 'legal',
      entries: [
        _e('LG-01', 'Home', 'Legal Dashboard', RolePortalRoutes.legalHome,
            Icons.dashboard_outlined, PortalScreenKind.dashboard),
        _e(
            'LG-02',
            'Review',
            'Contract Review Request Detail',
            RolePortalRoutes.legalContractReview,
            Icons.article_outlined,
            PortalScreenKind.detail),
        _e(
            'LG-03',
            'Templates',
            'Template Review',
            RolePortalRoutes.legalTemplateReview,
            Icons.library_books_outlined,
            PortalScreenKind.manager),
        _e(
            'LG-04',
            'Addendum',
            'Addendum Review',
            RolePortalRoutes.legalAddendumReview,
            Icons.post_add_outlined,
            PortalScreenKind.detail),
        _e(
            'LG-05',
            'Billing',
            'Review History & Billing',
            RolePortalRoutes.legalBilling,
            Icons.receipt_long_outlined,
            PortalScreenKind.finance),
      ],
    ),
    _portal(
      id: 'insurance',
      label: 'Insurance / Safety Partner Portal',
      short: 'Insurance',
      description: 'Insurance records, claims, safety checks and incidents.',
      icon: Icons.health_and_safety_outlined,
      home: RolePortalRoutes.insuranceHome,
      media: 'insurance',
      entries: [
        _e(
            'IN-01',
            'Home',
            'Insurance / Safety Dashboard',
            RolePortalRoutes.insuranceHome,
            Icons.dashboard_outlined,
            PortalScreenKind.dashboard),
        _e(
            'IN-02',
            'Records',
            'Shoot Insurance Records',
            RolePortalRoutes.insuranceRecords,
            Icons.policy_outlined,
            PortalScreenKind.manager),
        _e('IN-03', 'Claims', 'Claim Support', RolePortalRoutes.insuranceClaims,
            Icons.support_agent_outlined, PortalScreenKind.safety),
        _e(
            'IN-04',
            'Permits',
            'Safety Checks & Permits',
            RolePortalRoutes.insuranceSafety,
            Icons.fact_check_outlined,
            PortalScreenKind.manager),
        _e(
            'IN-05',
            'Incidents',
            'Incident Reports',
            RolePortalRoutes.insuranceIncidents,
            Icons.report_outlined,
            PortalScreenKind.safety),
      ],
    ),
    _portal(
      id: 'distribution',
      label: 'Distribution / Release Partner Portal',
      short: 'Release',
      description: 'Distributor contacts, release coordination and reporting.',
      icon: Icons.public_outlined,
      home: RolePortalRoutes.distributionHome,
      media: 'distribution',
      entries: [
        _e(
            'DS-01',
            'Home',
            'Distribution Dashboard',
            RolePortalRoutes.distributionHome,
            Icons.dashboard_outlined,
            PortalScreenKind.dashboard),
        _e(
            'DS-02',
            'Contacts',
            'Distributor Contacts & Records',
            RolePortalRoutes.distributionContacts,
            Icons.contacts_outlined,
            PortalScreenKind.manager),
        _e(
            'DS-03',
            'Release',
            'Release Coordination',
            RolePortalRoutes.distributionRelease,
            Icons.rocket_launch_outlined,
            PortalScreenKind.calendar),
        _e(
            'DS-04',
            'Reports',
            'Performance Reporting',
            RolePortalRoutes.distributionReports,
            Icons.analytics_outlined,
            PortalScreenKind.reports),
      ],
    ),
  ];

  static RolePortalSpec portalForRoute(String route) {
    return portals.firstWhere(
      (portal) => portal.screens.any((screen) => screen.route == route),
      orElse: () => portals.first,
    );
  }

  static RolePortalScreenSpec screenForRoute(String route) {
    final portal = portalForRoute(route);
    return portal.screens.firstWhere(
      (screen) => screen.route == route,
      orElse: () => portal.screens.first,
    );
  }

  static PortalMediaAsset mediaForCategory(String category) {
    return images.firstWhere(
      (asset) => asset.category == category,
      orElse: () => images.first,
    );
  }

  static List<PortalMetric> metricsFor(RolePortalSpec portal) => [
        PortalMetric(
          label: 'Active Bookings',
          value: portal.id == 'talent' ? '8' : '12',
          delta: '+2 this week',
          icon: Icons.work_outline_rounded,
          tone: PortalMetricTone.blue,
        ),
        const PortalMetric(
          label: 'Awaiting Action',
          value: '5',
          delta: '2 urgent',
          icon: Icons.priority_high_rounded,
          tone: PortalMetricTone.gold,
        ),
        const PortalMetric(
          label: 'Secured Value',
          value: '3.4M',
          delta: 'PKR protected',
          icon: Icons.verified_user_outlined,
          tone: PortalMetricTone.green,
        ),
        const PortalMetric(
          label: 'Rating',
          value: '4.8',
          delta: 'trusted profile',
          icon: Icons.star_outline_rounded,
          tone: PortalMetricTone.purple,
        ),
      ];

  static RolePortalScreenSpec _s(
    String id,
    String nav,
    String title,
    String subtitle,
    String route,
    IconData icon,
    PortalScreenKind kind,
    String primary,
    String secondary,
    String media, {
    List<String> formFields = const [],
  }) {
    return RolePortalScreenSpec(
      id: id,
      navLabel: nav,
      title: title,
      subtitle: subtitle,
      route: route,
      icon: icon,
      kind: kind,
      primaryAction: primary,
      secondaryAction: secondary,
      mediaCategory: media,
      formFields: formFields,
      filters: const ['All', 'Urgent', 'Pending', 'Verified', 'Archived'],
    );
  }

  static ({
    String id,
    String nav,
    String title,
    String route,
    IconData icon,
    PortalScreenKind kind
  }) _e(
    String id,
    String nav,
    String title,
    String route,
    IconData icon,
    PortalScreenKind kind,
  ) {
    return (
      id: id,
      nav: nav,
      title: title,
      route: route,
      icon: icon,
      kind: kind,
    );
  }

  static RolePortalSpec _portal({
    required String id,
    required String label,
    required String short,
    required String description,
    required IconData icon,
    required String home,
    required String media,
    required List<
            ({
              String id,
              String nav,
              String title,
              String route,
              IconData icon,
              PortalScreenKind kind
            })>
        entries,
  }) {
    return RolePortalSpec(
      id: id,
      label: label,
      shortLabel: short,
      description: description,
      icon: icon,
      homeRoute: home,
      screens: entries
          .map(
            (entry) => _s(
              entry.id,
              entry.nav,
              entry.title,
              '${entry.title} for $short with linked bookings, records, forms and lifecycle actions.',
              entry.route,
              entry.icon,
              entry.kind,
              _primaryFor(entry.kind),
              _secondaryFor(entry.kind),
              media,
              formFields: _fieldsFor(entry.kind),
            ),
          )
          .toList(),
    );
  }

  static String _primaryFor(PortalScreenKind kind) {
    return switch (kind) {
      PortalScreenKind.dashboard => 'Review actions',
      PortalScreenKind.profile => 'Save profile',
      PortalScreenKind.portfolio => 'Add media',
      PortalScreenKind.calendar => 'Save calendar',
      PortalScreenKind.inbox => 'Respond',
      PortalScreenKind.detail => 'Approve terms',
      PortalScreenKind.composer => 'Submit',
      PortalScreenKind.manager => 'Save changes',
      PortalScreenKind.finance => 'Generate receipt',
      PortalScreenKind.safety => 'Submit report',
      PortalScreenKind.reports => 'Export report',
    };
  }

  static String _secondaryFor(PortalScreenKind kind) {
    return switch (kind) {
      PortalScreenKind.dashboard => 'Open records',
      PortalScreenKind.profile => 'Preview',
      PortalScreenKind.portfolio => 'Reorder',
      PortalScreenKind.calendar => 'Add hold',
      PortalScreenKind.inbox => 'Ask question',
      PortalScreenKind.detail => 'Request change',
      PortalScreenKind.composer => 'Save draft',
      PortalScreenKind.manager => 'Bulk update',
      PortalScreenKind.finance => 'Open ledger',
      PortalScreenKind.safety => 'Add evidence',
      PortalScreenKind.reports => 'Schedule email',
    };
  }

  static List<String> _fieldsFor(PortalScreenKind kind) {
    return switch (kind) {
      PortalScreenKind.profile => [
          'Display name',
          'City',
          'Bio',
          'Verification note'
        ],
      PortalScreenKind.composer => ['Title', 'Budget / rate', 'Dates', 'Terms'],
      PortalScreenKind.manager => [
          'Record name',
          'Category',
          'Availability',
          'Internal note'
        ],
      PortalScreenKind.finance => [
          'Amount',
          'Milestone',
          'Reference',
          'Payout note'
        ],
      PortalScreenKind.safety => [
          'Issue summary',
          'Severity',
          'Evidence note',
          'Contact preference'
        ],
      _ => ['Search note', 'Status update', 'Decision reason'],
    };
  }
}

class RolePortalDemoStore extends ChangeNotifier {
  RolePortalDemoStore._();

  static final instance = RolePortalDemoStore._();

  final Map<String, String> _submitted = {};
  final Set<String> _shortlisted = {'BK-2048'};
  int lifecycleIndex = 2;

  Map<String, String> get submitted => Map.unmodifiable(_submitted);
  Set<String> get shortlisted => Set.unmodifiable(_shortlisted);

  void save(String key, String value) {
    _submitted[key] = value;
    notifyListeners();
  }

  void toggleShortlist(String id) {
    if (_shortlisted.contains(id)) {
      _shortlisted.remove(id);
    } else {
      _shortlisted.add(id);
    }
    notifyListeners();
  }

  void advanceLifecycle() {
    lifecycleIndex = (lifecycleIndex + 1)
        .clamp(0, BookingLifecycleStatus.values.length - 1)
        .toInt();
    notifyListeners();
  }

  BookingLifecycleStatus get currentStatus =>
      BookingLifecycleStatus.values[lifecycleIndex];
}
