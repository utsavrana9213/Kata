import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:servekeen/widgets/dot_grid_painter.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/category_services_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servekeen/theme/palette.dart';
import 'package:servekeen/vendor_filters.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

  List<Map<String, dynamic>> get _filteredCategories {
    final query = normalizeSearch(_searchController.text);
    if (query.isEmpty) return _categories;
    final terms = query.split(' ').where((term) => term.isNotEmpty);
    return _categories.where((category) {
      final label = normalizeSearch((category['label'] ?? '').toString());
      return terms.every((term) => label.contains(term));
    }).toList();
  }

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _backgroundColor =>
      _isDarkMode ? Colors.black : AppPalette.softBlendBackground;
  Color get _cardSurface =>
      _isDarkMode ? const Color(0xFF121212) : Colors.white;
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
  List<Color> get _pageGradient => _isDarkMode
      ? const [Colors.black, Colors.black]
      : const [Color(0xB8E5ECEE), Color(0xA8DDE9E3)];

  IconData _iconForCategory(String label) {
    final value = label.toLowerCase();
    const matches = <String, IconData>{
      'cater': Icons.restaurant_rounded,
      'food': Icons.restaurant_rounded,
      'banquet': Icons.celebration_rounded,
      'wedding': Icons.favorite_rounded,
      'resort': Icons.holiday_village_rounded,
      'hotel': Icons.hotel_rounded,
      'villa': Icons.villa_rounded,
      'packer': Icons.local_shipping_rounded,
      'mover': Icons.local_shipping_rounded,
      'courier': Icons.inventory_2_rounded,
      'adventure': Icons.paragliding_rounded,
      'travel': Icons.flight_takeoff_rounded,
      'spa': Icons.spa_rounded,
      'salon': Icons.content_cut_rounded,
      'beauty': Icons.face_retouching_natural_rounded,
      'hospital': Icons.local_hospital_rounded,
      'doctor': Icons.medical_services_rounded,
      'education': Icons.school_rounded,
      'repair': Icons.handyman_rounded,
      'clean': Icons.cleaning_services_rounded,
      'property': Icons.apartment_rounded,
      'home': Icons.home_work_rounded,
      'event': Icons.event_available_rounded,
      'photo': Icons.camera_alt_rounded,
      'vehicle': Icons.directions_car_rounded,
      'car': Icons.directions_car_rounded,
      'pet': Icons.pets_rounded,
      'fitness': Icons.fitness_center_rounded,
      'legal': Icons.gavel_rounded,
      'finance': Icons.account_balance_rounded,
    };
    for (final entry in matches.entries) {
      if (value.contains(entry.key)) return entry.value;
    }
    return Icons.grid_view_rounded;
  }

  String? _assetForCategory(String label) {
    final value = label.toLowerCase();
    const matches = <String, String>{
      'cater': 'catering.png',
      'food': 'catering.png',
      'banquet': 'banquets.png',
      'wedding': 'banquets.png',
      'resort': 'resorts.png',
      'villa': 'resorts.png',
      'packer': 'moving.png',
      'mover': 'moving.png',
      'adventure': 'adventure.png',
      'travel': 'adventure.png',
      'spa': 'spa.png',
      'salon': 'spa.png',
      'courier': 'courier.png',
      'delivery': 'courier.png',
      'dance': 'dance.png',
      'auto': 'automotive.png',
      'vehicle': 'automotive.png',
      'fun': 'fun.png',
      'amusement': 'fun.png',
      'fitness': 'fitness.png',
      'gym': 'fitness.png',
      'clinic': 'clinics.png',
      'hospital': 'clinics.png',
      'medical': 'clinics.png',
      'education': 'education.png',
      'school': 'education.png',
      'photo': 'photography.png',
      'camera': 'photography.png',
    };
    for (final entry in matches.entries) {
      if (value.contains(entry.key)) {
        return 'assets/images/categories/${entry.value}';
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await ApiService().fetchAppData();
      if (mounted) {
        setState(() {
          if (data['categories'] != null) {
            _categories = (data['categories'] as List).map((e) {
              String imgPath = e['imgfold'] ?? '';
              if (imgPath.isNotEmpty && !imgPath.startsWith('http')) {
                imgPath = "https://servekeen.com/$imgPath";
              }

              return {
                'id': (e['id'] ?? '').toString(),
                'label': e['category_name'] ?? e['name'] ?? 'Unknown',
                'image': imgPath,
                'is_network': imgPath.isNotEmpty,
                'asset': _assetForCategory(
                  (e['category_name'] ?? e['name'] ?? '').toString(),
                ),
                'icon': _iconForCategory(
                  (e['category_name'] ?? e['name'] ?? '').toString(),
                ),
              };
            }).toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (kDebugMode) debugPrint('Error loading categories: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _isDarkMode ? Colors.black : const Color(0xDDEBF1F2),
        foregroundColor: _textPrimary,
        title: Text(
          'Categories',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: _isDarkMode ? 0.04 : 0.05,
                child: CustomPaint(painter: DotGridPainter()),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _pageGradient,
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildSearchBar(context),
                const SizedBox(height: 10),
                if (!_isLoading) _buildSearchSummary(),
                const SizedBox(height: 10),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  _buildCategoriesGrid(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _isDarkMode
            ? const LinearGradient(
                colors: [Color(0xFF1B2836), Color(0xFF151F2A)],
              )
            : const LinearGradient(
                colors: [Color(0xFAFFFFFF), Color(0xE2E5EEF0)],
              ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? _brandColor.withAlpha(170)
              : _borderColor,
          width: _searchFocusNode.hasFocus ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _brandColor.withAlpha(_searchFocusNode.hasFocus ? 35 : 18),
            blurRadius: _searchFocusNode.hasFocus ? 18 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        style: GoogleFonts.poppins(color: _textPrimary),
        decoration: InputDecoration(
          hintText: 'Search all categories',
          hintStyle: GoogleFonts.poppins(color: _textSecondary),
          border: InputBorder.none,
          prefixIcon: Icon(
            _searchFocusNode.hasFocus
                ? Icons.manage_search_rounded
                : Icons.search_rounded,
            color: _searchFocusNode.hasFocus ? _brandColor : _textSecondary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: Icon(Icons.close_rounded, color: _textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSearchSummary() {
    final query = _searchController.text.trim();
    final count = _filteredCategories.length;
    return Row(
      children: [
        Expanded(
          child: Text(
            query.isEmpty
                ? '${_categories.length} service categories'
                : '$count ${count == 1 ? 'category' : 'categories'} found',
            style: GoogleFonts.poppins(
              color: _textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (query.isNotEmpty)
          TextButton(
            onPressed: () {
              _searchController.clear();
              _searchFocusNode.unfocus();
              setState(() {});
            },
            child: const Text('Cancel'),
          ),
      ],
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    final filtered = _filteredCategories;

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: _textSecondary),
            const SizedBox(height: 10),
            Text(
              'No matching category',
              style: GoogleFonts.poppins(
                color: _textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Check the spelling or try a shorter name.',
              style: GoogleFonts.poppins(color: _textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        int columns;
        if (maxW < 480) {
          columns = 2;
        } else if (maxW < 800) {
          columns = 3;
        } else {
          columns = 4;
        }
        const spacing = 12.0;
        final tileW = (maxW - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: filtered.map((c) {
            return _categoryTile(
              context,
              c['label'] as String,
              c['icon'] as IconData,
              tileW,
              id: c['id'] as String,
              image: c['image'],
              isNetwork: c['is_network'],
              asset: c['asset'],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _categoryTile(
    BuildContext context,
    String label,
    IconData icon,
    double width, {
    required String id,
    String? image,
    bool? isNetwork,
    String? asset,
  }) {
    final color = _brandColor;
    Widget iconWidget;
    if (asset != null && asset.isNotEmpty) {
      iconWidget = Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => Icon(icon, color: color, size: 20),
      );
    } else if (isNetwork == true && image != null && image.isNotEmpty) {
      iconWidget = Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Icon(icon, color: color, size: 20),
      );
    } else {
      iconWidget = Icon(icon, color: color, size: 20);
    }

    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        color: _isDarkMode ? _cardSurface : Colors.white.withAlpha(205),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CategoryServicesPage(categoryId: id, categoryName: label),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isDarkMode
                    ? const [Color(0xFF1B2836), Color(0xFF151F2A)]
                    : const [Color(0xF2FFFFFF), Color(0xD9E4EDF2)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
              boxShadow: _isDarkMode
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x30204670),
                        blurRadius: 16,
                        offset: Offset(0, 7),
                      ),
                      BoxShadow(
                        color: Color(0xA6FFFFFF),
                        blurRadius: 2,
                        offset: Offset(-1, -1),
                      ),
                    ],
            ),
            constraints: const BoxConstraints(minHeight: 128),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: _textSecondary,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: Center(child: iconWidget),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
