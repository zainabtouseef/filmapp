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
    if (normalized.contains('agenc') || normalized.contains('partner')) {
      return _AgencyProfile(candidate: candidate);
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
        const _GallerySection(
          title: 'Categorized video portfolio',
          icon: Icons.video_library_outlined,
          filters: ['Dramas (4)', 'Films / Movies (4)', 'Web Series (2)'],
          tiles: [
            'Dramas · Lead · 2026',
            'Dramas · Supporting · 2025',
            'Films · Lead · 2025',
            'Films · Cameo · 2024',
            'Web Series · Lead · 2026',
            'Web Series · Supporting · 2025',
          ],
        ),
        const SizedBox(height: 12),
        const _GallerySection(
          title: 'Photo gallery',
          filters: ['Headshots', 'Full-length', 'Editorial', 'On-set'],
          tiles: [
            'Headshots',
            'Full-length',
            'Editorial',
            'On-set',
            'Headshots',
            'Full-length',
          ],
        ),
        const SizedBox(height: 12),
        DPTwoColumn(
          left: _WorkHistorySection(
            title: 'Work history / credits',
            rows: const [
              ('Northern Sky · Drama', 'Supporting Lead · 2026 · Ayaan Films'),
              ('Bank Forward · TVC', 'Principal · 2025 · Orbit Brands'),
              ('Stage Line · Theatre', 'Lead · 2024 · Lahore Arts'),
            ],
          ),
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
          left: _ShowreelSection(
            candidate: candidate,
            title: 'Featured reel',
            caption: 'Runway + editorial reel • in-app playback',
          ),
          right: const _InfoSection(
            title: 'Comp card',
            icon: Icons.straighten_outlined,
            rows: [
              ('Height', "5'9\""),
              ('Bust · Waist · Hip', '34-24-35'),
              ('Shoe size', '8 (US)'),
              ('Hair · Eyes', 'Black · Brown'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _GallerySection(
          title: 'Portfolio',
          filters: ['Editorial (5)', 'Commercial (3)', 'Runway (4)'],
          tiles: [
            'Editorial',
            'Editorial',
            'Commercial',
            'Commercial',
            'Runway',
            'Runway'
          ],
        ),
        const SizedBox(height: 12),
        const _GallerySection(
          title: 'Photo gallery',
          filters: ['Headshots', 'Full-length', 'Beauty'],
          tiles: [
            'Headshots',
            'Full-length',
            'Beauty',
            'Headshots',
            'Full-length',
            'Beauty'
          ],
        ),
        const SizedBox(height: 12),
        DPTwoColumn(
          left: _WorkHistorySection(
            title: 'Work history / credits',
            rows: const [
              ('Noor Couture Campaign', 'Editorial model · 2026'),
              ('Lahore Fashion Week', 'Runway · 2025'),
              ('City Mag Cover', 'Editorial · 2024'),
            ],
          ),
          right: _SocialsRateAvailabilitySection(candidate: candidate),
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
          left: _InfoSection(
            title: 'Department & specialty',
            icon: Icons.groups_2_outlined,
            rows: [
              ('Department', candidate.skills.first),
              ('Specialty', candidate.notes),
              ('Kit owned', 'Yes — full package'),
              ('Crew size', 'Solo + 1 assistant'),
            ],
          ),
          right: _InfoSection(
            title: 'Rate card',
            icon: Icons.receipt_long_outlined,
            rows: [
              ('Day rate', candidate.rateRange),
              (
                'Overtime',
                '${_pkr((dpMoneyFromLabel(candidate.rateRange) * 0.14).round())} / hr'
              ),
              (
                'Kit fee',
                '${_pkr((dpMoneyFromLabel(candidate.rateRange) * 0.3).round())} / day'
              ),
              ('Travel', 'Billed at cost'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _GallerySection(
          title: 'Showreel & stills',
          filters: ['Feature', 'TVC', 'Documentary'],
          tiles: [
            'Feature',
            'Feature',
            'TVC',
            'TVC',
            'Documentary',
            'Documentary'
          ],
        ),
        const SizedBox(height: 12),
        _WorkHistorySection(
          title: 'Work history / credits',
          rows: const [
            ('Jhelum Drama Pilot', 'DOP · 2026'),
            ('Echo Street Music Video', 'DOP · 2026'),
            ('Northern Sky', 'Camera operator · 2025'),
          ],
        ),
        const SizedBox(height: 12),
        _InfoSection(
          title: 'Socials, availability, reviews',
          icon: Icons.public_outlined,
          rows: [
            (
              'Instagram',
              '${candidate.instagramHandle} · ${(candidate.instagramFollowers / 1000).toStringAsFixed(1)}k',
            ),
            (
              'Availability',
              candidate.available ? 'Open for selected dates' : 'Limited dates',
            ),
            ('Reviews', '${candidate.rating}/5'),
          ],
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
    final dayRate = dpMoneyFromLabel(candidate.rateRange);
    return Column(
      children: [
        const _GallerySection(
          title: 'Photo gallery',
          filters: ['Main hall', 'Cyclorama', 'Green room', 'Exterior'],
          tiles: [
            'Main hall',
            'Cyclorama',
            'Green room',
            'Exterior',
            'Main hall',
            'Cyclorama'
          ],
        ),
        const SizedBox(height: 12),
        DPTwoColumn(
          left: const _InfoSection(
            title: 'Specs',
            icon: Icons.location_city_outlined,
            rows: [
              ('Size', '4,200 sq ft'),
              ('Ceiling height', '18 ft'),
              ('Power', '3-phase, 200A'),
              ('Parking', '12 vehicles'),
            ],
          ),
          right: _InfoSection(
            title: 'Rate card',
            icon: Icons.receipt_long_outlined,
            rows: [
              ('Half day', _pkr((dayRate * 0.6).round())),
              ('Full day', _pkr(dayRate)),
              ('Weekly', _pkr((dayRate * 5.5).round())),
              ('Permits', 'Included'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _WorkHistorySection(
          title: 'Recent bookings',
          rows: const [
            ('Aurora Biscuit TVC', 'Pre-production · Jul 2026'),
            ('Echo Street Music Video', 'Wrapped · Jul 2026'),
            ('Bank Forward TVC', 'Wrapped · 2025'),
          ],
        ),
        const SizedBox(height: 12),
        _InfoSection(
          title: 'Address, availability, reviews',
          icon: Icons.public_outlined,
          rows: [
            ('Address', '${candidate.city} · exact address on booking'),
            (
              'Availability',
              candidate.available ? 'Open weekdays' : 'Limited dates',
            ),
            ('Reviews', '${candidate.rating}/5'),
          ],
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
    final dayRate = dpMoneyFromLabel(candidate.rateRange);
    return Column(
      children: [
        DPTwoColumn(
          left: _InfoSection(
            title: 'Spec sheet',
            icon: Icons.video_camera_back_outlined,
            rows: [
              ('Kit', candidate.skills.join(', ')),
              ('Output', 'HMI equivalent'),
              ('Accessories', 'Stands, diffusion, gel kit'),
              ('Power draw', '2.4kW total'),
            ],
          ),
          right: _InfoSection(
            title: 'Rate card',
            icon: Icons.receipt_long_outlined,
            rows: [
              ('Day', _pkr(dayRate)),
              ('Week', _pkr((dayRate * 5).round())),
              ('Deposit', '${_pkr((dayRate * 1.2).round())} refundable'),
              ('Insurance', 'Included'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _GallerySection(
          title: 'Photos',
          filters: ['Kit', 'On-set', 'Case'],
          tiles: ['Kit', 'Kit', 'On-set', 'On-set', 'Case', 'Case'],
        ),
        const SizedBox(height: 12),
        _WorkHistorySection(
          title: 'Recent rentals',
          rows: const [
            ('Echo Street Music Video', 'Jul 2026'),
            ('Noor Couture Campaign', 'Jul 2026'),
          ],
        ),
        const SizedBox(height: 12),
        _InfoSection(
          title: 'Condition, availability, reviews',
          icon: Icons.public_outlined,
          rows: [
            ('Condition', 'Excellent — serviced monthly'),
            (
              'Availability',
              candidate.available ? 'Available now' : 'Limited dates',
            ),
            ('Reviews', '${candidate.rating}/5'),
          ],
        ),
      ],
    );
  }
}

class _AgencyProfile extends StatelessWidget {
  final DpCandidate candidate;

  const _AgencyProfile({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _GallerySection(
          title: 'Roster preview',
          filters: ['Lead talent', 'Background', 'Kids'],
          tiles: [
            'Talent 01',
            'Talent 02',
            'Talent 03',
            'Talent 04',
            'Talent 05',
            'Talent 06'
          ],
        ),
        const SizedBox(height: 12),
        DPTwoColumn(
          left: _InfoSection(
            title: 'Agency details',
            icon: Icons.corporate_fare_outlined,
            rows: [
              ('Roster size', '120 talents'),
              ('Specialties', candidate.skills.join(', ')),
              ('Response time', '4h median'),
              ('Active contracts', '${candidate.completedBookings ~/ 3}'),
            ],
          ),
          right: _InfoSection(
            title: 'Rate & terms',
            icon: Icons.receipt_long_outlined,
            rows: [
              ('Commission', '12% standard'),
              ('Casting fee', candidate.rateRange),
              ('Payment terms', '50% upfront'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _WorkHistorySection(
          title: 'Recent placements',
          rows: const [
            ('Aurora Biscuit TVC', 'Casting · Jul 2026'),
            ('Hunza Winter Film', 'Casting · Jul 2026'),
          ],
        ),
        const SizedBox(height: 12),
        _InfoSection(
          title: 'Office, availability, reviews',
          icon: Icons.public_outlined,
          rows: [
            ('Office', '${candidate.city} · exact address on booking'),
            ('Reviews', '${candidate.rating}/5'),
            (
              'Availability',
              candidate.available ? 'Accepting new briefs' : 'Limited capacity',
            ),
          ],
        ),
      ],
    );
  }
}

class _ShowreelSection extends StatelessWidget {
  final DpCandidate candidate;
  final String title;
  final String? caption;

  const _ShowreelSection({
    required this.candidate,
    this.title = 'Featured showreel',
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _ProfileSection(
      title: title,
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
        dpText(
          context,
          caption ?? '${candidate.name} selected reel • in-app playback',
        ),
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

/// One reusable gallery shape (filter chips + tile grid) covering every
/// "gallery" style section across categories — video portfolios, photo
/// galleries, showreels & stills, roster previews all render identically.
class _GallerySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> filters;
  final List<String> tiles;

  const _GallerySection({
    required this.title,
    this.icon = Icons.photo_library_outlined,
    required this.filters,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: title,
      icon: icon,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in filters)
              DPStatusChip(label: filter, tone: DpTone.info),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tile in tiles) _PhotoTile(label: tile),
          ],
        ),
      ],
    );
  }
}

/// Plain label/value rows section — used for specs, rate cards, comp
/// cards, and the socials/availability/reviews block per category.
class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<(String, String)> rows;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: title,
      icon: icon,
      children: [
        for (final row in rows) DPDetailRow(label: row.$1, value: row.$2),
      ],
    );
  }
}

/// Same label/value row shape as [_InfoSection], used for work history,
/// recent bookings/rentals/placements — kept as a separate name to match
/// the design's distinct "history" section type.
class _WorkHistorySection extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;

  const _WorkHistorySection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: title,
      icon: Icons.workspace_premium_outlined,
      children: [
        for (final row in rows) DPDetailRow(label: row.$1, value: row.$2),
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
              '${candidate.instagramHandle} · ${(candidate.instagramFollowers / 1000).toStringAsFixed(1)}k',
        ),
        DPDetailRow(label: 'Rate card', value: candidate.rateRange),
        DPDetailRow(
          label: 'Availability',
          value:
              candidate.available ? 'Open for selected dates' : 'Limited dates',
        ),
        DPDetailRow(label: 'Reviews', value: '${candidate.rating}/5'),
      ],
    );
  }
}

String _pkr(int amount) {
  if (amount >= 1000000) return 'PKR ${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return 'PKR ${(amount / 1000).round()}k';
  return 'PKR $amount';
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
