import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common/modern_search_bar.dart';
import '../../../dashboard/providers/dashboard_providers.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final totalCustomers = statsAsync.asData?.value.totalCustomers ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Customers',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── MODERN SEARCH BAR ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ModernSearchBar(
              controller: _searchController,
              hintText: 'Search by name or phone...',
              onChanged: (v) => setState(() {}),
            ),
          ),

          // ── CUSTOMER COUNT CHIP ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Total Customers',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    totalCustomers.toString(),
                    style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // ── CUSTOMERS LIST ──────────────────────────────────
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final query = _searchController.text.toLowerCase();
                final filtered = customers.where((c) => 
                  c.name.toLowerCase().contains(query) || 
                  c.phone.contains(query)
                ).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No customers found'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(color: AppColors.border.withOpacity(0.3), height: 32),
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                          child: Text(
                            customer.name[0].toUpperCase(),
                            style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customer.phone,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.formatCurrency(customer.totalSpent),
                              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${customer.totalOrders} Orders',
                              style: AppTypography.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-customer'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Customer', style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
