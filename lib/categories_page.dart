import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:servekeen/widgets/dot_grid_painter.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/category_services_page.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

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
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('Categories'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(painter: DotGridPainter()),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7F9FC), Color(0xFFEFF3F9)],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.search),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search categories',
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.clear),
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

  Widget _categoryTile(BuildContext context, String label, IconData icon, double width, {required String id, String? image, bool? isNetwork}) {
    final color = Colors.blueAccent;
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: () {
            _showSubcategoryPicker(context, id, label);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFF3F7FF),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: (isNetwork == true && image != null) 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(image, fit: BoxFit.cover),
                      )
                    : Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSubcategoryPicker(BuildContext context, String categoryId, String categoryName) async {
    final subsRaw = await ApiService().fetchSubcategories(categoryId);
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Subcategory', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: false,
                      onSelected: (_) {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryServicesPage(
                              categoryId: categoryId,
                              categoryName: categoryName,
                            ),
                          ),
                        );
                      },
                    ),
                    ...subsRaw.map((m) {
                      final id = (m['id'] ?? '').toString();
                      final label = (m['subname'] ?? m['name'] ?? 'Unknown').toString();
                      return ChoiceChip(
                        label: Text(label),
                        selected: false,
                        onSelected: (_) {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryServicesPage(
                                categoryId: categoryId,
                                categoryName: categoryName,
                                initialSubcategoryId: id,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
