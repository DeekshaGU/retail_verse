import 'package:flutter/material.dart';
import 'package:retail_verse_pos/core/theme/app_colors.dart';
import 'package:retail_verse_pos/core/theme/app_typography.dart';
import 'package:retail_verse_pos/data/remote/super_admin_service.dart';
import 'package:retail_verse_pos/features/dashboard/presentation/widgets/dashboard_widgets.dart';

class SaSubscriptionsScreen extends StatefulWidget {
  const SaSubscriptionsScreen({super.key});

  @override
  State<SaSubscriptionsScreen> createState() => _SaSubscriptionsScreenState();
}

class _SaSubscriptionsScreenState extends State<SaSubscriptionsScreen> {
  final _svc = SuperAdminService();
  late Future<List<Map<String, dynamic>>> _plansF;
  late Future<List<Map<String, dynamic>>> _bizF;
  String _q = '';
  final _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _plansF = _svc.listSubscriptionPlans();
    _bizF = _svc.listBusinesses();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // ── PREMIUM INTEGRATED HEADER ──────────────────
            Container(
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subscriptions', style: AppTypography.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: _searchC,
                      onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search client ecosystems...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TabBar(
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 4,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.5),
                    labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1),
                    tabs: const [
                      Tab(text: 'CLIENTS'),
                      Tab(text: 'CATALOG'),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _buildClientsTab(),
                  _buildPlansTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _bizF,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final items = (snap.data ?? []).where((b) {
          final name = (b['businessName'] ?? '').toString().toLowerCase();
          return name.contains(_q);
        }).toList();

        return RefreshIndicator(
          onRefresh: () async => setState(() => _bizF = _svc.listBusinesses()),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            itemCount: items.length,
            itemBuilder: (context, i) => _buildModernClientCard(items[i]),
          ),
        );
      },
    );
  }

  Widget _buildModernClientCard(Map<String, dynamic> b) {
    final name = b['businessName']?.toString() ?? 'Unnamed';
    final plan = b['subscriptionPlan']?.toString() ?? 'free';
    final status = b['subscriptionStatus']?.toString() ?? 'active';
    final active = status.toLowerCase() == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppColors.shadowSubtle,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                _buildPlanBadge(plan),
              ],
            ),
          ),
          _buildStatusTag(status, active),
        ],
      ),
    );
  }

  Widget _buildPlanBadge(String plan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(plan.toUpperCase(), style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 9)),
    );
  }

  Widget _buildStatusTag(String label, bool active) {
    final color = active ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildPlansTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _plansF,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final items = snap.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          itemCount: items.length,
          itemBuilder: (context, i) => _buildModernPlanCard(items[i]),
        );
      },
    );
  }

  Widget _buildModernPlanCard(Map<String, dynamic> p) {
    final code = p['code']?.toString() ?? 'PLAN';
    final price = p['price']?.toString() ?? '0';
    final period = p['billingPeriod']?.toString() ?? 'month';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: AppColors.shadowSubtle,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(code.toUpperCase(), style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Enterprise Solution', style: AppTypography.labelLarge.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 28),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Divider(height: 1, thickness: 1)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₹$price', style: AppTypography.displaySmall.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              const SizedBox(width: 8),
              Text('/ $period', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 32),
          _buildFeatureRow('Unlimited Global Invoices'),
          _buildFeatureRow('Advanced Inventory Control'),
          _buildFeatureRow('Multi-Store Management'),
          _buildFeatureRow('Priority Enterprise Support'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Configure Catalog Item', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 16),
          Text(text, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
