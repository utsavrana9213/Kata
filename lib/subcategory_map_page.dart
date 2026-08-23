import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/service_model.dart';
import 'package:servekeen/service_detail_page.dart';
import 'package:servekeen/theme/palette.dart';

class SubcategoryMapPage extends StatefulWidget {
  final String categoryId;
  final String subcategoryId;
  final String subcategoryName;

  const SubcategoryMapPage({
    super.key,
    required this.categoryId,
    required this.subcategoryId,
    required this.subcategoryName,
  });

  @override
  State<SubcategoryMapPage> createState() => _SubcategoryMapPageState();
}

class _SubcategoryMapPageState extends State<SubcategoryMapPage> {
  final List<Service> _services = [];
  LatLng? _userPos;
  bool _loading = true;
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadUserPos();
    final list = await ApiService().fetchServicesByCategoryId(
      widget.categoryId,
      subcategoryId: widget.subcategoryId,
    );
    setState(() {
      _services.clear();
      _services.addAll(list);
      _services.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
      _loading = false;
    });
  }

  Future<void> _loadUserPos() async {
    final sp = await SharedPreferences.getInstance();
    final lat = sp.getDouble('user_lat');
    final lng = sp.getDouble('user_lng');
    if (lat != null && lng != null) {
      _userPos = LatLng(lat, lng);
    } else {
      _userPos = const LatLng(13.0827, 80.2707);
    }
  }

  double _distanceTo(Service s) {
    if (_userPos == null || s.lati == null || s.lngi == null) {
      return double.infinity;
    }
    return _haversine(
      _userPos!.latitude,
      _userPos!.longitude,
      s.lati!,
      s.lngi!,
    );
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double d) => d * math.pi / 180.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subcategoryName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppPalette.deepBlue,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildMap()),
                _buildNearestList(),
              ],
            ),
    );
  }

  Widget _buildMap() {
    final center = _userPos ?? const LatLng(13.0827, 80.2707);
    final markers = <Marker>{};
    if (_userPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: _userPos!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    }
    for (final s in _services) {
      if (s.lati != null && s.lngi != null) {
        markers.add(
          Marker(
            markerId: MarkerId('s_${s.id}'),
            position: LatLng(s.lati!, s.lngi!),
            infoWindow: InfoWindow(
              title: s.companyName,
              snippet: s.serviceName,
            ),
          ),
        );
      }
    }
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: center, zoom: 12),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (c) => _controller = c,
    );
  }

  Widget _buildNearestList() {
    final items = _services
        .where((s) => s.lati != null && s.lngi != null)
        .map((s) => _NearestItem(service: s, distanceKm: _distanceTo(s)))
        .toList();
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final tier = item.service.priceTier;
          return ListTile(
            title: Text(
              item.service.serviceName,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${item.service.companyName} • ${item.distanceKm.toStringAsFixed(2)} km',
              style: GoogleFonts.poppins(color: Colors.black54),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tier != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.service.isPremium
                          ? AppPalette.fusionPurple
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tier,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: item.service.isPremium
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                if (tier != null) const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              final s = item.service;
              if (s.lati != null && s.lngi != null) {
                _controller?.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(s.lati!, s.lngi!), 15),
                );
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailPage(service: s),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NearestItem {
  final Service service;
  final double distanceKm;
  _NearestItem({required this.service, required this.distanceKm});
}
