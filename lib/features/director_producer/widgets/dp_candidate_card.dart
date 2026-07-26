import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dp_candidate.dart';
import 'dp_glass_card.dart';
import 'dp_holographic_button.dart';
import 'dp_status_chip.dart';

class DPCandidateCard extends StatefulWidget {
  final DpCandidate candidate;
  final VoidCallback? onProfile;
  final VoidCallback? onRequest;
  final Future<bool> Function()? onShortlist;

  const DPCandidateCard({
    super.key,
    required this.candidate,
    this.onProfile,
    this.onRequest,
    this.onShortlist,
  });

  @override
  State<DPCandidateCard> createState() => _DPCandidateCardState();
}

class _DPCandidateCardState extends State<DPCandidateCard> {
  bool _shortlisted = false;
  bool _savingShortlist = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final candidate = widget.candidate;
    return DPGlassCard(
      selected: _shortlisted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: candidate.imageUrl?.isNotEmpty == true
                      ? Image.network(
                          candidate.imageUrl!,
                          fit: BoxFit.cover,
                          semanticLabel: '${candidate.name} profile image',
                          errorBuilder: (context, error, stackTrace) =>
                              _AvatarFallback(
                            label: candidate.avatarLabel,
                          ),
                        )
                      : _AvatarFallback(label: candidate.avatarLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardLabel.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${candidate.city} · ${candidate.rateRange}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _savingShortlist ? null : _toggleShortlist,
                icon: Icon(
                  _shortlisted ? Icons.favorite : Icons.favorite_border,
                  color: _shortlisted ? colors.infoPurple : colors.iconMuted,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              DpDotLabel(label: candidate.category, tone: DpTone.info),
              DpDotLabel(
                label: candidate.available ? 'Available' : 'Limited',
                tone: candidate.available ? DpTone.success : DpTone.warning,
              ),
              if (candidate.verified)
                const DpDotLabel(label: 'Verified', tone: DpTone.warning),
              if (candidate.isNew)
                const DpDotLabel(label: 'New', tone: DpTone.warning),
              Text(
                '★ ${candidate.rating}',
                style: AppTextStyles.caption.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _ReputationSafetyPanel(candidate: candidate),
          const SizedBox(height: 9),
          Text(
            candidate.skills.take(3).join(' - '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: DPHolographicButton(
                  label: 'Profile',
                  icon: Icons.person_search_rounded,
                  onTap: widget.onProfile,
                  secondary: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DPHolographicButton(
                  label: 'Request',
                  icon: Icons.send_rounded,
                  onTap: widget.onRequest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleShortlist() async {
    final action = widget.onShortlist;
    if (action == null || _shortlisted) {
      setState(() => _shortlisted = !_shortlisted);
      return;
    }
    setState(() => _savingShortlist = true);
    final saved = await action();
    if (!mounted) return;
    setState(() {
      _savingShortlist = false;
      _shortlisted = saved || _shortlisted;
    });
  }
}

class _ReputationSafetyPanel extends StatefulWidget {
  final DpCandidate candidate;

  const _ReputationSafetyPanel({required this.candidate});

  @override
  State<_ReputationSafetyPanel> createState() => _ReputationSafetyPanelState();
}

class _ReputationSafetyPanelState extends State<_ReputationSafetyPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final metrics = widget.candidate.trustMetrics;
    final score = metrics?.score;
    final label = metrics?.label ?? 'Pending';
    final tone = _scoreTone(score);
    final color = _scoreColor(context, score);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: colors.isLight ? 0.08 : 0.13),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: score == null ? 0 : score / 100,
                        strokeWidth: 5,
                        backgroundColor: colors.surface.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Text(
                      score?.toString() ?? '--',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: color,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Reputation & safety',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          DPStatusChip(label: label, tone: tone),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        metrics == null
                            ? 'Backend trust score pending for this listing.'
                            : '${metrics.completionLabel} · ${metrics.responseLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: colors.textTertiary,
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: metrics == null
                  ? _TrustFactorRow(
                      label: 'Score inputs',
                      value:
                          'Waiting for live KYC, reviews, disputes, completion and response metrics.',
                      fraction: 0,
                      color: colors.textTertiary,
                    )
                  : Column(
                      children: [
                        for (final factor in metrics.factors) ...[
                          _TrustFactorRow(
                            label:
                                '${factor.label} · ${factor.score}/${factor.maxScore}',
                            value: factor.summary,
                            fraction: factor.maxScore == 0
                                ? 0
                                : factor.score / factor.maxScore,
                            color: _factorColor(context, factor.status),
                          ),
                          if (factor != metrics.factors.last)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  DpTone _scoreTone(int? score) {
    if (score == null) return DpTone.neutral;
    if (score >= 90) return DpTone.success;
    if (score >= 75) return DpTone.info;
    if (score >= 55) return DpTone.warning;
    return DpTone.danger;
  }
}

class _TrustFactorRow extends StatelessWidget {
  final String label;
  final String value;
  final double fraction;
  final Color color;

  const _TrustFactorRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: fraction.clamp(0, 1),
            minHeight: 5,
            backgroundColor: colors.surface.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

Color _scoreColor(BuildContext context, int? score) {
  final colors = context.appColors;
  if (score == null) return colors.textTertiary;
  if (score >= 90) return colors.success;
  if (score >= 75) return colors.infoBlue;
  if (score >= 55) return colors.warning;
  return colors.danger;
}

Color _factorColor(BuildContext context, String status) {
  final colors = context.appColors;
  return switch (status) {
    'verified' || 'tracked' || 'clear' => colors.success,
    'attention' => colors.danger,
    'pending' => colors.warning,
    _ => colors.infoBlue,
  };
}

class _AvatarFallback extends StatelessWidget {
  final String label;

  const _AvatarFallback({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      color: colors.softSurface,
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.cardLabel.copyWith(
          color: colors.goldDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
