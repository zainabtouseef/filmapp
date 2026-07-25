import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/core_ui/core_routes.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/cine_card_system.dart';

/// A persistent nudge shown at the top of every business-portal screen
/// while the signed-in user's identity verification isn't approved yet —
/// signup lets people skip KYC to explore the app, but this keeps
/// reminding them, and [ensureKycApproved] blocks the actions that
/// actually need a verified account (see that function's doc).
///
/// Renders nothing for signed-out sessions, super admin staff (no
/// `AuthRole`/KYC applies to them), or once verification is approved.
class KycStatusBanner extends StatefulWidget {
  const KycStatusBanner({super.key});

  @override
  State<KycStatusBanner> createState() => _KycStatusBannerState();
}

class _KycStatusBannerState extends State<KycStatusBanner> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    if (auth != null && auth.isAuthenticated && auth.kycStatus == null) {
      auth.refreshKycStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) return const SizedBox.shrink();
    final status = auth.kycStatus;
    if (status == null || status == 'approved') return const SizedBox.shrink();

    final colors = context.appColors;
    final (icon, tone, message, ctaLabel) = switch (status) {
      'pending' => (
          Icons.hourglass_top_rounded,
          CineTone.information,
          'Verification under review — some actions stay locked until it\'s approved.',
          'View status',
        ),
      'needs_resubmission' || 'rejected' => (
          Icons.error_outline_rounded,
          CineTone.critical,
          'Verification needs attention — resubmit your documents to unlock bookings.',
          'Resubmit',
        ),
      _ => (
          Icons.verified_user_outlined,
          CineTone.warning,
          'Verification incomplete — complete it to send or accept bookings.',
          'Complete Verification',
        ),
    };
    final tint = cineToneColor(context, tone);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: CardShell(
        variant: CardVariant.alert,
        density: CardDensity.compact,
        tone: tone,
        accentEdge: true,
        onTap: () => _openVerification(context, status),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: tint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.caption.copyWith(
                  color: colors.textPrimary,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _openVerification(context, status),
              child: Text(ctaLabel),
            ),
          ],
        ),
      ),
    );
  }

  void _openVerification(BuildContext context, String status) {
    if (status == 'pending') {
      Navigator.pushNamed(context, CoreRoutes.verificationStatus);
      return;
    }
    final auth = AuthScope.of(context);
    final roleLabel = auth.user?.primaryRole?.name ?? 'Director / Producer';
    Navigator.pushNamed(context, CoreRoutes.kyc, arguments: roleLabel);
  }
}

/// Blocks an action (booking request, etc.) unless the signed-in user's
/// KYC is approved — shows a dialog pointing them at verification instead.
/// Returns `true` if the caller should proceed, `false` if it was blocked.
///
/// Signed-out sessions and accounts where `kycStatus` hasn't loaded yet are
/// allowed through here (the real auth/authorization check still happens
/// server-side) — this is a UX nudge, not the security boundary.
Future<bool> ensureKycApproved(BuildContext context) async {
  final auth = AuthScope.maybeOf(context);
  if (auth == null || !auth.isAuthenticated) return true;
  final status = auth.kycStatus;
  if (status == null) {
    // Not loaded yet — kick off a fetch for next time, but don't block now.
    unawaited(auth.refreshKycStatus());
    return true;
  }
  if (status == 'approved') return true;

  final message = status == 'pending'
      ? 'Your verification is still under review. You can send booking requests once it\'s approved.'
      : 'Complete your verification first — bookings and contracts require a verified account.';
  final roleLabel = auth.user?.primaryRole?.name ?? 'Director / Producer';

  final proceedToKyc = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Verification required'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
              status == 'pending' ? 'View status' : 'Complete Verification'),
        ),
      ],
    ),
  );

  if (proceedToKyc == true && context.mounted) {
    Navigator.pushNamed(
      context,
      status == 'pending' ? CoreRoutes.verificationStatus : CoreRoutes.kyc,
      arguments: status == 'pending' ? null : roleLabel,
    );
  }
  return false;
}
