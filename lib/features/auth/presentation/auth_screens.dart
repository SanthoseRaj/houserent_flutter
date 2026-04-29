import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../core/models/app_models.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    final session = await ref.read(authControllerProvider.future);
    final onboardingSeen = await ref
        .read(sessionStorageProvider)
        .isOnboardingSeen();
    if (!mounted) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }

    if (session != null) {
      context.go(session.user.role == UserRole.admin ? '/admin' : '/user');
      return;
    }

    context.go(onboardingSeen ? '/login' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                size: 48,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'HouseRent Pro',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Rental operations, applications, payments and tenant care.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _items = const [
    (
      title: 'Browse polished rental listings',
      subtitle:
          'Explore homes and shops with filters, premium cards, and rich property details.',
      icon: Icons.travel_explore_rounded,
    ),
    (
      title: 'Apply with verified documents',
      subtitle:
          'Submit tenant details, upload proofs, and track approvals in one place.',
      icon: Icons.fact_check_rounded,
    ),
    (
      title: 'Run rent collection end to end',
      subtitle:
          'Manage dues, receipts, complaints, chats, and admin operations from the same app.',
      icon: Icons.payments_rounded,
    ),
  ];

  Future<void> _finish() async {
    await SessionStorage().markOnboardingSeen();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.sky, AppColors.peach],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(42),
                          ),
                          child: Icon(
                            item.icon,
                            size: 96,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(item.subtitle, textAlign: TextAlign.center),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _index == index ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _index == index ? AppColors.navy : AppColors.sky,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: _index == _items.length - 1 ? 'Start Now' : 'Next',
                onPressed: () {
                  if (_index == _items.length - 1) {
                    _finish();
                    return;
                  }
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAdmin = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final session = await ref
          .read(authControllerProvider.notifier)
          .login(
            phone: _phoneController.text,
            password: _passwordController.text,
            isAdmin: _isAdmin,
          );
      if (!mounted) {
        return;
      }
      context.go(session.user.role == UserRole.admin ? '/admin' : '/user');
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      title: 'Welcome back',
      subtitle: 'Use phone number and password to enter your rental workspace.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _RoleToggle(
              isAdmin: _isAdmin,
              onChanged: (value) => setState(() => _isAdmin = value),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _phoneController,
              validator: phoneValidator,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              validator: passwordValidator,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: _isAdmin ? 'Login as Admin' : 'Login as User',
              onPressed: _submit,
              icon: _isAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.login_rounded,
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: 18),
            if (!_isAdmin)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('New here? '),
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: const Text('Create account'),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.sky,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Demo credentials',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Admin: 9999999999 / Admin@123'),
                  const Text('User: 9876543210 / User@123'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _occupationController = TextEditingController();
  final _aadhaarController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _occupationController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final session = await ref.read(authRepositoryProvider).signUp({
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'occupation': _occupationController.text.trim(),
        'aadhaarNumber': _aadhaarController.text.trim(),
      });
      await ref.read(authControllerProvider.notifier).completeSession(session);
      if (!mounted) {
        return;
      }
      context.go(session.user.role == UserRole.admin ? '/admin' : '/user');
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      title: 'Create your tenant profile',
      subtitle:
          'Create an account instantly and continue without OTP verification.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _fullNameController,
              validator: (value) =>
                  requiredValidator(value, label: 'Full name'),
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              validator: emailValidator,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              validator: phoneValidator,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _occupationController,
              validator: (value) =>
                  requiredValidator(value, label: 'Occupation'),
              decoration: const InputDecoration(labelText: 'Occupation'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _aadhaarController,
              validator: aadhaarValidator,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Aadhaar number'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              validator: passwordValidator,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Create password'),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Create account',
              onPressed: _submit,
              icon: Icons.person_add_alt_1_rounded,
              isLoading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isAdmin = false;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .forgotPassword(
            email: _emailController.text.trim(),
            accountType: _isAdmin ? 'admin' : 'user',
          );
      if (!mounted) {
        return;
      }
      context.go(
        '/reset-password',
        extra: ResetPasswordPayload(
          email: result.email,
          accountType: result.accountType,
          devOtp: result.devOtp,
        ),
      );
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      title: 'Reset your password',
      subtitle: 'We will send a short OTP to confirm the request.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _RoleToggle(
              isAdmin: _isAdmin,
              onChanged: (value) => setState(() => _isAdmin = value),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _emailController,
              validator: emailValidator,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address'),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Send reset OTP',
              onPressed: _submit,
              icon: Icons.sms_rounded,
              isLoading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, this.payload});

  final OtpRoutePayload? payload;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  bool _submitting = false;
  String? _devOtp;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.payload?.email ?? '');
    _devOtp = widget.payload?.devOtp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .verifyOtp(
            email: _emailController.text.trim(),
            otp: _otpController.text.trim(),
            accountType: widget.payload?.accountType ?? 'user',
          );
      await ref.read(authControllerProvider.notifier).completeSession(session);
      if (!mounted) {
        return;
      }
      context.go('/user');
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .resendOtp(
            email: _emailController.text.trim(),
            accountType: widget.payload?.accountType ?? 'user',
            purpose: 'signup',
          );
      setState(() => _devOtp = result.devOtp);
      if (mounted) {
        showAppSnackBar(context, 'OTP resent successfully');
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      title: 'Verify your email',
      subtitle: 'Enter the six-digit OTP to activate your account.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_devOtp != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.peach,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text('Local demo OTP: $_devOtp'),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _emailController,
              validator: emailValidator,
              decoration: const InputDecoration(labelText: 'Email address'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _otpController,
              validator: (value) => requiredValidator(value, label: 'OTP'),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '6-digit OTP'),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Verify and continue',
              onPressed: _submit,
              icon: Icons.verified_rounded,
              isLoading: _submitting,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _resendOtp, child: const Text('Resend OTP')),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.payload});

  final ResetPasswordPayload? payload;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.payload?.email ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            email: _emailController.text.trim(),
            otp: _otpController.text.trim(),
            newPassword: _passwordController.text,
            accountType: widget.payload?.accountType ?? 'user',
          );
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Password reset successful');
      context.go('/login');
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      title: 'Choose a new password',
      subtitle: 'Use the OTP you received to safely set a new password.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (widget.payload?.devOtp != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.peach,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text('Local demo OTP: ${widget.payload?.devOtp}'),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _emailController,
              validator: emailValidator,
              decoration: const InputDecoration(labelText: 'Email address'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _otpController,
              validator: (value) => requiredValidator(value, label: 'OTP'),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              validator: passwordValidator,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Reset password',
              onPressed: _submit,
              icon: Icons.lock_reset_rounded,
              isLoading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthFrame extends StatelessWidget {
  const _AuthFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FBFD), Color(0xFFFFF7EE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(subtitle),
                    const SizedBox(height: 24),
                    AppSectionCard(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [AppColors.navy, AppColors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.apartment_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HouseRent Pro',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('Property operations that feel premium'),
          ],
        ),
      ],
    );
  }
}

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.isAdmin, required this.onChanged});

  final bool isAdmin;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.sky,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onChanged(false),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !isAdmin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('User / Tenant')),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => onChanged(true),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isAdmin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('Admin')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
