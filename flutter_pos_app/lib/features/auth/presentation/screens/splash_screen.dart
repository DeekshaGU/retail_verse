import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/navigation/role_nav.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/session_service.dart';
import '../../../dashboard/providers/dashboard_providers.dart';
import '../../providers/auth_provider.dart';

/// Splash screen with logo and animation + session check
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: AppConstants.splashDuration),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    _checkSessionAndNavigate();
  }

  Future<bool> _backendReachable() async {
    try {
      final uri = ApiEndpoints.healthCheckUri();
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      final body = res.body;
      return res.statusCode == 200 &&
          (body.contains('POS Backend running') ||
              body.contains('POS backend is running') ||
              body.contains('"ok":true'));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Splash: backend ping failed: $e');
      }
      return false;
    }
  }

  /// `true` = token accepted, `false` = unauthorized (clear session), `null` = network error.
  Future<bool?> _probeAuthenticatedSession() async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) return false;
    try {
      final uri = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.dashboardStats}',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));
      // Only 200 counts as a valid session; 403/404/5xx were wrongly treated as "logged in"
      // before, which skipped the login screen while the token was useless.
      if (res.statusCode == 401 || res.statusCode == 403) return false;
      if (res.statusCode == 200) return true;
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Splash: auth probe failed (network?): $e');
      }
      return null;
    }
  }

  Future<void> _checkSessionAndNavigate() async {
    try {
      await Future.delayed(
        const Duration(milliseconds: AppConstants.splashDuration),
      );

      final hasSession = await SessionService.hasSession();

      if (!mounted) return;

      if (hasSession) {
        if (kDebugMode) {
          debugPrint('Splash: saved session found, hydrating auth state');
        }
        await ref.read(authProvider.notifier).restoreFromStorage();
        if (!mounted) return;

        final probe = await _probeAuthenticatedSession();
        if (!mounted) return;
        if (probe == false) {
          if (kDebugMode) {
            debugPrint(
              'Splash: token rejected or invalid for API (401/403), clearing session',
            );
          }
          await ref.read(authProvider.notifier).logout();
          if (!mounted) return;
          context.go('/login');
          return;
        }

        invalidateAllDashboardProviders(ref);

        if (probe == null) {
          final ok = await _backendReachable();
          if (!mounted) return;
          if (!ok) {
            final clear = await showDialog<bool>(
              context: context,
              barrierDismissible: true,
              builder: (ctx) => AlertDialog(
                title: const Text('Backend not reachable'),
                content: SingleChildScrollView(
                  child: Text(
                    'Could not reach your server at:\n\n${ApiEndpoints.baseUrl}\n\n'
                    '• Phone + laptop same Wi‑Fi?\n'
                    '• Node server running (port 5000)?\n'
                    '• Use your PC LAN IP — update in Settings → API after login.\n'
                    '• API base URL should be set to https://app-backend-je91.onrender.com/api\n\n'
                    'To sign in with a different account, clear the saved session.',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('OK'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Clear saved login'),
                  ),
                ],
              ),
            );
            if (!mounted) return;
            if (clear == true) {
              await ref.read(authProvider.notifier).logout();
              if (!mounted) return;
              context.go('/login');
              return;
            }
          }
        }

        final home = initialHomeRouteForUser(ref.read(authProvider).user);
        if (!mounted) return;
        context.go(home);
      } else {
        if (kDebugMode) {
          debugPrint('Splash: no saved session, navigating to login');
        }
        context.go('/login');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Splash: navigation error: $e\n$st');
      }
      try {
        await ref.read(authProvider.notifier).logout();
      } catch (_) {}
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AppConstants.logoAsset,
                height: 96,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              Text(
                AppConstants.appName,
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.bold,
                  fontSize: 32, // Slightly larger for impact
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}