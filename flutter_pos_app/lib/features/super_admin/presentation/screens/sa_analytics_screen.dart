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
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snap.hasError) {
            return Center(child: Text('Error loading analytics', style: AppTypography.titleMedium));
          }

          final root = snap.data ?? const {};
          final data = Map<String, dynamic>.from(root['data'] ?? {});
          final cards = Map<String, dynamic>.from(data['cards'] ?? {});
          final perBiz = (data['perBusinessOrders'] as List?) ?? [];
          
          final totalRev = _money(_n(cards['totalRevenue']));
          final totalOrders = _n(cards['totalOrders']);
          final totalCustomers = _n(cards['totalCustomers']);
          final totalBizCount = _n(cards['totalBusinesses'] ?? 0);
          final activeBizCount = _n(cards['activeBusinesses']);

          return RefreshIndicator(
            onRefresh: () async => setState(() => _f = _svc.getAnalyticsSummary()),
            child: CustomScrollView(
              slivers: [
                // ── PREMIUM HEADER ─────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text('Insights & Performance', style: AppTypography.labelLarge.copyWith(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          Text('Platform Intelligence', style: AppTypography.displaySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── KPI GRID ────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: MediaQuery.of(context).size.width > 600 ? 300 : 200,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: MediaQuery.of(context).size.width > 900 ? 1.3 : (MediaQuery.of(context).size.width > 600 ? 0.9 : 0.75),
                    ),
                    delegate: SliverChildListDelegate([
                      _AnalyticsKPICard(
                        title: 'Total Revenue',
                        value: '\$$totalRev',
                        subtitle: 'Platform GMV',
                        icon: Icons.payments_rounded,
                        color: AppColors.success,
                      ),
                      _AnalyticsKPICard(
                        title: 'Total Orders',
                        value: totalOrders.toInt().toString(),
                        subtitle: 'Transactions',
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.primary,
                      ),
                      _AnalyticsKPICard(
                        title: 'Client Stores',
                        value: totalBizCount.toInt().toString(),
                        subtitle: '$activeBizCount Active',
                        icon: Icons.storefront_rounded,
                        color: AppColors.info,
                      ),
                      _AnalyticsKPICard(
                        title: 'Total Customers',
                        value: totalCustomers.toInt().toString(),
                        subtitle: 'Buying clients',
                        icon: Icons.group_rounded,
                        color: Colors.deepPurple,
                      ),
                      _AnalyticsKPICard(
                        title: 'Growth',
                        value: '14.2%',
                        subtitle: 'Monthly increase',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.secondary,
                      ),
                    ]),
                    ),
                  ),

                // ── BUSINESS PERFORMANCE ──────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Store Performance', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                        const Icon(Icons.sort_rounded, color: AppColors.textTertiary),
                      ],
                    ),
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
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: AppColors.shadowSubtle,
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                      child: const Icon(Icons.store_rounded, color: AppColors.primary, size: 20),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(bid, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                                  ],
                                ),
                                Text('\$$rev', style: AppTypography.titleMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$orders Transactions', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                Text('Performance: High', style: AppTypography.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: (orders / 100).clamp(0, 1).toDouble(),
                                backgroundColor: AppColors.backgroundSecondary,
                                color: AppColors.primary,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: perBiz.length,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnalyticsKPICard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;

  const _AnalyticsKPICard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.shadowSubtle,
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: constraints.maxWidth > 100 ? 22 : 18),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(value, style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
                    ),
                    const SizedBox(height: 2),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 9)),
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
