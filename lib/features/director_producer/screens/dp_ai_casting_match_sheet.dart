import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/layout/kyc_status_banner.dart';
import '../models/dp_candidate.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_empty_state.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPAICastingMatchFab extends StatelessWidget {
  final String? initialCategory;
  final String? projectId;

  const DPAICastingMatchFab({
    super.key,
    this.initialCategory,
    this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'AI casting match score',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _openSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: colors.goldGradient,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colors.goldDark.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.goldDark.withValues(alpha: 0.26),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, color: colors.onGold),
                const SizedBox(width: 9),
                Text(
                  'AI Match',
                  style:
                      AppTextStyles.statusText.copyWith(color: colors.onGold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AICastingMatchSheet(
        initialCategory: initialCategory,
        projectId: projectId,
        onProfile: (candidate) => _openProfile(context, candidate),
        onRequest: (candidate) => _openRequest(context, candidate),
      ),
    );
  }

  void _openProfile(BuildContext context, DpCandidate candidate) {
    Navigator.pushNamed(
      context,
      DirectorProducerRoutes.profile,
      arguments: {
        'candidateId': candidate.profileId,
        'type': candidate.category,
        if (projectId != null) 'projectId': projectId,
      },
    );
  }

  Future<void> _openRequest(
    BuildContext context,
    DpCandidate candidate,
  ) async {
    if (candidate.marketplaceListingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${candidate.name} needs a public marketplace listing before requests can be sent.',
          ),
        ),
      );
      return;
    }
    if (!await ensureKycApproved(context)) return;
    if (!context.mounted) return;
    Navigator.pushNamed(
      context,
      DirectorProducerRoutes.bookingRequest,
      arguments: {
        'candidateId': candidate.marketplaceListingId,
        if (projectId != null) 'projectId': projectId,
        'category': candidate.category,
      },
    );
  }
}

class _AICastingMatchSheet extends StatefulWidget {
  final String? initialCategory;
  final String? projectId;
  final ValueChanged<DpCandidate> onProfile;
  final ValueChanged<DpCandidate> onRequest;

  const _AICastingMatchSheet({
    required this.initialCategory,
    required this.projectId,
    required this.onProfile,
    required this.onRequest,
  });

  @override
  State<_AICastingMatchSheet> createState() => _AICastingMatchSheetState();
}

class _AICastingMatchSheetState extends State<_AICastingMatchSheet> {
  final _briefController = TextEditingController();
  final _budgetController = TextEditingController();
  late String _category = _normalizeCategory(widget.initialCategory);
  String _city = 'Any city';
  String _language = 'Any language';
  bool _verifiedOnly = true;
  Future<List<DpCandidate>>? _future;

  static const _categories = ['All', 'Actors', 'Models', 'Influencers'];
  static const _cities = [
    'Any city',
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Peshawar',
    'Quetta',
  ];
  static const _languages = [
    'Any language',
    'Urdu',
    'English',
    'Punjabi',
    'Sindhi',
    'Pashto',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void dispose() {
    _briefController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<List<DpCandidate>> _load() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      throw const ApiException(
        code: 'auth.required',
        message: 'Sign in to run AI casting match.',
      );
    }
    final bundle = await auth.directorDiscovery(category: _category);
    return bundle.items
        .map((item) => item.toCandidate())
        .where((candidate) => _categories.contains(candidate.category))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.54,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: DPGlassCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ListView(
                controller: controller,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
                ),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: colors.goldGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: colors.onGold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CineMatch AI casting score',
                              style: AppTextStyles.cardTitle.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            dpText(
                              context,
                              'Paste a role brief and rank live actors, models and influencers by fit.',
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _briefController,
                    minLines: 3,
                    maxLines: 5,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Script / role brief',
                      hintText:
                          'Example: Lahore telecom ad, warm Urdu-speaking female lead, 25-35, confident on camera.',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ChoiceSection(
                    label: 'Talent type',
                    values: _categories,
                    selected: _category,
                    onSelected: (value) {
                      setState(() {
                        _category = value;
                        _future = _load();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _ChoiceSection(
                    label: 'Shoot city',
                    values: _cities,
                    selected: _city,
                    onSelected: (value) => setState(() => _city = value),
                  ),
                  const SizedBox(height: 10),
                  _ChoiceSection(
                    label: 'Language',
                    values: _languages,
                    selected: _language,
                    onSelected: (value) => setState(() => _language = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Max budget PKR',
                            hintText: '150000',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SwitchListTile.adaptive(
                          value: _verifiedOnly,
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          title: Text(
                            'Prefer verified',
                            style: AppTextStyles.smallMeta.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onChanged: (value) =>
                              setState(() => _verifiedOnly = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FutureBuilder<List<DpCandidate>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const DPGlassCard(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return DPEmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Match engine unavailable',
                          message: _friendlyError(snapshot.error),
                        );
                      }
                      final candidates = snapshot.data ?? const <DpCandidate>[];
                      if (candidates.isEmpty) {
                        return const DPEmptyState(
                          icon: Icons.person_search_outlined,
                          title: 'No live talent to rank',
                          message:
                              'Publish actor, model or influencer marketplace listings first, then run CineMatch again.',
                        );
                      }
                      final results = candidates
                          .map(_scoreCandidate)
                          .where((result) =>
                              !_verifiedOnly || result.candidate.verified)
                          .toList()
                        ..sort((a, b) => b.score.compareTo(a.score));
                      if (results.isEmpty) {
                        return const DPEmptyState(
                          icon: Icons.verified_user_outlined,
                          title: 'No verified matches',
                          message:
                              'Turn off “Prefer verified” or approve more talent profiles in Super Admin.',
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DpDotLabel(
                            label: 'Ranked ${results.length} live profiles',
                            tone: DpTone.success,
                          ),
                          const SizedBox(height: 10),
                          for (final result in results.take(8)) ...[
                            _AIMatchResultCard(
                              result: result,
                              onProfile: () {
                                Navigator.pop(context);
                                widget.onProfile(result.candidate);
                              },
                              onRequest: () {
                                Navigator.pop(context);
                                widget.onRequest(result.candidate);
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _CastingMatchResult _scoreCandidate(DpCandidate candidate) {
    final reasons = <String>[];
    final risks = <String>[];
    var score = 36.0;

    final brief = _briefController.text.trim().toLowerCase();
    final searchable = [
      candidate.name,
      candidate.category,
      candidate.city,
      candidate.notes,
      ...candidate.skills,
      candidate.instagramHandle,
    ].join(' ').toLowerCase();

    if (_category == 'All') {
      score += 6;
    } else if (candidate.category == _category) {
      score += 18;
      reasons.add('Correct talent type');
    }

    if (_city == 'Any city') {
      score += 6;
    } else if (candidate.city.toLowerCase() == _city.toLowerCase()) {
      score += 18;
      reasons.add('City fit');
    } else {
      score -= 8;
      risks.add('Different city');
    }

    if (candidate.available) {
      score += 10;
      reasons.add('Available');
    } else {
      score -= 12;
      risks.add('Limited availability');
    }

    if (candidate.verified) {
      score += 9;
      reasons.add('Verified profile');
    } else {
      score -= 8;
      risks.add('Verification pending');
    }

    if (_language == 'Any language') {
      score += 4;
    } else if (searchable.contains(_language.toLowerCase())) {
      score += 10;
      reasons.add('Language signal');
    } else {
      score -= 4;
      risks.add('Language not confirmed');
    }

    final budget = _parseBudget(_budgetController.text);
    final rate = _parseRate(candidate.rateRange);
    if (budget == null) {
      score += 4;
    } else if (rate == null) {
      score += 2;
      risks.add('Rate needs confirmation');
    } else if (rate <= budget) {
      score += 14;
      reasons.add('Inside budget');
    } else {
      score -= 10;
      risks.add('Above budget');
    }

    final tokens = brief
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length >= 3)
        .toSet();
    if (tokens.isEmpty) {
      reasons.add('Add a richer brief for sharper ranking');
      score += 4;
    } else {
      final matches = tokens.where(searchable.contains).length;
      final boost = math.min(20, matches * 5).toDouble();
      score += boost;
      if (matches > 0) reasons.add('$matches brief signals matched');
    }

    if (candidate.rating > 0) {
      score += math.min(8, candidate.rating * 1.4);
    }
    if (candidate.completedBookings > 0) {
      score += math.min(7, candidate.completedBookings / 5);
      reasons.add('Booking history');
    }
    if (candidate.category == 'Influencers' &&
        candidate.instagramFollowers >= 10000) {
      score += 7;
      reasons.add('Audience reach');
    }

    final clamped = score.round().clamp(1, 99);
    return _CastingMatchResult(
      candidate: candidate,
      score: clamped,
      reasons: reasons.take(4).toList(),
      risks: risks.take(3).toList(),
    );
  }

  int? _parseBudget(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  int? _parseRate(String value) {
    final normalized = value.toLowerCase().replaceAll(',', '');
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*([km]?)').firstMatch(normalized);
    if (match == null) return null;
    final number = double.tryParse(match.group(1) ?? '');
    if (number == null) return null;
    final suffix = match.group(2);
    final multiplier = suffix == 'm'
        ? 1000000
        : suffix == 'k'
            ? 1000
            : 1;
    return (number * multiplier).round();
  }

  String _normalizeCategory(String? category) {
    return _categories.contains(category) ? category! : 'All';
  }

  String _friendlyError(Object? error) {
    if (error is ApiException) return error.message;
    return 'Could not load live marketplace profiles right now.';
  }
}

class _AIMatchResultCard extends StatelessWidget {
  final _CastingMatchResult result;
  final VoidCallback onProfile;
  final VoidCallback onRequest;

  const _AIMatchResultCard({
    required this.result,
    required this.onProfile,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final candidate = result.candidate;
    final scoreTone = result.score >= 78
        ? DpTone.success
        : result.score >= 58
            ? DpTone.warning
            : DpTone.info;
    return DPGlassCard(
      padding: const EdgeInsets.all(13),
      accentColor: result.score >= 78 ? colors.success : colors.goldDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CandidateImage(candidate: candidate),
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
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${candidate.category} · ${candidate.city} · ${candidate.rateRange}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${result.score}%',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: colors.goldDark,
                    ),
                  ),
                  DpDotLabel(label: 'Match', tone: scoreTone),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final reason in result.reasons)
                DPStatusChip(label: reason, tone: DpTone.success),
              for (final risk in result.risks)
                DPStatusChip(label: risk, tone: DpTone.warning),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DPHolographicButton(
                  label: 'Profile',
                  icon: Icons.person_search_rounded,
                  secondary: true,
                  onTap: onProfile,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DPHolographicButton(
                  label: 'Request',
                  icon: Icons.send_rounded,
                  onTap: onRequest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CandidateImage extends StatelessWidget {
  final DpCandidate candidate;

  const _CandidateImage({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 50,
        height: 50,
        child: candidate.imageUrl?.isNotEmpty == true
            ? Image.network(
                candidate.imageUrl!,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                fit: BoxFit.cover,
                semanticLabel: '${candidate.name} profile image',
                errorBuilder: (_, __, ___) =>
                    _FallbackAvatar(label: candidate.avatarLabel),
              )
            : _FallbackAvatar(label: candidate.avatarLabel),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String label;

  const _FallbackAvatar({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      alignment: Alignment.center,
      color: colors.softSurface,
      child: Text(
        label,
        style: AppTextStyles.cardLabel.copyWith(
          color: colors.goldDark,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  final String label;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  const _ChoiceSection({
    required this.label,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final value in values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DpDotChip(
                    label: value,
                    active: selected == value,
                    onTap: () => onSelected(value),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CastingMatchResult {
  final DpCandidate candidate;
  final int score;
  final List<String> reasons;
  final List<String> risks;

  const _CastingMatchResult({
    required this.candidate,
    required this.score,
    required this.reasons,
    required this.risks,
  });
}
