import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';

/// A shared, image-led presentation for actor and model profiles.
///
/// The same visual language is used in buyer-facing marketplace views and in
/// the actor/model profile builders, so talent does not look less compelling
/// when it is opened from a different portal.
class TalentProfileShowcase extends StatelessWidget {
  final String name;
  final String role;
  final String city;
  final String summary;
  final String? portraitUrl;
  final String? coverUrl;
  final bool verified;
  final bool available;
  final String rateLabel;
  final double? rating;
  final int? reviewCount;
  final List<String> highlights;
  final List<Widget> actions;
  final String badge;

  const TalentProfileShowcase({
    super.key,
    required this.name,
    required this.role,
    required this.city,
    required this.summary,
    this.portraitUrl,
    this.coverUrl,
    this.verified = false,
    this.available = true,
    this.rateLabel = 'Rate on request',
    this.rating,
    this.reviewCount,
    this.highlights = const [],
    this.actions = const [],
    this.badge = 'CineConnect profile',
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final heroHeight = compact ? 520.0 : 430.0;
        final imageUrl =
            coverUrl?.trim().isNotEmpty == true ? coverUrl : portraitUrl;
        final showInsetPortrait = portraitUrl?.trim().isNotEmpty == true &&
            coverUrl?.trim().isNotEmpty == true &&
            portraitUrl != coverUrl;

        return Container(
          key: const ValueKey('talent-profile-showcase'),
          height: heroHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: colors.goldMid.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: colors.isLight ? 0.13 : 0.30),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _ShowcaseImage(
                imageUrl: imageUrl,
                fallbackLabel: _initials(name),
                alignment: Alignment.topCenter,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: compact ? Alignment.topCenter : Alignment.centerLeft,
                    end: compact
                        ? Alignment.bottomCenter
                        : Alignment.centerRight,
                    colors: compact
                        ? const [
                            Color(0x12000000),
                            Color(0x72000000),
                            Color(0xF014171C),
                          ]
                        : const [
                            Color(0x2B000000),
                            Color(0x7A080B10),
                            Color(0xF014171C),
                          ],
                    stops: compact
                        ? const [0.0, 0.50, 0.78]
                        : const [0.0, 0.47, 0.73],
                  ),
                ),
              ),
              Positioned(
                top: 18,
                left: 18,
                right: 18,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ShowcasePill(
                      icon: Icons.auto_awesome_rounded,
                      label: badge,
                      emphasized: true,
                    ),
                    if (verified)
                      const _ShowcasePill(
                        icon: Icons.verified_rounded,
                        label: 'Identity verified',
                      ),
                  ],
                ),
              ),
              if (showInsetPortrait && !compact)
                Positioned(
                  left: 24,
                  bottom: 24,
                  child: Container(
                    width: 190,
                    height: 246,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: const Color(0xFFE5B95B), width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _ShowcaseImage(
                      imageUrl: portraitUrl,
                      fallbackLabel: _initials(name),
                    ),
                  ),
                ),
              if (showInsetPortrait && compact)
                Positioned(
                  left: 20,
                  top: 62,
                  child: Container(
                    width: 112,
                    height: 144,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE5B95B),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _ShowcaseImage(
                      imageUrl: portraitUrl,
                      fallbackLabel: _initials(name),
                    ),
                  ),
                ),
              Positioned(
                left: compact ? 20 : (showInsetPortrait ? 238 : 28),
                right: compact ? 20 : 28,
                bottom: compact ? 22 : 26,
                child: Align(
                  alignment:
                      compact ? Alignment.bottomLeft : Alignment.bottomRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: compact ? double.infinity : 560,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          role.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.micro.copyWith(
                            color: const Color(0xFFE8BE68),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.7,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          name.trim().isEmpty ? 'Your professional name' : name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heroSerifNumber.copyWith(
                            color: Colors.white,
                            fontSize: compact ? 34 : 43,
                            height: 1.02,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          summary.trim().isEmpty
                              ? 'Add a memorable positioning statement that tells buyers what makes this profile right for their production.'
                              : summary,
                          maxLines: compact ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.smallMeta.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.42,
                            fontSize: compact ? 13 : 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            _ShowcasePill(
                              icon: Icons.location_on_outlined,
                              label:
                                  city.trim().isEmpty ? 'City not set' : city,
                            ),
                            _ShowcasePill(
                              icon: available
                                  ? Icons.event_available_rounded
                                  : Icons.event_busy_outlined,
                              label: available
                                  ? 'Available for bookings'
                                  : 'Limited availability',
                            ),
                            _ShowcasePill(
                              icon: Icons.payments_outlined,
                              label: rateLabel,
                            ),
                            if (rating != null && rating! > 0)
                              _ShowcasePill(
                                icon: Icons.star_rounded,
                                label:
                                    '${rating!.toStringAsFixed(1)}${reviewCount == null ? '' : ' · $reviewCount reviews'}',
                              ),
                            for (final highlight
                                in highlights.take(compact ? 2 : 4))
                              _ShowcasePill(
                                icon: Icons.check_circle_outline_rounded,
                                label: highlight,
                              ),
                          ],
                        ),
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(spacing: 8, runSpacing: 8, children: actions),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TalentProfileGallery extends StatelessWidget {
  final List<TalentProfileGalleryItem> items;
  final ValueChanged<TalentProfileGalleryItem>? onOpen;

  const TalentProfileGallery({
    super.key,
    required this.items,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected portfolio',
          style: AppTextStyles.sectionTitle.copyWith(
            color: colors.textPrimary,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Open a frame to review the work at full size.',
          style: AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 292,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: onOpen == null ? null : () => onOpen!(item),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 226,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: colors.border),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ShowcaseImage(
                        imageUrl: item.imageUrl,
                        fallbackLabel: 'CC',
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xD9000000)],
                          ),
                        ),
                      ),
                      if (item.isVideo)
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: Text(
                          item.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardLabel.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TalentProfileGalleryItem {
  final String label;
  final String? imageUrl;
  final bool isVideo;
  final Object? value;

  const TalentProfileGalleryItem({
    required this.label,
    required this.imageUrl,
    this.isVideo = false,
    this.value,
  });
}

class _ShowcaseImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackLabel;
  final Alignment alignment;

  const _ShowcaseImage({
    required this.imageUrl,
    required this.fallbackLabel,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B5A24), Color(0xFF22314D), Color(0xFF11151C)],
        ),
      ),
      child: Center(
        child: Text(
          fallbackLabel,
          style: AppTextStyles.heroSerifNumber.copyWith(
            color: Colors.white.withValues(alpha: 0.86),
            fontSize: 58,
          ),
        ),
      ),
    );
    if (url == null || url.trim().isEmpty) return fallback;
    return Image.network(
      url,
      fit: BoxFit.cover,
      alignment: alignment,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _ShowcasePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasized;

  const _ShowcasePill({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized
            ? const Color(0xFFE2AE47)
            : Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized
              ? const Color(0xFFF4D798)
              : Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: emphasized ? const Color(0xFF251805) : Colors.white,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: emphasized ? const Color(0xFF251805) : Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2);
  final initials = words.map((part) => part[0].toUpperCase()).join();
  return initials.isEmpty ? 'CC' : initials;
}
