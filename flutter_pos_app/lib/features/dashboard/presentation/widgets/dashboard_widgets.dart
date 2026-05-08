import 'package:flutter/material.dart';
import 'package:retail_verse_pos/core/theme/app_colors.dart';
import 'package:retail_verse_pos/core/theme/app_typography.dart';
import 'package:retail_verse_pos/core/utils/formatters.dart';

// ── 1. PREMIUM HERO HEADER ─────────────────────
class PremiumHeroHeader extends StatelessWidget {
  final String userName;
  final double totalSales;
  final int totalOrders;
  final List<Widget>? actions;
  final String? subtitle;

  const PremiumHeroHeader({
    super.key,
    required this.userName,
    this.totalSales = 0,
    this.totalOrders = 0,
    this.actions,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.accent, // Dark Navy
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
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
                  Text(subtitle ?? 'Good morning,',
                      style: AppTypography.bodyLarge.copyWith(color: Colors.white70)),
                  Text(userName,
                      style: AppTypography.displaySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                ],
              ),
              if (actions != null) Row(children: actions!) else 
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // GLASS SUMMARY CONTAINER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                _buildSummaryItem('Revenue', AppFormatters.formatCurrency(totalSales)),
                _buildDivider(),
                _buildSummaryItem('Orders', totalOrders.toString()),
                _buildDivider(),
                _buildStatusItem(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTypography.labelMedium.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppTypography.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 8));
  }

  Widget _buildStatusItem() {
    return Expanded(
      child: Column(
        children: [
          Text('Status', style: AppTypography.labelMedium.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('LIVE', style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 2. PREMIUM SEARCH HEADER ──────────────────
class PremiumSearchHeader extends StatelessWidget {
  final String title;
  final Widget searchBar;
  final Widget? bottom;
  final List<Widget>? actions;

  const PremiumSearchHeader({
    super.key,
    required this.title,
    required this.searchBar,
    this.bottom,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.accent, // Dark Navy
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.displaySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
              if (actions != null) Row(children: actions!),
            ],
          ),
          const SizedBox(height: 20),
          searchBar,
          if (bottom != null) ...[
            const SizedBox(height: 20),
            bottom!,
          ],
        ],
      ),
    );
  }
}

// ── 3. SAAS KPI CARD ──────────────────────
class SaaSKPICard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const SaaSKPICard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
          ],
          border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                if (subtitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(subtitle!, style: AppTypography.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 4),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── 4. PREMIUM SECTION CARD ──────────────────
class PremiumSectionCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsets? padding;

  const PremiumSectionCard({super.key, required this.child, this.title, this.padding});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(title!, style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
            ],
            border: Border.all(color: AppColors.cardBorder.withOpacity(0.6)),
          ),
          child: child,
        ),
      ],
    );
  }
}

// ── 5. PREMIUM FLOATING NAV BAR ──────────────
class PremiumFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<PremiumNavItem> items;
  final Function(int) onDestinationSelected;

  const PremiumFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.accent, // Dark Navy
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onDestinationSelected(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isSelected ? items[index].selectedIcon : items[index].icon,
                      color: isSelected ? AppColors.primary : Colors.white70,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[index].label,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected ? AppColors.primary : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class PremiumNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const PremiumNavItem({required this.label, required this.icon, required this.selectedIcon});
}

// ── 6. SECTION HEADER ─────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onActionTap;
  final String? actionLabel;

  const SectionHeader({
    super.key,
    required this.title,
    this.onActionTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900)),
          if (onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              child: Text(actionLabel ?? 'View All',
                  style: AppTypography.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
