import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:servekeen/service_model.dart';
import 'package:servekeen/api_service.dart';

class CategoryNode {
  final String id;
  final String name;
  CategoryNode(this.id, this.name);
}

class SubcategoryNode {
  final String id;
  final String name;
  SubcategoryNode(this.id, this.name);
}

class HierarchyRepository {
  static final HierarchyRepository _instance = HierarchyRepository._internal();
  factory HierarchyRepository() => _instance;
  HierarchyRepository._internal();

  bool _initialized = false;

  final Map<String, String> _categoryNames = {};
  final Map<String, Map<String, String>> _subcategoryNamesByCategory = {};
  final Map<String, Map<String, List<Service>>> _servicesByCatSub = {};

  bool _looksLikeId(String value) => RegExp(r'^\d+$').hasMatch(value.trim());

  String? categoryNameFor(String? idOrName) {
    final value = (idOrName ?? '').trim();
    if (value.isEmpty) return null;
    return _categoryNames[value] ?? (_looksLikeId(value) ? null : value);
  }

  String? subcategoryNameFor(String? categoryId, String? idOrName) {
    final value = (idOrName ?? '').trim();
    if (value.isEmpty) return null;
    final map = _subcategoryNamesByCategory[(categoryId ?? '').trim()];
    return map?[value] ?? (_looksLikeId(value) ? null : value);
  }

  Future<void> init() async {
    if (_initialized) return;
    final csvString = await rootBundle.loadString('services_rows.csv');
    final rows = const CsvToListConverter(eol: '\n').convert(csvString);
    if (rows.isEmpty) {
      _initialized = true;
      return;
    }
    final headers = rows.first.map((e) => e.toString()).toList();
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length != headers.length) continue;
      final Map<String, dynamic> json = {};
      for (var j = 0; j < headers.length; j++) {
        json[headers[j]] = row[j];
      }
      final categoryId = (json['category_id'] ?? json['categorys'] ?? '')
          .toString()
          .trim();
      if (categoryId.isEmpty) continue;
      final subStr = (json['subcategory'] ?? '').toString().trim();
      final subs = subStr.isEmpty
          ? <String>['']
          : subStr
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
      final service = Service.fromJson(json);
      final catMap = _servicesByCatSub.putIfAbsent(categoryId, () => {});
      if (subs.isEmpty) {
        final list = catMap.putIfAbsent('', () => []);
        list.add(service);
      } else {
        for (final s in subs) {
          final list = catMap.putIfAbsent(s, () => []);
          list.add(service);
        }
      }
    }
    try {
      final data = await ApiService().fetchAppData();
      if (data['categories'] is List) {
        for (final c in (data['categories'] as List)) {
          final id = (c['id'] ?? '').toString();
          final label = (c['category_name'] ?? c['name'] ?? '').toString();
          if (id.isNotEmpty) _categoryNames[id] = label;
        }
      }
    } catch (_) {}
    _initialized = true;
  }

  List<CategoryNode> getCategories() {
    final ids = _servicesByCatSub.keys.toList();
    ids.sort((a, b) {
      final na = _categoryNames[a] ?? 'Category $a';
      final nb = _categoryNames[b] ?? 'Category $b';
      return na.toLowerCase().compareTo(nb.toLowerCase());
    });
    return ids
        .map((id) => CategoryNode(id, _categoryNames[id] ?? 'Category'))
        .toList();
  }

  Future<List<SubcategoryNode>> getSubcategories(String categoryId) async {
    final names = _subcategoryNamesByCategory[categoryId] ?? {};
    if (names.isEmpty) {
      try {
        final subs = await ApiService().fetchSubcategories(categoryId);
        final map = <String, String>{};
        for (final s in subs) {
          final id = (s['id'] ?? '').toString();
          final name =
              (s['subname'] ?? s['subcategory_name'] ?? s['name'] ?? '')
                  .toString();
          if (id.isNotEmpty && name.trim().isNotEmpty) map[id] = name;
        }
        _subcategoryNamesByCategory[categoryId] = map;
      } catch (_) {}

      // If still empty, derive IDs from available services (server data) as a fallback
      if ((_subcategoryNamesByCategory[categoryId] == null ||
          _subcategoryNamesByCategory[categoryId]!.isEmpty)) {
        try {
          final app = await ApiService().fetchAppData();
          final list = (app['services'] as List?) ?? const [];
          final ids = <String>{};
          for (final e in list) {
            final cat = (e['category_id'] ?? e['categorys'] ?? '').toString();
            if (cat != categoryId) continue;
            final subStr = (e['subcategory'] ?? '').toString();
            for (final part in subStr.split(',')) {
              final id = part.trim();
              if (id.isNotEmpty) ids.add(id);
            }
          }
          if (ids.isNotEmpty) {
            _subcategoryNamesByCategory[categoryId] = {
              for (final id in ids) id: '',
            };
          }
        } catch (_) {}
      }
    }
    // Union of subcategories known from CSV services and server names
    final csvIds = (_servicesByCatSub[categoryId]?.keys.toList() ?? <String>[]);
    final serverIds =
        (_subcategoryNamesByCategory[categoryId]?.keys.toList() ?? <String>[]);
    final ids = <String>{...csvIds, ...serverIds}.toList();
    ids.sort((a, b) {
      final na =
          _subcategoryNamesByCategory[categoryId]?[a] ??
          (a.isEmpty ? 'All' : '');
      final nb =
          _subcategoryNamesByCategory[categoryId]?[b] ??
          (b.isEmpty ? 'All' : '');
      return na.toLowerCase().compareTo(nb.toLowerCase());
    });
    return ids.map((id) {
      final name =
          _subcategoryNamesByCategory[categoryId]?[id] ??
          (id.isEmpty ? 'All' : '');
      return SubcategoryNode(id, name);
    }).toList();
  }

  List<Service> getServices(String categoryId, {String? subcategoryId}) {
    final catMap = _servicesByCatSub[categoryId] ?? {};
    if (subcategoryId == null || subcategoryId.isEmpty) {
      final all = <Service>[];
      for (final list in catMap.values) {
        all.addAll(list);
      }
      return all;
    }
    return List<Service>.from(catMap[subcategoryId] ?? const []);
  }

  /// Offline-safe source for the home screen when the app-data endpoint is
  /// unavailable or returns an incomplete services payload.
  List<Service> getAllServices() {
    final unique = <String, Service>{};
    for (final category in _servicesByCatSub.values) {
      for (final services in category.values) {
        for (final service in services) {
          if (service.companyName.isNotEmpty &&
              service.serviceName.isNotEmpty) {
            unique.putIfAbsent(service.id, () => service);
          }
        }
      }
    }
    return unique.values.toList();
  }
}
