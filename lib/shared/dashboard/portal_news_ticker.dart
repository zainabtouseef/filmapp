import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';

/// One real event shown in a [PortalNewsTicker] — a booking, contract,
/// payment, application, or similar — never fabricated.
class PortalNewsItem {
  final String badge;
  final String title;
  final String meta;
  final String ago;
  final VoidCallback? onTap;

  const PortalNewsItem({
    required this.badge,
    required this.title,
    required this.meta,
    required this.ago,
    this.onTap,
  });
}

/// A horizontally auto-scrolling marquee of real recent activity — a
/// "LIVE" pulse dot, then an endless-looped strip of [PortalNewsItem]s.
/// Reduced motion renders a static, non-scrolling row instead.
class PortalNewsTicker extends StatefulWidget {
  final List<PortalNewsItem> items;
  final String liveLabel;

  const PortalNewsTicker({
    super.key,
    required this.items,
    this.liveLabel = 'LIVE',
  });

  @override
  State<PortalNewsTicker> createState() => _PortalNewsTickerState();
}

class _PortalNewsTickerState extends State<PortalNewsTicker>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _controller;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..addListener(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!_reduceMotion && widget.items.isNotEmpty && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  void _onTick() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    _scrollController.jumpTo(_controller.value * max);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: colors.isLight ? 0.08 : 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _LivePulse(label: widget.liveLabel),
          const SizedBox(width: 14),
          Container(width: 1, height: 20, color: colors.border),
          Expanded(
            child: widget.items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'No recent activity yet.',
                      style: AppTextStyles.smallMeta
                          .copyWith(color: colors.textTertiary),
                    ),
                  )
                : ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.04, 0.94, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: ListView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final item in [
                          ...widget.items,
                          if (!_reduceMotion) ...widget.items,
                        ])
                          _NewsEntry(item: item),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LivePulse extends StatelessWidget {
  final String label;

  const _LivePulse({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          onEnd: () {},
          builder: (context, value, child) => Opacity(opacity: value, child: child),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.danger,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: AppTextStyles.micro.copyWith(
            color: colors.danger,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _NewsEntry extends StatelessWidget {
  final PortalNewsItem item;

  const _NewsEntry({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 19),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.goldSoft,
                shape: BoxShape.circle,
              ),
              child: Text(
                item.badge,
                style: AppTextStyles.micro.copyWith(
                  color: colors.goldDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.meta,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.ago,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.goldDark,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
