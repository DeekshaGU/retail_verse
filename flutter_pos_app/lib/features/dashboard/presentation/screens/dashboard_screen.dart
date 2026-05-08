import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retail_verse_pos/core/theme/app_colors.dart';
import 'package:retail_verse_pos/core/theme/app_typography.dart';
import 'package:retail_verse_pos/features/auth/providers/auth_provider.dart';
import 'package:retail_verse_pos/features/dashboard/providers/dashboard_providers.dart';
import 'package:retail_verse_pos/features/dashboard/presentation/widgets/dashboard_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final statsAsync = ref.watch(dashboardStatsProvider);
    
    final userName = user?['name'] ?? 'Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: statsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error loading dashboard: $e')),
        data: (stats) {
          return CustomScrollView(
            slivers: [
              // ── 1. PREMIUM HERO HEADER ─────────────────────
              SliverToBoxAdapter(
                child: PremiumHeroHeader(
                  userName: userName,
                  totalSales: stats.totalSales,
                  totalOrders: stats.totalOrders,
                ),
              ),

              // ── 2. KPI GRID ────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    SaaSKPICard(
                      title: 'Total Sales',
                      value: '\$${stats.totalSales}',
                      subtitle: '+12.5%',
                      icon: Icons.payments_rounded,
                      accentColor: AppColors.primary,
                      onTap: () => context.push('/dashboard/sales'),
                    ),
                    SaaSKPICard(
                      title: 'Orders',
                      value: '${stats.totalOrders}',
                      subtitle: 'Live Now',
                      icon: Icons.receipt_long_rounded,
                      accentColor: AppColors.success,
                      onTap: () => context.go('/orders'),
                    ),
                    SaaSKPICard(
                      title: 'Low Stock',
                      value: '${stats.lowStockItems}',
                      subtitle: 'Needs restock',
                      icon: Icons.inventory_2_rounded,
                      accentColor: AppColors.info,
                      onTap: () => context.go('/inventory'),
                    ),
                    SaaSKPICard(
                      title: 'Customers',
                      value: '${stats.totalCustomers}',
                      subtitle: 'Registered',
                      icon: Icons.people_alt_rounded,
                      accentColor: AppColors.warning,
                      onTap: () => context.go('/customers'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
