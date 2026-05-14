import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/service_model.dart';

class ServiceStatsPage extends StatefulWidget {
  final Service service;
  const ServiceStatsPage({super.key, required this.service});

  @override
  State<ServiceStatsPage> createState() => _ServiceStatsPageState();
}

class _ServiceStatsPageState extends State<ServiceStatsPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _stats;

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
    final res = await ApiService().fetchServiceStats(widget.service.id);
    if (!mounted) return;
    if (res['status'] == 'success') {
      setState(() {
        _stats = (res['stats'] as Map?)?.cast<String, dynamic>() ?? {};
        _loading = false;
      });
      return;
    }
    setState(() {
      _error = (res['message'] ?? 'Failed to load stats').toString();
      _loading = false;
    });
  }

  int _count(String key) {
    final v = _stats?[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Widget _tile(IconData icon, String label, String key) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade100,
          foregroundColor: Colors.black87,
          child: Icon(icon),
        ),
        title: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        trailing: Text(
          _count(key).toString(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
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
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.serviceName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                              const SizedBox(height: 6),
                              Text(s.companyName, style: GoogleFonts.poppins(color: Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Interactions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _tile(Icons.remove_red_eye_outlined, 'View Details', 'view_details'),
                      _tile(Icons.phone_outlined, 'Phone Clicks', 'tap_phone'),
                      _tile(Icons.email_outlined, 'Email Clicks', 'tap_email'),
                      _tile(Icons.web_outlined, 'Website Clicks', 'tap_website'),
                      _tile(Icons.map_outlined, 'Map Clicks', 'tap_map'),
                      _tile(Icons.chat_outlined, 'WhatsApp Clicks', 'tap_whatsapp'),
                    ],
                  ),
      ),
    );
  }
}
