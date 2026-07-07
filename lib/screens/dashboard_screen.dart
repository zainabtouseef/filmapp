import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../models/talent.dart';
import '../widgets/chips.dart';
import '../widgets/featured_talent_card.dart';
import '../widgets/talent_carousel_card.dart';
import '../widgets/cine_bottom_nav.dart';

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
    (Icons.person_outline_rounded, 'Actors'),
    (Icons.people_outline_rounded, 'Models'),
    (Icons.shield_outlined, 'Directors'),
    (Icons.person_outline_rounded, 'Makeup Artists'),
    (Icons.grid_view_rounded, 'More'),
  ];

  final _tabs = const [
    'Available this week',
    'Rising Stars',
    'Top Rated',
    'New Talents'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _CinematicBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
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
                        _sectionHeader('Featured Talent'),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child:
                              FeaturedTalentCard(talent: TalentData.featured),
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
                ),
                CineBottomNav(
                  currentIndex: _navIndex,
                  onTap: (i) => setState(() => _navIndex = i),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Header ------------------------------------------------------------
  Widget _header() {
    return CineConnectHeader(
      horizontalPadding: _pagePadding(),
      avatar: const PortraitImage(asset: 'assets/images/me.jpg'),
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
                icon: Icons.location_on_outlined,
                label: 'Lahore',
              ),
            1 => const FilterChipBox(label: 'Budget: 5k–15k'),
            2 => const FilterChipBox(label: 'Available this week'),
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
                'View all',
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

class TalentTabsBar extends StatelessWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final double horizontalPadding;

  const TalentTabsBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    this.onTap,
    this.horizontalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final wide = MediaQuery.sizeOf(context).width >= 700;

    return SizedBox(
      height: wide ? 70 : 54,
      child: Stack(
        children: [
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: 0,
            child: Container(
              height: 1,
              color: colors.border.withValues(alpha: 0.76),
            ),
          ),
          ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: tabs.length,
            separatorBuilder: (_, __) => SizedBox(width: wide ? 100 : 44),
            itemBuilder: (context, index) {
              return _TalentTab(
                label: tabs[index],
                active: index == currentIndex,
                wide: wide,
                onTap: () => onTap?.call(index),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TalentTab extends StatelessWidget {
  final String label;
  final bool active;
  final bool wide;
  final VoidCallback? onTap;

  const _TalentTab({
    required this.label,
    required this.active,
    required this.wide,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final underlineWidth = wide ? 320.0 : 174.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            style: AppTextStyles.label.copyWith(
              color: active ? colors.goldDark : colors.textSecondary,
              fontSize: wide ? 30 : 19,
              fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: 0,
              shadows: active
                  ? [
                      Shadow(color: colors.goldGlow, blurRadius: 10),
                    ]
                  : null,
            ),
          ),
          SizedBox(height: wide ? 18 : 13),
          if (active)
            SizedBox(
              width: underlineWidth,
              height: wide ? 5 : 4,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: wide ? 10 : 8,
                    top: wide ? 1.5 : 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: wide ? 2.8 : 2.4,
                      decoration: BoxDecoration(
                        gradient: colors.goldGradient,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: colors.goldGlow,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: wide ? 9 : 7,
                      height: wide ? 9 : 7,
                      decoration: BoxDecoration(
                        color: colors.goldDark,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: colors.goldGlow, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(height: wide ? 5 : 4),
        ],
      ),
    );
  }
}

class CastingCallBanner extends StatelessWidget {
  final double horizontalPadding;

  const CastingCallBanner({super.key, this.horizontalPadding = 16});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 700;
    final height = wide ? 110.0 : 104.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 28 : 18,
              vertical: wide ? 18 : 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: colors.cardGradient,
              border: Border.all(
                color: colors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(
                    alpha: colors.isLight ? 0.23 : 0.45,
                  ),
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                _CastingIcon(size: wide ? 66 : 54),
                SizedBox(width: wide ? 28 : 14),
                Expanded(child: _CastingCopy(wide: wide)),
                SizedBox(width: wide ? 22 : 12),
                GoldOutlinedButton(
                  label: 'Create Casting Call',
                  height: wide ? 54 : 48,
                  compact: !wide,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CastingIcon extends StatelessWidget {
  final double size;

  const _CastingIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.isLight ? colors.surface : const Color(0x16000000),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(
          color: colors.goldMid.withValues(alpha: 0.78),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.goldGlow,
            blurRadius: 14,
            spreadRadius: -3,
          ),
        ],
      ),
      child: Icon(
        Icons.movie_creation_outlined,
        color: colors.goldDark,
        size: size * 0.58,
      ),
    );
  }
}

class _CastingCopy extends StatelessWidget {
  final bool wide;

  const _CastingCopy({required this.wide});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Looking for the perfect match?',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.heading.copyWith(
            color: colors.textPrimary,
            fontSize: wide ? 24 : 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            shadows: colors.isLight
                ? null
                : const [
                    Shadow(color: Color(0xD0000000), blurRadius: 8),
                  ],
          ),
        ),
        SizedBox(height: wide ? 8 : 6),
        Text(
          'Post your casting call and get responses.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMuted.copyWith(
            color: colors.textSecondary,
            fontSize: wide ? 16 : 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class GoldOutlinedButton extends StatelessWidget {
  final String label;
  final double height;
  final bool compact;
  final VoidCallback? onTap;

  const GoldOutlinedButton({
    super.key,
    required this.label,
    this.height = 52,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
        constraints: BoxConstraints(maxWidth: compact ? 174 : 280),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: colors.glassGradient,
          border: Border.all(
            color: colors.goldMid.withValues(alpha: 0.92),
            width: 1.15,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.goldGlow,
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                style: AppTextStyles.label.copyWith(
                  color: colors.goldDark,
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(width: compact ? 10 : 14),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.goldDark,
                size: compact ? 22 : 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CinematicBackdrop extends StatelessWidget {
  const _CinematicBackdrop();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(gradient: colors.backgroundGradient),
      child: CustomPaint(
        painter: _CinematicBackdropPainter(colors),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CinematicBackdropPainter extends CustomPainter {
  final CineThemeColors colors;

  const _CinematicBackdropPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.goldGlow.withValues(alpha: colors.isLight ? 0.48 : 0.6),
          colors.goldGlow.withValues(alpha: colors.isLight ? 0.15 : 0.24),
          colors.goldGlow.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.28, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.88, size.height * 0.12),
          radius: size.width * 0.48,
        ),
      );
    canvas.drawRect(Offset.zero & size, goldPaint);

    final bluePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.isLight ? const Color(0x14E8B85A) : const Color(0x20101A22),
          colors.isLight ? const Color(0x08FFFFFF) : const Color(0x10080F15),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.02, size.height * 0.42),
          radius: size.width * 0.64,
        ),
      );
    canvas.drawRect(Offset.zero & size, bluePaint);

    final topShadePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors.isLight
            ? const [
                Color(0x00FFFFFF),
                Color(0x0AF6E9D7),
                Color(0x18EDE2D4),
              ]
            : const [
                Color(0x00000000),
                Color(0x24000000),
                Color(0x4A000000),
              ],
        stops: [0.0, 0.52, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, topShadePaint);

    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.12,
        colors: colors.isLight
            ? const [
                Colors.transparent,
                Color(0x08B97816),
                Color(0x18B97816),
              ]
            : const [
                Colors.transparent,
                Color(0x66000000),
                Color(0xCC000000),
              ],
        stops: const [0.52, 0.82, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignettePaint);

    final noisePaint = Paint();
    for (var y = 0.0; y < size.height; y += 10) {
      for (var x = 0.0; x < size.width; x += 10) {
        final seed = ((x * 37 + y * 17).round() % 19);
        if (seed < 5) {
          noisePaint.color = (colors.isLight ? colors.goldDark : Colors.white)
              .withValues(
                  alpha: colors.isLight ? 0.006 : 0.007 + seed * 0.0015);
          canvas.drawCircle(
              Offset(x + seed, y + (seed * 0.7)), 0.45, noisePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicBackdropPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
