import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLocalLoading = false;

  Future<void> _handleSignup() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (_isLocalLoading) return;

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      _showErrorSnackBar('Password and confirm password do not match');
      return;
    }

    setState(() => _isLocalLoading = true);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      authNotifier.clearError();

      print('🔵 SignupScreen: Attempting registration...');

      final success = await authNotifier.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      print('🔵 SignupScreen: Registration result: $success');

      if (success) {
        authNotifier.logout();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Account created successfully. Please sign in.',
            ),
            backgroundColor: const Color(0xFF163F6B),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.push('/login');
      } else {
        final error = ref.read(authProvider).error;
        print('❌ SignupScreen: Registration failed - $error');
        _showErrorSnackBar(error ?? 'Signup failed');
      }
    } on Exception catch (e) {
      if (!mounted) return;
      print('❌ SignupScreen: Registration exception - ${e.toString()}');
      _showErrorSnackBar(e.toString());
    } catch (e) {
      if (!mounted) return;
      print('❌ SignupScreen: Unexpected error - ${e.toString()}');
      _showErrorSnackBar('Signup failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLocalLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleGoogleSignup() async {
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
        _showSuccessAndNavigate('Google Sign-Up successful');
      }
    } catch (e) {
      _showErrorSnackBar('Google Sign-Up failed: $e');
    }
  }

  Future<void> _handleFacebookSignup() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        final UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCred.user != null) {
          _showSuccessAndNavigate('Facebook Sign-Up successful');
        }
      } else if (result.status != LoginStatus.cancelled) {
        _showErrorSnackBar('Facebook Sign-Up failed: ${result.message}');
      }
    } catch (e) {
      _showErrorSnackBar('Facebook Sign-Up failed: $e');
    }
  }

  void _showSuccessAndNavigate(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
    context.push('/dashboard');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
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
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign up to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8A8A8A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
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
                        _AuthInputField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          hint: 'Full Name',
                          icon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_emailFocusNode);
                          },
                        ),
                        const SizedBox(height: 14),
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
                            FocusScope.of(context).requestFocus(_phoneFocusNode);
                          },
                        ),
                        const SizedBox(height: 14),
                        _AuthInputField(
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          hint: 'Phone',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          validator: AppValidators.validatePhone,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_passwordFocusNode);
                          },
                        ),
                        const SizedBox(height: 14),
                        _AuthInputField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          hint: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          validator: AppValidators.validatePassword,
                          onFieldSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_confirmPasswordFocusNode);
                          },
                          suffixIcon: IconButton(
                            splashRadius: 20,
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF202020),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _AuthInputField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          hint: 'Confirm Password',
                          icon: Icons.verified_user_outlined,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please confirm your password';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleSignup(),
                          suffixIcon: IconButton(
                            splashRadius: 20,
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF202020),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF163F6B),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(
                          0xFF163F6B,
                        ).withValues(alpha: 0.7),
                        elevation: 4,
                        shadowColor: const Color(
                          0xFF163F6B,
                        ).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
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
                        onTap: _handleGoogleSignup,
                      ),
                      const SizedBox(width: 18),
                      _SocialCircleButton(
                        imagePath: 'assets/facebook.png',
                        fallbackText: 'f',
                        onTap: _handleFacebookSignup,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Color(0xFF6A6A6A), fontSize: 14),
                      ),
                      TextButton(
                        onPressed: isLoading ? null : () {
                           FocusScope.of(context).unfocus();
                           context.push('/login');
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Color(0xFF163F6B),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
      inputFormatters: hint == 'Email'
          ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
          : null,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF111111),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF8A8A8A),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 8),
          child: Icon(icon, color: const Color(0xFF202020), size: 24),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD5D5D5), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF163F6B), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
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
              color: fallbackText == 'G'
                  ? const Color(0xFFDB4437)
                  : const Color(0xFF1877F2),
            ),
          ),
        ),
      ),
    );
  }
}
