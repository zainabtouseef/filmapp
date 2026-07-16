import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/brand_sponsor_demo_data.dart';
import '../widgets/brand_sponsor_components.dart';

class BR02BrandProfileScreen extends StatelessWidget {
  const BR02BrandProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = BrandSponsorDemoStore.instance;
    final profile = BrandSponsorDemoData.profile;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return BrandTwoColumn(
          left: BrandSectionCard(
            title: 'Brand identity',
            icon: Icons.business_center_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrandMediaFrame(
                  imageUrl: profile.imageUrl,
                  title: profile.name,
                  badge: profile.category,
                  fallbackIcon: Icons.campaign_outlined,
                  aspectRatio: 16 / 8.2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.metricNumberCompact.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: store.profilePublished ? 'PUBLISHED' : 'DRAFT',
                      color: store.profilePublished
                          ? colors.success
                          : colors.goldMid,
                      icon: store.profilePublished
                          ? Icons.verified_outlined
                          : Icons.edit_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  profile.description,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                BrandResponsiveGrid(
                  minWidth: 210,
                  children: [
                    BrandInfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'KYB',
                      value: profile.trustStatus,
                    ),
                    BrandInfoRow(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: profile.category,
                    ),
                    BrandInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Representative',
                      value: profile.representative,
                    ),
                    BrandInfoRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Billing',
                      value: profile.billing,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CoreSecondaryButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit profile',
                        compact: true,
                        onTap: () => _showEditSheet(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CorePrimaryButton(
                        icon: store.profilePublished
                            ? Icons.visibility_off_outlined
                            : Icons.publish_outlined,
                        label: store.profilePublished ? 'Unpublish' : 'Publish',
                        compact: true,
                        onTap: () {
                          store.toggleProfilePublished();
                          brandSnack(context, 'Brand profile state updated');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          right: Column(
            children: [
              BrandSectionCard(
                title: 'Brand assets',
                icon: Icons.image_outlined,
                child: Column(
                  children: [
                    BrandResponsiveGrid(
                      minWidth: 120,
                      children: [
                        for (final item in BrandSponsorDemoData.opportunities)
                          BrandMediaFrame(
                            imageUrl: item.imageUrl,
                            title: item.title,
                            badge: item.category,
                            fallbackIcon: Icons.image_outlined,
                            aspectRatio: 1,
                            compact: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CorePrimaryButton(
                      icon: Icons.cloud_upload_outlined,
                      label: store.assetUploadPending
                          ? 'Asset pending moderation'
                          : 'Upload asset',
                      compact: true,
                      onTap: () {
                        store.queueAssetUpload();
                        brandSnack(context, 'Asset preview queued');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BrandSectionCard(
                title: 'Campaign history',
                icon: Icons.history_outlined,
                child: Column(
                  children: [
                    for (final payment in BrandSponsorDemoData.payments.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: GlassSectionCard(
                          radius: 14,
                          padding: const EdgeInsets.all(10),
                          child: BrandInfoRow(
                            icon: Icons.payments_outlined,
                            label: payment.label,
                            value: payment.amount,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditSheet(BuildContext context) {
    final name = TextEditingController(text: BrandSponsorDemoData.profile.name);
    final category =
        TextEditingController(text: BrandSponsorDemoData.profile.category);
    showBrandSheet(
      context,
      title: 'Edit brand profile',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: InputDecoration(
              labelText: 'Brand name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: category,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.save_outlined,
            label: 'Save changes',
            onTap: () {
              Navigator.pop(context);
              brandSnack(context, 'Brand profile changes saved');
            },
          ),
        ],
      ),
    );
  }
}
