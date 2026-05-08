import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retail_verse_pos/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:retail_verse_pos/core/constants/app_constants.dart';
import 'package:retail_verse_pos/core/navigation/role_nav.dart';
import 'package:retail_verse_pos/core/theme/app_colors.dart';
import 'package:retail_verse_pos/core/theme/app_typography.dart';
import 'package:retail_verse_pos/data/remote/super_admin_service.dart';
import 'package:retail_verse_pos/features/auth/providers/auth_provider.dart';

const _kPrimaryShellRoutes = <_SaRoute>[
  _SaRoute(label: 'Home', path: '/super-admin/dashboard', icon: Icons.space_dashboard_outlined, selectedIcon: Icons.space_dashboard_rounded),
  _SaRoute(label: 'Clients', path: '/super-admin/businesses', icon: Icons.apartment_outlined, selectedIcon: Icons.apartment_rounded),
  _SaRoute(label: 'Team', path: '/super-admin/users', icon: Icons.groups_outlined, selectedIcon: Icons.groups_rounded),
];

const _kSecondaryShellRoutes = <_SaRoute>[
  _SaRoute(label: 'Subscriptions', path: '/super-admin/subscriptions', icon: Icons.workspace_premium_outlined, selectedIcon: Icons.workspace_premium_rounded),
  _SaRoute(label: 'Analytics', path: '/super-admin/analytics', icon: Icons.insights_outlined, selectedIcon: Icons.insights_rounded),
  _SaRoute(label: 'Settings', path: '/super-admin/settings', icon: Icons.tune_outlined, selectedIcon: Icons.tune_rounded),
  _SaRoute(label: 'Custom Domain', path: '/super-admin/custom-domains', icon: Icons.language_outlined, selectedIcon: Icons.language_rounded),
  _SaRoute(label: 'Audit logs', path: '/super-admin/logs', icon: Icons.history_rounded, selectedIcon: Icons.history_rounded),
];

class SuperAdminShell extends ConsumerStatefulWidget {
  final Widget child;
  const SuperAdminShell({super.key, required this.child});

  @override
  ConsumerState<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends ConsumerState<SuperAdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _svc = SuperAdminService();

  Future<void> _openClientStorePicker(BuildContext context) async {
    final items = await _svc.listBusinesses();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Client Store', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Switch context to a specific business dashboard', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final b = items[i];
                  final name = b['businessName']?.toString() ?? b['businessId']?.toString() ?? 'Unknown';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.storefront_rounded, color: AppColors.primary)),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.go('/dashboard');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final user = ref.watch(authProvider).user ?? {};
    final email = user['email']?.toString() ?? 'Super Admin';
    final bottomIdx = _bottomIndexForPath(path);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _SuperAdminDrawer(email: email, onStore: () => _openClientStorePicker(context), onPick: (p) => context.go(p)),
      appBar: path == '/super-admin/dashboard' ? null : _buildModernAppBar(),
      body: widget.child,
      bottomNavigationBar: PremiumFloatingNavBar(
        selectedIndex: bottomIdx,
        onDestinationSelected: (i) => i == 3 ? _openMoreSheet(context) : context.go(_kPrimaryShellRoutes[i].path),
        items: [
          ..._kPrimaryShellRoutes.map((r) => PremiumNavItem(icon: r.icon, selectedIcon: r.selectedIcon, label: r.label)),
          const PremiumNavItem(icon: Icons.more_horiz_rounded, selectedIcon: Icons.apps_rounded, label: 'More'),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: false,
      leading: IconButton(icon: const Icon(Icons.menu_open_rounded, color: AppColors.primary), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
      title: Row(
        children: [
          Image.asset(AppConstants.logoAsset, height: 28),
          const SizedBox(width: 12),
          Text('Platform', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        ],
      ),
      actions: [
        IconButton(onPressed: () => _openClientStorePicker(context), icon: const Icon(Icons.swap_horizontal_circle_outlined, color: AppColors.primary)),
        const SizedBox(width: 8),
      ],
    );
  }

  void _openMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: _kSecondaryShellRoutes.map((r) => _MoreToolIcon(route: r, onTap: () { Navigator.pop(ctx); context.go(r.path); })).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  int _bottomIndexForPath(String path) {
    for (var i = 0; i < _kPrimaryShellRoutes.length; i++) {
      if (path == _kPrimaryShellRoutes[i].path || path.startsWith('${_kPrimaryShellRoutes[i].path}/')) return i;
    }
    return 3;
  }
}

class _MoreToolIcon extends StatelessWidget {
  final _SaRoute route;
  final VoidCallback onTap;
  const _MoreToolIcon({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
            child: Icon(route.icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(route.label, textAlign: TextAlign.center, style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }
}

class _SuperAdminDrawer extends StatelessWidget {
  final String email;
  final VoidCallback onStore;
  final void Function(String path) onPick;
  const _SuperAdminDrawer({required this.email, required this.onStore, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDrawerSection('CORE MODULES', _kPrimaryShellRoutes),
                const SizedBox(height: 24),
                _buildDrawerSection('SYSTEM TOOLS', _kSecondaryShellRoutes),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)])),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 30, backgroundColor: Colors.white12, child: Icon(Icons.shield_rounded, color: Colors.white, size: 32)),
          const SizedBox(height: 16),
          Text('Super Admin Panel', style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(email, style: AppTypography.bodySmall.copyWith(color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title, List<_SaRoute> routes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 12, bottom: 8), child: Text(title, style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w900))),
        ...routes.map((r) => ListTile(
          leading: Icon(r.icon, size: 22, color: AppColors.textPrimary),
          title: Text(r.label, style: const TextStyle(fontWeight: FontWeight.w600)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () { Navigator.pop(_scaffoldKey.currentContext!); onPick(r.path); },
        )),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: OutlinedButton.icon(
        onPressed: onStore,
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        label: const Text('Launch Client POS'),
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}

final _scaffoldKey = GlobalKey<ScaffoldState>();

class _SaRoute {
  final String label, path;
  final IconData icon, selectedIcon;
  const _SaRoute({required this.label, required this.path, required this.icon, required this.selectedIcon});
}
