import 'dart:async';
import 'dart:math' as math;
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.accent, // Dark Navy
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
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
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.accent, // Dark Navy
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
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

// ── 7. MODERN LINE CHART ──────────────────
class ModernLineChart extends StatefulWidget {
  final String title;
  final String value;
  final String change;
  final List<double> data;
  final Color color;

  const ModernLineChart({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.data,
    this.color = AppColors.primary,
  });

  @override
  State<ModernLineChart> createState() => _ModernLineChartState();
}

class _ModernLineChartState extends State<ModernLineChart> with SingleTickerProviderStateMixin {
  late List<double> _currentData;
  late AnimationController _controller;
  bool _isLive = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentData = List.from(widget.data);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _toggleLive() {
    setState(() {
      _isLive = !_isLive;
    });

    if (_isLive) {
      _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        if (!mounted) return;
        setState(() {
          // Shift data left and add a new random point near the last one
          final last = _currentData.last;
          // Add a base fluctuation even if last is 0 to keep it "alive"
          final baseFluct = last == 0 ? 5.0 : (last * 0.1);
          final fluctuation = (math.Random().nextDouble() - 0.5) * baseFluct;
          _currentData.removeAt(0);
          _currentData.add((last + fluctuation).clamp(0.0, 1000000.0));
        });
      });
    } else {
      _timer?.cancel();
      setState(() {
        _currentData = List.from(widget.data);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleLive,
      borderRadius: BorderRadius.circular(32),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLive 
              ? [const Color(0xFF4F46E5), const Color(0xFF312E81)] 
              : [const Color(0xFF3730A3), const Color(0xFF312E81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withOpacity(_isLive ? 0.6 : 0.4), 
              blurRadius: _isLive ? 40 : 25, 
              spreadRadius: _isLive ? 5 : 0,
              offset: const Offset(0, 10)
            ),
          ],
          border: _isLive ? Border.all(color: Colors.white.withOpacity(0.3), width: 2) : null,
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
                    Row(
                      children: [
                        Text(widget.title, style: AppTypography.labelLarge.copyWith(color: Colors.white70)),
                        if (_isLive) ...[
                          const SizedBox(width: 8),
                          _LiveIndicator(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(widget.value, style: AppTypography.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(widget.change, style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 100,
              width: double.infinity,
              child: TweenAnimationBuilder<List<double>>(
                tween: _DataListTween(begin: widget.data, end: _currentData),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return CustomPaint(
                    painter: _LineChartPainter(data: value, color: Colors.white),
                  );
                },
              ),
            ),
            if (_isLive) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'LIVE TRACKING ACTIVE',
                  style: AppTypography.labelSmall.copyWith(color: Colors.white54, letterSpacing: 1, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LiveIndicator extends StatefulWidget {
  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
      ),
    );
  }
}

class _DataListTween extends Tween<List<double>> {
  _DataListTween({super.begin, super.end});

  @override
  List<double> lerp(double t) {
    if (begin == null || end == null) return end ?? [];
    final List<double> result = [];
    final length = math.min(begin!.length, end!.length);
    for (int i = 0; i < length; i++) {
      result.add(begin![i] + (end![i] - begin![i]) * t);
    }
    return result;
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _LineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final xStep = size.width / (data.length - 1);
    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    double getY(double val) => size.height - ((val - minVal) / range * size.height);

    path.moveTo(0, getY(data[0]));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, getY(data[0]));

    for (int i = 1; i < data.length; i++) {
      final x = i * xStep;
      final y = getY(data[i]);
      
      final prevX = (i - 1) * xStep;
      final prevY = getY(data[i - 1]);
      path.cubicTo(
        prevX + xStep / 2, prevY,
        x - xStep / 2, y,
        x, y,
      );
      fillPath.cubicTo(
        prevX + xStep / 2, prevY,
        x - xStep / 2, y,
        x, y,
      );
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
