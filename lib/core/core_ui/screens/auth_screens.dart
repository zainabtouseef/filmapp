import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../../../features/actor_talent/routes/actor_talent_routes.dart';
import '../../../features/brand_sponsors/routes/brand_sponsor_routes.dart';
import '../../../features/casting_agency/routes/casting_agency_routes.dart';
import '../../../features/crew_services/routes/crew_services_routes.dart';
import '../../../features/director_producer/routes/director_producer_routes.dart';
import '../../../features/distribution_partner/routes/distribution_partner_routes.dart';
import '../../../features/insurance_partner/routes/insurance_partner_routes.dart';
import '../../../features/legal_partner/routes/legal_partner_routes.dart';
import '../../../features/location_owner/routes/location_owner_routes.dart';
import '../../../features/media_equipment/routes/media_equipment_routes.dart';
import '../../../features/model_extension/routes/model_extension_routes.dart';
import '../../../features/super_admin/routes/super_admin_routes.dart';
import '../core_routes.dart';
import '../mock_data/shared_mock_data.dart';
import '../widgets/core_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identity = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _biometric = false;
  bool _loading = false;
  String _demoLoginAs = 'Director / Producer';
  String? _identityError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _identity.text = 'producer@cineconnect.demo';
    _password.text = 'demo123';
  }

  @override
  void dispose() {
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final fakeUserType =
        _demoLoginAs == 'User' || _portalRouteFor(_demoLoginAs) != null
            ? 'user'
            : 'super_admin';
    final fakeAdminPermission = _demoPermissionFor(_demoLoginAs);

    if (fakeUserType == 'super_admin') {
      setState(() => _loading = true);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      Navigator.pushNamed(context, _adminRouteFor(fakeAdminPermission));
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _identityError =
          _identity.text.trim().isEmpty ? 'Phone or email is required' : null;
      _passwordError = _password.text.isEmpty ? 'Password is required' : null;
    });
    if (_identityError != null || _passwordError != null) return;

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    const fakeAccountStatus = 'verified';
    if (fakeAccountStatus == 'verification_pending') {
      Navigator.pushNamed(context, CoreRoutes.verificationStatus);
    } else if (_portalRouteFor(_demoLoginAs) != null) {
      Navigator.pushNamed(context, _portalRouteFor(_demoLoginAs)!);
    } else {
      Navigator.pushNamed(context, CoreRoutes.dashboard);
    }
  }

  String _demoPermissionFor(String label) {
    return switch (label) {
      'Super Admin' => 'super_admin',
      'Payments Officer' => 'payments_officer',
      'Verification Agent' => 'verification_agent',
      'Dispute Officer' => 'dispute_officer',
      'Content Moderator' => 'content_moderator',
      _ => 'user',
    };
  }

  String _adminRouteFor(String permission) {
    return switch (permission) {
      'super_admin' => SuperAdminRoutes.dashboard,
      'verification_agent' => SuperAdminRoutes.verifications,
      'payments_officer' => SuperAdminRoutes.paymentQueue,
      'dispute_officer' => SuperAdminRoutes.disputes,
      'content_moderator' => SuperAdminRoutes.contentModeration,
      _ => CoreRoutes.dashboard,
    };
  }

  String? _portalRouteFor(String label) {
    return switch (label) {
      'Director / Producer' => DirectorProducerRoutes.home,
      'Actor / Talent' => ActorTalentRoutes.dashboard,
      'Model' => ModelExtensionRoutes.categories,
      'Location Owner' => LocationOwnerRoutes.home,
      'Media / Equipment Provider' => MediaEquipmentRoutes.home,
      'Crew / Services' => CrewServicesRoutes.home,
      'Casting Agency' => CastingAgencyRoutes.home,
      'Brand / Sponsor' => BrandSponsorRoutes.home,
      'Legal Partner' => LegalPartnerRoutes.home,
      'Insurance / Safety Partner' => InsurancePartnerRoutes.home,
      'Distribution / Release Partner' => DistributionPartnerRoutes.home,
      _ => null,
    };
  }

  static const _demoRoles = [
    'User',
    'Director / Producer',
    'Actor / Talent',
    'Model',
    'Location Owner',
    'Media / Equipment Provider',
    'Crew / Services',
    'Casting Agency',
    'Brand / Sponsor',
    'Legal Partner',
    'Insurance / Safety Partner',
    'Distribution / Release Partner',
    'Super Admin',
    'Payments Officer',
    'Verification Agent',
    'Dispute Officer',
    'Content Moderator',
  ];

  void _showDemoRolePicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CoreBottomSheet(
        title: 'Demo Login As',
        subtitle: 'Pick a role to preview its portal.',
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.55,
          ),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _demoRoles
                  .map(
                    (role) => CoreChip(
                      label: role,
                      selected: _demoLoginAs == role,
                      onTap: () {
                        setState(() => _demoLoginAs = role);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showOtpSheet() {
    final otp = TextEditingController();
    final rootContext = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CoreBottomSheet(
        title: 'Login with OTP',
        subtitle: 'Enter any 6 digits to continue to your portal.',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OtpInputRow(controller: otp),
            const SizedBox(height: 16),
            CorePrimaryButton(
              icon: Icons.login_rounded,
              label: 'Verify & Login',
              onTap: () {
                if (otp.text.trim().length == 6) {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    rootContext,
                    _portalRouteFor(_demoLoginAs) ?? CoreRoutes.dashboard,
                  );
                } else {
                  showCoreSnack(context, 'Enter a 6-digit OTP');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoreBrandMark(),
          const SizedBox(height: 22),
          Text(
            'Welcome Back',
            style: AppTextStyles.sectionTitle.copyWith(
              color: colors.textPrimary,
              fontSize: 21,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Continue managing your production universe.',
            style:
                AppTextStyles.bodyMuted.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 24),
          CoreGlassCard(
            child: Column(
              children: [
                CoreTextField(
                  controller: _identity,
                  label: 'Phone or email',
                  icon: Icons.alternate_email_rounded,
                  errorText: _identityError,
                ),
                const SizedBox(height: 14),
                CoreTextField(
                  controller: _password,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: !_showPassword,
                  errorText: _passwordError,
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colors.iconMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _showOtpSheet,
                        child: const Text('Login with OTP instead'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                          context, CoreRoutes.forgotPassword),
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _biometric,
                  activeThumbColor: colors.goldMid,
                  onChanged: (value) => setState(() => _biometric = value),
                  title: Text(
                    'Biometric login',
                    style:
                        AppTextStyles.label.copyWith(color: colors.textPrimary),
                  ),
                  subtitle: Text(
                    'Enable after first login',
                    style: AppTextStyles.caption
                        .copyWith(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _showDemoRolePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                      color: colors.surface.withValues(alpha: 0.4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.badge_outlined,
                            size: 18, color: colors.goldDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Demo login as',
                                style: AppTextStyles.caption
                                    .copyWith(color: colors.textSecondary),
                              ),
                              Text(
                                _demoLoginAs,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.label
                                    .copyWith(color: colors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.expand_more_rounded,
                            color: colors.iconMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                CorePrimaryButton(
                  icon: Icons.login_rounded,
                  label: 'Login',
                  loading: _loading,
                  onTap: _loading ? null : _login,
                ),
                const SizedBox(height: 12),
                CoreSecondaryButton(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Create an account',
                  onTap: () =>
                      Navigator.pushNamed(context, CoreRoutes.roleSelection),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SignUpFlowScreen extends StatefulWidget {
  final String selectedRole;

  const SignUpFlowScreen({super.key, required this.selectedRole});

  @override
  State<SignUpFlowScreen> createState() => _SignUpFlowScreenState();
}

class _SignUpFlowScreenState extends State<SignUpFlowScreen> {
  int _step = 0;
  bool _terms = false;
  bool _showPassword = false;
  String _city = SharedMockData.cities.first;

  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _referral = TextEditingController();
  final _otp = TextEditingController();
  final Map<String, String?> _errors = {};
  int _resendSeconds = 30;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _referral.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  bool _validateSignup() {
    setState(() {
      _errors
        ..clear()
        ..['fullName'] =
            _fullName.text.trim().isEmpty ? 'Full name is required' : null
        ..['phone'] =
            _phone.text.trim().isEmpty ? 'Phone number is required' : null
        ..['email'] = _email.text.trim().isEmpty ? 'Email is required' : null
        ..['password'] = _password.text.isEmpty ? 'Password is required' : null
        ..['confirm'] =
            _confirm.text != _password.text ? 'Passwords must match' : null
        ..['terms'] = _terms ? null : 'Accept terms to continue';
    });
    return _errors.values.every((error) => error == null);
  }

  void _createAccount() {
    if (!_validateSignup()) return;
    _startTimer();
    setState(() => _step = 1);
  }

  void _verifyOtp() {
    if (_otp.text.trim().length != 6) {
      setState(() => _errors['otp'] = 'Enter any 6-digit OTP');
      return;
    }
    Navigator.pushNamed(
      context,
      CoreRoutes.kyc,
      arguments: widget.selectedRole,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoreAppHeader(
            title: _step == 0 ? 'Create Account' : 'Verify Your Phone',
            subtitle: _step == 0
                ? 'Build your verified CineConnect profile.'
                : 'Enter the 6-digit code sent to your number.',
            icon: _step == 0
                ? Icons.person_add_alt_1_outlined
                : Icons.sms_outlined,
          ),
          const SizedBox(height: 20),
          StepWizardIndicator(currentStep: _step, totalSteps: 2),
          const SizedBox(height: 20),
          if (_step == 0) _signupForm(context) else _otpForm(context),
        ],
      ),
    );
  }

  Widget _signupForm(BuildContext context) {
    final colors = context.appColors;
    return CoreGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(
            label: 'Signing up as: ${widget.selectedRole}',
            icon: Icons.verified_outlined,
            tone: CoreStatusTone.warning,
          ),
          const SizedBox(height: 18),
          CoreTextField(
              controller: _fullName,
              label: 'Full name',
              icon: Icons.person_outline,
              errorText: _errors['fullName']),
          const SizedBox(height: 14),
          CoreTextField(
              controller: _phone,
              label: 'Phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              errorText: _errors['phone']),
          const SizedBox(height: 14),
          CoreTextField(
              controller: _email,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              errorText: _errors['email']),
          const SizedBox(height: 14),
          CoreTextField(
            controller: _password,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: !_showPassword,
            errorText: _errors['password'],
            suffix: IconButton(
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(_showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
            ),
          ),
          const SizedBox(height: 14),
          CoreTextField(
              controller: _confirm,
              label: 'Confirm password',
              icon: Icons.lock_reset_rounded,
              obscureText: !_showPassword,
              errorText: _errors['confirm']),
          const SizedBox(height: 14),
          CoreDropdownField<String>(
            value: _city,
            values: SharedMockData.cities,
            label: 'City',
            icon: Icons.location_on_outlined,
            onChanged: (value) => setState(() => _city = value ?? _city),
          ),
          const SizedBox(height: 14),
          CoreTextField(
              controller: _referral,
              label: 'Referral code optional',
              icon: Icons.confirmation_number_outlined),
          const SizedBox(height: 10),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _terms,
            activeColor: colors.goldMid,
            onChanged: (value) => setState(() => _terms = value ?? false),
            title: Text(
              'I agree to CineConnect terms, privacy and verification rules',
              style:
                  AppTextStyles.caption.copyWith(color: colors.textSecondary),
            ),
            subtitle: _errors['terms'] == null
                ? null
                : Text(
                    _errors['terms']!,
                    style: AppTextStyles.caption
                        .copyWith(color: colors.infoPurple),
                  ),
          ),
          const SizedBox(height: 18),
          CorePrimaryButton(
            icon: Icons.mark_email_read_outlined,
            label: 'Create Account',
            onTap: _createAccount,
          ),
        ],
      ),
    );
  }

  Widget _otpForm(BuildContext context) {
    final colors = context.appColors;
    return CoreGlassCard(
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.goldMid.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.sms_outlined, color: colors.goldMid, size: 34),
          ),
          const SizedBox(height: 18),
          OtpInputRow(controller: _otp, errorText: _errors['otp']),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _resendSeconds == 0
                      ? 'You can resend the code now'
                      : 'Resend available in $_resendSeconds seconds',
                  style: AppTextStyles.caption
                      .copyWith(color: colors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: _resendSeconds == 0 ? _startTimer : null,
                child: const Text('Resend'),
              ),
            ],
          ),
          TextButton(
            onPressed: () => setState(() => _step = 0),
            child: const Text('Change phone number'),
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.verified_outlined,
            label: 'Verify',
            onTap: _verifyOtp,
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  final _identity = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _identity.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _next() {
    setState(() => _error = null);
    if (_step == 0 && _identity.text.trim().isEmpty) {
      setState(() => _error = 'Enter your phone or email');
      return;
    }
    if (_step == 1 && _otp.text.trim().length != 6) {
      setState(() => _error = 'Enter any 6-digit OTP');
      return;
    }
    if (_step == 2) {
      if (_password.text.isEmpty || _password.text != _confirm.text) {
        setState(() => _error = 'New passwords must match');
        return;
      }
      setState(() => _step = 3);
      showCoreSuccessDialog(
        context,
        title: 'Password updated successfully',
        message: 'You can now sign in with your new password.',
        buttonLabel: 'Back to Login',
        onDone: () => Navigator.pushNamed(context, CoreRoutes.login),
      );
      return;
    }
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoreAppHeader(
            title: 'Reset Password',
            subtitle: 'Use OTP confirmation to create a new password.',
            icon: Icons.lock_reset_rounded,
          ),
          const SizedBox(height: 20),
          StepWizardIndicator(currentStep: _step.clamp(0, 3), totalSteps: 4),
          const SizedBox(height: 20),
          CoreGlassCard(
            child: Column(
              children: [
                if (_step == 0)
                  CoreTextField(
                    controller: _identity,
                    label: 'Phone or email',
                    icon: Icons.alternate_email_rounded,
                    errorText: _error,
                  )
                else if (_step == 1)
                  OtpInputRow(controller: _otp, errorText: _error)
                else if (_step == 2) ...[
                  CoreTextField(
                    controller: _password,
                    label: 'New password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                    errorText: _error,
                  ),
                  const SizedBox(height: 14),
                  CoreTextField(
                    controller: _confirm,
                    label: 'Confirm new password',
                    icon: Icons.lock_reset_rounded,
                    obscureText: true,
                  ),
                ] else
                  const CoreEmptyState(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Password Reset Complete',
                    message: 'Your account security has been updated.',
                  ),
                const SizedBox(height: 20),
                CorePrimaryButton(
                  icon: _step == 3
                      ? Icons.login_rounded
                      : Icons.arrow_forward_rounded,
                  label: _step == 0
                      ? 'Send OTP'
                      : _step == 1
                          ? 'Verify OTP'
                          : _step == 2
                              ? 'Update Password'
                              : 'Back to Login',
                  onTap: _step == 3
                      ? () => Navigator.pushNamed(context, CoreRoutes.login)
                      : _next,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoreBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _CoreBottomSheet({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
        decoration: BoxDecoration(
          gradient: colors.cardGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.sectionTitle
                      .copyWith(color: colors.textPrimary)),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: AppTextStyles.bodyMuted
                      .copyWith(color: colors.textSecondary)),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
