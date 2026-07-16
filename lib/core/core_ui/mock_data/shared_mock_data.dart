import 'package:flutter/material.dart';

import '../core_routes.dart';
import '../models/shared_models.dart';

class SharedMockData {
  SharedMockData._();

  static const roles = [
    CineRole(
      icon: Icons.movie_creation_outlined,
      name: 'Director / Producer',
      description:
          'Create projects, book talent, manage contracts and payments.',
    ),
    CineRole(
      icon: Icons.theater_comedy_outlined,
      name: 'Actor / Talent',
      description:
          'Receive offers, manage portfolio, negotiate and sign contracts.',
    ),
    CineRole(
      icon: Icons.style_outlined,
      name: 'Model',
      description:
          'Manage campaigns, usage rights, releases and brand bookings.',
    ),
    CineRole(
      icon: Icons.location_city_outlined,
      name: 'Location Owner',
      description:
          'List homes, studios, rooftops and shootable spaces securely.',
    ),
    CineRole(
      icon: Icons.videocam_outlined,
      name: 'Media / Equipment Provider',
      description:
          'Offer cameras, lights, drones, crews and production packages.',
    ),
    CineRole(
      icon: Icons.groups_2_outlined,
      name: 'Crew / Services',
      description:
          'Offer makeup, styling, DOP, editing, writing, transport and more.',
    ),
    CineRole(
      icon: Icons.badge_outlined,
      name: 'Casting Agency',
      description: 'Manage rosters, auditions, shortlists and agency bookings.',
    ),
    CineRole(
      icon: Icons.campaign_outlined,
      name: 'Brand / Sponsor',
      description:
          'Post campaigns, product placements and sponsorship opportunities.',
    ),
    CineRole(
      icon: Icons.gavel_outlined,
      name: 'Legal Partner',
      description: 'Review contracts, templates, addendums and billing.',
    ),
    CineRole(
      icon: Icons.health_and_safety_outlined,
      name: 'Insurance / Safety Partner',
      description:
          'Support shoot insurance, claims, permits and safety checks.',
    ),
    CineRole(
      icon: Icons.public_outlined,
      name: 'Distribution / Release Partner',
      description: 'Coordinate release partners, records and performance data.',
    ),
  ];

  static const cities = [
    'Lahore',
    'Karachi',
    'Islamabad',
    'Rawalpindi',
    'Multan',
  ];

  static const notifications = [
    CoreNotification(
      icon: Icons.edit_document,
      title: 'Contract awaiting your signature',
      message: 'Actor Booking Agreement for TVC Shoot — Lahore is ready.',
      time: '8 min ago',
      category: CoreNotificationCategory.contracts,
      routeName: CoreRoutes.contract,
      unread: true,
    ),
    CoreNotification(
      icon: Icons.verified_user_outlined,
      title: 'Payment proof under verification',
      message: 'Deposit proof for BK-2048 has been sent to Super Admin.',
      time: '28 min ago',
      category: CoreNotificationCategory.payments,
      routeName: CoreRoutes.ledger,
      unread: true,
    ),
    CoreNotification(
      icon: Icons.swap_horiz_rounded,
      title: 'New counteroffer received',
      message: 'Ali Khan proposed PKR 180,000 for Fashion Campaign — Karachi.',
      time: '1 hr ago',
      category: CoreNotificationCategory.bookings,
      routeName: CoreRoutes.chat,
      unread: true,
    ),
    CoreNotification(
      icon: Icons.verified_outlined,
      title: 'KYC approved',
      message: 'Your Director / Producer profile is now verified.',
      time: 'Today',
      category: CoreNotificationCategory.system,
      routeName: CoreRoutes.verificationStatus,
      unread: false,
    ),
    CoreNotification(
      icon: Icons.calendar_month_outlined,
      title: 'Shoot reminder for tomorrow',
      message: 'Drama Episode Shoot — Islamabad begins at 8:00 AM.',
      time: 'Yesterday',
      category: CoreNotificationCategory.bookings,
      routeName: CoreRoutes.chat,
      unread: false,
    ),
    CoreNotification(
      icon: Icons.support_agent_outlined,
      title: 'Admin requested payment clarification',
      message: 'Please add a clearer transaction reference for Final Payment.',
      time: 'Mon',
      category: CoreNotificationCategory.payments,
      routeName: CoreRoutes.paymentProof,
      unread: false,
    ),
  ];

  static const chatMessages = [
    ChatMessage(
      sender: 'Sara Ahmed',
      message: 'We need the actor on set by 7:30 AM for wardrobe and blocking.',
      time: '10:12 AM',
      mine: false,
    ),
    ChatMessage(
      sender: 'You',
      message:
          'Confirmed. Please keep transport details in the booking record.',
      time: '10:18 AM',
      mine: true,
    ),
    ChatMessage(
      sender: 'Ali Khan',
      message:
          'Pinned: Final call time locked at 7:30 AM, Lahore Cantt location.',
      time: '10:22 AM',
      mine: false,
      type: ChatMessageType.decision,
      pinned: true,
    ),
    ChatMessage(
      sender: 'Sara Ahmed',
      message: 'Wardrobe reference board',
      time: '10:26 AM',
      mine: false,
      type: ChatMessageType.image,
    ),
    ChatMessage(
      sender: 'You',
      message: 'Updated addendum draft',
      time: '10:31 AM',
      mine: true,
      type: ChatMessageType.pdf,
    ),
    ChatMessage(
      sender: 'Ali Khan',
      message: 'Voice note · 0:24',
      time: '10:35 AM',
      mine: false,
      type: ChatMessageType.voice,
    ),
  ];

  static const clauses = [
    ContractClause(
        title: 'Parties', value: 'Sara Ahmed Productions and Ali Khan'),
    ContractClause(title: 'Project name', value: 'TVC Shoot — Lahore'),
    ContractClause(title: 'Shoot dates', value: 'August 14-15, 2026'),
    ContractClause(
        title: 'Fee', value: 'PKR 180,000 inclusive of one shoot day'),
    ContractClause(
        title: 'Payment schedule',
        value: '40% deposit, 40% shoot day, 20% final delivery'),
    ContractClause(
        title: 'Deliverables',
        value: 'Performance for 30-second TVC plus stills usage'),
    ContractClause(
        title: 'Usage rights',
        value: 'Pakistan digital, TV, OOH for 12 months'),
    ContractClause(
        title: 'Cancellation terms',
        value: '48-hour cancellation fee applies after contract signing'),
    ContractClause(
        title: 'Overtime',
        value: 'PKR 18,000 per additional hour after 10 hours'),
    ContractClause(
        title: 'Dispute process',
        value: 'CineConnect admin mediation before external escalation'),
    ContractClause(
        title: 'Special conditions',
        value: 'Phone and exact address remain hidden until secured booking'),
  ];

  static const milestones = [
    PaymentMilestone(name: 'Deposit', amount: 72000),
    PaymentMilestone(name: 'Milestone 1', amount: 60000),
    PaymentMilestone(name: 'Shoot-Day Payment', amount: 72000),
    PaymentMilestone(name: 'Final Payment', amount: 36000),
    PaymentMilestone(name: 'Damage Deposit', amount: 50000),
  ];

  static const ledgerRows = [
    LedgerRowData(
      projectName: 'TVC Shoot — Lahore',
      bookingId: 'BK-2048',
      milestone: 'Deposit',
      amount: 72000,
      direction: LedgerDirection.outgoing,
      status: LedgerStatus.pendingVerification,
      date: 'Jul 7, 2026',
      receiptId: 'RCPT-7821',
      transactionId: 'HBL-884120',
    ),
    LedgerRowData(
      projectName: 'Fashion Campaign — Karachi',
      bookingId: 'BK-2021',
      milestone: 'Final Payment',
      amount: 140000,
      direction: LedgerDirection.incoming,
      status: LedgerStatus.verified,
      date: 'Jul 4, 2026',
      receiptId: 'RCPT-7794',
      transactionId: 'UBL-102993',
    ),
    LedgerRowData(
      projectName: 'Drama Episode Shoot — Islamabad',
      bookingId: 'BK-1986',
      milestone: 'Milestone 1',
      amount: 95000,
      direction: LedgerDirection.outgoing,
      status: LedgerStatus.released,
      date: 'Jun 29, 2026',
      receiptId: 'RCPT-7710',
      transactionId: 'JAZZ-443210',
    ),
    LedgerRowData(
      projectName: 'Music Video — Lahore',
      bookingId: 'BK-1932',
      milestone: 'Damage Deposit',
      amount: 50000,
      direction: LedgerDirection.incoming,
      status: LedgerStatus.disputed,
      date: 'Jun 22, 2026',
      receiptId: 'RCPT-7622',
      transactionId: 'BAFL-762991',
    ),
  ];

  static List<String> roleDocuments(String role) {
    if (role.contains('Location')) {
      return [
        'Property ownership/rent proof',
        'Utility bill optional',
        'Location permission declaration',
      ];
    }
    if (role.contains('Media') || role.contains('Equipment')) {
      return [
        'Business document',
        'Equipment ownership/proof',
        'Service portfolio',
      ];
    }
    if (role.contains('Actor') || role.contains('Model')) {
      return [
        'Portfolio/showreel optional',
        'Agency letter optional',
      ];
    }
    return [
      'Company registration optional',
      'Production house proof optional',
      'Business card/portfolio optional',
    ];
  }
}
