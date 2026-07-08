import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// A talent portrait that gracefully falls back to a cinematic
/// placeholder if the asset is missing (so the app runs before you
/// drop real photos into assets/images/).
class PortraitImage extends StatelessWidget {
  final String asset;
  final BoxFit fit;
  final String? label;

  const PortraitImage({
    super.key,
    required this.asset,
    this.fit = BoxFit.cover,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = _placeholder();
    if (asset.isEmpty) return placeholder;
    return Image.asset(
      asset,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF262019), Color(0xFF15110C)],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline_rounded,
              color: AppColors.textTertiary, size: 34),
          if (label != null) ...[
            const SizedBox(height: 6),
            Text(label!, style: AppTextStyles.micro),
          ],
        ],
      ),
    );
  }
}
