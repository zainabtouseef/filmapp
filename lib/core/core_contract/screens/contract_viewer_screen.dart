import 'package:flutter/material.dart';

import '../../core_ui/mock_data/shared_mock_data.dart';
import '../../core_ui/widgets/core_widgets.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';

class ContractViewerScreen extends StatefulWidget {
  final bool showAddendumBanner;

  /// Called once the in-sheet OTP signature actually succeeds — lets a
  /// caller sync its own booking/contract state without this shared
  /// screen depending on any portal-specific store.
  final VoidCallback? onSigned;

  const ContractViewerScreen({
    super.key,
    this.showAddendumBanner = false,
    this.onSigned,
  });

  @override
  State<ContractViewerScreen> createState() => _ContractViewerScreenState();
}

class _ContractViewerScreenState extends State<ContractViewerScreen> {
  String _version = 'v1.1';
  bool _signed = false;
  final bool requiresKycBeforeSigning = true;

  void _correctionDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'What needs correction?',
          style: AppTextStyles.sectionTitle
              .copyWith(color: context.appColors.textPrimary),
        ),
        content: CoreTextField(
          controller: controller,
          label: 'Correction note',
          icon: Icons.edit_note_outlined,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showCoreSnack(context, 'Correction request sent');
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _signatureSheet() {
    final typed = TextEditingController();
    final otp = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: _SignatureSheet(
          typed: typed,
          otp: otp,
          onSigned: () {
            if (otp.text.trim().length != 6) {
              showCoreSnack(context, 'Enter any 6-digit OTP');
              return;
            }
            Navigator.pop(context);
            setState(() => _signed = true);
            widget.onSigned?.call();
            showCoreSuccessDialog(
              context,
              title: 'Contract Signed',
              message: 'The agreement status is now marked as Signed.',
            );
          },
        ),
      ),
    );
  }

  void _qrDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        final colors = context.appColors;
        return AlertDialog(
          backgroundColor: colors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'QR Verification',
            style:
                AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 150,
                height: 150,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.textPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 49,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (_, i) => Container(
                    color: (i * 7 + i) % 3 == 0
                        ? colors.onGold
                        : colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'CC-CON-2026-0041',
                style: AppTextStyles.label.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        'Actor Booking Agreement',
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
                  'Contract ID: CC-CON-2026-0041 · Booking BK-2048 · TVC Shoot — Lahore',
                  style: AppTextStyles.caption
                      .copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 14),
                CoreDropdownField<String>(
                  value: _version,
                  values: const ['v1.0', 'v1.1', 'Addendum 1'],
                  label: 'Version selector',
                  icon: Icons.history_rounded,
                  onChanged: (value) =>
                      setState(() => _version = value ?? _version),
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
          _documentBody(context),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _actionButton(Icons.edit_note_outlined, 'Request Correction',
                  _correctionDialog),
              _actionButton(
                  Icons.draw_outlined, 'Sign Contract', _signatureSheet),
              _actionButton(Icons.picture_as_pdf_outlined, 'Download PDF',
                  () => showCoreSnack(context, 'PDF download simulated')),
              _actionButton(
                  Icons.qr_code_2_rounded, 'View QR Verification', _qrDialog),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
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

  Widget _documentBody(BuildContext context) {
    final colors = context.appColors;
    final clauses = SharedMockData.clauses;
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
          for (var i = 0; i < clauses.length; i++)
            ContractClauseRow(
              title: clauses[i].title,
              value: clauses[i].value,
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

class _SignatureSheet extends StatelessWidget {
  final TextEditingController typed;
  final TextEditingController otp;
  final VoidCallback onSigned;

  const _SignatureSheet({
    required this.typed,
    required this.otp,
    required this.onSigned,
  });

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
              controller: typed,
              label: 'Typed signature',
              icon: Icons.drive_file_rename_outline,
            ),
            const SizedBox(height: 14),
            Container(
              height: 92,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                'Draw signature area',
                style:
                    AppTextStyles.caption.copyWith(color: colors.textSecondary),
              ),
            ),
            const SizedBox(height: 14),
            OtpInputRow(controller: otp),
            const SizedBox(height: 18),
            CorePrimaryButton(
              icon: Icons.verified_outlined,
              label: 'OTP-confirmed signature',
              onTap: onSigned,
            ),
          ],
        ),
      ),
    );
  }
}
