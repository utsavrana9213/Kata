import 'package:servekeen/service_model.dart';

enum VendorTier { standard, premium }

String normalizeSearch(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');

bool isTier(Service service, VendorTier tier) =>
    tier == VendorTier.premium ? service.isPremium : !service.isPremium;

/// Conservative client-side relevance guard for imperfect backend search.
/// A service is shown only when a query matches a real vendor field/category.
List<Service> rankRelevantServices(
  Iterable<Service> services,
  String query, {
  required VendorTier tier,
  Map<String, String> categoryNames = const {},
}) {
  final q = normalizeSearch(query);
  final terms = q.split(' ').where((term) => term.isNotEmpty).toList();
  final results = services.where((service) {
    if (!isTier(service, tier)) return false;
    if (terms.isEmpty) return true;
    final haystack = normalizeSearch(
      [
        service.companyName,
        service.serviceName,
        service.subcategory ?? '',
        categoryNames[service.categorys] ?? '',
        service.locations ?? '',
        service.address ?? '',
        service.shortDescription ?? '',
      ].join(' '),
    );
    return terms.every(haystack.contains);
  }).toList();
  results.sort(
    (a, b) =>
        _score(a, q, categoryNames).compareTo(_score(b, q, categoryNames)),
  );
  return results;
}

int _score(Service service, String query, Map<String, String> categories) {
  final fields = [
    categories[service.categorys] ?? '',
    service.subcategory ?? '',
    service.serviceName,
    service.companyName,
  ].map(normalizeSearch).toList();
  for (var index = 0; index < fields.length; index++) {
    if (fields[index] == query) return index;
    if (fields[index].startsWith(query)) return index + 4;
  }
  return 20;
}
