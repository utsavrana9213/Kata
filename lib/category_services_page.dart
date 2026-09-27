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
  String _tierFilter = 'All';
  String _locationFilter = 'All';
  double _minRating = 0;
  double? _maxPrice;
  String _sortBy = 'Recommended';

  int get _activeFilterCount =>
      (_tierFilter == 'All' ? 0 : 1) +
      (_locationFilter == 'All' ? 0 : 1) +
      (_minRating <= 0 ? 0 : 1) +
      (_maxPrice == null ? 0 : 1) +
      (_sortBy == 'Recommended' ? 0 : 1) +
      ((_selectedSubcategoryId ?? '').isEmpty ? 0 : 1);

  List<Service> get _visibleServices {
    final result = _services.where((service) {
      if (_tierFilter == 'Premium' && !service.isPremium) return false;
      if (_tierFilter == 'Standard' && service.isPremium) return false;
      if (_locationFilter != 'All' &&
          (service.locations ?? '').trim() != _locationFilter) {
        return false;
      }
      if ((service.avrRat ?? 0) < _minRating) return false;
      if (_maxPrice != null && (service.price ?? 0) > _maxPrice!) return false;
      return true;
    }).toList();
    if (_sortBy == 'Price: Low to high') {
      result.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
    } else if (_sortBy == 'Price: High to low') {
      result.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
    } else if (_sortBy == 'Top rated') {
      result.sort((a, b) => (b.avrRat ?? 0).compareTo(a.avrRat ?? 0));
    }
    return result;
  }

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _backgroundColor =>
      _isDarkMode ? Colors.black : AppPalette.softBlendBackground;
  Color get _appBarSurface => _isDarkMode ? Colors.black : Colors.white;
  Color get _cardSurface =>
      _isDarkMode ? const Color(0xFF121212) : Colors.white;
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
          _buildFilterToolbar(),
          if (_refreshingServices) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildServicesList()),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_visibleServices.length} related services',
              style: GoogleFonts.poppins(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: Text(
              _activeFilterCount == 0
                  ? 'Filters'
                  : 'Filters ($_activeFilterCount)',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    var draftTier = _tierFilter;
    var draftSubcategory = _selectedSubcategoryId;
    var draftLocation = _locationFilter;
    var draftRating = _minRating;
    var draftMaxPrice = _maxPrice;
    var draftSort = _sortBy;
    final locations =
        _services
            .map((service) => (service.locations ?? '').trim())
            .where((location) => location.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final highestPrice = _services.fold<double>(0, (highest, service) {
      final price = service.price ?? 0;
      return price > highest ? price : highest;
    });
    final sliderMax = highestPrice <= 0 ? 1000.0 : highestPrice.ceilToDouble();
    draftMaxPrice ??= sliderMax;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.76,
          minChildSize: 0.5,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? const Color(0xFF151F2A)
                  : const Color(0xFFF1F6F6),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: _isDarkMode ? Colors.white12 : Colors.white,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x55204670), blurRadius: 30),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _textSecondary.withAlpha(90),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filter services',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    children: [
                      _filterLabel('Service type'),
                      DropdownButtonFormField<String>(
                        value: draftSubcategory ?? '',
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: [SubcategoryNode('', 'All'), ..._subcategories]
                            .map(
                              (subcategory) => DropdownMenuItem(
                                value: subcategory.id,
                                child: Text(subcategory.name),
                              ),
                            )
                            .toList(),
                        onChanged: _loadingSubs
                            ? null
                            : (value) => setSheetState(
                                () => draftSubcategory = (value ?? '').isEmpty
                                    ? null
                                    : value,
                              ),
                      ),
                      const SizedBox(height: 18),
                      _filterLabel('Membership'),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Standard', 'Premium'].map((tier) {
                          return ChoiceChip(
                            label: Text(tier),
                            selected: draftTier == tier,
                            onSelected: (_) =>
                                setSheetState(() => draftTier = tier),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      _filterLabel('Location'),
                      DropdownButtonFormField<String>(
                        value: locations.contains(draftLocation)
                            ? draftLocation
                            : 'All',
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.place_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: ['All', ...locations]
                            .map(
                              (location) => DropdownMenuItem(
                                value: location,
                                child: Text(location),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setSheetState(() => draftLocation = value ?? 'All'),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: _filterLabel('Maximum price')),
                          Text(
                            '₹${draftMaxPrice!.round()}',
                            style: GoogleFonts.poppins(
                              color: _brandColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        min: 0,
                        max: sliderMax,
                        divisions: 20,
                        value: draftMaxPrice!.clamp(0, sliderMax),
                        onChanged: (value) =>
                            setSheetState(() => draftMaxPrice = value),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _filterLabel('Minimum rating')),
                          Text(
                            draftRating == 0
                                ? 'Any'
                                : '${draftRating.toStringAsFixed(1)}+ ★',
                            style: GoogleFonts.poppins(
                              color: _brandColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        min: 0,
                        max: 5,
                        divisions: 10,
                        value: draftRating,
                        onChanged: (value) =>
                            setSheetState(() => draftRating = value),
                      ),
                      const SizedBox(height: 10),
                      _filterLabel('Sort by'),
                      DropdownButtonFormField<String>(
                        value: draftSort,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.sort_rounded),
                          border: OutlineInputBorder(),
                        ),
                        items:
                            [
                                  'Recommended',
                                  'Top rated',
                                  'Price: Low to high',
                                  'Price: High to low',
                                ]
                                .map(
                                  (sort) => DropdownMenuItem(
                                    value: sort,
                                    child: Text(sort),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => setSheetState(
                          () => draftSort = value ?? 'Recommended',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setSheetState(() {
                            draftTier = 'All';
                            draftSubcategory = null;
                            draftLocation = 'All';
                            draftRating = 0;
                            draftMaxPrice = sliderMax;
                            draftSort = 'Recommended';
                          }),
                          child: const Text('Clear all'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final subcategoryChanged =
                                draftSubcategory != _selectedSubcategoryId;
                            setState(() {
                              _selectedSubcategoryId = draftSubcategory;
                              _tierFilter = draftTier;
                              _locationFilter = draftLocation;
                              _minRating = draftRating;
                              _maxPrice = draftMaxPrice! >= sliderMax
                                  ? null
                                  : draftMaxPrice;
                              _sortBy = draftSort;
                            });
                            Navigator.pop(sheetContext);
                            if (subcategoryChanged) _fetchServices();
                          },
                          child: const Text('Show results'),
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

  Widget _filterLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
    ),
  );

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
    final services = _visibleServices;
    if (services.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 48),
          Icon(Icons.filter_alt_off_rounded, size: 48, color: _textSecondary),
          const SizedBox(height: 12),
          Text(
            'No services match these filters',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: _textPrimary),
          ),
          TextButton(
            onPressed: () {
              final hadSubcategory = _selectedSubcategoryId != null;
              setState(() {
                _selectedSubcategoryId = null;
                _tierFilter = 'All';
                _locationFilter = 'All';
                _minRating = 0;
                _maxPrice = null;
                _sortBy = 'Recommended';
              });
              if (hadSubcategory) _fetchServices();
            },
            child: const Text('Clear filters'),
          ),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: () => _fetchServices(forceRemote: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final s = services[index];
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
