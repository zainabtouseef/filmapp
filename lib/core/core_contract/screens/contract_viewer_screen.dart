import 'package:flutter/material.dart';

import '../../contracts/contract_models.dart';
import '../../contracts/contracts_controller.dart';
import '../../core_ui/widgets/core_widgets.dart';
import '../../network/save_download.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';

class ContractViewerScreen extends StatefulWidget {
  final String? contractId;
  final bool showAddendumBanner;

  /// Called once the in-sheet OTP signature actually succeeds — lets a
  /// caller sync its own booking/contract state without this shared
  /// screen depending on any portal-specific store.
  final VoidCallback? onSigned;

  const ContractViewerScreen({
    super.key,
    this.contractId,
    this.showAddendumBanner = false,
    this.onSigned,
  });

  @override
  State<ContractViewerScreen> createState() => _ContractViewerScreenState();
}

class _ContractViewerScreenState extends State<ContractViewerScreen> {
  bool _signed = false;
  bool _signing = false;
  Future<CineContract>? _contractFuture;
  final bool requiresKycBeforeSigning = true;

  // Contract identifiers are opaque server values. Production demo records use
  // `DEMO-CTR-*`, while user-created records may use a different prefix; the
  // backend remains the authority for existence and access control.
  bool get _live => widget.contractId?.trim().isNotEmpty ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_live && _contractFuture == null) {
      final contracts = ContractsScope.maybeOf(context);
      if (contracts != null) {
        _contractFuture = contracts.contract(widget.contractId!);
      }
    }
  }

  void _correctionDialog([CineContract? contract]) {
    final controller = TextEditingController();
    final rootContext = context;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.appColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'What needs correction?',
          style: AppTextStyles.sectionTitle
              .copyWith(color: dialogContext.appColors.textPrimary),
        ),
        content: CoreTextField(
          controller: controller,
          label: 'Correction note',
          icon: Icons.edit_note_outlined,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final contracts = ContractsScope.maybeOf(rootContext);
              if (contract == null || contracts == null) {
                showCoreSnack(
                  rootContext,
                  'A live contract is required before requesting a correction.',
                );
                return;
              }
              try {
                await contracts.createAddendum(
                  contractId: contract.publicId,
                  reason: 'Correction request',
                  content: controller.text.trim().isEmpty
                      ? 'Please review the requested correction.'
                      : controller.text.trim(),
                );
              } catch (_) {
                if (rootContext.mounted) {
                  showCoreSnack(
                    rootContext,
                    'Correction request could not be sent. Please try again.',
                  );
                }
                return;
              }
              if (!rootContext.mounted || !dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              showCoreSnack(rootContext, 'Correction request sent');
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _signatureSheet() {
    final typed = TextEditingController();
    final rootContext = context;
    final contracts = ContractsScope.maybeOf(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: _SignatureSheet(
          typed: typed,
          loading: _signing,
          onSigned: (consent) async {
            if (!_live || contracts == null) {
              showCoreSnack(
                rootContext,
                'Open a live CineConnect contract before signing.',
              );
              return;
            }
            if (typed.text.trim().length < 2) {
              showCoreSnack(rootContext, 'Enter your signed-in account name.');
              return;
            }
            if (!consent) {
              showCoreSnack(
                  rootContext, 'Confirm the signing acknowledgement.');
              return;
            }
            if (_signing) return;
            setState(() => _signing = true);
            try {
              final updated = await contracts.sign(
                widget.contractId!,
                typedName: typed.text.trim(),
                consent: consent,
              );
              if (!mounted || !rootContext.mounted) return;
              setState(() {
                _signed = updated.isSigned;
                _contractFuture = Future.value(updated);
                _signing = false;
              });
            } catch (error) {
              if (!mounted || !rootContext.mounted) return;
              setState(() => _signing = false);
              showCoreSnack(rootContext, '$error');
              return;
            }
            if (!sheetContext.mounted || !rootContext.mounted) return;
            Navigator.pop(sheetContext);
            widget.onSigned?.call();
            showCoreSuccessDialog(
              rootContext,
              title: 'Contract Signed',
              message: 'The agreement status is now marked as Signed.',
            );
          },
        ),
      ),
    );
  }

  Future<void> _downloadPdf(CineContract contract) async {
    final contracts = ContractsScope.maybeOf(context);
    if (contracts == null) return;
    try {
      final download = await contracts.downloadContract(contract.publicId);
      if (!mounted) return;
      final saved =
          saveDownload(download.filename, download.bytes, download.contentType);
      showCoreSnack(
        context,
        saved
            ? 'Contract PDF downloaded'
            : 'Contract PDF is ready. Browser download is available on web.',
      );
    } catch (error) {
      if (mounted) showCoreSnack(context, 'Contract download failed: $error');
    }
  }

  void _retryContract() {
    final contracts = ContractsScope.maybeOf(context);
    if (!_live || contracts == null) return;
    setState(() {
      _contractFuture = contracts.contract(widget.contractId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_live && _contractFuture != null) {
      return FutureBuilder<CineContract>(
        future: _contractFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CoreScreenScaffold(
              child: CoreEmptyState(
                icon: Icons.hourglass_top_rounded,
                title: 'Loading contract',
                message: 'Fetching the signed agreement from CineConnect.',
              ),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return CoreScreenScaffold(
              child: CoreEmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Contract unavailable',
                message:
                    'CineConnect could not load this live contract. No demo contract is being substituted.',
                actionLabel: 'Retry',
                onAction: _retryContract,
              ),
            );
          }
          final contract = snapshot.data!;
          _signed = contract.isSigned;
          return _contractScaffold(context, contract: contract);
        },
      );
    }
    return const CoreScreenScaffold(
      child: CoreEmptyState(
        icon: Icons.description_outlined,
        title: 'Choose a live contract',
        message:
            'Open a contract from a booking or contract workspace to review and sign it.',
      ),
    );
  }

  Widget _contractScaffold(
    BuildContext context, {
    required CineContract contract,
  }) {
    final colors = context.appColors;
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoreAppHeader(
            title: 'Contract Viewer',
            subtitle:
                'Review auto-filled terms, versions, signing and verification.',
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: 18),
          CoreGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        contract.title,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: colors.textPrimary,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    StatusBadge(
                      label: _signed ? 'Signed' : 'Awaiting Signature',
                      tone: _signed
                          ? CoreStatusTone.success
                          : CoreStatusTone.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Contract ID: ${contract.publicId} · Booking ${contract.bookingId} · ${contract.displayValue}',
                  style: AppTextStyles.caption
                      .copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: colors.goldMid,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Contract version ${contract.versionNumber} · Template version ${contract.template.versionNumber}',
                        style: AppTextStyles.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (requiresKycBeforeSigning) ...[
            const SizedBox(height: 14),
            const InlineNotice(
              message:
                  'Identity verification required before signing high-value contracts.',
              icon: Icons.lock_outline_rounded,
              tone: CoreStatusTone.warning,
            ),
          ],
          if (widget.showAddendumBanner) ...[
            const SizedBox(height: 14),
            const InlineNotice(
              message: 'Addendum request opened from chat decision.',
              icon: Icons.note_add_outlined,
              tone: CoreStatusTone.info,
            ),
          ],
          const SizedBox(height: 18),
          _documentBody(context, contract: contract),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _actionButton(Icons.edit_note_outlined, 'Request Correction',
                  () => _correctionDialog(contract)),
              _actionButton(
                Icons.draw_outlined,
                _signed ? 'Contract Signed' : 'Review & Sign',
                _signed ? null : _signatureSheet,
              ),
              _actionButton(Icons.picture_as_pdf_outlined, 'Download PDF',
                  () => _downloadPdf(contract)),
              _actionButton(
                Icons.qr_code_2_rounded,
                'QR verification unavailable',
                () => showCoreSnack(
                  context,
                  'QR verification requires a signed verification service and is not enabled.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback? onTap) {
    return SizedBox(
      width: 190,
      child: CoreSecondaryButton(
        icon: icon,
        label: label,
        compact: true,
        onTap: onTap,
      ),
    );
  }

  Widget _documentBody(
    BuildContext context, {
    required CineContract contract,
  }) {
    final colors = context.appColors;
    final clauses = contract.clauses;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        // Fully opaque in both themes — this is document text, it must
        // never let the animated backdrop show through behind it.
        color: colors.isLight ? colors.surface : colors.softSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color:
                colors.shadow.withValues(alpha: colors.isLight ? 0.16 : 0.34),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'CINECONNECT CONTRACT RECORD',
              style: AppTextStyles.panelLabel.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ContractClauseRow(
            title: 'Parties',
            value: contract.counterpartySummary,
          ),
          ContractClauseRow(
            title: 'Commercials',
            value:
                '${contract.displayValue} · effective ${contract.effectiveDate ?? 'on signature'} · ${contract.signatureProgressPercent}',
          ),
          for (var i = 0; i < clauses.length; i++)
            ContractClauseRow(
              title: clauses[i].title,
              value: clauses[i].bodyText,
              showDivider: i != clauses.length - 1,
            ),
        ],
      ),
    );
  }
}

class ContractClauseRow extends StatelessWidget {
  final String title;
  final String value;
  final bool showDivider;

  const ContractClauseRow({
    super.key,
    required this.title,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.micro.copyWith(
              color: colors.goldDark,
              letterSpacing: 0,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: colors.textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureSheet extends StatefulWidget {
  final TextEditingController typed;
  final bool loading;
  final Future<void> Function(bool consent) onSigned;

  const _SignatureSheet({
    required this.typed,
    required this.loading,
    required this.onSigned,
  });

  @override
  State<_SignatureSheet> createState() => _SignatureSheetState();
}

class _SignatureSheetState extends State<_SignatureSheet> {
  bool _consent = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      decoration: BoxDecoration(
        gradient: colors.cardGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'E-Signing Options',
              style: AppTextStyles.sectionTitle
                  .copyWith(color: colors.textPrimary, fontSize: 19),
            ),
            const SizedBox(height: 14),
            CoreTextField(
              controller: widget.typed,
              label: 'Signed-in account name',
              icon: Icons.drive_file_rename_outline,
            ),
            const SizedBox(height: 14),
            CheckboxListTile(
              value: _consent,
              onChanged: widget.loading
                  ? null
                  : (value) => setState(() => _consent = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'I reviewed this contract and agree to sign it using my authenticated CineConnect account.',
                style: AppTextStyles.body.copyWith(color: colors.textPrimary),
              ),
            ),
            const SizedBox(height: 18),
            CorePrimaryButton(
              icon: Icons.verified_outlined,
              label: 'Sign with authenticated account',
              loading: widget.loading,
              onTap: () => widget.onSigned(_consent),
            ),
          ],
        ),
      ),
    );
  }
}
