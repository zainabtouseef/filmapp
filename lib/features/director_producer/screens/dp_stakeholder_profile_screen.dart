import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/director/director_discovery_models.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/open_url.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/verification/verification_models.dart';
import '../models/dp_candidate.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_empty_state.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';
import '../../../shared/layout/kyc_status_banner.dart';

class DPStakeholderProfileScreen extends StatefulWidget {
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
  State<DPStakeholderProfileScreen> createState() =>
      _DPStakeholderProfileScreenState();
}

class _DPStakeholderProfileScreenState
    extends State<DPStakeholderProfileScreen> {
  Future<Object>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<Object> _load() async {
    final id = widget.candidateId;
    final auth = AuthScope.maybeOf(context);
    if (id == null || id.isEmpty) {
      throw const ApiException(
        code: 'validation.missing_listing',
        message: 'Open a live marketplace listing to view its profile.',
      );
    }
    if (auth == null || !auth.isAuthenticated) {
      throw const ApiException(
        code: 'auth.required',
        message: 'Sign in to load the live stakeholder profile.',
      );
    }
    final directorRoute = _DirectorDiscoveryRoute.tryParse(id);
    if (directorRoute != null) {
      return auth.directorDiscoveryItem(
        kind: directorRoute.kind,
        publicId: directorRoute.publicId,
      );
    }
    return auth.marketplaceListing(id);
  }

  void _retry() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Object>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const DPGlassCard(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _ProfileErrorState(
            message: _friendlyError(snapshot.error),
            onRetry: _retry,
          );
        }
        final data = snapshot.data!;
        if (data is DirectorDiscoveryItem) {
          final candidate = data.toCandidate();
          final type = widget.profileType ?? candidate.category;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DPProjectBreadcrumbs(
                project: null,
                current: candidate.name,
              ),
              const SizedBox(height: 10),
              _ProfileHero(candidate: candidate, type: type),
              const SizedBox(height: 14),
              _LiveDirectorDiscoveryProfile(item: data, candidate: candidate),
              const SizedBox(height: 14),
              DPGlassCard(
                selected: true,
                child: Row(
                  children: [
                    Expanded(
                      child: DPHolographicButton(
                        label: candidate.marketplaceListingId == null
                            ? 'Provider action pending'
                            : 'Shortlist to project',
                        icon: candidate.marketplaceListingId == null
                            ? Icons.link_off_rounded
                            : Icons.favorite_border_rounded,
                        onTap: candidate.marketplaceListingId == null
                            ? () => _showProviderActionPending(
                                  context,
                                  candidate,
                                )
                            : () => _showShortlistHint(context, candidate),
                        secondary: true,
                      ),
                    ),
                    if (candidate.marketplaceListingId != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: DPHolographicButton(
                          label: 'Select / Send Request',
                          icon: Icons.send_rounded,
                          onTap: () async {
                            if (!await ensureKycApproved(context)) return;
                            if (!context.mounted) return;
                            Navigator.pushNamed(
                              context,
                              DirectorProducerRoutes.bookingRequest,
                              arguments: {
                                'candidateId': candidate.marketplaceListingId,
                                'projectId': widget.projectId,
                                'category': type,
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }
        final listing = data as MarketplaceListing;
        final candidate = listing.toCandidate();
        final type = widget.profileType ?? candidate.category;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DPProjectBreadcrumbs(
              project: null,
              current: candidate.name,
            ),
            const SizedBox(height: 10),
            _ProfileHero(candidate: candidate, type: type),
            const SizedBox(height: 14),
            _LiveListingProfile(listing: listing, candidate: candidate),
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
                      onTap: () async {
                        if (!await ensureKycApproved(context)) return;
                        if (!context.mounted) return;
                        Navigator.pushNamed(
                          context,
                          DirectorProducerRoutes.bookingRequest,
                          arguments: {
                            'candidateId': candidate.id,
                            'projectId': widget.projectId,
                            'category': type,
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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

  void _showProviderActionPending(BuildContext context, DpCandidate candidate) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${candidate.name} is a live provider profile. Booking and shortlist actions need a marketplace listing link first.',
        ),
      ),
    );
  }

  String _friendlyError(Object? error) {
    if (error is ApiException) {
      return switch (error.code) {
        'auth.required' ||
        'auth.invalid_token' =>
          'Sign in to load live stakeholder details.',
        'network.offline' =>
          'Live stakeholder details are unavailable. Check your connection and retry.',
        _ => error.message,
      };
    }
    return 'Live stakeholder details are unavailable right now.';
  }
}

class _DirectorDiscoveryRoute {
  final String kind;
  final String publicId;

  const _DirectorDiscoveryRoute({
    required this.kind,
    required this.publicId,
  });

  static _DirectorDiscoveryRoute? tryParse(String value) {
    final parts = value.split(':');
    if (parts.length != 3 || parts.first != 'director') return null;
    return _DirectorDiscoveryRoute(kind: parts[1], publicId: parts[2]);
  }
}

class _ProfileErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      accentColor: colors.warning,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, color: colors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not load live profile',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              child: candidate.imageUrl == null
                  ? null
                  : Image.network(
                      candidate.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
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
                                '$type • ${candidate.city}',
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

class _LiveListingProfile extends StatelessWidget {
  final MarketplaceListing listing;
  final DpCandidate candidate;

  const _LiveListingProfile({
    required this.listing,
    required this.candidate,
  });

  @override
  Widget build(BuildContext context) {
    final media = listing.media
        .where((item) => item.file?.publicUrl != null)
        .take(6)
        .toList();
    return Column(
      children: [
        DPTwoColumn(
          left: _ProfileSection(
            title: 'Live profile summary',
            icon: Icons.badge_outlined,
            children: [
              dpText(context, listing.summary),
              const SizedBox(height: 12),
              DPDetailRow(label: 'Listing type', value: candidate.category),
              DPDetailRow(label: 'City', value: candidate.city),
              DPDetailRow(label: 'Rate', value: candidate.rateRange),
              DPDetailRow(label: 'Owner', value: listing.ownerName),
              DPDetailRow(
                label: 'Verification',
                value: listing.verificationStatus,
              ),
            ],
          ),
          right: _ProfileSection(
            title: 'Booking readiness',
            icon: Icons.event_available_outlined,
            children: [
              DPDetailRow(
                label: 'Availability',
                value: candidate.available
                    ? 'Available for selected dates'
                    : 'Limited dates',
              ),
              DPDetailRow(
                label: 'Contact policy',
                value: 'Phone/address reveal after booking visibility rules',
              ),
              DPDetailRow(
                label: 'Source',
                value: 'Live marketplace database',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (media.isEmpty)
          const DPEmptyState(
            icon: Icons.photo_library_outlined,
            title: 'No public gallery yet',
            message:
                'This listing has no approved public media attached in the database.',
          )
        else
          _LiveGallerySection(media: media),
      ],
    );
  }
}

class _LiveDirectorDiscoveryProfile extends StatelessWidget {
  final DirectorDiscoveryItem item;
  final DpCandidate candidate;

  const _LiveDirectorDiscoveryProfile({
    required this.item,
    required this.candidate,
  });

  @override
  Widget build(BuildContext context) {
    final sections = item.sections.where((section) {
      return section.rows.any((row) => row.value.trim().isNotEmpty);
    }).toList();
    return Column(
      children: [
        DPTwoColumn(
          left: _ProfileSection(
            title: 'Live provider summary',
            icon: Icons.storefront_outlined,
            children: [
              dpText(context, item.summary),
              const SizedBox(height: 12),
              DPDetailRow(label: 'Provider type', value: candidate.category),
              DPDetailRow(label: 'City', value: candidate.city),
              DPDetailRow(label: 'Rate', value: candidate.rateRange),
              DPDetailRow(label: 'Owner', value: item.ownerName ?? 'Not shown'),
              DPDetailRow(
                label: 'Verification',
                value: item.verificationStatus,
              ),
            ],
          ),
          right: _ProfileSection(
            title: 'Director readiness',
            icon: Icons.fact_check_outlined,
            children: [
              DPDetailRow(
                label: 'Availability',
                value: candidate.available
                    ? 'Marked available in provider database'
                    : 'Limited or pending status',
              ),
              const DPDetailRow(
                label: 'Booking status',
                value:
                    'Profile view only until provider record is linked to a marketplace listing.',
              ),
              const DPDetailRow(
                label: 'Source',
                value: 'Live provider-specific Director discovery database',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (item.kind == 'actor' || item.kind == 'model') ...[
          _ResumeSection(resumeFile: item.resumeFile),
          const SizedBox(height: 12),
        ],
        for (final section in sections) ...[
          _ProfileSection(
            title: section.title,
            icon: Icons.info_outline_rounded,
            children: [
              if (section.rows.isEmpty)
                const DPEmptyState(
                  icon: Icons.info_outline_rounded,
                  title: 'No details yet',
                  message:
                      'This provider has not filled this section in the database.',
                )
              else
                for (final row in section.rows)
                  DPDetailRow(label: row.label, value: row.value),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (item.media.isEmpty)
          const DPEmptyState(
            icon: Icons.photo_library_outlined,
            title: 'No public gallery yet',
            message:
                'This provider has no approved public media attached in the database.',
          )
        else
          _LiveGallerySection(media: item.media),
      ],
    );
  }
}

class _ResumeSection extends StatelessWidget {
  final UploadedFile? resumeFile;

  const _ResumeSection({required this.resumeFile});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final file = resumeFile;
    final url = file?.publicUrl;
    return _ProfileSection(
      title: 'CV / Resume',
      icon: Icons.description_outlined,
      children: [
        if (file == null || url == null)
          const DPEmptyState(
            icon: Icons.description_outlined,
            title: 'No CV / resume uploaded',
            message: 'This actor / talent has not uploaded a CV or resume yet.',
          )
        else
          Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, color: colors.goldDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  file.originalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DPHolographicButton(
                label: 'View',
                icon: Icons.open_in_new_rounded,
                secondary: true,
                onTap: () => openUrlInNewTab(url),
              ),
            ],
          ),
      ],
    );
  }
}

class _LiveGallerySection extends StatelessWidget {
  final List<MarketplaceListingMedia> media;

  const _LiveGallerySection({required this.media});

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: 'Public gallery',
      icon: Icons.photo_library_outlined,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in media)
              _PhotoTile(
                label: item.caption ?? item.file?.originalName ?? 'Media',
                imageUrl: item.file?.publicUrl,
                isVideo:
                    item.file?.mimeType.startsWith('video/') ?? false,
              ),
          ],
        ),
      ],
    );
  }
}

class DPProjectBreadcrumbs extends StatelessWidget {
  final Object? project;
  final String current;

  const DPProjectBreadcrumbs({super.key, this.project, required this.current});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(Icons.travel_explore_outlined, size: 16, color: colors.goldDark),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Marketplace / $current',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class DPDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DPDetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
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

class _PhotoTile extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool isVideo;

  const _PhotoTile({
    required this.label,
    this.imageUrl,
    this.isVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final url = imageUrl;
    return GestureDetector(
      onTap: url == null ? null : () => openUrlInNewTab(url),
      child: Container(
        width: 96,
        height: 96,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: colors.goldGradient,
          border: Border.all(color: colors.border),
          image: url == null || isVideo
              ? null
              : DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                ),
        ),
        child: Stack(
          children: [
            if (isVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            Align(
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
          ],
        ),
      ),
    );
  }
}
