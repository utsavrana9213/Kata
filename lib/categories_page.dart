import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:servekeen/widgets/dot_grid_painter.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/category_services_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servekeen/theme/palette.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

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
      : const [AppPalette.softBlendBackground, AppPalette.lightBlueTint];

  @override
  void initState() {
    super.initState();
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
                'icon': Icons.category,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
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
                const SizedBox(height: 12),
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
    return Card(
      elevation: 0,
      color: _cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.search, color: _textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(color: _textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search categories',
                  hintStyle: GoogleFonts.poppins(color: _textSecondary),
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear',
                          icon: Icon(Icons.clear, color: _textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _categories.where((c) {
      final label = (c['label'] as String).toLowerCase();
      return query.isEmpty || label.contains(query);
    }).toList();

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
  }) {
    final color = _brandColor;
    Widget iconWidget;
    if (isNetwork == true && image != null && image.isNotEmpty) {
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
        color: _cardSurface,
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
                    : const [Colors.white, Color(0xFFF3F7FF)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Center(child: iconWidget),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: _textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
