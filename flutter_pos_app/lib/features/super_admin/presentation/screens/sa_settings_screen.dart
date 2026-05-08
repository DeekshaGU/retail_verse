import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retail_verse_pos/core/theme/app_colors.dart';
import 'package:retail_verse_pos/core/theme/app_typography.dart';
import 'package:retail_verse_pos/features/auth/providers/auth_provider.dart';
import 'package:retail_verse_pos/features/dashboard/presentation/widgets/dashboard_widgets.dart';

class SaSettingsScreen extends ConsumerWidget {
  const SaSettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of the platform control panel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Logout')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── PREMIUM HEADER ─────────────────────────────
          PremiumSearchHeader(
            title: 'System Settings',
            searchBar: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.settings_suggest_rounded, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Global Platform Preferences',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionTitle('App Redirection'),
                _buildSettingsCard([
                  _SettingsTile(
                    icon: Icons.person_rounded,
                    title: 'Account & Profile',
                    subtitle: 'Manage your personal credentials',
                    onTap: () => context.go('/account'),
                  ),
                  _SettingsTile(
                    icon: Icons.dashboard_customize_rounded,
                    title: 'Business POS View',
                    subtitle: 'Switch to the store dashboard',
                    onTap: () => context.go('/dashboard'),
                  ),
                  _SettingsTile(
                    icon: Icons.tune_rounded,
                    title: 'Global Preferences',
                    subtitle: 'API, Theme & Sync settings',
                    onTap: () => context.go('/settings'),
                  ),
                ]),
                const SizedBox(height: 32),
                _buildSectionTitle('System Management'),
                _buildSettingsCard([
                  _SettingsTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'Broadcast Alerts',
                    subtitle: 'Send platform-wide notifications',
                    enabled: false,
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.security_rounded,
                    title: 'Security Audit',
                    subtitle: 'View global access logs',
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 40),
                _buildLogoutButton(context, ref),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context, ref),
        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
        label: const Text('Log Out From Super Admin', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: enabled ? onTap : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: (enabled ? AppColors.primary : Colors.grey).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: enabled ? AppColors.primary : Colors.grey, size: 22),
      ),
      title: Text(title, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, color: enabled ? AppColors.textPrimary : Colors.grey)),
      subtitle: Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
    );
  }
}
