import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/navigation/role_nav.dart';
import '../../../../core/navigation/role_route_guard.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/product_thumbnail.dart';
import '../../../../data/models/product_model.dart' as api;
import '../../../auth/providers/auth_provider.dart';
import '../../../dashboard/providers/dashboard_providers.dart';
import '../../../pos/providers/product_providers.dart';
import '../../data/models/category.dart';

/// Category products loaded from GET /products (filtered by category name).
class CategoryProductsScreen extends ConsumerStatefulWidget {
  final Category category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<api.Product> _filter(List<api.Product> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q);
    }).toList();
  }

  int _inStockCount(List<api.Product> list) =>
      list.where((p) => p.stock > 10).length;

  int _lowStockCount(List<api.Product> list) => list
      .where((p) => p.stock > 0 && p.stock <= 10)
      .length;

  Future<void> _navigateToAddProduct() async {
    final role = effectiveUserRole(ref.read(authProvider).user);
    if (role != 'admin') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admin can add products.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    await context.push(
      '/inventory/${widget.category.id}/add-product',
      extra: widget.category,
    );
    if (mounted) {
      ref.invalidate(categoryProductsProvider(widget.category.name));
    }
  }

  Future<void> _deleteProduct(api.Product product) async {
    try {
      await ref.read(productRepositoryProvider).deleteProduct(product.id);
      if (mounted) {
        ref.invalidate(categoryProductsProvider(widget.category.name));
        ref.invalidate(productsProvider);
        invalidateAllDashboardProviders(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} removed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException
            ? (e.statusCode == 403
                ? 'No permission to delete products (inventory role required).'
                : e.message)
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _editProduct(api.Product product) async {
    final role = effectiveUserRole(ref.read(authProvider).user);
    final isInventoryManager = role == 'inventory_manager';
    final nameCtrl = TextEditingController(text: product.name);
    final descCtrl = TextEditingController(text: product.description ?? '');
    final priceCtrl = TextEditingController(text: product.price.toString());
    final stockCtrl = TextEditingController(text: product.stock.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(product.name, style: AppTypography.titleSmall),
            const SizedBox(height: 12),
            if (isInventoryManager) ...[
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                minLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ] else ...[
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockCtrl,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      if (isInventoryManager) {
        await ref.read(productRepositoryProvider).updateProduct(
              id: product.id,
              name: nameCtrl.text.trim(),
              description: descCtrl.text.trim(),
            );
      } else {
        final price = double.tryParse(priceCtrl.text.trim());
        final stock = int.tryParse(stockCtrl.text.trim());
        await ref.read(productRepositoryProvider).updateProduct(
              id: product.id,
              price: price,
              stock: stock,
            );
      }
      ref.invalidate(categoryProductsProvider(widget.category.name));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      nameCtrl.dispose();
      descCtrl.dispose();
      priceCtrl.dispose();
      stockCtrl.dispose();
    }
  }

  void _showProductMenu(BuildContext context, api.Product product) {
    final role = effectiveUserRole(ref.read(authProvider).user);
    final canDelete = role == 'admin';
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(role == 'inventory_manager' ? 'Edit name & description' : 'Edit'),
              onTap: () {
                Navigator.pop(ctx);
                _editProduct(product);
              },
            ),
            if (canDelete)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Delete', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog<void>(
                    context: context,
                    builder: (dctx) => AlertDialog(
                      title: const Text('Delete product?'),
                      content: Text('Remove "${product.name}" from the store?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dctx),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(dctx);
                            _deleteProduct(product);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = effectiveUserRole(ref.watch(authProvider).user);
    final canAccessInventory = canAccessInventoryManagement(role);
    final canAddProduct = role == 'admin';
    final async = ref.watch(categoryProductsProvider(widget.category.name));

    if (!canAccessInventory) {
      return RoleAccessDeniedView(onGoHome: () => context.go('/dashboard'));
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primary,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.category.name,
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          if (canAddProduct)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: _navigateToAddProduct,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load products\n$e',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ),
        data: (all) {
          final filtered = _filter(all);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(categoryProductsProvider(widget.category.name));
              await ref.read(
                categoryProductsProvider(widget.category.name).future,
              );
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Total',
                          value: all.length.toString(),
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Well stocked',
                          subtitle: '>10 units',
                          value: _inStockCount(all).toString(),
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Low Stock',
                          value: _lowStockCount(all).toString(),
                          icon: Icons.warning_outlined,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppColors.textTertiary,
                            ),
                            SizedBox(height: 16),
                            Center(
                              child: Text('No products in this category'),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            return _ProductCard(
                              product: product,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${product.name} · SKU ${product.sku}',
                                    ),
                                  ),
                                );
                              },
                              onMenuTap: () => _showProductMenu(context, product),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final api.Product product;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onMenuTap,
  });

  Color _statusColor() {
    if (product.stock > 10) return AppColors.success;
    if (product.stock > 0) return AppColors.warning;
    return AppColors.error;
  }

  String _statusText() {
    if (product.stock > 10) return 'In Stock';
    if (product.stock > 0) return 'Low Stock';
    return 'Out of Stock';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final statusText = _statusText();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ProductThumbnail(
                  imageUrl: product.imageUrl,
                  size: 80,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.sku,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(2)}',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.stock} units available',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onMenuTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundTertiary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
