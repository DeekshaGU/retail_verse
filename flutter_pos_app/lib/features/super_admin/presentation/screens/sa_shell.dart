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
import 'package:retail_verse_pos/features/super_admin/presentation/widgets/support_dialog.dart';

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
  _SaRoute(label: 'Support', path: 'support', icon: Icons.support_agent_rounded, selectedIcon: Icons.support_agent_rounded),
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
            Text('Client Store Control', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Switch control to a specific client store', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
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
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(24), 
                      border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
                      boxShadow: AppColors.shadowSubtle,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
                        child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                      ),
                      title: Text(name, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w900)),
                      subtitle: const Text('Tap to switch context', style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
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

    return PopScope(
      canPop: path == '/super-admin/dashboard',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/super-admin/dashboard');
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: _SuperAdminDrawer(
          email: email, 
          onStore: () => _openClientStorePicker(context), 
          onPick: (p) => context.go(p)
        ),
        appBar: path == '/super-admin/dashboard' ? null : _buildModernAppBar(),
        floatingActionButton: const _BlinkingSupportFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Stack(
          children: [
            widget.child,
            // Floating Bottom Navigation - ONLY on Dashboard
            if (path == '/super-admin/dashboard')
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width > 600 ? 500 : MediaQuery.of(context).size.width - 40,
                    ),
                    child: _ModernFloatingNavBar(
                      selectedIndex: bottomIdx,
                      onDestinationSelected: (i) => i == 3 ? _openMoreSheet(context) : context.push(_kPrimaryShellRoutes[i].path),
                      items: [
                        ..._kPrimaryShellRoutes.map((r) => _ModernNavItem(icon: r.icon, selectedIcon: r.selectedIcon, label: r.label)),
                        const _ModernNavItem(icon: Icons.more_horiz_rounded, selectedIcon: Icons.apps_rounded, label: 'More'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    final path = GoRouterState.of(context).uri.path;
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.more_vert_rounded, 
            color: AppColors.primary, 
            size: 20
          ),
        ), 
        onPressed: () => _scaffoldKey.currentState?.openDrawer()
      ),
      title: Text('Retail Verse', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      actions: [
        IconButton(
          onPressed: () => _openClientStorePicker(context), 
          icon: const Icon(Icons.swap_horizontal_circle_outlined, color: AppColors.primary)
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _openMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 40, offset: Offset(0, -10))],
          ),
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 32),
                GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  children: _kSecondaryShellRoutes.map((r) => _MoreToolIcon(
                    route: r, 
                    onTap: () { 
                      Navigator.pop(ctx); 
                      if (r.path == 'support') {
                        showDialog(context: context, builder: (c) => const SupportDialog());
                      } else {
                        context.push(r.path); 
                      }
                    }
                  )).toList(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
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

class _ModernFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<_ModernNavItem> items;

  const _ModernFloatingNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (i) {
          final isSelected = selectedIndex == i;
          final item = items[i];
          return InkWell(
            onTap: () => onDestinationSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    color: isSelected ? Colors.white : Colors.white60,
                    size: 24,
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ModernNavItem {
  final IconData icon, selectedIcon;
  final String label;
  const _ModernNavItem({required this.icon, required this.selectedIcon, required this.label});
}

class _MoreToolIcon extends StatelessWidget {
  final _SaRoute route;
  final VoidCallback onTap;
  const _MoreToolIcon({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Icon(route.icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            route.label, 
            textAlign: TextAlign.center, 
            style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary)
          ),
        ],
      ),
    );
  }
}

class _SuperAdminDrawer extends ConsumerWidget {
  final String email;
  final VoidCallback onStore;
  final void Function(String path) onPick;
  const _SuperAdminDrawer({required this.email, required this.onStore, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildDrawerSection(context, 'CORE MODULES', _kPrimaryShellRoutes),
                const SizedBox(height: 32),
                _buildDrawerSection(context, 'MORE TOOLS', _kSecondaryShellRoutes),
              ],
            ),
          ),
          _buildFooter(context, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              'Retail Verse',
              style: AppTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            Text(
              email,
              style: AppTypography.bodySmall.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Text(
                'SUPER ADMIN',
                style: AppTypography.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSection(BuildContext context, String title, List<_SaRoute> routes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 16), 
          child: Text(
            title, 
            style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w900, letterSpacing: 1.5)
          )
        ),
        ...routes.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(r.icon, size: 22, color: AppColors.textSecondary),
            title: Text(r.label, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onTap: () { 
              Navigator.pop(context); 
              if (r.path == 'support') {
                showDialog(context: context, builder: (c) => const SupportDialog());
              } else {
                onPick(r.path); 
              }
            },
            hoverColor: AppColors.primary.withOpacity(0.05),
          ),
        )),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.5))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: onStore,
            icon: const Icon(Icons.launch_rounded, size: 18),
            label: const Text('Launch Client POS'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: AppColors.primary.withOpacity(0.1),
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
            label: Text('Logout Retail Verse', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaRoute {
  final String label, path;
  final IconData icon, selectedIcon;
  const _SaRoute({required this.label, required this.path, required this.icon, required this.selectedIcon});
}

class _BlinkingSupportFAB extends StatefulWidget {
  const _BlinkingSupportFAB();

  @override
  State<_BlinkingSupportFAB> createState() => _BlinkingSupportFABState();
}

class _BlinkingSupportFABState extends State<_BlinkingSupportFAB> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80), // Offset to not overlap with nav bar
      child: FadeTransition(
        opacity: _controller,
        child: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const SupportDialog(),
            );
          },
          backgroundColor: AppColors.warning,
          shape: const CircleBorder(),
          child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
