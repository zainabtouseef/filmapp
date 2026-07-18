import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../core_ui/core_routes.dart';
import '../../core_ui/widgets/core_widgets.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';

class SettingsAccountScreen extends StatefulWidget {
  const SettingsAccountScreen({super.key});

  @override
  State<SettingsAccountScreen> createState() => _SettingsAccountScreenState();
}

class _SettingsAccountScreenState extends State<SettingsAccountScreen> {
  bool _inApp = true;
  bool _push = true;
  bool _email = true;
  bool _sms = false;
  bool _whatsapp = false;
  bool _hidePhone = true;
  bool _hideLocation = true;
  bool _watermark = true;
  bool _discovery = true;
  bool _biometric = false;
  bool _twoFactor = false;
  bool _loggingOut = false;
  String _language = 'English';

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

  void _otpPaymentModal() {
    final otp = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _SettingsSheet(
          title: 'Confirm Payment Account Change',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const InlineNotice(
                message:
                    'Payment account changes require OTP confirmation and may be reviewed by admin.',
                icon: Icons.admin_panel_settings_outlined,
                tone: CoreStatusTone.warning,
              ),
              const SizedBox(height: 14),
              OtpInputRow(controller: otp),
              const SizedBox(height: 16),
              CorePrimaryButton(
                icon: Icons.verified_user_outlined,
                label: 'Confirm Change',
                onTap: () {
                  Navigator.pop(context);
                  showCoreSnack(
                    context,
                    'Payment account change sent for high-value review',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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

  void _confirmDanger(String title, {required bool irreversible}) {
    final colors = context.appColors;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              irreversible
                  ? Icons.warning_amber_rounded
                  : Icons.pause_circle_outline_rounded,
              color: irreversible ? colors.danger : colors.goldDark,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: colors.textPrimary,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          irreversible
              ? 'This permanently deletes your account and cannot be undone.'
              : 'You can reactivate your account any time by logging back in.',
          style: AppTextStyles.bodyMuted.copyWith(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showCoreSnack(context, '$title requested');
            },
            style: irreversible
                ? TextButton.styleFrom(foregroundColor: colors.danger)
                : null,
            child: Text(irreversible ? 'Delete' : 'Confirm'),
          ),
        ],
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
              () => showCoreSnack(context, 'Edit profile simulated'),
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
            _toggle(
              Icons.notifications_none_rounded,
              'In-app',
              _inApp,
              (v) => setState(() => _inApp = v),
            ),
            _toggle(
              Icons.phone_iphone_rounded,
              'Push',
              _push,
              (v) => setState(() => _push = v),
            ),
            _toggle(
              Icons.email_outlined,
              'Email',
              _email,
              (v) => setState(() => _email = v),
            ),
            _toggle(
              Icons.sms_outlined,
              'SMS',
              _sms,
              (v) => setState(() => _sms = v),
            ),
            _toggle(
              Icons.chat_outlined,
              'WhatsApp consent',
              _whatsapp,
              (v) => setState(() => _whatsapp = v),
            ),
          ]),
          _languageSection(),
          _section('Privacy', [
            _toggle(
              Icons.phone_locked_outlined,
              'Hide phone number until secured booking',
              _hidePhone,
              (v) => setState(() => _hidePhone = v),
            ),
            _toggle(
              Icons.location_off_outlined,
              'Hide exact location until secured stage',
              _hideLocation,
              (v) => setState(() => _hideLocation = v),
            ),
            _toggle(
              Icons.water_drop_outlined,
              'Watermark public portfolio previews',
              _watermark,
              (v) => setState(() => _watermark = v),
            ),
            _toggle(
              Icons.travel_explore_outlined,
              'Allow profile discovery',
              _discovery,
              (v) => setState(() => _discovery = v),
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
              (v) => setState(() => _biometric = v),
            ),
            _toggle(
              Icons.password_rounded,
              'Two-factor authentication',
              _twoFactor,
              (v) => setState(() => _twoFactor = v),
            ),
            _navRow(
              Icons.devices_other_outlined,
              'Active sessions',
              () => showCoreSnack(context, 'Active sessions simulated'),
            ),
          ]),
          _section('Support', [
            _navRow(Icons.help_outline_rounded, 'Help center', _faqSheet),
            _navRow(
              Icons.support_agent_outlined,
              'Contact support',
              () => showCoreSnack(context, 'Contact support simulated'),
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
              'Deactivate account',
              () => _confirmDanger('Deactivate account', irreversible: false),
            ),
            _navRow(
              Icons.delete_outline_rounded,
              'Delete account',
              () => _confirmDanger('Delete account', irreversible: true),
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
            values: const ['English', 'Urdu', 'Roman Urdu'],
            label: 'Language',
            icon: Icons.translate_rounded,
            onChanged: (value) =>
                setState(() => _language = value ?? _language),
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
                'Payment account changes require OTP confirmation and may be reviewed by admin.',
            icon: Icons.admin_panel_settings_outlined,
            tone: CoreStatusTone.warning,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_outlined, color: colors.goldDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'HBL · Sara Ahmed Productions · **** 4821',
                    style: AppTextStyles.label.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.add_rounded,
                  label: 'Add account',
                  compact: true,
                  onTap: _otpPaymentModal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.edit_outlined,
                  label: 'Change account',
                  compact: true,
                  onTap: _otpPaymentModal,
                ),
              ),
            ],
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
    ValueChanged<bool> onChanged,
  ) {
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
        );
      },
    );
  }

  Widget _navRow(IconData icon, String title, VoidCallback onTap) {
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
          trailing: Icon(Icons.chevron_right_rounded, color: colors.iconMuted),
          onTap: onTap,
        );
      },
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
