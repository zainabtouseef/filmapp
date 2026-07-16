part of '../super_admin_screens.dart';

class ReviewHubScreen extends StatelessWidget {
  const ReviewHubScreen({super.key});

  static const _summary = [
    _ReviewSummaryData(
      label: 'People Pending',
      value: '12',
      subtext: '3 today',
      icon: Icons.groups_rounded,
      tone: AdminDecisionTone.danger,
      route: SuperAdminRoutes.reviewHubPeople,
    ),
    _ReviewSummaryData(
      label: 'Listings Pending',
      value: '18',
      subtext: '5 today',
      icon: Icons.storefront_outlined,
      tone: AdminDecisionTone.warning,
      route: SuperAdminRoutes.reviewHubListings,
    ),
    _ReviewSummaryData(
      label: 'Content Reports',
      value: '9',
      subtext: '2 today',
      icon: Icons.flag_outlined,
      tone: AdminDecisionTone.info,
      route: SuperAdminRoutes.reviewHubContent,
    ),
    _ReviewSummaryData(
      label: 'High Risk',
      value: '4',
      subtext: 'Requires attention',
      icon: Icons.warning_amber_rounded,
      tone: AdminDecisionTone.danger,
      route: SuperAdminRoutes.auditLogs,
    ),
  ];

  static const _people = [
    _ReviewPersonData(
      name: 'Ali Khan',
      role: 'Actor / Talent',
      city: 'Lahore',
      docsDone: 4,
      docsTotal: 5,
      risk: 'Low Risk',
      time: '2h ago',
      asset: AppAssets.bilalAbbas,
      tone: AdminDecisionTone.success,
    ),
    _ReviewPersonData(
      name: 'Sara Malik',
      role: 'Model',
      city: 'Karachi',
      docsDone: 5,
      docsTotal: 5,
      risk: 'Medium Risk',
      time: '18h ago',
      asset: AppAssets.sanaKhalid,
      tone: AdminDecisionTone.warning,
    ),
    _ReviewPersonData(
      name: 'FrameHouse Pvt Ltd',
      role: 'Media Provider',
      city: 'Lahore',
      docsDone: 6,
      docsTotal: 6,
      risk: 'High Risk',
      time: '1d ago',
      tone: AdminDecisionTone.danger,
    ),
  ];

  static const _listings = [
    _ReviewListingData(
      title: 'Gulberg Heritage Home',
      owner: 'Sara Malik',
      city: 'Lahore',
      category: 'Location',
      price: 'PKR 95k/day',
      deposit: 'Deposit PKR 50k',
      status: 'Pending',
      icon: Icons.apartment_rounded,
      tone: AdminDecisionTone.warning,
    ),
    _ReviewListingData(
      title: 'ARRI Alexa Mini Package',
      owner: 'FrameHouse Pvt Ltd',
      city: 'Karachi',
      category: 'Equipment',
      price: 'PKR 80k/day',
      deposit: 'Deposit PKR 120k',
      status: 'Pending',
      icon: Icons.videocam_outlined,
      tone: AdminDecisionTone.info,
    ),
    _ReviewListingData(
      title: 'Makeup + Hair Team',
      owner: 'Glam Pro Studio',
      city: 'Lahore',
      category: 'Service',
      price: 'PKR 45k',
      deposit: 'Deposit PKR 15k',
      status: 'SLA 24h+',
      icon: Icons.brush_outlined,
      tone: AdminDecisionTone.info,
    ),
    _ReviewListingData(
      title: 'Lighting Kit Pro Bundle',
      owner: 'Northstar Crew',
      city: 'Islamabad',
      category: 'Equipment',
      price: 'PKR 60k/day',
      deposit: 'Deposit PKR 80k',
      status: 'Pending',
      icon: Icons.lightbulb_outline_rounded,
      tone: AdminDecisionTone.warning,
    ),
    _ReviewListingData(
      title: 'DOP + Gaffer Crew Bundle',
      owner: 'Northstar Crew',
      city: 'Islamabad',
      category: 'Services',
      price: 'PKR 180k',
      deposit: 'Deposit PKR 35k',
      status: 'High Risk',
      icon: Icons.groups_2_outlined,
      tone: AdminDecisionTone.danger,
    ),
  ];

  static const _content = [
    _ReviewContentData(
      title: 'Rooftop location gallery',
      owner: 'Gulberg House',
      role: 'Location Owner',
      time: '3h ago',
      visibility: 'Public pending',
      watermark: 'Passed',
      reports: '1 report',
      icon: Icons.landscape_outlined,
      tone: AdminDecisionTone.info,
    ),
    _ReviewContentData(
      title: 'Drone reel rate claim',
      owner: 'FrameHouse Pvt Ltd',
      role: 'Media Provider',
      time: 'Today',
      visibility: 'Review required',
      watermark: 'N/A',
      reports: '0 reports',
      icon: Icons.flight_takeoff_rounded,
      tone: AdminDecisionTone.warning,
    ),
    _ReviewContentData(
      title: 'Fashion campaign portfolio set',
      owner: 'Sara Malik',
      role: 'Model',
      time: '32m ago',
      visibility: 'Public pending',
      watermark: 'Passed',
      reports: '0 reports',
      icon: Icons.photo_camera_outlined,
      tone: AdminDecisionTone.info,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReviewSummaryStrip(
          items: _summary,
          onRouteTap: (route) => Navigator.pushNamed(context, route),
        ),
        const SizedBox(height: 16),
        _ReviewPeopleSection(
          people: _people,
          onReview: () =>
              Navigator.pushNamed(context, SuperAdminRoutes.verificationDetail),
          onViewAll: () =>
              Navigator.pushNamed(context, SuperAdminRoutes.reviewHubPeople),
        ),
        const SizedBox(height: 16),
        _ReviewListingsSection(
          listings: _listings,
          onOpen: (listing) => _previewListing(
            context,
            AdminListing(
              title: listing.title,
              owner: listing.owner,
              city: listing.city,
              category: listing.category,
              price: listing.price,
              deposit: listing.deposit.replaceFirst('Deposit ', ''),
              date: 'Today',
              visibility: 'Public preview',
              status: listing.status,
            ),
          ),
          onViewAll: () =>
              Navigator.pushNamed(context, SuperAdminRoutes.reviewHubListings),
        ),
        const SizedBox(height: 16),
        _ReviewContentSection(
          items: _content,
          onViewAll: () =>
              Navigator.pushNamed(context, SuperAdminRoutes.reviewHubContent),
        ),
      ],
    );
  }
}

class _ReviewSummaryData {
  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final AdminDecisionTone tone;
  final String route;

  const _ReviewSummaryData({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.tone,
    required this.route,
  });
}

class _ReviewPersonData {
  final String name;
  final String role;
  final String city;
  final int docsDone;
  final int docsTotal;
  final String risk;
  final String time;
  final String? asset;
  final AdminDecisionTone tone;

  const _ReviewPersonData({
    required this.name,
    required this.role,
    required this.city,
    required this.docsDone,
    required this.docsTotal,
    required this.risk,
    required this.time,
    this.asset,
    required this.tone,
  });
}

class _ReviewListingData {
  final String title;
  final String owner;
  final String city;
  final String category;
  final String price;
  final String deposit;
  final String status;
  final IconData icon;
  final AdminDecisionTone tone;

  const _ReviewListingData({
    required this.title,
    required this.owner,
    required this.city,
    required this.category,
    required this.price,
    required this.deposit,
    required this.status,
    required this.icon,
    required this.tone,
  });
}

class _ReviewContentData {
  final String title;
  final String owner;
  final String role;
  final String time;
  final String visibility;
  final String watermark;
  final String reports;
  final IconData icon;
  final AdminDecisionTone tone;

  const _ReviewContentData({
    required this.title,
    required this.owner,
    required this.role,
    required this.time,
    required this.visibility,
    required this.watermark,
    required this.reports,
    required this.icon,
    required this.tone,
  });
}

class _ReviewSummaryStrip extends StatelessWidget {
  final List<_ReviewSummaryData> items;
  final ValueChanged<String> onRouteTap;

  const _ReviewSummaryStrip({
    required this.items,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    return AdminQuickActionsSection(
      items: items
          .map(
            (item) => MetricActionItem(
              icon: item.icon,
              value: item.value,
              title: item.label,
              subtitle: item.subtext,
              accentColor: _dashboardToneColor(context, item.tone),
              onTap: () => onRouteTap(item.route),
            ),
          )
          .toList(),
    );
  }
}

class _ReviewPeopleSection extends StatelessWidget {
  final List<_ReviewPersonData> people;
  final VoidCallback onReview;
  final VoidCallback onViewAll;

  const _ReviewPeopleSection({
    required this.people,
    required this.onReview,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          _ReviewSectionHeader(
            title: 'People Verification',
            icon: Icons.manage_accounts_outlined,
            action: 'View All People',
            onAction: onViewAll,
          ),
          const SizedBox(height: 12),
          ...people.asMap().entries.map((entry) {
            return _ReviewPersonRow(
              person: entry.value,
              onReview: onReview,
              showDivider: entry.key != people.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _ReviewPersonRow extends StatelessWidget {
  final _ReviewPersonData person;
  final VoidCallback onReview;
  final bool showDivider;

  const _ReviewPersonRow({
    required this.person,
    required this.onReview,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = _dashboardToneColor(context, person.tone);
    return Container(
      padding: EdgeInsets.only(bottom: showDivider ? 10 : 2),
      margin: EdgeInsets.only(bottom: showDivider ? 10 : 0),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: SizedBox(
        height: 94,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ReviewAvatar(person: person),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${person.role} - ${person.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.micro.copyWith(
                      color: colors.textSecondary,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${person.docsDone}/${person.docsTotal}',
                        style: AppTextStyles.micro.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: person.docsDone / person.docsTotal,
                            minHeight: 3,
                            color: toneColor,
                            backgroundColor:
                                colors.borderMuted.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 92,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AdminStatusBadge(label: person.risk, tone: person.tone),
                  const SizedBox(height: 6),
                  Text(
                    person.time,
                    maxLines: 1,
                    style: AppTextStyles.micro.copyWith(
                      color: colors.textSecondary,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ReviewOutlineButton(label: 'Review', onTap: onReview),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewAvatar extends StatelessWidget {
  final _ReviewPersonData person;

  const _ReviewAvatar({required this.person});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipOval(
              child: person.asset == null
                  ? Container(
                      color: colors.softSurface,
                      alignment: Alignment.center,
                      child: Text(
                        'FH',
                        style: AppTextStyles.caption.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : Image.asset(person.asset!, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
                border: Border.all(
                    color: _dashboardToneColor(context, person.tone)),
              ),
              child: Icon(
                Icons.verified_user_outlined,
                color: _dashboardToneColor(context, person.tone),
                size: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewListingsSection extends StatelessWidget {
  final List<_ReviewListingData> listings;
  final ValueChanged<_ReviewListingData> onOpen;
  final VoidCallback onViewAll;

  const _ReviewListingsSection({
    required this.listings,
    required this.onOpen,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _ReviewSectionHeader(
              title: 'Listings Review',
              icon: Icons.storefront_outlined,
              action: 'View All Listings',
              onAction: onViewAll,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 278,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 16),
              itemCount: listings.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return SizedBox(
                  width: 168,
                  child: _ReviewListingCard(
                    listing: listing,
                    onOpen: () => onOpen(listing),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewListingCard extends StatelessWidget {
  final _ReviewListingData listing;
  final VoidCallback onOpen;

  const _ReviewListingCard({
    required this.listing,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = _dashboardToneColor(context, listing.tone);
    return Container(
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderMuted),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 66,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        toneColor.withValues(alpha: 0.34),
                        colors.softSurface.withValues(alpha: 0.84),
                        colors.surface.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                  child: Icon(listing.icon, color: toneColor, size: 32),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: AdminStatusBadge(
                      label: listing.category, tone: listing.tone),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${listing.owner} - ${listing.city}',
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
                          label: listing.price, tone: AdminDecisionTone.info),
                      AdminStatusBadge(
                          label: listing.deposit.replaceFirst('Deposit ', ''),
                          tone: AdminDecisionTone.neutral),
                      AdminStatusBadge(
                          label: listing.status, tone: listing.tone),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: _ReviewOutlineButton(label: 'Open', onTap: onOpen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewContentSection extends StatelessWidget {
  final List<_ReviewContentData> items;
  final VoidCallback onViewAll;

  const _ReviewContentSection({
    required this.items,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          _ReviewSectionHeader(
            title: 'Content Moderation',
            icon: Icons.shield_outlined,
            action: 'View All Content',
            onAction: onViewAll,
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            return _ReviewContentRow(
              item: entry.value,
              showDivider: entry.key != items.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _ReviewContentRow extends StatelessWidget {
  final _ReviewContentData item;
  final bool showDivider;

  const _ReviewContentRow({
    required this.item,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = _dashboardToneColor(context, item.tone);
    return Container(
      padding: EdgeInsets.only(bottom: showDivider ? 10 : 2),
      margin: EdgeInsets.only(bottom: showDivider ? 10 : 0),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: toneColor.withValues(alpha: 0.12),
            ),
            child: Icon(item.icon, color: toneColor, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.owner} - ${item.role} - ${item.time}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.micro.copyWith(
                    color: colors.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    AdminStatusBadge(
                      label: item.visibility,
                      tone: AdminDecisionTone.info,
                    ),
                    AdminStatusBadge(
                      label: item.watermark,
                      tone: AdminDecisionTone.warning,
                    ),
                    AdminStatusBadge(
                      label: item.reports,
                      tone: AdminDecisionTone.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _ReviewContentActions(item: item),
        ],
      ),
    );
  }
}

class _ReviewContentActions extends StatelessWidget {
  final _ReviewContentData item;

  const _ReviewContentActions({required this.item});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: [
        _ReviewContentAction(
          icon: Icons.check_circle_outline,
          tooltip: 'Approve',
          tone: AdminDecisionTone.warning,
          onTap: () => showCoreSnack(context, '${item.title} approved'),
        ),
        _ReviewContentAction(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Remove',
          tone: AdminDecisionTone.danger,
          onTap: () => _noteDialog(context, 'Removal reason'),
        ),
        _ReviewContentAction(
          icon: Icons.warning_amber_rounded,
          tooltip: 'Warn',
          tone: AdminDecisionTone.warning,
          onTap: () => _noteDialog(context, 'Warning template'),
        ),
        _ReviewContentAction(
          icon: Icons.person_outline_rounded,
          tooltip: 'Profile',
          tone: AdminDecisionTone.neutral,
          onTap: () => Navigator.pushNamed(context, SuperAdminRoutes.users),
        ),
      ],
    );
  }
}

class _ReviewContentAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final AdminDecisionTone tone;
  final VoidCallback? onTap;

  const _ReviewContentAction({
    required this.icon,
    required this.tooltip,
    required this.tone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = _dashboardToneColor(context, tone);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            icon,
            color: tone == AdminDecisionTone.neutral
                ? colors.textSecondary
                : toneColor,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _ReviewSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String action;
  final VoidCallback onAction;

  const _ReviewSectionHeader({
    required this.title,
    required this.icon,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(icon, color: colors.goldDark, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionHeaderStyle.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        Flexible(
          child: TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    action,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: colors.goldDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(Icons.chevron_right_rounded,
                    color: colors.goldDark, size: 19),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ReviewOutlineButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.goldDark, width: 1.1),
          color: colors.goldGlow.withValues(alpha: 0.04),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(
            color: colors.goldDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
