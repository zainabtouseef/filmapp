import 'package:flutter/material.dart';

import '../../../core/core_safety/screens/report_block_screen.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/trust_safety/trust_safety_controller.dart';
import '../../../core/trust_safety/trust_safety_models.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _blockedUsersFuture ??= TrustSafetyScope.maybeOf(context)?.blockedUsers();
  }

  void _refreshBlockedUsers() {
    final trustSafety = TrustSafetyScope.maybeOf(context);
    if (trustSafety == null) return;
    setState(() {
      _blockedUsersFuture = trustSafety.blockedUsers(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActorTalentDemoStore.instance,
      builder: (context, _) {
        final store = ActorTalentDemoStore.instance;
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
            ActorTwoColumn(
              left: ActorSectionCard(
                title: 'Blocked Users',
                icon: Icons.block_rounded,
                child: _BlockedUsersPanel(
                  fallbackNames: store.blockedUsers.toList(),
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
                          builder: (_) => ReportBlockScreen(
                            onBlock: TrustSafetyScope.maybeOf(context) == null
                                ? () =>
                                    store.block('Ali Khan (TVC Shoot - Lahore)')
                                : null,
                          ),
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
      },
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
}

class _BlockedUsersPanel extends StatelessWidget {
  final List<String> fallbackNames;
  final Future<List<BlockedUserDto>>? future;
  final VoidCallback onRefresh;

  const _BlockedUsersPanel({
    required this.fallbackNames,
    required this.future,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return _DemoBlockedUsersList(names: fallbackNames);
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

class _DemoBlockedUsersList extends StatelessWidget {
  final List<String> names;

  const _DemoBlockedUsersList({required this.names});

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) {
      return StatusChip(
        label: 'No blocked users',
        color: context.appColors.success,
      );
    }
    return Column(
      children: [
        for (var i = 0; i < names.length; i++)
          _DemoBlockedUserRow(
            name: names[i],
            showDivider: i != names.length - 1,
          ),
      ],
    );
  }
}

class _DemoBlockedUserRow extends StatelessWidget {
  final String name;
  final bool showDivider;

  const _DemoBlockedUserRow({required this.name, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Row(
        children: [
          Icon(Icons.person_off_outlined, color: colors.danger, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ActorTalentDemoStore.instance.unblock(name);
              actorSnack(context, '$name unblocked');
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
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
