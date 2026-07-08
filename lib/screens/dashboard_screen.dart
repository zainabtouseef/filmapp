import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_icons.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_color_scheme.dart';
import '../core/theme/app_text_styles.dart';
import '../models/talent.dart';
import '../shared/widgets/app_header.dart';
import '../shared/widgets/app_scaffold.dart';
import '../shared/widgets/app_search_bar.dart';
import '../shared/widgets/casting_call_banner.dart';
import '../shared/widgets/category_chip.dart';
import '../shared/widgets/featured_talent_card.dart';
import '../shared/widgets/filter_chip_button.dart';
import '../shared/widgets/portrait_image.dart';
import '../shared/widgets/talent_card.dart';
import '../shared/widgets/talent_tabs_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _category = 0;
  int _tab = 0;
  int _navIndex = 1; // Discover
  bool _verifiedOnly = true;

  final _categories = const [
    (AppIcons.actors, AppStrings.categoryActors),
    (AppIcons.models, AppStrings.categoryModels),
    (AppIcons.directors, AppStrings.categoryDirectors),
    (AppIcons.makeupArtists, AppStrings.categoryMakeupArtists),
    (AppIcons.more, AppStrings.categoryMore),
  ];

  final _tabs = const [
    AppStrings.tabAvailableThisWeek,
    AppStrings.tabRisingStars,
    AppStrings.tabTopRated,
    AppStrings.tabNewTalents,
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      navIndex: _navIndex,
      onNavTap: (i) => setState(() => _navIndex = i),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            SizedBox(height: _topGap(afterHeader: true)),
            _searchBar(),
            SizedBox(height: _topGap(afterSearch: true)),
            _categoryRow(),
            SizedBox(height: _topGap(afterCategories: true)),
            _filterRow(),
            SizedBox(height: _topGap(afterFilters: true)),
            _sectionHeader(AppStrings.featuredTalentTitle),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FeaturedTalentCard(talent: TalentData.featured),
            ),
            const SizedBox(height: 27),
            _tabRow(),
            SizedBox(height: _isTabletWidth() ? 30 : 20),
            _carousel(),
            SizedBox(height: _isTabletWidth() ? 42 : 28),
            _ctaBanner(),
          ],
        ),
      ),
    );
  }

  // ---- Header ------------------------------------------------------------
  Widget _header() {
    return CineConnectHeader(
      horizontalPadding: _pagePadding(),
      avatar: const PortraitImage(asset: AppAssets.currentUserAvatar),
    );
  }

  // ---- Search ------------------------------------------------------------
  Widget _searchBar() {
    return PremiumSearchBar(horizontalPadding: _pagePadding());
  }

  // ---- Category row ------------------------------------------------------
  Widget _categoryRow() {
    final tablet = _isTabletWidth();

    return SizedBox(
      height: tablet ? 56 : 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: _pagePadding()),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => SizedBox(width: tablet ? 20 : 14),
        itemBuilder: (_, i) => CategoryChip(
          icon: _categories[i].$1,
          label: _categories[i].$2,
          active: i == _category,
          onTap: () => setState(() => _category = i),
        ),
      ),
    );
  }

  Widget _filterRow() {
    final tablet = _isTabletWidth();

    return SizedBox(
      height: tablet ? 56 : 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: _pagePadding()),
        itemCount: 4,
        separatorBuilder: (_, __) => SizedBox(width: tablet ? 22 : 16),
        itemBuilder: (context, index) {
          return switch (index) {
            0 => const FilterChipBox(
                icon: AppIcons.location,
                label: AppStrings.filterLocation,
              ),
            1 => const FilterChipBox(label: AppStrings.filterBudget),
            2 => const FilterChipBox(label: AppStrings.filterAvailability),
            _ => VerifiedToggleChip(
                value: _verifiedOnly,
                onChanged: (v) => setState(() => _verifiedOnly = v),
              ),
          };
        },
      ),
    );
  }

  double _pagePadding() {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 700 ? 32 : 16;
  }

  bool _isTabletWidth() => MediaQuery.sizeOf(context).width >= 700;

  double _topGap({
    bool afterHeader = false,
    bool afterSearch = false,
    bool afterCategories = false,
    bool afterFilters = false,
  }) {
    final tablet = _isTabletWidth();
    if (afterHeader) return tablet ? 36 : 30;
    if (afterSearch) return tablet ? 32 : 30;
    if (afterCategories) return tablet ? 34 : 24;
    if (afterFilters) return tablet ? 32 : 28;
    return 0;
  }

  // ---- Section header ----------------------------------------------------
  Widget _sectionHeader(String title) {
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _pagePadding()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.sectionTitle.copyWith(
              color: colors.textPrimary,
              fontSize: 27,
            ),
          ),
          Row(
            children: [
              Text(
                AppStrings.viewAll,
                style: AppTextStyles.label
                    .copyWith(color: colors.goldDark, fontSize: 16),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.chevron_right_rounded,
                size: 23,
                color: colors.goldDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Tab row -----------------------------------------------------------
  Widget _tabRow() {
    return TalentTabsBar(
      tabs: _tabs,
      currentIndex: _tab,
      horizontalPadding: _pagePadding(),
      onTap: (index) => setState(() => _tab = index),
    );
  }

  // ---- Carousel ----------------------------------------------------------
  Widget _carousel() {
    final wide = _isTabletWidth();

    return SizedBox(
      height: wide ? 365 : 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: _pagePadding()),
        itemCount: TalentData.carousel.length,
        separatorBuilder: (_, __) => SizedBox(width: wide ? 24 : 16),
        itemBuilder: (_, i) => TalentCarouselCard(
          talent: TalentData.carousel[i],
          active: i == 0,
        ),
      ),
    );
  }

  // ---- CTA banner --------------------------------------------------------
  Widget _ctaBanner() {
    return CastingCallBanner(horizontalPadding: _pagePadding());
  }
}
