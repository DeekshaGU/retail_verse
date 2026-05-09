import 'package:flutter/foundation.dart' as fdn;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/navigation/role_nav.dart';
import '../core/navigation/role_route_guard.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../data/models/product_model.dart';
import '../features/pos/presentation/screens/pos_billing_screen.dart';
import '../features/pos/presentation/screens/pos_cart_screen.dart';
import '../features/pos/presentation/screens/pos_product_detail_screen.dart';
import '../features/pos/presentation/screens/pos_screen.dart';
import '../features/orders/presentation/screens/orders_list_screen.dart';
import '../features/orders/presentation/screens/order_detail_screen.dart';
import '../features/inventory/presentation/screens/inventory_screen.dart';
import '../features/inventory/presentation/screens/category_products_screen.dart';
import '../features/inventory/presentation/screens/add_product_screen.dart';
import '../features/inventory/data/models/category.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/account/presentation/screens/account_screen.dart';
import '../features/customers/presentation/screens/customers_screen.dart';
import '../features/admin/presentation/admin_staff_screen.dart';
import '../features/super_admin/presentation/screens/sa_shell.dart';
import '../features/super_admin/presentation/screens/sa_dashboard_screen.dart';
import '../features/super_admin/presentation/screens/sa_businesses_screen.dart';
import '../features/super_admin/presentation/screens/sa_users_screen.dart';
import '../features/super_admin/presentation/screens/sa_subscriptions_screen.dart';
import '../features/super_admin/presentation/screens/sa_analytics_screen.dart';
import '../features/super_admin/presentation/screens/sa_settings_screen.dart';
import '../features/super_admin/presentation/screens/sa_custom_domains_screen.dart';
import '../features/super_admin/presentation/screens/sa_logs_screen.dart';
import '../features/super_admin/presentation/screens/sa_stores_performance_screen.dart';
import '../features/super_admin/presentation/screens/sa_add_business_screen.dart';
import '../features/dashboard/presentation/widgets/dashboard_widgets.dart';
import '../features/dashboard/presentation/screens/sales_details_screen.dart';
import '../features/dashboard/presentation/screens/avg_sale_details_screen.dart';
import '../features/customers/presentation/screens/add_customer_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (BuildContext context, GoRouterState state) {
    final loc = state.uri.path;
    const public = {'/splash', '/login', '/signup'};
    if (public.contains(loc)) return null;

    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final token = container.read(authProvider).token?.trim();
      final loggedIn = token != null && token.isNotEmpty;
      if (!loggedIn) return '/login';
    } catch (_) {
      // Provider not available yet — stay on splash until ready.
      if (loc == '/splash' || loc == '/login' || loc == '/signup') return null;
      return '/splash';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),

    // Super Admin panel (isolated from POS shell). Visible entry is in Settings for super_admin only.
    ShellRoute(
      builder: (context, state, child) => SuperAdminShell(child: child),
      routes: [
        GoRoute(
          path: '/super-admin/dashboard',
          builder: (context, state) => const SaDashboardScreen(),
        ),
        GoRoute(
          path: '/super-admin/businesses',
          builder: (context, state) => const SaBusinessesScreen(),
        ),
        GoRoute(
          path: '/super-admin/users',
          builder: (context, state) => const SaUsersScreen(),
        ),
        GoRoute(
          path: '/super-admin/subscriptions',
          builder: (context, state) => const SaSubscriptionsScreen(),
        ),
        GoRoute(
          path: '/super-admin/analytics',
          builder: (context, state) => const SaAnalyticsScreen(),
        ),
        GoRoute(
          path: '/super-admin/settings',
          builder: (context, state) => const SaSettingsScreen(),
        ),
        GoRoute(
          path: '/super-admin/custom-domains',
          builder: (context, state) => const SaCustomDomainsScreen(),
        ),
        GoRoute(
          path: '/super-admin/logs',
          builder: (context, state) => const SaLogsScreen(),
        ),
        GoRoute(
          path: '/super-admin/stores-performance',
          builder: (context, state) => const SaStoresPerformanceScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/super-admin/businesses/add',
      builder: (context, state) => const SaAddBusinessScreen(),
    ),

    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(
          child: _ShellAccessGate(
            location: state.uri.path,
            child: child,
          ),
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const DashboardScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
        GoRoute(
          path: '/sales-details',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SalesDetailsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
        GoRoute(
          path: '/avg-sale-details',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AvgSaleDetailsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
        GoRoute(
          path: '/pos',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const POSScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
          routes: [
            GoRoute(
              path: 'cart',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const PosCartScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.06, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
              ),
            ),
            GoRoute(
              path: 'billing',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const PosBillingScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.06, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
              ),
            ),
            GoRoute(
              path: 'product',
              pageBuilder: (context, state) {
                final extra = state.extra;
                Product? product;
                void Function(Product, int)? onAddToBilling;
                if (extra is PosBillingProductDetailExtra) {
                  product = extra.product;
                  onAddToBilling = extra.onAdded;
                } else if (extra is Product) {
                  product = extra;
                }
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: product == null
                      ? const _PosProductMissingFallback()
                      : PosProductDetailScreen(
                          product: product,
                          onAddToBilling: onAddToBilling,
                        ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/orders',
          pageBuilder: (context, state) => _guardedShellPage(
            context: context,
            state: state,
            routePath: '/orders',
            child: const OrdersListScreen(),
          ),
        ),
        GoRoute(
          path: '/inventory',
          pageBuilder: (context, state) => _guardedShellPage(
            context: context,
            state: state,
            routePath: '/inventory',
            child: const InventoryScreen(),
          ),
        ),
        GoRoute(
          path: '/inventory/:categoryId',
          pageBuilder: (context, state) {
            final category = state.extra as Category;
            return _guardedShellPage(
              context: context,
              state: state,
              routePath: '/inventory/${state.pathParameters['categoryId'] ?? ''}',
              child: CategoryProductsScreen(category: category),
            );
          },
        ),
        GoRoute(
          path: '/inventory/:categoryId/add-product',
          pageBuilder: (context, state) {
            final category = state.extra as Category?;
            return _guardedShellPage(
              context: context,
              state: state,
              routePath:
                  '/inventory/${state.pathParameters['categoryId'] ?? ''}/add-product',
              child: AddProductScreen(category: category),
            );
          },
        ),
        GoRoute(
          path: '/customers',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CustomersScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
        GoRoute(
          path: '/add-customer',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AddCustomerScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
        GoRoute(
          path: '/admin/staff',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AdminStaffScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
        GoRoute(
          path: '/account',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AccountScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
        GoRoute(
          path: '/order-detail/:id',
          pageBuilder: (context, state) {
            final order = state.extra as dynamic;
            return CustomTransitionPage(
              key: state.pageKey,
              child: OrderDetailScreen(order: order),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            );
          },
        ),
      ],
    ),
  ],
);

CustomTransitionPage<void> _guardedShellPage({
  required BuildContext context,
  required GoRouterState state,
  required String routePath,
  required Widget child,
}) {
  final container = ProviderScope.containerOf(context, listen: false);
  final role = effectiveUserRole(container.read(authProvider).user);
  final allowed = isRouteAllowedForShell(routePath, role);
  return CustomTransitionPage(
    key: state.pageKey,
    child: allowed
        ? child
        : RoleAccessDeniedView(
            onGoHome: () => context.go('/dashboard'),
          ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

/// Shown when `/pos/product` is opened without `extra` (deep link / bad navigation).
class _PosProductMissingFallback extends StatelessWidget {
  const _PosProductMissingFallback();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 48),
              const SizedBox(height: 16),
              const Text('No product selected.'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go('/pos'),
                child: const Text('Back to products'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellAccessGate extends ConsumerWidget {
  const _ShellAccessGate({
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = effectiveUserRole(ref.watch(authProvider).user);
    if (isRouteAllowedForShell(location, role)) {
      return child;
    }
    return RoleAccessDeniedView(onGoHome: () => context.go('/dashboard'));
  }
}

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.path;
    final role = effectiveUserRole(ref.read(authProvider).user);

    if (!isRouteAllowedForShell(location, role)) {
      _selectedIndex = 0;
      return;
    }

    final items = shellNavItemsForRole(role);
    var idx = 0;
    for (var i = 0; i < items.length; i++) {
      if (shellPathMatchesItem(location, items[i].path)) {
        idx = i;
        break;
      }
    }
    _selectedIndex = idx.clamp(0, items.length - 1);
  }

  void _onItemTapped(int index, List<ShellNavItem> items) {
    if (index < 0 || index >= items.length) return;
    setState(() => _selectedIndex = index);
    context.go(items[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final role = effectiveUserRole(ref.watch(authProvider).user);
    if (fdn.kDebugMode) {
      final path = GoRouterState.of(context).uri.path;
      fdn.debugPrint('[auth] NAV ROLE (MainLayout): $role path=$path');
    }
    final items = shellNavItemsForRole(role);
    final safeIndex = _selectedIndex.clamp(0, items.length - 1);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    final body = isTablet
        ? Scaffold(
            key: ValueKey<String>('shell_nav_$role'),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: safeIndex,
                  onDestinationSelected: (i) => _onItemTapped(i, items),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final it in items)
                      NavigationRailDestination(
                        icon: Icon(it.icon),
                        selectedIcon: Icon(it.selectedIcon),
                        label: Text(it.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: widget.child),
              ],
            ),
          )
        : Scaffold(
            key: ValueKey<String>('shell_nav_$role'),
            extendBody: true,
            body: widget.child,
            bottomNavigationBar: PremiumFloatingNavBar(
              selectedIndex: safeIndex,
              onDestinationSelected: (i) => _onItemTapped(i, items),
              items: [
                for (final it in items)
                  PremiumNavItem(
                    icon: it.icon,
                    selectedIcon: it.selectedIcon,
                    label: it.label,
                  ),
              ],
            ),
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !context.mounted) return;

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }

        if (context.canPop()) {
          context.pop();
          return;
        }

        final path = GoRouterState.of(context).uri.path;
        final home = initialHomeRouteForUser(ref.read(authProvider).user);

        if (path != home) {
          context.go(home);
        } else {
          SystemNavigator.pop();
        }
      },
      child: body,
    );
  }
}
