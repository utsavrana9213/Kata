import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/category_services_page.dart';
import 'package:servekeen/service_detail_page.dart';
import 'package:servekeen/service_model.dart';
import 'package:servekeen/theme/palette.dart';
import 'package:geolocator/geolocator.dart';

import 'data/hierarchy_repository.dart';

class NearMePage extends StatefulWidget {
  const NearMePage({super.key});

  @override
  State<NearMePage> createState() => _NearMePageState();
}

class _NearMePageState extends State<NearMePage> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(13.0827, 80.2707);
  List<Service> _services = [];
  List<Map<String, String>> _categories = [];
  String? _selectedCategoryId;
  bool _loading = true;
  String? _error;
  bool _locationDenied = false;

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _backgroundColor =>
      _isDarkMode ? Colors.black : AppPalette.softBlendBackground;
  Color get _appBarSurface => _isDarkMode ? Colors.black : Colors.white;
  Color get _cardSurface =>
      _isDarkMode ? const Color(0xFF121212) : Colors.white;
  Color get _fieldSurface =>
      _isDarkMode ? const Color(0xFF151F2A) : Colors.white;
  Color get _mutedSurface =>
      _isDarkMode ? const Color(0xFF223142) : AppPalette.lightBlueTint;
  Color get _textPrimary =>
      _isDarkMode ? const Color(0xFFEAF2FC) : AppPalette.deepBlue;
  Color get _textSecondary => _isDarkMode
      ? const Color(0xFFB4C3D5)
      : AppPalette.deepBlue.withAlpha(150);
  Color get _brandColor =>
      _isDarkMode ? const Color(0xFF75AFFF) : AppPalette.fusionPurple;
  Color get _borderColor => _isDarkMode
      ? Colors.white.withAlpha(24)
      : AppPalette.deepBlue.withAlpha(26);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final sp = await SharedPreferences.getInstance();
    final lat = sp.getDouble('user_lat');
    final lng = sp.getDouble('user_lng');
    if (lat != null && lng != null) {
      _center = LatLng(lat, lng);
    }

    try {
      await _requestLocation();
      final data = await ApiService().fetchAppData();
      final categories = <Map<String, String>>[];
      final services = <Service>[];

      final rawCats = data['categories'];
      if (rawCats is List) {
        for (final c in rawCats) {
          if (c is Map) {
            final id = (c['id'] ?? '').toString();
            final name = (c['category_name'] ?? c['name'] ?? '').toString();
            if (id.isNotEmpty && name.isNotEmpty) {
              categories.add({'id': id, 'name': name});
            }
          }
        }
      }

      final rawServices = data['services'];
      if (rawServices is List) {
        for (final s in rawServices) {
          if (s is Map) {
            final service = Service.fromJson(s.cast<String, dynamic>());
            if (service.companyName.isNotEmpty &&
                service.serviceName.isNotEmpty) {
              services.add(service);
            }
          }
        }
      }

      if (services.isEmpty) {
        await HierarchyRepository().init();
        services.addAll(HierarchyRepository().getAllServices());
      }

      if (categories.isEmpty) {
        await HierarchyRepository().init();
        categories.addAll(
          HierarchyRepository().getCategories().map(
            (c) => {'id': c.id, 'name': c.name},
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _services = services;
        _loading = false;
      });
    } catch (_) {
      await HierarchyRepository().init();
      final fallbackServices = HierarchyRepository().getAllServices();
      if (mounted) {
        setState(() {
          _services = fallbackServices;
          _loading = false;
        });
      }
    }
  }

  Future<void> _requestLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _locationDenied = true;
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition();
      _center = LatLng(position.latitude, position.longitude);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('user_lat', position.latitude);
      await prefs.setDouble('user_lng', position.longitude);
    } catch (_) {
      _locationDenied = true;
    }
  }

  LatLng _getEffectiveLocation(Service s) {
    if (s.lati != null && s.lngi != null && s.lati != 0 && s.lngi != 0) {
      return LatLng(s.lati!, s.lngi!);
    }
    final hash = s.id.hashCode;
    final latOffset = ((hash % 100) - 50) * 0.0008;
    final lngOffset = (((hash ~/ 100) % 100) - 50) * 0.0008;
    return LatLng(_center.latitude + latOffset, _center.longitude + lngOffset);
  }

  List<Service> get _filteredServices {
    final query = _searchController.text.trim().toLowerCase();
    final items = _services.where((s) {
      final categoryOk =
          _selectedCategoryId == null ||
          s.categorys == _selectedCategoryId ||
          _selectedCategoryId!.isEmpty;
      final queryOk =
          query.isEmpty ||
          s.serviceName.toLowerCase().contains(query) ||
          s.companyName.toLowerCase().contains(query) ||
          (_categoryName(s.categorys) ?? '').toLowerCase().contains(query) ||
          (s.subcategory ?? '').toLowerCase().contains(query) ||
          (s.locations ?? '').toLowerCase().contains(query) ||
          (s.address ?? '').toLowerCase().contains(query);
      return categoryOk && queryOk;
    }).toList();
    items.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    return items;
  }

  double _distanceTo(Service s) {
    final pos = _getEffectiveLocation(s);
    return _haversine(
      _center.latitude,
      _center.longitude,
      pos.latitude,
      pos.longitude,
    );
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _deg2rad(double d) => d * math.pi / 180.0;

  String? _categoryName(String? categoryId) {
    final id = (categoryId ?? '').trim();
    if (id.isEmpty) return null;
    for (final c in _categories) {
      if (c['id'] == id) return c['name'];
    }
    return HierarchyRepository().categoryNameFor(id);
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredServices;
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Near Me',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        backgroundColor: _appBarSurface,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry loading Near Me'),
              ),
            )
          : Column(
              children: [
                if (_locationDenied)
                  Container(
                    width: double.infinity,
                    color: _mutedSurface,
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Location is unavailable. Showing vendors near Chennai; enable location for accurate distances.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                _buildSearchAndCategories(),
                SizedBox(
                  height: (MediaQuery.sizeOf(context).height * 0.28).clamp(
                    180.0,
                    240.0,
                  ),
                  child: _buildMap(items),
                ),
                Expanded(child: _buildVendorList(items)),
              ],
            ),
    );
  }

  Widget _buildSearchAndCategories() {
    return Container(
      color: _cardSurface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: GoogleFonts.poppins(color: _textPrimary),
            decoration: InputDecoration(
              hintText: 'Search vendors or services nearby',
              hintStyle: GoogleFonts.poppins(color: _textSecondary),
              prefixIcon: Icon(Icons.search, color: _textSecondary),
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: _searchController.clear,
                      icon: Icon(Icons.close, color: _textSecondary),
                    ),
              filled: true,
              fillColor: _fieldSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _borderColor),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isAll = index == 0;
                final id = isAll ? null : _categories[index - 1]['id'];
                final name = isAll ? 'All' : _categories[index - 1]['name']!;
                final selected = _selectedCategoryId == id;
                return ChoiceChip(
                  label: Text(name),
                  selected: selected,
                  selectedColor: AppPalette.fusionPurple,
                  labelStyle: GoogleFonts.poppins(
                    color: selected ? Colors.white : _textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: _fieldSurface,
                  shape: StadiumBorder(side: BorderSide(color: _borderColor)),
                  onSelected: (_) => setState(() => _selectedCategoryId = id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<Service> items) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('me'),
        position: _center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
      ),
      ...items.map((s) {
        final pos = _getEffectiveLocation(s);
        return Marker(
          markerId: MarkerId('vendor_${s.id}'),
          position: pos,
          infoWindow: InfoWindow(title: s.companyName, snippet: s.serviceName),
          onTap: () => _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(pos, 15),
          ),
        );
      }),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _center, zoom: 12),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (controller) => _mapController = controller,
    );
  }

  Widget _buildVendorList(List<Service> items) {
    if (items.isEmpty) {
      return Container(
        height: 92,
        alignment: Alignment.center,
        color: _backgroundColor,
        child: Text(
          'No nearby vendors found',
          style: GoogleFonts.poppins(color: _textSecondary),
        ),
      );
    }
    return ColoredBox(
      color: _backgroundColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final s = items[index];
          final category = _categoryName(s.categorys);
          return ListTile(
            tileColor: _cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _borderColor),
            ),
            leading: CircleAvatar(
              backgroundColor: _mutedSurface,
              child: Icon(Icons.place, color: _brandColor),
            ),
            title: Text(
              s.companyName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            subtitle: Text(
              '${s.serviceName}${category == null ? '' : ' • $category'} • ${_distanceTo(s).toStringAsFixed(2)} km',
              style: GoogleFonts.poppins(color: _textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(Icons.chevron_right, color: _textSecondary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailPage(service: s),
                ),
              );
            },
            onLongPress: () {
              if (s.categorys == null || s.categorys!.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryServicesPage(
                    categoryId: s.categorys!,
                    categoryName: category ?? 'Category',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
