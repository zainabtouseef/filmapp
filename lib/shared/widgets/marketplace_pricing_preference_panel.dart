import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/core_ui/widgets/core_widgets.dart';
import '../../core/marketplace/marketplace_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/cine_card_system.dart';

/// Provider-owned marketplace pricing controls shared by every specialist
/// portal. The choice is stored on the listing and enforced by the booking API.
class MarketplacePricingPreferencePanel extends StatefulWidget {
  final Set<String> listingTypes;
  final String title;

  const MarketplacePricingPreferencePanel({
    super.key,
    required this.listingTypes,
    this.title = 'Marketplace pricing visibility',
  });

  @override
  State<MarketplacePricingPreferencePanel> createState() =>
      _MarketplacePricingPreferencePanelState();
}

class _MarketplacePricingPreferencePanelState
    extends State<MarketplacePricingPreferencePanel> {
  Future<List<MarketplaceListing>>? _future;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<List<MarketplaceListing>> _load() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) return const [];
    final listings = await auth.myMarketplaceListings();
    return listings.where((listing) {
      if (widget.listingTypes.contains(listing.listingType)) return true;
      return widget.listingTypes.contains('actor') &&
          listing.listingType == 'talent';
    }).toList();
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CardShell(
      tone: CineTone.premium,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.price_check_outlined, color: colors.goldDark),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh pricing settings',
                onPressed: _saving ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Choose what buyers see and whether they may counter. This setting applies to cards, profiles, booking requests, and bargaining.',
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<MarketplaceListing>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator(minHeight: 2);
              }
              if (snapshot.hasError) {
                return InlineNotice(
                  message: _message(snapshot.error!),
                  icon: Icons.cloud_off_outlined,
                  tone: CoreStatusTone.warning,
                );
              }
              final listings = snapshot.data ?? const [];
              if (listings.isEmpty) {
                return const InlineNotice(
                  message:
                      'Publish your marketplace profile first. Its pricing choice will appear here immediately.',
                  icon: Icons.storefront_outlined,
                  tone: CoreStatusTone.info,
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < listings.length; index++) ...[
                    _PricingListingRow(
                      listing: listings[index],
                      busy: _saving,
                      onEdit: () => _edit(listings[index]),
                    ),
                    if (index != listings.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _edit(MarketplaceListing listing) async {
    var mode = listing.pricingMode;
    final amount = TextEditingController(
      text: listing.configuredPriceFromMinor == null
          ? ''
          : '${listing.configuredPriceFromMinor! ~/ 100}',
    );
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Pricing for ${listing.title}'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: mode,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Buyer-facing pricing choice',
                      prefixIcon: Icon(Icons.visibility_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'fixed',
                        child: Text('Fixed public price'),
                      ),
                      DropdownMenuItem(
                        value: 'negotiable',
                        child: Text('Public starting price + bargaining'),
                      ),
                      DropdownMenuItem(
                        value: 'on_request',
                        child: Text('Hide price + invite offers'),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setDialogState(() {
                              if (value != null) mode = value;
                              error = null;
                            }),
                  ),
                  const SizedBox(height: 12),
                  CoreTextField(
                    controller: amount,
                    label: mode == 'on_request'
                        ? 'Private guide price (optional, PKR)'
                        : 'Public price (PKR)',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  InlineNotice(
                    message: _description(mode),
                    icon: mode == 'fixed'
                        ? Icons.lock_outline_rounded
                        : Icons.handshake_outlined,
                    tone: CoreStatusTone.info,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    InlineNotice(
                      message: error!,
                      icon: Icons.error_outline_rounded,
                      tone: CoreStatusTone.danger,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      final whole = int.tryParse(
                        amount.text.replaceAll(RegExp(r'[^0-9]'), ''),
                      );
                      if (mode != 'on_request' && (whole == null || whole <= 0)) {
                        setDialogState(
                          () => error = 'Add a valid public price.',
                        );
                        return;
                      }
                      setState(() => _saving = true);
                      try {
                        await AuthScope.of(context)
                            .updateMarketplaceListingPricing(
                          listingId: listing.publicId,
                          pricingMode: mode,
                          priceFromMinor:
                              whole == null || whole <= 0 ? null : whole * 100,
                          currency: listing.currency,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (caught) {
                        setDialogState(() => error = _message(caught));
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save choice'),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    if (saved == true && mounted) _refresh();
  }
}

class _PricingListingRow extends StatelessWidget {
  final MarketplaceListing listing;
  final bool busy;
  final VoidCallback onEdit;

  const _PricingListingRow({
    required this.listing,
    required this.busy,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 10, 11),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: listing.allowsBargaining ? colors.infoBlue : colors.goldMid,
            width: 4,
          ),
          top: BorderSide(color: colors.border),
          right: BorderSide(color: colors.border),
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${listing.pricingChoiceLabel} · ${listing.showsPrice ? listing.toCandidate().rateRange : 'amount hidden'}',
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : onEdit,
            icon: const Icon(Icons.tune_outlined, size: 17),
            label: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

String _description(String mode) => switch (mode) {
      'fixed' =>
        'Buyers see the amount and may accept it. The server blocks counteroffers.',
      'on_request' =>
        'No amount appears on marketplace cards or profiles. Buyers submit an offer and bargaining stays available.',
      _ =>
        'Buyers see this starting amount and both sides may bargain through tracked counteroffers.',
    };

String _message(Object error) {
  if (error is ApiException) return error.message;
  return 'Could not update marketplace pricing. Try again.';
}
