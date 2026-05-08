import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/navigation/role_nav.dart';
import '../../../../core/utils/validators.dart';
import '../../../dashboard/providers/dashboard_providers.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLocalLoading = false;
  bool _useOtp = false;
  bool _otpSent = false;
  
  Timer? _otpTimer;
  int _otpCountdown = 0;

  @override
  void dispose() {
    _otpTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startOtpTimer() {
    setState(() {
      _otpCountdown = 30;
      _otpSent = true;
    });
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown > 0) {
        setState(() {
          _otpCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (_useOtp && _otpController.text.length < 6) {
      _showErrorSnackBar('Please enter valid 6-digit OTP');
      return;
    }
    if (_isLocalLoading) return;

    setState(() {
      _isLocalLoading = true;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      authNotifier.clearError();

      final success = _useOtp
          ? await authNotifier.verifyOtp(
              phone: _phoneController.text.trim(),
              otp: _otpController.text.trim(),
            )
          : await authNotifier.login(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

      if (!mounted) return;

      if (success) {
        invalidateAllDashboardProviders(ref);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final home = initialHomeRouteForUser(ref.read(authProvider).user);
        context.go(home); // Use go instead of push to clear login from stack
      } else {
        final error = ref.read(authProvider).error;
        _showErrorSnackBar(error ?? 'Invalid email or password');
      }
    } on Exception catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLocalLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorSnackBar('Please enter your email first to reset password');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to email')),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to send reset email: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCred.user != null) {
        _showSuccessAndNavigate('Google Sign-In successful');
      }
    } catch (e) {
      _showErrorSnackBar('Google Sign-In failed: $e');
    }
  }

  Future<void> _handleFacebookSignIn() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        final UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCred.user != null) {
          _showSuccessAndNavigate('Facebook Sign-In successful');
        }
      } else if (result.status != LoginStatus.cancelled) {
        _showErrorSnackBar('Facebook Sign-In failed: ${result.message}');
      }
    } catch (e) {
      _showErrorSnackBar('Facebook Sign-In failed: $e');
    }
  }

  void _showSuccessAndNavigate(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
    context.go('/dashboard');
  }

  Future<void> _handleSendOtp() async {
    FocusScope.of(context).unfocus();
    if (_isLocalLoading) return;
    if (_phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Phone number is required');
      return;
    }
    final phoneError = AppValidators.validatePhone(_phoneController.text.trim());
    if (phoneError != null) {
      _showErrorSnackBar(phoneError);
      return;
    }

    setState(() => _isLocalLoading = true);
    try {
      final ok = await ref
          .read(authProvider.notifier)
          .sendOtp(phone: _phoneController.text.trim());
      if (!mounted) return;
      if (ok) {
        _startOtpTimer();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('OTP sent'),
            backgroundColor: const Color(0xFF163F6B),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        FocusScope.of(context).requestFocus(_otpFocusNode);
      } else {
        final error = ref.read(authProvider).error;
        _showErrorSnackBar(error ?? 'Failed to send OTP');
      }
    } finally {
      if (mounted) setState(() => _isLocalLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = _isLocalLoading || authState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: AutofillGroup(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        height: 84,
                        width: 84,
                        decoration: BoxDecoration(
                          color: const Color(0xFF163F6B),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8A8A8A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 34),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE0E0E0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _ModeChip(
                                      label: 'Email',
                                      selected: !_useOtp,
                                      onTap: isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _useOtp = false;
                                                _otpSent = false;
                                                _otpController.clear();
                                                _otpTimer?.cancel();
                                                _otpCountdown = 0;
                                              });
                                            },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _ModeChip(
                                      label: 'Phone OTP',
                                      selected: _useOtp,
                                      onTap: isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _useOtp = true;
                                                _otpSent = false;
                                                _otpController.clear();
                                                _otpTimer?.cancel();
                                                _otpCountdown = 0;
                                              });
                                            },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (!_useOtp) ...[
                              _AuthInputField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                hint: 'Email',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                validator: AppValidators.validateEmail,
                                onFieldSubmitted: (_) {
                                  FocusScope.of(context).requestFocus(_passwordFocusNode);
                                },
                              ),
                              const SizedBox(height: 16),
                              _AuthInputField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                hint: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                validator: AppValidators.validatePassword,
                                onFieldSubmitted: (_) => _handleLogin(),
                                suffixIcon: IconButton(
                                  splashRadius: 20,
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: const Color(0xFF202020),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _handleForgotPassword,
                                  child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF163F6B), fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ] else ...[
                              _AuthInputField(
                                controller: _phoneController,
                                focusNode: _phoneFocusNode,
                                hint: 'Phone',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.telephoneNumber],
                                validator: (v) => _useOtp ? AppValidators.validatePhone(v) : null,
                                onFieldSubmitted: (_) => _handleSendOtp(),
                                suffixIcon: TextButton(
                                  onPressed: (_otpCountdown > 0 || isLoading) ? null : _handleSendOtp,
                                  child: Text(_otpCountdown > 0 ? 'Resend in ${_otpCountdown}s' : 'Send OTP'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_otpSent)
                                Pinput(
                                  length: 6,
                                  controller: _otpController,
                                  focusNode: _otpFocusNode,
                                  defaultPinTheme: PinTheme(
                                    width: 50,
                                    height: 56,
                                    textStyle: const TextStyle(fontSize: 20, color: Color(0xFF111111), fontWeight: FontWeight.w600),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFD5D5D5)),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                    ),
                                  ),
                                  focusedPinTheme: PinTheme(
                                    width: 50,
                                    height: 56,
                                    textStyle: const TextStyle(fontSize: 20, color: Color(0xFF111111), fontWeight: FontWeight.w600),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFF163F6B), width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                    ),
                                  ),
                                  onCompleted: (_) => _handleLogin(),
                                ),
                          ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF163F6B),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF163F6B).withValues(alpha: 0.7),
                          elevation: 4,
                          shadowColor: const Color(0xFF163F6B).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                              ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialCircleButton(
                          imagePath: 'assets/google.png',
                          fallbackText: 'G',
                          onTap: _handleGoogleSignIn,
                        ),
                        const SizedBox(width: 18),
                        _SocialCircleButton(
                          imagePath: 'assets/facebook.png',
                          fallbackText: 'f',
                          onTap: _handleFacebookSignIn,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(color: Color(0xFF6A6A6A), fontSize: 14)),
                        TextButton(
                          onPressed: isLoading ? null : () {
                            FocusScope.of(context).unfocus();
                            context.push('/signup'); // push instead of go
                          },
                          child: const Text('Create Account', style: TextStyle(color: Color(0xFF163F6B), fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SelectableText(
                      ApiEndpoints.baseUrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9A9A9A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Wrong URL? Change in Settings → API after sign in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Color(0xFFB0B0B0)),
                    ),
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

class _AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final List<String>? autofillHints;

  const _AuthInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: autofillHints,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      scrollPadding: const EdgeInsets.only(bottom: 120),
      inputFormatters: hint == 'Email' ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))] : null,
      style: const TextStyle(fontSize: 16, color: Color(0xFF111111), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 16, fontWeight: FontWeight.w400),
        prefixIcon: Container(margin: const EdgeInsets.only(right: 8), child: Icon(icon, color: const Color(0xFF202020), size: 24)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFD5D5D5), width: 1.2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF163F6B), width: 1.8)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      ),
    );
  }
}

class _SocialCircleButton extends StatelessWidget {
  final String imagePath;
  final String fallbackText;
  final VoidCallback onTap;

  const _SocialCircleButton({
    required this.imagePath,
    required this.fallbackText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD9D9D9)),
        ),
        child: Center(
          child: Text(
            fallbackText,
            style: TextStyle(
              fontSize: fallbackText == 'f' ? 24 : 18,
              fontWeight: FontWeight.w700,
              color: fallbackText == 'G' ? const Color(0xFFDB4437) : const Color(0xFF1877F2),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF163F6B) : const Color(0xFFF3F5F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF163F6B),
            ),
          ),
        ),
      ),
    );
  }
}
