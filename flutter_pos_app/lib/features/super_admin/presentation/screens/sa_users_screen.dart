import 'package:flutter/material.dart';
import 'package:retail_verse_pos/core/theme/app_colors.dart';
import 'package:retail_verse_pos/core/theme/app_typography.dart';
import 'package:retail_verse_pos/core/utils/validators.dart';
import 'package:retail_verse_pos/data/remote/admin_users_service.dart';
import 'package:retail_verse_pos/core/network/api_exception.dart';
import 'package:retail_verse_pos/data/remote/super_admin_service.dart';
import 'package:retail_verse_pos/features/dashboard/presentation/widgets/dashboard_widgets.dart';

class SaUsersScreen extends StatefulWidget {
  const SaUsersScreen({super.key});

  @override
  State<SaUsersScreen> createState() => _SaUsersScreenState();
}

class _SaUsersScreenState extends State<SaUsersScreen> {
  final _svc = SuperAdminService();
  late Future<List<Map<String, dynamic>>> _f;
  String _searchQ = '';
  final _searchC = TextEditingController();

  static const _assignableRoles = ['admin', 'client', 'cashier', 'inventory', 'user'];

  @override
  void initState() {
    super.initState();
    _f = _svc.listUsers();
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
      body: Column(
        children: [
          // ── PREMIUM INTEGRATED HEADER ──────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Teams', style: AppTypography.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                      IconButton(
                        onPressed: _openCreateUserDialog,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
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
                      onChanged: (v) => setState(() => _searchQ = v.trim().toLowerCase()),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
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

                final users = snap.data ?? [];
                final filtered = users.where((u) {
                  final name = u['name']?.toString().toLowerCase() ?? '';
                  final email = u['email']?.toString().toLowerCase() ?? '';
                  return name.contains(_searchQ) || email.contains(_searchQ);
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() => _f = _svc.listUsers()),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _buildModernUserCard(filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernUserCard(Map<String, dynamic> u) {
    final name = u['name']?.toString() ?? '';
    final email = u['email']?.toString() ?? '';
    final role = u['role']?.toString() ?? 'user';
    final active = u['isActive'] == true;
    final title = name.isEmpty ? email : name;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppColors.shadowSubtle,
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                ),
                child: CircleAvatar(
                  radius: constraints.maxWidth > 300 ? 28 : 24,
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  child: Text(
                    title.isNotEmpty ? title[0].toUpperCase() : '?',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w900, 
                      color: AppColors.primary,
                      fontSize: constraints.maxWidth > 300 ? 24 : 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(title, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                    ),
                    Text(email, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTag(role.toUpperCase(), AppColors.primary, Icons.verified_user_rounded),
                        _buildTag(active ? 'ACTIVE' : 'INACTIVE', active ? AppColors.success : AppColors.error, active ? Icons.check_circle_rounded : Icons.cancel_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              _buildActionMenu(u, active, email),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTag(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(text, style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildActionMenu(Map<String, dynamic> u, bool active, String email) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textTertiary),
      onSelected: (v) => _handleMenuAction(v, u, active, email),
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'toggle', child: Text(active ? 'Deactivate Member' : 'Activate Member')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'role:admin', child: Text('Assign Admin Role')),
        const PopupMenuItem(value: 'role:cashier', child: Text('Assign Cashier Role')),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'delete', child: Text('Remove from Team', style: TextStyle(color: AppColors.error))),
      ],
    );
  }

  Future<void> _handleMenuAction(String v, Map<String, dynamic> u, bool active, String email) async {
    final id = u['_id']?.toString() ?? u['id']?.toString() ?? '';
    if (id.isEmpty) return;

    try {
      if (v == 'toggle') {
        await _svc.updateUserStatus(userId: id, isActive: !active);
      } else if (v == 'delete') {
        final confirm = await _showConfirmDialog(email);
        if (confirm != true) return;
        await _svc.deleteUser(userId: id);
      } else if (v.startsWith('role:')) {
        await _svc.updateUserRole(userId: id, role: v.substring(5));
      }
      if (mounted) {
        setState(() => _f = _svc.listUsers());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated successfully'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<bool?> _showConfirmDialog(String email) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Access for $email will be revoked immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Remove')),
        ],
      ),
    );
  }

  Future<void> _openCreateUserDialog() async {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();
    var role = _assignableRoles.first;
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add Team Member'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField(nameC, 'Name', Icons.person_outline),
                  const SizedBox(height: 12),
                  _buildField(emailC, 'Email', Icons.email_outlined),
                  const SizedBox(height: 12),
                  _buildField(passC, 'Temporary Password', Icons.lock_outline, obscure: true),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: _assignableRoles.map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                    onChanged: (v) => setLocal(() => role = v!),
                    decoration: const InputDecoration(labelText: 'System Role', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      ),
    );

    if (ok == true) {
      try {
        await _svc.createUser(name: nameC.text, email: emailC.text, password: passC.text, role: role);
        if (mounted) setState(() => _f = _svc.listUsers());
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool obscure = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: AppColors.textTertiary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('No team members found', style: AppTypography.headlineSmall.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
