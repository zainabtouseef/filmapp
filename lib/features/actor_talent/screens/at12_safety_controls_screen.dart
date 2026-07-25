import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_safety/screens/report_block_screen.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/trust_safety/trust_safety_controller.dart';
import '../../../core/trust_safety/trust_safety_models.dart';
import '../../../core/uploads/upload_repository.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/actor_talent_models.dart';
import '../widgets/actor_talent_components.dart';

/// AT-12 Safety Controls
class AT12SafetyControlsScreen extends StatefulWidget {
  const AT12SafetyControlsScreen({super.key});

  @override
  State<AT12SafetyControlsScreen> createState() =>
      _AT12SafetyControlsScreenState();
}

class _AT12SafetyControlsScreenState extends State<AT12SafetyControlsScreen> {
  Future<List<BlockedUserDto>>? _blockedUsersFuture;
  Future<List<DisputeDto>>? _disputesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _blockedUsersFuture ??= TrustSafetyScope.maybeOf(context)?.blockedUsers();
    _disputesFuture ??= TrustSafetyScope.maybeOf(context)?.disputes();
  }

  void _refreshBlockedUsers() {
    final trustSafety = TrustSafetyScope.maybeOf(context);
    if (trustSafety == null) return;
    setState(() {
      _blockedUsersFuture = trustSafety.blockedUsers(force: true);
    });
  }

  void _refreshDisputes() {
    final trustSafety = TrustSafetyScope.maybeOf(context);
    if (trustSafety == null) return;
    setState(() => _disputesFuture = trustSafety.disputes());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActorSectionCard(
          title: 'Booking Protections',
          icon: Icons.health_and_safety_outlined,
          child: Column(
            children: [
              const ActorInfoRow(
                icon: Icons.phone_locked_outlined,
                label: 'Contact privacy',
                value: 'Use CineConnect chat',
              ),
              const ActorInfoRow(
                icon: Icons.fact_check_outlined,
                label: 'Content and usage',
                value: 'Review before accepting',
              ),
              const ActorInfoRow(
                icon: Icons.flight_takeoff_outlined,
                label: 'Travel consent',
                value: 'Confirm in offer terms',
              ),
              const ActorInfoRow(
                icon: Icons.lock_clock_outlined,
                label: 'Secured dates',
                value: 'Locked by booking',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: 'Account, Privacy & Security',
          icon: Icons.manage_accounts_outlined,
          tone: ActorTone.blue,
          child: ActorResponsiveGrid(
            minWidth: 210,
            children: [
              CoreSecondaryButton(
                icon: Icons.settings_outlined,
                label: 'Account settings',
                onTap: () => Navigator.pushNamed(context, CoreRoutes.settings),
              ),
              CoreSecondaryButton(
                icon: Icons.verified_user_outlined,
                label: 'Identity verification',
                onTap: () => Navigator.pushNamed(
                  context,
                  CoreRoutes.verificationStatus,
                ),
              ),
              CoreSecondaryButton(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () => Navigator.pushNamed(
                  context,
                  CoreRoutes.notifications,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: 'Booking Disputes',
          icon: Icons.gavel_outlined,
          tone: ActorTone.gold,
          actionText: 'Open dispute',
          onActionTap: _openDispute,
          child: _DisputesPanel(
            future: _disputesFuture,
            onRefresh: _refreshDisputes,
            onAddEvidence: _openEvidence,
          ),
        ),
        const SizedBox(height: 12),
        ActorTwoColumn(
          left: ActorSectionCard(
            title: 'Blocked Users',
            icon: Icons.block_rounded,
            child: _BlockedUsersPanel(
              future: _blockedUsersFuture,
              onRefresh: _refreshBlockedUsers,
            ),
          ),
          right: ActorSectionCard(
            title: 'Report & Support',
            icon: Icons.support_agent_outlined,
            child: Column(
              children: [
                CorePrimaryButton(
                  icon: Icons.report_gmailerrorred_outlined,
                  label: 'Report suspicious offer',
                  compact: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ReportBlockScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CoreSecondaryButton(
                  icon: Icons.support_agent_outlined,
                  label: 'Contact safety support',
                  compact: true,
                  onTap: () => _openSafetySupport(context),
                ),
                const SizedBox(height: 12),
                Text(
                  'For immediate danger, leave the location and contact local emergency services.',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: context.appColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSafetySupport(BuildContext context) async {
    final trustSafety = TrustSafetyScope.maybeOf(context);
    if (trustSafety == null) {
      actorSnack(context, 'Sign in to contact safety support');
      return;
    }
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _SafetySupportDialog(trustSafety: trustSafety),
    );
    if (created == true && context.mounted) {
      actorSnack(context, 'Safety support ticket created');
    }
  }

  Future<void> _openDispute() async {
    final trustSafety = TrustSafetyScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    if (trustSafety == null || bookings == null) {
      actorSnack(context, 'Sign in to open a booking dispute');
      return;
    }
    try {
      final rows = (await bookings.bookings(force: true))
          .where((item) => item.status != 'draft')
          .toList();
      if (!mounted) return;
      if (rows.isEmpty) {
        actorSnack(context, 'A sent or confirmed booking is required');
        return;
      }
      final created = await showDialog<bool>(
        context: context,
        builder: (_) => _DisputeDialog(
          trustSafety: trustSafety,
          bookings: rows,
        ),
      );
      if (created == true && mounted) {
        _refreshDisputes();
        actorSnack(context, 'Booking dispute opened');
      }
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    }
  }

  Future<void> _openEvidence(DisputeDto dispute) async {
    final trustSafety = TrustSafetyScope.maybeOf(context);
    final auth = AuthScope.maybeOf(context);
    if (trustSafety == null || auth == null || !auth.isAuthenticated) {
      actorSnack(context, 'Sign in to add dispute evidence');
      return;
    }
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _DisputeEvidenceDialog(
        dispute: dispute,
        trustSafety: trustSafety,
        auth: auth,
      ),
    );
    if (added == true && mounted) {
      _refreshDisputes();
      actorSnack(context, 'Evidence added to dispute');
    }
  }
}

class _DisputesPanel extends StatelessWidget {
  final Future<List<DisputeDto>>? future;
  final VoidCallback onRefresh;
  final ValueChanged<DisputeDto> onAddEvidence;

  const _DisputesPanel({
    required this.future,
    required this.onRefresh,
    required this.onAddEvidence,
  });

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const CoreEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in to view disputes',
        message: 'Booking cases are private to the parties and safety team.',
      );
    }
    return FutureBuilder<List<DisputeDto>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.sync_problem_outlined,
            title: 'Could not load disputes',
            message: 'Check your connection and try again.',
            actionLabel: 'Try again',
            onAction: onRefresh,
          );
        }
        final rows = snapshot.data ?? const <DisputeDto>[];
        if (rows.isEmpty) {
          return const CoreEmptyState(
            icon: Icons.handshake_outlined,
            title: 'No booking disputes',
            message:
                'Payment, cancellation, contract and safety cases appear here.',
          );
        }
        return Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              _DisputeRow(
                dispute: rows[index],
                onAddEvidence: () => onAddEvidence(rows[index]),
              ),
              if (index != rows.length - 1) const Divider(height: 18),
            ],
          ],
        );
      },
    );
  }
}

class _DisputeRow extends StatelessWidget {
  final DisputeDto dispute;
  final VoidCallback onAddEvidence;

  const _DisputeRow({
    required this.dispute,
    required this.onAddEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final open = !const {'resolved', 'rejected'}.contains(dispute.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _titleCase(dispute.type),
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            StatusChip(
              label: _titleCase(dispute.status),
              color: open ? colors.warning : colors.success,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          dispute.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.smallMeta.copyWith(
            color: colors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: Text(
                'Booking ${dispute.bookingId} · ${dispute.evidenceCount} evidence items',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            if (open)
              TextButton.icon(
                onPressed: onAddEvidence,
                icon: const Icon(Icons.attach_file_rounded, size: 17),
                label: const Text('Add evidence'),
              ),
          ],
        ),
      ],
    );
  }
}

class _DisputeDialog extends StatefulWidget {
  final TrustSafetyController trustSafety;
  final List<Booking> bookings;

  const _DisputeDialog({
    required this.trustSafety,
    required this.bookings,
  });

  @override
  State<_DisputeDialog> createState() => _DisputeDialogState();
}

class _DisputeDialogState extends State<_DisputeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  late String _bookingId = widget.bookings.first.publicId;
  String _type = 'payment';
  String _severity = 'medium';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.trustSafety.createDispute({
        'booking_id': _bookingId,
        'type': _type,
        'severity': _severity,
        'description': _description.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Could not open the dispute. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Open booking dispute'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _bookingId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Booking',
                    prefixIcon: Icon(Icons.event_available_outlined),
                  ),
                  items: [
                    for (final booking in widget.bookings)
                      DropdownMenuItem(
                        value: booking.publicId,
                        child: Text(
                          '${booking.requester.displayName} · ${_titleCase(booking.status)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) {
                          if (value != null) _bookingId = value;
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Issue type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'payment', child: Text('Payment')),
                    DropdownMenuItem(
                      value: 'cancellation',
                      child: Text('Cancellation'),
                    ),
                    DropdownMenuItem(
                        value: 'contract', child: Text('Contract')),
                    DropdownMenuItem(value: 'safety', child: Text('Safety')),
                    DropdownMenuItem(value: 'general', child: Text('Other')),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _type = value ?? _type),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _severity,
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    prefixIcon: Icon(Icons.priority_high_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(
                        value: 'critical', child: Text('Critical')),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) =>
                          setState(() => _severity = value ?? _severity),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  minLines: 4,
                  maxLines: 7,
                  enabled: !_submitting,
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Describe the booking issue'
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(color: context.appColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: const Icon(Icons.gavel_outlined),
          label: Text(_submitting ? 'Opening' : 'Open dispute'),
        ),
      ],
    );
  }
}

class _DisputeEvidenceDialog extends StatefulWidget {
  final DisputeDto dispute;
  final TrustSafetyController trustSafety;
  final AuthController auth;

  const _DisputeEvidenceDialog({
    required this.dispute,
    required this.trustSafety,
    required this.auth,
  });

  @override
  State<_DisputeEvidenceDialog> createState() => _DisputeEvidenceDialogState();
}

class _DisputeEvidenceDialogState extends State<_DisputeEvidenceDialog> {
  final _description = TextEditingController();
  PlatformFile? _file;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'mp4'],
      withData: true,
    );
    if (result != null) setState(() => _file = result.files.single);
  }

  Future<void> _submit() async {
    if (_description.text.trim().isEmpty && _file == null) {
      setState(() => _error = 'Add a note or attach a file.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      String? fileId;
      final file = _file;
      if (file != null && file.bytes != null) {
        final uploaded = await widget.auth.uploadFile(
          purpose: 'dispute_evidence',
          file: PickedFileData(
            name: file.name,
            mimeType: _mimeType(file.extension),
            bytes: file.bytes!,
          ),
        );
        fileId = uploaded.publicId;
      }
      await widget.trustSafety.addDisputeEvidence(
        widget.dispute.publicId,
        {
          'evidence_type': fileId == null ? 'note' : 'attachment',
          'description': _description.text.trim(),
          if (fileId != null) 'file_id': fileId,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Could not add evidence. Try again.';
        });
      }
    }
  }

  String _mimeType(String? extension) {
    return switch (extension?.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      'mp4' => 'video/mp4',
      _ => 'image/jpeg',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add dispute evidence'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 6,
              enabled: !_submitting,
              decoration: const InputDecoration(
                labelText: 'Evidence note',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            CoreSecondaryButton(
              icon: Icons.attach_file_rounded,
              label: _file?.name ?? 'Attach image, PDF or video',
              compact: true,
              onTap: _submitting ? null : _pickFile,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: context.appColors.danger),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(_submitting ? 'Adding' : 'Add evidence'),
        ),
      ],
    );
  }
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _BlockedUsersPanel extends StatelessWidget {
  final Future<List<BlockedUserDto>>? future;
  final VoidCallback onRefresh;

  const _BlockedUsersPanel({
    required this.future,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const CoreEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in to view blocked users',
        message: 'Blocked accounts are loaded from Trust & Safety.',
      );
    }
    return FutureBuilder<List<BlockedUserDto>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Column(
            children: [
              const CoreEmptyState(
                icon: Icons.sync_problem_outlined,
                title: 'Could not load blocked users',
                message: 'Check your connection and try again.',
              ),
              const SizedBox(height: 8),
              CoreSecondaryButton(
                icon: Icons.refresh_rounded,
                label: 'Try again',
                compact: true,
                onTap: onRefresh,
              ),
            ],
          );
        }
        final blockedUsers = snapshot.data ?? const [];
        if (blockedUsers.isEmpty) {
          return StatusChip(
            label: 'No blocked users',
            color: context.appColors.success,
          );
        }
        return Column(
          children: [
            for (var i = 0; i < blockedUsers.length; i++)
              _BlockedUserRow(
                user: blockedUsers[i],
                showDivider: i != blockedUsers.length - 1,
                onRefresh: onRefresh,
              ),
          ],
        );
      },
    );
  }
}

class _SafetySupportDialog extends StatefulWidget {
  final TrustSafetyController trustSafety;

  const _SafetySupportDialog({required this.trustSafety});

  @override
  State<_SafetySupportDialog> createState() => _SafetySupportDialogState();
}

class _SafetySupportDialogState extends State<_SafetySupportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController(text: 'Talent safety concern');
  final _message = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.trustSafety.createSupportTicket({
        'category': 'safety',
        'priority': 'high',
        'subject': _subject.text.trim(),
        'message': _message.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not create the ticket. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.support_agent_outlined),
          SizedBox(width: 10),
          Expanded(child: Text('Contact safety support')),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _subject,
                enabled: !_submitting,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (value) =>
                    (value?.trim().length ?? 0) < 2 ? 'Enter a subject' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _message,
                enabled: !_submitting,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'What happened?',
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Describe the safety concern'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: AppTextStyles.smallMeta.copyWith(color: colors.danger),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: Icon(
            _submitting ? Icons.hourglass_top_rounded : Icons.send_outlined,
          ),
          label: Text(_submitting ? 'Sending' : 'Create ticket'),
        ),
      ],
    );
  }
}

class _BlockedUserRow extends StatefulWidget {
  final BlockedUserDto user;
  final bool showDivider;
  final VoidCallback onRefresh;

  const _BlockedUserRow({
    required this.user,
    required this.onRefresh,
    this.showDivider = true,
  });

  @override
  State<_BlockedUserRow> createState() => _BlockedUserRowState();
}

class _BlockedUserRowState extends State<_BlockedUserRow> {
  bool _unblocking = false;

  Future<void> _unblock() async {
    final trustSafety = TrustSafetyScope.maybeOf(context);
    if (trustSafety == null) return;
    setState(() => _unblocking = true);
    try {
      await trustSafety.unblockUser(widget.user.user.publicId);
      widget.onRefresh();
      if (!mounted) return;
      actorSnack(context, '${widget.user.user.displayName} unblocked');
    } catch (error) {
      if (!mounted) return;
      actorSnack(context, 'Could not unblock: $error');
    } finally {
      if (mounted) setState(() => _unblocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reason = widget.user.reason?.trim();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: widget.showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Row(
        children: [
          Icon(Icons.person_off_outlined, color: colors.danger, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: _unblocking ? null : _unblock,
            child: Text(_unblocking ? 'Unblocking…' : 'Unblock'),
          ),
        ],
      ),
    );
  }
}
