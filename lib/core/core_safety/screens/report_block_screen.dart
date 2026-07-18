import 'package:flutter/material.dart';

import '../../core_ui/core_back_navigation.dart';
import '../../core_ui/widgets/core_widgets.dart';
import '../../network/api_exception.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../../trust_safety/trust_safety_controller.dart';

class ReportBlockScreen extends StatefulWidget {
  final String? initialReason;
  final String entityType;
  final String? entityId;
  final String? reportedUserId;

  /// Called when the report is submitted with "Block user" switched on —
  /// lets the caller persist the block in whatever store backs its own
  /// blocked-users list, without this shared screen depending on any
  /// portal-specific state.
  final VoidCallback? onBlock;

  const ReportBlockScreen({
    super.key,
    this.initialReason,
    this.entityType = 'user',
    this.entityId,
    this.reportedUserId,
    this.onBlock,
  });

  @override
  State<ReportBlockScreen> createState() => _ReportBlockScreenState();
}

class _ReportBlockScreenState extends State<ReportBlockScreen> {
  static const _reasons = [
    'Fake offer',
    'Harassment',
    'Fake profile',
    'Payment fraud',
    'Stolen portfolio content',
    'Image misuse',
    'Unsafe shoot environment',
    'Other',
  ];

  late String _reason;
  late final TextEditingController _description;
  String _urgency = 'Normal';
  bool _uploaded = false;
  bool _block = false;
  bool _submitting = false;
  String? _notice;
  List<String> _liveReasons = const [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialReason;
    if (initial != null && _reasons.contains(initial)) {
      _reason = initial;
      _description = TextEditingController();
    } else {
      _reason = 'Other';
      _description = TextEditingController(text: initial ?? '');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    if (_liveReasons.isNotEmpty) return;
    final trustSafety = TrustSafetyScope.maybeOf(context);
    if (trustSafety == null) return;
    try {
      final reasons = await trustSafety.reportReasons();
      if (!mounted) return;
      setState(() {
        _liveReasons = reasons;
        _notice = 'Live report reasons loaded from Trust & Safety.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notice =
            'Live reporting unavailable — this screen will keep your draft locally.';
      });
    }
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  String _reasonCode() {
    if (_liveReasons.contains(_reason)) return _reason;
    return switch (_reason) {
      'Harassment' => 'harassment',
      'Fake offer' || 'Fake profile' => 'spam',
      'Payment fraud' => 'fraud',
      'Unsafe shoot environment' => 'safety_concern',
      'Stolen portfolio content' || 'Image misuse' => 'inappropriate_content',
      _ => 'other',
    };
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final trustSafety = TrustSafetyScope.maybeOf(context);
    try {
      if (trustSafety != null) {
        await trustSafety.createReport({
          'entity_type': widget.entityType,
          'entity_id': widget.entityId ??
              widget.reportedUserId ??
              'DEMO-REPORTED-ENTITY',
          'reported_user_id': widget.reportedUserId,
          'reason': _reasonCode(),
          'description':
              '${_description.text.trim()}\nUrgency: $_urgency\nEvidence attached: $_uploaded',
        });
        if (_block && widget.reportedUserId != null) {
          await trustSafety.blockUser(widget.reportedUserId!,
              reason: _reasonCode());
        }
      }
      if (_block) {
        widget.onBlock?.call();
      }
      if (!mounted) return;
      showCoreSuccessDialog(
        context,
        title: 'Report submitted to CineConnect Support.',
        message: _block
            ? widget.reportedUserId == null
                ? 'Report saved. Blocking needs a real user id from the calling screen.'
                : 'This user will no longer be able to contact you.'
            : 'Support CRM and moderation routing have received the live report.',
        buttonLabel: 'Return',
        onDone: () => navigateCoreBack(context),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showCoreSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      showCoreSnack(context, 'Could not submit report right now.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoreAppHeader(
            title: 'Report & Block',
            subtitle:
                'Report fake offers, harassment, payment issues or unsafe behavior.',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 18),
          if (_notice != null) ...[
            InlineNotice(
              message: _notice!,
              tone: _notice!.startsWith('Live')
                  ? CoreStatusTone.info
                  : CoreStatusTone.warning,
            ),
            const SizedBox(height: 12),
          ],
          CoreGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_off_outlined, color: colors.goldDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reported user/project: Ali Khan · TVC Shoot — Lahore',
                          style: AppTextStyles.label
                              .copyWith(color: colors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CoreDropdownField<String>(
                  value: _liveReasons.isEmpty
                      ? _reason
                      : _liveReasons.contains(_reason)
                          ? _reason
                          : _reasonCode(),
                  values: _liveReasons.isEmpty ? _reasons : _liveReasons,
                  label: 'Reason picker',
                  icon: Icons.report_problem_outlined,
                  onChanged: (value) =>
                      setState(() => _reason = value ?? _reason),
                ),
                const SizedBox(height: 14),
                UploadCard(
                  title: 'Evidence attachment',
                  subtitle: 'Attach screenshots, contracts or payment proof',
                  uploaded: _uploaded,
                  onTap: () => setState(() => _uploaded = true),
                ),
                const SizedBox(height: 14),
                CoreTextField(
                  controller: _description,
                  label: 'Description',
                  icon: Icons.notes_outlined,
                  maxLines: 5,
                ),
                const SizedBox(height: 14),
                CoreDropdownField<String>(
                  value: _urgency,
                  values: const ['Normal', 'Urgent', 'Safety Risk'],
                  label: 'Urgency selector',
                  icon: Icons.priority_high_rounded,
                  onChanged: (value) =>
                      setState(() => _urgency = value ?? _urgency),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: colors.goldMid,
                  value: _block,
                  onChanged: (value) => setState(() => _block = value),
                  title: Text(
                    'Block user',
                    style:
                        AppTextStyles.label.copyWith(color: colors.textPrimary),
                  ),
                  subtitle: Text(
                    'This user will no longer be able to contact you.',
                    style: AppTextStyles.caption
                        .copyWith(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(height: 18),
                CorePrimaryButton(
                  icon: Icons.outbox_outlined,
                  label: _submitting ? 'Submitting...' : 'Submit report',
                  onTap: _submitting ? null : _submit,
                ),
                const SizedBox(height: 10),
                CoreSecondaryButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Return to previous screen',
                  onTap: () => navigateCoreBack(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
