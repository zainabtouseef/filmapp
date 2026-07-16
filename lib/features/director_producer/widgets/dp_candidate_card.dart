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

  const DPCandidateCard({
    super.key,
    required this.candidate,
    this.onProfile,
    this.onRequest,
  });

  @override
  State<DPCandidateCard> createState() => _DPCandidateCardState();
}

class _DPCandidateCardState extends State<DPCandidateCard> {
  bool _shortlisted = false;

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
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.goldGlow.withValues(alpha: 0.2),
                child: Text(
                  candidate.avatarLabel,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
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
                      '${candidate.city} - ${candidate.rateRange}',
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
                onPressed: () => setState(() => _shortlisted = !_shortlisted),
                icon: Icon(
                  _shortlisted ? Icons.favorite : Icons.favorite_border,
                  color: _shortlisted ? colors.infoPurple : colors.iconMuted,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              DPStatusChip(label: candidate.category, tone: DpTone.info),
              DPStatusChip(
                label: candidate.available ? 'Available' : 'Limited',
                tone: candidate.available ? DpTone.success : DpTone.warning,
              ),
              if (candidate.verified)
                const DPStatusChip(
                  label: 'Verified',
                  tone: DpTone.success,
                  icon: Icons.verified_outlined,
                ),
              DPStatusChip(label: '${candidate.rating}', tone: DpTone.warning),
            ],
          ),
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
}
