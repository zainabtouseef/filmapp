import 'package:flutter/material.dart';

import '../widgets/cine_marketplace_card.dart';

/// The Flow Reel's profile tab bar: plain text tabs, active tab in ink
/// with a thin gold underline — deliberately simpler than
/// [lib/shared/widgets/talent_tabs_bar.dart]'s glowing carousel-filter
/// tabs, which serve a different purpose elsewhere in the app.
class EntityProfileTabs extends StatelessWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const EntityProfileTabs({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CineMarketplaceVisuals.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Padding(
                  padding:
                      EdgeInsets.only(right: i == tabs.length - 1 ? 0 : 28),
                  child: _Tab(
                    label: tabs[i],
                    active: i == currentIndex,
                    palette: palette,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 0),
        Container(height: 1, color: palette.border),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final CineMarketplacePalette palette;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.active,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: palette.archivo(
                size: 14,
                weight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? palette.ink : palette.muted,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 3,
              width: active ? 28 : 0,
              decoration: BoxDecoration(
                color: palette.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
