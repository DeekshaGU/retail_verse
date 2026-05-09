import 'package:flutter/material.dart';
import 'package:retail_verse_pos/core/theme/app_colors.dart';
import 'package:retail_verse_pos/core/theme/app_typography.dart';
import 'package:retail_verse_pos/data/remote/super_admin_service.dart';
import 'package:retail_verse_pos/features/dashboard/presentation/widgets/dashboard_widgets.dart';

class SaLogsScreen extends StatefulWidget {
  const SaLogsScreen({super.key});

  @override
  State<SaLogsScreen> createState() => _SaLogsScreenState();
}

class _SaLogsScreenState extends State<SaLogsScreen> {
  final _svc = SuperAdminService();
  late Future<List<Map<String, dynamic>>> _f;

  @override
  void initState() {
    super.initState();
    _f = _svc.listAuditLogs(limit: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── PREMIUM INTEGRATED HEADER ──────────────────
          Container(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Platform Audit', style: AppTypography.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.history_toggle_off_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Monitoring Enterprise Activity',
                          style: AppTypography.bodyMedium.copyWith(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _f,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() => _f = _svc.listAuditLogs(limit: 100)),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _buildModernLogTile(items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLogTile(Map<String, dynamic> l) {
    final action = l['action']?.toString() ?? 'SYSTEM_EVENT';
    final actor = l['actorEmail']?.toString() ?? 'SYSTEM';
    final at = l['createdAt']?.toString() ?? '';
    final biz = l['businessId']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.terminal_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('By $actor ${biz.isNotEmpty ? "• Biz: $biz" : ""}', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(at, style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list_alt_rounded, size: 80, color: AppColors.textTertiary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('No logs available', style: AppTypography.headlineSmall.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
