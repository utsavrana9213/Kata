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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await HierarchyRepository().init();
    final subs = await HierarchyRepository().getSubcategories(widget.categoryId);
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
    final titleStyle = GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppPalette.deepBlue);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName, style: titleStyle),
        backgroundColor: Colors.white,
        foregroundColor: AppPalette.deepBlue,
        centerTitle: true,
        elevation: 0.5,
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
        : (_subcategories.firstWhere(
              (s) => s.id == selected,
              orElse: () => SubcategoryNode(selected, 'Subcategory $selected'),
            ).name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Text('${widget.categoryName} > $selectedName', style: GoogleFonts.poppins(color: AppPalette.deepBlue.withAlpha(150))),
    );
  }

  Widget _buildSubcategoryFilter() {
    if (_loadingSubs) {
      return const SizedBox(height: 56, child: Center(child: LinearProgressIndicator()));
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
              color: selected ? Colors.white : AppPalette.deepBlue,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.white,
            shape: StadiumBorder(side: BorderSide(color: AppPalette.deepBlue.withAlpha(26))),
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
            Center(child: Text('No services found', style: GoogleFonts.poppins(color: AppPalette.deepBlue.withAlpha(140)))),
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
                MaterialPageRoute(builder: (_) => ServiceDetailPage(service: s)),
              );
            },
            child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _ServiceThumb(service: s),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.companyName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppPalette.deepBlue)),
                      const SizedBox(height: 4),
                      Text(s.serviceName, style: GoogleFonts.poppins(color: AppPalette.deepBlue.withAlpha(160))),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          if (s.locations != null && s.locations!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.place, size: 14, color: AppPalette.fusionPurple),
                                const SizedBox(width: 4),
                                Text(s.locations!, style: GoogleFonts.poppins(fontSize: 12, color: AppPalette.deepBlue.withAlpha(150))),
                              ],
                            ),
                          if (s.price != null)
                            Text('₹${s.price!.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppPalette.fusionPurple)),
                          if (tier != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: s.isPremium ? AppPalette.elegantPink : AppPalette.lightBlueTint,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppPalette.deepBlue.withAlpha(24)),
                              ),
                              child: Text(
                                tier,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: s.isPremium ? Colors.white : AppPalette.deepBlue,
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
                  color: AppPalette.lightBlueTint,
                ),
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppPalette.lightBlueTint,
              ),
              child: const Icon(Icons.business, color: Colors.grey),
            ),
    );
  }
}
