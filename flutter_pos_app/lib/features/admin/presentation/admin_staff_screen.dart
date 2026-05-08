import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/remote/admin_users_service.dart';

/// Admin-only: list staff, create accounts with roles, change roles.
class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  final _service = AdminUsersService();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  /// Business admin may create only these roles (matches backend).
  static const _staffRoles = ['cashier', 'inventory_manager'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.listUsers();
      if (mounted) {
        setState(() {
          _users = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is ApiException ? e.message : e.toString();
        });
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    var role = _staffRoles.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: const Text('Create staff user'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Phone (optional)',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Password (min 6 chars)',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Role', style: AppTypography.labelMedium),
                  ),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: role,
                    items: _staffRoles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.replaceAll('_', ' ')),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => role = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true || !mounted) {
      nameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
      passCtrl.dispose();
      return;
    }

    try {
      await _service.createStaff(
        name: nameCtrl.text,
        email: emailCtrl.text,
        phone: phoneCtrl.text,
        password: passCtrl.text,
        role: role,
      );
      nameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
      passCtrl.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created')),
        );
        await _load();
      }
    } catch (e) {
      nameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
      passCtrl.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : '$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _changeRole(Map<String, dynamic> user) async {
    final id = user['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final currentRole = user['role']?.toString() ?? '';
    if (!_staffRoles.contains(currentRole)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Administrator roles cannot be changed here'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    var role = _staffRoles.contains(currentRole) ? currentRole : 'cashier';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text('Role · ${user['email']}'),
            content: DropdownButton<String>(
              isExpanded: true,
              value: _staffRoles.contains(role) ? role : 'cashier',
              items: _staffRoles
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.replaceAll('_', ' ')),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setLocal(() => role = v);
              },
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
          );
        },
      ),
    );

    if (ok != true || !mounted) return;

    try {
      await _service.updateUserRole(userId: id, role: role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role updated')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : '$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deactivateUser(Map<String, dynamic> user) async {
    final id = user['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final currentRole = user['role']?.toString() ?? '';
    if (!_staffRoles.contains(currentRole)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot deactivate administrator accounts here'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final isActive = user['isActive'] != false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isActive ? 'Deactivate user?' : 'Activate user?'),
        content: Text(
          isActive
              ? '${user['email']} will not be able to log in until reactivated.'
              : '${user['email']} will be able to log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      await _service.setUserActive(userId: id, isActive: !isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'User deactivated' : 'User activated'),
          ),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : '$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final id = user['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete team member?'),
        content: Text(
          'This will remove access for ${user['email']}. You can recreate the user later if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _service.deleteUser(userId: id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : '$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text('User management', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _showCreateDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add staff'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final u = _users[i];
                    final name = u['name']?.toString() ?? '';
                    final email = u['email']?.toString() ?? '';
                    final role = u['role']?.toString() ?? '';
                    final canEditStaff = _staffRoles.contains(role);
                    final isActive = u['isActive'] != false;
                    return Material(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        title: Text(
                          name.isEmpty ? email : name,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '$email · $role${isActive ? '' : ' · Inactive'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canEditStaff)
                              IconButton(
                                icon: Icon(
                                  isActive
                                      ? Icons.person_off_outlined
                                      : Icons.person_outline_rounded,
                                ),
                                onPressed: () => _deactivateUser(u),
                                tooltip: isActive ? 'Deactivate' : 'Activate',
                              ),
                            if (canEditStaff)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () => _deleteUser(u),
                                tooltip: 'Delete',
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: canEditStaff
                                  ? () => _changeRole(u)
                                  : null,
                              tooltip: canEditStaff
                                  ? 'Change role'
                                  : 'Role managed separately',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
