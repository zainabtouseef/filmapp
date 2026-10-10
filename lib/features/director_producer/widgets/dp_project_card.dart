import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/cine_marketplace_card.dart' show CineTonePlate;
import '../models/dp_project.dart';
import 'dp_budget_health_bar.dart';
import 'dp_glass_card.dart';
import 'dp_holographic_button.dart';

Color _stageColor(BuildContext context, String status) {
  final colors = context.appColors;
  return switch (status) {
    'Shooting' => colors.success,
    'Casting' || 'Negotiating' => colors.goldMid,
    'Draft' => colors.textTertiary,
    _ => colors.infoBlue,
  };
}

class DPProjectCard extends StatefulWidget {
  final DpProject project;
  final VoidCallback? onOpen;

  const DPProjectCard({
    super.key,
    required this.project,
    this.onOpen,
  });

  @override
  State<DPProjectCard> createState() => _DPProjectCardState();
}

class _DPProjectCardState extends State<DPProjectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final urgent = widget.project.pendingActions > 7;
    final stageColor = _stageColor(context, widget.project.status);
    return MouseRegion(
      cursor: widget.onOpen == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered && !reduceMotion ? 1.008 : 1,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: DPGlassCard(
          selected: urgent,
          accentColor: stageColor,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'project-cover-${widget.project.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 16 / 7,
                      child: AnimatedScale(
                        scale: _hovered && !reduceMotion ? 1.035 : 1,
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        child: (widget.project.coverImageUrl?.isNotEmpty ??
                                false)
                            ? Image.network(
                                widget.project.coverImageUrl!,
                                webHtmlElementStrategy:
                                    WebHtmlElementStrategy.prefer,
                                fit: BoxFit.cover,
                                semanticLabel:
                                    '${widget.project.title} project cover',
                                errorBuilder: (context, error, stackTrace) =>
                                    CineTonePlate(kind: widget.project.type),
                              )
                            : CineTonePlate(kind: widget.project.type),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle.copyWith(
                              color: colors.textPrimary,
                              fontSize: 15.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.project.city} · ${widget.project.dateRange}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.smallMeta
                                .copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _DotLabel(
                        label: widget.project.type, color: colors.goldDark),
                  ],
                ),
                const SizedBox(height: 10),
                DPBudgetHealthBar(
                  value: widget.project.progress,
                  label: 'Reported project progress',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 7,
                  children: [
                    _DotLabel(label: widget.project.status, color: stageColor),
                    _DotLabel(
                      label: '${widget.project.pendingActions} actions',
                      color: widget.project.pendingActions > 7
                          ? colors.danger
                          : colors.success,
                    ),
                    _DotLabel(
                      label: 'Shoot ${widget.project.shootDate}',
                      color: colors.textTertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(height: 1, color: colors.borderMuted),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.project.bookingsCount} bookings · ${widget.project.contractsCount} contracts · ${widget.project.paymentsStatus}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption
                            .copyWith(color: colors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DPHolographicButton(
                      label: 'Open Hub',
                      icon: Icons.open_in_new_rounded,
                      onTap: widget.onOpen,
                      secondary: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DotLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _DotLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
