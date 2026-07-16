part of '../super_admin_screens.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _flagged = false;

  @override
  Widget build(BuildContext context) {
    final booking = AdminMockData.bookings.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _headline(
                        context, '${booking.id} - ${booking.project}'),
                  ),
                  AdminStatusBadge(
                      label: booking.status, tone: AdminDecisionTone.warning),
                ],
              ),
              const SizedBox(height: 8),
              _text(context,
                  '${booking.parties} - ${booking.city} - ${booking.category}'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AdminStatusBadge(
                      label: booking.value, tone: AdminDecisionTone.info),
                  AdminRiskBadge(
                    label: _flagged ? 'Flagged' : booking.risk,
                    risk: _flagged || booking.risk != 'No risk'
                        ? AdminRiskTone.high
                        : AdminRiskTone.low,
                  ),
                  AdminStatusBadge(
                      label: 'Activity ${booking.activity}',
                      tone: AdminDecisionTone.neutral),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AdminSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reviewCard(context, 'Negotiation Summary', const [
                'Offer sent - 10:12 AM - producer',
                'Counteroffer submitted - 11:04 AM - stakeholder',
                'Terms approved - both parties',
              ]),
              _reviewDivider(context),
              _reviewCard(context, 'Contract Status', const [
                'Template: Actor Booking Agreement v1.0',
                'Signature pending - payee',
                'Usage rights clause included',
              ]),
              _reviewDivider(context),
              _reviewCard(context, 'Payment Status', const [
                'Deposit expected PKR 90,000',
                'Proof not yet uploaded',
                'Milestone: Deposit',
              ]),
              _reviewDivider(context),
              const AdminSectionHeader(
                title: 'Timeline',
                icon: Icons.history_rounded,
              ),
              const SizedBox(height: 8),
              const AdminTimeline(
                items: [
                  'Offer sent - 10:12 AM - producer',
                  'Counteroffer submitted - 11:04 AM - stakeholder',
                  'Terms approved - pending signature',
                  'Payment proof not yet verified',
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AdminSurface(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AdminActionButton(
                icon: Icons.description_outlined,
                label: 'Open Contract',
                secondary: true,
                onTap: () => Navigator.pushNamed(
                    context, SuperAdminRoutes.contractTemplates),
              ),
              AdminActionButton(
                icon: Icons.payments_outlined,
                label: 'Open Payment',
                secondary: true,
                onTap: () => Navigator.pushNamed(
                    context, SuperAdminRoutes.paymentReview),
              ),
              AdminActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'View Chat',
                secondary: true,
                onTap: () => Navigator.pushNamed(context, CoreRoutes.chat),
              ),
              AdminActionButton(
                icon: _flagged ? Icons.flag_rounded : Icons.flag_outlined,
                label: _flagged ? 'Flagged' : 'Flag Booking',
                secondary: true,
                onTap: _flagged
                    ? null
                    : () => _noteDialog(
                          context,
                          'Flag booking - reason',
                          onSave: () => setState(() => _flagged = true),
                        ),
              ),
              AdminActionButton(
                icon: Icons.gpp_maybe_outlined,
                label: 'Open Dispute',
                onTap: () =>
                    Navigator.pushNamed(context, SuperAdminRoutes.disputeCase),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
