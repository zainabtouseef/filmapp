import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
              title: 'Privacy & Boundaries',
              icon: Icons.health_and_safety_outlined,
              child: Column(
                children: [
                  _SafetySwitch(
                    label: 'Phone number hidden',
                    subtitle: 'Directors contact you through CineConnect chat.',
                    value: store.phoneHidden,
                    onChanged: store.togglePhoneHidden,
                  ),
                  _SafetySwitch(
                    label: 'Adult content boundary',
                    subtitle: 'Blocks unsafe or mismatched content offers.',
                    value: store.adultContentBoundary,
                    onChanged: store.toggleAdultContentBoundary,
                  ),
                  _SafetySwitch(
                    label: 'Travel consent required',
                    subtitle: 'Outstation requests need explicit confirmation.',
                    value: store.travelConsentRequired,
                    onChanged: store.toggleTravelConsent,
                  ),
                  _SafetySwitch(
                    label: 'Emergency support on shoot days',
                    subtitle: 'Shows safety contact during active bookings.',
                    value: store.emergencySupport,
                    onChanged: store.toggleEmergencySupport,
                    showDivider: false,
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
                            onBlock: () =>
                                store.block('Ali Khan (TVC Shoot — Lahore)'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.call_outlined,
                      label: 'Emergency contact',
                      compact: true,
                      onTap: () async {
                        await Clipboard.setData(
                          const ClipboardData(text: '+92 300 0000000'),
                        );
                        if (!context.mounted) return;
                        actorSnack(
                          context,
                          'Emergency support number copied: +92 300 0000000',
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Safety reports route to SC-16 and Super Admin support queue.',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusChip(
                label: 'Using local safety preview',
                color: context.appColors.goldMid,
              ),
              const SizedBox(height: 8),
              _DemoBlockedUsersList(names: fallbackNames),
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

class _SafetySwitch extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _SafetySwitch({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
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
