import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:retail_verse_pos/core/theme/app_colors.dart';
import 'package:retail_verse_pos/core/theme/app_typography.dart';
import 'package:retail_verse_pos/data/remote/super_admin_service.dart';
import 'package:retail_verse_pos/features/dashboard/presentation/widgets/dashboard_widgets.dart';

class SaDashboardScreen extends StatefulWidget {
  const SaDashboardScreen({super.key});

  @override
  State<SaDashboardScreen> createState() => _SaDashboardScreenState();
}

class _SaDashboardScreenState extends State<SaDashboardScreen> {
  final _svc = SuperAdminService();
  late Future<Map<String, dynamic>> _f;

  @override
  void initState() {
    super.initState();
    _f = _svc.getAnalyticsSummary();
  }

  static num _n(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  void _showStorePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _StorePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _f,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        
        final root = snap.data ?? const {};
        final data = (root['data'] is Map)
            ? Map<String, dynamic>.from(root['data'] as Map)
            : const <String, dynamic>{};

        final cards = (data['cards'] is Map)
            ? Map<String, dynamic>.from(data['cards'] as Map)
            : const <String, dynamic>{};

        final businesses = (data['businesses'] is Map)
            ? Map<String, dynamic>.from(data['businesses'] as Map)
            : const <String, dynamic>{};

        final totalAdmins = _n(cards['totalAdmins']);
        final totalStaff = _n(cards['totalCustomers']);
        final totalUsers = totalAdmins + totalStaff;
        
        final totalBiz = cards.containsKey('totalBusinesses') ? _n(cards['totalBusinesses']) : _n(businesses['total']);
        final activeBiz = cards.containsKey('activeBusinesses') ? _n(cards['activeBusinesses']) : _n(businesses['active']);
        final pendingSubs = _n(cards['pendingSubscriptions']);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _f = _svc.getAnalyticsSummary();
                });
                await _f;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── 1. PREMIUM PLATFORM HEADER ─────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 40),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Platform Controller',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: Colors.white60,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Super Admin',
                                    style: AppTypography.displaySmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              _buildStorePickerButton(),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Glassmorphism summary container
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem('Clients', totalBiz.toInt().toString(), Icons.business_rounded),
                                Container(width: 1, height: 40, color: Colors.white10),
                                _buildSummaryItem('Active', activeBiz.toInt().toString(), Icons.verified_user_rounded),
                                Container(width: 1, height: 40, color: Colors.white10),
                                _buildSummaryItem('Users', totalUsers.toInt().toString(), Icons.group_rounded),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── 2. KPI GRID ────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                    sliver: SliverGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                      children: [
                        SaaSKPICard(
                          title: 'Total Clients',
                          value: totalBiz.toInt().toString(),
                          subtitle: 'Global store count',
                          icon: Icons.business_center_rounded,
                          accentColor: AppColors.primary,
                          onTap: () => context.go('/super-admin/businesses'),
                        ),
                        SaaSKPICard(
                          title: 'Active Licenses',
                          value: activeBiz.toInt().toString(),
                          subtitle: 'Live instances',
                          icon: Icons.check_circle_rounded,
                          accentColor: AppColors.success,
                        ),
                        SaaSKPICard(
                          title: 'Staff Users',
                          value: totalStaff.toInt().toString(),
                          subtitle: 'Platform wide',
                          icon: Icons.people_alt_rounded,
                          accentColor: AppColors.info,
                        ),
                        SaaSKPICard(
                          title: 'Pending Stores',
                          value: pendingSubs.toInt().toString(),
                          subtitle: 'Awaiting approval',
                          icon: Icons.hourglass_empty_rounded,
                          accentColor: AppColors.warning,
                        ),
                      ],
                    ),
                  ),

                  // ── 3. MANAGEMENT OPERATIONS ───────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'System Operations',
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/super-admin/businesses'),
                                child: const Text('View All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildModernOpTile(
                            title: 'Onboard New Business',
                            subtitle: 'Create a new client store manually',
                            icon: Icons.add_business_rounded,
                            color: AppColors.primary,
                            onTap: () => context.go('/super-admin/businesses'),
                          ),
                          _buildModernOpTile(
                            title: 'License Keys',
                            subtitle: 'Manage subscription validity',
                            icon: Icons.key_rounded,
                            color: AppColors.success,
                          ),
                          _buildModernOpTile(
                            title: 'Domain Management',
                            subtitle: 'White-label custom domains',
                            icon: Icons.dns_rounded,
                            color: AppColors.accent,
                            onTap: () => context.go('/super-admin/custom-domains'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white60,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStorePickerButton() {
    return InkWell(
      onTap: _showStorePicker,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Switch',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernOpTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StorePickerSheet extends StatefulWidget {
  const _StorePickerSheet();

  @override
  State<_StorePickerSheet> createState() => _StorePickerSheetState();
}

class _StorePickerSheetState extends State<_StorePickerSheet> {
  final _svc = SuperAdminService();
  List<Map<String, dynamic>> _all = [];
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _svc.listBusinesses();
      if (mounted) {
        setState(() {
          _all = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _all.where((b) {
      final name = b['businessName']?.toString().toLowerCase() ?? '';
      return name.contains(_search.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Client Business',
                  style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Switch the current active data view',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search business name...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty 
                ? Center(child: Text('No results found', style: AppTypography.bodyLarge))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final b = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.cardBorder.withOpacity(0.4)),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context);
                            context.go('/dashboard'); 
                          },
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.store_rounded, color: AppColors.primary),
                          ),
                          title: Text(
                            b['businessName'] ?? 'Unnamed',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            b['ownerEmail'] ?? 'No email',
                            style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
