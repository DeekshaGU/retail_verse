import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retail_verse_pos/core/theme/app_colors.dart';
import 'package:retail_verse_pos/core/theme/app_typography.dart';
import 'package:retail_verse_pos/core/widgets/common/modern_search_bar.dart';
import 'package:retail_verse_pos/features/auth/providers/auth_provider.dart';
import 'package:retail_verse_pos/features/inventory/data/models/category_entity.dart';
import 'package:retail_verse_pos/features/inventory/data/models/category.dart' as inv;
import 'package:retail_verse_pos/features/inventory/data/local/category_local_service.dart';
import 'package:retail_verse_pos/features/dashboard/presentation/widgets/dashboard_widgets.dart';

inv.Category _entityToNavCategory(CategoryEntity e) {
  return inv.Category(
    id: e.id,
    name: e.name,
    subtitle: e.subtitle,
    imagePath: e.imagePath,
    productCount: e.productCount,
  );
}

class InventoryCategoriesScreen extends ConsumerStatefulWidget {
  const InventoryCategoriesScreen({super.key});

  @override
  ConsumerState<InventoryCategoriesScreen> createState() => _InventoryCategoriesScreenState();
}

class _InventoryCategoriesScreenState extends ConsumerState<InventoryCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CategoryLocalService _service = CategoryLocalService();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final role = user?['role'] ?? 'staff';
    final canManage = role == 'admin' || role == 'super_admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── PREMIUM SEARCH HEADER ──────────────────────
          PremiumSearchHeader(
            title: 'Inventory',
            searchBar: ModernSearchBar(
              controller: _searchController,
              hintText: 'Search categories...',
              onChanged: (v) => setState(() => _query = v),
              onClear: () => setState(() => _query = ''),
            ),
            actions: [
              if (canManage)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
                  onPressed: () => context.push('/inventory/categories/add'),
                ),
            ],
          ),

          Expanded(
            child: FutureBuilder<List<CategoryEntity>>(
              future: _service.getAllCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                final filtered = list.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();

                if (filtered.isEmpty) return _buildEmptyState();

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildCategoryCard(filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryEntity category) {
    return InkWell(
      onTap: () => context.push('/inventory/categories/products', extra: _entityToNavCategory(category)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
          border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.category_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 12),
            Text(category.name, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text('${category.productCount} Items', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: AppColors.textSecondary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('No categories found', style: AppTypography.headlineSmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
