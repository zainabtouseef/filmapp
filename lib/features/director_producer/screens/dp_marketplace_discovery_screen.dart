import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../models/dp_candidate.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_candidate_card.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPMarketplaceDiscoveryScreen extends StatefulWidget {
  const DPMarketplaceDiscoveryScreen({super.key});

  @override
  State<DPMarketplaceDiscoveryScreen> createState() =>
      _DPMarketplaceDiscoveryScreenState();
}

class _DPMarketplaceDiscoveryScreenState
    extends State<DPMarketplaceDiscoveryScreen> {
  String _category = 'All';
  Future<List<DpCandidate>>? _candidatesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _candidatesFuture ??= _load();
  }

  Future<List<DpCandidate>> _load() async {
    final type = switch (_category) {
      'Talent' => 'talent',
      _ => null,
    };
    final listings =
        await AuthScope.of(context).marketplaceListings(type: type);
    return listings.map((item) => item.toCandidate()).toList();
  }

  List<DpCandidate> _fallbackRows() {
    return DirectorProducerDemoData.candidates.where((candidate) {
      return _category == 'All' || candidate.category == _category;
    }).toList();
  }

  void _setCategory(String category) {
    setState(() {
      _category = category;
      _candidatesFuture = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.tune_rounded,
          label: 'Filters',
          onTap: () =>
              Navigator.pushNamed(context, DirectorProducerRoutes.filters),
        ),
        const SizedBox(height: 6),
        _MarketplaceSearchBar(
          onSaveSearch: _saveCurrentSearch,
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in const [
                'All',
                'Talent',
                'Models',
                'Crew',
                'Locations',
                'Media & Equipment',
                'Agencies',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _setCategory(category),
                    child: DPStatusChip(
                      label: category,
                      tone: _category == category
                          ? DpTone.warning
                          : DpTone.neutral,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<DpCandidate>>(
          future: _candidatesFuture,
          builder: (context, snapshot) {
            final usingFallback = snapshot.hasError ||
                (snapshot.connectionState == ConnectionState.done &&
                    (snapshot.data ?? const []).isEmpty);
            final candidates = usingFallback
                ? _fallbackRows()
                : snapshot.data ?? const <DpCandidate>[];
            if (snapshot.connectionState != ConnectionState.done &&
                candidates.isEmpty) {
              return const DPGlassCard(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (usingFallback && snapshot.error is ApiException) ...[
                  DPStatusChip(
                    label:
                        'Live marketplace unavailable — showing preview data',
                    tone: DpTone.warning,
                  ),
                  const SizedBox(height: 10),
                ],
                DPResponsiveGrid(
                  minWidth: 300,
                  children: candidates
                      .take(12)
                      .map(
                        (candidate) => DPCandidateCard(
                          candidate: candidate,
                          onProfile: () => Navigator.pushNamed(
                            context,
                            DirectorProducerRoutes.profile,
                            arguments: candidate.id,
                          ),
                          onRequest: () => Navigator.pushNamed(
                            context,
                            DirectorProducerRoutes.bookingRequest,
                          ),
                          onShortlist: () => _shortlistCandidate(candidate),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _saveCurrentSearch() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      _showSnack('Sign in to save marketplace searches.');
      return;
    }
    try {
      await auth.createSavedSearch(
        name: _category == 'All' ? 'Marketplace search' : '$_category search',
        listingType: _category == 'Talent' ? 'talent' : null,
      );
      if (!mounted) return;
      _showSnack('Search saved.');
    } on ApiException catch (exception) {
      if (!mounted) return;
      _showSnack(exception.message);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not save search right now.');
    }
  }

  Future<bool> _shortlistCandidate(DpCandidate candidate) async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      _showSnack('Sign in to save shortlists.');
      return false;
    }
    try {
      await auth.addToDefaultShortlist(candidate.id);
      if (!mounted) return false;
      _showSnack('${candidate.name} added to shortlist.');
      return true;
    } on ApiException catch (exception) {
      if (!mounted) return false;
      _showSnack(exception.message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      _showSnack('Could not update shortlist right now.');
      return false;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _MarketplaceSearchBar extends StatelessWidget {
  final VoidCallback onSaveSearch;

  const _MarketplaceSearchBar({required this.onSaveSearch});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colors.goldDark, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search talent, crew, locations, media, agencies...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          DPHolographicButton(
            label: 'Save Search',
            icon: Icons.bookmark_add_outlined,
            onTap: onSaveSearch,
            secondary: true,
          ),
        ],
      ),
    );
  }
}
