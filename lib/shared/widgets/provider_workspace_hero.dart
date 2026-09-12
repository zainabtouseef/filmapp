import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import 'status_chip.dart';

class ProviderHeroFact {
  final IconData icon;
  final String label;
  final String value;

  const ProviderHeroFact({
    required this.icon,
    required this.label,
    required this.value,
  });
}

/// A shared, image-led identity header for specialist workspaces.
///
/// It intentionally gives the provider's real cover image more visual weight
/// than the surrounding operational cards, while the tinted side panel keeps
/// the important profile and workflow facts scannable.
class ProviderWorkspaceHero extends StatelessWidget {
  final String imageUrl;
  final String? avatarUrl;
  final String eyebrow;
  final String title;
  final String summary;
  final String badge;
  final IconData fallbackIcon;
  final Color accentColor;
  final List<ProviderHeroFact> facts;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  const ProviderWorkspaceHero({
    super.key,
    required this.imageUrl,
    this.avatarUrl,
    required this.eyebrow,
    required this.title,
    required this.summary,
    required this.badge,
    required this.fallbackIcon,
    required this.accentColor,
    required this.facts,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    this.secondaryLabel,
    this.secondaryIcon,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final image = _HeroImage(
          imageUrl: imageUrl,
          title: title,
          badge: badge,
          fallbackIcon: fallbackIcon,
          accentColor: accentColor,
        );
        final details = _HeroDetails(
          compact: compact,
          avatarUrl: avatarUrl,
          eyebrow: eyebrow,
          title: title,
          summary: summary,
          facts: facts,
          accentColor: accentColor,
          primaryLabel: primaryLabel,
          primaryIcon: primaryIcon,
          onPrimary: onPrimary,
          secondaryLabel: secondaryLabel,
          secondaryIcon: secondaryIcon,
          onSecondary: onSecondary,
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.appColors.card,
              border: Border.all(color: context.appColors.border),
            ),
            child: compact
                ? Column(
                    children: [
                      AspectRatio(aspectRatio: 16 / 9, child: image),
                      details,
                    ],
                  )
                : SizedBox(
                    height: 342,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 6, child: image),
                        Expanded(flex: 4, child: details),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String badge;
  final IconData fallbackIcon;
  final Color accentColor;

  const _HeroImage({
    required this.imageUrl,
    required this.title,
    required this.badge,
    required this.fallbackIcon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.trim().isNotEmpty)
          Image.network(
            imageUrl,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                wasSynchronouslyLoaded || frame != null
                    ? child
                    : _fallback(context),
            errorBuilder: (_, __, ___) => _fallback(context),
          )
        else
          _fallback(context),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.78),
              ],
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              StatusChip(label: badge, color: accentColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallback(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.28),
            context.appColors.softSurface,
            accentColor.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -32,
            child: Icon(
              fallbackIcon,
              size: 210,
              color: accentColor.withValues(alpha: 0.12),
            ),
          ),
          Center(
            child: Icon(fallbackIcon, size: 56, color: accentColor),
          ),
        ],
      ),
    );
  }
}

class _HeroDetails extends StatelessWidget {
  final bool compact;
  final String? avatarUrl;
  final String eyebrow;
  final String title;
  final String summary;
  final List<ProviderHeroFact> facts;
  final Color accentColor;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  const _HeroDetails({
    required this.compact,
    required this.avatarUrl,
    required this.eyebrow,
    required this.title,
    required this.summary,
    required this.facts,
    required this.accentColor,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.09),
        border: Border(
          left: BorderSide(color: accentColor, width: 5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _HeroAvatar(
                  imageUrl: avatarUrl ?? '',
                  title: title,
                  accentColor: accentColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.micro.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardLabel.copyWith(
                          color: colors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            for (final fact in facts.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(fact.icon, size: 17, color: accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fact.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.smallMeta.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        fact.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.smallMeta.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (compact) const SizedBox(height: 8) else const Spacer(),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                FilledButton.icon(
                  onPressed: onPrimary,
                  icon: Icon(primaryIcon, size: 18),
                  label: Text(primaryLabel),
                  style: FilledButton.styleFrom(backgroundColor: accentColor),
                ),
                if (secondaryLabel != null && onSecondary != null)
                  OutlinedButton.icon(
                    onPressed: onSecondary,
                    icon: Icon(secondaryIcon ?? Icons.arrow_forward_rounded,
                        size: 18),
                    label: Text(secondaryLabel!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  final String imageUrl;
  final String title;
  final Color accentColor;

  const _HeroAvatar({
    required this.imageUrl,
    required this.title,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final initial = title.trim().isEmpty ? 'C' : title.trim()[0].toUpperCase();
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentColor.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.trim().isEmpty
          ? Center(
              child: Text(
                initial,
                style: AppTextStyles.cardLabel.copyWith(
                  color: accentColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Image.network(
              imageUrl,
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  initial,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
    );
  }
}
