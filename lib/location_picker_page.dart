import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  LatLng? _selected;
  GoogleMapController? _controller;
  bool _requesting = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
    _initPermission();
  }

  Future<void> _loadSaved() async {
    final sp = await SharedPreferences.getInstance();
    final lat = sp.getDouble('user_lat');
    final lng = sp.getDouble('user_lng');
    if (lat != null && lng != null) {
      setState(() {
        _selected = LatLng(lat, lng);
      });
    }
  }

  Future<void> _useCurrent() async {
    setState(() => _requesting = true);
    try {
      final perm = await Geolocator.checkPermission();
      LocationPermission p = perm;
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.whileInUse || p == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final latLng = LatLng(pos.latitude, pos.longitude);
        setState(() => _selected = latLng);
        _controller?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
        setState(() => _hasPermission = true);
      }
    } finally {
      setState(() => _requesting = false);
    }
  }

  Future<void> _initPermission() async {
    final perm = await Geolocator.checkPermission();
    LocationPermission p = perm;
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
      p = await Geolocator.requestPermission();
    }
    setState(() {
      _hasPermission = p == LocationPermission.whileInUse || p == LocationPermission.always;
    });
  }

  Future<void> _saveAndClose() async {
    if (_selected == null) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble('user_lat', _selected!.latitude);
    await sp.setDouble('user_lng', _selected!.longitude);
    if (mounted) Navigator.pop(context, _selected);
  }

  @override
  Widget build(BuildContext context) {
    final center = _selected ?? const LatLng(13.0827, 80.2707); // Chennai default
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Location')),
      body: Column(children: [
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 12),
            liteModeEnabled: true,
            myLocationButtonEnabled: _hasPermission,
            myLocationEnabled: _hasPermission,
            onMapCreated: (c) => _controller = c,
            onTap: (latLng) => setState(() => _selected = latLng),
            markers: {
              if (_selected != null)
                Marker(markerId: const MarkerId('selected'), position: _selected!),
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _requesting ? null : _useCurrent,
                icon: const Icon(Icons.my_location),
                label: Text('Use current', style: GoogleFonts.poppins()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _selected == null ? null : _saveAndClose,
                icon: const Icon(Icons.check),
                label: Text('Confirm', style: GoogleFonts.poppins()),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
