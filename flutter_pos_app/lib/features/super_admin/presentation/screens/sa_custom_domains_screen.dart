import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retail_verse_pos/core/theme/app_colors.dart';
import 'package:retail_verse_pos/core/theme/app_typography.dart';
import 'package:retail_verse_pos/data/remote/super_admin_service.dart';
import 'package:retail_verse_pos/features/dashboard/presentation/widgets/dashboard_widgets.dart';

class SaCustomDomainsScreen extends ConsumerStatefulWidget {
  const SaCustomDomainsScreen({super.key});

  @override
  ConsumerState<SaCustomDomainsScreen> createState() => _SaCustomDomainsScreenState();
}

class _SaCustomDomainsScreenState extends ConsumerState<SaCustomDomainsScreen> {
  final _superAdminService = SuperAdminService();
  final _domainController = TextEditingController();

  List<Map<String, dynamic>> _businesses = [];
  List<Map<String, dynamic>> _domains = [];
  String? _selectedBusinessId;

  bool _isLoading = true;
  bool _isSubmitting = false;

  Map<String, dynamic>? _lastAddedDomain;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final businesses = await _superAdminService.listBusinesses();
      final domains = await _superAdminService.listCustomDomains();
      if (mounted) {
        setState(() {
          _businesses = businesses;
          _domains = domains;
          if (_businesses.isNotEmpty && _selectedBusinessId == null) {
            _selectedBusinessId = _businesses.first['id']?.toString() ?? _businesses.first['_id']?.toString();
          }
        });
      }
    } catch (e) {
      if (mounted) _showError('Failed to load data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _addDomain() async {
    if (_selectedBusinessId == null) {
      _showError('Please select a business');
      return;
    }
    final domain = _domainController.text.trim();
    if (domain.isEmpty) {
      _showError('Please enter a domain');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final newDomain = await _superAdminService.addCustomDomain(
        businessId: _selectedBusinessId!,
        domain: domain,
      );
      _domainController.clear();
      _showSuccess('Domain added. Please configure DNS.');
      setState(() => _lastAddedDomain = newDomain);
      await _loadData();
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                Text('Domain Manager', style: AppTypography.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
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
                        child: const Icon(Icons.language_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Platform White-label Infrastructure',
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
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                    children: [
                      _buildConnectCard(),
                      if (_lastAddedDomain != null) ...[
                        const SizedBox(height: 24),
                        _buildDnsInstructionCard(_lastAddedDomain!),
                      ],
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Active Infrastructure', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                          _buildBadge(_domains.length.toString(), AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_domains.isEmpty)
                        _buildEmptyState()
                      else
                        ..._domains.map((d) => _buildModernDomainCard(d)),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildConnectCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Link New Domain', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          _buildModernDropdown(),
          const SizedBox(height: 16),
          _buildModernTextField(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _addDomain,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Connect Domain', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBusinessId,
      decoration: InputDecoration(
        labelText: 'Select Business',
        prefixIcon: const Icon(Icons.business_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: AppColors.backgroundSecondary.withOpacity(0.5),
      ),
      items: _businesses.map((b) {
        final name = b['businessName']?.toString() ?? 'Unnamed';
        return DropdownMenuItem(value: b['id']?.toString() ?? b['_id']?.toString(), child: Text(name));
      }).toList(),
      onChanged: (v) => setState(() => _selectedBusinessId = v),
      isExpanded: true,
    );
  }

  Widget _buildModernTextField() {
    return TextField(
      controller: _domainController,
      decoration: InputDecoration(
        labelText: 'Domain Name',
        hintText: 'e.g. shop.client.com',
        prefixIcon: const Icon(Icons.link_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: AppColors.backgroundSecondary.withOpacity(0.5),
      ),
    );
  }

  Future<void> _verifyDomain(String id) async {
    try {
      await _superAdminService.verifyCustomDomain(id);
      _showSuccess('Domain verified successfully');
      _loadData();
    } catch (e) {
      _showError('Verification failed: $e');
    }
  }

  Future<void> _activateDomain(String id) async {
    try {
      await _superAdminService.activateCustomDomain(id);
      _showSuccess('Domain activated');
      _loadData();
    } catch (e) {
      _showError('Activation failed: $e');
    }
  }

  Future<void> _deleteDomain(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Domain?'),
        content: const Text('This will disconnect the domain from the business.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _superAdminService.deleteCustomDomain(id);
      _showSuccess('Domain deleted');
      _loadData();
    } catch (e) {
      _showError('Delete failed: $e');
    }
  }

  Widget _buildModernDomainCard(Map<String, dynamic> data) {
    final domain = data['domain'] ?? 'Unknown';
    final status = data['status']?.toString().toLowerCase() ?? 'pending';
    final id = data['id']?.toString() ?? data['_id']?.toString() ?? '';
    
    final isPending = status == 'pending';
    final isVerified = status == 'verified';
    final isActive = status == 'active';
    
    Color statusColor = AppColors.warning;
    if (isVerified) statusColor = Colors.blue;
    if (isActive) statusColor = AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.language_rounded, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(domain, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900)),
                    Text(status.toUpperCase(), style: AppTypography.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteDomain(id),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                style: IconButton.styleFrom(backgroundColor: AppColors.error.withOpacity(0.05)),
              ),
            ],
          ),
          if (!isActive) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                if (isPending)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _verifyDomain(id),
                      child: const Text('Verify DNS'),
                    ),
                  ),
                if (isVerified)
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _activateDomain(id),
                      child: const Text('Activate Domain'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDnsInstructionCard(Map<String, dynamic> domain) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Text('DNS Setup', style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _buildDnsField('CNAME', domain['dnsName'] ?? 'store', domain['dnsValue'] ?? 'app.retailverse.in'),
        ],
      ),
    );
  }

  Widget _buildDnsField(String type, String name, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: Text('$type: $name -> $value', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold))),
          IconButton(onPressed: () => Clipboard.setData(ClipboardData(text: value)), icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.link_off_rounded, size: 60, color: AppColors.textTertiary.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text('No domains linked yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
