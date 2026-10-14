import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../auth/role_mapper.dart';
import '../../profile/profile_models.dart';
import '../../network/api_exception.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../../../features/general_public/routes/general_public_routes.dart';
import '../core_routes.dart';
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
  bool _loading = false;
  String? _identityError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _identity.text = '';
    _password.text = '';
  }

  @override
  void dispose() {
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _identityError =
          _identity.text.trim().isEmpty ? 'Email is required' : null;
      _passwordError = _password.text.isEmpty ? 'Password is required' : null;
    });
    if (_identityError != null || _passwordError != null) return;

    setState(() => _loading = true);
    try {
      final auth = AuthScope.of(context);
      await auth.login(email: _identity.text.trim(), password: _password.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, auth.initialAuthenticatedRoute);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _passwordError = error.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return CoreScreenScaffold(
      showBackdrop: false,
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
            style: AppTextStyles.bodyMuted.copyWith(
              color: colors.textSecondary,
            ),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      CoreRoutes.forgotPassword,
                    ),
                    child: const Text('Forgot Password?'),
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
  bool _terms = false;
  bool _showPassword = false;
  bool _loading = false;
  String? _cityId;
  Future<List<ProfileCity>>? _citiesFuture;

  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _referral = TextEditingController();
  final Map<String, String?> _errors = {};

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _referral.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _citiesFuture ??= AuthScope.of(context).cities();
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
        ..['password'] = _password.text.length < 10
            ? 'Password must contain at least 10 characters'
            : null
        ..['confirm'] =
            _confirm.text != _password.text ? 'Passwords must match' : null
        ..['city'] = _cityId == null ? 'Select a city' : null
        ..['terms'] = _terms ? null : 'Accept terms to continue';
    });
    return _errors.values.every((error) => error == null);
  }

  Future<void> _createAccount() async {
    if (!_validateSignup()) return;
    setState(() => _loading = true);
    try {
      await AuthScope.of(context).register(
        email: _email.text.trim(),
        password: _password.text,
        displayName: _fullName.text.trim(),
        initialRole: RoleMapper.codeForLabel(widget.selectedRole),
        phone: _phone.text.trim().startsWith('0')
            ? '+92${_phone.text.trim().substring(1)}'
            : _phone.text.trim(),
        cityId: _cityId,
        referralCode: _referral.text.trim(),
      );
      if (!mounted) return;
      showCoreSnack(context,
          'Account created. Your phone is saved but is not SMS verified.');
      Navigator.pushReplacementNamed(
        context,
        widget.selectedRole == 'General Public'
            ? GeneralPublicRoutes.home
            : CoreRoutes.kyc,
        arguments: widget.selectedRole,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errors['email'] = error.fields['email']?.first;
        _errors['password'] = error.fields['password']?.first;
        _errors['fullName'] = error.fields['display_name']?.first;
        _errors['phone'] = error.fields['phone']?.first;
        _errors['city'] = error.fields['city_id']?.first;
        _errors['form'] = error.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      showBackdrop: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoreAppHeader(
            title: 'Create Account',
            subtitle:
                'Create your account, then submit identity documents for review.',
            icon: Icons.person_add_alt_1_outlined,
          ),
          const SizedBox(height: 20),
          const InlineNotice(
              message:
                  'SMS verification is not configured. Phone numbers remain unverified.'),
          const SizedBox(height: 20),
          _signupForm(context),
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
          if (_errors['form'] != null) ...[
            const SizedBox(height: 12),
            InlineNotice(
              message: _errors['form']!,
              icon: Icons.info_outline_rounded,
              tone: CoreStatusTone.warning,
            ),
          ],
          const SizedBox(height: 18),
          CoreTextField(
            controller: _fullName,
            label: 'Full name',
            icon: Icons.person_outline,
            errorText: _errors['fullName'],
          ),
          const SizedBox(height: 14),
          CoreTextField(
            controller: _phone,
            label: 'Phone number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            errorText: _errors['phone'],
          ),
          const SizedBox(height: 14),
          CoreTextField(
            controller: _email,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            errorText: _errors['email'],
          ),
          const SizedBox(height: 14),
          CoreTextField(
            controller: _password,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: !_showPassword,
            errorText: _errors['password'],
            suffix: IconButton(
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          const SizedBox(height: 14),
          CoreTextField(
            controller: _confirm,
            label: 'Confirm password',
            icon: Icons.lock_reset_rounded,
            obscureText: !_showPassword,
            errorText: _errors['confirm'],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<ProfileCity>>(
            future: _citiesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(children: [
                  const InlineNotice(
                      message: 'Could not load cities. Please retry.'),
                  TextButton(
                      onPressed: () => setState(
                          () => _citiesFuture = AuthScope.of(context).cities()),
                      child: const Text('Retry')),
                ]);
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final cities = snapshot.data!;
              if (cities.isEmpty) {
                return const InlineNotice(
                    message:
                        'No active cities are configured. Contact support.');
              }
              return Column(children: [
                CoreDropdownField<String?>(
                  value: _cityId,
                  values: cities.map<String?>((city) => city.publicId).toList(),
                  labelBuilder: (id) =>
                      cities.firstWhere((city) => city.publicId == id).name,
                  label: 'City',
                  icon: Icons.location_on_outlined,
                  onChanged: (value) => setState(() => _cityId = value),
                ),
                if (_errors['city'] != null) Text(_errors['city']!),
              ]);
            },
          ),
          const SizedBox(height: 14),
          CoreTextField(
            controller: _referral,
            label: 'Referral code optional',
            icon: Icons.confirmation_number_outlined,
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _terms,
            activeColor: colors.goldMid,
            onChanged: (value) => setState(() => _terms = value ?? false),
            title: Text(
              'I agree to CineConnect terms, privacy and verification rules',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
            subtitle: _errors['terms'] == null
                ? null
                : Text(
                    _errors['terms']!,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.infoPurple,
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          CorePrimaryButton(
            icon: Icons.mark_email_read_outlined,
            label: 'Create Account',
            loading: _loading,
            onTap: _loading ? null : _createAccount,
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  final String? resetToken;
  const ForgotPasswordScreen({super.key, this.resetToken});

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
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final token = widget.resetToken;
    if (token != null && token.isNotEmpty) {
      _otp.text = token;
      _step = 2;
    }
  }

  @override
  void dispose() {
    _identity.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    setState(() => _error = null);
    if (_step == 0 && _identity.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email');
      return;
    }
    if (_step == 0) {
      setState(() => _loading = true);
      try {
        await AuthScope.of(context).forgotPassword(_identity.text.trim());
      } on ApiException catch (error) {
        if (!mounted) return;
        setState(() => _error = error.message);
        return;
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      if (!mounted) return;
    }
    if (_step == 1 && _otp.text.trim().length < 16) {
      setState(() => _error =
          'Use the secure token from your reset email, not a six-digit OTP.');
      return;
    }
    if (_step == 2) {
      if (_password.text.length < 10 || _password.text != _confirm.text) {
        setState(() =>
            _error = 'Passwords must match and contain at least 10 characters');
        return;
      }
      setState(() => _loading = true);
      try {
        await AuthScope.of(context)
            .resetPassword(token: _otp.text.trim(), password: _password.text);
      } on ApiException catch (error) {
        if (mounted) setState(() => _error = error.message);
        return;
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      if (!mounted) return;
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
      showBackdrop: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoreAppHeader(
            title: 'Reset Password',
            subtitle:
                'Request a secure reset link, then choose a new password.',
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
                    label: 'Email',
                    icon: Icons.alternate_email_rounded,
                    errorText: _error,
                    keyboardType: TextInputType.emailAddress,
                  )
                else if (_step == 1)
                  CoreTextField(
                      controller: _otp,
                      label: 'Secure token from your reset email',
                      icon: Icons.key_outlined,
                      errorText: _error)
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
                      ? 'Send Reset Email'
                      : _step == 1
                          ? 'Continue with reset token'
                          : _step == 2
                              ? 'Update Password'
                              : 'Back to Login',
                  loading: _loading,
                  onTap: _step == 3
                      ? () => Navigator.pushNamed(context, CoreRoutes.login)
                      : _loading
                          ? null
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
