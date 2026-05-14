import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servekeen/api_service.dart';
import 'package:servekeen/service_model.dart';
import 'package:image_picker/image_picker.dart';

class AddServicePage extends StatefulWidget {
  final Service? service;
  const AddServicePage({super.key, this.service});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _serviceNameController = TextEditingController();
  final _locationsController = TextEditingController();
  final _categoryIdController = TextEditingController();
  final _subcategoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _perPriceController = TextEditingController();
  final _allHourController = ValueNotifier<bool>(false);
  final _workingDaysController = TextEditingController();
  final _openTimeController = TextEditingController();
  final _closeTimeController = TextEditingController();
  final _numberController = TextEditingController();
  final _addressController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();

  final _gmapController = TextEditingController();
  final _latiController = TextEditingController();
  final _lngiController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _pickedImages = [];
  final List<String> _existingImages = [];

  bool _categoriesLoading = false;
  bool _subcategoriesLoading = false;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategories = [];
  final Map<String, String> _categoryNameById = {};
  final Map<String, String> _subcategoryNameById = {};
  String? _selectedCategoryId;
  final Set<String> _selectedSubcategoryIds = {};

  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    final s = widget.service;
    if (s != null) {
      _companyNameController.text = s.companyName;
      _serviceNameController.text = s.serviceName;
      _locationsController.text = (s.locations ?? '').toString();
      _categoryIdController.text = (s.categorys ?? '').toString();
      _subcategoryController.text = (s.subcategory ?? '').toString();
      _priceController.text = s.price?.toString() ?? '';
      _perPriceController.text = (s.perPrice ?? '').toString();
      _allHourController.value = s.allHour ?? false;
      _workingDaysController.text = (s.workingDays ?? '').toString();
      _openTimeController.text = (s.openTime ?? '').toString();
      _closeTimeController.text = (s.closeTime ?? '').toString();
      _numberController.text = (s.number ?? '').toString();
      _addressController.text = (s.address ?? '').toString();
      _shortDescriptionController.text = (s.shortDescription ?? '').toString();
      _descriptionController.text = (s.description ?? '').toString();
      _websiteController.text = (s.website ?? '').toString();
      _facebookController.text = (s.facebook ?? '').toString();
      _instagramController.text = (s.instagram ?? '').toString();
      _twitterController.text = (s.twitter ?? '').toString();
      _linkedinController.text = (s.linkedin ?? '').toString();
      _gmapController.text = (s.gmap ?? '').toString();
      _latiController.text = s.lati?.toString() ?? '';
      _lngiController.text = s.lngi?.toString() ?? '';

      final raw = (s.imgFold ?? '').toString();
      if (raw.trim().isNotEmpty) {
        _existingImages.addAll(
          raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
        );
      }
      _selectedCategoryId = _categoryIdController.text.trim().isEmpty ? null : _categoryIdController.text.trim();
      final subsRaw = _subcategoryController.text.trim();
      if (subsRaw.isNotEmpty) {
        _selectedSubcategoryIds
          ..clear()
          ..addAll(subsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
      return;
    }

    final u = ApiService().currentUser;
    final name = (u?['name'] ?? '').toString();
    if (name.isNotEmpty) _companyNameController.text = name;
    final mobile = (u?['mobile'] ?? u?['phone'] ?? '').toString();
    if (mobile.isNotEmpty) _numberController.text = mobile;
    final addr = (u?['address'] ?? '').toString();
    if (addr.isNotEmpty) _addressController.text = addr;
    final website = (u?['bwebsite'] ?? u?['website'] ?? '').toString();
    if (website.isNotEmpty) _websiteController.text = website;

    _selectedCategoryId = _categoryIdController.text.trim().isEmpty ? null : _categoryIdController.text.trim();
    final subsRaw = _subcategoryController.text.trim();
    if (subsRaw.isNotEmpty) {
      _selectedSubcategoryIds
        ..clear()
        ..addAll(subsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _serviceNameController.dispose();
    _locationsController.dispose();
    _categoryIdController.dispose();
    _subcategoryController.dispose();
    _priceController.dispose();
    _perPriceController.dispose();
    _workingDaysController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    _numberController.dispose();
    _addressController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _gmapController.dispose();
    _latiController.dispose();
    _lngiController.dispose();
    _allHourController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (!mounted) return;
    if (files.isEmpty) return;
    setState(() {
      _pickedImages.addAll(files);
    });
  }

  void _removePickedImage(int index) {
    setState(() {
      if (index >= 0 && index < _pickedImages.length) {
        _pickedImages.removeAt(index);
      }
    });
  }

  Future<void> _loadCategories() async {
    if (_categoriesLoading) return;
    setState(() => _categoriesLoading = true);
    try {
      final data = await ApiService().fetchAppData();
      final raw = (data['categories'] as List?)?.cast<dynamic>() ?? const [];
      final parsed = <Map<String, dynamic>>[];
      _categoryNameById.clear();
      for (final item in raw) {
        if (item is! Map) continue;
        final m = item.cast<String, dynamic>();
        final id = (m['id'] ?? '').toString();
        if (id.isEmpty) continue;
        final name = (m['category_name'] ?? m['name'] ?? 'Category $id').toString();
        parsed.add({'id': id, 'name': name, ...m});
        _categoryNameById[id] = name;
      }
      parsed.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

      if (!mounted) return;
      setState(() {
        _categories = parsed;
      });

      if (_selectedCategoryId != null && _selectedCategoryId!.trim().isNotEmpty) {
        await _loadSubcategories(_selectedCategoryId!);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _loadSubcategories(String categoryId) async {
    if (_subcategoriesLoading) return;
    setState(() => _subcategoriesLoading = true);
    try {
      final subs = await ApiService().fetchSubcategories(categoryId);
      _subcategoryNameById.clear();
      final parsed = <Map<String, dynamic>>[];
      for (final item in subs) {
        final id = (item['id'] ?? '').toString();
        if (id.isEmpty) continue;
        final name = (item['subname'] ?? item['subcategory_name'] ?? item['name'] ?? 'Subcategory $id').toString();
        parsed.add({'id': id, 'name': name, ...item});
        _subcategoryNameById[id] = name;
      }
      parsed.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
      if (!mounted) return;
      setState(() {
        _subcategories = parsed;
        _selectedSubcategoryIds.removeWhere((id) => !_subcategoryNameById.containsKey(id));
        _subcategoryController.text = _selectedSubcategoryIds.join(', ');
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _subcategoriesLoading = false);
    }
  }

  Future<void> _openSubcategoryPicker() async {
    if (_selectedCategoryId == null || _selectedCategoryId!.trim().isEmpty) return;
    if (_subcategoriesLoading) return;

    final selected = <String>{..._selectedSubcategoryIds};
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Select Subcategories', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: MediaQuery.of(ctx).size.height * 0.55,
                      child: ListView.builder(
                        itemCount: _subcategories.length,
                        itemBuilder: (context, index) {
                          final s = _subcategories[index];
                          final id = (s['id'] ?? '').toString();
                          final name = (s['name'] ?? '').toString();
                          final isChecked = selected.contains(id);
                          return CheckboxListTile(
                            value: isChecked,
                            onChanged: (v) {
                              setSheetState(() {
                                if (v == true) {
                                  selected.add(id);
                                } else {
                                  selected.remove(id);
                                }
                              });
                            },
                            title: Text(name, style: GoogleFonts.poppins()),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    setState(() {
      _selectedSubcategoryIds
        ..clear()
        ..addAll(selected);
      _subcategoryController.text = _selectedSubcategoryIds.join(', ');
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final payload = <String, dynamic>{
        'companyname': _companyNameController.text.trim(),
        'servicename': _serviceNameController.text.trim(),
        'locations': _locationsController.text.trim(),
        'category_id': _categoryIdController.text.trim(),
        'categorys': _categoryIdController.text.trim(),
        'subcategory': _subcategoryController.text.trim(),
        'price': _priceController.text.trim(),
        'perprice': _perPriceController.text.trim(),
        'allhour': _allHourController.value ? 1 : 0,
        'workingdays': _workingDaysController.text.trim(),
        'opentime': _openTimeController.text.trim(),
        'closetime': _closeTimeController.text.trim(),
        'number': _numberController.text.trim(),
        'address': _addressController.text.trim(),
        'shortdescription': _shortDescriptionController.text.trim(),
        'description': _descriptionController.text.trim(),
        'website': _websiteController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'twitter': _twitterController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'gmap': _gmapController.text.trim(),
        'lati': _latiController.text.trim(),
        'lngi': _lngiController.text.trim(),
        'is_active': 1,
      };
      payload.removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

      final isEdit = widget.service != null;
      Map<String, dynamic> res;
      String serviceId = widget.service?.id ?? '';
      if (isEdit) {
        res = await ApiService().updateService(serviceId, payload);
      } else {
        res = await ApiService().createService(payload);
        final svc = res['service'];
        if (svc is Map && (svc['id'] ?? '').toString().isNotEmpty) {
          serviceId = (svc['id']).toString();
        }
      }
      if (!mounted) return;
      if (res['status'] == 'success') {
        if (_pickedImages.isNotEmpty && serviceId.trim().isNotEmpty) {
          final bytes = <Uint8List>[];
          final names = <String>[];
          for (final f in _pickedImages) {
            bytes.add(await f.readAsBytes());
            names.add(f.name);
          }
          final uploadRes = await ApiService().uploadServiceImages(
            serviceId: serviceId,
            images: bytes,
            filenames: names,
          );
          if (!mounted) return;
          if (uploadRes['status'] != 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text((uploadRes['message'] ?? 'Failed to upload images').toString()), backgroundColor: Colors.red),
            );
            return;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Service updated successfully' : 'Service added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((res['message'] ?? 'Failed to add service').toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icon == null ? null : Icon(icon),
        filled: true,
        fillColor: cs.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: validator,
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                      if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.service != null;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Service' : 'Add Service', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Update Service' : 'Save Service'),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primaryContainer.withValues(alpha: 0.35),
              cs.surface,
              cs.surface,
              cs.primaryContainer.withValues(alpha: 0.18),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionCard(
                    icon: Icons.info_outline,
                    title: 'Basic Information',
                    subtitle: 'Help customers understand what you offer.',
                    children: [
                      _field(
                        controller: _companyNameController,
                        label: 'Company Name',
                        icon: Icons.business_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _serviceNameController,
                        label: 'Service Name',
                        icon: Icons.design_services_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _locationsController,
                        label: 'Locations',
                        icon: Icons.location_on_outlined,
                        hintText: 'e.g. Surat, Ahmedabad',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    icon: Icons.sell_outlined,
                    title: 'Category & Pricing',
                    subtitle: 'Choose the right category and set pricing.',
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final categoryDropdown = DropdownButtonFormField<String>(
                            value: (_selectedCategoryId != null && _categoryNameById.containsKey(_selectedCategoryId)) ? _selectedCategoryId : null,
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem<String>(
                                    value: (c['id'] ?? '').toString(),
                                    child: Text((c['name'] ?? '').toString(), overflow: TextOverflow.ellipsis),
                                  ),
                                )
                                .toList(),
                            onChanged: (_submitting || _categoriesLoading)
                                ? null
                                : (v) async {
                                    final id = (v ?? '').trim();
                                    setState(() {
                                      _selectedCategoryId = id.isEmpty ? null : id;
                                      _categoryIdController.text = id;
                                      _selectedSubcategoryIds.clear();
                                      _subcategoryController.clear();
                                      _subcategories = [];
                                    });
                                    if (id.isNotEmpty) {
                                      await _loadSubcategories(id);
                                    }
                                  },
                            decoration: InputDecoration(
                              labelText: 'Category',
                              prefixIcon: const Icon(Icons.category_outlined),
                              filled: true,
                              fillColor: cs.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: cs.outlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: cs.primary, width: 1.6),
                              ),
                              suffixIcon: _categoriesLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                    )
                                  : null,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          );
                          final subcategoryButton = SizedBox(
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: (_submitting || _selectedCategoryId == null || _subcategoriesLoading) ? null : _openSubcategoryPicker,
                              icon: _subcategoriesLoading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.list_alt_outlined),
                              label: Text(
                                _selectedSubcategoryIds.isEmpty ? 'Subcategories' : '${_selectedSubcategoryIds.length} selected',
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: BorderSide(color: cs.outlineVariant),
                                backgroundColor: cs.surface,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                              ),
                            ),
                          );
                          if (constraints.maxWidth < 380) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                categoryDropdown,
                                const SizedBox(height: 12),
                                subcategoryButton,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: categoryDropdown),
                              const SizedBox(width: 12),
                              Expanded(child: subcategoryButton),
                            ],
                          );
                        },
                      ),
                      if (_selectedSubcategoryIds.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Text(
                            _selectedSubcategoryIds
                                .map((id) => _subcategoryNameById[id] ?? id)
                                .where((s) => s.trim().isNotEmpty)
                                .join(', '),
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[800]),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final priceField = _field(
                            controller: _priceController,
                            label: 'Price',
                            icon: Icons.currency_rupee,
                            keyboardType: TextInputType.number,
                          );
                          final perPriceField = _field(
                            controller: _perPriceController,
                            label: 'Per Price',
                            icon: Icons.payments_outlined,
                            hintText: 'e.g. hour/day',
                          );
                          if (constraints.maxWidth < 380) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                priceField,
                                const SizedBox(height: 12),
                                perPriceField,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: priceField),
                              const SizedBox(width: 12),
                              Expanded(child: perPriceField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      ValueListenableBuilder<bool>(
                        valueListenable: _allHourController,
                        builder: (context, v, _) {
                          return Container(
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: cs.outlineVariant),
                            ),
                            child: SwitchListTile(
                              value: v,
                              onChanged: _submitting ? null : (nv) => _allHourController.value = nv,
                              title: Text('All Hour', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              subtitle: Text('Show as available all day', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final workingDaysField = _field(
                            controller: _workingDaysController,
                            label: 'Working Days',
                            icon: Icons.calendar_month_outlined,
                            hintText: 'e.g. Mon-Sat',
                          );
                          final numberField = _field(
                            controller: _numberController,
                            label: 'Contact Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          );
                          if (constraints.maxWidth < 380) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                workingDaysField,
                                const SizedBox(height: 12),
                                numberField,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: workingDaysField),
                              const SizedBox(width: 12),
                              Expanded(child: numberField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final openField = _field(
                            controller: _openTimeController,
                            label: 'Open Time',
                            icon: Icons.schedule_outlined,
                            hintText: 'e.g. 9:00 AM',
                          );
                          final closeField = _field(
                            controller: _closeTimeController,
                            label: 'Close Time',
                            icon: Icons.schedule_outlined,
                            hintText: 'e.g. 6:00 PM',
                          );
                          if (constraints.maxWidth < 380) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                openField,
                                const SizedBox(height: 12),
                                closeField,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: openField),
                              const SizedBox(width: 12),
                              Expanded(child: closeField),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    icon: Icons.notes_outlined,
                    title: 'Description',
                    subtitle: 'Add a clear summary and full details.',
                    children: [
                      _field(controller: _addressController, label: 'Address', icon: Icons.home_outlined, maxLines: 2),
                      const SizedBox(height: 12),
                      _field(controller: _shortDescriptionController, label: 'Short Description', icon: Icons.short_text, maxLines: 2),
                      const SizedBox(height: 12),
                      _field(controller: _descriptionController, label: 'Description', icon: Icons.description_outlined, maxLines: 5),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    icon: Icons.photo_library_outlined,
                    title: 'Images',
                    subtitle: 'Good photos improve conversions.',
                    children: [
                      SizedBox(
                        height: 46,
                        child: FilledButton.tonalIcon(
                          onPressed: _submitting ? null : _pickImages,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Add Images'),
                        ),
                      ),
                      if (_existingImages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _existingImages
                              .map(
                                (url) => ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    url,
                                    width: 78,
                                    height: 78,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 78,
                                      height: 78,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (_pickedImages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_pickedImages.length, (i) {
                            final f = _pickedImages[i];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(f.path),
                                    width: 78,
                                    height: 78,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 78,
                                      height: 78,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: GestureDetector(
                                    onTap: _submitting ? null : () => _removePickedImage(i),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: cs.scrim.withValues(alpha: 0.55), shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.link_outlined, color: cs.onPrimaryContainer),
                        ),
                        title: Text('Links & Social', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                        subtitle: Text('Optional', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                        children: [
                          _field(controller: _websiteController, label: 'Website', icon: Icons.language_outlined, keyboardType: TextInputType.url),
                          const SizedBox(height: 12),
                          _field(controller: _facebookController, label: 'Facebook', icon: Icons.facebook_outlined),
                          const SizedBox(height: 12),
                          _field(controller: _instagramController, label: 'Instagram', icon: Icons.camera_alt_outlined),
                          const SizedBox(height: 12),
                          _field(controller: _twitterController, label: 'Twitter', icon: Icons.alternate_email),
                          const SizedBox(height: 12),
                          _field(controller: _linkedinController, label: 'LinkedIn', icon: Icons.work_outline),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.map_outlined, color: cs.onPrimaryContainer),
                        ),
                        title: Text('Map Location', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                        subtitle: Text('Optional', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                        children: [
                          _field(controller: _gmapController, label: 'Google Map Link', icon: Icons.pin_drop_outlined),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final latField = _field(controller: _latiController, label: 'Latitude', icon: Icons.my_location_outlined, keyboardType: TextInputType.number);
                              final lngField = _field(controller: _lngiController, label: 'Longitude', icon: Icons.my_location_outlined, keyboardType: TextInputType.number);
                              if (constraints.maxWidth < 380) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    latField,
                                    const SizedBox(height: 12),
                                    lngField,
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(child: latField),
                                  const SizedBox(width: 12),
                                  Expanded(child: lngField),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
