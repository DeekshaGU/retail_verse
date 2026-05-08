import 'package:flutter/material.dart';
import 'package:retail_verse_pos/core/theme/app_colors.dart';
import 'package:retail_verse_pos/core/theme/app_typography.dart';
import 'package:retail_verse_pos/data/remote/super_admin_service.dart';
import 'package:retail_verse_pos/features/dashboard/presentation/widgets/dashboard_widgets.dart';

class SaAnalyticsScreen extends StatefulWidget {
  const SaAnalyticsScreen({super.key});

  @override
  State<SaAnalyticsScreen> createState() => _SaAnalyticsScreenState();
}

class _SaAnalyticsScreenState extends State<SaAnalyticsScreen> {
  final _svc = SuperAdminService();
  late Future<Map<String, dynamic>> _f;

  @override
  void initState() {
    super.initState();
    _f = _svc.getAnalyticsSummary();
  }

  static num _n(dynamic v) => (v is num) ? v : (num.tryParse(v?.toString() ?? '0') ?? 0);

  static String _money(num n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _f,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error loading analytics', style: AppTypography.titleMedium));
          }

          final root = snap.data ?? const {};
          final data = Map<String, dynamic>.from(root['data'] ?? {});
          final cards = Map<String, dynamic>.from(data['cards'] ?? {});
          final perBiz = (data['perBusinessOrders'] as List?) ?? [];
          
          final totalOrders = _n(cards['totalOrders']);
          final totalRev = _money(_n(cards['totalRevenue']));
          final totalBizCount = _n(cards['totalBusinesses']);
          final activeBizCount = _n(cards['activeBusinesses']);

          return RefreshIndicator(
            onRefresh: () async => setState(() => _f = _svc.getAnalyticsSummary()),
            child: CustomScrollView(
              slivers: [
                // ── PREMIUM HEADER ─────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Insights & Growth', style: AppTypography.labelLarge.copyWith(color: Colors.white60, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Platform Analytics', style: AppTypography.displaySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),

                // ── KPI GRID ────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      SaaSKPICard(
                        title: 'Total Revenue',
                        value: '\$$totalRev',
                        subtitle: 'Gross platform volume',
                        icon: Icons.payments_rounded,
                        accentColor: AppColors.success,
                      ),
                      SaaSKPICard(
                        title: 'Total Orders',
                        value: totalOrders.toInt().toString(),
                        subtitle: 'Transactions handled',
                        icon: Icons.receipt_long_rounded,
                        accentColor: AppColors.primary,
                      ),
                      SaaSKPICard(
                        title: 'Client Stores',
                        value: totalBizCount.toInt().toString(),
                        subtitle: '$activeBizCount stores active',
                        icon: Icons.storefront_rounded,
                        accentColor: AppColors.info,
                      ),
                      SaaSKPICard(
                        title: 'Growth Rate',
                        value: '12%',
                        subtitle: 'Monthly increase',
                        icon: Icons.trending_up_rounded,
                        accentColor: AppColors.accent,
                      ),
                    ],
                  ),
                ),

                // ── BUSINESS PERFORMANCE ──────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text('Store Performance', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900)),
                  ),
                ),

                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final r = Map<String, dynamic>.from(perBiz[index]);
                      final bid = r['businessId']?.toString() ?? 'Unassigned';
                      final orders = _n(r['orders']);
                      final rev = _money(_n(r['revenue']));
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(bid, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900)),
                                Text('\$$rev', style: AppTypography.titleMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('$orders Total Orders', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (orders / 100).clamp(0, 1).toDouble(), // Dummy scale
                                backgroundColor: AppColors.backgroundSecondary,
                                color: AppColors.primary,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: perBiz.length,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}
