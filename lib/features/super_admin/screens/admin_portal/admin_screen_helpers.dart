part of '../super_admin_screens.dart';

class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minTileWidth;
  final double childAspectRatio;

  const _ResponsiveGrid({
    required this.children,
    this.minTileWidth = 260,
    this.childAspectRatio = 1.25,
  });

  @override
  Widget build(BuildContext context) {
    if (children.every((child) => child is AdminMetricTile)) {
      return MetricActionRail(
        items: [
          for (final child in children.cast<AdminMetricTile>())
            child.toActionItem(context),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            (constraints.maxWidth / minTileWidth).floor().clamp(1, 4);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (_, index) => children[index],
        );
      },
    );
  }
}

class _TwoPane extends StatelessWidget {
  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;

  const _TwoPane({
    required this.left,
    required this.right,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  @override
  Widget build(BuildContext context) {
    // Keyed off total window width (not the local, sidebar-shrunk content
    // width) and aligned to AppBreakpoints.laptop — the same threshold
    // AdminScreenScaffold uses to show the side nav — so this pane never
    // ends up stacked while the desktop chrome is already showing.
    if (context.isDesktopWidth) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: leftFlex, child: left),
          const SizedBox(width: 16),
          Expanded(flex: rightFlex, child: right),
        ],
      );
    }
    return Column(
      children: [
        left,
        const SizedBox(height: 16),
        right,
      ],
    );
  }
}

class _ThreePane extends StatelessWidget {
  final Widget left;
  final Widget center;
  final Widget right;

  const _ThreePane({
    required this.left,
    required this.center,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    // Three fixed-plus-flexible columns need more room than a two-pane
    // split, so this waits for AppBreakpoints.wideDesktop rather than
    // .laptop — the side nav can appear slightly before this pane goes
    // three-column, but it never shows a cramped, broken row (unlike the
    // old 1040 local-width threshold, which was reachable through the
    // side nav's own space and produced ~250px center columns).
    if (MediaQuery.sizeOf(context).width >= AppBreakpoints.wideDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 270, child: left),
          const SizedBox(width: 16),
          Expanded(child: center),
          const SizedBox(width: 16),
          SizedBox(width: 320, child: right),
        ],
      );
    }
    return Column(
      children: [
        left,
        const SizedBox(height: 16),
        center,
        const SizedBox(height: 16),
        right,
      ],
    );
  }
}

Widget _text(BuildContext context, String text, {bool strong = false}) {
  final colors = context.appColors;
  return Text(
    text,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: (strong ? AppTextStyles.label : AppTextStyles.caption).copyWith(
      color: strong ? colors.textPrimary : colors.textSecondary,
      fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
      height: 1.28,
    ),
  );
}

Widget _headline(BuildContext context, String text) {
  final colors = context.appColors;
  return Text(
    text,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: AppTextStyles.cardTitle.copyWith(
      color: colors.textPrimary,
    ),
  );
}

Widget _tinyAction(BuildContext context, String label, VoidCallback? onTap) {
  return TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      minimumSize: const Size(0, 44),
      tapTargetSize: MaterialTapTargetSize.padded,
    ),
    child: Text(label),
  );
}

Widget _kv(BuildContext context, String label, String value) {
  final colors = context.appColors;
  return Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _bullet(BuildContext context, String text) {
  final colors = context.appColors;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline, color: colors.goldDark, size: 17),
        const SizedBox(width: 8),
        Expanded(child: _text(context, text)),
      ],
    ),
  );
}

Widget _dropdown(
  BuildContext context,
  String label,
  String value,
  List<String> values,
  ValueChanged<String> onChanged,
) {
  return SizedBox(
    width: 230,
    child: CoreDropdownField<String>(
      value: value,
      values: values,
      label: label,
      icon: Icons.filter_list_rounded,
      onChanged: (next) => onChanged(next ?? value),
    ),
  );
}

Widget _clauseEditor(BuildContext context, String clause) {
  final colors = context.appColors;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: colors.borderMuted)),
    ),
    child: Row(
      children: [
        Expanded(child: _text(context, clause, strong: true)),
        AdminStatusBadge(label: 'Required', tone: AdminDecisionTone.info),
      ],
    ),
  );
}

/// A titled group of bullet rows meant to live *inside* a single
/// [AdminSurface] alongside other [_reviewCard] sections, separated by
/// [_reviewDivider] — not its own bordered/shadowed card. Stacking several
/// of these inside one surface reads as one document with sections rather
/// than a tall pile of separately-chromed cards.
Widget _reviewCard(BuildContext context, String title, List<String> rows) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _headline(context, title),
      const SizedBox(height: 7),
      ...rows.map((row) => _bullet(context, row)),
    ],
  );
}

Widget _reviewDivider(BuildContext context) {
  final colors = context.appColors;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Divider(height: 1, thickness: 1, color: colors.border),
  );
}

void _staffSheet(BuildContext context) {
  void assign(String name) {
    Navigator.pop(context);
    showCoreSnack(context, 'Assigned to $name');
  }

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => AdminDetailDrawer(
      title: 'Assign Admin Staff',
      children: [
        AdminUserMiniCard(
          name: 'Ayesha',
          detail: 'Verification Agent - 12 open',
          badge: 'KYC',
          onTap: () => assign('Ayesha'),
        ),
        const SizedBox(height: 10),
        AdminUserMiniCard(
          name: 'Raamiz',
          detail: 'Payments Officer - 8 open',
          badge: 'Payments',
          onTap: () => assign('Raamiz'),
        ),
        const SizedBox(height: 10),
        AdminUserMiniCard(
          name: 'Mahnoor',
          detail: 'Content Moderator - 6 open',
          badge: 'Content',
          onTap: () => assign('Mahnoor'),
        ),
      ],
    ),
  );
}

void _noteDialog(BuildContext context, String title, {VoidCallback? onSave}) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final colors = dialogContext.appColors;
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: colors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            title,
            style: AppTextStyles.sectionHeaderStyle
                .copyWith(color: colors.textPrimary),
          ),
          content: SizedBox(
            width: 360,
            child: CoreTextField(
              controller: controller,
              label: 'Note for audit log',
              icon: Icons.edit_note_outlined,
              maxLines: 3,
              onChanged: (_) => setDialogState(() {}),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                      onSave?.call();
                      showCoreSnack(
                          context, 'Note written to audit log: "$title"');
                    },
              child: const Text('Save Note'),
            ),
          ],
        ),
      );
    },
  );
}

void _confirm(BuildContext context, String title) {
  showAdminDecisionDialog(
    context,
    title: title,
    message: 'This static admin action will be logged for the demo.',
    action: 'Confirm',
    onConfirm: () => showCoreSnack(context, '$title confirmed'),
  );
}

void _previewListing(BuildContext context, AdminListing listing) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.appColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(listing.title),
      content: Text(
          '${listing.category} - ${listing.city} - ${listing.price}\nPublic listing preview is ready for moderation.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
    ),
  );
}

class AdminMockDataProxy {
  AdminMockDataProxy._();

  static const ledgerRow = LedgerRowData(
    projectName: 'Fashion Campaign - Karachi',
    bookingId: 'BK-2052',
    milestone: 'Final Payment',
    amount: 220000,
    direction: LedgerDirection.outgoing,
    status: LedgerStatus.pendingVerification,
    date: 'Jul 8, 2026',
    receiptId: 'RCPT-DSP-441',
    transactionId: 'HBL-884120',
  );
}
