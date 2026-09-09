import 'package:flutter/material.dart';

import '../../../shared/widgets/cine_marketplace_card.dart';
import '../models/dp_candidate.dart';

/// Director/public-buyer adapter for the shared database-backed marketplace
/// card. Keeping this adapter preserves the existing portal API while Brand
/// and Director use the same visual language.
class DPCandidateCard extends StatelessWidget {
  final DpCandidate candidate;
  final VoidCallback? onProfile;
  final VoidCallback? onRequest;
  final Future<bool> Function()? onShortlist;
  final bool featured;

  const DPCandidateCard({
    super.key,
    required this.candidate,
    this.onProfile,
    this.onRequest,
    this.onShortlist,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    return CineMarketplaceCard(
      title: candidate.name,
      kind: _kindForCategory(candidate.category),
      category: candidate.category,
      subtitle: candidate.skills.isEmpty
          ? candidate.category
          : candidate.skills.take(2).join(' · '),
      summary: candidate.notes,
      city: candidate.city,
      rateLabel: candidate.rateRange,
      verificationStatus: candidate.verified ? 'approved' : 'pending',
      imageUrl: candidate.imageUrl,
      tags: candidate.skills,
      available: candidate.available,
      rating: candidate.rating,
      trustScore: candidate.trustMetrics?.score,
      busy: false,
      featured: featured,
      onProfile: onProfile,
      onRequest: onRequest,
      onShortlist: onShortlist,
    );
  }
}

String _kindForCategory(String category) {
  return switch (category.toLowerCase()) {
    'actors' || 'actor' || 'talent' => 'actor',
    'models' || 'model' => 'model',
    'influencers' || 'influencer' || 'creators' => 'influencer',
    'crew' => 'crew',
    'locations' || 'location' => 'location',
    'media & equipment' || 'equipment' => 'equipment',
    'agencies' || 'agency' => 'agency',
    'distribution' => 'distribution',
    _ => 'provider',
  };
}
