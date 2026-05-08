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
            // ── PREMIUM HEADER ─────────────────────────────
            PremiumSearchHeader(
              title: 'Subscriptions',
              searchBar: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _searchC,
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search client subscriptions...',
                    hintStyle: TextStyle(color: Colors.white60),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.white70),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            Container(
              color: const Color(0xFF0F172A),
              child: TabBar(
                indicatorColor: AppColors.primary,
                indicatorWeight: 4,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Client Status'),
                  Tab(text: 'Plan Catalog'),
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
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        final items = (snap.data ?? []).where((b) {
          final name = (b['businessName'] ?? '').toString().toLowerCase();
          return name.contains(_q);
        }).toList();

        return RefreshIndicator(
          onRefresh: () async => setState(() => _bizF = _svc.listBusinesses()),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900)),
                Text('Plan: ${plan.toUpperCase()}', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          _buildStatusTag(status, active),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String label, bool active) {
    final color = active ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPlansTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _plansF,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        final items = snap.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(20),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF8FAFC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(code.toUpperCase(), style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary)),
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 24),
            ],
          ),
          const Divider(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₹$price', style: AppTypography.displaySmall.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              const SizedBox(width: 4),
              Text('/ $period', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 20),
          _buildFeatureRow('Unlimited Invoices'),
          _buildFeatureRow('Inventory Management'),
          _buildFeatureRow('Multi-User Access'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
          const SizedBox(width: 12),
          Text(text, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
