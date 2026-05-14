import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/service_model.dart';
import 'package:servekeen/service_stats_page.dart';

class VendorStatisticsPage extends StatefulWidget {
  const VendorStatisticsPage({super.key});

  @override
  State<VendorStatisticsPage> createState() => _VendorStatisticsPageState();
}

class _VendorStatisticsPageState extends State<VendorStatisticsPage> {
  bool _loading = true;
  String? _error;
  List<Service> _services = [];
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final q = _searchController.text.trim().toLowerCase();
    if (q == _query) return;
    setState(() {
      _query = q;
    });
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
        _loading = false;
      });
      return;
    }
    setState(() {
      _error = (res['message'] ?? 'Failed to load services').toString();
      _loading = false;
    });
  }

  List<Service> _filtered() {
    final q = _query;
    if (q.isEmpty) return _services;
    return _services.where((s) {
      final name = s.serviceName.toLowerCase();
      final company = s.companyName.toLowerCase();
      final location = (s.locations ?? '').toLowerCase();
      final address = (s.address ?? '').toLowerCase();
      return name.contains(q) || company.contains(q) || location.contains(q) || address.contains(q);
    }).toList();
  }

  String _priceLabel(Service s) {
    final p = s.price;
    if (p == null) return '';
    return '₹${p.toStringAsFixed(p == p.roundToDouble() ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text(_error!, style: GoogleFonts.poppins(color: Colors.red))),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search your services...',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: Colors.black54),
                            suffixIcon: _searchController.text.trim().isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      FocusScope.of(context).unfocus();
                                    },
                                    icon: const Icon(Icons.close, color: Colors.black54),
                                  ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Services (${filtered.length})',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Center(child: Text('No services found', style: GoogleFonts.poppins(color: Colors.black54))),
                        )
                      else
                        ...filtered.map((s) {
                          final tier = s.priceTier;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                title: Text(s.serviceName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  [
                                    s.companyName,
                                    if ((s.locations ?? '').toString().trim().isNotEmpty) s.locations!,
                                  ].join(' • '),
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (tier != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: s.isPremium ? Colors.deepPurple : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          tier,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: s.isPremium ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    if (tier != null) const SizedBox(width: 8),
                                    if (s.price != null) Text(_priceLabel(s), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ServiceStatsPage(service: s)),
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}
