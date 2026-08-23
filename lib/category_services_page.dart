import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servekeen/service_model.dart';
import 'package:servekeen/data/hierarchy_repository.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/service_detail_page.dart';
import 'package:servekeen/theme/palette.dart';

class CategoryServicesPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String? initialSubcategoryId;

  const CategoryServicesPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.initialSubcategoryId,
  });

  @override
  State<CategoryServicesPage> createState() => _CategoryServicesPageState();
}

class _CategoryServicesPageState extends State<CategoryServicesPage> {
  List<SubcategoryNode> _subcategories = [];
  String? _selectedSubcategoryId;
  List<Service> _services = [];
  bool _loadingSubs = true;
  bool _loadingServices = true;
  bool _refreshingServices = false;
  int _servicesRequestSerial = 0;

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _backgroundColor =>
      _isDarkMode ? Colors.black : AppPalette.softBlendBackground;
  Color get _appBarSurface => _isDarkMode ? Colors.black : Colors.white;
  Color get _cardSurface =>
      _isDarkMode ? const Color(0xFF121212) : Colors.white;
  Color get _chipSurface =>
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
    _init();
  }

  Future<void> _init() async {
    await HierarchyRepository().init();
    final subs = await HierarchyRepository().getSubcategories(
      widget.categoryId,
    );
    setState(() {
      _subcategories = subs;
      _selectedSubcategoryId = widget.initialSubcategoryId;
      _loadingSubs = false;
    });
    _fetchServices();
  }

  Future<void> _fetchServices({bool forceRemote = false}) async {
    final requestId = ++_servicesRequestSerial;
    final cached = forceRemote
        ? <Service>[]
        : HierarchyRepository().getServices(
            widget.categoryId,
            subcategoryId: _selectedSubcategoryId,
          );

    if (!mounted) return;
    setState(() {
      if (cached.isNotEmpty) {
        _services = cached;
        _loadingServices = false;
        _refreshingServices = true;
      } else {
        _services = [];
        _loadingServices = true;
        _refreshingServices = false;
      }
    });

    List<Service> remote = [];
    try {
      remote = await ApiService().fetchServicesByCategoryId(
        widget.categoryId,
        subcategoryId: _selectedSubcategoryId,
      );
    } catch (_) {}

    if (!mounted || requestId != _servicesRequestSerial) return;
    setState(() {
      if (remote.isNotEmpty) {
        _services = remote;
      } else if (_services.isEmpty) {
        _services = cached;
      }
      _loadingServices = false;
      _refreshingServices = false;
    });
  }

  void _onSubSelected(String? id) {
    if (_selectedSubcategoryId == id) return;
    setState(() {
      _selectedSubcategoryId = id;
    });
    _fetchServices();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: _textPrimary,
    );
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(widget.categoryName, style: titleStyle),
        backgroundColor: _appBarSurface,
        foregroundColor: _textPrimary,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          _buildBreadcrumb(),
          _buildSubcategoryFilter(),
          if (_refreshingServices) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildServicesList()),
        ],
      ),
    );
  }

  // Removed map redirection; service taps open detail page directly

  Widget _buildBreadcrumb() {
    final selected = _selectedSubcategoryId;
    final selectedName = selected == null || selected.isEmpty
        ? 'All'
        : (_subcategories
              .firstWhere(
                (s) => s.id == selected,
                orElse: () =>
                    SubcategoryNode(selected, 'Subcategory $selected'),
              )
              .name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        '${widget.categoryName} > $selectedName',
        style: GoogleFonts.poppins(color: _textSecondary),
      ),
    );
  }

  Widget _buildSubcategoryFilter() {
    if (_loadingSubs) {
      return const SizedBox(
        height: 56,
        child: Center(child: LinearProgressIndicator()),
      );
    }
    final items = [SubcategoryNode('', 'All'), ..._subcategories];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = (_selectedSubcategoryId ?? '') == item.id;
          return ChoiceChip(
            label: Text(item.name),
            selected: selected,
            onSelected: (_) => _onSubSelected(item.id.isEmpty ? null : item.id),
            selectedColor: AppPalette.fusionPurple,
            labelStyle: GoogleFonts.poppins(
              color: selected ? Colors.white : _textPrimary,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: _chipSurface,
            shape: StadiumBorder(side: BorderSide(color: _borderColor)),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }

  Widget _buildServicesList() {
    if (_loadingServices) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_services.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchServices(forceRemote: true),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const SizedBox(height: 48),
            Center(
              child: Text(
                'No services found',
                style: GoogleFonts.poppins(color: _textSecondary),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _fetchServices(forceRemote: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _services.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final s = _services[index];
          final tier = s.priceTier;
          return InkWell(
            onTap: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailPage(service: s),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              color: _cardSurface,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderColor),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _ServiceThumb(service: s),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.serviceName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _textSecondary,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (s.locations != null &&
                                  s.locations!.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.place,
                                      size: 13,
                                      color: _brandColor,
                                    ),
                                    const SizedBox(width: 2),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 120,
                                      ),
                                      child: Text(
                                        s.locations!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (s.price != null && s.price! > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _brandColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '₹${s.price!.toStringAsFixed(0)}${s.perPrice != null && s.perPrice!.isNotEmpty ? ' / ${s.perPrice}' : ''}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _brandColor,
                                    ),
                                  ),
                                ),
                              if (tier != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: s.isPremium
                                        ? AppPalette.elegantPink
                                        : _mutedSurface,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: _borderColor),
                                  ),
                                  child: Text(
                                    tier,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: s.isPremium
                                          ? Colors.white
                                          : _textPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceThumb extends StatelessWidget {
  final Service service;
  const _ServiceThumb({required this.service});

  @override
  Widget build(BuildContext context) {
    final imgPath = service.primaryImageUrl ?? '';
    final localAsset = service.localAssetImage;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholder = isDark
        ? const Color(0xFF223142)
        : AppPalette.lightBlueTint;
    return SizedBox(
      width: 84,
      height: 84,
      child: imgPath.isNotEmpty
          ? Image.network(
              imgPath,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: placeholder,
                ),
                child: localAsset != null
                    ? Image.asset(localAsset, fit: BoxFit.contain)
                    : const Icon(Icons.broken_image, color: Colors.grey),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: placeholder,
              ),
              child: localAsset != null
                  ? Image.asset(localAsset, fit: BoxFit.contain)
                  : const Icon(Icons.business, color: Colors.grey),
            ),
    );
  }
}
