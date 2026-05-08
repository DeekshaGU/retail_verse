import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:retail_verse_pos/core/theme/app_colors.dart';
import 'package:retail_verse_pos/core/theme/app_typography.dart';
import 'package:retail_verse_pos/data/remote/super_admin_service.dart';
import 'package:retail_verse_pos/features/dashboard/presentation/widgets/dashboard_widgets.dart';

class SaBusinessesScreen extends StatefulWidget {
  const SaBusinessesScreen({super.key});

  @override
  State<SaBusinessesScreen> createState() => _SaBusinessesScreenState();
}

class _SaBusinessesScreenState extends State<SaBusinessesScreen> {
  final _svc = SuperAdminService();
  late Future<Map<String, dynamic>> _f;
  final _searchC = TextEditingController();
  String _searchQ = '';

  @override
  void initState() {
    super.initState();
    _f = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final res = await Future.wait([
      _svc.listBusinesses(),
      _svc.listCustomDomains(),
      _svc.getAnalyticsSummary(),
    ]);
    return {
      'businesses': res[0] as List<Map<String, dynamic>>,
      'domains': res[1] as List<Map<String, dynamic>>,
      'analytics': res[2] as Map<String, dynamic>,
    };
  }

  Future<void> _openAddBusiness() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => const _AddBusinessSheet(),
    );
    if (!mounted) return;
    if (saved == true) {
      setState(() => _f = _loadData());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business created successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── PREMIUM HEADER ─────────────────────────────
          PremiumSearchHeader(
            title: 'Platform Clients',
            actions: [
              IconButton(
                onPressed: _openAddBusiness,
                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
              ),
            ],
            searchBar: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _searchC,
                onChanged: (v) => setState(() => _searchQ = v.trim().toLowerCase()),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search business name or ID...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _f,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                final data = snap.data ?? {};
                final businesses = (data['businesses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                final domains = (data['domains'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                final filtered = businesses.where((b) {
                  if (_searchQ.isEmpty) return true;
                  final name = b['businessName']?.toString().toLowerCase() ?? '';
                  final id = b['businessId']?.toString().toLowerCase() ?? '';
                  return name.contains(_searchQ) || id.contains(_searchQ);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business_rounded, size: 80, color: AppColors.textTertiary.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text('No businesses found', style: AppTypography.headlineSmall.copyWith(color: AppColors.textTertiary)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() => _f = _loadData()),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final b = filtered[index];
                      // Match domain logic
                      final bId = b['id']?.toString() ?? b['_id']?.toString() ?? '';
                      final domainObj = domains.cast<Map<String, dynamic>?>().firstWhere(
                        (d) => d?['businessId'] == bId,
                        orElse: () => null
                      );
                      return _BusinessModernCard(business: b, domain: domainObj);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessModernCard extends StatelessWidget {
  final Map<String, dynamic> business;
  final Map<String, dynamic>? domain;

  const _BusinessModernCard({required this.business, this.domain});

  @override
  Widget build(BuildContext context) {
    final name = business['businessName'] ?? 'Unnamed Business';
    final owner = business['ownerName'] ?? 'No owner';
    final email = business['ownerEmail'] ?? '';
    final status = business['status'] ?? 'active';
    final plan = business['subscriptionPlan'] ?? 'free';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.store_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      owner,
                      style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const Divider(height: 32),
          if (email.isNotEmpty)
            _buildInfoRow(Icons.email_outlined, email),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTag(plan.toUpperCase(), AppColors.primary),
              const SizedBox(width: 8),
              if (domain != null)
                _buildTag(domain!['domain'], AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final active = status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: active ? AppColors.success : AppColors.error,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(text, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AddBusinessSheet extends StatefulWidget {
  const _AddBusinessSheet();

  @override
  State<_AddBusinessSheet> createState() => _AddBusinessSheetState();
}

class _AddBusinessSheetState extends State<_AddBusinessSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _owner = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _svc = SuperAdminService();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _owner.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _svc.createBusiness(
        businessName: _name.text,
        ownerName: _owner.text,
        ownerEmail: _email.text,
        phone: _phone.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Register New Client', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              _buildField(_name, 'Business Name', Icons.business_rounded, required: true),
              const SizedBox(height: 16),
              _buildField(_owner, 'Owner Name', Icons.person_outline_rounded),
              const SizedBox(height: 16),
              _buildField(_email, 'Owner Email', Icons.email_outlined),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Business', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool required = false}) {
    return TextFormField(
      controller: controller,
      validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: AppColors.backgroundSecondary.withOpacity(0.5),
      ),
    );
  }
}
