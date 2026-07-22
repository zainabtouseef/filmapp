import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../models/dp_candidate.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_project_console_widgets.dart';
import '../widgets/dp_status_chip.dart';

class DPStakeholderProfileScreen extends StatelessWidget {
  final String? candidateId;
  final String? profileType;
  final String? projectId;

  const DPStakeholderProfileScreen({
    super.key,
    this.candidateId,
    this.profileType,
    this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    final candidate = DirectorProducerDemoData.candidates.firstWhere(
      (item) => item.id == candidateId,
      orElse: () => DirectorProducerDemoData.candidates.first,
    );
    final type = profileType ?? candidate.category;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPProjectBreadcrumbs(
          project: projectId == null ? null : dpProjectForId(projectId),
          current: candidate.name,
        ),
        const SizedBox(height: 10),
        _ProfileHero(candidate: candidate, type: type),
        const SizedBox(height: 14),
        _ProfileTemplate(candidate: candidate, type: type),
        const SizedBox(height: 14),
        DPGlassCard(
          selected: true,
          child: Row(
            children: [
              Expanded(
                child: DPHolographicButton(
                  label: 'Shortlist to project',
                  icon: Icons.favorite_border_rounded,
                  onTap: () => _showShortlistHint(context, candidate),
                  secondary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DPHolographicButton(
                  label: 'Select / Send Request',
                  icon: Icons.send_rounded,
                  onTap: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.bookingRequest,
                    arguments: {
                      'candidateId': candidate.id,
                      'projectId': projectId,
                      'category': type,
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showShortlistHint(BuildContext context, DpCandidate candidate) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Use Discover ♡ to choose project → requirement for ${candidate.name}.',
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final DpCandidate candidate;
  final String type;

  const _ProfileHero({required this.candidate, required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      selected: true,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Container(
              height: 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.goldMid.withValues(alpha: 0.72),
                    colors.infoBlue.withValues(alpha: 0.46),
                    colors.surface,
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      colors.surface
                          .withValues(alpha: colors.isLight ? 0.92 : 0.78),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor:
                              colors.goldGlow.withValues(alpha: 0.42),
                          child: Text(
                            candidate.avatarLabel,
                            style: AppTextStyles.metricNumberCompact.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                candidate.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.sectionTitle.copyWith(
                                  color: colors.textPrimary,
                                  fontSize: 23,
                                ),
                              ),
                              const SizedBox(height: 6),
                              dpText(
                                context,
                                '$type • ${candidate.city} • Urdu, Punjabi, English',
                                strong: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (candidate.verified)
                          const DPStatusChip(
                            label: 'Verified',
                            tone: DpTone.success,
                            icon: Icons.verified_outlined,
                          ),
                        if (candidate.isNew)
                          const DPStatusChip(
                            label: 'NEW',
                            tone: DpTone.warning,
                          ),
                        DPStatusChip(
                          label: '${candidate.rating} rating',
                          tone: DpTone.warning,
                        ),
                        DPStatusChip(
                          label: '${candidate.completedBookings} completed',
                          tone: DpTone.success,
                        ),
                        DPStatusChip(
                          label: candidate.available
                              ? 'Available on dates'
                              : 'Limited dates',
                          tone: candidate.available
                              ? DpTone.success
                              : DpTone.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTemplate extends StatelessWidget {
  final DpCandidate candidate;
  final String type;

  const _ProfileTemplate({required this.candidate, required this.type});

  @override
  Widget build(BuildContext context) {
    final normalized = type.toLowerCase();
    if (normalized.contains('location')) {
      return _LocationProfile(candidate: candidate);
    }
    if (normalized.contains('equipment') || normalized.contains('media')) {
      return _EquipmentProfile(candidate: candidate);
    }
    if (normalized.contains('crew')) {
      return _CrewProfile(candidate: candidate);
    }
    if (normalized.contains('model')) {
      return _ModelProfile(candidate: candidate);
    }
    return _ActorProfile(candidate: candidate);
  }
}

class _ActorProfile extends StatelessWidget {
  final DpCandidate candidate;

  const _ActorProfile({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DPTwoColumn(
          left: _ShowreelSection(candidate: candidate),
          right: _SnapshotSection(candidate: candidate),
        ),
        const SizedBox(height: 12),
        _VideoRailsSection(
          categories: const [
            'Dramas',
            'Films / Movies',
            'TVCs / Ads',
            'Music Videos',
            'Web Series',
            'Theatre',
            'Self-tapes / Intro',
          ],
        ),
        const SizedBox(height: 12),
        _PhotoGallerySection(
          categories: const ['Headshots', 'Full-length', 'Editorial', 'On-set'],
        ),
        const SizedBox(height: 12),
        DPTwoColumn(
          left: _CreditsSection(candidate: candidate),
          right: _SocialsRateAvailabilitySection(candidate: candidate),
        ),
      ],
    );
  }
}

class _ModelProfile extends StatelessWidget {
  final DpCandidate candidate;

  const _ModelProfile({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DPTwoColumn(
          left: _PhotoGallerySection(
            categories: const [
              'Comp card',
              'Editorial',
              'Ramp',
              'Ethnic',
              'Western',
              'Product',
            ],
          ),
          right: _ProfileSection(
            title: 'Usage rights & brand safety',
            icon: Icons.verified_user_outlined,
            children: [
              const DPDetailRow(
                  label: 'Digital campaign', value: 'PKR 180k / 6 months'),
              const DPDetailRow(
                  label: 'Billboard / OOH', value: 'PKR 320k / 3 months'),
              const DPDetailRow(
                  label: 'Category conflicts', value: 'No tobacco, politics'),
              DPDetailRow(label: 'Instagram', value: candidate.instagramHandle),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DPTwoColumn(
          left: _CreditsSection(candidate: candidate),
          right: _SocialsRateAvailabilitySection(candidate: candidate),
        ),
      ],
    );
  }
}

class _LocationProfile extends StatelessWidget {
  final DpCandidate candidate;

  const _LocationProfile({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DPTwoColumn(
          left: _PhotoGallerySection(
            categories: const ['Exterior', 'Kitchen', 'Holding', 'Parking'],
          ),
          right: _ProfileSection(
            title: 'Property specs',
            icon: Icons.location_city_outlined,
            children: const [
              DPDetailRow(label: 'Capacity', value: '45 crew + cast'),
              DPDetailRow(label: 'Parking', value: '8 cars, 1 truck'),
              DPDetailRow(label: 'Power', value: '3-phase, generator allowed'),
              DPDetailRow(
                  label: 'Exact address', value: 'Locked until booking'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DPTwoColumn(
          left: _ProfileSection(
            title: 'Rules',
            icon: Icons.rule_outlined,
            children: const [
              DPDetailRow(label: 'Night shoot', value: 'Until 11 PM'),
              DPDetailRow(label: 'Food / smoke', value: 'No open flame'),
              DPDetailRow(label: 'Cleaning', value: 'PKR 12k mandatory'),
            ],
          ),
          right: _SocialsRateAvailabilitySection(candidate: candidate),
        ),
      ],
    );
  }
}

class _EquipmentProfile extends StatelessWidget {
  final DpCandidate candidate;

  const _EquipmentProfile({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DPTwoColumn(
          left: _ProfileSection(
            title: 'Inventory & condition',
            icon: Icons.video_camera_back_outlined,
            children: const [
              DPDetailRow(label: 'Camera', value: 'Alexa Mini LF, serviced'),
              DPDetailRow(label: 'Lighting', value: 'Aputure 600D x4'),
              DPDetailRow(label: 'Grip', value: 'Slider, jib, stands'),
              DPDetailRow(label: 'Insurance', value: 'Active equipment cover'),
            ],
          ),
          right: _ProfileSection(
            title: 'Packages',
            icon: Icons.inventory_2_outlined,
            children: const [
              DPDetailRow(label: 'TVC day package', value: 'PKR 240k/day'),
              DPDetailRow(label: 'Deposit', value: '30% refundable hold'),
              DPDetailRow(label: 'Coverage cities', value: 'Karachi, Lahore'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PhotoGallerySection(
          categories: const ['Camera bodies', 'Lenses', 'Lighting', 'Truck'],
        ),
      ],
    );
  }
}

class _CrewProfile extends StatelessWidget {
  final DpCandidate candidate;

  const _CrewProfile({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DPTwoColumn(
          left: _CreditsSection(candidate: candidate),
          right: _ProfileSection(
            title: 'Service, kit, day rate',
            icon: Icons.groups_2_outlined,
            children: [
              DPDetailRow(
                  label: 'Service category', value: candidate.skills.first),
              const DPDetailRow(
                  label: 'Kit owned', value: 'Monitor, meters, radio set'),
              DPDetailRow(label: 'Day rate', value: candidate.rateRange),
              const DPDetailRow(
                  label: 'Availability', value: 'Open for selected dates'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _VideoRailsSection(
            categories: const ['Drama', 'TVC', 'BTS', 'Night work']),
      ],
    );
  }
}

class _ShowreelSection extends StatelessWidget {
  final DpCandidate candidate;

  const _ShowreelSection({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _ProfileSection(
      title: 'Featured showreel',
      icon: Icons.play_circle_outline_rounded,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: colors.cardGradient,
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Icon(Icons.play_circle_fill_rounded,
                  color: colors.goldDark, size: 48),
            ),
          ),
        ),
        const SizedBox(height: 10),
        dpText(context, '${candidate.name} selected reel • in-app playback'),
      ],
    );
  }
}

class _SnapshotSection extends StatelessWidget {
  final DpCandidate candidate;

  const _SnapshotSection({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: 'Booking intelligence',
      icon: Icons.insights_outlined,
      children: [
        DPDetailRow(label: 'Rate card', value: candidate.rateRange),
        DPDetailRow(label: 'Response time', value: '2h 20m median'),
        DPDetailRow(label: 'Completion history', value: '96% on-platform'),
        const DPDetailRow(label: 'Disputes', value: '0 open'),
      ],
    );
  }
}

class _VideoRailsSection extends StatelessWidget {
  final List<String> categories;

  const _VideoRailsSection({required this.categories});

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: 'Categorized video portfolio',
      icon: Icons.video_library_outlined,
      children: [
        for (final category in categories.take(5)) ...[
          Row(
            children: [
              Expanded(
                  child: dpText(context, '$category (${_countFor(category)})',
                      strong: true)),
              const DPStatusChip(label: 'Moderated', tone: DpTone.success),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  _MediaThumb(
                    title: '$category work ${i + 1}',
                    subtitle: i == 0 ? 'Lead • 2026' : 'Supporting • 2025',
                    icon: Icons.play_arrow_rounded,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  int _countFor(String category) => category.length % 4 + 2;
}

class _PhotoGallerySection extends StatelessWidget {
  final List<String> categories;

  const _PhotoGallerySection({required this.categories});

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: 'Photo gallery',
      icon: Icons.photo_library_outlined,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in categories)
              DPStatusChip(label: category, tone: DpTone.info),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 8; i++)
              _PhotoTile(label: categories[i % categories.length]),
          ],
        ),
      ],
    );
  }
}

class _CreditsSection extends StatelessWidget {
  final DpCandidate candidate;

  const _CreditsSection({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final credits = [
      ['Northern Sky', 'Drama', 'Supporting Lead', '2026', 'Ayaan Films'],
      ['Bank Forward', 'TVC', 'Principal', '2025', 'Orbit Brands'],
      ['Stage Lines', 'Theatre', 'Lead', '2024', 'Lahore Arts'],
    ];
    return _ProfileSection(
      title: 'Work history / credits',
      icon: Icons.workspace_premium_outlined,
      children: [
        for (final credit in credits)
          DPDetailRow(
            label: '${credit[0]} • ${credit[1]}',
            value: '${credit[2]} • ${credit[3]} • ${credit[4]}',
          ),
        DPDetailRow(
          label: 'CineConnect verified bookings',
          value: '${candidate.completedBookings} stamped records',
        ),
      ],
    );
  }
}

class _SocialsRateAvailabilitySection extends StatelessWidget {
  final DpCandidate candidate;

  const _SocialsRateAvailabilitySection({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: 'Socials, rates, availability, reviews',
      icon: Icons.public_outlined,
      children: [
        DPDetailRow(
          label: 'Instagram',
          value:
              '${candidate.instagramHandle} • ${(candidate.instagramFollowers / 1000).toStringAsFixed(1)}k followers',
        ),
        const DPDetailRow(
            label: 'Social preview', value: '6 recent tiles • self-reported'),
        DPDetailRow(label: 'Rate card', value: candidate.rateRange),
        DPDetailRow(
          label: 'Availability',
          value:
              candidate.available ? 'Open for selected dates' : 'Limited dates',
        ),
        DPDetailRow(
            label: 'Reviews',
            value: '${candidate.rating}/5 • detailed breakdown'),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: title,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _MediaThumb({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 174,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: colors.cardGradient,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colors.goldGlow.withValues(alpha: 0.22),
            ),
            child: Center(child: Icon(icon, color: colors.goldDark, size: 28)),
          ),
          const SizedBox(height: 8),
          dpText(context, title, strong: true),
          const SizedBox(height: 3),
          dpText(context, subtitle),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String label;

  const _PhotoTile({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: colors.goldGradient,
        border: Border.all(color: colors.border),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: colors.onGold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
