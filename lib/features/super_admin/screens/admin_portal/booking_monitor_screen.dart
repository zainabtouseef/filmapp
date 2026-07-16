part of '../super_admin_screens.dart';

class BookingMonitorScreen extends StatefulWidget {
  const BookingMonitorScreen({super.key});

  @override
  State<BookingMonitorScreen> createState() => _BookingMonitorScreenState();
}

class _BookingMonitorScreenState extends State<BookingMonitorScreen> {
  final Set<String> _flagged = {};
  String _filter = 'Status';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFilterBar(
          filters: const [
            'Category',
            'City',
            'Booking value',
            'Status',
            'Risk flagged',
            'Date range'
          ],
          selected: _filter,
          onSelected: (value) {
            setState(() => _filter = value);
            showCoreSnack(context, 'Filter state changed');
          },
        ),
        const SizedBox(height: 16),
        ...AdminMockData.bookings.map((booking) {
          final flagged = _flagged.contains(booking.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BookingRow(
              booking: booking,
              flagged: flagged,
              onOpen: () =>
                  Navigator.pushNamed(context, SuperAdminRoutes.bookingDetail),
              onFlag: flagged
                  ? null
                  : () => _noteDialog(
                        context,
                        'Flag ${booking.id} - reason',
                        onSave: () =>
                            setState(() => _flagged.add(booking.id)),
                      ),
            ),
          );
        }),
      ],
    );
  }
}

class _BookingRow extends StatelessWidget {
  final AdminBooking booking;
  final bool flagged;
  final VoidCallback onOpen;
  final VoidCallback? onFlag;

  const _BookingRow({
    required this.booking,
    required this.flagged,
    required this.onOpen,
    required this.onFlag,
  });

  static const _categoryIcons = {
    'Actor': Icons.theater_comedy_outlined,
    'Model': Icons.face_retouching_natural_outlined,
    'Location': Icons.apartment_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final icon = _categoryIcons[booking.category] ?? Icons.work_outline_rounded;
    return GestureDetector(
      onTap: onOpen,
      child: AdminSurface(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colors.goldGlow.withValues(alpha: 0.16),
              ),
              child: Icon(icon, color: colors.goldDark, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${booking.id} - ${booking.project}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        booking.value,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.goldDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${booking.parties} - ${booking.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.micro.copyWith(
                      color: colors.textSecondary,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      AdminStatusBadge(
                          label: booking.status,
                          tone: AdminDecisionTone.warning),
                      AdminRiskBadge(
                        label: flagged ? 'Flagged' : booking.risk,
                        risk: flagged || booking.risk != 'No risk'
                            ? AdminRiskTone.high
                            : AdminRiskTone.low,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ReviewOutlineButton(label: 'Open', onTap: onOpen),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onFlag,
                  child: Icon(
                    flagged ? Icons.flag_rounded : Icons.flag_outlined,
                    size: 18,
                    color: flagged ? colors.danger : colors.iconMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
