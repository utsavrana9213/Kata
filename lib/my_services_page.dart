import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servekeen/add_service_page.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/service_model.dart';
import 'package:servekeen/service_detail_page.dart';
import 'package:servekeen/theme/palette.dart';

class MyServicesPage extends StatefulWidget {
  const MyServicesPage({super.key});

  @override
  State<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends State<MyServicesPage> {
  bool _loading = true;
  String? _error;
  List<Service> _services = [];
  final Map<String, String> _categoryNames = {};
  final Set<String> _updatingActive = {};
  final Map<String, bool> _activeOverrides = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _load();
  }

  Future<void> _loadCategories() async {
    if (_categoryNames.isNotEmpty) return;
    try {
      final data = await ApiService().fetchAppData();
      final categories = data['categories'];
      if (categories is List) {
        for (final c in categories) {
          if (c is Map) {
            final id = (c['id'] ?? '').toString().trim();
            final name = (c['category_name'] ?? c['name'] ?? '')
                .toString()
                .trim();
            if (id.isNotEmpty && name.isNotEmpty) {
              _categoryNames[id] = name;
            }
          }
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService().fetchMyServices();
    if (!mounted) return;
    if (res['status'] == 'success' && res['services'] is List) {
      final raw = (res['services'] as List).cast<dynamic>();
      final parsed = <Service>[];
      for (final item in raw) {
        if (item is Map) {
          parsed.add(Service.fromJson(item.cast<String, dynamic>()));
        }
      }
      setState(() {
        _services = parsed;
        _activeOverrides.clear();
        _updatingActive.clear();
        _loading = false;
      });
      return;
    }
    setState(() {
      _error = (res['message'] ?? 'Failed to load services').toString();
      _loading = false;
    });
  }

  String _categoryLabel(Service s) {
    final raw = (s.categorys ?? '').trim();
    if (raw.isEmpty) return 'Category';
    final mapped = _categoryNames[raw];
    if (mapped != null && mapped.trim().isNotEmpty) return mapped.trim();
    return raw;
  }

  String _formatPrice(Service s) {
    final p = s.price;
    if (p == null) return '';
    final formatted = p.toStringAsFixed(p == p.roundToDouble() ? 0 : 2);
    return '₹$formatted';
  }

  bool _isActive(Service s) {
    return _activeOverrides[s.id] ?? (s.isActive ?? true);
  }

  Future<void> _setActive(Service s, bool value) async {
    if (_updatingActive.contains(s.id)) return;
    final previous = _isActive(s);
    setState(() {
      _updatingActive.add(s.id);
      _activeOverrides[s.id] = value;
    });
    final res = await ApiService().updateService(s.id, {
      'is_active': value ? 1 : 0,
    });
    if (!mounted) return;
    if (res['status'] == 'success') {
      setState(() {
        _updatingActive.remove(s.id);
      });
      await _load();
      return;
    }
    setState(() {
      _updatingActive.remove(s.id);
      _activeOverrides[s.id] = previous;
    });
    final msg = (res['message'] ?? 'Failed to update status').toString();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.poppins())));
  }

  Future<void> _openEdit(Service s) async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => AddServicePage(service: s)));
    if (!mounted) return;
    if (updated == true) {
      await _load();
    }
  }

  void _openDetails(Service s) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ServiceDetailPage(service: s)),
    );
  }

  Widget _buildServiceCard(Service s) {
    final titleStyle = GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    );
    final metaStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );
    final priceStyle = GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF2F80ED),
    );
    final imageUrl = s.primaryImageUrl;
    final localAsset = s.localAssetImage;
    final isUpdating = _updatingActive.contains(s.id);
    final active = _isActive(s);
    final tier = s.priceTier;

    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: imageUrl == null
                        ? Container(
                            color: Colors.grey.shade200,
                            child: localAsset != null
                                ? Image.asset(localAsset, fit: BoxFit.contain)
                                : null,
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: localAsset != null
                                  ? Image.asset(localAsset, fit: BoxFit.contain)
                                  : null,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(s.serviceName, style: titleStyle),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _categoryLabel(s),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (tier != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: s.isPremium
                          ? AppPalette.fusionPurple
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tier,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: s.isPremium ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Text(_formatPrice(s), style: priceStyle)),
                Text('Active', style: metaStyle),
                const SizedBox(width: 10),
                AbsorbPointer(
                  absorbing: isUpdating,
                  child: Switch(
                    value: active,
                    onChanged: (v) => _setActive(s, v),
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF2F80ED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openEdit(s),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDetails(s),
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                    label: Text(
                      'View Details',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAdd() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddServicePage()));
    if (!mounted) return;
    if (created == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Services',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      _error!,
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ),
                ],
              )
            : _services.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No services yet',
                      style: GoogleFonts.poppins(color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _openAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('Add your first service'),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final s = _services[index];
                  return _buildServiceCard(s);
                },
              ),
      ),
    );
  }
}
