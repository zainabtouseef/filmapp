import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_models.dart';
import '../../core_ui/core_routes.dart';
import '../../core_ui/widgets/core_widgets.dart';
import '../../network/api_exception.dart';
import '../../network/browser_push.dart';
import '../../payments/payment_models.dart';
import '../../payments/payments_controller.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../../trust_safety/trust_safety_controller.dart';

class SettingsAccountScreen extends StatefulWidget {
  const SettingsAccountScreen({super.key});

  @override
  State<SettingsAccountScreen> createState() => _SettingsAccountScreenState();
}

class _SettingsAccountScreenState extends State<SettingsAccountScreen> {
  final bool _inApp = true;
  bool _push = false;
  bool _pushSubscribed = false;
  Map<String, dynamic> _capabilities = const {};
  bool _email = false;
  bool _sms = false;
  final bool _whatsapp = false;
  final bool _hidePhone = true;
  final bool _hideLocation = true;
  final bool _watermark = false;
  final bool _biometric = false;
  final bool _twoFactor = false;
  bool _loggingOut = false;
  bool _loadingSettings = true;
  bool _savingSettings = false;
  String _language = 'English';
  String? _settingsError;
  Future<void>? _settingsFuture;
  Future<List<PayoutAccountDto>>? _payoutAccountsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settingsFuture ??= _loadSettings();
    final payments = PaymentsScope.maybeOf(context);
    if (payments != null) {
      _payoutAccountsFuture ??= payments.payoutAccounts();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final auth = AuthScope.of(context);
      final settings = await auth.settings();
      final bootstrap = await auth.bootstrap();
      final data = bootstrap['data'] as Map<String, dynamic>;
      _capabilities =
          Map<String, dynamic>.from(data['capabilities'] as Map? ?? const {});
      final subscribed = await browserPushSubscribed();
      if (mounted) {
        _pushSubscribed = subscribed;
        _applySettings(settings);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _settingsError = error.message;
          _loadingSettings = false;
        });
      }
    }
  }

  void _applySettings(AuthSettings settings) {
    setState(() {
      _language = switch (settings.locale) {
        _ => 'English',
      };
      _push = settings.pushEnabled && _pushSubscribed;
      _email = settings.emailEnabled && _capabilities['email'] == true;
      _sms = settings.smsEnabled && _capabilities['sms_otp'] == true;
      _settingsError = null;
      _loadingSettings = false;
      _savingSettings = false;
    });
  }

  Future<void> _saveSettings({
    String? locale,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
  }) async {
    if (_savingSettings) return;
    setState(() {
      _savingSettings = true;
      _settingsError = null;
    });
    try {
      final settings = await AuthScope.of(context).updateSettings(
        locale: locale,
        pushEnabled: pushEnabled,
        emailEnabled: emailEnabled,
        smsEnabled: smsEnabled,
      );
      if (!mounted) return;
      _applySettings(settings);
      showCoreSnack(context, 'Settings saved');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _settingsError = error.message;
        _savingSettings = false;
      });
      showCoreSnack(context, error.message);
    }
  }

  Future<void> _savePush(bool enabled) async {
    try {
      final auth = AuthScope.of(context);
      final body = enabled
          ? await subscribeBrowserPush(
              _capabilities['vapid_public_key'] as String)
          : await unsubscribeBrowserPush();
      if (body.isNotEmpty) {
        await auth.apiClient.post('/push-devices', body: body);
      }
      if (!mounted) return;
      _pushSubscribed = enabled;
      await _saveSettings(pushEnabled: enabled);
    } catch (error) {
      if (mounted) {
        showCoreSnack(context, 'Push settings were not changed: $error');
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    await AuthScope.of(context).logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      CoreRoutes.login,
      (route) => false,
    );
  }

  Future<void> _addPayoutAccount() async {
    final payments = PaymentsScope.maybeOf(context);
    if (payments == null) return;
    final draft = await showDialog<_PayoutAccountDraft>(
      context: context,
      builder: (_) => const _PayoutAccountDialog(),
    );
    if (draft == null || !mounted) return;
    try {
      await payments.createPayoutAccount(
        provider: draft.provider,
        accountName: draft.accountName,
        accountIdentifier: draft.accountIdentifier,
      );
      if (!mounted) return;
      setState(() {
        _payoutAccountsFuture = payments.payoutAccounts();
      });
      showCoreSnack(context, 'Payout account submitted for verification');
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    }
  }

  Future<void> _contactSupport() async {
    final trustSafety = TrustSafetyScope.maybeOf(context);
    if (trustSafety == null) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _SupportDialog(trustSafety: trustSafety),
    );
    if (created == true && mounted) {
      showCoreSnack(context, 'Support ticket created');
    }
  }

  Future<void> _editBasicInfo() async {
    final auth = AuthScope.of(context);
    final controller =
        TextEditingController(text: auth.user?.displayName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit basic info'),
        content: CoreTextField(
          controller: controller,
          label: 'Display name',
          icon: Icons.person_outline_rounded,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.length >= 2) Navigator.pop(dialogContext, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;
    try {
      await auth.updateMe(displayName: name);
      if (mounted) showCoreSnack(context, 'Basic info updated');
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    }
  }

  Future<void> _activeSessions() async {
    final auth = AuthScope.of(context);
    await showDialog<void>(
      context: context,
      builder: (_) => _ActiveSessionsDialog(auth: auth),
    );
  }

  Future<void> _requestAccountAction(String action) async {
    final trustSafety = TrustSafetyScope.maybeOf(context);
    if (trustSafety == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Request account $action'),
        content: Text(
          action == 'deletion'
              ? 'Support will verify your identity, review retained booking and payment records, and contact you before deletion.'
              : 'Support will verify the request and contact you before deactivating access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await trustSafety.createSupportTicket({
        'category': 'account_$action',
        'priority': 'high',
        'subject': 'Account $action request',
        'message':
            'Please verify my identity and begin the account $action process. I understand support will contact me before any account state changes.',
      });
      if (mounted) showCoreSnack(context, 'Account $action request created');
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    }
  }

  void _faqSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SettingsSheet(
        title: 'Help Center',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _FaqRow(
              question: 'How does payment verification work?',
              answer: 'Upload proof; Super Admin verifies before closure.',
            ),
            _FaqRow(
              question: 'When is contact visible?',
              answer: 'Phone and exact location unlock after secured booking.',
            ),
            _FaqRow(
              question: 'Can I switch roles?',
              answer: 'Yes, from the role switcher once each role is verified.',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoreAppHeader(
            title: 'Settings & Account',
            subtitle:
                'Account, notifications, privacy, payments, security and support.',
            icon: Icons.settings_outlined,
          ),
          const SizedBox(height: 18),
          _section('Account', [
            _navRow(
              Icons.person_outline,
              'Edit basic info',
              _editBasicInfo,
              subtitle:
                  'Update the display name used across every CineConnect portal.',
            ),
            _navRow(
              Icons.lock_reset_rounded,
              'Change password',
              () => Navigator.pushNamed(context, CoreRoutes.forgotPassword),
            ),
            _navRow(
              Icons.switch_account_outlined,
              'Manage roles',
              () => Navigator.pushNamed(context, CoreRoutes.profileRoles),
            ),
            _navRow(
              Icons.logout_rounded,
              _loggingOut ? 'Signing out...' : 'Sign out',
              _loggingOut ? () {} : _logout,
            ),
            _navRow(
              Icons.verified_user_outlined,
              'Verification status',
              () => Navigator.pushNamed(context, CoreRoutes.verificationStatus),
            ),
          ]),
          _section('Notifications', [
            if (_loadingSettings)
              const LinearProgressIndicator(minHeight: 2)
            else if (_settingsError != null)
              InlineNotice(
                message: _settingsError!,
                icon: Icons.cloud_off_outlined,
                tone: CoreStatusTone.warning,
              ),
            _toggle(
              Icons.notifications_none_rounded,
              'In-app',
              _inApp,
              null,
              subtitle: 'Required for booking and security updates.',
            ),
            _toggle(
              Icons.phone_iphone_rounded,
              'Push',
              _push,
              _loadingSettings ||
                      _savingSettings ||
                      _capabilities['push'] != true ||
                      !browserPushSupported
                  ? null
                  : _savePush,
              subtitle: browserPushSupported && _capabilities['push'] == true
                  ? 'Notifications on this browser'
                  : 'Push is unavailable on this device.',
            ),
            _toggle(
              Icons.email_outlined,
              'Email',
              _email,
              _loadingSettings ||
                      _savingSettings ||
                      _capabilities['email'] != true
                  ? null
                  : (value) => _saveSettings(emailEnabled: value),
              subtitle: _capabilities['email'] == true
                  ? null
                  : 'Email delivery is not configured.',
            ),
            _toggle(
              Icons.sms_outlined,
              'SMS',
              _sms,
              null,
              subtitle: 'SMS delivery is not configured.',
            ),
            _toggle(
              Icons.chat_outlined,
              'WhatsApp consent',
              _whatsapp,
              null,
              subtitle: 'WhatsApp delivery is not configured yet.',
            ),
          ]),
          _languageSection(),
          _section('Privacy', [
            _toggle(
              Icons.phone_locked_outlined,
              'Hide phone number until secured booking',
              _hidePhone,
              null,
              subtitle: 'Enforced by CineConnect booking policy.',
            ),
            _toggle(
              Icons.location_off_outlined,
              'Hide exact location until secured stage',
              _hideLocation,
              null,
              subtitle: 'Enforced by CineConnect booking policy.',
            ),
            _toggle(
              Icons.water_drop_outlined,
              'Watermark public portfolio previews',
              _watermark,
              null,
              subtitle: 'Portfolio-level control is not available yet.',
            ),
            _navRow(
              Icons.travel_explore_outlined,
              'Manage profile visibility',
              () => Navigator.pushNamed(context, CoreRoutes.profileRoles),
              subtitle: 'Open your role profile to control its visibility.',
            ),
          ]),
          _paymentSection(),
          _section('Security', [
            _navRow(
              Icons.lock_reset_rounded,
              'Change password',
              () => Navigator.pushNamed(context, CoreRoutes.forgotPassword),
            ),
            _toggle(
              Icons.fingerprint_rounded,
              'Enable biometric login',
              _biometric,
              null,
              subtitle: 'Device biometric sign-in is not configured yet.',
            ),
            _toggle(
              Icons.password_rounded,
              'Two-factor authentication',
              _twoFactor,
              null,
              subtitle: 'Two-factor enrollment is not available yet.',
            ),
            _navRow(
              Icons.devices_other_outlined,
              'Active sessions',
              _activeSessions,
              subtitle: 'Review devices and revoke remote access.',
            ),
          ]),
          _section('Support', [
            _navRow(Icons.help_outline_rounded, 'Help center', _faqSheet),
            _navRow(
              Icons.support_agent_outlined,
              'Contact support',
              _contactSupport,
            ),
            _navRow(
              Icons.report_problem_outlined,
              'Report a problem',
              () => Navigator.pushNamed(context, CoreRoutes.report),
            ),
          ]),
          _section('Danger Zone', [
            _navRow(
              Icons.pause_circle_outline_rounded,
              'Request account deactivation',
              () => _requestAccountAction('deactivation'),
              subtitle: 'Creates a verified high-priority support request.',
            ),
            _navRow(
              Icons.delete_outline_rounded,
              'Request account deletion',
              () => _requestAccountAction('deletion'),
              subtitle: 'Creates a verified deletion and retention review.',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _languageSection() {
    return CoreGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(text: 'Language'),
          const SizedBox(height: 10),
          CoreDropdownField<String>(
            value: _language,
            values: const ['English'],
            label: 'Language',
            icon: Icons.translate_rounded,
            onChanged: (value) {
              if (_loadingSettings || _savingSettings) return;
              final locale = switch (value) {
                'Urdu' => 'ur-PK',
                'Roman Urdu' => 'ur-Latn-PK',
                _ => 'en-PK',
              };
              _saveSettings(locale: locale);
            },
          ),
        ],
      ),
    );
  }

  Widget _paymentSection() {
    final colors = context.appColors;
    return CoreGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(text: 'Payment Accounts'),
          const SizedBox(height: 10),
          const InlineNotice(
            message:
                'Account identifiers are encrypted and new accounts remain pending until verified.',
            icon: Icons.lock_outline_rounded,
            tone: CoreStatusTone.info,
          ),
          const SizedBox(height: 12),
          if (_payoutAccountsFuture == null)
            const Text('Sign in to manage payout accounts.')
          else
            FutureBuilder<List<PayoutAccountDto>>(
              future: _payoutAccountsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator(minHeight: 2);
                }
                if (snapshot.hasError) {
                  return const InlineNotice(
                    message: 'Payout accounts could not be loaded.',
                    icon: Icons.cloud_off_outlined,
                    tone: CoreStatusTone.warning,
                  );
                }
                final accounts = snapshot.data ?? const [];
                if (accounts.isEmpty) {
                  return Text(
                    'No payout account added.',
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: colors.textSecondary,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final account in accounts)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_outlined,
                              color: colors.goldDark,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${account.provider.toUpperCase()} · ${account.accountName} · ${account.accountMasked}',
                                style: AppTextStyles.label.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              account.status,
                              style: AppTextStyles.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 12),
          CoreSecondaryButton(
            icon: Icons.add_rounded,
            label: 'Add payout account',
            compact: true,
            onTap: _payoutAccountsFuture == null ? null : _addPayoutAccount,
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CoreGlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(text: title),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _toggle(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool>? onChanged, {
    String? subtitle,
  }) {
    return Builder(
      builder: (context) {
        final colors = context.appColors;
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: colors.goldMid,
          secondary: Icon(icon, color: colors.goldDark),
          value: value,
          onChanged: onChanged,
          title: Text(
            title,
            style: AppTextStyles.label.copyWith(color: colors.textPrimary),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
        );
      },
    );
  }

  Widget _navRow(
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return Builder(
      builder: (context) {
        final colors = context.appColors;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: colors.goldDark),
          title: Text(
            title,
            style: AppTextStyles.label.copyWith(color: colors.textPrimary),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
          trailing: Icon(Icons.chevron_right_rounded, color: colors.iconMuted),
          onTap: onTap,
        );
      },
    );
  }
}

class _ActiveSessionsDialog extends StatefulWidget {
  final AuthController auth;

  const _ActiveSessionsDialog({required this.auth});

  @override
  State<_ActiveSessionsDialog> createState() => _ActiveSessionsDialogState();
}

class _ActiveSessionsDialogState extends State<_ActiveSessionsDialog> {
  late Future<List<AuthDeviceSession>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = widget.auth.sessions();
  }

  void _refresh() => setState(() => _future = widget.auth.sessions());

  Future<void> _revoke(AuthDeviceSession session) async {
    setState(() => _busyId = session.id);
    try {
      await widget.auth.revokeSession(session.id);
      if (!mounted) return;
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _revokeOthers() async {
    setState(() => _busyId = 'others');
    try {
      final count = await widget.auth.revokeOtherSessions();
      if (!mounted) return;
      showCoreSnack(context, '$count other session(s) signed out');
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Active sessions'),
      content: SizedBox(
        width: 560,
        child: FutureBuilder<List<AuthDeviceSession>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return CoreEmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load sessions',
                message: 'Check your connection and retry.',
                actionLabel: 'Retry',
                onAction: _refresh,
              );
            }
            final sessions = snapshot.data ?? const [];
            if (sessions.isEmpty) {
              return const CoreEmptyState(
                icon: Icons.devices_other_outlined,
                title: 'No active sessions',
                message: 'Sign in again to create a new device session.',
              );
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 430),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      session.isCurrent
                          ? Icons.devices_rounded
                          : Icons.devices_other_outlined,
                      color: context.appColors.goldDark,
                    ),
                    title: Text(
                      session.isCurrent
                          ? '${session.deviceLabel} · This device'
                          : session.deviceLabel,
                    ),
                    subtitle: Text(
                      '${session.ipAddress} · ${_sessionDate(session.lastUsedAt ?? session.createdAt)}',
                    ),
                    trailing: session.isCurrent
                        ? Icon(Icons.verified_user_outlined,
                            color: context.appColors.success)
                        : TextButton(
                            onPressed:
                                _busyId == null ? () => _revoke(session) : null,
                            child: Text(
                              _busyId == session.id ? 'Revoking...' : 'Revoke',
                            ),
                          ),
                  );
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busyId == null ? _revokeOthers : null,
          child: Text(
            _busyId == 'others' ? 'Signing out...' : 'Sign out other devices',
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

String _sessionDate(DateTime? value) {
  if (value == null) return 'Activity time unknown';
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _PayoutAccountDraft {
  final String provider;
  final String accountName;
  final String accountIdentifier;

  const _PayoutAccountDraft({
    required this.provider,
    required this.accountName,
    required this.accountIdentifier,
  });
}

class _PayoutAccountDialog extends StatefulWidget {
  const _PayoutAccountDialog();

  @override
  State<_PayoutAccountDialog> createState() => _PayoutAccountDialogState();
}

class _PayoutAccountDialogState extends State<_PayoutAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accountName = TextEditingController();
  final _identifier = TextEditingController();
  String _provider = 'bank';

  @override
  void dispose() {
    _accountName.dispose();
    _identifier.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _PayoutAccountDraft(
        provider: _provider,
        accountName: _accountName.text.trim(),
        accountIdentifier: _identifier.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add payout account'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _provider,
                decoration: const InputDecoration(labelText: 'Account type'),
                items: const [
                  DropdownMenuItem(value: 'bank', child: Text('Bank account')),
                  DropdownMenuItem(
                      value: 'wallet', child: Text('Mobile wallet')),
                ],
                onChanged: (value) =>
                    setState(() => _provider = value ?? _provider),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountName,
                decoration: const InputDecoration(labelText: 'Account name'),
                validator: (value) => (value?.trim().length ?? 0) < 2
                    ? 'Enter the account holder name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _identifier,
                decoration: const InputDecoration(
                  labelText: 'IBAN, account number, or wallet number',
                ),
                obscureText: true,
                validator: (value) => (value?.trim().length ?? 0) < 4
                    ? 'Enter a valid account identifier'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Submit')),
      ],
    );
  }
}

class _SupportDialog extends StatefulWidget {
  final TrustSafetyController trustSafety;

  const _SupportDialog({required this.trustSafety});

  @override
  State<_SupportDialog> createState() => _SupportDialogState();
}

class _SupportDialogState extends State<_SupportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
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
        'category': 'general',
        'priority': 'normal',
        'subject': _subject.text.trim(),
        'message': _message.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not create the ticket. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contact support'),
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
                  labelText: 'How can we help?',
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? 'Enter a message' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: context.appColors.danger),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_submitting ? 'Submitting...' : 'Create ticket'),
        ),
      ],
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSheet({required this.title, required this.child});

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
              title,
              style: AppTextStyles.sectionTitle.copyWith(
                color: colors.textPrimary,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _FaqRow extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqRow({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: AppTextStyles.label.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
