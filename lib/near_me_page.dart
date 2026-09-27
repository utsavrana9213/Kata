import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/service_detail_page.dart';
import 'package:servekeen/service_model.dart';
import 'package:servekeen/theme/palette.dart';
import 'package:geolocator/geolocator.dart';
import 'package:servekeen/location_picker_page.dart';

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
  bool _hasLocationPermission = false;
  bool _showMap = true;
  double _radiusKm = 25;

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
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _locationDenied = true;
      _hasLocationPermission = false;
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _locationDenied = true;
      _hasLocationPermission = false;
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _center = LatLng(position.latitude, position.longitude);
      _locationDenied = false;
      _hasLocationPermission = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('user_lat', position.latitude);
      await prefs.setDouble('user_lng', position.longitude);
    } catch (_) {
      _locationDenied = true;
      _hasLocationPermission = false;
    }
  }

  LatLng? _getEffectiveLocation(Service s) {
    if (s.lati != null && s.lngi != null && s.lati != 0 && s.lngi != 0) {
      return LatLng(s.lati!, s.lngi!);
    }
    return null;
  }

  List<Service> get _filteredServices {
    final query = _searchController.text.trim().toLowerCase();
    final items = _services.where((s) {
      final distance = _distanceTo(s);
      if (distance == null || distance > _radiusKm) return false;
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
    items.sort((a, b) => _distanceTo(a)!.compareTo(_distanceTo(b)!));
    return items;
  }

  double? _distanceTo(Service s) {
    final pos = _getEffectiveLocation(s);
    if (pos == null) return null;
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
    final safeA = a.clamp(0.0, 1.0);
    return r * 2 * math.atan2(math.sqrt(safeA), math.sqrt(1 - safeA));
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

  Future<void> _refreshLocation() async {
    setState(() => _loading = true);
    await _requestLocation();
    if (!mounted) return;
    setState(() => _loading = false);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 13));
  }

  Future<void> _pickLocation() async {
    final selected = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerPage()),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _center = selected;
      _locationDenied = false;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(selected, 13));
  }

  Future<void> _showRadiusPicker() async {
    var draft = _radiusKm;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _cardSurface,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Search radius',
                  style: GoogleFonts.poppins(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Show services within ${draft.round()} km',
                  style: GoogleFonts.poppins(color: _textSecondary),
                ),
                Slider(
                  value: draft,
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: '${draft.round()} km',
                  onChanged: (value) => setSheetState(() => draft = value),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() => _radiusKm = draft);
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Apply radius'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        backgroundColor: _isDarkMode ? _appBarSurface : const Color(0xE8EEF4F5),
        foregroundColor: _textPrimary,
        elevation: 8,
        shadowColor: AppPalette.deepBlue.withAlpha(35),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Update current location',
            onPressed: _refreshLocation,
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _mutedSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_off_outlined, color: _brandColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Current location is unavailable. Choose a location to see accurate nearby services.',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _pickLocation,
                            child: const Text('Choose'),
                          ),
                        ],
                      ),
                    ),
                  ),
                _buildSearchAndCategories(),
                _buildResultsToolbar(items.length),
                if (_showMap)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: (MediaQuery.sizeOf(context).height * 0.27)
                            .clamp(180.0, 230.0),
                        child: _buildMap(items),
                      ),
                    ),
                  ),
                Expanded(child: _buildVendorList(items)),
              ],
            ),
    );
  }

  Widget _buildSearchAndCategories() {
    return Container(
      color: Colors.transparent,
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

  Widget _buildResultsToolbar(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          gradient: _isDarkMode
              ? null
              : const LinearGradient(
                  colors: [Color(0xF4FFFFFF), Color(0xDDE4EEEC)],
                ),
          color: _isDarkMode ? _cardSurface : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count nearby services',
                    style: GoogleFonts.poppins(
                      color: _textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Within ${_radiusKm.round()} km',
                    style: GoogleFonts.poppins(
                      color: _textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _showRadiusPicker,
              icon: const Icon(Icons.radar_rounded, size: 17),
              label: const Text('Radius'),
            ),
            IconButton.filledTonal(
              tooltip: _showMap ? 'Hide map' : 'Show map',
              onPressed: () => setState(() => _showMap = !_showMap),
              icon: Icon(_showMap ? Icons.list_rounded : Icons.map_rounded),
            ),
          ],
        ),
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
      ...items.where((s) => _getEffectiveLocation(s) != null).map((s) {
        final pos = _getEffectiveLocation(s)!;
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
      myLocationEnabled: _hasLocationPermission,
      myLocationButtonEnabled: _hasLocationPermission,
      onMapCreated: (controller) => _mapController = controller,
    );
  }

  Widget _buildVendorList(List<Service> items) {
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          Icon(Icons.location_searching_rounded, size: 52, color: _brandColor),
          const SizedBox(height: 12),
          Text(
            'No services found within ${_radiusKm.round()} km',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a larger radius, another category, or choose a different location.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: _textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _showRadiusPicker,
            icon: const Icon(Icons.radar_rounded),
            label: const Text('Change radius'),
          ),
        ],
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
          final distance = _distanceTo(s)!;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceDetailPage(service: s),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: _isDarkMode
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xF7FFFFFF), Color(0xE5E7EFF0)],
                        ),
                  color: _isDarkMode ? _cardSurface : null,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.deepBlue.withAlpha(18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: _nearbyThumb(s),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          Text(
                            s.serviceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: _textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _nearbyBadge(
                                Icons.near_me_rounded,
                                distance < 1
                                    ? '${(distance * 1000).round()} m'
                                    : '${distance.toStringAsFixed(1)} km',
                              ),
                              if (category != null)
                                _nearbyBadge(Icons.category_outlined, category),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: _textSecondary),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _nearbyThumb(Service service) {
    final url = service.primaryImageUrl ?? '';
    final local = service.localAssetImage;
    final fallback = Container(
      width: 72,
      height: 72,
      color: _mutedSurface,
      child: local == null
          ? Icon(Icons.storefront_rounded, color: _brandColor)
          : Image.asset(local, fit: BoxFit.contain),
    );
    if (url.isEmpty) return fallback;
    return Image.network(
      url,
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _nearbyBadge(IconData icon, String label) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _brandColor.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _brandColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: _textPrimary,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
